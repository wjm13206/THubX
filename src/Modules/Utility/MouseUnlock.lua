local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local MouseUnlock = {}
MouseUnlock.Title = "鼠标解锁"

local isEnabled = false
local isUnlocked = false
local originalMouseBehavior = nil
local heartbeatConnection = nil
local keyStates = { K = false, L = false }
local toggleTriggered = false
local beganConn = nil
local endedConn = nil

local function enforceUnlock()
	if not isUnlocked then
		return
	end
	if Services.UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
		Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

local function doUnlock()
	if isUnlocked then
		return
	end
	if originalMouseBehavior == nil then
		originalMouseBehavior = Services.UserInputService.MouseBehavior
	end
	Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	isUnlocked = true
	if not heartbeatConnection then
		heartbeatConnection = Services.RunService.Heartbeat:Connect(enforceUnlock)
	end
end

local function doRestore()
	if not isUnlocked then
		return
	end
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
	if originalMouseBehavior then
		Services.UserInputService.MouseBehavior = originalMouseBehavior
	else
		Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	isUnlocked = false
end

local function onInputBegan(input, gameProcessed)
	if not isEnabled or gameProcessed then
		return
	end
	if Services.UserInputService:GetFocusedTextBox() then
		return
	end
	local key = input.KeyCode
	if key == Enum.KeyCode.K and Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		if not toggleTriggered then
			toggleTriggered = true
			if isUnlocked then
				doRestore()
			else
				doUnlock()
			end
		end
	end
end

local function onInputEnded(input)
	if not isEnabled then
		return
	end
	local key = input.KeyCode
	if key == Enum.KeyCode.K then
		toggleTriggered = false
	end
end

local function setEnabled(on)
	if on and isEnabled then
		return
	end
	if not on and not isEnabled then
		return
	end
	isEnabled = on
	keyStates.K = false
	keyStates.L = false
	toggleTriggered = false
	if on then
		beganConn = Services.UserInputService.InputBegan:Connect(onInputBegan)
		endedConn = Services.UserInputService.InputEnded:Connect(onInputEnded)
	else
		if beganConn then
			beganConn:Disconnect()
			beganConn = nil
		end
		if endedConn then
			endedConn:Disconnect()
			endedConn = nil
		end
		if isUnlocked then
			doRestore()
		end
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function MouseUnlock.Init(Tabs, ctx)
	local section = Tabs.Utility:Section({ Title = "鼠标解锁" })
	section:Toggle({
		Title = "启用 (Ctrl+K 切换解锁)",
		Icon = "mouse",
		Value = false,
		Callback = function(state)
			setEnabled(state)
		end,
	})
	section:Button({
		Title = "立即解锁 / 恢复",
		Icon = "unlock",
		Callback = function()
			if isUnlocked then
				doRestore()
				ctx.WindUI:Notify({ Title = "鼠标解锁", Content = "已恢复", Duration = 3 })
			else
				doUnlock()
				ctx.WindUI:Notify({ Title = "鼠标解锁", Content = "已解锁", Duration = 3 })
			end
		end,
	})
end

return MouseUnlock
