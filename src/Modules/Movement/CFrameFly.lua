local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local UserInputService = Services.UserInputService
local RunService = Services.RunService

local CFspeed = 50
local enable = false
local CFloop = nil
local bindKey = Enum.KeyCode.F
local connection = nil
local isMobile = UserInputService and UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function toggleCFrameFly()
    if enable then
        enable = false
        if CFloop then
            CFloop:Disconnect()
            CFloop = nil
        end

        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end

            local Head = character:FindFirstChild("Head")
            if Head then
                Head.Anchored = false
            end
        end
    else
        enable = true
        local character = LocalPlayer.Character
        if not character then return end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        humanoid.PlatformStand = true
        local Head = character:WaitForChild("Head")
        Head.Anchored = true

        if CFloop then CFloop:Disconnect() end

        CFloop = RunService.Heartbeat:Connect(function(deltaTime)
            local moveDirection = humanoid.MoveDirection * (CFspeed * deltaTime)
            local headCFrame = Head.CFrame
            local camera = workspace.CurrentCamera
            local cameraCFrame = camera.CFrame
            local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position

            cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
            local cameraPosition = cameraCFrame.Position
            local headPosition = headCFrame.Position

            local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)

            Head.CFrame = CFrame.new(headPosition) * (cameraCFrame - cameraPosition) * CFrame.new(objectSpaceVelocity)
        end)
    end
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == bindKey and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        toggleCFrameFly()
        return Enum.ContextActionResult.Sink
    end
end

local Engine = {}

function Engine.enable()
    if isMobile then
        if not enable then toggleCFrameFly() end
    else
        if connection then connection:Disconnect() end
        connection = UserInputService.InputBegan:Connect(onInputBegan)
    end
end

function Engine.disable()
    if isMobile then
        if enable then toggleCFrameFly() end
    else
        if enable then toggleCFrameFly() end
        if connection then connection:Disconnect() end
    end
end

function Engine.setspeed(speed)
    if type(speed) == "number" and speed >= 0 then
        CFspeed = speed
    end
end

function Engine.setbindkey(key)
    if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
        bindKey = key
    end
end

local M = {}
M.Title = "穿帧飞行"

function M.Init(Tabs, ctx)
    local section = Tabs.Movement:Section({ Title = "飞行�? })
    section:Toggle({
        Title = "穿帧飞行",
        Icon = "rocket",
        Value = false,
        Callback = function(state)
            if state then
                Engine.enable()
            else
                Engine.disable()
            end
        end,
    })
    section:Slider({
        Title = "飞行速度",
        Step = 1,
        Value = { Min = 0, Max = 200, Default = 50 },
        Callback = function(v)
            Engine.setspeed(v)
        end,
    })
    section:Keybind({
        Title = "飞行开�?,
        Icon = "keyboard",
        Value = "F",
        Callback = function(v)
            local ok, key = pcall(function()
                return Enum.KeyCode[v]
            end)
            if ok and key then
                Engine.setbindkey(key)
            end
        end,
    })
end

Unload.OnUnload(function()
    pcall(function()
        Engine.disable()
    end)
end)

return M
