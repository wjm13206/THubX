local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local RunService = Services.RunService
local LocalPlayer = Players.LocalPlayer

local instances = {}

local function getFullPath(obj)
    local parts = {}
    local current = obj
    while current do
        table.insert(parts, 1, current.Name)
        current = current.Parent
    end
    return table.concat(parts, ".")
end

local function findObjectByAbsolutePath(pathStr)
    local parts = {}
    for part in string.gmatch(pathStr, "[^%.]+") do
        table.insert(parts, part)
    end
    if #parts == 0 then return nil end

    local current = game
    for i = 1, #parts do
        current = current:FindFirstChild(parts[i])
        if not current then
            return nil
        end
    end
    return current
end

local function findDeepestMatchLevel(pathStr, patterns)
    local pathParts = {}
    for part in string.gmatch(pathStr, "[^%.]+") do
        table.insert(pathParts, part)
    end

    local searchTerms
    if type(patterns) == "table" then
        searchTerms = patterns
    else
        searchTerms = {patterns}
    end

    if #searchTerms == 1 then
        local term = searchTerms[1]
        local deepestLevel = 0
        for i, part in ipairs(pathParts) do
            if i > 1 and string.find(part, term) then
                deepestLevel = i - 1
            end
        end
        return deepestLevel
    end

    local matchedLevels = {}
    for _, term in ipairs(searchTerms) do
        local deepestForTerm = 0
        for i, part in ipairs(pathParts) do
            if i > 1 and string.find(part, term) then
                deepestForTerm = i - 1
            end
        end
        if deepestForTerm == 0 then
            return 0
        end
        table.insert(matchedLevels, deepestForTerm)
    end

    local maxLevel = 0
    for _, level in ipairs(matchedLevels) do
        if level > maxLevel then
            maxLevel = level
        end
    end
    return maxLevel
end

local function pathFuzzyHit(pathStr, patterns)
    if type(patterns) == "table" then
        for _, term in ipairs(patterns) do
            if not string.find(pathStr, term, 1, true) then
                return false
            end
        end
        return true
    end
    return string.find(pathStr, patterns, 1, true) ~= nil
end

