local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local DeathBall = {}
DeathBall.Title = "死亡球"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local VirtualInputManager = Services.Get("VirtualInputManager")
local ContextActionService = Services.Get("ContextActionService")
local RunService = Services.RunService
local LocalPlayer = Players.LocalPlayer

local connections = {}
local mainGui = nil
local statusText = nil
local distanceText = nil
local targetBall = nil
local isEnabled = false
local character = nil
local rootPart = nil

local function findBall()
	for _, child in pairs(Workspace:GetChildren()) do
		if child.Name == "Part" and child:IsA("BasePart") then
			return child
		end
	end
	return nil
end

local function createUI()
	if mainGui then
		return
	end
	mainGui = Instance.new("ScreenGui")
	mainGui.Name = "THubXDeathBall"
	if gethui then
		mainGui.Parent = gethui()
	else
		mainGui.Parent = Services.CoreGui
	end
	statusText = Instance.new("TextLabel")
	statusText.Parent = mainGui
	statusText.Size = UDim2.new(0, 200, 0, 30)
	statusText.Position = UDim2.new(0.5, -100, 0.1, 0)
	statusText.BackgroundTransparency = 1
	statusText.Text = "游戏未开始"
	statusText.TextColor3 = Color3.fromRGB(230, 230, 250)
	statusText.TextSize = 25
	statusText.Font = Enum.Font.GothamBold
	distanceText = Instance.new("TextLabel")
	distanceText.Parent = mainGui
	distanceText.Size = UDim2.new(0, 200, 0, 20)
	distanceText.Position = UDim2.new(0.5, -100, 0.14, 0)
	distanceText.BackgroundTransparency = 1
	distanceText.Text = ""
	distanceText.TextColor3 = Color3.fromRGB(166, 166, 166)
	distanceText.TextSize = 15
end

local function destroyUI()
	if mainGui then
		mainGui:Destroy()
		mainGui = nil
		statusText = nil
		distanceText = nil
	end
end

local function teleportToBallAndBack()
	if not targetBall or not targetBall:IsDescendantOf(Workspace) then
		return
	end
	if not rootPart or not rootPart.Parent then
		return
	end
	local currentCFrame = rootPart.CFrame
	local ballCFrame = targetBall.CFrame
	local ballSize = targetBall.Size
	local radius = (ballSize.X + ballSize.Y + ballSize.Z) / 6
	local offset = radius + 2
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
	for _ = 1, 3 do
		RunService.Heartbeat:Wait()
	end
	local direction = (currentCFrame.Position - ballCFrame.Position).Unit
	local newPos = ballCFrame.Position + direction * offset
	rootPart.CFrame = CFrame.new(newPos, ballCFrame.Position)
	for _ = 1, 3 do
		RunService.Heartbeat:Wait()
	end
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
	rootPart.CFrame = currentCFrame
end

local function updateUI()
	local ball = targetBall
	local playerChar = LocalPlayer.Character
	local playerPos = playerChar and playerChar:FindFirstChild("HumanoidRootPart")
	if not ball or not playerPos then
		if statusText then
			statusText.Text = "游戏未开始"
			statusText.TextColor3 = Color3.fromRGB(230, 230, 250)
		end
		if distanceText then
			distanceText.Text = ""
		end
		return
	end
	local isSpectating = playerPos.Position.Z < -767.55 and playerPos.Position.Y > 279.17
	if isSpectating then
		if statusText then
			statusText.Text = "观战中"
			statusText.TextColor3 = Color3.fromRGB(230, 230, 250)
		end
		if distanceText then
			distanceText.Text = ""
		end
	else
		local locked = ball.Highlight and ball.Highlight.FillColor ~= Color3.new(1, 1, 1)
		if statusText then
			if locked then
				statusText.Text = "已被球锁定"
				statusText.TextColor3 = Color3.fromRGB(238, 17, 17)
			else
				statusText.Text = "未被球锁定"
				statusText.TextColor3 = Color3.fromRGB(17, 238, 17)
			end
		end
		if distanceText then
			distanceText.Text = string.format("%.0f", (ball.Position - playerPos.Position).Magnitude)
		end
	end
end

local function enable()
	if isEnabled then
		return
	end
	character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	rootPart = character:WaitForChild("HumanoidRootPart")
	createUI()
	if mainGui then
		mainGui.Enabled = true
	end
	targetBall = findBall()
	table.insert(connections, Workspace.ChildAdded:Connect(function(child)
		if child.Name == "Part" and child:IsA("BasePart") then
			targetBall = child
		end
	end))
	table.insert(connections, Workspace.ChildRemoved:Connect(function(child)
		if child == targetBall then
			targetBall = nil
		end
	end))
	table.insert(connections, ContextActionService:BindAction("THubXTeleportToBall", function(actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			teleportToBallAndBack()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.R))
	table.insert(connections, RunService.Heartbeat:Connect(function()
		if isEnabled then
			updateUI()
		end
	end))
	table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(newChar)
		if isEnabled then
			character = newChar
			rootPart = character:WaitForChild("HumanoidRootPart")
		end
	end))
	isEnabled = true
end

local function disable()
	if not isEnabled then
		return
	end
	for _, connection in ipairs(connections) do
		if connection then
			if connection.Disconnect then
				connection:Disconnect()
			elseif connection.Unbind then
				connection:Unbind()
			end
		end
	end
	connections = {}
	if mainGui then
		mainGui.Enabled = false
	end
	isEnabled = false
	character = nil
	rootPart = nil
	targetBall = nil
end

Unload.OnUnload(function()
	disable()
	destroyUI()
	pcall(function()
		ContextActionService:UnbindAction("THubXTeleportToBall")
	end)
end)

function DeathBall.Init(Tabs, ctx)
	local section = Tabs.Games:Section({ Title = "死亡球" })
	section:Toggle({
		Title = "启用死亡球辅助",
		Icon = "volleyball",
		Value = false,
		Callback = function(state)
			if state then
				enable()
			else
				disable()
			end
		end,
	})
	section:Button({
		Title = "手动击球 (R键",
		Icon = "zap",
		Callback = function()
			teleportToBallAndBack()
		end,
	})
end

return DeathBall
