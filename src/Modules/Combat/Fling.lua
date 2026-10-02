local Unload = require("../../Core/Unload")

local Fling = {}
Fling.Title = "甩飞"

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer

local function getRoot(char)
	if char and char:FindFirstChildOfClass("Humanoid") then
		return char:FindFirstChildOfClass("Humanoid").RootPart
	end
	return nil
end

local function breakVelocity()
	local V3 = Vector3.new(0, 0, 0)
	local char = LocalPlayer.Character
	if not char then return end
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Velocity = V3
			v.RotVelocity = V3
		end
	end
end

local flingActive = false
local flingBodyVelocity = nil
local flingDiedConnection = nil
local flingLoopConnection = nil
local flingSteppedConnection = nil
local flingNoclipConn = nil
local flingCharRemovingConn = nil
local flingLastPosition = nil

local function stopFling()
	flingActive = false

	if flingDiedConnection then
		flingDiedConnection:Disconnect()
		flingDiedConnection = nil
	end
	if flingLoopConnection then
		flingLoopConnection:Disconnect()
		flingLoopConnection = nil
	end
	if flingSteppedConnection then
		flingSteppedConnection:Disconnect()
		flingSteppedConnection = nil
	end
	if flingNoclipConn then
		flingNoclipConn:Disconnect()
		flingNoclipConn = nil
	end
	if flingCharRemovingConn then
		flingCharRemovingConn:Disconnect()
		flingCharRemovingConn = nil
	end

	pcall(function()
		if flingBodyVelocity and flingBodyVelocity.Parent then
			flingBodyVelocity:Destroy()
		end
	end)
	flingBodyVelocity = nil

	pcall(function()
		local char = LocalPlayer.Character
		if char then
			for _, child in pairs(char:GetDescendants()) do
				if child:IsA("BasePart") then
					child.CanCollide = true
					child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
				end
			end
		end
	end)
end

local function startFling()
	if flingActive then return end
	stopFling()

	local char = LocalPlayer.Character
	if not char then return end

	local root = getRoot(char)
	if not root then return end
	flingLastPosition = root.Position

	pcall(function()
		for _, child in pairs(char:GetDescendants()) do
			if child:IsA("BasePart") then
				child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
			end
		end
	end)

	flingNoclipConn = RunService.Stepped:Connect(function()
		if not flingActive then return end
		local c = LocalPlayer.Character
		if c and c.Parent then
			for _, child in pairs(c:GetDescendants()) do
				if child:IsA("BasePart") and child.CanCollide == true and child.Name ~= "FloatPart" then
					child.CanCollide = false
				end
			end
		end
	end)

	flingBodyVelocity = Instance.new("BodyAngularVelocity")
	flingBodyVelocity.Name = "__FlingVelocity"
	flingBodyVelocity.Parent = root
	flingBodyVelocity.AngularVelocity = Vector3.new(0, 99999, 0)
	flingBodyVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
	flingBodyVelocity.P = math.huge

	flingActive = true

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		flingDiedConnection = humanoid.Died:Connect(function()
			stopFling()
		end)
	end

	flingCharRemovingConn = LocalPlayer.CharacterRemoving:Connect(function()
		stopFling()
	end)

	flingSteppedConnection = RunService.Stepped:Connect(function()
		if not flingActive then return end
		if not char or not char.Parent or not root or not root.Parent then
			stopFling()
			return
		end
		local currentPos = root.Position
		if (currentPos - flingLastPosition).Magnitude > 2000 then
			breakVelocity()
			if flingBodyVelocity then
				flingBodyVelocity.AngularVelocity = Vector3.zero
			end
		end
		flingLastPosition = currentPos
	end)

	flingLoopConnection = RunService.Heartbeat:Connect(function()
		if not flingActive then return end
		if not flingBodyVelocity or not flingBodyVelocity.Parent then
			stopFling()
			return
		end
		flingBodyVelocity.AngularVelocity = Vector3.new(0, 99999, 0)
		task.wait(0.2)
		if flingBodyVelocity then
			flingBodyVelocity.AngularVelocity = Vector3.new(0, 0, 0)
		end
		task.wait(0.1)
	end)
end

local flingShortcutEnabled = false
local flingKeybind = Enum.KeyCode.G
local flingHotkeyConnection = nil

