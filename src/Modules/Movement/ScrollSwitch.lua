local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local ScrollSwitch = {}
ScrollSwitch.Title = "滚轮切道"

local Players = Services.Players
local UserInputService = Services.UserInputService
local ContextActionService = Services.Get("ContextActionService")
local VirtualInputManager = Services.Get("VirtualInputManager")
local player = Players.LocalPlayer
local character = nil

local ACTION_NAME = "THubXScrollSwitch"

local enabled = false
local modifierKey = Enum.KeyCode.V
local validSlots = {}
local currentSlotIndex = 1
local lastScrollTime = 0
local modifierHeld = false
local connections = {}

local numberToKeyCode = {
	[0] = Enum.KeyCode.Zero,
	[1] = Enum.KeyCode.One,
	[2] = Enum.KeyCode.Two,
	[3] = Enum.KeyCode.Three,
	[4] = Enum.KeyCode.Four,
	[5] = Enum.KeyCode.Five,
	[6] = Enum.KeyCode.Six,
	[7] = Enum.KeyCode.Seven,
	[8] = Enum.KeyCode.Eight,
	[9] = Enum.KeyCode.Nine,
}

local function pressNumberKey(num)
	local keyCode = numberToKeyCode[num]
	if keyCode then
		VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
		VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
	end
end

local function hasToolEquipped()
	if not character then
		return false
	end
	return character:FindFirstChildOfClass("Tool") ~= nil
end

local function scanAllSlots()
	validSlots = {}
	if not character then
		return
	end
	for i = 1, 9 do
		pressNumberKey(i)
		task.wait(0.05)
		if hasToolEquipped() then
			table.insert(validSlots, i)
			pressNumberKey(i)
			task.wait(0.05)
		end
	end
	pressNumberKey(0)
	task.wait(0.05)
	if hasToolEquipped() then
		table.insert(validSlots, 0)
		pressNumberKey(0)
		task.wait(0.05)
	end
	if #validSlots > 0 then
		currentSlotIndex = 1
		pressNumberKey(validSlots[1])
	end
end

local function switchToPrev()
	if #validSlots == 0 then
		return
	end
	currentSlotIndex = currentSlotIndex - 1
	if currentSlotIndex < 1 then
		currentSlotIndex = #validSlots
	end
	pressNumberKey(validSlots[currentSlotIndex])
end

local function switchToNext()
	if #validSlots == 0 then
		return
	end
	currentSlotIndex = currentSlotIndex + 1
	if currentSlotIndex > #validSlots then
		currentSlotIndex = 1
	end
	pressNumberKey(validSlots[currentSlotIndex])
end

local function bindEvents()
	ContextActionService:UnbindAction("ScrollSwitch")
	ContextActionService:UnbindAction(ACTION_NAME)
	ContextActionService:BindAction(
		ACTION_NAME,
		function(actionName, inputState, inputObject)
			if inputState == Enum.UserInputState.Change then
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
					local now = tick()
					if now - lastScrollTime < 0.1 then
						return Enum.ContextActionResult.Sink
					end
					lastScrollTime = now
					local delta = inputObject.Position.Z
					if delta > 0 then
						switchToPrev()
					elseif delta < 0 then
						switchToNext()
					end
					return Enum.ContextActionResult.Sink
				else
					return Enum.ContextActionResult.Pass
				end
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.UserInputType.MouseWheel
	)
	local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		local pressedSlot = nil
		for i = 1, 9 do
			if input.KeyCode == numberToKeyCode[i] then
				pressedSlot = i
				break
			end
		end
		if not pressedSlot and input.KeyCode == Enum.KeyCode.Zero then
			pressedSlot = 0
		end
		if pressedSlot then
			for idx, slot in ipairs(validSlots) do
				if slot == pressedSlot then
					currentSlotIndex = idx
					break
				end
			end
		end
	end)
	table.insert(connections, inputBeganConn)
	local charAddedConn = player.CharacterAdded:Connect(function(newChar)
		character = newChar
		task.wait(0.2)
		if enabled then
			scanAllSlots()
		end
	end)
	table.insert(connections, charAddedConn)
end

local function unbindEvents()
	ContextActionService:UnbindAction("ScrollSwitch")
	ContextActionService:UnbindAction(ACTION_NAME)
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	connections = {}
	modifierHeld = false
end

local function setEnabled(state)
	if state then
		if enabled then
			return
		end
		enabled = true
		character = player.Character
		if character then
			task.wait(0.2)
			scanAllSlots()
		end
		bindEvents()
	else
		if not enabled then
			return
		end
		enabled = false
		unbindEvents()
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function ScrollSwitch.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Movement, ScrollSwitch.Title, { Icon = "repeat" })
	folder:Toggle({
		Title = "启用滚轮切道(按住V+滚轮)",
		Icon = "repeat",
		Value = false,
		Callback = function(state)
			setEnabled(state)
		end,
	})
end

return ScrollSwitch
