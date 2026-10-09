local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "自由相机"

local cloneref = Services.cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local freecamEnabled = false
local moduleEnabled = false
local cameraRotation = Vector2.new()
local freecamConnection = nil
local charLock = nil
local moveVector = Vector3.new()

local currentKeybind = Enum.KeyCode.F
local eventConnections = {}

local DEFAULT_SPEED = 1.0
local cameraSpeed = DEFAULT_SPEED
local lookSensitivity = 50
local WHEEL_SENSITIVITY = 0.1

local isMobile = UserInputService and UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local autoEnabledOnMobile = false

local function getRootPart()
	local char = LocalPlayer.Character
	if char then
		return char:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function lockCharacter()
	local root = getRootPart()
	if not root or charLock then return end
	charLock = Instance.new("BodyPosition")
	charLock.Name = "FreeCamLock"
	charLock.Position = root.Position
	charLock.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	charLock.D = 100
	charLock.P = 5000
	charLock.Parent = root
end

local function unlockCharacter()
	if charLock then
		charLock:Destroy()
		charLock = nil
	end
end

local function adjustSpeedWithMouseWheel(delta)
	if not freecamEnabled then return end
	if delta > 0 then
		cameraSpeed = cameraSpeed * (1 + WHEEL_SENSITIVITY)
	else
		cameraSpeed = cameraSpeed * (1 - WHEEL_SENSITIVITY)
	end
	cameraSpeed = math.max(0, cameraSpeed)
end

local function getMobileJoystickVector()
	if not isMobile then return Vector3.new() end
	local char = LocalPlayer.Character
	if not char then return Vector3.new() end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return Vector3.new() end
	local moveDir = hum.MoveDirection
	if moveDir.Magnitude < 0.01 then return Vector3.new() end
	local cameraCF = Camera.CFrame
	local right = cameraCF.RightVector
	local forward = cameraCF.LookVector * Vector3.new(1, 0, 1)
	if forward.Magnitude > 0.01 then
		forward = forward.Unit
	end
	local flatMove = Vector3.new(moveDir.X, 0, moveDir.Z)
	if flatMove.Magnitude < 0.01 then return Vector3.new() end
	flatMove = flatMove.Unit
	local camRight = Vector3.new(right.X, 0, right.Z)
	if camRight.Magnitude > 0.01 then
		camRight = camRight.Unit
	end
	local moveX = flatMove:Dot(camRight)
	local moveZ = -flatMove:Dot(forward)
	return Vector3.new(moveX, 0, moveZ)
end

local function updateFreecam(dt)
	if not freecamEnabled then return end
	local moveSpeed = cameraSpeed * 50
	local currentMoveVector = moveVector
	if isMobile then
		currentMoveVector = currentMoveVector + getMobileJoystickVector()
	else
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then
			currentMoveVector = currentMoveVector + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			currentMoveVector = currentMoveVector + Vector3.new(0, -1, 0)
		end
		local mouseDelta = UserInputService:GetMouseDelta()
		local sensitivity = lookSensitivity * 0.004
		cameraRotation = cameraRotation + Vector2.new(
			-math.rad(mouseDelta.Y * sensitivity),
			-math.rad(mouseDelta.X * sensitivity)
		)
		cameraRotation = Vector2.new(
			math.clamp(cameraRotation.X, -math.pi / 2, math.pi / 2),
			cameraRotation.Y
		)
	end
	local rotation = CFrame.fromEulerAnglesYXZ(cameraRotation.X, cameraRotation.Y, 0)
	local position = Camera.CFrame.Position
	if currentMoveVector.Magnitude > 0.01 and cameraSpeed > 0 then
		position = position + rotation:VectorToWorldSpace(currentMoveVector.Unit) * moveSpeed * dt
	end
	Camera.CFrame = CFrame.new(position) * rotation
end

local function internalEnable()
	if freecamEnabled then return end
	freecamEnabled = true
	cameraSpeed = DEFAULT_SPEED
	lockCharacter()
	local _, yaw, pitch = Camera.CFrame:ToEulerAnglesYXZ()
	cameraRotation = Vector2.new(pitch, yaw)
	Camera.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	freecamConnection = RunService.RenderStepped:Connect(updateFreecam)
end

local function internalDisable()
	if not freecamEnabled then return end
	freecamEnabled = false
	if freecamConnection then
		freecamConnection:Disconnect()
		freecamConnection = nil
	end
	unlockCharacter()
	Camera.CameraType = Enum.CameraType.Custom
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	moveVector = Vector3.new()
end