local function createNameTagInstance(modelName, matchMode, fontSize, showDistance, customText)
    local self = {}

    self.modelName = modelName
    self.matchMode = matchMode or "fuzzy"
    self.fontSize = fontSize
    self.showDistance = showDistance or false
    self.customText = customText

    self.enabled = false
    self.connections = {}
    self.activeTags = {}
    self.modelToTag = {}
    self.scanConnection = nil
    self.descendantConnection = nil
    self.modelConns = {}
    self.currentApplyTaskId = nil
    self.isApplying = false

    local taskCounter = 0
    local function getNewTaskId()
        taskCounter = taskCounter + 1
        return taskCounter
    end

    local function addTagToModel(model)
        if not model:IsA("Model") then return end
        if self.modelToTag[model] then return end
        if Players:GetPlayerFromCharacter(model) then return end

        local adornee = nil
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("BasePart") then
                adornee = child
                break
            end
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NameTag_" .. model.Name
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = model

        if adornee then
            billboard.Adornee = adornee
        end

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0.5
        label.Font = Enum.Font.SourceSansBold
        label.Parent = billboard

        if self.customText then
            label.Text = self.customText
        else
            label.Text = model.Name
        end

        if self.fontSize then
            label.TextScaled = false
            label.TextSize = self.fontSize
        else
            label.TextScaled = true
        end

        self.activeTags[model] = { billboard = billboard, label = label }
        self.modelToTag[model] = true

        if not adornee then
            local childConn
            childConn = model.DescendantAdded:Connect(function(child)
                if child:IsA("BasePart") and not billboard.Adornee then
                    billboard.Adornee = child
                    childConn:Disconnect()
                end
            end)
            table.insert(self.modelConns, childConn)
        end
    end

    local function removeTagFromModel(model)
        local tagData = self.activeTags[model]
        if not tagData then return end

        if tagData.billboard and tagData.billboard.Parent then
            tagData.billboard:Destroy()
        end
        self.activeTags[model] = nil
        self.modelToTag[model] = nil
    end

    local function removeAllTags()
        for model, _ in pairs(self.activeTags) do
            removeTagFromModel(model)
        end
    end

    local function isMatch(obj)
        if self.matchMode == "only" then
            return obj.Name == self.modelName
        elseif self.matchMode == "fuzzy" then
            return string.find(obj.Name, self.modelName) ~= nil
        elseif self.matchMode == "path" then
            return getFullPath(obj) == self.modelName
        elseif self.matchMode == "pathFuzzy" then
            return findDeepestMatchLevel(getFullPath(obj), self.modelName) > 0
        end
        return false
    end

    local function isDescendantOfTarget(obj, targetObj)
        local current = obj
        while current do
            if current == targetObj then
                return true
            end
            current = current.Parent
        end
        return false
    end

    local function asyncScanCore(taskId)
        if self.scanConnection then
            self.scanConnection:Disconnect()
            self.scanConnection = nil
        end

        local allObjects = Workspace:GetDescendants()
        local total = #allObjects
        local processed = 0
        local batch = 100

        self.scanConnection = RunService.RenderStepped:Connect(function()
            if taskId ~= self.currentApplyTaskId then
                if self.scanConnection then
                    self.scanConnection:Disconnect()
                    self.scanConnection = nil
                end
                return
            end

            local endIdx = math.min(processed + batch, total)
            for i = processed + 1, endIdx do
                local obj = allObjects[i]
                if obj:IsA("Model") then
                    if self.matchMode == "path" then
                        local targetObj = findObjectByAbsolutePath(self.modelName)
                        if targetObj and isDescendantOfTarget(obj, targetObj) then
                            addTagToModel(obj)
                        end
                    elseif self.matchMode == "pathFuzzy" then
                        if pathFuzzyHit(getFullPath(obj), self.modelName) then
                            addTagToModel(obj)
                        end
                    else
                        if isMatch(obj) then
                            addTagToModel(obj)
                        end
                    end
                end
            end
            processed = endIdx

            if processed >= total then
                if self.scanConnection then
                    self.scanConnection:Disconnect()
                    self.scanConnection = nil
                end
                self.isApplying = false
            end
        end)
    end

    self.enable = function()
        if self.enabled then return end
        self.enabled = true

        self.currentApplyTaskId = getNewTaskId()
        if self.scanConnection then
            self.scanConnection:Disconnect()
            self.scanConnection = nil
        end

        if self.descendantConnection then
            self.descendantConnection:Disconnect()
            self.descendantConnection = nil
        end
        for _, conn in pairs(self.modelConns) do
            conn:Disconnect()
        end
        self.modelConns = {}

        self.isApplying = true
        asyncScanCore(self.currentApplyTaskId)

        self.descendantConnection = Workspace.DescendantAdded:Connect(function(descendant)
            if not self.enabled then return end

            if self.matchMode == "path" then
                local targetObj = findObjectByAbsolutePath(self.modelName)
                if targetObj then
                    local current = descendant
                    while current do
                        if current == targetObj then
                            if descendant:IsA("Model") then
                                addTagToModel(descendant)
                                local childConn = descendant.DescendantAdded:Connect(function(child)
                                    if child:IsA("Model") then
                                        addTagToModel(child)
                                    end
                                end)
                                table.insert(self.modelConns, childConn)
                            end
                            break
                        end
                        current = current.Parent
                    end
                end
            elseif self.matchMode == "pathFuzzy" then
                if descendant:IsA("Model") and findDeepestMatchLevel(getFullPath(descendant), self.modelName) > 0 then
                    addTagToModel(descendant)
                    local childConn = descendant.DescendantAdded:Connect(function(child)
                        if child:IsA("Model") then
                            addTagToModel(child)
                        end
                    end)
                    table.insert(self.modelConns, childConn)
                end
            else
                local current = descendant
                while current do
                    if current:IsA("Model") and isMatch(current) then
                        addTagToModel(current)
                        local childConn = current.DescendantAdded:Connect(function(child)
                            if child:IsA("Model") then
                                addTagToModel(child)
                            end
                        end)
                        table.insert(self.modelConns, childConn)
                        break
                    end
                    current = current.Parent
                end
            end
        end)

        if self.showDistance then
            local lastDistUpdate = 0
            local heartbeatConn = RunService.Heartbeat:Connect(function()
                local now = tick()
                if now - lastDistUpdate < 0.3 then return end
                lastDistUpdate = now
                self:_updateDistances()
            end)
            table.insert(self.connections, heartbeatConn)
        end
    end

    self.disable = function()
        if not self.enabled then return end
        self.enabled = false

        for _, conn in ipairs(self.connections) do
            conn:Disconnect()
        end
        self.connections = {}

        if self.scanConnection then
            self.scanConnection:Disconnect()
            self.scanConnection = nil
        end
        if self.descendantConnection then
            self.descendantConnection:Disconnect()
            self.descendantConnection = nil
        end
        for _, conn in pairs(self.modelConns) do
            conn:Disconnect()
        end
        self.modelConns = {}

        if self.isApplying then
            self.currentApplyTaskId = getNewTaskId()
            self.isApplying = false
        end

        removeAllTags()
    end

    self.destroy = function()
        self:disable()

        for i, inst in ipairs(instances) do
            if inst == self then
                table.remove(instances, i)
                break
            end
        end

        setmetatable(self, nil)
    end

    self._updateDistances = function()
        if not self.enabled or not self.showDistance then return end

        local character = LocalPlayer and LocalPlayer.Character
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
        if not rootPart then return end

        for model, tag in pairs(self.activeTags) do
            if not model or not model.Parent then
                removeTagFromModel(model)
            else
                local adornee = tag.billboard.Adornee
                if adornee and adornee.Parent then
                    local dist = (adornee.Position - rootPart.Position).Magnitude
                    local rounded = math.floor(dist * 10 + 0.5) / 10
                    if tag.lastDist ~= rounded then
                        tag.lastDist = rounded
                        local baseText = self.customText or model.Name
                        tag.label.Text = string.format("%s (%.1f)", baseText, rounded)
                    end
                end
            end
        end
    end

    table.insert(instances, self)
    return self
