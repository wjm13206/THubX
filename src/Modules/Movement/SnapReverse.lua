local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local SnapReverse = {}
SnapReverse.Title = "视角反转"

local UserInputService = Services.UserInputService

local enabled = false
local currentKeyBind = Enum.KeyCode.G
local inputBeganConn = nil

local function snapCameraReverse()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local reversedLook = -camera.CFrame.LookVector
	camera.CFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + reversedLook)
end

local function onInputBegan(input, gameProcessed)
	if not enabled then
		return
	end
	if gameProcessed then
		return
	end
	if input.KeyCode == currentKeyBind then
		snapCameraReverse()
	end
end

local function setEnabled(state)
	if state then
		if enabled then
			return
		end
		enabled = true
		inputBeganConn = UserInputService.InputBegan:Connect(onInputBegan)
	else
		if not enabled then
			return
		end
		enabled = false
		if inputBeganConn then
			inputBeganConn:Disconnect()
			inputBeganConn = nil
		end
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function SnapReverse.Init(Tabs, ctx)
	local pendingKey = "G"
	local section = Tabs.Movement:Section({Title = "视角反转"})
	section:Toggle({
		Title = "启用视角反转 (按G反转视角)",
		Icon = "refresh-ccw",
		Default = false,
		Callback = function(state)
			setEnabled(state)
		end,
	})
	section:Input({
		Title = "反转按键",
		Icon = "keyboard",
		Placeholder = "输入按键名，如 G",
		Callback = function(v)
			if type(v) == "string" and v ~= "" then
				pendingKey = v
			end
		end,
	})
	section:Button({
		Title = "应用按键",
		Icon = "check",
		Callback = function()
			local ok, kc = pcall(function()
				return Enum.KeyCode[pendingKey]
			end)
			if ok and typeof(kc) == "EnumItem" then
				currentKeyBind = kc
			end
		end,
	})
end

return SnapReverse
