local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local FlyV4 = {}
FlyV4.Title = "V4飞行"

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService

local speeds = 1
local enable = false
local tpwalking = false
local flyConns = {}

local function getChar()
	local plr = Players.LocalPlayer
	return plr.Character
end

local function getHum(char)
	if char then
		return char:FindFirstChildWhichIsA("Humanoid")
	end
	return nil
end

local function setStates(hum, on)
	if hum then
		hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.Flying, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.Landed, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.Physics, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.Running, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.Seated, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, on)
		hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, on)
	end
end

local function startTpWalk()
	for i = 1, speeds do
		task.spawn(function()
			local hb = RunService.Heartbeat
			tpwalking = true
			local chr = getChar()
			local hum = getHum(chr)
			while tpwalking and hb:Wait() and chr and hum and hum.Parent do
				if hum.MoveDirection.Magnitude > 0 then
					chr:TranslateBy(hum.MoveDirection)
				end
			end
		end)
	end
end

local function flyLoop(part)
	local plr = Players.LocalPlayer
	local ctrl = { f = 0, b = 0, l = 0, r = 0 }
	local lastctrl = { f = 0, b = 0, l = 0, r = 0 }
	local maxspeed = 50
	local speed = 0
	local bg = Instance.new("BodyGyro")
	bg.P = 9e4
	bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
	bg.cframe = part.CFrame
	bg.Parent = part
	local bv = Instance.new("BodyVelocity")
	bv.velocity = Vector3.new(0, 0.1, 0)
	bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
	bv.Parent = part
	local hum = getHum(plr.Character)
	if enable == true and hum then
		plr.Character.Humanoid.PlatformStand = true
	end
	while enable == true do
		local h = hum
		if h and h.Health == 0 then
			break
		end
		RunService.RenderStepped:Wait()
		if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
			speed = speed + 0.5 + (speed / maxspeed)
			if speed > maxspeed then
				speed = maxspeed
			end
		else
			if speed ~= 0 then
				speed = speed - 1
				if speed < 0 then
					speed = 0
				end
			end
		end
		local cam = game.Workspace.CurrentCamera
		if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
			bv.velocity = ((cam.CoordinateFrame.lookVector * (ctrl.f + ctrl.b)) + ((cam.CoordinateFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).p) - cam.CoordinateFrame.p)) * speed
			lastctrl = { f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r }
		else
			if (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
				bv.velocity = ((cam.CoordinateFrame.lookVector * (lastctrl.f + lastctrl.b)) + ((cam.CoordinateFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).p) - cam.CoordinateFrame.p)) * speed
			else
				bv.velocity = Vector3.new(0, 0, 0)
			end
		end
		bg.cframe = cam.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
	end
	bg:Destroy()
	bv:Destroy()
	local ch2 = getChar()
	local h2 = getHum(ch2)
	if ch2 and h2 then
		h2.PlatformStand = false
		local anim = ch2:FindFirstChildOfClass("Animate")
		if anim then
			anim.Disabled = false
		end
	end
	tpwalking = false
end

local function setFly(on)
	enable = on
	local chr = getChar()
	local hum = getHum(chr)
	if on then
		startTpWalk()
		if chr then
			local anim = chr:FindFirstChildOfClass("Animate")
			if anim then
				anim.Disabled = true
			end
		end
		if hum then
			local tracks = hum:GetPlayingAnimationTracks()
			for i = 1, #tracks do
				tracks[i]:AdjustSpeed(0)
			end
		end
		setStates(hum, false)
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Swimming)
		end
		task.spawn(function()
			local c = getChar()
			if c and hum then
				if hum.RigType == Enum.HumanoidRigType.R6 then
					local torso = c:FindFirstChild("Torso")
					if torso then
						flyLoop(torso)
					end
				else
					local upper = c:FindFirstChild("UpperTorso")
					if upper then
						flyLoop(upper)
					end
				end
			end
		end)
	else
		setStates(hum, true)
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
		end
		tpwalking = false
	end
end

local function disable()
	if enable then
		setFly(false)
	end
	tpwalking = false
	for i = 1, #flyConns do
		pcall(function()
			flyConns[i]:Disconnect()
		end)
	end
	table.clear(flyConns)
end

Unload.OnUnload(disable)

function FlyV4.Init(Tabs, ctx)
	local section = Tabs.Movement:Section({ Title = "V4飞行" })
	section:Toggle({
		Title = "启用V4飞行",
		Icon = "plane",
		Value = false,
		Callback = function(state)
			setFly(state)
		end,
	})
	section:Slider({
		Title = "移动速度",
		Icon = "gauge",
		Step = 1,
		Value = { Min = 1, Max = 10, Default = 1 },
		Callback = function(v)
			speeds = v
			if enable == true then
				tpwalking = false
				startTpWalk()
			end
		end,
	})
	section:Keybind({
		Title = "飞行开关",
		Icon = "keyboard",
		Value = "F",
		Callback = function()
			setFly(not enable)
			if ctx and ctx.WindUI then
				ctx.WindUI:Notify({ Title = "V4飞行", Content = enable and "已开启 or "已关闭, Duration = 3 })
			end
		end,
	})
end

return FlyV4
