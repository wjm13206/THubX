local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local TCPTrigger = {}
TCPTrigger.Title = "交互触发"

local LocalPlayer = Services.Players.LocalPlayer
local RunService = Services.RunService

local ActiveTypes = {}
local Distance = 20
local RingScale = 0.8
local LoopEnabled = false
local ShowRing = true

local TypeCache = {}
local CacheConnections = {}
local LoopStates = {}
local LOOP_INTERVAL = 1 / 100

local VALID_TYPES = { TouchTransmitter = true, ClickDetector = true, ProximityPrompt = true }
local TYPE_TITLES = { TouchTransmitter = "触碰", ClickDetector = "点击", ProximityPrompt = "接近" }

local function GetRoot()
	local char = LocalPlayer.Character
	if char then
		return char:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function GetInstancePosition(inst)
	local cur = inst
	while cur do
		if cur:IsA("BasePart") then
			return cur.Position
		end
		cur = cur.Parent
	end
	return nil
end

local function FireTouch(inst, rootPart)
	if not firetouchinterest then
		return
	end
	local part = inst:FindFirstAncestorWhichIsA("Part")
	if part then
		task.spawn(function()
			firetouchinterest(part, rootPart, 1)
			task.wait()
			firetouchinterest(part, rootPart, 0)
		end)
	else
		pcall(function()
			inst.CFrame = rootPart.CFrame
		end)
	end
end

local function FireClick(inst)
	if not fireclickdetector then
		return
	end
	pcall(fireclickdetector, inst)
end

local function FirePrompt(inst)
	if not fireproximityprompt then
		return
	end
	pcall(fireproximityprompt, inst)
end

local FireMap = {
	TouchTransmitter = FireTouch,
	ClickDetector = FireClick,
	ProximityPrompt = FirePrompt,
}

local function BuildCache(interactType)
	TypeCache[interactType] = {}
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA(interactType) then
			table.insert(TypeCache[interactType], desc)
		end
	end
end

local function StartCacheTracking(interactType)
	BuildCache(interactType)
	local addedConn = workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA(interactType) then
			table.insert(TypeCache[interactType], desc)
		end
	end)
	local removingConn = workspace.DescendantRemoving:Connect(function(desc)
		if desc:IsA(interactType) then
			local cache = TypeCache[interactType]
			if cache then
				for i = #cache, 1, -1 do
					if cache[i] == desc then
						table.remove(cache, i)
						break
					end
				end
			end
		end
	end)
	CacheConnections[interactType] = { addedConn, removingConn }
end

local function StopCacheTracking(interactType)
	local conns = CacheConnections[interactType]
	if conns then
		for _, conn in ipairs(conns) do
			conn:Disconnect()
		end
		CacheConnections[interactType] = nil
	end
	TypeCache[interactType] = nil
end

local RingParts = {}

local function GetSegmentCount(radius)
	local circumference = math.pi * 2 * radius
	local count = math.floor(circumference / 0.5)
	return math.max(32, math.min(256, count))
end

local function DestroyRing()
	for _, part in ipairs(RingParts) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	RingParts = {}
end

