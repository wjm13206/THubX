local Unload = require("../../Core/Unload")

local Orbit = {}
Orbit.Title = "环绕武器"

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))

local _enabled = false
local _unloaded = false

local _plr
local _chr
local _hrp
local _bp

local _handles = {}
local _orbitParts = {}
local _movers = {}
local _connections = {}
local _toolNames = {}

local _offset = 8
local _speed = 1
local _mode = 1
local _rot = 0
local _toolRotSpeed = 1
local _lerpSpeed = 1
local _targetHRP = nil
local _lastTargetChange = 0

local _renderConn = nil
local _steppedConn = nil
local _postSimConn = nil
local _childAddedConn = nil
local _charAddedConn = nil
local _resyncThread = nil
local _initialized = false

local SETTINGS = {
	VelocityY = 220.290009,
	SimulationRadius = 2147483647,
	MaxOrbitDistance = 8,
	AntiSleepFreq = 15,
	AntiSleepAmp = 0.0015,
	PredictionTime = 0.1,
}

local function _getLocalHRP()
	if _plr and _plr.Character then
		return _plr.Character:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function _cleanupTool(h)
	local i = table.find(_handles, h)
	if not i then return end

	if _orbitParts[i] then _orbitParts[i]:Destroy() end

	if _movers[h] then
		if _movers[h].align then _movers[h].align:Destroy() end
		if _movers[h].angular then _movers[h].angular:Destroy() end
		_movers[h] = nil
	end

	if _connections[h] then
		_connections[h]:Disconnect()
		_connections[h] = nil
	end

	table.remove(_orbitParts, i)
	table.remove(_handles, i)
	table.remove(_toolNames, i)
end

local function _setupTool(v)
	if not v or not v:IsA("Tool") then return end
	local h = v:FindFirstChild("Handle")
	if not h or table.find(_handles, h) then return end

	v.Parent = _bp
	v.Parent = _chr
	v.Parent = _bp
	v.Parent = workspace
	v.Parent = _chr

	local ra = _chr:FindFirstChild("Right Arm") or _chr:FindFirstChild("RightHand")
	if ra then
		local grip = ra:FindFirstChild("RightGrip")
		if grip then
			grip:Destroy()
			v.Parent = _bp
			v.Parent = _chr
			v.Parent = _bp
			v.Parent = workspace
			v.Parent = _chr
		end
	end

	_connections[h] = v.AncestryChanged:Connect(function(_, parent)
		if parent ~= _chr then _cleanupTool(h) end
	end)

	table.insert(_handles, h)
	table.insert(_toolNames, v.Name)

	local i = #_handles

	local p = Instance.new("Part")
	p.Name = "OrbitRef_" .. v.Name
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Position = (_hrp and _hrp.Position) or Vector3.zero
	p.Parent = workspace
	_orbitParts[i] = p

	local av = Instance.new("BodyAngularVelocity")
	av.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	av.P = 1250
	av.Parent = h

	local ap = Instance.new("AlignPosition")
	ap.MaxForce = math.huge
	ap.MaxVelocity = math.huge
	ap.Responsiveness = 200
	ap.Attachment0 = Instance.new("Attachment", h)
	ap.Attachment1 = Instance.new("Attachment", p)
	ap.Parent = h

	_movers[h] = { align = ap, angular = av }
end

local function _handleCharacter(character)
	local function destroyGrips()
		for _, obj in ipairs(character:GetDescendants()) do
			if obj:IsA("Motor6D") and obj.Name == "RightGrip" then
				obj:Destroy()
			end
		end
	end
	destroyGrips()
	character.DescendantAdded:Connect(function(obj)
		if obj:IsA("Motor6D") and obj.Name == "RightGrip" then
			obj:Destroy()
		end
	end)
end

local function _resolveTarget()
	if not _targetHRP or not _targetHRP.Parent then
		local fallback = _getLocalHRP()
		if fallback then
			_targetHRP = fallback
		end
	end
	return _targetHRP
end

