local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "Ctrl点击传送"

local cloneref = Services.cloneref or clonereference or function(obj) return obj end
local userInputService = cloneref(game:GetService("UserInputService"))
local players = cloneref(game:GetService("Players"))
local localPlayer = players.LocalPlayer
local mouse = localPlayer:GetMouse()

local ctrlHeld = false
local inputBeganConn = nil
local inputEndedConn = nil
local mouseButton1Conn = nil

local function cleanConnections()
	if inputBeganConn then
		inputBeganConn:Disconnect()
		inputBeganConn = nil
	end
	if inputEndedConn then
		inputEndedConn:Disconnect()
		inputEndedConn = nil
	end
	if mouseButton1Conn then
		mouseButton1Conn:Disconnect()
		mouseButton1Conn = nil
	end
end

local function disable()
	ctrlHeld = false
	cleanConnections()
end

local function enable()
	if mouseButton1Conn then
		disable()
	end
	inputBeganConn = userInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			ctrlHeld = true
		end
	end)
	inputEndedConn = userInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			ctrlHeld = false
		end
	end)
	mouseButton1Conn = mouse.Button1Down:Connect(function()
		if not ctrlHeld then return end
		local character = localPlayer.Character
		if not character then return end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then return end
		local hitPos = mouse.Hit
		if hitPos then
			local targetPos = hitPos.Position + Vector3.new(0, 2.5, 0)
			humanoidRootPart.CFrame = CFrame.new(targetPos)
		end
	end)
end

Unload.OnUnload(disable)

function M.Init(Tabs, ctx)
	local section = Tabs.Utility:Section({ Title = "点击传送" })
	section:Toggle({
		Title = "按住Ctrl点击地面传送",
		Icon = "map-pin",
		Value = false,
		Callback = function(state)
			if state then
				enable()
			else
				disable()
			end
		end,
	})
end

return M