local function setModuleEnabled(value)
	if moduleEnabled == value then return end
	moduleEnabled = value
	if value then
		table.insert(eventConnections, UserInputService.InputBegan:Connect(onKeyPress))
		table.insert(eventConnections, UserInputService.InputEnded:Connect(onKeyRelease))
		table.insert(eventConnections, UserInputService.InputChanged:Connect(onMouseWheel))
		table.insert(eventConnections, LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
		table.insert(eventConnections, LocalPlayer.CharacterRemoving:Connect(onCharacterRemoving))
		if isMobile then
			autoEnabledOnMobile = true
			internalEnable()
		end
	else
		if freecamEnabled then
			internalDisable()
		end
		autoEnabledOnMobile = false
		for _, connection in pairs(eventConnections) do
			if connection.Connected then
				connection:Disconnect()
			end
		end
		table.clear(eventConnections)
	end
end

local function setFreecam(value)
	if not moduleEnabled then return end
	if value then
		internalEnable()
	else
		internalDisable()
	end
end

local function onKeyPress(input, gameProcessed)
	if not moduleEnabled then return end
	if gameProcessed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == currentKeybind and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		if freecamEnabled then
			internalDisable()
		else
			internalEnable()
		end
		return
	end
	if not freecamEnabled then return end
	local key = input.KeyCode
	if key == Enum.KeyCode.W then
		moveVector = moveVector + Vector3.new(0, 0, -1)
	elseif key == Enum.KeyCode.S then
		moveVector = moveVector + Vector3.new(0, 0, 1)
	elseif key == Enum.KeyCode.A then
		moveVector = moveVector + Vector3.new(-1, 0, 0)
	elseif key == Enum.KeyCode.D then
		moveVector = moveVector + Vector3.new(1, 0, 0)
	end
end

local function onKeyRelease(input, gameProcessed)
	if not moduleEnabled or not freecamEnabled then return end
	if gameProcessed then return end
	local key = input.KeyCode
	if key == Enum.KeyCode.W then
		moveVector = moveVector - Vector3.new(0, 0, -1)
	elseif key == Enum.KeyCode.S then
		moveVector = moveVector - Vector3.new(0, 0, 1)
	elseif key == Enum.KeyCode.A then
		moveVector = moveVector - Vector3.new(-1, 0, 0)
	elseif key == Enum.KeyCode.D then
		moveVector = moveVector - Vector3.new(1, 0, 0)
	end
end

local function onMouseWheel(input, gameProcessed)
	if not moduleEnabled or not freecamEnabled then return end
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		adjustSpeedWithMouseWheel(input.Position.Z)
	end
end

local function onCharacterAdded(character)
	task.wait(0.5)
	if freecamEnabled then
		internalDisable()
	else
		unlockCharacter()
	end
	local humanoid = character:WaitForChild("Humanoid", 2)
	if humanoid then
		Camera.CameraSubject = humanoid
		Camera.CameraType = Enum.CameraType.Custom
	end
	if autoEnabledOnMobile and isMobile then
		task.wait(0.1)
		internalEnable()
	end
end

local function onCharacterRemoving()
	if freecamEnabled then
		internalDisable()
	else
		unlockCharacter()
	end
end

local function fullUnload()
	internalDisable()
	for _, connection in pairs(eventConnections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	table.clear(eventConnections)
	unlockCharacter()
	freecamEnabled = false
	moduleEnabled = false
	autoEnabledOnMobile = false
	cameraRotation = Vector2.new()
	moveVector = Vector3.new()
	cameraSpeed = DEFAULT_SPEED
	currentKeybind = Enum.KeyCode.F
	if Camera then
		Camera.CameraType = Enum.CameraType.Custom
		if LocalPlayer.Character then
			local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				Camera.CameraSubject = humanoid
			end
		end
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

Unload.OnUnload(fullUnload)

function M.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Camera, M.Title, { Icon = "video" })
	folder:Toggle({
		Title = "启用自由相机模块",
		Icon = "video",
		Value = false,
		Callback = function(state)
			setModuleEnabled(state)
		end,
	})
	folder:Keybind({
		Title = "自由相机开关按键",
		Icon = "keyboard",
		Value = "F",
		Callback = function(v)
			local code = Enum.KeyCode[v]
			if code then
				currentKeybind = code
			end
		end,
	})
	folder:Slider({
		Title = "相机速度",
		Icon = "gauge",
		Step = 1,
		Value = { Min = 0, Max = 5, Default = 1 },
		Callback = function(v)
			cameraSpeed = math.max(0, v)
		end,
	})
end

return M
