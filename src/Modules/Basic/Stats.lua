local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "基础设置"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local Lighting = Services.Get("Lighting")
local RunService = Services.RunService

local LocalPlayer = Players.LocalPlayer

-- 当前数值（内存态，不持久化）
local speed = 16
local jump = 50
local maxhealth = 100
local health = 100
local gravity = Workspace.Gravity
local lockSpeed = false
local lockJump = false
local lockMaxHealth = false
local lockHealth = false
local lockGravity = false

local function getHum()
	local char = LocalPlayer.Character
	if not char then
		return nil
	end
	return char:FindFirstChildWhichIsA("Humanoid")
end

-- 移速/跳跃伪装钩子（有执行器函数时才安装）
local checkcaller = checkcaller or function()
	return false
end
local newcclosure = newcclosure or function(f)
	return f
end
local mt = nil
local oldIndex = nil
local oldNewindex = nil
local spoofInstalled = false

local function installSpoofHooks()
	if spoofInstalled then
		return
	end
	local okGetMt = pcall(function()
		mt = getrawmetatable(game)
	end)
	if not okGetMt or not mt then
		return
	end
	oldIndex = mt.__index
	oldNewindex = mt.__newindex
	mt.__index = newcclosure(function(self, key)
		if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
			local char = LocalPlayer.Character
			if char and self:IsDescendantOf(char) then
				if key == "WalkSpeed" and lockSpeed then
					return speed
				end
				if key == "JumpPower" and lockJump then
					return jump
				end
			end
		end
		return oldIndex(self, key)
	end)
	mt.__newindex = newcclosure(function(self, key, value)
		if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
			local char = LocalPlayer.Character
			if char and self:IsDescendantOf(char) then
				if key == "WalkSpeed" and lockSpeed then
					return
				end
				if key == "JumpPower" and lockJump then
					return
				end
			end
		end
		return oldNewindex(self, key, value)
	end)
	spoofInstalled = true
end

local function uninstallSpoofHooks()
	if not spoofInstalled then
		return
	end
	pcall(function()
		mt.__index = oldIndex
		mt.__newindex = oldNewindex
	end)
	spoofInstalled = false
end

local function refreshSpoofHooks()
	if lockSpeed or lockJump then
		installSpoofHooks()
	else
		uninstallSpoofHooks()
	end
end

Unload.OnUnload(function()
	uninstallSpoofHooks()
end)

-- 血量/重力锁定连接
local maxHealthConn = nil
local maxHealthBeat = nil
local healthConn = nil
local healthBeat = nil
local gravityConn = nil

local function detachMaxHealth()
	if maxHealthConn then
		maxHealthConn:Disconnect()
		maxHealthConn = nil
	end
	if maxHealthBeat then
		maxHealthBeat:Disconnect()
		maxHealthBeat = nil
	end
end

local function attachMaxHealth(hum)
	detachMaxHealth()
	if not hum then
		return
	end
	maxHealthConn = hum:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		if lockMaxHealth then
			hum.MaxHealth = maxhealth
		end
	end)
	local last = 0
	maxHealthBeat = RunService.Heartbeat:Connect(function()
		if not lockMaxHealth then
			detachMaxHealth()
			return
		end
		local now = tick()
		if now - last < 0.5 then
			return
		end
		last = now
		if hum and hum.Parent and hum.MaxHealth ~= maxhealth then
			hum.MaxHealth = maxhealth
		end
	end)
end

local function detachHealth()
	if healthConn then
		healthConn:Disconnect()
		healthConn = nil
	end
	if healthBeat then
		healthBeat:Disconnect()
		healthBeat = nil
	end
end

local function attachHealth(hum)
	detachHealth()
	if not hum then
		return
	end
	healthConn = hum:GetPropertyChangedSignal("Health"):Connect(function()
		if lockHealth then
			hum.Health = health
		end
	end)
	local last = 0
	healthBeat = RunService.Heartbeat:Connect(function()
		if not lockHealth then
			detachHealth()
			return
		end
		local now = tick()
		if now - last < 0.5 then
			return
		end
		last = now
		if hum and hum.Parent and hum.Health ~= health then
			hum.Health = health
		end
	end)
end

local function detachGravity()
	if gravityConn then
		gravityConn:Disconnect()
		gravityConn = nil
	end
end

local function attachGravity()
	detachGravity()
	gravityConn = RunService.Stepped:Connect(function()
		if not lockGravity then
			detachGravity()
			return
		end
		if Workspace.Gravity ~= gravity then
			Workspace.Gravity = gravity
		end
	end)
end

Unload.OnUnload(function()
	detachMaxHealth()
	detachHealth()
	detachGravity()
end)

-- 重生后重挂
local charAddedConn = nil
local charRemovingConn = nil

