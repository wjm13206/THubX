local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local PartTP = {}
PartTP.Title = "零件传送"

local partName = ""
local delayTime = 0.1

local function isValidCharacter(player)
	local character = player.Character
	if not character then
		return false, nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then
		return false, nil
	end
	return true, hrp
end

local function teleportToParts(ctx)
	if partName == "" then
		ctx.WindUI:Notify({ Title = "零件传送", Content = "请先输入零件名称", Duration = 3 })
		return
	end
	local player = Services.Players.LocalPlayer
	local valid, hrp = isValidCharacter(player)
	if not valid then
		return
	end
	local targets = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == partName then
			table.insert(targets, obj)
		end
	end
	if #targets == 0 then
		ctx.WindUI:Notify({ Title = "零件传送", Content = "未找到该零件", Duration = 3 })
		return
	end
	local playerPos = hrp.Position
	table.sort(targets, function(a, b)
		return (a.Position - playerPos).Magnitude < (b.Position - playerPos).Magnitude
	end)
	ctx.WindUI:Notify({ Title = "零件传送", Content = "找到 " .. #targets .. " 个，开始传送", Duration = 3 })
	for _, part in ipairs(targets) do
		local validNow, currentHrp = isValidCharacter(player)
		if not validNow then
			break
		end
		currentHrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
		currentHrp.AssemblyLinearVelocity = Vector3.zero
		currentHrp.AssemblyAngularVelocity = Vector3.zero
		task.wait(delayTime)
	end
end

Unload.OnUnload(function()
end)

function PartTP.Init(Tabs, ctx)
	local section = Tabs.Utility:Section({ Title = "零件传送" })
	section:Input({
		Title = "零件名称",
		Icon = "tag",
		Placeholder = "输入零件名",
		Callback = function(v)
			partName = v
		end,
	})
	section:Slider({
		Title = "传送间隔(秒)",
		Icon = "timer",
		Step = 1,
		Value = { Min = 1, Max = 20, Default = 1 },
		Callback = function(v)
			delayTime = v / 10
		end,
	})
	section:Button({
		Title = "开始传送",
		Icon = "navigation",
		Callback = function()
			task.spawn(function()
				teleportToParts(ctx)
			end)
		end,
	})
end

return PartTP
