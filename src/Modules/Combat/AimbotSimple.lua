local Unload = require("../../Core/Unload")

local AimbotSimple = {}
AimbotSimple.Title = "轻量自瞄"

local hasDrawing = typeof(rawget(_G, "Drawing")) == "table" and typeof(Drawing.new) == "function"

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local active = false
local fov = 75
local ring = nil
local conn = nil
local keyConn = nil

local function getCam()
	return game.Workspace.CurrentCamera
end

local function lookAt(target)
	local cam = getCam()
	local lookVector = (target - cam.CFrame.Position).unit
	cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + lookVector)
end

local function getClosest(trgPart)
	local cam = getCam()
	local nearest = nil
	local last = math.huge
	local center = cam.ViewportSize / 2

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= Players.LocalPlayer then
			local part = player.Character and player.Character:FindFirstChild(trgPart)
			if part then
				local ePos, isVisible = cam:WorldToViewportPoint(part.Position)
				local distance = (Vector2.new(ePos.x, ePos.y) - center).Magnitude

				if distance < last and isVisible and distance < fov then
					last = distance
					nearest = player
				end
			end
		end
	end

	return nearest
end

local function enable()
	if active then return end
	if not hasDrawing then return false end
	active = true

	ring = Drawing.new("Circle")
	ring.Visible = true
	ring.Thickness = 2
	ring.Color = Color3.fromRGB(0, 0, 0)
	ring.Filled = false
	ring.Radius = fov
	ring.Position = getCam().ViewportSize / 2

	conn = RunService.RenderStepped:Connect(function()
		if not active then return end
		ring.Position = getCam().ViewportSize / 2
		local closest = getClosest("Head")
		if closest and closest.Character and closest.Character:FindFirstChild("Head") then
			lookAt(closest.Character.Head.Position)
		end
	end)

	keyConn = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Delete and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			disable()
		end
	end)

	return true
end

local function disable()
	if not active then return end
	active = false
	if conn then
		conn:Disconnect()
		conn = nil
	end
	if keyConn then
		keyConn:Disconnect()
		keyConn = nil
	end
	if ring then
		pcall(function() ring:Remove() end)
		ring = nil
	end
end

Unload.OnUnload(function()
	disable()
end)

function AimbotSimple.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Combat, AimbotSimple.Title, { Icon = "triangle-alert" })
	if not hasDrawing then
		folder:Button({
			Title = "当前执行器不支持 Drawing",
			Icon = "triangle-alert",
			Callback = function()
				ctx.Utils.NotifyFallback("THubX", "当前执行器不支持 Drawing 库")
			end,
		})
		return
	end
	folder:Toggle({
		Title = "启用轻量自瞄",
		Icon = "crosshair",
		Value = false,
		Callback = function(state)
			if state then
				if not enable() then
					ctx.WindUI:Notify({ Title = "轻量自瞄", Content = "启动失败", Duration = 3 })
				end
			else
				disable()
			end
		end,
	})
	folder:Slider({
		Title = "索敌范围",
		Icon = "scan",
		Step = 5,
		Value = { Min = 20, Max = 300, Default = 75 },
		Callback = function(v)
			fov = v
			if ring then
				ring.Radius = v
			end
		end,
	})
end

return AimbotSimple
