local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "恶劣功能"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local RunService = Services.RunService

local LocalPlayer = Players.LocalPlayer

local targetName = ""
local busy = false

local function findPlayer(name)
	if not name or name == "" then
		return nil
	end
	local lower = string.lower(name)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			if string.lower(plr.Name) == lower or string.lower(plr.DisplayName) == lower then
				return plr
			end
			if string.find(string.lower(plr.Name), lower, 1, true)
				or string.find(string.lower(plr.DisplayName), lower, 1, true) then
				return plr
			end
		end
	end
	return nil
end

local function executeFlingTeleport(target, notify)
	if busy then
		notify("正忙，请稍后再试")
		return
	end
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildWhichIsA("Humanoid")
	local tChar = target.Character
	local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
	if not root or not hum or not tRoot then
		notify("角色不存在，无法执行")
		return
	end
	busy = true
	local originalPos = root.CFrame
	root.CFrame = CFrame.new(tRoot.Position)
	hum.PlatformStand = true
	for _, inst in ipairs(char:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.CanCollide = true
			inst.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 0.5)
		end
	end
	local angVel = Instance.new("BodyAngularVelocity")
	angVel.Name = "__FlingTeleportVelocity"
	angVel.AngularVelocity = Vector3.new(99999, 99999, 99999)
	angVel.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	angVel.P = math.huge
	angVel.Parent = root
	local bodyPos = Instance.new("BodyPosition")
	bodyPos.Name = "__FlingTeleportPos"
	bodyPos.Position = tRoot.Position
	bodyPos.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bodyPos.D = 100
	bodyPos.P = 5000
	bodyPos.Parent = root
	local steppedConn = RunService.Stepped:Connect(function()
		for _, inst in ipairs(char:GetDescendants()) do
			if inst:IsA("BasePart") then
				inst.CanCollide = true
			end
		end
		if tChar and tChar.Parent then
			local tr = tChar:FindFirstChild("HumanoidRootPart")
			if tr then
				bodyPos.Position = tr.Position
			end
		end
	end)
	local heartConn = RunService.Heartbeat:Connect(function()
		root.Velocity = Vector3.new(root.Velocity.X, math.sin(tick() * 12) * 5, root.Velocity.Z)
	end)
	task.wait(1.5)
	steppedConn:Disconnect()
	heartConn:Disconnect()
	pcall(function()
		angVel:Destroy()
	end)
	pcall(function()
		bodyPos:Destroy()
	end)
	hum.PlatformStand = false
	for _, inst in ipairs(char:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.CanCollide = false
			inst.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
		end
	end
	root.CFrame = originalPos
	busy = false
	notify("已对 " .. target.DisplayName .. " 执行甩飞传送")
end

function M.Init(Tabs, ctx)
	local WindUI = ctx.WindUI
	local function notify(text)
		WindUI:Notify({ Title = "甩飞传送", Content = text, Duration = 3 })
	end

	local section = Tabs.Combat:Section({ Title = "恶劣功能（可能导致封号）" })
	section:Input({
		Title = "要甩飞的玩家名",
		Icon = "user",
		Value = "",
		Placeholder = "输入玩家名（支持模糊匹配）",
		Callback = function(text)
			targetName = tostring(text or "")
		end,
	})
	section:Button({
		Title = "甩飞这个玩家",
		Icon = "rocket",
		Callback = function()
			local target = findPlayer(targetName)
			if target then
				task.spawn(executeFlingTeleport, target, notify)
			else
				notify("未找到玩家: " .. targetName)
			end
		end,
	})
	section:Button({
		Title = "甩飞全部玩家",
		Icon = "bomb",
		Callback = function()
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LocalPlayer and plr.Character then
					task.spawn(executeFlingTeleport, plr, function() end)
					task.wait(1.6)
				end
			end
			notify("已对全部玩家执行完毕")
		end,
	})
end

return M