local function onFlingHotkeyInput(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == flingKeybind and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		if flingActive then
			stopFling()
		else
			startFling()
		end
	end
end

local function setShortcutEnabled(enabled)
	if enabled == flingShortcutEnabled then return end
	if enabled then
		if flingHotkeyConnection then
			flingHotkeyConnection:Disconnect()
		end
		flingHotkeyConnection = UserInputService.InputBegan:Connect(onFlingHotkeyInput)
		flingShortcutEnabled = true
	else
		if flingHotkeyConnection then
			flingHotkeyConnection:Disconnect()
			flingHotkeyConnection = nil
		end
		if flingActive then
			stopFling()
		end
		flingShortcutEnabled = false
	end
end

local flyflingActive = false
local flyflingVehicleFly = nil
local flyflingWalkFling = nil
local flyflingSpeed = 20
local flyflingCharRemovingConn = nil
local flyflingDiedConn = nil

local function stopFlyFling()
	if flyflingDiedConn then
		flyflingDiedConn:Disconnect()
		flyflingDiedConn = nil
	end
	if flyflingCharRemovingConn then
		flyflingCharRemovingConn:Disconnect()
		flyflingCharRemovingConn = nil
	end
	if flyflingVehicleFly then
		pcall(flyflingVehicleFly.disable)
		flyflingVehicleFly = nil
	end
	if flyflingWalkFling then
		pcall(flyflingWalkFling.disable)
		flyflingWalkFling = nil
	end
	breakVelocity()
	flyflingActive = false
end

local function startFlyFling(speed)
	stopFlyFling()

	if speed and type(speed) == "number" then
		flyflingSpeed = speed
	end

	local function startVehicleFly()
		local char = LocalPlayer.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local flyActive = true
		local flyBodyVelocity = nil
		local flyBodyGyro = nil
		local root = getRoot(char)

		if root then
			flyBodyGyro = Instance.new("BodyGyro")
			flyBodyGyro.P = 9e4
			flyBodyGyro.Parent = root
			flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
			flyBodyGyro.CFrame = Workspace.CurrentCamera.CFrame

			flyBodyVelocity = Instance.new("BodyVelocity")
			flyBodyVelocity.Parent = root
			flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
			flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		end

		humanoid.PlatformStand = true

		local keyDownConnection
		local keyUpConnection
		local control = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}

		keyDownConnection = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			local speedVal = flyflingSpeed
			if input.KeyCode == Enum.KeyCode.W then
				control.F = speedVal
			elseif input.KeyCode == Enum.KeyCode.S then
				control.B = -speedVal
			elseif input.KeyCode == Enum.KeyCode.A then
				control.L = -speedVal
			elseif input.KeyCode == Enum.KeyCode.D then
				control.R = speedVal
			end
		end)

		keyUpConnection = UserInputService.InputEnded:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode == Enum.KeyCode.W then
				control.F = 0
			elseif input.KeyCode == Enum.KeyCode.S then
				control.B = 0
			elseif input.KeyCode == Enum.KeyCode.A then
				control.L = 0
			elseif input.KeyCode == Enum.KeyCode.D then
				control.R = 0
			end
		end)

		local renderConnection = RunService.RenderStepped:Connect(function()
			if not flyActive or not char or not char.Parent then
				return
			end
			local camera = Workspace.CurrentCamera
			if flyBodyVelocity then
				local velocity = ((camera.CFrame.LookVector * (control.F + control.B)) +
					((camera.CFrame * CFrame.new(control.L + control.R, (control.F + control.B + control.Q + control.E) * 0.2, 0).p) - camera.CFrame.p)) * 50
				flyBodyVelocity.Velocity = velocity
			end
			if flyBodyGyro then
				flyBodyGyro.CFrame = camera.CFrame
			end
		end)

		return {
			disable = function()
				flyActive = false
				if keyDownConnection then keyDownConnection:Disconnect() end
				if keyUpConnection then keyUpConnection:Disconnect() end
				if renderConnection then renderConnection:Disconnect() end
				pcall(function()
					if flyBodyVelocity then flyBodyVelocity:Destroy() end
					if flyBodyGyro then flyBodyGyro:Destroy() end
				end)
				if humanoid then humanoid.PlatformStand = false end
			end
		}
	end

	local function startWalkFlingInner()
		local walkActive = true
		local char = LocalPlayer.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		local ffDiedConn = nil

		if humanoid then
			ffDiedConn = humanoid.Died:Connect(function()
				if walkActive then
					stopFlyFling()
				end
			end)
		end

		if char then
			pcall(function()
				for _, child in pairs(char:GetDescendants()) do
					if child:IsA("BasePart") then
						child.CanCollide = false
					end
				end
			end)
		end

		local moveVal = 0.1
		local walkLoop = RunService.Heartbeat:Connect(function()
			if not walkActive or not char or not char.Parent then
				return
			end
			local root = getRoot(char)
			if root then
				local vel = root.Velocity
				root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)

				task.wait()
				if root and root.Parent then
					root.Velocity = vel
				end

				task.wait()
				if root and root.Parent then
					root.Velocity = vel + Vector3.new(0, moveVal, 0)
					moveVal = moveVal * -1
				end
			end
		end)

		return {
			disable = function()
				walkActive = false
				if walkLoop then walkLoop:Disconnect() end
				if ffDiedConn then ffDiedConn:Disconnect() end
				pcall(function()
					local c = LocalPlayer.Character
					if c then
						for _, child in pairs(c:GetDescendants()) do
							if child:IsA("BasePart") then
								child.CanCollide = true
							end
						end
					end
				end)
			end
		}
	end

	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		flyflingDiedConn = humanoid.Died:Connect(function()
			stopFlyFling()
		end)
	end

	flyflingCharRemovingConn = LocalPlayer.CharacterRemoving:Connect(function()
		stopFlyFling()
	end)

	flyflingVehicleFly = startVehicleFly()
	flyflingWalkFling = startWalkFlingInner()
	flyflingActive = true
