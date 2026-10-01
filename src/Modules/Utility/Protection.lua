local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "防护系统"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local RunService = Services.RunService
local CoreGui = Services.CoreGui

local LocalPlayer = Players.LocalPlayer

-- 防击倒
local antiFallConn = nil
local antiFallOn = false
local function attachAntiFall(hum)
	if antiFallConn then
		antiFallConn:Disconnect()
	end
	antiFallConn = hum.StateChanged:Connect(function(_, newState)
		if antiFallOn then
			if newState == Enum.HumanoidStateType.FallingDown
				or newState == Enum.HumanoidStateType.Ragdoll
				or newState == Enum.HumanoidStateType.Freefall then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
	end)
end

local function setAntiFall(on)
	antiFallOn = on
	if on then
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildWhichIsA("Humanoid")
		if hum then
			attachAntiFall(hum)
		end
	else
		if antiFallConn then
			antiFallConn:Disconnect()
			antiFallConn = nil
		end
	end
end

-- 防虚空伤害（NaN 技巧）
local savedFallenHeight = nil
local voidOn = false
local function setAntiVoid(on)
	voidOn = on
	if on then
		if savedFallenHeight == nil then
			savedFallenHeight = Workspace.FallenPartsDestroyHeight
		end
		Workspace.FallenPartsDestroyHeight = 0 / 0
	else
		if savedFallenHeight ~= nil then
			Workspace.FallenPartsDestroyHeight = savedFallenHeight
			savedFallenHeight = nil
		end
	end
end

-- 防死亡
local antiDeadConn = nil
local antiDeadOn = false
local function applyAntiDead(hum)
	if hum and hum.Parent and hum:GetStateEnabled(Enum.HumanoidStateType.Dead) then
		hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end
end

local function setAntiDead(on)
	antiDeadOn = on
	if on then
		local char = LocalPlayer.Character
		if char then
			applyAntiDead(char:FindFirstChildWhichIsA("Humanoid"))
		end
		local last = 0
		antiDeadConn = RunService.Stepped:Connect(function()
			if not antiDeadOn then
				return
			end
			local now = tick()
			if now - last < 1 then
				return
			end
			last = now
			local c = LocalPlayer.Character
			if c then
				applyAntiDead(c:FindFirstChildWhichIsA("Humanoid"))
			end
		end)
	else
		if antiDeadConn then
			antiDeadConn:Disconnect()
			antiDeadConn = nil
		end
		local char = LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildWhichIsA("Humanoid")
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
			end
		end
	end
end

-- 防挂机（默认开启）
local afkConn = nil
local disabledIdleConns = {}
local function setAntiAFK(on)
	if on then
		if afkConn then
			return
		end
		local disabledAny = false
		pcall(function()
			local getconns = getconnections or get_signal_cons
			if getconns then
				for _, conn in ipairs(getconns(LocalPlayer.Idled)) do
					pcall(function()
						conn:Disable()
					end)
					table.insert(disabledIdleConns, conn)
					disabledAny = true
				end
			end
		end)
		if disabledAny then
			afkConn = LocalPlayer.Idled:Connect(function() end)
			return
		end
		afkConn = LocalPlayer.Idled:Connect(function()
			local vimOk, vim = pcall(function()
				return Services.Get("VirtualInputManager")
			end)
			if vimOk and vim then
				pcall(function()
					vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
					vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
				end)
			else
				pcall(function()
					Services.Get("VirtualUser"):CaptureController()
					Services.Get("VirtualUser"):ClickButton2(Vector2.new())
				end)
			end
		end)
	else
		if afkConn then
			afkConn:Disconnect()
			afkConn = nil
		end
		for _, conn in ipairs(disabledIdleConns) do
			pcall(function()
				conn:Enable()
			end)
		end
		table.clear(disabledIdleConns)
	end
end

