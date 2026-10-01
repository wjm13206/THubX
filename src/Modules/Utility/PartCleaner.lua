local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local PartCleaner = {}
PartCleaner.Title = "移动部件清理"

local isEnabled = false
local heartbeatConnection = nil
local frameCount = 0
local scanInterval = 10
local scanRadius = 300

local PROTECTED_NAMES = {
	HumanoidRootPart = true,
	Head = true,
	Torso = true,
	UpperTorso = true,
	LowerTorso = true,
	Humanoid = true,
}

local overlapParams = nil
local function getOverlapParams()
	if overlapParams then
		return overlapParams
	end
	local success, result = pcall(function()
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.RespectCanCollide = false
		return params
	end)
	if success then
		overlapParams = result
	end
	return overlapParams
end

local function isPartMoving(part)
	local success, vel = pcall(function()
		return part.Velocity
	end)
	if success and vel and vel.Magnitude > 0.1 then
		return true
	end
	success, vel = pcall(function()
		return part.AssemblyLinearVelocity
	end)
	if success and vel and vel.Magnitude > 0.1 then
		return true
	end
	return false
end

local function scanAndClean()
	if not isEnabled then
		return
	end
	local character = Services.Players.LocalPlayer.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end
	local params = getOverlapParams()
	if not params then
		return
	end
	local success, partsInRange = pcall(function()
		return workspace:GetPartBoundsInRadius(rootPart.Position, scanRadius, params)
	end)
	if not success then
		return
	end
	local count = 0
	for _, part in ipairs(partsInRange) do
		if count >= 5 then
			break
		end
		if not isEnabled then
			return
		end
		if part and part.Parent then
			if not part.Anchored then
				if not PROTECTED_NAMES[part.Name] then
					if not part:IsDescendantOf(character) then
						if isPartMoving(part) then
							pcall(function()
								part:Destroy()
							end)
							count = count + 1
						end
					end
				end
			end
		end
	end
end

local function onHeartbeat()
	if not isEnabled then
		return
	end
	frameCount = frameCount + 1
	if frameCount >= scanInterval then
		frameCount = 0
		scanAndClean()
	end
end

local function setEnabled(on)
	if on and isEnabled then
		return
	end
	if not on and not isEnabled then
		return
	end
	isEnabled = on
	frameCount = 0
	if on then
		heartbeatConnection = Services.RunService.Heartbeat:Connect(onHeartbeat)
	else
		if heartbeatConnection then
			heartbeatConnection:Disconnect()
			heartbeatConnection = nil
		end
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function PartCleaner.Init(Tabs, ctx)
	local section = Tabs.Utility:Section({ Title = "移动部件清理" })
	section:Toggle({
		Title = "启用清理",
		Icon = "eraser",
		Value = false,
		Callback = function(state)
			setEnabled(state)
		end,
	})
	section:Slider({
		Title = "扫描半径",
		Icon = "radius",
		Step = 10,
		Value = { Min = 50, Max = 600, Default = 300 },
		Callback = function(v)
			scanRadius = v
		end,
	})
	section:Slider({
		Title = "扫描间隔(帧",
		Icon = "timer",
		Step = 1,
		Value = { Min = 1, Max = 60, Default = 10 },
		Callback = function(v)
			scanInterval = math.floor(v)
		end,
	})
end

return PartCleaner
