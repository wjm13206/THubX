local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local GuiDeleter = {}
GuiDeleter.Title = "界面删除"

local Players = Services.Players
local UserInputService = Services.UserInputService

local enabled = false
local bindKey = Enum.KeyCode.Backspace
local conn = nil

local function deleteAtCursor()
	local player = Players.LocalPlayer
	local mouse = player:GetMouse()
	local playerGui = player:FindFirstChildWhichIsA("PlayerGui")
	if not playerGui then
		return
	end
	pcall(function()
		local guis = playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
		for _, gui in ipairs(guis) do
			if gui.Visible then
				gui:Destroy()
			end
		end
	end)
end

local function setEnabled(on)
	if on == enabled then
		return
	end
	enabled = on
	if on then
		conn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.KeyCode == bindKey and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				deleteAtCursor()
			end
		end)
	else
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function GuiDeleter.Init(Tabs, ctx)
	local settings = ctx.FeatureSettings("界面删除")
	Tabs.Interact:Toggle({
		Title = "按键删除指向界面",
		Icon = "layout-template",
		Value = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
	settings:Keybind({
		Title = "删除按键",
		Icon = "keyboard",
		Value = "Backspace",
		Callback = function(v)
			local code = Enum.KeyCode[v]
			if code then
				bindKey = code
			end
		end,
	})
end

return GuiDeleter
