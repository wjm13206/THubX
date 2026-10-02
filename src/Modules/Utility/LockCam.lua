local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local LockCam = {}
LockCam.Title = "锁定视角"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local RunService = Services.RunService
local ContextActionService = Services.Get("ContextActionService")
local UserInputService = Services.UserInputService

local ACTION = "THubXLockCamera"
local bindKey = Enum.KeyCode.Tab

local enabled = false
local locking = false
local bound = false
local savedHRP = nil
local savedCF = nil

local function getHRP()
	local character = Players.LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function updateCamera()
	if not locking then
		return
	end
	local hrp = getHRP()
	if not hrp or not savedHRP or not savedCF then
		return
	end
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end
	local offset = savedCF.Position - savedHRP.Position
	local newPos = hrp.Position + offset
	cam.CFrame = CFrame.lookAt(newPos, newPos + savedCF.LookVector)
end

local function stopLock()
	locking = false
	savedHRP = nil
	savedCF = nil
	pcall(function()
		RunService:UnbindFromRenderStep("THubXCameraLock")
	end)
end

local function onAction(_, state)
	if not enabled then
		return Enum.ContextActionResult.Pass
	end
	if state == Enum.UserInputState.Begin then
		if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			return Enum.ContextActionResult.Pass
		end
		local hrp = getHRP()
		local cam = Workspace.CurrentCamera
		if hrp and cam then
			savedHRP = hrp.CFrame
			savedCF = cam.CFrame
			locking = true
			RunService:BindToRenderStep("THubXCameraLock", Enum.RenderPriority.Camera.Value + 1, updateCamera)
		end
		return Enum.ContextActionResult.Sink
	elseif state == Enum.UserInputState.End then
		stopLock()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function bind()
	if bound then
		pcall(function()
			ContextActionService:UnbindAction(ACTION)
		end)
	end
	ContextActionService:BindActionAtPriority(
		ACTION,
		onAction,
		false,
		Enum.ContextActionPriority.High.Value,
		bindKey)
	bound = true
end

local function unbind()
	if bound then
		pcall(function()
			ContextActionService:UnbindAction(ACTION)
		end)
		bound = false
	end
end

local function setEnabled(on)
	if on == enabled then
		return
	end
	enabled = on
	if on then
		bind()
	else
		stopLock()
		unbind()
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function LockCam.Init(Tabs, ctx)
	local settings = ctx.FeatureSettings("锁定视角")
	Tabs.Utility:Toggle({
		Title = "按住锁定视角",
		Icon = "video",
		Value = false,
		Callback = function(v)
			setEnabled(v)
		end,
	})
	settings:Keybind({
		Title = "锁定按键名",
		Icon = "keyboard",
		Value = "Tab",
		Callback = function(v)
			local code = Enum.KeyCode[v]
			if code then
				bindKey = code
				if enabled then
					bind()
				end
			end
		end,
	})
end

return LockCam
