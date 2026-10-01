local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local AntiFling = {}
AntiFling.Title = "反甩�?

local Players = Services.Players
local RunService = Services.RunService

local enabled = false
local conns = {}
local patrolConn = nil

local function setupCharacter(character)
	if not character then
		return
	end
	for _, v in pairs(character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
	local conn = character.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") then
			desc.CanCollide = false
		end
	end)
	table.insert(conns, conn)
end

local function onPlayerAdded(player)
	if not enabled then
		return
	end
	local localPlayer = Players.LocalPlayer
	if player == localPlayer then
		return
	end
	local charConn = player.CharacterAdded:Connect(function(character)
		setupCharacter(character)
	end)
	table.insert(conns, charConn)
	if player.Character then
		setupCharacter(player.Character)
	end
end

local function restoreAll()
	local localPlayer = Players.LocalPlayer
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			for _, v in pairs(player.Character:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = true
				end
			end
		end
	end
end

local function setEnabled(on)
	if on == enabled then
		return
	end
	enabled = on
	local localPlayer = Players.LocalPlayer
	if on then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= localPlayer then
				onPlayerAdded(player)
			end
		end
		table.insert(conns, Players.PlayerAdded:Connect(onPlayerAdded))
		patrolConn = RunService.Heartbeat:Connect(function()
			if not enabled then
				return
			end
			for _, player in pairs(Players:GetPlayers()) do
				if player ~= localPlayer and player.Character then
					for _, v in pairs(player.Character:GetDescendants()) do
						if v:IsA("BasePart") and v.CanCollide == true then
							v.CanCollide = false
						end
					end
				end
			end
		end)
	else
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		conns = {}
		if patrolConn then
			patrolConn:Disconnect()
			patrolConn = nil
		end
		restoreAll()
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function AntiFling.Init(Tabs, ctx)
	local section = Tabs.Utility:Section({ Title = "反甩�? })
	section:Toggle({
		Title = "他端碰撞关闭",
		Icon = "shield-off",
		Value = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
end

return AntiFling