local function _computeTargetCFrame(i, numTools, time)
	local target = _resolveTarget()
	if not target then
		return CFrame.new()
	end

	local angle = math.rad(_rot + (360 / numTools) * i)
	local targetCFrame = CFrame.new()

	if _mode == 1 then
		targetCFrame = target.CFrame * CFrame.Angles(0, angle, 0) * CFrame.new(_offset, 0, 0)

	elseif _mode == 2 then
		targetCFrame = target.CFrame * CFrame.new(
			math.cos(angle) * _offset,
			math.sin(time * 2 + i) * 2,
			math.sin(angle) * _offset
		)

	elseif _mode == 3 then
		targetCFrame = target.CFrame * CFrame.Angles(angle, angle, 0) * CFrame.new(_offset, 0, 0)

	elseif _mode == 4 then
		targetCFrame = CFrame.new(target.Position) * CFrame.Angles(0, angle, 0) * CFrame.new(_offset, 0, 0)

	elseif _mode == 5 then
		targetCFrame = target.CFrame * CFrame.new(
			math.cos(angle) * _offset,
			math.sin(angle) * _offset,
			math.sin(angle) * _offset
		)

	elseif _mode == 6 then
		targetCFrame = target.CFrame * CFrame.Angles(angle, 0, angle) * CFrame.new(_offset, 0, 0)

	else
		local subType = _mode % 8
		local safeSpeed = time * (1 + (_mode % 5) / 10)

		if subType == 0 then
			local petalCount = (_mode % 5) + 3
			local wave = math.sin(angle * petalCount + safeSpeed)
			local currentOffset = _offset + (wave * (_offset / 3))
			targetCFrame = target.CFrame * CFrame.Angles(0, angle, 0) * CFrame.new(currentOffset, 0, 0)

		elseif subType == 1 then
			local tiltX = math.rad((_mode * 15) % 360) + (time * 0.5)
			local tiltZ = math.rad((_mode * 45) % 360)
			targetCFrame = target.CFrame * CFrame.Angles(tiltX, angle, tiltZ) * CFrame.new(_offset, 0, 0)

		elseif subType == 2 then
			local height = math.sin(angle + (time * 2)) * (_offset * 0.8)
			local twist = math.cos(safeSpeed + (i / 2)) * 2
			targetCFrame = target.CFrame * CFrame.Angles(0, angle, 0) * CFrame.new(_offset + twist, height, 0)

		elseif subType == 3 then
			local noiseX = math.sin(angle * ((_mode % 3) + 1))
			local noiseY = math.cos(angle * ((_mode % 2) + 1))
			targetCFrame = target.CFrame * CFrame.Angles(angle, 0, angle) * CFrame.new(_offset * noiseX, _offset * noiseY, 0)

		elseif subType == 4 then
			local fig8X = math.cos(angle) * _offset
			local fig8Z = math.sin(angle * 2) * _offset
			targetCFrame = target.CFrame * CFrame.new(fig8X, 0, fig8Z)

		elseif subType == 5 then
			local spikeFreq = (_mode % 4) + 3
			local height = math.abs(math.sin(angle * spikeFreq)) * (_offset * 0.8)
			targetCFrame = target.CFrame * CFrame.Angles(0, angle, 0) * CFrame.new(_offset, height - (_offset / 2), 0)

		elseif subType == 6 then
			local band = (i % 3)
			local tiltAngle = math.rad(60 * band)
			targetCFrame = target.CFrame * CFrame.Angles(tiltAngle, angle, 0) * CFrame.new(_offset, 0, 0)

		elseif subType == 7 then
			local pulse = math.sin(safeSpeed * 2) * (_offset * 0.4)
			targetCFrame = target.CFrame * CFrame.Angles(0, angle, 0) * CFrame.new(_offset + pulse, 0, 0)
		end

		if _mode > 20 then
			local slowWobble = math.rad(math.sin(time) * 15)
			targetCFrame = targetCFrame * CFrame.Angles(slowWobble, 0, slowWobble)
		end
	end

	return targetCFrame
end

