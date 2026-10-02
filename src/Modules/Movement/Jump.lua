local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "跳跃增强"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local RunService = Services.RunService
local UserInputService = Services.UserInputService

local LocalPlayer = Players.LocalPlayer

-- 连跳（无限跳）
local infJumpOn = false
local infJumpConn = nil
local lastJump = 0
local function setInfJump(on)
	infJumpOn = on
	if on then
		if infJumpConn then
			return
		end
		infJumpConn = UserInputService.JumpRequest:Connect(function()
			if not infJumpOn then
				return
			end
			local now = tick()
			if now - lastJump < 0.25 then
				return
			end
			lastJump = now
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildWhichIsA("Humanoid")
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	else
		if infJumpConn then
			infJumpConn:Disconnect()
			infJumpConn = nil
		end
	end
end

-- 边缘跳跃（土狼时间）
local edgeJumpOn = false
local edgeConn = nil
local lastState = nil
local lastCFrame = nil
local function setEdgeJump(on)
	edgeJumpOn = on
	if on then
		if edgeConn then
			return
		end
		edgeConn = RunService.Heartbeat:Connect(function()
			if not edgeJumpOn then
				return
			end
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildWhichIsA("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not hum or not root then
				return
			end
			local state = hum:GetState()
			if lastState and lastState ~= Enum.HumanoidStateType.Jumping
				and state == Enum.HumanoidStateType.Freefall and lastCFrame then
				root.CFrame = lastCFrame
				root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, hum.JumpPower, root.AssemblyLinearVelocity.Z)
			end
			lastState = state
			lastCFrame = root.CFrame
		end)
	else
		if edgeConn then
			edgeConn:Disconnect()
			edgeConn = nil
		end
	end
end

-- 自动跳跃（独立线程，0.2 秒）
local autoJumpOn = false
local autoJumpThread = nil
local function setAutoJump(on)
	autoJumpOn = on
	if on then
		if autoJumpThread then
			return
		end
		autoJumpThread = task.spawn(function()
			while autoJumpOn do
				task.wait(0.2)
				if not autoJumpOn then
					break
				end
				local char = LocalPlayer.Character
				local hum = char and char.Parent and char:FindFirstChildWhichIsA("Humanoid")
				if hum then
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
			autoJumpThread = nil
		end)
	else
		if autoJumpThread then
			pcall(task.cancel, autoJumpThread)
			autoJumpThread = nil
		end
	end
end

Unload.OnUnload(function()
	setInfJump(false)
	setEdgeJump(false)
	setAutoJump(false)
end)

function M.Init(Tabs, ctx)
	Tabs.Movement:Toggle({
		Title = "连跳",
		Icon = "arrow-up",
		Value = false,
		Callback = function(state)
			setInfJump(state)
		end,
	})
	Tabs.Movement:Toggle({
		Title = "边缘跳跃",
		Icon = "footprints",
		Value = false,
		Callback = function(state)
			setEdgeJump(state)
		end,
	})
	Tabs.Movement:Toggle({
		Title = "自动跳跃",
		Icon = "repeat",
		Value = false,
		Callback = function(state)
			setAutoJump(state)
		end,
	})
	Tabs.Movement:Toggle({
		Title = "锚定到世界",
		Icon = "anchor",
		Value = false,
		Callback = function(state)
			local char = LocalPlayer.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				root.Anchored = state
			end
		end,
	})
	Tabs.Movement:Toggle({
		Title = "坐下",
		Icon = "armchair",
		Value = false,
		Callback = function(state)
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildWhichIsA("Humanoid")
			if hum then
				hum.Sit = state
			end
		end,
	})
end

return M