local function setupCharacter(char)
	if not char then
		return
	end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if hum then
		if lockMaxHealth then
			attachMaxHealth(hum)
		end
		if lockHealth then
			attachHealth(hum)
		end
	else
		local childConn
		childConn = char.ChildAdded:Connect(function(child)
			if child:IsA("Humanoid") then
				task.wait(0.1)
				if lockMaxHealth then
					attachMaxHealth(child)
				end
				if lockHealth then
					attachHealth(child)
				end
				if childConn then
					childConn:Disconnect()
				end
			end
		end)
	end
end

-- 密度
local densitySaved = {}

local function getDensity()
	local char = LocalPlayer.Character
	if not char then
		return 1
	end
	local mass, vol = 0, 0
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			mass = mass + p:GetMass()
			vol = vol + p.Size.X * p.Size.Y * p.Size.Z
		end
	end
	if vol <= 0 then
		return 1
	end
	return mass / vol
end

local function setDensity(d)
	local char = LocalPlayer.Character
	if not char then
		return
	end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			if not densitySaved[p] then
				densitySaved[p] = p.CustomPhysicalProperties
			end
			local old = p.CustomPhysicalProperties
			local friction = old and old.Friction or 0.7
			local elasticity = old and old.Elasticity or 0.5
			p.CustomPhysicalProperties = PhysicalProperties.new(d, friction, elasticity)
		end
	end
end

local function restoreDensity()
	for part, props in pairs(densitySaved) do
		pcall(function()
			if part and part.Parent then
				part.CustomPhysicalProperties = props
			end
		end)
	end
	table.clear(densitySaved)
end

Unload.OnUnload(restoreDensity)

-- 名称/血条显示距离
local pdndConns = {}
local phdConns = {}
local asphConns = {}
local showNameDist = false
local allNameDist = 100
local showHealthDist = false
local allHealthDist = 100
local alwaysShowHealth = false

local function clearConns(t)
	for _, c in pairs(t) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(t)
end

local function applyNameDist()
	clearConns(pdndConns)
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hum = char and char:FindFirstChildWhichIsA("Humanoid")
		if hum then
			if showNameDist then
				hum.NameDisplayDistance = allNameDist
			end
		end
		pdndConns[plr.UserId] = plr.CharacterAdded:Connect(function(char)
			char:WaitForChild("Humanoid")
			task.wait(0.2)
			local h = char:FindFirstChildWhichIsA("Humanoid")
			if h and showNameDist then
				h.NameDisplayDistance = allNameDist
			end
		end)
	end
end

local function applyHealthDist()
	clearConns(phdConns)
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hum = char and char:FindFirstChildWhichIsA("Humanoid")
		if hum then
			if showHealthDist then
				hum.HealthDisplayDistance = allHealthDist
			end
		end
		phdConns[plr.UserId] = plr.CharacterAdded:Connect(function(char)
			char:WaitForChild("Humanoid")
			task.wait(0.2)
			local h = char:FindFirstChildWhichIsA("Humanoid")
			if h and showHealthDist then
				h.HealthDisplayDistance = allHealthDist
			end
		end)
	end
end

local function applyAlwaysShowHealth()
	clearConns(asphConns)
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hum = char and char:FindFirstChildWhichIsA("Humanoid")
		if hum then
			hum.HealthDisplayType = alwaysShowHealth and Enum.HumanoidHealthDisplayType.AlwaysOn
				or Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
		end
		asphConns[plr.UserId] = plr.CharacterAdded:Connect(function(char)
			char:WaitForChild("Humanoid")
			task.wait(0.2)
			local h = char:FindFirstChildWhichIsA("Humanoid")
			if h then
				h.HealthDisplayType = alwaysShowHealth and Enum.HumanoidHealthDisplayType.AlwaysOn
					or Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
			end
		end)
	end
end

Unload.OnUnload(function()
	clearConns(pdndConns)
	clearConns(phdConns)
	clearConns(asphConns)
	if charAddedConn then
		charAddedConn:Disconnect()
	end
	if charRemovingConn then
		charRemovingConn:Disconnect()
	end
end)