end

local walkflingActive = false
local walkflingLoop = nil
local walkflingDiedConn = nil
local walkflingCharRemovingConn = nil

local function stopWalkFling()
	walkflingActive = false

	if walkflingLoop then
		walkflingLoop:Disconnect()
		walkflingLoop = nil
	end
	if walkflingDiedConn then
		walkflingDiedConn:Disconnect()
		walkflingDiedConn = nil
	end
	if walkflingCharRemovingConn then
		walkflingCharRemovingConn:Disconnect()
		walkflingCharRemovingConn = nil
	end

	pcall(function()
		local char = LocalPlayer.Character
		if char then
			for _, child in pairs(char:GetDescendants()) do
				if child:IsA("BasePart") then
					child.CanCollide = true
				end
			end
		end
	end)
end

local function startWalkFling()
	if walkflingActive then return end
	stopWalkFling()

	local char = LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		walkflingDiedConn = humanoid.Died:Connect(function()
			stopWalkFling()
		end)
	end

	walkflingCharRemovingConn = LocalPlayer.CharacterRemoving:Connect(function()
		stopWalkFling()
	end)

	pcall(function()
		for _, child in pairs(char:GetDescendants()) do
			if child:IsA("BasePart") then
				child.CanCollide = false
			end
		end
	end)

	walkflingActive = true
	local moveVal = 0.1

	walkflingLoop = RunService.Heartbeat:Connect(function()
		if not walkflingActive then return end

		char = LocalPlayer.Character
		if not char or not char.Parent then
			stopWalkFling()
			return
		end

		local root = getRoot(char)
		if not root then return end

		local vel = root.Velocity
		root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)

		RunService.RenderStepped:Wait()
		if char and char.Parent and root and root.Parent then
			root.Velocity = vel
		end

		RunService.Stepped:Wait()
		if char and char.Parent and root and root.Parent then
			root.Velocity = vel + Vector3.new(0, moveVal, 0)
			moveVal = moveVal * -1
		end
	end)
end

local invisflingActive = false
local invisflingCleanup = {}
local invisflingCharRemovingConn = nil

