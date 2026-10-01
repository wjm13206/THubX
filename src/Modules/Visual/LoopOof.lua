local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local LoopOof = {}
LoopOof.Title = "循环惨叫"

local Players = Services.Players
local RunService = Services.RunService

local active = false
local loop = nil
local conns = {}
local roster = {}

local function getOofSound(character)
	if not character then
		return nil
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return nil
	end
	for _, s in pairs(head:GetChildren()) do
		if s:IsA("Sound") then
			return s
		end
	end
	return nil
end

local function playAll()
	for _, player in pairs(roster) do
		if player and player.Character then
			local sound = getOofSound(player.Character)
			if sound then
				pcall(function()
					sound.Playing = true
				end)
			end
		end
	end
end

local function refreshRoster()
	roster = {}
	for _, player in pairs(Players:GetPlayers()) do
		table.insert(roster, player)
	end
end

local function clearConns()
	for _, c in ipairs(conns) do
		if c then
			pcall(function()
				c:Disconnect()
			end)
		end
	end
	conns = {}
	roster = {}
end

local function setEnabled(on)
	if on == active then
		return
	end
	active = on
	if on then
		refreshRoster()
		loop = RunService.Heartbeat:Connect(function()
			if not active then
				if loop then
					loop:Disconnect()
					loop = nil
				end
				return
			end
			playAll()
			task.wait(0.1)
		end)
		table.insert(conns, loop)
		table.insert(conns, Players.PlayerAdded:Connect(function(player)
			table.insert(roster, player)
		end))
		table.insert(conns, Players.PlayerRemoving:Connect(function(player)
			for i, p in ipairs(roster) do
				if p == player then
					table.remove(roster, i)
					break
				end
			end
		end))
	else
		if loop then
			loop:Disconnect()
			loop = nil
		end
		clearConns()
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function LoopOof.Init(Tabs, ctx)
	local section = Tabs.Visual:Section({ Title = "循环惨叫" })
	section:Toggle({
		Title = "全员循环惨叫",
		Icon = "volume-2",
		Value = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
end

return LoopOof
