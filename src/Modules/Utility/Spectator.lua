local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Spectator = {}
Spectator.Title = "旁观"

local localPlayer = Services.Players.LocalPlayer
local camera = workspace.CurrentCamera
local spectatorPlayers = {}
local currentSpectateIndex = 0
local isSpectating = false

local renderSteppedConn = nil
local playerAddedConn = nil
local playerRemovingConn = nil

local function refreshList()
	spectatorPlayers = {}
	for _, player in ipairs(Services.Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
			table.insert(spectatorPlayers, player)
		end
	end
	if currentSpectateIndex > #spectatorPlayers then
		currentSpectateIndex = 0
	end
end

local function switchToPlayer(index, ctx)
	if not isSpectating then
		return
	end
	if #spectatorPlayers == 0 then
		currentSpectateIndex = 0
		camera.CameraSubject = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") or camera
		return
	end
	currentSpectateIndex = index
	if currentSpectateIndex < 1 then
		currentSpectateIndex = #spectatorPlayers
	elseif currentSpectateIndex > #spectatorPlayers then
		currentSpectateIndex = 1
	end
	local targetPlayer = spectatorPlayers[currentSpectateIndex]
	if targetPlayer and targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
			camera.CameraType = Enum.CameraType.Custom
			if ctx then
				ctx.WindUI:Notify({ Title = "旁观", Content = "正在旁观 " .. targetPlayer.DisplayName, Duration = 2 })
			end
		end
	end
end

local function startSpectate(ctx)
	if isSpectating then
		return
	end
	isSpectating = true
	if not playerAddedConn then
		playerAddedConn = Services.Players.PlayerAdded:Connect(refreshList)
	end
	if not playerRemovingConn then
		playerRemovingConn = Services.Players.PlayerRemoving:Connect(refreshList)
	end
	if not renderSteppedConn then
		renderSteppedConn = Services.RunService.RenderStepped:Connect(function()
			if not isSpectating then
				return
			end
			refreshList()
			local currentPlayer = spectatorPlayers[currentSpectateIndex]
			if currentPlayer and (not currentPlayer.Character or not currentPlayer.Character:FindFirstChild("Humanoid")) then
				switchToPlayer(currentSpectateIndex + 1, nil)
			end
		end)
	end
	refreshList()
	if #spectatorPlayers > 0 then
		switchToPlayer(1, ctx)
	else
		ctx.WindUI:Notify({ Title = "旁观", Content = "没有可旁观的玩家", Duration = 3 })
	end
end

local function stopSpectate()
	if not isSpectating then
		return
	end
	isSpectating = false
	currentSpectateIndex = 0
	if localPlayer.Character then
		local humanoid = localPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
	camera.CameraType = Enum.CameraType.Custom
	if renderSteppedConn then
		renderSteppedConn:Disconnect()
		renderSteppedConn = nil
	end
	if playerAddedConn then
		playerAddedConn:Disconnect()
		playerAddedConn = nil
	end
	if playerRemovingConn then
		playerRemovingConn:Disconnect()
		playerRemovingConn = nil
	end
end

Unload.OnUnload(function()
	stopSpectate()
end)

function Spectator.Init(Tabs, ctx)

	Tabs.Teleport:Toggle({
		Title = "启用旁观",
		Icon = "eye",
		Value = false,
		Callback = function(state)
			if state then
				startSpectate(ctx)
			else
				stopSpectate()
			end
		end,
	})
	Tabs.Teleport:Button({
		Title = "上一个人",
		Icon = "chevron-left",
		Callback = function()
			switchToPlayer(currentSpectateIndex - 1, ctx)
		end,
	})
	Tabs.Teleport:Button({
		Title = "下一个人",
		Icon = "chevron-right",
		Callback = function()
			switchToPlayer(currentSpectateIndex + 1, ctx)
		end,
	})
end

return Spectator
