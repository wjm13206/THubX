local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local TPWalk = {}
TPWalk.Title = "瞬移行走"

local RunService = Services.RunService
local player = Services.Players.LocalPlayer

local enabled = false
local speed = 1
local conn = nil

local function update(delta)
	if not enabled then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not (character and humanoid and humanoid.Parent) then
		return
	end
	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude > 0 then
		character:TranslateBy(moveDir * speed * delta * 10)
	end
end

local function setEnabled(state)
	enabled = state
	if enabled then
		if not conn then
			conn = RunService.Heartbeat:Connect(update)
		end
	else
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function TPWalk.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Movement, TPWalk.Title, { Icon = "zap" })
	folder:Toggle({
		Title = "启用瞬移行走",
		Icon = "zap",
		Value = false,
		Callback = function(state)
			setEnabled(state)
		end,
	})
	folder:Slider({
		Title = "移动速度",
		Icon = "gauge",
		Step = 1,
		Value = {Min = 0, Max = 10, Default = 1},
		Callback = function(v)
			if type(v) == "number" and v >= 0 then
				speed = v
			end
		end,
	})
end

return TPWalk
