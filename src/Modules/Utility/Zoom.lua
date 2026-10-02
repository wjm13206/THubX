local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "缩放视角"

local cloneref = Services.cloneref or clonereference or function(obj) return obj end
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Workspace = cloneref(game:GetService("Workspace"))

local bindKey = Enum.KeyCode.C
local tweenTime = 0.15
local zoomStep = 5
local minZoomFOV = 5
local defaultZoomFOV = 30

local isEnabled = false
local isZooming = false
local normalFOV = 70
local currentZoomFOV = defaultZoomFOV

local inputBeganConn = nil
local inputEndedConn = nil
local camera = Workspace.CurrentCamera

local function updateCameraFOV(targetFOV)
	local tween = TweenService:Create(camera, TweenInfo.new(tweenTime), { FieldOfView = targetFOV })
	tween:Play()
end

local function adjustZoom(delta)
	if not isZooming or not isEnabled then return end
	local newZoomFOV = math.clamp(currentZoomFOV + delta * zoomStep, minZoomFOV, normalFOV)
	if newZoomFOV == currentZoomFOV then return end
	currentZoomFOV = newZoomFOV
	updateCameraFOV(currentZoomFOV)
end

local function startZoom()
	if not isEnabled then return end
	isZooming = true
	currentZoomFOV = defaultZoomFOV
	updateCameraFOV(currentZoomFOV)
end

local function stopZoom()
	if not isEnabled then return end
	isZooming = false
	updateCameraFOV(normalFOV)
end

local function isMatchingInput(input)
	return input.UserInputType == bindKey or input.KeyCode == bindKey
end

local function enable()
	if isEnabled then return end
	camera = Workspace.CurrentCamera
	normalFOV = camera.FieldOfView
	defaultZoomFOV = math.clamp(defaultZoomFOV, minZoomFOV, normalFOV)
	currentZoomFOV = defaultZoomFOV
	inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if isMatchingInput(input) and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			startZoom()
		end
		if isZooming then
			if input.KeyCode == Enum.KeyCode.Minus then
				adjustZoom(-1)
			elseif input.KeyCode == Enum.KeyCode.Equals then
				adjustZoom(1)
			end
		end
	end)
	inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if isMatchingInput(input) then
			stopZoom()
		end
	end)
	isEnabled = true
end

local function disable()
	if not isEnabled then return end
	if isZooming then
		stopZoom()
		isZooming = false
	end
	if inputBeganConn then
		inputBeganConn:Disconnect()
		inputBeganConn = nil
	end
	if inputEndedConn then
		inputEndedConn:Disconnect()
		inputEndedConn = nil
	end
	isEnabled = false
end

Unload.OnUnload(disable)

function M.Init(Tabs, ctx)
	local settings = ctx.FeatureSettings("缩放视角")
	Tabs.Utility:Toggle({
		Title = "启用缩放",
		Icon = "zoom-in",
		Value = false,
		Callback = function(state)
			if state then
				enable()
			else
				disable()
			end
		end,
	})
	settings:Keybind({
		Title = "缩放按键",
		Icon = "keyboard",
		Value = "C",
		Callback = function(v)
			local code = Enum.KeyCode[v]
			if code then
				bindKey = code
			end
		end,
	})
	settings:Slider({
		Title = "缩放视野",
		Icon = "eye",
		Step = 1,
		Value = { Min = 5, Max = 70, Default = 30 },
		Callback = function(v)
			defaultZoomFOV = math.clamp(v, minZoomFOV, normalFOV)
		end,
	})
end

return M
