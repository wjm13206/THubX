local Unload = require("../../Core/Unload")

local Defense = {}
Defense.Title = "防御力场"

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local localPlayer = Players.LocalPlayer

local isEnabled = false
local heartbeatConnection = nil
local characterAddedConnection = nil

local CONFIG = {
	RADIUS = 15,
	SHOW_VISUAL = true,
	VISUAL_TRANSPARENCY = 0.85,
	SCAN_INTERVAL = 5,
	MOVEMENT_THRESHOLD = 0.1,
	MAX_DELETE_PER_SCAN = 10,
}

local PROTECTED_NAMES = {
	["HumanoidRootPart"] = true,
	["Head"] = true,
	["Torso"] = true,
	["UpperTorso"] = true,
	["LowerTorso"] = true,
	["Left Arm"] = true,
	["Right Arm"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
	["Humanoid"] = true,
}

local visualField = nil

local overlapParams
local function getOverlapParams()
	if overlapParams then return overlapParams end
	local success, result = pcall(function()
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.RespectCanCollide = false
		return params
	end)
	if success then
		overlapParams = result
	end
	return overlapParams
end

local function getAllCharacters()
	local characters = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			characters[player.Character] = true
		end
	end
	return characters
end

local function isPartOfCharacter(part, character)
	if not character then return false end
	return part:IsDescendantOf(character)
end

local function isPartOfAnyPlayer(part, allCharacters)
	for char, _ in pairs(allCharacters) do
		if isPartOfCharacter(part, char) then
			return true
		end
	end
	return false
end

local function isPartMoving(part)
	local success, vel = pcall(function() return part.AssemblyLinearVelocity end)
	if success and vel and vel.Magnitude > CONFIG.MOVEMENT_THRESHOLD then
		return true
	end

	success, vel = pcall(function() return part.Velocity end)
	if success and vel and vel.Magnitude > CONFIG.MOVEMENT_THRESHOLD then
		return true
	end

	return false
end

local function safeCreatePart()
	local success, part = pcall(function()
		return Instance.new("Part")
	end)
	if success and part then
		return part
	end
	return nil
end

local function removeVisual()
	if visualField then
		pcall(function()
			visualField:Destroy()
		end)
		visualField = nil
	end
end

local function createVisual(character)
	removeVisual()

	if not CONFIG.SHOW_VISUAL then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local part = safeCreatePart()
	if not part then return end

	part.Name = "DefenseFieldVisual"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(CONFIG.RADIUS * 2, CONFIG.RADIUS * 2, CONFIG.RADIUS * 2)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Transparency = CONFIG.VISUAL_TRANSPARENCY
	part.Color = Color3.fromRGB(255, 50, 50)
	part.Material = Enum.Material.ForceField
	part.CastShadow = false
	part.Parent = cloneref(workspace)
	part.Position = rootPart.Position

	visualField = part
end

local function onCharacterAdded(character)
	if not isEnabled then return end

	removeVisual()

	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if rootPart and CONFIG.SHOW_VISUAL then
		createVisual(character)
	end
end

local function scanAndDelete(centerPosition)
	local params = getOverlapParams()
	if not params then return end

	local allCharacters = getAllCharacters()

	local partsInRange
	local success, result = pcall(function()
		return cloneref(workspace):GetPartBoundsInRadius(centerPosition, CONFIG.RADIUS, params)
	end)

	if not success then return end
	partsInRange = result

	local deleteCount = 0
	for _, part in ipairs(partsInRange) do
		if deleteCount >= CONFIG.MAX_DELETE_PER_SCAN then break end
		if not isEnabled then return end

		if part and part.Parent then
			if not part.Anchored then
				if not PROTECTED_NAMES[part.Name] then
					if not isPartOfAnyPlayer(part, allCharacters) then
						if isPartMoving(part) then
							pcall(function()
								part:Destroy()
							end)
							deleteCount = deleteCount + 1
						end
					end
				end
			end
		end
	end
end

local frameCount = 0

local function onHeartbeat()
	if not isEnabled then return end

	local character = localPlayer.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	if CONFIG.SHOW_VISUAL and visualField and visualField.Parent then
		visualField.Position = rootPart.Position
	end

	frameCount = frameCount + 1
	if frameCount >= CONFIG.SCAN_INTERVAL then
		frameCount = 0
		scanAndDelete(rootPart.Position)
	end
end

local function enable()
	if isEnabled then return end

	isEnabled = true
	frameCount = 0

	heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)
	characterAddedConnection = localPlayer.CharacterAdded:Connect(onCharacterAdded)

	if localPlayer.Character and CONFIG.SHOW_VISUAL then
		createVisual(localPlayer.Character)
	end
end

local function disable()
	if not isEnabled then return end

	isEnabled = false

	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end

	if characterAddedConnection then
		characterAddedConnection:Disconnect()
		characterAddedConnection = nil
	end

	removeVisual()
end

Unload.OnUnload(function()
	disable()
end)

function Defense.Init(Tabs, ctx)
	local settings = ctx.FeatureSettings("防御力场")
	Tabs.Combat:Toggle({
		Title = "启用力场",
		Icon = "shield",
		Value = false,
		Callback = function(state)
			if state then
				enable()
			else
				disable()
			end
		end,
	})
	settings:Slider({
		Title = "力场半径",
		Icon = "scan",
		Step = 1,
		Value = { Min = 5, Max = 50, Default = 15 },
		Callback = function(v)
			CONFIG.RADIUS = v
			if isEnabled and CONFIG.SHOW_VISUAL and localPlayer.Character then
				createVisual(localPlayer.Character)
			end
		end,
	})
	Tabs.Combat:Toggle({
		Title = "显示力场",
		Icon = "eye",
		Value = true,
		Callback = function(state)
			CONFIG.SHOW_VISUAL = state
			if not state then
				removeVisual()
			elseif isEnabled and localPlayer.Character then
				createVisual(localPlayer.Character)
			end
		end,
	})
end

return Defense
