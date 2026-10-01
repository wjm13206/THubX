local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "防甩飞"

local cloneref = Services.cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer

local enabled = false
local connections = {}
local currentCharacter = nil

local function toolMatch(Handle)
	local allPlayers = Players:GetPlayers()
	for i = 1, #allPlayers do
		local Player = allPlayers[i]
		if Player ~= LocalPlayer then
			local Character = Player.Character
			if Character then
				local RightArm = Character:FindFirstChild("Right Arm")
				if RightArm then
					local RightGrip = RightArm:FindFirstChild("RightGrip")
					if RightGrip and RightGrip.Part1 == Handle then
						return Player
					end
				end
			end
		end
	end
	return nil
end

local function setupCharacter(character)
	if not enabled then return end
	local RightArm = character:WaitForChild("Right Arm")
	local conn = RightArm.ChildAdded:Connect(function(child)
		if child:IsA("Weld") and child.Name == "RightGrip" and enabled then
			local ConnectedHandle = child.Part1
			local matched = toolMatch(ConnectedHandle)
			if matched and ConnectedHandle and ConnectedHandle.Parent then
				ConnectedHandle.Parent:Destroy()
			end
		end
	end)
	if not connections[character] then
		connections[character] = {}
	end
	table.insert(connections[character], conn)
end

local function onCharacterAdded(character)
	if not enabled then return end
	if currentCharacter and connections[currentCharacter] then
		for _, conn in ipairs(connections[currentCharacter]) do
			pcall(function() conn:Disconnect() end)
		end
		connections[currentCharacter] = nil
	end
	currentCharacter = character
	setupCharacter(character)
end

local function clearAllConnections()
	for _, connList in pairs(connections) do
		for _, conn in ipairs(connList) do
			pcall(function() conn:Disconnect() end)
		end
	end
	connections = {}
	currentCharacter = nil
end

local function enable()
	if enabled then return end
	enabled = true
	local character = LocalPlayer.Character
	if character then
		onCharacterAdded(character)
	end
	local charAddedConn = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	connections["_charAdded"] = { charAddedConn }
end

local function disable()
	enabled = false
end

Unload.OnUnload(function()
	enabled = false
	clearAllConnections()
end)

function M.Init(Tabs, ctx)
	local section = Tabs.Utility:Section({ Title = "防甩飞", Icon = "ban" })
	section:Toggle({
		Title = "开启防甩飞",
		Icon = "ban",
		Default = false,
		Callback = function(state)
			if state then
				enable()
			else
				disable()
			end
		end,
	})
end

return M
