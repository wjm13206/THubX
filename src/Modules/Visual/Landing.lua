local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Landing = {}
Landing.Title = "落地特效"

local Players = Services.Players
local RunService = Services.RunService
local TweenService = Services.TweenService
local Debris = Services.Get("Debris")

local RING_COLOR = Color3.fromRGB(100, 150, 255)
local END_RADIUS = 6
local DURATION = 1

local enabled = false
local conns = {}
local wasJumping = false
local jumpStart = 0

local function spawnRing(position)
	local ring = Instance.new("Part")
	ring.Name = "LandingRing"
	ring.Color = RING_COLOR
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.3
	ring.CanCollide = false
	ring.Anchored = true
	ring.CastShadow = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.1, 2, 2)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	local light = Instance.new("PointLight")
	light.Color = RING_COLOR
	light.Brightness = 1.5
	light.Range = 8
	light.Parent = ring
	local info = TweenInfo.new(DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local endSize = END_RADIUS * 2
	TweenService:Create(ring, info, { Size = Vector3.new(0.1, endSize, endSize) }):Play()
	TweenService:Create(ring, info, { Transparency = 1 }):Play()
	TweenService:Create(light, info, { Brightness = 0 }):Play()
	Debris:AddItem(ring, DURATION + 0.5)
end

local function getRefs(character)
	if not character then
		return nil, nil
	end
	return character:FindFirstChildOfClass("Humanoid"),
		character:FindFirstChild("HumanoidRootPart")
end

local function watch(character)
	local humanoid, root = getRefs(character)
	if not humanoid then
		return
	end
	wasJumping = false
	jumpStart = 0
	local hb = RunService.Heartbeat:Connect(function()
		humanoid, root = getRefs(character)
		if not humanoid or not root then
			return
		end
		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Jumping and not wasJumping then
			wasJumping = true
			jumpStart = tick()
		elseif wasJumping and state ~= Enum.HumanoidStateType.Jumping
			and state ~= Enum.HumanoidStateType.Freefall then
			local dur = tick() - jumpStart
			if dur > 0.2 and dur < 2 then
				spawnRing(root.Position - Vector3.new(0, 3, 0))
			end
			wasJumping = false
		end
	end)
	table.insert(conns, hb)
	local died = humanoid.Died:Connect(function()
		wasJumping = false
	end)
	table.insert(conns, died)
end

local function clearConns()
	for _, c in ipairs(conns) do
		if c and c.Connected then
			c:Disconnect()
		end
	end
	conns = {}
end

local function setEnabled(on)
	if on == enabled then
		return
	end
	enabled = on
	if on then
		local player = Players.LocalPlayer
		if player.Character then
			watch(player.Character)
		end
		local added = player.CharacterAdded:Connect(function(character)
			task.wait(0.5)
			if enabled then
				clearConns()
				watch(character)
			end
		end)
		table.insert(conns, added)
	else
		clearConns()
		wasJumping = false
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function Landing.Init(Tabs, ctx)
	local section = Tabs.Visual:Section({ Title = "落地特效" })
	section:Toggle({
		Title = "落地光环",
		Icon = "circle-dot",
		Default = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
	section:Button({
		Title = "测试一次特效",
		Icon = "play",
		Callback = function()
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				spawnRing(root.Position - Vector3.new(0, 3, 0))
			end
		end,
	})
end

return Landing
