local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "视觉增强"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local Lighting = Services.Get("Lighting")
local RunService = Services.RunService

local LocalPlayer = Players.LocalPlayer

-- 夜视
local nvConn = nil
local function setNightVision(on)
	if on then
		if nvConn then
			return
		end
		Lighting.Ambient = Color3.new(1, 1, 1)
		nvConn = RunService.Stepped:Connect(function()
			if Lighting.Ambient ~= Color3.new(1, 1, 1) then
				Lighting.Ambient = Color3.new(1, 1, 1)
			end
		end)
	else
		if nvConn then
			nvConn:Disconnect()
			nvConn = nil
		end
		Lighting.Ambient = Color3.new(0, 0, 0)
	end
end

-- 超级夜视
local snvConn = nil
local savedBrightness = Lighting.Brightness
local savedExposure = Lighting.ExposureCompensation
local function setSuperNightVision(on)
	if on then
		if snvConn then
			return
		end
		savedBrightness = Lighting.Brightness
		savedExposure = Lighting.ExposureCompensation
		Lighting.Brightness = 2
		Lighting.ExposureCompensation = 2.5
		snvConn = RunService.Stepped:Connect(function()
			if Lighting.Brightness ~= 2 then
				Lighting.Brightness = 2
			end
			if Lighting.ExposureCompensation ~= 2.5 then
				Lighting.ExposureCompensation = 2.5
			end
		end)
	else
		if snvConn then
			snvConn:Disconnect()
			snvConn = nil
		end
		Lighting.Brightness = savedBrightness
		Lighting.ExposureCompensation = savedExposure
	end
end

-- 随身灯笼 / 超级光明（独立光源，与人物光源模块共存）
local lanternAttachment = nil
local lanternLight = nil
local lanternCharConn = nil
local lanternCfg = nil

local function findBodyPart(character)
	local part = character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
	if part and part:IsA("BasePart") then
		return part
	end
	return nil
end

local function clearLantern()
	if lanternLight then
		pcall(function()
			lanternLight:Destroy()
		end)
		lanternLight = nil
	end
	if lanternAttachment then
		pcall(function()
			lanternAttachment:Destroy()
		end)
		lanternAttachment = nil
	end
end

local function attachLantern(character)
	clearLantern()
	if not character or not lanternCfg then
		return
	end
	local body = findBodyPart(character)
	if not body then
		return
	end
	lanternAttachment = Instance.new("Attachment")
	lanternAttachment.Name = "THubXLantern"
	lanternAttachment.Position = Vector3.new(0, 1.5, 0)
	lanternAttachment.Parent = body
	lanternLight = Instance.new("PointLight")
	lanternLight.Brightness = lanternCfg.Brightness
	lanternLight.Range = lanternCfg.Range
	lanternLight.Color = lanternCfg.Color
	lanternLight.Shadows = lanternCfg.Shadows
	lanternLight.Parent = lanternAttachment
end

local function setLantern(cfg)
	if lanternCharConn then
		lanternCharConn:Disconnect()
		lanternCharConn = nil
	end
	if not cfg then
		lanternCfg = nil
		clearLantern()
		return
	end
	lanternCfg = cfg
	if LocalPlayer.Character then
		attachLantern(LocalPlayer.Character)
	end
	lanternCharConn = LocalPlayer.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		if lanternCfg then
			attachLantern(character)
		end
	end)
end

-- X光
local xrayOn = false
local xrayParts = {}
local xrayAddConn = nil
local xrayRemoveConn = nil

local function isCharacterPart(inst)
	local model = inst:FindFirstAncestorWhichIsA("Model")
	if model and model:FindFirstChildWhichIsA("Humanoid") then
		return true
	end
	local parent = inst.Parent
	if parent and parent:FindFirstChildWhichIsA("Humanoid") then
		return true
	end
	return false
end

local function applyXray(inst)
	if not inst:IsA("BasePart") then
		return
	end
	if isCharacterPart(inst) then
		return
	end
	xrayParts[inst] = true
	inst.LocalTransparencyModifier = 0.5
end

