local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local ClickInspect = {}
ClickInspect.Title = "点击查看"

local Players = Services.Players
local UserInputService = Services.UserInputService

local enabled = false
local conn = nil

local function ctrlHeld()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
end

local function setEnabled(on)
	if on == enabled then
		return
	end
	enabled = on
	if on then
		local mouse = Players.LocalPlayer:GetMouse()
		conn = mouse.Button1Down:Connect(function()
			if not enabled or not ctrlHeld() then
				return
			end
			local target = mouse.Target
			if not target then
				return
			end
			print("========== 部件信息 ==========")
			print("名称: " .. target.Name)
			print("类型: " .. target.ClassName)
			print("路径: " .. target:GetFullName())
			if target:IsA("BasePart") then
				print("位置: " .. tostring(target.Position))
				print("大小: " .. tostring(target.Size))
				print("材质: " .. tostring(target.Material))
				print("锚定: " .. tostring(target.Anchored))
				print("碰撞: " .. tostring(target.CanCollide))
				print("透明度 " .. tostring(target.Transparency))
			end
			print("==============================")
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

function ClickInspect.Init(Tabs, ctx)

	Tabs.Interact:Toggle({
		Title = "Ctrl+点击打印部件信息",
		Icon = "info",
		Value = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
end

return ClickInspect