local function stopInvisFling()
	if not invisflingActive then return end
	invisflingActive = false

	if invisflingCharRemovingConn then
		invisflingCharRemovingConn:Disconnect()
		invisflingCharRemovingConn = nil
	end

	if invisflingCleanup.steppedConn then
		invisflingCleanup.steppedConn:Disconnect()
	end

	if invisflingCleanup.flyCleanup then
		pcall(invisflingCleanup.flyCleanup)
	end

	pcall(function()
		if invisflingCleanup.bodyThrust then
			invisflingCleanup.bodyThrust:Destroy()
		end
	end)

	pcall(function()
		local char = LocalPlayer.Character
		if char and invisflingCleanup.originalChar then
			for _, v in pairs(char:GetChildren()) do
				if v ~= invisflingCleanup.originalRoot and v.Name ~= "Humanoid" then
					v:Destroy()
				end
			end
			if invisflingCleanup.originalRoot and invisflingCleanup.originalRoot.Parent then
				invisflingCleanup.originalRoot.Transparency = 0
				invisflingCleanup.originalRoot.Color = Color3.new(1, 1, 1)
			end
		end
	end)

	pcall(function()
		Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character
	end)

	invisflingCleanup = {}
end

local function startInvisFling()
	if invisflingActive then return end
	stopInvisFling()

	local char = LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end

	invisflingCharRemovingConn = LocalPlayer.CharacterRemoving:Connect(function()
		stopInvisFling()
	end)

	local fakeModel = Instance.new("Model")
	fakeModel.Parent = char

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.CanCollide = false
	torso.Anchored = true

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Parent = fakeModel
	head.Anchored = true
	head.CanCollide = false

	local fakeHumanoid = Instance.new("Humanoid")
	fakeHumanoid.Name = "Humanoid"
	fakeHumanoid.Parent = fakeModel

	torso.Position = Vector3.new(0, 9999, 0)

	local originalRoot = getRoot(char)
	invisflingCleanup.originalRoot = originalRoot
	invisflingCleanup.originalChar = char

	LocalPlayer.Character = fakeModel
	task.wait(3)
	LocalPlayer.Character = char
	task.wait(3)

	local newHumanoid = Instance.new("Humanoid")
	newHumanoid.Parent = char

	local root = getRoot(char)
	invisflingCleanup.root = root

	for _, v in pairs(char:GetChildren()) do
		if v ~= root and v.Name ~= "Humanoid" then
			v:Destroy()
		end
	end

	if root then
		root.Transparency = 0
		root.Color = Color3.new(1, 1, 1)
		root.CanCollide = false
	end

	invisflingCleanup.steppedConn = RunService.Stepped:Connect(function()
		if LocalPlayer.Character and getRoot(LocalPlayer.Character) then
			getRoot(LocalPlayer.Character).CanCollide = false
		end
	end)

	local function startFly()
		local flyChar = LocalPlayer.Character
		local flyHumanoid = flyChar and flyChar:FindFirstChildOfClass("Humanoid")
		if not flyHumanoid then return end

		flyHumanoid.PlatformStand = true

		local flyRoot = getRoot(flyChar)
		local flyBodyVelocity = Instance.new("BodyVelocity")
		flyBodyVelocity.Parent = flyRoot
		flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

		local flyBodyGyro = Instance.new("BodyGyro")
		flyBodyGyro.Parent = flyRoot
		flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		flyBodyGyro.P = 9e4

		local flyControl = {F = 0, B = 0, L = 0, R = 0}
		local flySpeed = 50

		local keyDown = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode == Enum.KeyCode.W then flyControl.F = flySpeed
			elseif input.KeyCode == Enum.KeyCode.S then flyControl.B = -flySpeed
			elseif input.KeyCode == Enum.KeyCode.A then flyControl.L = -flySpeed
			elseif input.KeyCode == Enum.KeyCode.D then flyControl.R = flySpeed
			end
		end)

		local keyUp = UserInputService.InputEnded:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode == Enum.KeyCode.W then flyControl.F = 0
			elseif input.KeyCode == Enum.KeyCode.S then flyControl.B = 0
			elseif input.KeyCode == Enum.KeyCode.A then flyControl.L = 0
			elseif input.KeyCode == Enum.KeyCode.D then flyControl.R = 0
			end
		end)

		local renderConn = RunService.RenderStepped:Connect(function()
			if not flyChar or not flyChar.Parent then return end
			local camera = Workspace.CurrentCamera
			flyBodyGyro.CFrame = camera.CFrame
			flyBodyVelocity.Velocity = ((camera.CFrame.LookVector * (flyControl.F + flyControl.B)) +
				((camera.CFrame * CFrame.new(flyControl.L + flyControl.R, (flyControl.F + flyControl.B) * 0.2, 0).p) - camera.CFrame.p)) * flySpeed
		end)

		return function()
			keyDown:Disconnect()
			keyUp:Disconnect()
			renderConn:Disconnect()
			pcall(function()
				flyBodyVelocity:Destroy()
				flyBodyGyro:Destroy()
			end)
			if flyHumanoid then flyHumanoid.PlatformStand = false end
		end
	end

	invisflingCleanup.flyCleanup = startFly()

	Workspace.CurrentCamera.CameraSubject = root
	invisflingCleanup.bodyThrust = Instance.new("BodyThrust")
	invisflingCleanup.bodyThrust.Parent = root
	invisflingCleanup.bodyThrust.Force = Vector3.new(99999, 99999 * 10, 99999)
	invisflingCleanup.bodyThrust.Location = root.Position

	invisflingActive = true
