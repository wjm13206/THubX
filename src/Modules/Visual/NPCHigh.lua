local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local NPCHigh = {}
NPCHigh.Title = "NPC高亮"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local RunService = Services.RunService

local outlineColor = Color3.fromRGB(255, 215, 0)
local showDistance = false

local enabled = false
local npcData = {}
local conns = {}

local function isNPC(model)
	if not model:IsA("Model") then
		return false
	end
	if not model:FindFirstChild("Humanoid") then
		return false
	end
	return Players:GetPlayerFromCharacter(model) == nil
end

local function getAdornee(model)
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end
	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
		return model.PrimaryPart
	end
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			return child
		end
	end
	return nil
end

local function makeTag(model, adornee)
	local board = Instance.new("BillboardGui")
	board.Name = "NPC_NameTag"
	board.Adornee = adornee
	board.Size = UDim2.new(0, 200, 0, 50)
	board.StudsOffset = Vector3.new(0, 3, 0)
	board.AlwaysOnTop = true
	board.Parent = model
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 16
	label.Text = "[NPC] " .. model.Name
	label.Parent = board
	return board, label
end

local function processNPC(model)
	if npcData[model] then
		return
	end
	npcData[model] = { processing = true }
	task.spawn(function()
		local adornee = nil
		while enabled and model and model.Parent do
			adornee = getAdornee(model)
			if adornee then
				break
			end
			task.wait(1)
		end
		if not enabled or not model or not model.Parent or not adornee then
			npcData[model] = nil
			return
		end
		if npcData[model] and npcData[model].billboard then
			return
		end
		local data = {}
		data.highlights = {}
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				local hl = Instance.new("Highlight")
				hl.Name = "NPC_Highlight"
				hl.OutlineColor = outlineColor
				hl.FillColor = outlineColor
				hl.FillTransparency = 0.5
				hl.Parent = part
				table.insert(data.highlights, hl)
			end
		end
		data.billboard, data.label = makeTag(model, adornee)
		data.baseName = "[NPC] " .. model.Name
		npcData[model] = data
	end)
end

local function unprocessNPC(model)
	local data = npcData[model]
	if not data then
		return
	end
	if data.highlights then
		for _, hl in ipairs(data.highlights) do
			if hl and hl.Parent then
				hl:Destroy()
			end
		end
	end
	if data.billboard and data.billboard.Parent then
		data.billboard:Destroy()
	end
	npcData[model] = nil
end

local function updateDistances()
	local player = Players.LocalPlayer
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for model, data in pairs(npcData) do
		if data and not data.processing and model and model.Parent then
			if data.billboard and data.billboard.Adornee and data.label then
				local ad = data.billboard.Adornee
				if ad and ad.Parent then
					local dist = math.floor((ad.Position - root.Position).Magnitude * 10 + 0.5) / 10
					if data.lastDist ~= dist then
						data.lastDist = dist
						data.label.Text = string.format("%s (%.1f)", data.baseName, dist)
					end
				end
			end
		end
	end
end

local function stopListeners()
	for _, c in ipairs(conns) do
		if c then
			c:Disconnect()
		end
	end
	conns = {}
end

local function clearAll()
	for model in pairs(npcData) do
		unprocessNPC(model)
	end
	npcData = {}
end

local function setEnabled(on)
	if on == enabled then
		return
	end
	enabled = on
	if on then
		table.insert(conns, Workspace.DescendantAdded:Connect(function(desc)
			if enabled and isNPC(desc) then
				processNPC(desc)
			end
		end))
		table.insert(conns, Workspace.DescendantRemoving:Connect(function(desc)
			if isNPC(desc) then
				unprocessNPC(desc)
			end
		end))
		local lastClean = 0
		table.insert(conns, RunService.Heartbeat:Connect(function()
			if not enabled then
				return
			end
			local now = tick()
			if now - lastClean >= 2 then
				lastClean = now
				local dead = {}
				for model, data in pairs(npcData) do
					if data and not data.processing then
						if not model or not model.Parent then
							table.insert(dead, model)
						end
					end
				end
				for _, m in ipairs(dead) do
					unprocessNPC(m)
				end
			end
			if showDistance then
				updateDistances()
			end
		end))
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if isNPC(obj) then
				processNPC(obj)
			end
		end
	else
		stopListeners()
		clearAll()
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function NPCHigh.Init(Tabs, ctx)
	local section = Tabs.Visual:Section({ Title = "NPC高亮" })
	section:Toggle({
		Title = "启用NPC高亮",
		Icon = "bot",
		Value = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
	section:Toggle({
		Title = "显示距离",
		Icon = "ruler",
		Value = false,
		Callback = function(v)
			showDistance = v
		end,
	})
	section:Colorpicker({
		Title = "高亮颜色",
		Icon = "palette",
		Default = Color3.fromRGB(255, 215, 0),
		Callback = function(v)
			outlineColor = v
		end,
	})
end

return NPCHigh
