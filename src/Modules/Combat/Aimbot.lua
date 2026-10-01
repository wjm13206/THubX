local Unload = require("../../Core/Unload")

local Aimbot = {}
Aimbot.Title = "自瞄"

local cloneref = cloneref or clonereference or function(obj) return obj end
local _players = cloneref(game:GetService("Players"))
local _localPlayer = _players.LocalPlayer
local _currentCamera = cloneref(game.Workspace.CurrentCamera)
local _tweenService = cloneref(game:GetService("TweenService"))
local _userInputService = cloneref(game:GetService("UserInputService"))
local _runService = cloneref(game:GetService("RunService"))

local _enabled = false
local _teamCheck = false
local _wallCheck = false
local _showFov = true
local _fov = 360
local _aimPart = "Head"
local _smoothing = 30
local _prediction = false
local _predictionAmount = 100
local _stickyAim = false
local _useMouse = true
local _mouseBind = "MouseButton2"
local _keybind = Enum.KeyCode.E

local _isAimKeyDown = false
local _target = nil
local _cameraTween = nil
local _fovCircle = nil
local _connections = {}

local _isMobile = false
local function _checkMobile()
	_isMobile = _userInputService and _userInputService.TouchEnabled and not _userInputService.KeyboardEnabled
end

local function _createFovCircle()
	local coreGui = cloneref(game:FindFirstChild("CoreGui")) or _localPlayer:WaitForChild("PlayerGui")

	local fovGui = Instance.new("ScreenGui")
	fovGui.Name = "AimBotFOV"
	fovGui.Parent = coreGui
	fovGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	fovGui.ResetOnSpawn = false
	fovGui.Enabled = false
	pcall(function() syn.protect_gui(fovGui) end)

	local fovFrame = Instance.new("Frame")
	fovFrame.Name = "FOVFrame"
	fovFrame.Parent = fovGui
	fovFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fovFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	fovFrame.BorderSizePixel = 0
	fovFrame.BackgroundTransparency = 1
	fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	fovFrame.Size = UDim2.new(0, _fov, 0, _fov)

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = fovFrame

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(100, 0, 100)
	uiStroke.Parent = fovFrame
	uiStroke.Thickness = 1
	uiStroke.ApplyStrokeMode = "Border"

	_fovCircle = {
		Gui = fovGui,
		Frame = fovFrame,
		Stroke = uiStroke
	}
end

local function _isAlive(player)
	if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
		return true
	end
	return false
end

local function _getTeam(player)
	if player.Team and not _localPlayer.Neutral then
		return game.Teams[player.Team.Name]
	end
	return true
end

local function _isVisible(position, character)
	if not _wallCheck then
		return true
	end

	local parts = {_currentCamera, _localPlayer.Character}
	if character then
		table.insert(parts, character)
	end

	return #_currentCamera:GetPartsObscuringTarget({position}, parts) == 0
end

local function _getClosestToScreenCenter()
	local aimFov = _fov
	local targetPos = nil
	local screenCenter = Vector2.new(_currentCamera.ViewportSize.X / 2, _currentCamera.ViewportSize.Y / 2)

	for _, player in pairs(_players:GetPlayers()) do
		if player ~= _localPlayer then
			if not _teamCheck or _getTeam(player) ~= _getTeam(_localPlayer) then
				if _isAlive(player) then
					local targetPart = player.Character:FindFirstChild(_aimPart)
					if targetPart then
						local screenPos, onScreen = _currentCamera:WorldToViewportPoint(targetPart.Position)
						local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
						local magnitude = (screenPos2D - screenCenter).Magnitude

						if onScreen and magnitude < aimFov and _isVisible(targetPart.Position, player.Character) then
							aimFov = magnitude
							targetPos = player
						end
					end
				end
			end
		end
	end

	return targetPos
end

