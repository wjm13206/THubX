local Services = require("../../Core/Services")

local Gifts = {}
Gifts.Title = "圣诞礼物闪现"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local player = Players.LocalPlayer
local duration = 0.5

local function flashPresents()
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end
	local mainModel = Workspace:FindFirstChild("XMas_PresentHunt%")
		or Workspace:FindFirstChild("XMas_PresentHunt")
	if not mainModel then
		return false
	end
	local presentsFolder = mainModel:FindFirstChild("Presents")
	if not presentsFolder then
		return false
	end
	local giftsData = {}
	for i = 1, 100 do
		local gift = presentsFolder:FindFirstChild(tostring(i))
		if gift and gift:IsA("Model") then
			table.insert(giftsData, { gift = gift, originalCFrame = gift:GetPivot() })
		end
	end
	if #giftsData == 0 then
		return false
	end
	local flashCFrame = CFrame.new(rootPart.Position + Vector3.new(0, 2, 0))
	for _, data in ipairs(giftsData) do
		data.gift:PivotTo(flashCFrame)
	end
	task.wait(duration)
	for _, data in ipairs(giftsData) do
		if data.gift and data.gift.Parent then
			data.gift:PivotTo(data.originalCFrame)
		end
	end
	return true
end

function Gifts.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Games, Gifts.Title, { Icon = "timer" })
	local WindUI = ctx.WindUI
	folder:Slider({
		Title = "停留时间(秒)",
		Icon = "timer",
		Step = 1,
		Value = { Min = 1, Max = 20, Default = 5 },
		Callback = function(v)
			duration = v / 10
		end,
	})
	folder:Button({
		Title = "礼物闪现到脚下",
		Icon = "gift",
		Callback = function()
			task.spawn(function()
				if flashPresents() then
					WindUI:Notify({ Title = "礼物", Content = "已归位", Duration = 3 })
				else
					WindUI:Notify({ Title = "礼物", Content = "未找到礼物", Duration = 3 })
				end
			end)
		end,
	})
end

return Gifts