function M.Init(Tabs, ctx)
	charAddedConn = LocalPlayer.CharacterAdded:Connect(setupCharacter)
	charRemovingConn = LocalPlayer.CharacterRemoving:Connect(function()
		detachMaxHealth()
		detachHealth()
	end)
	if LocalPlayer.Character then
		setupCharacter(LocalPlayer.Character)
	end

	-- 基础数值
	local numSection = Tabs.Basic:Section({ Title = "基础数值" })
	numSection:Slider({
		Title = "玩家移速",
		Icon = "gauge",
		Step = 1,
		Value = { Min = 0, Max = 1000, Default = 16 },
		Callback = function(v)
			speed = v
			local hum = getHum()
			if hum then
				hum.WalkSpeed = v
			end
		end,
	})
	numSection:Toggle({
		Title = "锁定玩家移速",
		Icon = "lock",
		Value = false,
		Callback = function(state)
			lockSpeed = state
			refreshSpoofHooks()
		end,
	})
	numSection:Slider({
		Title = "跳跃力量",
		Icon = "arrow-up",
		Step = 1,
		Value = { Min = 0, Max = 1000, Default = 50 },
		Callback = function(v)
			jump = v
			local hum = getHum()
			if hum then
				hum.JumpPower = v
			end
		end,
	})
	numSection:Toggle({
		Title = "锁定跳跃力量",
		Icon = "lock",
		Value = false,
		Callback = function(state)
			lockJump = state
			refreshSpoofHooks()
		end,
	})
	numSection:Slider({
		Title = "最大血量",
		Icon = "heart",
		Step = 1,
		Value = { Min = 0, Max = 1000, Default = 100 },
		Callback = function(v)
			maxhealth = v
			local hum = getHum()
			if hum then
				hum.MaxHealth = v
			end
		end,
	})
	numSection:Toggle({
		Title = "锁定最大血量",
		Icon = "lock",
		Value = false,
		Callback = function(state)
			lockMaxHealth = state
			if state then
				attachMaxHealth(getHum())
			else
				detachMaxHealth()
			end
		end,
	})
	numSection:Slider({
		Title = "当前血量",
		Icon = "heart-pulse",
		Step = 1,
		Value = { Min = 0, Max = 1000, Default = 100 },
		Callback = function(v)
			health = v
			local hum = getHum()
			if hum then
				hum.Health = v
			end
		end,
	})
	numSection:Toggle({
		Title = "锁定当前血量",
		Icon = "lock",
		Value = false,
		Callback = function(state)
			lockHealth = state
			if state then
				attachHealth(getHum())
			else
				detachHealth()
			end
		end,
	})
	numSection:Slider({
		Title = "世界重力",
		Icon = "globe",
		Step = 1,
		Value = { Min = 0, Max = 1000, Default = math.floor(gravity) },
		Callback = function(v)
			gravity = v
			Workspace.Gravity = v
		end,
	})
	numSection:Toggle({
		Title = "锁定世界重力",
		Icon = "lock",
		Value = false,
		Callback = function(state)
			lockGravity = state
			if state then
				attachGravity()
			else
				detachGravity()
			end
		end,
	})

	-- 体格
	local bodySection = Tabs.Basic:Section({ Title = "体格" })
	bodySection:Slider({
		Title = "角色密度",
		Icon = "box",
		Step = 0.0001,
		Value = { Min = 0.0001, Max = 100, Default = 1 },
		Callback = function(v)
			setDensity(tonumber(v) or 1)
		end,
	})
	bodySection:Button({
		Title = "恢复默认密度",
		Icon = "rotate-ccw",
		Callback = function()
			restoreDensity()
		end,
	})
	bodySection:Slider({
		Title = "臀部高度",
		Icon = "move-vertical",
		Step = 1,
		Value = { Min = 0, Max = 100, Default = 0 },
		Callback = function(v)
			local hum = getHum()
			if hum then
				hum.HipHeight = tonumber(v) or 0
			end
		end,
	})
	bodySection:Slider({
		Title = "最大攀爬角度",
		Icon = "trending-up",
		Step = 1,
		Value = { Min = 0, Max = 90, Default = 89 },
		Callback = function(v)
			local hum = getHum()
			if hum then
				hum.MaxSlopeAngle = tonumber(v) or 89
			end
		end,
	})
	bodySection:Toggle({
		Title = "死亡时断开关节",
		Icon = "bone",
		Value = true,
		Callback = function(state)
			local hum = getHum()
			if hum then
				hum.BreakJointsOnDeath = state
			end
		end,
	})

	-- 显示
	local showSection = Tabs.Basic:Section({ Title = "显示" })
	showSection:Toggle({
		Title = "控制玩家名称显示距离",
		Icon = "tag",
		Value = false,
		Callback = function(state)
			showNameDist = state
			applyNameDist()
		end,
	})
	showSection:Input({
		Title = "名称显示距离",
		Icon = "ruler",
		Value = "100",
		Placeholder = "输入数字",
		Callback = function(text)
			local n = tonumber(text)
			if n then
				allNameDist = n
				applyNameDist()
			end
		end,
	})
	showSection:Toggle({
		Title = "控制玩家生命值显示距离",
		Icon = "heart",
		Value = false,
		Callback = function(state)
			showHealthDist = state
			applyHealthDist()
		end,
	})
	showSection:Input({
		Title = "生命值显示距离",
		Icon = "ruler",
		Value = "100",
		Placeholder = "输入数字",
		Callback = function(text)
			local n = tonumber(text)
			if n then
				allHealthDist = n
				applyHealthDist()
			end
		end,
	})
	showSection:Toggle({
		Title = "始终显示玩家生命值",
		Icon = "eye",
		Value = false,
		Callback = function(state)
			alwaysShowHealth = state
			applyAlwaysShowHealth()
		end,
	})
end

return M