end

local targetUnloaded = false

local function getPlayer(PlayerName)
	PlayerName = PlayerName:lower()
	if PlayerName == "random" then
		local players = Players:GetPlayers()
		pcall(function() table.remove(players, table.find(players, LocalPlayer)) end)
		return players[math.random(#players)]
	else
		for _, player in next, Players:GetPlayers() do
			if player ~= LocalPlayer then
				if player.Name:lower():match("^" .. PlayerName) or player.DisplayName:lower():match("^" .. PlayerName) then
					return player
				end
			end
		end
	end
end

local function Fling(TargetPlayer)
	local OldPos = nil
	local FallenPartsDestroyHeight = nil
	local Character = LocalPlayer.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	local HumanoidRootPart = Humanoid and Humanoid.RootPart
	local TargetCharacter = TargetPlayer.Character
	local TargetHumanoid = TargetCharacter and TargetCharacter:FindFirstChildOfClass("Humanoid")
	local TargetRootPart = TargetHumanoid and TargetHumanoid.RootPart
	local TargetHead = TargetCharacter and TargetCharacter:FindFirstChild("Head")
	local Accessory = TargetCharacter and TargetCharacter:FindFirstChildOfClass("Accessory")
	local Handle = Accessory and Accessory:FindFirstChild("Handle")

	if Character and Humanoid and HumanoidRootPart then
		if HumanoidRootPart.Velocity.Magnitude < 50 then OldPos = HumanoidRootPart.CFrame end
		if TargetHumanoid and TargetHumanoid.Sit then return end
		if not TargetCharacter:FindFirstChildWhichIsA("BasePart") then return end
		if TargetHead then
			Workspace.CurrentCamera.CameraSubject = TargetHead
		elseif not TargetHead and Handle then
			Workspace.CurrentCamera.CameraSubject = Handle
		elseif TargetHumanoid and TargetRootPart then
			Workspace.CurrentCamera.CameraSubject = TargetHumanoid
		end

		local function FPos(BasePart, Pos, Ang)
			local newCFrame = CFrame.new(BasePart.Position) * Pos * Ang
			HumanoidRootPart.CFrame = newCFrame
			Character:SetPrimaryPartCFrame(newCFrame)
			HumanoidRootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
			HumanoidRootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
		end

		local function SFBasePart(BasePart)
			local Now = tick()
			local Angle = 0
			repeat
				if targetUnloaded then break end
				if HumanoidRootPart and TargetHumanoid then
					if BasePart.Velocity.Magnitude < 50 then
						Angle = Angle + 100
						FPos(BasePart, CFrame.new(0, 1.5, 0) + TargetHumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0) + TargetHumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + TargetHumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + TargetHumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 1.5, 0) + TargetHumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0) + TargetHumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
					else
						FPos(BasePart, CFrame.new(0, 1.5, TargetHumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, -TargetHumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 1.5, TargetHumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 1.5, TargetRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, -TargetRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 1.5, TargetRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
						task.wait()
					end
				else
					break
				end
			until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TargetCharacter or TargetHumanoid.Sit or Humanoid.Health <= 0 or tick() > Now + 2
		end

		FallenPartsDestroyHeight = Workspace.FallenPartsDestroyHeight
		Workspace.FallenPartsDestroyHeight = 0/0
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

		local BV = Instance.new("BodyVelocity")
		BV.Parent = HumanoidRootPart
		BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
		BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)

		if TargetRootPart and TargetHead then
			if (TargetRootPart.CFrame.Position - TargetHead.CFrame.Position).Magnitude > 5 then SFBasePart(TargetHead) else SFBasePart(TargetRootPart) end
		elseif TargetRootPart then
			SFBasePart(TargetRootPart)
		elseif TargetHead then
			SFBasePart(TargetHead)
		elseif Accessory and Handle then
			SFBasePart(Handle)
		else
			return
		end

		BV:Destroy()
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		Workspace.CurrentCamera.CameraSubject = Humanoid

		if OldPos then
			repeat
				HumanoidRootPart.CFrame = OldPos * CFrame.new(0, .5, 0)
				Character:SetPrimaryPartCFrame(OldPos * CFrame.new(0, .5, 0))
				Humanoid:ChangeState("GettingUp")
				for _, x in next, Character:GetChildren() do
					if x:IsA("BasePart") then
						x.Velocity = Vector3.new()
						x.RotVelocity = Vector3.new()
					end
				end
				task.wait()
			until (HumanoidRootPart.Position - OldPos.Position).Magnitude < 25
		end

		Workspace.FallenPartsDestroyHeight = FallenPartsDestroyHeight
	else
		return
	end
end

local function tofling(targetName)
	local name = tostring(targetName or "")
	if name == "" then return end

	if name:lower() == "all" then
		for _, pl in next, Players:GetPlayers() do
			if pl ~= LocalPlayer then
				pcall(function()
					Fling(pl)
				end)
			end
		end
		return
	end

	local target = getPlayer(name)
	if target and target ~= LocalPlayer then
		pcall(function()
			Fling(target)
		end)
	end
end

Unload.OnUnload(function()
	if flingActive then stopFling() end
	if flyflingActive then stopFlyFling() end
	if walkflingActive then stopWalkFling() end
	if invisflingActive then stopInvisFling() end
	targetUnloaded = true
end)

function Fling.Init(Tabs, ctx)
	local settings = ctx.FeatureSettings("甩飞")
	Tabs.Combat:Toggle({
		Title = "普通甩飞",
		Icon = "send",
		Value = false,
		Callback = function(state)
			if state then
				startFling()
			else
				stopFling()
			end
		end,
	})
	Tabs.Combat:Toggle({
		Title = "飞行甩飞",
		Icon = "plane",
		Value = false,
		Callback = function(state)
			if state then
				startFlyFling(flyflingSpeed)
			else
				stopFlyFling()
			end
		end,
	})
	settings:Slider({
		Title = "飞行甩飞速度",
		Icon = "gauge",
		Step = 1,
		Value = { Min = 5, Max = 100, Default = 20 },
		Callback = function(v)
			flyflingSpeed = v
		end,
	})
	Tabs.Combat:Toggle({
		Title = "走路甩飞",
		Icon = "footprints",
		Value = false,
		Callback = function(state)
			if state then
				startWalkFling()
			else
				stopWalkFling()
			end
		end,
	})
	Tabs.Combat:Toggle({
		Title = "隐身甩飞",
		Icon = "ghost",
		Value = false,
		Callback = function(state)
			if state then
				task.spawn(startInvisFling)
			else
				stopInvisFling()
			end
		end,
	})
	Tabs.Combat:Toggle({
		Title = "Ctrl+G 快捷甩飞",
		Icon = "keyboard",
		Value = false,
		Callback = function(state)
			setShortcutEnabled(state)
		end,
	})
	local targetName = ""
	Tabs.Combat:Input({
		Title = "指定甩飞目标",
		Icon = "user",
		Value = "",
		Placeholder = "玩家名/ random / all",
		Callback = function(v)
			targetName = v
		end,
	})
	Tabs.Combat:Button({
		Title = "甩飞目标",
		Icon = "send",
		Callback = function()
			task.spawn(function()
				tofling(targetName)
			end)
		end,
	})
end

return Fling
