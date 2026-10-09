local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Players = Services.Players
local UserInputService = Services.UserInputService
local localPlayer = Players.LocalPlayer

local enabled = false
local highlights = {}
local labels = {}
local connections = {}
local playerAddedConn = nil
local playerRemovingConn = nil
local mouseClickHandlerSet = false

local FRIEND_COLOR = Color3.new(0, 1, 0)
local NON_FRIEND_COLOR = Color3.new(1, 0, 0)
local MARKED_COLOR = Color3.new(1, 1, 1)

local markedPlayers = {}

local DEFAULT_CONFIG = {
    fillColor = Color3.new(1, 0, 0),
    fillTransparency = 0.8,
    outlineColor = Color3.new(1, 0, 0),
    outlineTransparency = 0,
    onlyOutline = false,
    labelOffset = Vector3.new(0, 3, 0),
    labelSize = UDim2.new(0, 200, 0, 50),
    textSize = 18,
    textColor = Color3.new(1, 1, 1),
}

local function getPlayerColor(player)
    if markedPlayers[player] then
        return MARKED_COLOR
    elseif player:IsFriendsWith(localPlayer.UserId) then
        return FRIEND_COLOR
    else
        return NON_FRIEND_COLOR
    end
end

local function updatePlayerColor(player)
    local highlight = highlights[player]
    if not highlight then return end

    local color = getPlayerColor(player)
    highlight.FillColor = color
    highlight.OutlineColor = color
end

local function addHighlight(player, character)
    if player == localPlayer or not character then return end

    local color = getPlayerColor(player)

    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillColor = color
    highlight.FillTransparency = DEFAULT_CONFIG.fillTransparency
    highlight.OutlineColor = color
    highlight.OutlineTransparency = DEFAULT_CONFIG.outlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    if DEFAULT_CONFIG.onlyOutline then
        highlight.FillTransparency = 1
    end
    highlights[player] = highlight
end

local function addLabel(player, character)
    if player == localPlayer or not character then return end
    local head = character:WaitForChild("Head", 5)
    if not head then return end

    local isMarked = markedPlayers[player]
    local isFriend = player:IsFriendsWith(localPlayer.UserId)
    local prefix = ""

    if isMarked then
        prefix = "[*] "
    elseif isFriend then
        prefix = "[F] "
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = head
    billboard.Size = DEFAULT_CONFIG.labelSize
    billboard.StudsOffset = DEFAULT_CONFIG.labelOffset
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    if player.DisplayName == player.Name then
        label.Text = prefix .. player.DisplayName
    else
        label.Text = prefix .. player.DisplayName .. " (@" .. player.Name .. ")"
    end
    label.TextColor3 = DEFAULT_CONFIG.textColor
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = DEFAULT_CONFIG.textSize
    label.Parent = billboard

    labels[player] = billboard
end

local function removePlayerEffects(player)
    local h = highlights[player]
    if h then
        h:Destroy()
        highlights[player] = nil
    end
    local l = labels[player]
    if l then
        l:Destroy()
        labels[player] = nil
    end
end

local function setupPlayer(player)
    if not enabled then return end
    if player == localPlayer then return end

    if connections[player] then
        for _, conn in ipairs(connections[player]) do
            conn:Disconnect()
        end
        connections[player] = nil
        removePlayerEffects(player)
    end

    local character = player.Character
    if character then
        addHighlight(player, character)
        addLabel(player, character)
    end

    local charAdded = player.CharacterAdded:Connect(function(newChar)
        removePlayerEffects(player)
        addHighlight(player, newChar)
        addLabel(player, newChar)
    end)

    local charRemoving = player.CharacterRemoving:Connect(function()
        removePlayerEffects(player)
    end)

    connections[player] = {charAdded, charRemoving}
end

local function clearAll()
    for player, conns in pairs(connections) do
        for _, conn in ipairs(conns) do
            conn:Disconnect()
        end
        removePlayerEffects(player)
    end
    connections = {}
    highlights = {}
    labels = {}
end

local function startGlobalListeners()
    if playerAddedConn then return end
    playerAddedConn = game.Players.PlayerAdded:Connect(setupPlayer)
    playerRemovingConn = game.Players.PlayerRemoving:Connect(removePlayerEffects)
end

local function stopGlobalListeners()
    if playerAddedConn then
        playerAddedConn:Disconnect()
        playerAddedConn = nil
    end
    if playerRemovingConn then
        playerRemovingConn:Disconnect()
        playerRemovingConn = nil
    end
end

local mouseClickConn = nil
local function setupMouseClickHandler()
    if mouseClickConn then return end
    mouseClickConn = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if not enabled then return end

        if input.UserInputType == Enum.UserInputType.MouseButton3 then
            local mouse = localPlayer:GetMouse()
            local target = mouse.Target
            if not target then return end

            local character = target:FindFirstAncestorOfClass("Model")
            if not character then return end

            local player = game.Players:GetPlayerFromCharacter(character)
            if not player or player == localPlayer then return end

            if markedPlayers[player] then
                markedPlayers[player] = nil
            else
                markedPlayers[player] = true
            end

            updatePlayerColor(player)
            local label = labels[player]
            if label then
                local characterNow = player.Character
                if characterNow then
                    removePlayerEffects(player)
                    addHighlight(player, characterNow)
                    addLabel(player, characterNow)
                end
            end
        end
    end)
end

local Engine = {}

function Engine.enable()
    if enabled then return end
    enabled = true
    startGlobalListeners()
    for _, player in ipairs(game.Players:GetPlayers()) do
        setupPlayer(player)
    end
    if not mouseClickHandlerSet then
        setupMouseClickHandler()
        mouseClickHandlerSet = true
    end
end

function Engine.disable()
    if not enabled then return end
    enabled = false
    clearAll()
end

local M = {}
M.Title = "玩家透视"

function M.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.ESP, M.Title, { Icon = "eye" })
    folder:Toggle({
        Title = "玩家透视",
        Icon = "eye",
        Value = false,
        Callback = function(state)
            if state then
                Engine.enable()
            else
                Engine.disable()
            end
        end,
    })
end

Unload.OnUnload(function()
    pcall(function()
        Engine.disable()
    end)
end)

return M
