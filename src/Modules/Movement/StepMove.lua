local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Players = Services.Players
local ContextActionService = Services.Get("ContextActionService")
local UserInputService = Services.UserInputService

local localPlayer = Players.LocalPlayer

local enabled = false
local moveDistance = 10

local ACTION_MOVE_FORWARD = "THubXMoveForward"
local ACTION_MOVE_BACKWARD = "THubXMoveBackward"
local ACTION_MOVE_LEFT = "THubXMoveLeft"
local ACTION_MOVE_RIGHT = "THubXMoveRight"

local function getRootPart(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
end

local function onAction(actionName, inputState, input)
    if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
    if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end

    local character = localPlayer.Character
    if not character then return Enum.ContextActionResult.Pass end
    local rootPart = getRootPart(character)
    if not rootPart then return Enum.ContextActionResult.Pass end

    local moveVec
    if actionName == ACTION_MOVE_FORWARD then
        moveVec = rootPart.CFrame.LookVector * moveDistance
    elseif actionName == ACTION_MOVE_BACKWARD then
        moveVec = -rootPart.CFrame.LookVector * moveDistance
    elseif actionName == ACTION_MOVE_LEFT then
        moveVec = -rootPart.CFrame.RightVector * moveDistance
    elseif actionName == ACTION_MOVE_RIGHT then
        moveVec = rootPart.CFrame.RightVector * moveDistance
    end

    moveVec = Vector3.new(moveVec.X, 0, moveVec.Z)
    rootPart.CFrame = rootPart.CFrame + moveVec

    return Enum.ContextActionResult.Sink
end

local Engine = {}

function Engine.enable()
    if enabled then return end
    enabled = true

    ContextActionService:BindActionAtPriority(
        ACTION_MOVE_FORWARD,
        onAction,
        false,
        Enum.ContextActionPriority.High.Value,
        Enum.KeyCode.Up
    )
    ContextActionService:BindActionAtPriority(
        ACTION_MOVE_BACKWARD,
        onAction,
        false,
        Enum.ContextActionPriority.High.Value,
        Enum.KeyCode.Down
    )
    ContextActionService:BindActionAtPriority(
        ACTION_MOVE_LEFT,
        onAction,
        false,
        Enum.ContextActionPriority.High.Value,
        Enum.KeyCode.Left
    )
    ContextActionService:BindActionAtPriority(
        ACTION_MOVE_RIGHT,
        onAction,
        false,
        Enum.ContextActionPriority.High.Value,
        Enum.KeyCode.Right
    )
end

function Engine.disable()
    if not enabled then return end
    enabled = false

    ContextActionService:UnbindAction(ACTION_MOVE_FORWARD)
    ContextActionService:UnbindAction(ACTION_MOVE_BACKWARD)
    ContextActionService:UnbindAction(ACTION_MOVE_RIGHT)
    ContextActionService:UnbindAction(ACTION_MOVE_LEFT)
end

function Engine.SetDistance(distance)
    assert(type(distance) == "number" and distance >= 0, "Distance must be a non-negative number")
    moveDistance = distance
end

local M = {}
M.Title = "方向键步移"

function M.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Movement, M.Title, { Icon = "move" })
    folder:Toggle({
        Title = "方向键步移",
        Icon = "move",
        Value = false,
        Callback = function(state)
            if state then
                Engine.enable()
            else
                Engine.disable()
            end
        end,
    })
    folder:Slider({
        Title = "步移距离",
        Step = 1,
        Value = { Min = 1, Max = 50, Default = 10 },
        Callback = function(v)
            Engine.SetDistance(v)
        end,
    })
end

Unload.OnUnload(function()
    pcall(function()
        Engine.disable()
    end)
end)

return M