-- 传送后保持
local keepConn = nil
local teleportCheck = false
local function setKeepTHub(on)
	if on then
		if keepConn then
			return
		end
		teleportCheck = false
		keepConn = LocalPlayer.OnTeleport:Connect(function(_)
			if teleportCheck then
				return
			end
			teleportCheck = true
			local code = [[
				if not game:IsLoaded() then game.Loaded:Wait() end
				local cloneref = cloneref or clonereference or function(obj) return obj end
				loadstring(cloneref(game):HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/main.lua"))()
			]]
			if queueteleport then
				queueteleport(code)
			elseif queueonteleport then
				queueonteleport(code)
			elseif queue_on_teleport then
				queue_on_teleport(code)
			end
		end)
	else
		if keepConn then
			keepConn:Disconnect()
			keepConn = nil
		end
	end
end

-- 禁用购买提示框
local function setPurchasePromptDisabled(off)
	pcall(function()
		local app = CoreGui:FindFirstChild("PurchasePromptApp")
		if app then
			app.Enabled = not off
		end
	end)
end

-- 禁用游戏暂停
local pauseConn = nil
local function setNetworkPauseDisabled(on)
	if on then
		if pauseConn then
			return
		end
		pcall(function()
			local gui = CoreGui:FindFirstChild("RobloxGui")
			if gui then
				local node = gui:FindFirstChild("CoreScripts/NetworkPause", true)
				if node then
					node:Destroy()
				end
				pauseConn = gui.ChildAdded:Connect(function(obj)
					if obj.Name == "NetworkPause" or obj.Name == "CoreScripts/NetworkPause" then
						obj:Destroy()
					end
				end)
			end
		end)
	else
		if pauseConn then
			pauseConn:Disconnect()
			pauseConn = nil
		end
	end
end

-- 交互禁用（触点 / 点击 / 可交互）
local disabledTypes = { TouchTransmitter = false, ClickDetector = false, ProximityPrompt = false }
local interactBackup = {}
local interactConn = nil

local function applyInteractSetting(inst, className, disabled)
	if className == "ClickDetector" and inst:IsA("ClickDetector") then
		if disabled then
			if interactBackup[inst] == nil then
				interactBackup[inst] = inst.MaxActivationDistance
			end
			inst.MaxActivationDistance = 0
		else
			local old = interactBackup[inst]
			inst.MaxActivationDistance = old ~= nil and old or 32
			interactBackup[inst] = nil
		end
	elseif className == "TouchTransmitter" and inst:IsA("TouchTransmitter") then
		local part = inst:FindFirstAncestorWhichIsA("BasePart")
		if part then
			if disabled then
				if interactBackup[inst] == nil then
					interactBackup[inst] = part.CanTouch
				end
				part.CanTouch = false
			else
				local old = interactBackup[inst]
				if old ~= nil then
					part.CanTouch = old
				else
					part.CanTouch = true
				end
				interactBackup[inst] = nil
			end
		end
	elseif className == "ProximityPrompt" and inst:IsA("ProximityPrompt") then
		inst.Enabled = not disabled
	end
end

local function refreshInteractConn()
	local need = disabledTypes.TouchTransmitter or disabledTypes.ClickDetector or disabledTypes.ProximityPrompt
	if need and not interactConn then
		interactConn = Workspace.DescendantAdded:Connect(function(inst)
			local cls = inst.ClassName
			if disabledTypes[cls] then
				pcall(applyInteractSetting, inst, cls, true)
			end
		end)
	elseif not need and interactConn then
		interactConn:Disconnect()
		interactConn = nil
	end
end

local function setInteractDisabled(className, off)
	disabledTypes[className] = off
	for _, inst in ipairs(Workspace:GetDescendants()) do
		if inst.ClassName == className then
			pcall(applyInteractSetting, inst, className, off)
		end
	end
	refreshInteractConn()
end

-- 管理员检测
local staffConn = nil
local staffKeywords = { "mod", "admin", "staff", "dev", "owner", "founder", "manager", "supervisor" }
local function checkStaff(player, notify)
	if game.CreatorType ~= Enum.CreatorType.Group then
		return
	end
	local ok, role = pcall(function()
		return player:GetRoleInGroup(game.CreatorId)
	end)
	if ok and role then
		local lower = string.lower(tostring(role))
		for _, kw in ipairs(staffKeywords) do
			if string.find(lower, kw, 1, true) then
				notify(player.DisplayName .. " 可能是 " .. tostring(role))
				return
			end
		end
	end
end

-- 死亡播报
local deathConns = {}
local deathOn = false
local function clearDeathConns()
	for _, c in pairs(deathConns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(deathConns)
end

local function watchPlayerDeath(player, notify)
	local function hookChar(char)
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if hum then
			deathConns[player.UserId .. "_died"] = hum.Died:Connect(function()
				notify(player.DisplayName .. " 死亡了")
			end)
		end
	end
	local char = player.Character
	if char then
		hookChar(char)
	end
	deathConns[player.UserId .. "_added"] = player.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid")
		task.wait(0.2)
		if deathOn then
			hookChar(char)
		end
	end)
end

local function setDeathAnnounce(on, notify)
	deathOn = on
	clearDeathConns()
	if on then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer then
				watchPlayerDeath(plr, notify)
			end
		end
	end
end

-- 聊天重发标志（由 ChatControl 消费）
M.ChatResend = false

Unload.OnUnload(function()
	setAntiFall(false)
	setAntiVoid(false)
	setAntiDead(false)
	setAntiAFK(false)
	setKeepTHub(false)
	setPurchasePromptDisabled(false)
	setNetworkPauseDisabled(false)
	setInteractDisabled("TouchTransmitter", false)
	setInteractDisabled("ClickDetector", false)
	setInteractDisabled("ProximityPrompt", false)
	if staffConn then
		staffConn:Disconnect()
		staffConn = nil
	end
	clearDeathConns()
	M.ChatResend = false
end)

function M.Init(Tabs, ctx)
	local WindUI = ctx.WindUI
	local function notify(text)
		if WindUI then
			WindUI:Notify({ Title = "提醒", Content = text, Duration = 5 })
		end
	end

	setAntiAFK(true)

	local section = Tabs.Utility:Section({ Title = "防护系统" })
	section:Toggle({
		Title = "防挂机",
		Icon = "shield",
		Value = true,
		Callback = function(state)
			setAntiAFK(state)
		end,
	})
	section:Toggle({
		Title = "传送后保持 THubX",
		Icon = "repeat",
		Value = false,
		Callback = function(state)
			setKeepTHub(state)
		end,
	})
	section:Toggle({
		Title = "防击倒",
		Icon = "shield",
		Value = false,
		Callback = function(state)
			setAntiFall(state)
		end,
	})
	section:Toggle({
		Title = "防虚空伤害",
		Icon = "shield",
		Value = false,
		Callback = function(state)
			setAntiVoid(state)
		end,
	})
	section:Toggle({
		Title = "防死亡",
		Icon = "shield-plus",
		Value = false,
		Callback = function(state)
			setAntiDead(state)
		end,
	})
	section:Toggle({
		Title = "禁用购买提示框",
		Icon = "shopping-cart",
		Value = false,
		Callback = function(state)
			setPurchasePromptDisabled(state)
		end,
	})
	section:Toggle({
		Title = "禁用游戏暂停",
		Icon = "pause",
		Value = false,
		Callback = function(state)
			setNetworkPauseDisabled(state)
		end,
	})
	section:Toggle({
		Title = "禁用触点实例",
		Icon = "ban",
		Value = false,
		Callback = function(state)
			setInteractDisabled("TouchTransmitter", state)
			notify(state and "已禁用所有触点" or "已恢复所有触点")
		end,
	})
	section:Toggle({
		Title = "禁用点击触发实例",
		Icon = "ban",
		Value = false,
		Callback = function(state)
			setInteractDisabled("ClickDetector", state)
		end,
	})
	section:Toggle({
		Title = "禁用可交互实例",
		Icon = "ban",
		Value = false,
		Callback = function(state)
			setInteractDisabled("ProximityPrompt", state)
		end,
	})
	section:Toggle({
		Title = "管理员检测",
		Icon = "siren",
		Value = false,
		Callback = function(state)
			if state then
				for _, plr in ipairs(Players:GetPlayers()) do
					checkStaff(plr, notify)
				end
				staffConn = Players.PlayerAdded:Connect(function(plr)
					checkStaff(plr, notify)
				end)
			else
				if staffConn then
					staffConn:Disconnect()
					staffConn = nil
				end
			end
		end,
	})
	section:Toggle({
		Title = "死亡播报",
		Icon = "megaphone",
		Value = false,
		Callback = function(state)
			setDeathAnnounce(state, notify)
		end,
	})
	section:Toggle({
		Title = "聊天重发",
		Icon = "repeat",
		Value = false,
		Callback = function(state)
			M.ChatResend = state
		end,
	})
	section:Button({
		Title = "触发所有触点实例",
		Icon = "zap",
		Callback = function()
			if not firetouchinterest then
				notify("执行器不支持此功能")
				return
			end
			local char = LocalPlayer.Character
			local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart"))
			if not root then
				return
			end
			for _, v in ipairs(Workspace:GetDescendants()) do
				if v:IsA("TouchTransmitter") then
					local x = v:FindFirstAncestorWhichIsA("BasePart")
					if x then
						task.spawn(function()
							pcall(function()
								firetouchinterest(x, root, 1)
								task.wait()
								firetouchinterest(x, root, 0)
							end)
						end)
					end
				end
			end
		end,
	})
	section:Button({
		Title = "触发所有点击触发实例",
		Icon = "mouse-pointer-click",
		Callback = function()
			if not fireclickdetector then
				notify("执行器不支持此功能")
				return
			end
			for _, v in ipairs(Workspace:GetDescendants()) do
				if v:IsA("ClickDetector") then
					pcall(fireclickdetector, v)
				end
			end
		end,
	})
	section:Button({
		Title = "触发所有可交互实例",
		Icon = "hand",
		Callback = function()
			if not fireproximityprompt then
				notify("执行器不支持此功能")
				return
			end
			for _, v in ipairs(Workspace:GetDescendants()) do
				if v:IsA("ProximityPrompt") then
					pcall(fireproximityprompt, v)
				end
			end
		end,
	})
end

return M
