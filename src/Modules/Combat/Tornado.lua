local Unload = require("../../Core/Unload")

local Tornado = {}
Tornado.Title = "龙卷飞"

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))

local enabled = false
local config = {
	radius = 50,
	height = 100,
	rotationSpeed = 10,
	attractionStrength = 1000,
}
local parts = {}
local connections = {}
local localPlayer = nil

local function shouldControlPart(part)
	if not part:IsA("BasePart") then
		return false
	end

	if part.Anchored then
		return false
	end

	if not part:IsDescendantOf(Workspace) then
		return false
	end

	local character = localPlayer.Character
	if character and (part:IsDescendantOf(character) or part.Parent == character) then
		return false
	end

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local otherCharacter = player.Character
			if otherCharacter and (part:IsDescendantOf(otherCharacter) or part.Parent == otherCharacter) then
				return false
			end
		end
	end

	return true
end

local function retainPart(part)
	if shouldControlPart(part) then
		part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
		part.CanCollide = false
		return true
	end
	return false
end

local function addPart(part)
	if not table.find(parts, part) and retainPart(part) then
		table.insert(parts, part)
	end
end

local function removePart(part)
	local index = table.find(parts, part)
	if index then
		table.remove(parts, index)
	end
end

local function setupNetworkControl()
	local heartbeatConnection = RunService.Heartbeat:Connect(function()
		if sethiddenproperty then
			pcall(function()
				sethiddenproperty(localPlayer, "SimulationRadius", math.huge)
			end)
		end
		localPlayer.ReplicationFocus = Workspace
	end)

	table.insert(connections, heartbeatConnection)
end

local function setupTornadoLogic()
	local tornadoConnection = RunService.Heartbeat:Connect(function()
		if not enabled then return end

		local character = localPlayer.Character
		if not character then return end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local center = rootPart.Position

		for _, part in pairs(parts) do
			if part.Parent and not part.Anchored and part:IsDescendantOf(Workspace) then
				local pos = part.Position

				local distance = (Vector3.new(pos.X, center.Y, pos.Z) - center).Magnitude

				local angle = math.atan2(pos.Z - center.Z, pos.X - center.X)

				local newAngle = angle + math.rad(config.rotationSpeed)

				local targetPos = Vector3.new(
					center.X + math.cos(newAngle) * math.min(config.radius, distance),
					center.Y + (config.height * math.abs(math.sin((pos.Y - center.Y) / math.max(config.height, 0.01)))),
					center.Z + math.sin(newAngle) * math.min(config.radius, distance)
				)

				local directionToTarget = (targetPos - part.Position).Unit
				part.Velocity = directionToTarget * config.attractionStrength
			end
		end
	end)

	table.insert(connections, tornadoConnection)

	local descendantAddedConnection = Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			addPart(descendant)
		end
	end)
	table.insert(connections, descendantAddedConnection)

	local descendantRemovingConnection = Workspace.DescendantRemoving:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			removePart(descendant)
		end
	end)
	table.insert(connections, descendantRemovingConnection)
end

local function cleanupConnections()
	for _, connection in pairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	connections = {}
end

local function cleanupParts()
	for _, part in pairs(parts) do
		if part and part.Parent then
			pcall(function()
				part.CustomPhysicalProperties = PhysicalProperties.new(
					part.Material,
					0.3, 0.5, 0.5,
					1, 1
				)
				part.CanCollide = true
			end)
		end
	end
	parts = {}
end

local function enable()
	if enabled then return end

	localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	for _, descendant in pairs(Workspace:GetDescendants()) do
		if descendant:IsA("BasePart") then
			addPart(descendant)
		end
	end

	setupNetworkControl()

	setupTornadoLogic()

	enabled = true
end

local function disable()
	if not enabled then return end

	cleanupConnections()
	cleanupParts()

	enabled = false
end

Unload.OnUnload(function()
	disable()
end)

function Tornado.Init(Tabs, ctx)
	local settings = ctx.FeatureSettings("龙卷飞")
	Tabs.Combat:Toggle({
		Title = "启用龙卷飞",
		Icon = "tornado",
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
		Title = "吸附半径",
		Icon = "scan",
		Step = 5,
		Value = { Min = 10, Max = 200, Default = 50 },
		Callback = function(v)
			config.radius = math.clamp(v, 0, 10000)
		end,
	})
	settings:Slider({
		Title = "龙卷高度",
		Icon = "arrow-up",
		Step = 5,
		Value = { Min = 10, Max = 300, Default = 100 },
		Callback = function(v)
			config.height = math.clamp(v, 0, 10000)
		end,
	})
	settings:Slider({
		Title = "旋转速度",
		Icon = "rotate-cw",
		Step = 1,
		Value = { Min = 1, Max = 50, Default = 10 },
		Callback = function(v)
			config.rotationSpeed = math.clamp(v, 0, 10000)
		end,
	})
	settings:Slider({
		Title = "吸附强度",
		Icon = "magnet",
		Step = 50,
		Value = { Min = 100, Max = 5000, Default = 1000 },
		Callback = function(v)
			config.attractionStrength = math.clamp(v, 0, 10000)
		end,
	})
end

return Tornado
