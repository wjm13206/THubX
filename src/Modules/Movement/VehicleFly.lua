local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local UserInputService = Services.UserInputService

local FLYING = false
local bindKey = Enum.KeyCode.V
local connection = nil
local isMobile = UserInputService and UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local vehicleflyspeed = 1
local QEfly = true

local flyKeyDown = nil
local flyKeyUp = nil

local function getVehicleRoot()
    local character = LocalPlayer.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        return humanoid.SeatPart:IsA("VehicleSeat") and humanoid.SeatPart or nil
    end
    return nil
end

local function toggleVehicleFly()
    if FLYING then
        FLYING = false
        if flyKeyDown then flyKeyDown:Disconnect() flyKeyDown = nil end
        if flyKeyUp then flyKeyUp:Disconnect() flyKeyUp = nil end
    else
        FLYING = true

        local root = getVehicleRoot()
        if not root then
            FLYING = false
            return
        end

        local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local SPEED = 0

        local BG = Instance.new("BodyGyro")
        local BV = Instance.new("BodyVelocity")
        BG.P = 9e4
        BG.Parent = root
        BV.Parent = root
        BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.CFrame = root.CFrame
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        task.spawn(function()
            repeat task.wait()
                local camera = workspace.CurrentCamera
                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                    SPEED = 50
                elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
                    SPEED = 0
                end

                if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                    BV.Velocity = ((camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                    lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
                    BV.Velocity = ((camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                else
                    BV.Velocity = Vector3.new(0, 0, 0)
                end
                BG.CFrame = camera.CFrame
            until not FLYING

            CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            SPEED = 0
            BG:Destroy()
            BV:Destroy()
        end)

        flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then
                CONTROL.F = vehicleflyspeed
            elseif input.KeyCode == Enum.KeyCode.S then
                CONTROL.B = -vehicleflyspeed
            elseif input.KeyCode == Enum.KeyCode.A then
                CONTROL.L = -vehicleflyspeed
            elseif input.KeyCode == Enum.KeyCode.D then
                CONTROL.R = vehicleflyspeed
            elseif input.KeyCode == Enum.KeyCode.E and QEfly then
                CONTROL.Q = vehicleflyspeed * 2
            elseif input.KeyCode == Enum.KeyCode.Q and QEfly then
                CONTROL.E = -vehicleflyspeed * 2
            end
            pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
        end)

        flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0
            elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0
            elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0
            elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0
            elseif input.KeyCode == Enum.KeyCode.E then CONTROL.Q = 0
            elseif input.KeyCode == Enum.KeyCode.Q then CONTROL.E = 0
            end
        end)
    end
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == bindKey and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        toggleVehicleFly()
        return Enum.ContextActionResult.Sink
    end
end

local Engine = {}

function Engine.enable()
    if isMobile then
        if not FLYING then toggleVehicleFly() end
    else
        if connection then connection:Disconnect() end
        connection = UserInputService.InputBegan:Connect(onInputBegan)
    end
end

function Engine.disable()
    if isMobile then
        if FLYING then toggleVehicleFly() end
    else
        if FLYING then toggleVehicleFly() end
        if connection then connection:Disconnect() end
    end
end

function Engine.setspeed(speed)
    if type(speed) == "number" and speed > 0 then
        vehicleflyspeed = speed
    end
end

function Engine.setbindkey(key)
    if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
        bindKey = key
    end
end

local M = {}
M.Title = "载具飞行"

function M.Init(Tabs, ctx)
    local section = Tabs.Movement:Section({ Title = "飞行�? })
    section:Toggle({
        Title = "载具飞行",
        Icon = "car",
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
        Value = { Min = 1, Max = 10, Default = 1 },
        Callback = function(v)
            Engine.setspeed(v)
        end,
    })
    section:Keybind({
        Title = "飞行开�?,
        Icon = "keyboard",
        Value = "V",
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