end

local Engine = {}
Engine.new = createNameTagInstance
Engine.unload = function()
    for i = #instances, 1, -1 do
        local inst = instances[i]
        if inst and inst.destroy then
            inst:destroy()
        end
    end
    instances = {}
end

local currentTarget = ""
local currentMode = "fuzzy"
local showDistance = false

local M = {}
M.Title = "模型标签"

function M.Init(Tabs, ctx)
    local section = Tabs.Visual:Section({ Title = "标签" })
    section:Input({
        Title = "标签目标",
        Icon = "tag",
        Placeholder = "输入模型名称",
        Callback = function(v)
            currentTarget = v or ""
        end,
    })
    section:Dropdown({
        Title = "匹配模式",
        Icon = "list",
        Values = { "fuzzy", "only" },
        Value = "fuzzy",
        Callback = function(v)
            currentMode = v or "fuzzy"
        end,
    })
    section:Toggle({
        Title = "显示距离",
        Icon = "ruler",
        Value = false,
        Callback = function(state)
            showDistance = state
        end,
    })
    section:Button({
        Title = "开始标�?,
        Icon = "play",
        Callback = function()
            if currentTarget == "" then return end
            Engine.new(currentTarget, currentMode, nil, showDistance, nil).enable()
        end,
    })
    section:Button({
        Title = "清除标记",
        Icon = "trash-2",
        Callback = function()
            Engine.unload()
        end,
    })
end

Unload.OnUnload(function()
    pcall(function()
        Engine.unload()
    end)
end)

return M