local function _startLoops()
	_renderConn = RunService.RenderStepped:Connect(function(dt)
		if not _enabled then return end
		if not _targetHRP or not _targetHRP.Parent then
			local fallback = _getLocalHRP()
			if fallback then _targetHRP = fallback else return end
		end

		_rot = _rot + _speed
		local time = os.clock()
		local numTools = #_orbitParts

		for i, p in ipairs(_orbitParts) do
			if p and p.Parent then
				local targetCFrame = _computeTargetCFrame(i, numTools, time)
				local alpha = 1 - math.exp(-_lerpSpeed * dt)
				p.CFrame = p.CFrame:Lerp(targetCFrame, alpha)

				local h = _handles[i]
				if h and _movers[h] then
					local spinVar = (_mode % 30)
					_movers[h].angular.AngularVelocity = Vector3.new(0, _toolRotSpeed * (10 + spinVar), 0)
				end
			end
		end

		if sethiddenproperty then
			pcall(function() sethiddenproperty(_plr, "SimulationRadius", math.huge) end)
		end
	end)

	_steppedConn = RunService.Stepped:Connect(function()
		settings().Physics.AllowSleep = false
		pcall(function() _plr.SimulationRadius = SETTINGS.SimulationRadius end)
	end)

	local lastHRPPos = _hrp and _hrp.Position or Vector3.zero
	local hrpVel = Vector3.zero

	_postSimConn = RunService.PostSimulation:Connect(function(dt)
		if not _enabled then return end
		if not _targetHRP or not _targetHRP.Parent then return end

		local currentTime = os.clock()
		local currentPos = _hrp and _hrp.Position or Vector3.zero
		if dt > 0 then hrpVel = (currentPos - lastHRPPos) / dt end
		lastHRPPos = currentPos

		local predictedPos = currentPos + hrpVel * SETTINGS.PredictionTime
		local antiSleep = Vector3.new(0, math.sin(currentTime * SETTINGS.AntiSleepFreq) * SETTINGS.AntiSleepAmp, 0)
		local gravityAxis = SETTINGS.VelocityY + math.sin(currentTime)

		for _, h in ipairs(_handles) do
			if h and h:IsA("BasePart") then
				local dir = predictedPos - h.Position
				local xz = Vector3.new(dir.X, 0, dir.Z)
				local velXZ = Vector3.zero
				if xz.Magnitude > 0 then velXZ = xz.Unit * xz.Magnitude * 2 end
				h.AssemblyLinearVelocity = Vector3.new(velXZ.X, gravityAxis, velXZ.Z)
				h.AssemblyAngularVelocity = Vector3.new(0, math.huge, math.huge)
				h.CFrame = h.CFrame + antiSleep
			end
		end
	end)

	_resyncThread = task.spawn(function()
		while _enabled and not _unloaded do
			task.wait(0.1)
			for i = #_handles, 1, -1 do
				local h = _handles[i]
				local orbitPart = _orbitParts[i]
				if h and h.Parent and orbitPart then
					local separation = (h.Position - orbitPart.Position).Magnitude
					if separation > SETTINGS.MaxOrbitDistance then
						local tool = h.Parent
						if tool.Parent == _chr then
							tool.Parent = _bp
							task.wait()
							if tool.Parent == _bp then tool.Parent = _chr end
						end
					end
				end
			end
		end
	end)
end

local function _stopLoops()
	if _renderConn then _renderConn:Disconnect(); _renderConn = nil end
	if _steppedConn then _steppedConn:Disconnect(); _steppedConn = nil end
	if _postSimConn then _postSimConn:Disconnect(); _postSimConn = nil end
	if _resyncThread then task.cancel(_resyncThread); _resyncThread = nil end
end

local function _fullCleanup()
	_stopLoops()

	for _, con in pairs(_connections) do
		con:Disconnect()
	end
	table.clear(_connections)

	for _, p in ipairs(_orbitParts) do
		if p then p:Destroy() end
	end
	table.clear(_orbitParts)

	for h, m in pairs(_movers) do
		if m.align then m.align:Destroy() end
		if m.angular then m.angular:Destroy() end
	end
	table.clear(_movers)

	table.clear(_handles)
	table.clear(_toolNames)

	if _childAddedConn then _childAddedConn:Disconnect(); _childAddedConn = nil end
	if _charAddedConn then _charAddedConn:Disconnect(); _charAddedConn = nil end
