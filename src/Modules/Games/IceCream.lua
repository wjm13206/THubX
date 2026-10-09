local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local IceCream = {}
IceCream.Title = "自动吃冰淇淋"

local Players = Services.Players
local RunService = Services.RunService
local player = Players.LocalPlayer

local enabled = false
local isUsing = false
local lastUseTime = 0
local useCooldown = 3
local healthThreshold = 0.95
local itemName = "IceCreamCone"

local humanoid = nil
local heartbeatConn = nil
local charConn = nil

local function useItemOnTopOfCurrent()
	local character = player.Character
	if not character then
		return
	end
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		return
	end
	local targetItem = backpack:FindFirstChild(itemName)
	if not targetItem then
		return
	end
	targetItem.Parent = character
	task.wait(0.1)
	if targetItem:IsA("Tool") then
		targetItem:Activate()
	end
	task.wait(0.5)
	if targetItem and targetItem.Parent == character then
		targetItem.Parent = backpack
	end
end

local function tryUseIceCream()
	if isUsing then
		return
	end
	if not humanoid or not humanoid.Parent then
		return
	end
	local now = tick()
	if now - lastUseTime < useCooldown then
		return
	end
	local hp = humanoid.Health
	local maxHp = humanoid.MaxHealth
	if maxHp <= 0 then
		return
	end
	if hp >= maxHp * healthThreshold then
		return
	end
	local backpack = player:FindFirstChild("Backpack")
	if not backpack or not backpack:FindFirstChild(itemName) then
		return
	end
	isUsing = true
	lastUseTime = now
	task.spawn(function()
		pcall(useItemOnTopOfCurrent)
		isUsing = false
	end)
end

local function onHeartbeat()
	if not enabled then
		return
	end
	if not humanoid or not humanoid.Parent then
		return
	end
	local maxHp = humanoid.MaxHealth
	if maxHp <= 0 then
		return
	end
	if humanoid.Health < maxHp * healthThreshold then
		tryUseIceCream()
	end
end

local function unbindEvents()
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	if charConn then
		charConn:Disconnect()
		charConn = nil
	end
end

local function bindEvents()
	unbindEvents()
	heartbeatConn = RunService.Heartbeat:Connect(onHeartbeat)
	charConn = player.CharacterAdded:Connect(function(newChar)
		humanoid = newChar:WaitForChild("Humanoid", 5)
	end)
end

local function enable()
	if enabled then
		return
	end
	enabled = true
	local character = player.Character
	if character then
		humanoid = character:FindFirstChildOfClass("Humanoid")
	end
	bindEvents()
end

local function disable()
	if not enabled then
		return
	end
	enabled = false
	isUsing = false
	unbindEvents()
	humanoid = nil
end

Unload.OnUnload(function()
	disable()
end)

function IceCream.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Games, IceCream.Title, { Icon = "ice-cream-cone" })
	folder:Toggle({
		Title = "血量低自动吃冰淇淋",
		Icon = "ice-cream-cone",
		Value = false,
		Callback = function(state)
			if state then
				enable()
			else
				disable()
			end
		end,
	})
	folder:Slider({
		Title = "使用冷却(秒",
		Icon = "timer",
		Step = 1,
		Value = { Min = 1, Max = 30, Default = 3 },
		Callback = function(v)
			useCooldown = v
		end,
	})
	folder:Slider({
		Title = "触发血量%)",
		Icon = "heart-pulse",
		Step = 1,
		Value = { Min = 10, Max = 99, Default = 95 },
		Callback = function(v)
			healthThreshold = math.clamp(v / 100, 0, 1)
		end,
	})
end

return IceCream
