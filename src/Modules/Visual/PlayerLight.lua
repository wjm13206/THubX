local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local PlayerLight = {}
PlayerLight.Title = "人物光源"

local Players = Services.Players

local brightness = 2
local lightRange = 10
local lightColor = Color3.fromRGB(255, 255, 255)

local enabled = false
local attachment = nil
local pointLight = nil
local charConn = nil

local function findBodyPart(character)
	local part = character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
	if part and part:IsA("BasePart") then
		return part
	end
	return nil
end

local function cleanup()
	if pointLight then
		pcall(function()
			pointLight:Destroy()
		end)
		pointLight = nil
	end
	if attachment then
		pcall(function()
			attachment:Destroy()
		end)
		attachment = nil
	end
end

local function attach(character)
	cleanup()
	if not character then
		return
	end
	local body = findBodyPart(character)
	if not body then
		return
	end
	attachment = Instance.new("Attachment")
	attachment.Name = "THubXPlayerLight"
	attachment.CFrame = CFrame.new(Vector3.new(0, 1.5, 0))
	attachment.Parent = body
	pointLight = Instance.new("PointLight")
	pointLight.Enabled = enabled
	pointLight.Brightness = brightness
	pointLight.Range = lightRange
	pointLight.Color = lightColor
	pointLight.Shadows = false
	pointLight.Parent = attachment
end

local function applyProps()
	if pointLight and pointLight.Parent then
		pointLight.Brightness = brightness
		pointLight.Range = lightRange
		pointLight.Color = lightColor
	end
end

local function setEnabled(on)
	if on == enabled then
		return
	end
	enabled = on
	local player = Players.LocalPlayer
	if on then
		if player.Character then
			attach(player.Character)
		end
		if charConn then
			charConn:Disconnect()
		end
		charConn = player.CharacterAdded:Connect(function(character)
			task.wait(0.5)
			if enabled then
				attach(character)
			end
		end)
	else
		cleanup()
		if charConn then
			charConn:Disconnect()
			charConn = nil
		end
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function PlayerLight.Init(Tabs, ctx)
	local settings = ctx.FeatureSettings("人物光源")
	Tabs.Visual:Toggle({
		Title = "跟随光源",
		Icon = "lightbulb",
		Value = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
	settings:Slider({
		Title = "亮度",
		Icon = "sun",
		Step = 1,
		Value = { Min = 1, Max = 10, Default = 2 },
		Callback = function(v)
			brightness = v
			applyProps()
		end,
	})
	settings:Slider({
		Title = "范围",
		Icon = "radius",
		Step = 1,
		Value = { Min = 5, Max = 60, Default = 10 },
		Callback = function(v)
			lightRange = v
			applyProps()
		end,
	})
	settings:Colorpicker({
		Title = "光源颜色",
		Icon = "palette",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(v)
			lightColor = v
			applyProps()
		end,
	})
end

return PlayerLight
