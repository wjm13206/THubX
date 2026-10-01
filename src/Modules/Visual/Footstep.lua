local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Footstep = {}
Footstep.Title = "落脚点指示"

local Players = Services.Players
local RunService = Services.RunService

local DETECT_RADIUS = 5
local MAX_DEPTH = 10000
local MARKER_COLOR = Color3.fromRGB(255, 80, 80)

local enabled = false
local conn = nil
local markers = {}

local function createMarker(position)
	local model = Instance.new("Model")
	model.Name = "LandingMarker"
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Size = Vector3.new(0.6, 0.05, 0.6)
	ring.CFrame = CFrame.new(position)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Transparency = 0.4
	ring.Material = Enum.Material.Neon
	ring.BrickColor = BrickColor.new(MARKER_COLOR)
	ring.Parent = model
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MarkerGUI"
	billboard.Adornee = ring
	billboard.Size = UDim2.new(0, 1.5, 0, 1.5)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 0.3, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Parent = ring
	return model
end

local function getSurface(part, footPos)
	if not part or not part:IsA("BasePart") then
		return nil
	end
	if not part.CanCollide then
		return nil
	end
	local cf = part.CFrame
	local size = part.Size
	local topY = cf.Position.Y + size.Y / 2
	local rel = cf:PointToObjectSpace(Vector3.new(footPos.X, topY, footPos.Z))
	local halfX = size.X / 2
	local halfZ = size.Z / 2
	if math.abs(rel.X) > halfX + 1 or math.abs(rel.Z) > halfZ + 1 then
		return nil
	end
	local worldPos = cf:PointToWorldSpace(Vector3.new(
		math.clamp(rel.X, -halfX, halfX), size.Y / 2,
		math.clamp(rel.Z, -halfZ, halfZ)))
	if worldPos.Y < footPos.Y - 0.05 then
		return worldPos
	end
	return nil
end

local function clearMarkers()
	for part, marker in pairs(markers) do
		if marker and marker.Parent then
			marker:Destroy()
		end
	end
	markers = {}
end

local function update()
	if not enabled then
		return
	end
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		clearMarkers()
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		clearMarkers()
		return
	end
	local footPos = root.Position - Vector3.new(0, humanoid.HipHeight, 0)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { character }
	params.MaxParts = 100
	local boxCenter = footPos - Vector3.new(0, MAX_DEPTH / 2, 0)
	local parts = workspace:GetPartBoundsInBox(
		CFrame.new(boxCenter),
		Vector3.new(DETECT_RADIUS * 2, MAX_DEPTH, DETECT_RADIUS * 2),
		params)
	local current = {}
	local fresh = {}
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") and part.CanCollide and not current[part] then
			current[part] = true
			local point = getSurface(part, footPos)
			if point then
				local old = markers[part]
				if old and old.Parent then
					local ring = old:FindFirstChild("Ring")
					if ring then
						ring.CFrame = CFrame.new(point)
					end
					fresh[part] = old
				else
					local marker = createMarker(point)
					marker.Parent = workspace
					fresh[part] = marker
				end
			end
		end
	end
	for part, marker in pairs(markers) do
		if not fresh[part] then
			if marker and marker.Parent then
				marker:Destroy()
			end
		end
	end
	markers = fresh
end

local function setEnabled(on)
	enabled = on
	if conn then
		conn:Disconnect()
		conn = nil
	end
	if on then
		conn = RunService.RenderStepped:Connect(update)
	else
		clearMarkers()
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function Footstep.Init(Tabs, ctx)
	local section = Tabs.Visual:Section({ Title = "落脚点指示" })
	section:Toggle({
		Title = "显示落脚点",
		Icon = "footprints",
		Value = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
end

return Footstep
