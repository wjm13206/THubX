local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")
local Confirm = require("../../Core/Confirm")

local M = {}
M.Title = "数据修改"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local Lighting = Services.Get("Lighting")
local TweenService = Services.TweenService
local StarterGui = Services.StarterGui

local LocalPlayer = Players.LocalPlayer

local spawnPos = nil
local lastDeath = nil
local deathConn = nil
local charAddedConn = nil
local recordEnabled = false

local function getHum()
	local char = LocalPlayer.Character
	if not char then
		return nil
	end
	return char:FindFirstChildWhichIsA("Humanoid")
end

local function getRoot()
	local char = LocalPlayer.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function hookDeath(char)
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if hum then
		if deathConn then
			deathConn:Disconnect()
		end
		deathConn = hum.Died:Connect(function()
			local root = getRoot()
			if root then
				lastDeath = root.CFrame
			end
		end)
	end
end

local function startRecording()
	if recordEnabled then return end
	recordEnabled = true
	if LocalPlayer.Character then
		hookDeath(LocalPlayer.Character)
	end
	charAddedConn = LocalPlayer.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart")
		hookDeath(char)
		if spawnPos ~= nil then
			task.wait(0.1)
			local root = getRoot()
			if root then
				root.CFrame = spawnPos
			end
		end
	end)
end

local function stopRecording()
	recordEnabled = false
	if deathConn then
		deathConn:Disconnect()
		deathConn = nil
	end
	if charAddedConn then
		charAddedConn:Disconnect()
		charAddedConn = nil
	end
end

local function respawn()
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildWhichIsA("Humanoid")
	if hum then
		hum:ChangeState(Enum.HumanoidStateType.Dead)
		hum.Health = 0
	end
	task.wait(0.2)
	char = LocalPlayer.Character
	if char then
		local h = char:FindFirstChildWhichIsA("Humanoid")
		if h then
			h:Destroy()
		end
		for _, inst in ipairs(char:GetDescendants()) do
			if inst:IsA("BasePart") then
				inst:Destroy()
			end
		end
	end
end

local function respawn2()
	local char = LocalPlayer.Character
	local cam = Workspace.CurrentCamera
	if cam then
		cam.CameraType = Enum.CameraType.Scriptable
	end
	local root = getRoot()
	if root then
		root.CFrame = CFrame.new(0, -500, 0)
	end
	task.wait(0.5)
	local hum = getHum()
	if hum then
		hum.Health = 0
	end
	task.wait(1)
	if cam then
		cam.CameraType = Enum.CameraType.Custom
	end
end

local function refresh()
	local root = getRoot()
	local cam = Workspace.CurrentCamera
	local savedCF = root and root.CFrame or nil
	local savedCamCF = cam and cam.CFrame or nil
	respawn()
	if savedCF then
		LocalPlayer.CharacterAdded:Wait()
		task.wait(0.3)
		local newRoot = getRoot()
		if newRoot then
			newRoot.CFrame = savedCF
		end
		if savedCamCF and Workspace.CurrentCamera then
			Workspace.CurrentCamera.CFrame = savedCamCF
		end
	end
end