local function _getClosestToMouse()
	if _isMobile then
		return _getClosestToScreenCenter()
	end
	local aimFov = _fov
	local targetPos = nil
	local mouseLocation = _userInputService:GetMouseLocation()

	for _, player in pairs(_players:GetPlayers()) do
		if player ~= _localPlayer then
			if not _teamCheck or _getTeam(player) ~= _getTeam(_localPlayer) then
				if _isAlive(player) then
					local targetPart = player.Character:FindFirstChild(_aimPart)
					if targetPart then
						local screenPos, onScreen = _currentCamera:WorldToViewportPoint(targetPart.Position)
						local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
						local magnitude = (screenPos2D - mouseLocation).Magnitude

						if onScreen and magnitude < aimFov and _isVisible(targetPart.Position, player.Character) then
							aimFov = magnitude
							targetPos = player
						end
					end
				end
			end
		end
	end

	return targetPos
end

local function _cancelTween()
	if _cameraTween then
		_cameraTween:Cancel()
		_cameraTween = nil
	end
end

local function _aimAt(target)
	local targetPart = target.Character:FindFirstChild(_aimPart)
	if targetPart then
		local targetPos = targetPart.Position

		if _prediction then
			local ping = _localPlayer:GetNetworkPing()
			targetPos = targetPos + targetPart.Velocity * (ping * (_predictionAmount / 100))
		end

		_cameraTween = _tweenService:Create(
			_currentCamera,
			TweenInfo.new(_smoothing / 100, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{CFrame = CFrame.new(_currentCamera.CFrame.Position, targetPos)}
		)
		_cameraTween:Play()
	end
end

local function _setupInputListeners()
	if _isMobile then return end

	local keyBeganConn = _userInputService.InputBegan:Connect(function(input)
		if input.KeyCode == _keybind and not _useMouse then
			_target = _getClosestToMouse()
			_isAimKeyDown = true
		end
	end)

	local keyEndedConn = _userInputService.InputEnded:Connect(function(input)
		if input.KeyCode == _keybind and not _useMouse then
			_target = nil
			_isAimKeyDown = false
			_cancelTween()
		end
	end)

	local mouse = _localPlayer:GetMouse()

	local mouse1DownConn = mouse.Button1Down:Connect(function()
		if _mouseBind == "MouseButton1" and _useMouse then
			if _isAimKeyDown then
				_target = nil
				_isAimKeyDown = false
				_cancelTween()
			else
				_target = _getClosestToMouse()
				_isAimKeyDown = true
			end
		end
	end)

	local mouse1UpConn = mouse.Button1Up:Connect(function()
		if _mouseBind == "MouseButton1" and _useMouse then
			_target = nil
			_isAimKeyDown = false
			_cancelTween()
		end
	end)

	local mouse2DownConn = mouse.Button2Down:Connect(function()
		if _mouseBind == "MouseButton2" and _useMouse then
			_target = _getClosestToMouse()
			_isAimKeyDown = true
		end
	end)

	local mouse2UpConn = mouse.Button2Up:Connect(function()
		if _mouseBind == "MouseButton2" and _useMouse then
			_target = nil
			_isAimKeyDown = false
			_cancelTween()
		end
	end)

	table.insert(_connections, keyBeganConn)
	table.insert(_connections, keyEndedConn)
	table.insert(_connections, mouse1DownConn)
	table.insert(_connections, mouse1UpConn)
	table.insert(_connections, mouse2DownConn)
	table.insert(_connections, mouse2UpConn)
end

local function _setupMainLoop()
	local heartbeatConn = _runService.Heartbeat:Connect(function()
		if _enabled and _showFov and _fovCircle then
			_fovCircle.Gui.Enabled = true
			_fovCircle.Stroke.Enabled = true
			if _isMobile then
				local center = _currentCamera.ViewportSize / 2
				_fovCircle.Frame.Position = UDim2.new(0, center.X, 0, center.Y - 36)
				_fovCircle.Frame.Size = UDim2.fromOffset(_fov * 1.5 * 0.375, _fov * 1.5 * 0.375)
			else
				local mousePos = _userInputService:GetMouseLocation()
				_fovCircle.Frame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y - 36)
				_fovCircle.Frame.Size = UDim2.fromOffset(_fov * 1.5, _fov * 1.5)
			end
		elseif _fovCircle then
			_fovCircle.Gui.Enabled = false
			_fovCircle.Stroke.Enabled = false
		end

		if _enabled and _isAimKeyDown then
			if _stickyAim then
				if _target then
					if not _isAlive(_target) then
						_target = _getClosestToMouse()
					end

					if _target and _isAlive(_target) then
						_aimAt(_target)
					end
				end
			else
				local target = _getClosestToMouse()
				if target and _isAlive(target) then
					_aimAt(target)
				else
					_cancelTween()
				end
			end
		end
	end)

	table.insert(_connections, heartbeatConn)
