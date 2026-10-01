local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Fly = {}
Fly.Title = "飞行 (示例)"

local flying = false
local conn = nil

local function SetFlying(on)
	flying = on
	if conn then
		conn:Disconnect()
		conn = nil
	end
	local char = Services.Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if on and root then
		conn = Services.RunService.Heartbeat:Connect(function()
			if root and root.Parent then
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end)
	end
end

Unload.OnUnload(function()
	SetFlying(false)
end)

function Fly.Init(Tabs, _ctx)
	local section = Tabs.Movement:Section({ Title = "飞行类" })
	section:Toggle({
		Title = "启用飞行",
		Default = false,
		Callback = function(state)
			SetFlying(state)
		end,
	})
	section:Slider({
		Title = "飞行速度",
		Step = 1,
		Value = { Min = 16, Max = 200, Default = 50 },
		Callback = function(_v)
		end,
	})
end

return Fly
