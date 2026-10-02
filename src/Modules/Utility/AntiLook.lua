local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local AntiLook = {}
AntiLook.Title = "反视线阻挡"

local RunService = Services.RunService

local enabled = false
local blocker = nil
local conn = nil

local function createBlocker()
	if blocker then
		return
	end
	blocker = Instance.new("Part")
	blocker.Name = "AntiLookBlocker"
	blocker.Size = Vector3.new(4, 4, 0.2)
	blocker.Transparency = 1
	blocker.CanCollide = false
	blocker.Anchored = true
	blocker.Material = Enum.Material.SmoothPlastic
	blocker.CastShadow = false
	blocker.Parent = workspace
end

local function destroyBlocker()
	if blocker then
		blocker:Destroy()
		blocker = nil
	end
end

local function setEnabled(on)
	if on == enabled then
		return
	end
	enabled = on
	if on then
		createBlocker()
		if not conn then
			conn = RunService.RenderStepped:Connect(function()
				if not enabled then
					return
				end
				local cam = workspace.CurrentCamera
				if not cam then
					return
				end
				if not blocker or not blocker.Parent then
					createBlocker()
				end
				blocker.CFrame = (cam.CFrame * CFrame.new(0, 0, -2)) * CFrame.Angles(0, math.rad(180), 0)
			end)
		end
	else
		if conn then
			conn:Disconnect()
			conn = nil
		end
		destroyBlocker()
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function AntiLook.Init(Tabs, ctx)

	Tabs.Utility:Toggle({
		Title = "阻挡视线检测",
		Icon = "eye-off",
		Value = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
end

return AntiLook
