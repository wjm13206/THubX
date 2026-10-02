local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Hanker = {}
Hanker.Title = "恶劣功能"

local Players = Services.Players
local Workspace = Services.Get("Workspace")

local WindUIRef = nil
local function notify(title, content)
	if WindUIRef then
		pcall(function()
			WindUIRef:Notify({ Title = title, Content = content, Duration = 3 })
		end)
	end
end

-- 打飞机工具（移植自老项目 getjerktool，补了卸载清理）
local jerkTool = nil
local jerkConns = {}
local jerkRunning = false

local function stopJerk()
	jerkRunning = false
	for _, c in ipairs(jerkConns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(jerkConns)
	if jerkTool then
		pcall(function()
			jerkTool:Destroy()
		end)
		jerkTool = nil
	end
end

local function getJerkTool()
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	if not humanoid or not backpack then
		notify("打飞机工具", "未找到角色或背包")
		return
	end
	if jerkTool and jerkTool.Parent then
		notify("打飞机工具", "已经获得过了")
		return
	end
	stopJerk()

	local tool = Instance.new("Tool")
	tool.Name = "打飞机工具 "
	tool.ToolTip = "装备后播放动作"
	tool.RequiresHandle = false
	tool.Parent = backpack
	jerkTool = tool

	local jorkin = false
	local track = nil
	local function stopTomfoolery()
		jorkin = false
		if track then
			pcall(function()
				track:Stop()
			end)
			track = nil
		end
	end
	table.insert(jerkConns, tool.Equipped:Connect(function()
		jorkin = true
	end))
	table.insert(jerkConns, tool.Unequipped:Connect(stopTomfoolery))
	table.insert(jerkConns, humanoid.Died:Connect(stopTomfoolery))

	jerkRunning = true
	task.spawn(function()
		while jerkRunning and jerkTool and jerkTool.Parent do
			task.wait()
			if not jorkin then
				continue
			end
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not hum then
				continue
			end
			local isR15 = hum.RigType == Enum.HumanoidRigType.R15
			if not track then
				local okAnim, anim = pcall(function()
					local a = Instance.new("Animation")
					a.AnimationId = (not isR15) and "rbxassetid://72042024" or "rbxassetid://698251653"
					return a
				end)
				if okAnim and anim then
					local okTrack, t = pcall(function()
						return hum:LoadAnimation(anim)
					end)
					if okTrack then
						track = t
					end
				end
			end
			if track then
				pcall(function()
					track:Play()
					track:AdjustSpeed(isR15 and 0.7 or 0.65)
					track.TimePosition = 0.6
				end)
				task.wait(0.1)
				local t0 = tick()
				while jerkRunning and track and track.TimePosition < ((not isR15) and 0.65 or 0.7) and tick() - t0 < 5 do
					task.wait(0.1)
				end
				if track then
					pcall(function()
						track:Stop()
					end)
					track = nil
				end
			else
				task.wait(0.5)
			end
		end
		stopTomfoolery()
	end)
	notify("打飞机工具", "已放入背包，装备后生效")
end

-- 击杀贴身者（移植自老项目 fakeout）：
-- 带自己瞬移到虚空下 25 码停 1 秒，贴身的人掉落摔死，再传回原位
local function fakeout()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		notify("击杀贴身", "未找到角色")
		return
	end
	local oldpos = root.CFrame
	local origHeight = Workspace.FallenPartsDestroyHeight
	local needRestore = false
	if origHeight == origHeight then
		Workspace.FallenPartsDestroyHeight = 0 / 0
		needRestore = true
	end
	root.CFrame = CFrame.new(Vector3.new(0, origHeight - 25, 0))
	task.wait(1)
	if root.Parent then
		root.CFrame = oldpos
	end
	if needRestore then
		Workspace.FallenPartsDestroyHeight = origHeight
	end
end

Unload.OnUnload(function()
	pcall(stopJerk)
end)

function Hanker.Init(Tabs, ctx)
	WindUIRef = ctx.WindUI
	Tabs.Hanker:Button({
		Title = "警告：使用此部分功能会导致封号",
		Icon = "triangle-alert",
		Callback = function()
			notify("警告", "使用此部分功能会导致封号，请谨慎使用")
		end,
	})
	Tabs.Hanker:Button({
		Title = "获得打飞机工具",
		Icon = "wrench",
		Callback = function()
			getJerkTool()
		end,
	})
	Tabs.Hanker:Button({
		Title = "击杀贴在你身上的人",
		Icon = "skull",
		Callback = function()
			fakeout()
		end,
	})
end

return Hanker
