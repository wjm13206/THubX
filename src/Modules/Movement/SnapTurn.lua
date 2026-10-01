local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local SnapTurn = {}
SnapTurn.Title = "锁定转向"

local RunService = Services.RunService
local player = Services.Players.LocalPlayer

local enabled = false
local character = nil
local humanoid = nil
local rootPart = nil
local renderSteppedConn = nil
local charAddedConn = nil

local function onRenderStepped()
	if not humanoid or not humanoid.Parent or not rootPart or not rootPart.Parent then
		return
	end
	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude > 0 then
		rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + moveDir)
	end
end

local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
	humanoid.AutoRotate = false
	if renderSteppedConn then
		renderSteppedConn:Disconnect()
	end
	renderSteppedConn = RunService.RenderStepped:Connect(onRenderStepped)
end

local function setEnabled(state)
	if state then
		if enabled then
			return
		end
		enabled = true
		charAddedConn = player.CharacterAdded:Connect(function(char)
			if enabled then
				setupCharacter(char)
			end
		end)
		if player.Character then
			setupCharacter(player.Character)
		end
	else
		if not enabled then
			return
		end
		enabled = false
		if humanoid then
			humanoid.AutoRotate = true
		end
		if renderSteppedConn then
			renderSteppedConn:Disconnect()
			renderSteppedConn = nil
		end
		if charAddedConn then
			charAddedConn:Disconnect()
			charAddedConn = nil
		end
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function SnapTurn.Init(Tabs, ctx)
	local section = Tabs.Movement:Section({Title = "锁定转向"})
	section:Toggle({
		Title = "启用锁定转向",
		Icon = "rotate-cw",
		Default = false,
		Callback = function(state)
			setEnabled(state)
		end,
	})
end

return SnapTurn
