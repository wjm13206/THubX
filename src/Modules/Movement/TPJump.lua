local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local TPJump = {}
TPJump.Title = "跳跃增强"

local RunService = Services.RunService
local UserInputService = Services.UserInputService
local player = Services.Players.LocalPlayer

local enabled = false
local boostPower = 40
local jumpConn = nil

local function onJumpRequest()
	if not enabled then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not (character and humanoid and humanoid.Parent) then
		return
	end
	if humanoid:GetState() == Enum.HumanoidStateType.Jumping then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, boostPower, 0)
		end
	end
end

local function setEnabled(state)
	enabled = state
	if enabled then
		if not jumpConn then
			jumpConn = UserInputService.JumpRequest:Connect(onJumpRequest)
		end
	else
		if jumpConn then
			jumpConn:Disconnect()
			jumpConn = nil
		end
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function TPJump.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Movement, TPJump.Title, { Icon = "chevrons-up" })
	folder:Toggle({
		Title = "启用跳跃增强",
		Icon = "chevrons-up",
		Value = false,
		Callback = function(state)
			setEnabled(state)
		end,
	})
	folder:Slider({
		Title = "跳跃爆发力",
		Icon = "gauge",
		Step = 5,
		Value = {Min = 0, Max = 200, Default = 40},
		Callback = function(v)
			if type(v) == "number" and v >= 0 then
				boostPower = v
			end
		end,
	})
end

return TPJump
