local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local TriggerESP = {}
TriggerESP.Title = "触发器透视"

local RunService = Services.RunService
local Players = Services.Players

local COLORS = {
	touch = Color3.fromRGB(255, 100, 100),
	click = Color3.fromRGB(100, 150, 255),
	prompt = Color3.fromRGB(100, 255, 100),
}

local active = { touch = false, click = false, prompt = false }
local adornments = {}
local labels = {}
local conns = {}
local distConn = nil

local function updateDistances()
	local player = Players.LocalPlayer
	local character = player and player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	for part, label in pairs(labels) do
		if label and label.Parent and part and part.Parent then
			local dist = (part.Position - hrp.Position).Magnitude
			label.Text = string.format("%s\n%.1fm", part.Parent.Name, dist)
		end
	end
end

local function ensureDistConn()
	if not distConn then
		distConn = RunService.Heartbeat:Connect(updateDistances)
	end
end

local function maybeStopDistConn()
	if distConn and next(labels) == nil then
		distConn:Disconnect()
		distConn = nil
	end
end

local function addMark(part, color, name)
	if not part or not part.Parent then
		return
	end
	if not adornments[part] then
		local box = Instance.new("BoxHandleAdornment")
		box.Name = "ESP_BoxHandle"
		box.Adornee = part
		box.AlwaysOnTop = true
		box.ZIndex = 1
		box.Size = part.Size + Vector3.new(0.2, 0.2, 0.2)
		box.Color3 = color
		box.Transparency = 0.6
		box.Parent = part
		adornments[part] = box
	end
	if not labels[part] then
		local bg = Instance.new("BillboardGui")
		bg.Adornee = part
		bg.Size = UDim2.new(0, 250, 0, 70)
		bg.StudsOffset = Vector3.new(0, 2, 0)
		bg.AlwaysOnTop = true
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(1, -10, 1, -10)
		tl.Position = UDim2.new(0, 5, 0, 5)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.SourceSansBold
		tl.TextSize = 18
		tl.Text = name
		tl.Parent = bg
		labels[part] = tl
		bg.Parent = part
	end
	ensureDistConn()
end

local function getTarget(instance)
	if not instance or not instance.Parent then
		return nil
	end
	local target = instance.Parent
	if target:IsA("Attachment") then
		target = target.Parent
	end
	return target
end

local function markTarget(target, color)
	if not target then
		return
	end
	local found = false
	local function scan(obj)
		if obj:IsA("BasePart") then
			addMark(obj, color, target.Name)
			found = true
		end
		for _, child in ipairs(obj:GetChildren()) do
			scan(child)
		end
	end
	scan(target)
	if found then
		ensureDistConn()
	end
end

local function clearPart(part)
	local adorn = adornments[part]
	if adorn then
		adornments[part] = nil
		if adorn.Parent then
			adorn:Destroy()
		end
	end
	local label = labels[part]
	if label then
		labels[part] = nil
		if label.Parent then
			label.Parent:Destroy()
		end
	end
end

local function clearAll()
	for part, adorn in pairs(adornments) do
		if adorn and adorn.Parent then
			adorn:Destroy()
		end
	end
	adornments = {}
	for part, label in pairs(labels) do
		if label and label.Parent then
			label.Parent:Destroy()
		end
	end
	labels = {}
	if distConn then
		distConn:Disconnect()
		distConn = nil
	end
end

local KINDS = {
	touch = { class = "TouchTransmitter", color = COLORS.touch },
	click = { class = "ClickDetector", color = COLORS.click },
	prompt = { class = "ProximityPrompt", color = COLORS.prompt },
}

local function setKind(kind, on)
	local info = KINDS[kind]
	if not info or on == active[kind] then
		return
	end
	active[kind] = on
	if on then
		for _, inst in ipairs(game:GetDescendants()) do
			if inst:IsA(info.class) then
				markTarget(getTarget(inst), info.color)
			end
		end
		local c1 = game.DescendantAdded:Connect(function(desc)
			if desc:IsA(info.class) and active[kind] then
				task.wait()
				markTarget(getTarget(desc), info.color)
			end
		end)
		local c2 = game.DescendantRemoving:Connect(function(desc)
			if desc:IsA(info.class) then
				local target = getTarget(desc)
				if target then
					local function scan(obj)
						if obj:IsA("BasePart") then
							clearPart(obj)
						end
						for _, child in ipairs(obj:GetChildren()) do
							scan(child)
						end
					end
					scan(target)
				end
				maybeStopDistConn()
			end
		end)
		conns[kind] = { c1, c2 }
	else
		if conns[kind] then
			for _, c in ipairs(conns[kind]) do
				c:Disconnect()
			end
			conns[kind] = nil
		end
		for _, inst in ipairs(game:GetDescendants()) do
			if inst:IsA(info.class) then
				local target = getTarget(inst)
				if target then
					local function scan(obj)
						if obj:IsA("BasePart") then
							clearPart(obj)
						end
						for _, child in ipairs(obj:GetChildren()) do
							scan(child)
						end
					end
					scan(target)
				end
			end
		end
		maybeStopDistConn()
	end
end

local function disableAll()
	for kind in pairs(KINDS) do
		setKind(kind, false)
	end
	for _, pair in pairs(conns) do
		for _, c in ipairs(pair) do
			c:Disconnect()
		end
	end
	conns = {}
	clearAll()
end

Unload.OnUnload(disableAll)

function TriggerESP.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.ESP, TriggerESP.Title, { Icon = "hand" })
	folder:Toggle({
		Title = "触碰器透视",
		Icon = "hand",
		Value = false,
		Callback = function(v)
			setKind("touch", v)
		end,
	})
	folder:Toggle({
		Title = "点击器透视",
		Icon = "mouse-pointer-click",
		Value = false,
		Callback = function(v)
			setKind("click", v)
		end,
	})
	folder:Toggle({
		Title = "接近提示透视",
		Icon = "scan",
		Value = false,
		Callback = function(v)
			setKind("prompt", v)
		end,
	})
end

return TriggerESP
