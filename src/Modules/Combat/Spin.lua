local Unload = require("../../Core/Unload")

local Spin = {}
Spin.Title = "旋转"

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = Players.LocalPlayer

local isActive = false
local currentSpinBody = nil
local currentHeartbeat = nil
local currentSpeed = 20
local currentCharacter = nil
local characterAddedConn = nil

local connections = {}

local MUSIC_URL = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/beiqilexingnang.mp3"
local spinSongId = nil

local function getHubData()
	local d = rawget(_G, "data")
	if type(d) == "table" then
		return d
	end
	return nil
end

local function playMusic()
	local hubData = getHubData()
	if not hubData then return end
	local okBasic, basic = pcall(function() return hubData["basicdata"] end)
	if not okBasic or type(basic) ~= "table" then return end
	if basic["otherdata"] and basic["otherdata"]["musicData"] and basic["otherdata"]["musicData"]["isPlay"] then
		return
	end
	local fileName = "beiqilexingnang.mp3"
	local filePath = "THub/music/cache/" .. fileName

	local function doPlay(assetId)
		spinSongId = assetId
		local musicbox = basic["otherdata"]["musicbox"]
		musicbox.SoundId = assetId
		musicbox.TimePosition = 0
		musicbox.Looped = true
		musicbox:Play()
	end

	if isfile and isfile(filePath) then
		local assetId = getcustomasset(filePath)
		if assetId and assetId ~= "" then
			doPlay(assetId)
			return
		end
	end

	task.spawn(function()
		local success, response = pcall(function() return game:HttpGet(MUSIC_URL) end)
		if success and response and response ~= "" then
			pcall(function()
				local folder = "THub/music/cache"
				if not isfolder(folder) then makefolder(folder) end
				writefile(filePath, response)
				local assetId = getcustomasset(filePath)
				if assetId and assetId ~= "" then
					doPlay(assetId)
				end
			end)
		end
	end)
end

local function stopMusic()
	local hubData = getHubData()
	if not hubData then
		spinSongId = nil
		return
	end
	pcall(function()
		local basic = hubData["basicdata"]
		if spinSongId and basic["otherdata"]["musicbox"].SoundId == spinSongId and basic["otherdata"]["musicData"]["isPlay"] then
			basic["otherdata"]["musicbox"].Looped = false
			basic["otherdata"]["musicbox"]:Stop()
			spinSongId = nil
		end
	end)
end

local function getRoot(char)
	if char and char:FindFirstChildOfClass("Humanoid") then
		return char:FindFirstChildOfClass("Humanoid").RootPart
	end
	return nil
end

local function cleanupSpinBody()
	if currentSpinBody and currentSpinBody.Parent then
		pcall(function()
			currentSpinBody:Destroy()
		end)
	end
	currentSpinBody = nil
end

local function disconnectHeartbeat()
	if currentHeartbeat then
		currentHeartbeat:Disconnect()
		currentHeartbeat = nil
	end
end

local function stopSpin()
	isActive = false
	cleanupSpinBody()
	disconnectHeartbeat()
	stopMusic()

	if characterAddedConn then
		characterAddedConn:Disconnect()
		characterAddedConn = nil
	end

	currentCharacter = nil
end

local function startSpin(speed)
	stopSpin()

	if speed and type(speed) == "number" and speed > 0 then
		currentSpeed = speed
	end

	local char = LocalPlayer.Character
	if not char then
		characterAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
			characterAddedConn:Disconnect()
			characterAddedConn = nil
			startSpin(currentSpeed)
		end)
		return false
	end

	local root = getRoot(char)
	if not root then
		return false
	end

	currentCharacter = char
	isActive = true
	playMusic()

	currentSpinBody = Instance.new("BodyAngularVelocity")
	currentSpinBody.Name = "__SpinVelocity"
	currentSpinBody.Parent = root
	currentSpinBody.MaxTorque = Vector3.new(0, math.huge, 0)
	currentSpinBody.AngularVelocity = Vector3.new(0, currentSpeed, 0)

	disconnectHeartbeat()
	currentHeartbeat = RunService.Heartbeat:Connect(function()
		if isActive then
			local c = currentCharacter or LocalPlayer.Character
			if c then
				local r = getRoot(c)
				if r then
					local vel = r.Velocity
					if vel.Y < -75 then
						r.Velocity = Vector3.new(vel.X, -50, vel.Z)
					end
				end
			end
		end
	end)
	table.insert(connections, currentHeartbeat)

	characterAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
		currentCharacter = newChar
		local newRoot = getRoot(newChar)
		if newRoot and isActive then
			local newSpinBody = Instance.new("BodyAngularVelocity")
			newSpinBody.Name = "__SpinVelocity"
			newSpinBody.Parent = newRoot
			newSpinBody.MaxTorque = Vector3.new(0, math.huge, 0)
			newSpinBody.AngularVelocity = Vector3.new(0, currentSpeed, 0)

			cleanupSpinBody()
			currentSpinBody = newSpinBody
		end
	end)

	table.insert(connections, characterAddedConn)

	return true
end

local function updateSpinSpeed(speed)
	if currentSpinBody and currentSpinBody.Parent then
		currentSpinBody.AngularVelocity = Vector3.new(0, speed, 0)
	end
end

Unload.OnUnload(function()
	stopSpin()
end)

function Spin.Init(Tabs, ctx)
	local settings = ctx.FeatureSettings("旋转")
	Tabs.Combat:Toggle({
		Title = "启用旋转",
		Icon = "rotate-cw",
		Value = false,
		Callback = function(state)
			if state then
				startSpin(currentSpeed)
			else
				stopSpin()
			end
		end,
	})
	settings:Slider({
		Title = "旋转速度",
		Icon = "gauge",
		Step = 5,
		Value = { Min = 5, Max = 200, Default = 20 },
		Callback = function(v)
			currentSpeed = v
			if isActive then
				updateSpinSpeed(currentSpeed)
			end
		end,
	})
end

return Spin