local function setXray(on)
	xrayOn = on
	if on then
		for _, inst in ipairs(Workspace:GetDescendants()) do
			pcall(applyXray, inst)
		end
		if not xrayAddConn then
			xrayAddConn = Workspace.DescendantAdded:Connect(function(inst)
				if xrayOn then
					pcall(applyXray, inst)
				end
			end)
		end
		if not xrayRemoveConn then
			xrayRemoveConn = Workspace.DescendantRemoving:Connect(function(inst)
				xrayParts[inst] = nil
			end)
		end
	else
		for part in pairs(xrayParts) do
			pcall(function()
				if part and part.Parent then
					part.LocalTransparencyModifier = 0
				end
			end)
		end
		table.clear(xrayParts)
	end
end

-- 显示隐藏部件
local showHiddenOn = false
local shownParts = {}
local function setShowHidden(on)
	showHiddenOn = on
	if on then
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if inst:IsA("BasePart") and inst.Transparency == 1 and not isCharacterPart(inst) then
				shownParts[inst] = true
				pcall(function()
					inst.Transparency = 0
				end)
			end
		end
	else
		for part in pairs(shownParts) do
			pcall(function()
				if part and part.Parent then
					part.Transparency = 1
				end
			end)
		end
		table.clear(shownParts)
	end
end

-- 雾效
local fogRemoved = false
local savedFogEnd = Lighting.FogEnd
local movedAtmospheres = {}
local function setFogRemoved(off)
	if off then
		if fogRemoved then
			return
		end
		fogRemoved = true
		savedFogEnd = Lighting.FogEnd
		for _, inst in ipairs(Lighting:GetChildren()) do
			if inst:IsA("Atmosphere") then
				table.insert(movedAtmospheres, { Obj = inst, Parent = inst.Parent })
				inst.Parent = nil
			end
		end
		Lighting.FogEnd = 100000
	else
		if not fogRemoved then
			return
		end
		fogRemoved = false
		Lighting.FogEnd = savedFogEnd
		for _, rec in ipairs(movedAtmospheres) do
			pcall(function()
				if rec.Parent then
					rec.Obj.Parent = rec.Parent
				end
			end)
		end
		table.clear(movedAtmospheres)
	end
end

Unload.OnUnload(function()
	setNightVision(false)
	setSuperNightVision(false)
	setLantern(nil)
	setXray(false)
	setShowHidden(false)
	setFogRemoved(false)
	if xrayAddConn then
		xrayAddConn:Disconnect()
		xrayAddConn = nil
	end
	if xrayRemoveConn then
		xrayRemoveConn:Disconnect()
		xrayRemoveConn = nil
	end
	if lanternCharConn then
		lanternCharConn:Disconnect()
		lanternCharConn = nil
	end
end)

function M.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Visual, M.Title, { Icon = "moon" })
	folder:Toggle({
		Title = "夜视",
		Icon = "moon",
		Value = false,
		Callback = function(state)
			setNightVision(state)
		end,
	})
	folder:Toggle({
		Title = "超级夜视",
		Icon = "sun",
		Value = false,
		Callback = function(state)
			setSuperNightVision(state)
		end,
	})
	folder:Toggle({
		Title = "随身灯笼",
		Icon = "lamp",
		Value = false,
		Callback = function(state)
			if state then
				setLantern({ Brightness = 3, Range = 20, Color = Color3.fromRGB(255, 165, 0), Shadows = true })
			else
				setLantern(nil)
			end
		end,
	})
	folder:Toggle({
		Title = "超级光明",
		Icon = "lightbulb",
		Value = false,
		Callback = function(state)
			if state then
				setLantern({ Brightness = 2, Range = 1000, Color = Color3.fromRGB(255, 255, 255), Shadows = false })
			else
				setLantern(nil)
			end
		end,
	})
	folder:Toggle({
		Title = "X光",
		Icon = "scan",
		Value = false,
		Callback = function(state)
			setXray(state)
		end,
	})
	folder:Toggle({
		Title = "显示隐藏部件",
		Icon = "eye",
		Value = false,
		Callback = function(state)
			setShowHidden(state)
		end,
	})
	folder:Toggle({
		Title = "禁用雾效",
		Icon = "cloud-off",
		Value = false,
		Callback = function(state)
			setFogRemoved(state)
		end,
	})
end

return M