end

local function enable()
	if _unloaded then return end
	if _enabled then return end

	if not _initialized then
		_plr = Players.LocalPlayer
		_chr = _plr.Character or _plr.CharacterAdded:Wait()
		_hrp = _chr:WaitForChild("HumanoidRootPart")
		_bp = _plr:WaitForChild("Backpack")
		_targetHRP = _hrp
		_lastTargetChange = os.clock()

		_handleCharacter(_chr)

		_charAddedConn = _plr.CharacterAdded:Connect(function()
			disable()
		end)

		_initialized = true
	end

	_chr = _plr.Character
	if _chr then
		_hrp = _chr:FindFirstChild("HumanoidRootPart")
		_targetHRP = _hrp
	end

	if _chr then
		for _, v in ipairs(_chr:GetChildren()) do
			if v:IsA("Tool") then _setupTool(v) end
		end

		_childAddedConn = _chr.ChildAdded:Connect(function(c)
			if c:IsA("Tool") then
				task.wait()
				_setupTool(c)
			end
		end)
	end

	_startLoops()

	_enabled = true
end

local function disable()
	if _unloaded then return end
	if not _enabled then return end

	_enabled = false

	_fullCleanup()
end

local function setTarget(targetName)
	if _unloaded then return end

	if targetName == nil or targetName == "" then
		local localHRP = _getLocalHRP()
		if localHRP then
			_targetHRP = localHRP
			_lastTargetChange = os.clock()
		end
		return
	end

	local targetPlayer = nil

	if type(targetName) == "string" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Name:lower():find(targetName:lower(), 1, true)
				or (p.DisplayName and p.DisplayName:lower():find(targetName:lower(), 1, true)) then
				targetPlayer = p
				break
			end
		end
	end

	if targetPlayer and targetPlayer.Character then
		local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			_targetHRP = targetHRP
			_lastTargetChange = os.clock()
		end
	end
end

local function resetTarget()
	if _unloaded then return end
	local localHRP = _getLocalHRP()
	if localHRP then
		_targetHRP = localHRP
		_lastTargetChange = os.clock()
	end
end

Unload.OnUnload(function()
	_unloaded = true
	_enabled = false
	_fullCleanup()
end)

function Orbit.Init(Tabs, ctx)
	local settings = ctx.FeatureSettings("环绕武器")
	Tabs.Combat:Toggle({
		Title = "启用环绕",
		Icon = "orbit",
		Value = false,
		Callback = function(state)
			if state then
				enable()
			else
				disable()
			end
		end,
	})
	settings:Slider({
		Title = "环绕半径",
		Icon = "scan",
		Step = 1,
		Value = { Min = 2, Max = 30, Default = 8 },
		Callback = function(v)
			_offset = tonumber(v) or _offset
		end,
	})
	settings:Slider({
		Title = "环绕速度",
		Icon = "gauge",
		Step = 1,
		Value = { Min = -5, Max = 10, Default = 1 },
		Callback = function(v)
			local s = tonumber(v) or _speed
			if s > -0.5 and s < 0.5 then
				if s >= 0 then
					s = 0.5
				else
					s = -0.5
				end
			end
			_speed = s
		end,
	})
	settings:Slider({
		Title = "环绕模式",
		Icon = "shapes",
		Step = 1,
		Value = { Min = 1, Max = 20, Default = 1 },
		Callback = function(v)
			_mode = tonumber(v) or _mode
		end,
	})
	local targetName = ""
	Tabs.Combat:Input({
		Title = "环绕目标",
		Icon = "user",
		Value = "",
		Placeholder = "玩家名，空自己",
		Callback = function(v)
			targetName = v
		end,
	})
	Tabs.Combat:Button({
		Title = "锁定目标",
		Icon = "locate",
		Callback = function()
			setTarget(targetName)
		end,
	})
	Tabs.Combat:Button({
		Title = "重置目标",
		Icon = "rotate-ccw",
		Callback = function()
			resetTarget()
		end,
	})
end

return Orbit
