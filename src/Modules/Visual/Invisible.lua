local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Invisible = {}
Invisible.Title = "隐身"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local RunService = Services.RunService
local Lighting = Services.Get("Lighting")

local player = Players.LocalPlayer

local isInvis = false
local isRunning = false
local realChar = nil
local fakeChar = nil
local fixConn = nil
local fakeDiedConn = nil
local charAddedConn = nil

local function disc(conn)
	if conn then
		pcall(function()
			conn:Disconnect()
		end)
	end
	return nil
end

local function getRoot(char)
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(char)
	if not char then
		return nil
	end
	return char:FindFirstChildOfClass("Humanoid")
end

local function fixCamera(char)
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end
	local hum = getHumanoid(char)
	pcall(function()
		if hum then
			cam.CameraSubject = hum
		else
			cam.CameraSubject = char:FindFirstChildWhichIsA("BasePart")
		end
		cam.CameraType = Enum.CameraType.Custom
	end)
end

local function refreshAnimate(char)
	local anim = char and char:FindFirstChild("Animate")
	if anim and anim:IsA("LocalScript") then
		anim.Disabled = true
		task.wait()
		anim.Disabled = false
	end
end

local function restore()
	fixConn = disc(fixConn)
	fakeDiedConn = disc(fakeDiedConn)
	local fake = fakeChar
	local real = realChar
	fakeChar = nil
	isInvis = false
	isRunning = false
	if fake and fake.Parent then
		pcall(function()
			fake:Destroy()
		end)
	end
	if real then
		pcall(function()
			real.Parent = Workspace
			player.Character = real
			fixCamera(real)
			refreshAnimate(real)
		end)
	end
	realChar = nil
end

local function bindVoidCheck()
	fixConn = disc(fixConn)
	fixConn = RunService.Stepped:Connect(function()
		if not isInvis then
			return
		end
		local r = getRoot(fakeChar)
		if not r or not r.Parent then
			return
		end
		local ok, y = pcall(function()
			return r.Position.Y
		end)
		if not ok then
			return
		end
		local fallHeight = Workspace.FallenPartsDestroyHeight
		if y < fallHeight or y > math.abs(fallHeight) + 100000 then
			restore()
		end
	end)
end

local function setEnabled(on, toggleObj)
	if on then
		if isInvis or isRunning then
			return
		end
		isRunning = true
		local character = player.Character
		local humanoid = getHumanoid(character)
		local root = getRoot(character)
		if not (character and humanoid and root) then
			isRunning = false
			if toggleObj then
				toggleObj:Set(false)
			end
			return
		end
		pcall(function()
			local backpack = player:FindFirstChildOfClass("Backpack")
			for _, tool in ipairs(character:GetChildren()) do
				if tool:IsA("Tool") and backpack then
					tool.Parent = backpack
				end
			end
		end)
		realChar = character
		pcall(function()
			character.Archivable = true
		end)
		local clone = character:Clone()
		clone.Parent = Lighting
		for _, v in ipairs(clone:GetDescendants()) do
			if v:IsA("BasePart") then
				if v.Name == "HumanoidRootPart" then
					v.Transparency = 1
				elseif v.Transparency == 0 then
					v.Transparency = 0.5
				end
				v.Anchored = false
			elseif v:IsA("Decal") or v:IsA("Texture") then
				v.Transparency = 0.5
			end
		end
		local savedCF = root.CFrame
		pcall(function()
			character:MoveTo(Vector3.new(0, math.pi * 1000000, 0))
		end)
		local cam = Workspace.CurrentCamera
		if cam then
			pcall(function()
				cam.CameraType = Enum.CameraType.Scriptable
			end)
		end
		task.wait(0.2)
		if cam then
			pcall(function()
				cam.CameraType = Enum.CameraType.Custom
			end)
		end
		pcall(function()
			character.Parent = Lighting
		end)
		clone.Parent = Workspace
		local fakeRoot = getRoot(clone)
		if fakeRoot then
			pcall(function()
				fakeRoot.CFrame = savedCF
			end)
		end
		player.Character = clone
		fakeChar = clone
		fixCamera(clone)
		refreshAnimate(clone)
		local fakeHum = getHumanoid(clone)
		if fakeHum then
			fakeDiedConn = fakeHum.Died:Connect(function()
				restore()
				if toggleObj then
					toggleObj:Set(false)
				end
			end)
		end
		bindVoidCheck()
		isInvis = true
		isRunning = false
	else
		if isInvis then
			restore()
		end
	end
end

charAddedConn = player.CharacterAdded:Connect(function(newChar)
	if isInvis then
		fixConn = disc(fixConn)
		fakeDiedConn = disc(fakeDiedConn)
		local fake = fakeChar
		fakeChar = nil
		if fake and fake.Parent then
			pcall(function()
				fake:Destroy()
			end)
		end
		isInvis = false
		isRunning = false
	end
	realChar = newChar
end)

Unload.OnUnload(function()
	if charAddedConn then
		charAddedConn:Disconnect()
		charAddedConn = nil
	end
	if isInvis then
		restore()
	end
end)

function Invisible.Init(Tabs, ctx)
	local section = Tabs.Visual:Section({ Title = "隐身" })
	local toggleObj = nil
	toggleObj = section:Toggle({
		Title = "隐身自己",
		Icon = "ghost",
		Default = false,
		Callback = function(v)
			setEnabled(v, toggleObj)
		end,
	})
end

return Invisible
