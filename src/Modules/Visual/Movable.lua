local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Movable = {}
Movable.Title = "移动物高亮"

local Workspace = Services.Get("Workspace")
local RunService = Services.RunService
local Players = Services.Players

local fillColor = Color3.fromRGB(255, 215, 0)
local maxHeight = 100
local batchSize = 80

local enabled = false
local highlights = {}
local scanConn = nil
local listenConn = nil
local pendingTask = nil

local function isValidPart(part)
	if not part:IsA("BasePart") then
		return false
	end
	if part.Anchored then
		return false
	end
	local model = part
	while model and not model:IsA("Model") do
		model = model.Parent
	end
	if model and Players:GetPlayerFromCharacter(model) then
		return false
	end
	if part.Name == "Camera" or part.Name == "Terrain" then
		return false
	end
	if part.Position.Y >= maxHeight then
		return false
	end
	return true
end

local function addHighlight(part)
	if highlights[part] then
		return
	end
	local hl = Instance.new("Highlight")
	hl.Name = "MovableObjectHighlight"
	hl.FillColor = fillColor
	hl.OutlineColor = fillColor
	hl.FillTransparency = 0.7
	hl.OutlineTransparency = 0
	hl.Adornee = part
	hl.Parent = part
	highlights[part] = hl
end

local function clearAll()
	for part, hl in pairs(highlights) do
		if hl and hl.Parent then
			hl:Destroy()
		end
	end
	highlights = {}
end

local function stopScan()
	if scanConn then
		scanConn:Disconnect()
		scanConn = nil
	end
	if listenConn then
		listenConn:Disconnect()
		listenConn = nil
	end
	pendingTask = nil
end

local function scanAsync()
	local relevant = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("Model") then
			table.insert(relevant, obj)
		end
	end
	local total = #relevant
	local processed = 0
	local taskId = {}
	pendingTask = taskId
	scanConn = RunService.RenderStepped:Connect(function()
		if not enabled or taskId ~= pendingTask then
			if scanConn then
				scanConn:Disconnect()
				scanConn = nil
			end
			return
		end
		local endIdx = math.min(processed + batchSize, total)
		for i = processed + 1, endIdx do
			local obj = relevant[i]
			if obj:IsA("BasePart") then
				if isValidPart(obj) then
					addHighlight(obj)
				end
			elseif obj:IsA("Model") then
				for _, part in ipairs(obj:GetDescendants()) do
					if part:IsA("BasePart") and isValidPart(part) then
						addHighlight(part)
					end
				end
			end
		end
		processed = endIdx
		if processed >= total then
			if scanConn then
				scanConn:Disconnect()
				scanConn = nil
			end
			pendingTask = nil
		end
	end)
	listenConn = Workspace.DescendantAdded:Connect(function(desc)
		if not enabled then
			return
		end
		if desc:IsA("BasePart") then
			if isValidPart(desc) then
				addHighlight(desc)
			end
		elseif desc:IsA("Model") then
			for _, part in ipairs(desc:GetDescendants()) do
				if part:IsA("BasePart") and isValidPart(part) then
					addHighlight(part)
				end
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
		task.defer(function()
			if enabled then
				scanAsync()
			end
		end)
	else
		stopScan()
		clearAll()
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function Movable.Init(Tabs, ctx)
	local settings = ctx.FeatureSettings("移动物高亮")
	Tabs.ESP:Toggle({
		Title = "高亮未锚定部件",
		Icon = "boxes",
		Value = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
	settings:Slider({
		Title = "最大高度",
		Icon = "arrow-up",
		Step = 10,
		Value = { Min = 20, Max = 1000, Default = 100 },
		Callback = function(v)
			maxHeight = v
		end,
	})
	settings:Colorpicker({
		Title = "高亮颜色",
		Icon = "palette",
		Default = Color3.fromRGB(255, 215, 0),
		Callback = function(v)
			fillColor = v
		end,
	})
end

return Movable
