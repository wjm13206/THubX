local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local ClickDelete = {}
ClickDelete.Title = "点击删除"

local Players = Services.Players
local UserInputService = Services.UserInputService

local enabled = false
local conn = nil

local function setEnabled(on)
	if on == enabled then
		return
	end
	enabled = on
	if on then
		local player = Players.LocalPlayer
		local mouse = player:GetMouse()
		conn = mouse.Button1Down:Connect(function()
			if not enabled then
				return
			end
			local held = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
			if not held then
				return
			end
			local target = mouse.Target
			if not target then
				return
			end
			if target:IsA("BasePart") then
				local character = player.Character
				if character and target:IsDescendantOf(character) then
					return
				end
				target:Destroy()
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

function ClickDelete.Init(Tabs, ctx)
	local section = Tabs.Utility:Section({ Title = "点击删除" })
	section:Toggle({
		Title = "Ctrl+点击删除部件",
		Icon = "eraser",
		Value = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
end

return ClickDelete