local function randomString()
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local s = ""
	for _ = 1, 12 do
		local i = math.random(1, #chars)
		s = s .. string.sub(chars, i, i)
	end
	return s
end

Unload.OnUnload(function()
	if deathConn then
		deathConn:Disconnect()
		deathConn = nil
	end
	if charAddedConn then
		charAddedConn:Disconnect()
		charAddedConn = nil
	end
end)

function M.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Data, M.Title, { Icon = "ghost" })
	local WindUI = ctx.WindUI
	local function notify(title, text)
		if WindUI then
			WindUI:Notify({ Title = title, Content = text, Duration = 3 })
		end
	end


	folder:Toggle({
		Title = "记录死亡位置",
		Icon = "ghost",
		Value = false,
		Callback = function(state)
			if state then
				startRecording()
			else
				stopRecording()
			end
		end,
	})
	folder:Button({
		Title = "回满血",
		Icon = "heart-pulse",
		Callback = function()
			local hum = getHum()
			if hum then
				hum.Health = hum.MaxHealth
			end
		end,
	})
	folder:Button({
		Title = "自杀",
		Icon = "skull",
		Callback = function()
			local hum = getHum()
			if hum then
				hum.Health = 0
			end
		end,
	})
	folder:Button({
		Title = "强制自杀",
		Icon = "skull",
		Callback = function()
			respawn()
		end,
	})
	folder:Button({
		Title = "强制自杀2",
		Icon = "skull",
		Callback = function()
			respawn2()
		end,
	})
	folder:Button({
		Title = "原地重生",
		Icon = "rotate-ccw",
		Callback = function()
			refresh()
		end,
	})
	folder:Button({
		Title = "设置当前位置为重生点",
		Icon = "map-pin",
		Callback = function()
			local root = getRoot()
			if root then
				spawnPos = root.CFrame
				notify("重生点", "已设置当前位置为重生点")
			end
		end,
	})
	folder:Button({
		Title = "恢复默认重生点",
		Icon = "map-pin-off",
		Callback = function()
			spawnPos = nil
			notify("重生点", "已恢复默认重生点")
		end,
	})
	folder:Button({
		Title = "回到最后的死亡点",
		Icon = "ghost",
		Callback = function()
			if lastDeath ~= nil then
				local root = getRoot()
				if root then
					root.CFrame = lastDeath
				end
			else
				notify("错误", "没有记录的死亡点")
			end
		end,
	})
	folder:Button({
		Title = "获取游戏内全部工具",
		Icon = "briefcase",
		Callback = function()
			local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
			if not backpack then
				return
			end
			for _, src in ipairs({ Lighting, Services.Get("ReplicatedStorage") }) do
				for _, inst in ipairs(src:GetDescendants()) do
					if inst:IsA("Tool") or inst:IsA("HopperBin") then
						pcall(function()
							inst:Clone().Parent = backpack
						end)
					end
				end
			end
		end,
	})
	folder:Button({
		Title = "移除全部工具",
		Icon = "trash-2",
		Callback = function()
			Confirm.Show(ctx.Window, {
				Title = "移除全部工具",
				Content = "确定要删除背包和手上所有工具吗？此操作不可恢复。",
				ConfirmText = "删除",
				OnConfirm = function()
					local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
					if backpack then
						for _, inst in ipairs(backpack:GetChildren()) do
							if inst:IsA("Tool") or inst:IsA("HopperBin") then
								inst:Destroy()
							end
						end
					end
					local char = LocalPlayer.Character
					if char then
						for _, inst in ipairs(char:GetChildren()) do
							if inst:IsA("Tool") or inst:IsA("HopperBin") then
								inst:Destroy()
							end
						end
					end
				end,
			})
		end,
	})
	folder:Button({
		Title = "丢弃手中工具",
		Icon = "hand",
		Callback = function()
			local char = LocalPlayer.Character
			if char then
				for _, inst in ipairs(char:GetChildren()) do
					if inst:IsA("Tool") then
						inst.Parent = Workspace
					end
				end
			end
			notify("掉落工具", "已丢弃手中工具")
		end,
	})
	folder:Button({
		Title = "丢弃全部工具",
		Icon = "hand",
		Callback = function()
			Confirm.Show(ctx.Window, {
				Title = "丢弃全部工具",
				Content = "确定要把所有工具丢到地上吗？",
				ConfirmText = "丢弃",
				OnConfirm = function()
					local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
					local char = LocalPlayer.Character
					if backpack and char then
						for _, inst in ipairs(backpack:GetChildren()) do
							if inst:IsA("Tool") then
								inst.Parent = char
							end
						end
						task.wait()
						for _, inst in ipairs(char:GetChildren()) do
							if inst:IsA("Tool") then
								inst.Parent = Workspace
							end
						end
					end
					notify("掉落工具", "已丢弃全部工具")
				end,
			})
		end,
	})
	folder:Button({
		Title = "获得点击传送工具",
		Icon = "mouse-pointer",
		Callback = function()
			local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
			if not backpack then
				return
			end
			if backpack:FindFirstChild("手持点击传送") then
				notify("提示", "点击传送工具已存在")
				return
			end
			local mouse = LocalPlayer:GetMouse()
			local tool = Instance.new("Tool")
			tool.RequiresHandle = false
			tool.Name = "手持点击传送"
			tool.Parent = backpack
			tool.Activated:Connect(function()
				local pos = mouse.Hit + Vector3.new(0, 2.5, 0)
				local root = getRoot()
				if root then
					root.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
				end
			end)
		end,
	})
	folder:Button({
		Title = "重新加入当前房间",
		Icon = "refresh-cw",
		Callback = function()
			Services.Get("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end,
	})
	folder:Button({
		Title = "切换角色为R6",
		Icon = "person-standing",
		Callback = function()
			pcall(function()
				local desc = Services.Get("Players"):GetHumanoidDescriptionFromCurrentOutfit(LocalPlayer.UserId)
				local avatarEditor = Services.Get("AvatarEditorService")
				avatarEditor:PromptSaveAvatar(desc, Enum.HumanoidRigType.R6)
			end)
		end,
	})
	folder:Button({
		Title = "切换角色为R15",
		Icon = "person-standing",
		Callback = function()
			pcall(function()
				local desc = Services.Get("Players"):GetHumanoidDescriptionFromCurrentOutfit(LocalPlayer.UserId)
				local avatarEditor = Services.Get("AvatarEditorService")
				avatarEditor:PromptSaveAvatar(desc, Enum.HumanoidRigType.R15)
			end)
		end,
	})
	folder:Button({
		Title = "切换时间为白天",
		Icon = "sun",
		Callback = function()
			TweenService:Create(Lighting, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ClockTime = 14,
				GeographicLatitude = 41.73,
			}):Play()
		end,
	})
	folder:Button({
		Title = "切换时间为黑夜",
		Icon = "moon",
		Callback = function()
			TweenService:Create(Lighting, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ClockTime = 2,
				GeographicLatitude = 41.73,
			}):Play()
		end,
	})
	folder:Button({
		Title = "打印当前坐标",
		Icon = "map-pin",
		Callback = function()
			local root = getRoot()
			if root then
				local p = root.Position
				print(string.format("[THubX] 玩家坐标: (%.2f, %.2f, %.2f)", p.X, p.Y, p.Z))
				notify("坐标", string.format("(%.1f, %.1f, %.1f) 已输出到控制台", p.X, p.Y, p.Z))
			end
		end,
	})
	folder:Button({
		Title = "开启控制台界面",
		Icon = "terminal",
		Callback = function()
			StarterGui:SetCore("DevConsoleVisible", true)
		end,
	})
	folder:Button({
		Title = "启用所有ROBLOXUI",
		Icon = "layout-grid",
		Callback = function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		end,
	})
	folder:Button({
		Title = "获取建筑工具",
		Icon = "hammer",
		Callback = function()
			local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
			if not backpack then
				return
			end
			local count = 0
			for _, v in ipairs(backpack:GetChildren()) do
				if v:IsA("HopperBin") then
					count = count + 1
				end
			end
			if count >= 4 then
				notify("提示", "背包中已有建筑工具")
				return
			end
			for i = 1, 4 do
				local bin = Instance.new("HopperBin")
				bin.BinType = i
				bin.Name = randomString()
				bin.Parent = backpack
			end
		end,
	})
	folder:Button({
		Title = "终止当前游戏进程",
		Icon = "power",
		Callback = function()
			Confirm.Show(ctx.Window, {
				Title = "终止游戏进程",
				Content = "确定要关闭当前游戏吗？未保存的进度会丢失。",
				ConfirmText = "终止",
				OnConfirm = function()
					game:Shutdown()
				end,
			})
		end,
	})
end

return M
