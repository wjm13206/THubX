local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "滤镜控制"

local Lighting = Services.Get("Lighting")

local EFFECT_CLASSES = {
	{ Name = "泛光", Class = "BloomEffect" },
	{ Name = "模糊", Class = "BlurEffect" },
	{ Name = "太阳光", Class = "SunRaysEffect" },
	{ Name = "颜色校正", Class = "ColorCorrectionEffect" },
	{ Name = "景深", Class = "DepthOfFieldEffect" },
}

local createdByUs = {}

local function findEffect(className)
	for _, inst in ipairs(Lighting:GetChildren()) do
		if inst:IsA(className) then
			return inst
		end
	end
	return nil
end

local function setEffectEnabled(className, on)
	local eff = findEffect(className)
	if on then
		if not eff then
			local ok, created = pcall(Instance.new, className)
			if ok and created then
				created.Name = "THubX_" .. className
				created.Parent = Lighting
				table.insert(createdByUs, created)
				eff = created
			end
		else
			eff.Enabled = true
		end
	else
		if eff then
			eff.Enabled = false
		end
	end
end

local function getCCE(create)
	local eff = findEffect("ColorCorrectionEffect")
	if not eff and create then
		local ok, created = pcall(Instance.new, "ColorCorrectionEffect")
		if ok and created then
			created.Name = "THubX_ColorCorrectionEffect"
			created.Parent = Lighting
			table.insert(createdByUs, created)
			eff = created
		end
	end
	return eff
end

local COLOR_BLIND_MODES = {
	"正常",
	"红色弱",
	"红色盲",
	"绿色弱",
	"绿色盲",
	"蓝色弱",
	"蓝色盲",
	"全色弱",
	"全色盲",
}

local COLOR_BLIND_CFGS = {
	{ Saturation = 0, Brightness = 0, Contrast = 0, Tint = Color3.new(1, 1, 1) },
	{ Saturation = -0.3, Brightness = 0, Contrast = 0.1, Tint = Color3.new(0.85, 1, 1) },
	{ Saturation = -0.5, Brightness = 0, Contrast = 0.2, Tint = Color3.new(0.7, 1, 1) },
	{ Saturation = -0.3, Brightness = 0, Contrast = 0.1, Tint = Color3.new(1, 0.85, 1) },
	{ Saturation = -0.5, Brightness = 0, Contrast = 0.2, Tint = Color3.new(1, 0.7, 1) },
	{ Saturation = -0.3, Brightness = 0.1, Contrast = 0.1, Tint = Color3.new(1, 1, 0.85) },
	{ Saturation = -0.5, Brightness = 0.1, Contrast = 0.2, Tint = Color3.new(1, 1, 0.7) },
	{ Saturation = -0.8, Brightness = 0, Contrast = 0.3, Tint = Color3.new(0.9, 0.9, 0.9) },
	{ Saturation = -1, Brightness = 0, Contrast = 0.5, Tint = Color3.new(0.8, 0.8, 0.8) },
}

local function applyColorBlind(index)
	local cfg = COLOR_BLIND_CFGS[index]
	if not cfg then
		return
	end
	local eff = getCCE(true)
	if eff then
		eff.Enabled = true
		eff.Saturation = cfg.Saturation
		eff.Brightness = cfg.Brightness
		eff.Contrast = cfg.Contrast
		eff.TintColor = cfg.Tint
	end
end

Unload.OnUnload(function()
	for _, inst in ipairs(createdByUs) do
		pcall(function()
			inst:Destroy()
		end)
	end
	table.clear(createdByUs)
end)

function M.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Filter, M.Title, { Icon = "sparkles" })
	for _, info in ipairs(EFFECT_CLASSES) do
		local exists = findEffect(info.Class)
		folder:Toggle({
			Title = info.Name .. "（" .. info.Class .. "）",
			Icon = "sparkles",
			Value = exists and exists.Enabled or false,
			Callback = function(state)
				setEffectEnabled(info.Class, state)
			end,
		})
	end
	folder:Button({
		Title = "重置所有滤镜",
		Icon = "rotate-ccw",
		Callback = function()
			for _, info in ipairs(EFFECT_CLASSES) do
				local eff = findEffect(info.Class)
				if eff then
					eff.Enabled = true
					if eff:IsA("ColorCorrectionEffect") then
						eff.Saturation = 0
						eff.Brightness = 0
						eff.Contrast = 0
						eff.TintColor = Color3.new(1, 1, 1)
					end
				end
			end
		end,
	})

	local colorSettings = folder:Folder({ Title = "颜色微调" })
	colorSettings:Slider({
		Title = "饱和度",
		Icon = "palette",
		Step = 0.05,
		Value = { Min = -1, Max = 1, Default = 0 },
		Callback = function(v)
			local eff = getCCE(true)
			if eff then
				eff.Enabled = true
				eff.Saturation = v
			end
		end,
	})
	colorSettings:Slider({
		Title = "亮度",
		Icon = "sun",
		Step = 0.05,
		Value = { Min = -1, Max = 1, Default = 0 },
		Callback = function(v)
			local eff = getCCE(true)
			if eff then
				eff.Enabled = true
				eff.Brightness = v
			end
		end,
	})
	colorSettings:Slider({
		Title = "对比度",
		Icon = "contrast",
		Step = 0.05,
		Value = { Min = -1, Max = 1, Default = 0 },
		Callback = function(v)
			local eff = getCCE(true)
			if eff then
				eff.Enabled = true
				eff.Contrast = v
			end
		end,
	})
	colorSettings:Colorpicker({
		Title = "色调颜色",
		Icon = "pipette",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(v)
			local eff = getCCE(true)
			if eff then
				eff.Enabled = true
				eff.TintColor = v
			end
		end,
	})

	local blindSettings = folder:Folder({ Title = "色盲模拟器" })
	blindSettings:Dropdown({
		Title = "选择色盲模式",
		Icon = "glasses",
		Values = COLOR_BLIND_MODES,
		Value = "正常",
		Callback = function(v)
			for i, name in ipairs(COLOR_BLIND_MODES) do
				if name == v then
					applyColorBlind(i)
					break
				end
			end
		end,
	})
end

return M