local function BuildRing(rootPart)
	local ringRadius = Distance * RingScale
	local segmentCount = GetSegmentCount(ringRadius)
	local ringThickness = 0.3
	local ringHeight = 0.2
	local arcLength = (math.pi * 2 * ringRadius) / segmentCount + 0.05
	local footY = rootPart.Position.Y - (rootPart.Size.Y / 2) + 0.1
	local centerPos = Vector3.new(rootPart.Position.X, footY, rootPart.Position.Z)
	if #RingParts > 0 and #RingParts ~= segmentCount then
		DestroyRing()
	end
	if #RingParts == 0 then
		for i = 1, segmentCount do
			local angle = (i - 1) * (math.pi * 2 / segmentCount)
			local x = math.cos(angle) * ringRadius
			local z = math.sin(angle) * ringRadius
			local part = Instance.new("Part")
			part.Name = "__RingSegment"
			part.Size = Vector3.new(ringThickness, ringHeight, arcLength)
			part.Position = centerPos + Vector3.new(x, 0, z)
			part.Anchored = true
			part.CanCollide = false
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(0, 200, 255)
			part.Transparency = 0.5
			part.CFrame = CFrame.new(part.Position, centerPos) * CFrame.Angles(0, math.rad(90), 0)
			part.Parent = workspace
			table.insert(RingParts, part)
		end
	else
		for i, part in ipairs(RingParts) do
			if part and part.Parent then
				local angle = (i - 1) * (math.pi * 2 / #RingParts)
				local x = math.cos(angle) * ringRadius
				local z = math.sin(angle) * ringRadius
				part.Size = Vector3.new(ringThickness, ringHeight, arcLength)
				part.Position = centerPos + Vector3.new(x, 0, z)
				part.CFrame = CFrame.new(part.Position, centerPos) * CFrame.Angles(0, math.rad(90), 0)
			end
		end
	end
end

local function StartLoopTrigger(interactType)
	local state = ActiveTypes[interactType]
	if not state then
		return
	end
	local fireFunc = FireMap[interactType]
	local loopState = { loopConnection = nil, lastTriggerTime = 0 }
	loopState.loopConnection = RunService.Heartbeat:Connect(function()
		if not state.Running or not LoopEnabled then
			return
		end
		local rootPart = GetRoot()
		if not rootPart then
			return
		end
		local cache = TypeCache[interactType]
		if not cache then
			return
		end
		local currentTime = tick()
		if currentTime - loopState.lastTriggerTime < LOOP_INTERVAL then
			return
		end
		local triggered = false
		local distSq = Distance * Distance
		local rootPos = rootPart.Position
		for i = 1, #cache do
			if not state.Running or not LoopEnabled then
				break
			end
			local inst = cache[i]
			if inst and inst.Parent then
				local pos = GetInstancePosition(inst)
				if pos then
					local dx = pos.X - rootPos.X
					local dy = pos.Y - rootPos.Y
					local dz = pos.Z - rootPos.Z
					if dx * dx + dy * dy + dz * dz <= distSq then
						fireFunc(inst, rootPart)
						triggered = true
					end
				end
			end
		end
		if triggered then
			loopState.lastTriggerTime = currentTime
		end
	end)
	LoopStates[interactType] = loopState
end

local function StopLoopTrigger(interactType)
	local loopState = LoopStates[interactType]
	if loopState and loopState.loopConnection then
		loopState.loopConnection:Disconnect()
	end
	LoopStates[interactType] = nil
end

local function CreateLoop(interactType)
	local state = ActiveTypes[interactType]
	if not state then
		return
	end
	local fireFunc = FireMap[interactType]
	local ringCreated = false
	state.Connection = RunService.Heartbeat:Connect(function()
		if not state.Running then
			return
		end
		local rootPart = GetRoot()
		if not rootPart then
			if ringCreated then
				DestroyRing()
				ringCreated = false
			end
			return
		end
		if ShowRing then
			BuildRing(rootPart)
			ringCreated = true
		elseif ringCreated then
			DestroyRing()
			ringCreated = false
		end
		if LoopEnabled then
			return
		end
		local distSq = Distance * Distance
		local rootPos = rootPart.Position
		local currentlyInRange = {}
		local cache = TypeCache[interactType]
		if cache then
			for i = 1, #cache do
				if not state.Running then
					break
				end
				local inst = cache[i]
				if inst and inst.Parent then
					local pos = GetInstancePosition(inst)
					if pos then
						local dx = pos.X - rootPos.X
						local dy = pos.Y - rootPos.Y
						local dz = pos.Z - rootPos.Z
						if dx * dx + dy * dy + dz * dz <= distSq then
							currentlyInRange[inst] = true
							if not state.Triggered[inst] then
								state.Triggered[inst] = true
								fireFunc(inst, rootPart)
							end
						end
					end
				end
			end
		end
		for inst in pairs(state.Triggered) do
			if not currentlyInRange[inst] then
				state.Triggered[inst] = nil
			end
		end
	end)
end

local function enableType(interactType)
	if not VALID_TYPES[interactType] then
		return
	end
	if ActiveTypes[interactType] then
		disableType(interactType)
	end
	local state = {
		Running = true,
		Triggered = setmetatable({}, { __mode = "k" }),
		Connection = nil,
	}
	ActiveTypes[interactType] = state
	StartCacheTracking(interactType)
	CreateLoop(interactType)
	if LoopEnabled then
		StartLoopTrigger(interactType)
	end
end

local function disableType(interactType)
	if not VALID_TYPES[interactType] then
		return
	end
	local state = ActiveTypes[interactType]
	if not state then
		return
	end
	state.Running = false
	if state.Connection then
		state.Connection:Disconnect()
		state.Connection = nil
	end
	StopLoopTrigger(interactType)
	StopCacheTracking(interactType)
	ActiveTypes[interactType] = nil
	if not next(ActiveTypes) then
		DestroyRing()
	end
end

local function setLoop(on)
	if on and LoopEnabled then
		return
	end
	if not on and not LoopEnabled then
		return
	end
	LoopEnabled = on
	if on then
		for interactType, state in pairs(ActiveTypes) do
			if state.Running and not LoopStates[interactType] then
				StartLoopTrigger(interactType)
			end
		end
	else
		for interactType in pairs(LoopStates) do
			StopLoopTrigger(interactType)
		end
	end
end

Unload.OnUnload(function()
	for interactType in pairs(ActiveTypes) do
		disableType(interactType)
	end
	DestroyRing()
end)

function TCPTrigger.Init(Tabs, ctx)
	local settings = ctx.FeatureSettings("交互触发")
	for _, interactType in ipairs({ "TouchTransmitter", "ClickDetector", "ProximityPrompt" }) do
		local t = interactType
		Tabs.Interact:Toggle({
			Title = "自动" .. (TYPE_TITLES[t] or t),
			Icon = "zap",
			Value = false,
			Callback = function(state)
				if state then
					enableType(t)
				else
					disableType(t)
				end
			end,
		})
	end
	settings:Slider({
		Title = "触发距离",
		Icon = "ruler",
		Step = 1,
		Value = { Min = 5, Max = 100, Default = 20 },
		Callback = function(v)
			Distance = v
			DestroyRing()
		end,
	})
	Tabs.Interact:Toggle({
		Title = "显示范围圈",
		Icon = "circle",
		Value = true,
		Callback = function(state)
			ShowRing = state
			if not state then
				DestroyRing()
			end
		end,
	})
	Tabs.Interact:Toggle({
		Title = "循环触发模式",
		Icon = "repeat",
		Value = false,
		Callback = function(state)
			setLoop(state)
		end,
	})
end

return TCPTrigger