end

local function enable()
	_enabled = true
	if _isMobile then
		_isAimKeyDown = true
	end
end

local function disable()
	_enabled = false
	_isAimKeyDown = false
	_target = nil
	_cancelTween()
end

local function setFov(v)
	_fov = math.clamp(v, 50, 600)
	if _fovCircle and _fovCircle.Frame then
		_fovCircle.Frame.Size = UDim2.fromOffset(_fov * 1.5, _fov * 1.5)
	end
end

Unload.OnUnload(function()
	disable()
end)

_checkMobile()
_createFovCircle()
_setupInputListeners()
_setupMainLoop()

function Aimbot.Init(Tabs, ctx)
	local section = Tabs.Combat:Section({ Title = "自瞄" })
	section:Toggle({
		Title = "启用自瞄",
		Icon = "crosshair",
		Value = false,
		Callback = function(state)
			if state then
				enable()
			else
				disable()
			end
		end,
	})
	section:Toggle({
		Title = "队伍检�?,
		Icon = "users",
		Value = false,
		Callback = function(state)
			_teamCheck = state
		end,
	})
	section:Toggle({
		Title = "穿墙检�?,
		Icon = "brick-wall",
		Value = false,
		Callback = function(state)
			_wallCheck = state
		end,
	})
	section:Toggle({
		Title = "显示范围�?,
		Icon = "circle",
		Value = true,
		Callback = function(state)
			_showFov = state
		end,
	})
	section:Slider({
		Title = "索敌范围",
		Icon = "scan",
		Step = 10,
		Value = { Min = 50, Max = 600, Default = 360 },
		Callback = function(v)
			setFov(v)
		end,
	})
	section:Slider({
		Title = "平滑�?,
		Icon = "waves",
		Step = 1,
		Value = { Min = 0, Max = 50, Default = 30 },
		Callback = function(v)
			_smoothing = math.clamp(v, 0, 50)
		end,
	})
	section:Dropdown({
		Title = "瞄准部位",
		Icon = "locate",
		Values = { "Head", "Torso", "HumanoidRootPart" },
		Value = "Head",
		Callback = function(v)
			_aimPart = v
		end,
	})
	section:Toggle({
		Title = "粘性瞄�?,
		Icon = "magnet",
		Value = false,
		Callback = function(state)
			_stickyAim = state
		end,
	})
	section:Toggle({
		Title = "子弹预测",
		Icon = "zap",
		Value = false,
		Callback = function(state)
			_prediction = state
		end,
	})
	section:Slider({
		Title = "预测�?,
		Icon = "gauge",
		Step = 10,
		Value = { Min = 0, Max = 300, Default = 100 },
		Callback = function(v)
			_predictionAmount = math.max(0, v)
		end,
	})
	section:Keybind({
		Title = "自瞄按键",
		Icon = "keyboard",
		Value = "E",
		Callback = function(v)
			local code = Enum.KeyCode[v]
			if code then
				_keybind = code
			end
			_useMouse = false
		end,
	})
end

return Aimbot
