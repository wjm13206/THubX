local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local UserInputService = Services.UserInputService
local RunService = Services.RunService

local speeds = 1
local enable = false
local tpwalking = false
local bindKey = Enum.KeyCode.F
local connection = nil
local isMobile = UserInputService and UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function togglefly()
    if enable == true then
        enable = false
        tpwalking = false
        local speaker = Players.LocalPlayer
        local chr = speaker.Character
        local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
            hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        end
    else
        enable = true
        tpwalking = true
        for i = 1, speeds do
            spawn(function()
                local hb = RunService.Heartbeat
                local chr = Players.LocalPlayer.Character
                local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                    if hum.MoveDirection.Magnitude > 0 then
                        chr:TranslateBy(hum.MoveDirection)
                    end
                end
            end)
        end
        local chr = Players.LocalPlayer.Character
        if chr then
            local animate = chr:FindFirstChild("Animate")
            if animate then
                animate.Disabled = true
            end
            local Hum = chr:FindFirstChildOfClass("Humanoid") or chr:FindFirstChildOfClass("AnimationController")
            if Hum then
                for i, v in next, Hum:GetPlayingAnimationTracks() do
                    v:AdjustSpeed(0)
                end
            end
            local hum = chr:FindFirstChildWhichIsA("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
                hum:ChangeState(Enum.HumanoidStateType.Swimming)
            end
        end
    end

    local chr = Players.LocalPlayer.Character
    if not chr then return end
    local hum = chr:FindFirstChildWhichIsA("Humanoid")
    if not hum then return end

    if hum.RigType == Enum.HumanoidRigType.R6 then
        local torso = chr:FindFirstChild("Torso")
        if not torso then return end
        local ctrl = {f = 0, b = 0, l = 0, r = 0}
        local lastctrl = {f = 0, b = 0, l = 0, r = 0}
        local maxspeed = 50
        local speed = 0
        local bg = Instance.new("BodyGyro", torso)
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = torso.CFrame
        local bv = Instance.new("BodyVelocity", torso)
        bv.velocity = Vector3.new(0, 0.1, 0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        if enable == true then
            hum.PlatformStand = true
        end
        while enable == true or Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid") and Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").Health == 0 do
            RunService.RenderStepped:Wait()
            if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                speed = speed + .5 + (speed / maxspeed)
                if speed > maxspeed then
                    speed = maxspeed
                end
            elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
                speed = speed - 1
                if speed < 0 then
                    speed = 0
                end
            end
            if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f + ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * .2, 0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p)) * speed
                lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
            elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f + lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * .2, 0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p)) * speed
            else
                bv.velocity = Vector3.new(0, 0, 0)
            end
            bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
        end
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        lastctrl = {f = 0, b = 0, l = 0, r = 0}
        speed = 0
        bg:Destroy()
        bv:Destroy()
        hum.PlatformStand = false
        local animate = Players.LocalPlayer.Character:FindFirstChild("Animate")
        if animate then
            animate.Disabled = false
        end
        tpwalking = false
    else
        local UpperTorso = chr:FindFirstChild("UpperTorso")
        if not UpperTorso then return end
        local ctrl = {f = 0, b = 0, l = 0, r = 0}
        local lastctrl = {f = 0, b = 0, l = 0, r = 0}
        local maxspeed = 50
        local speed = 0
        local bg = Instance.new("BodyGyro", UpperTorso)
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = UpperTorso.CFrame
        local bv = Instance.new("BodyVelocity", UpperTorso)
        bv.velocity = Vector3.new(0, 0.1, 0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        if enable == true then
            hum.PlatformStand = true
        end
        while enable == true or Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid") and Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").Health == 0 do
            wait()
            if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                speed = speed + .5 + (speed / maxspeed)
                if speed > maxspeed then
                    speed = maxspeed
                end
            elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
                speed = speed - 1
                if speed < 0 then
                    speed = 0
                end
            end
            if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f + ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * .2, 0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p)) * speed
                lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
            elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f + lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * .2, 0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p)) * speed
            else
                bv.velocity = Vector3.new(0, 0, 0)
            end
            bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
        end
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        lastctrl = {f = 0, b = 0, l = 0, r = 0}
        speed = 0
        bg:Destroy()
        bv:Destroy()
        hum.PlatformStand = false
        local animate = Players.LocalPlayer.Character:FindFirstChild("Animate")
        if animate then
            animate.Disabled = false
        end
        tpwalking = false
    end
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == bindKey and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        togglefly()
        return Enum.ContextActionResult.Sink
    end
end

local Engine = {}

function Engine.enable()
    if isMobile then
        if not enable then
            togglefly()
        end
    else
        if connection then
            connection:Disconnect()
        end
        connection = UserInputService.InputBegan:Connect(onInputBegan)
    end
end

function Engine.disable()
    if isMobile then
        if enable then
            togglefly()
        end
    else
        if enable then
            togglefly()
        end
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
end

function Engine.setflyspeed(spd)
    if type(spd) == "number" and spd >= 1 then
        speeds = spd
        if enable == true then
            tpwalking = false
            for i = 1, speeds do
                spawn(function()
                    local hb = RunService.Heartbeat
                    tpwalking = true
                    local chr = Players.LocalPlayer.Character
                    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                    while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                        if hum.MoveDirection.Magnitude > 0 then
                            chr:TranslateBy(hum.MoveDirection)
                        end
                    end
                end)
            end
        end
    end
end

function Engine.setbindkey(key)
    if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
        bindKey = key
    end
end

local M = {}
M.Title = "飞行"

function M.Init(Tabs, ctx)
    local section = Tabs.Movement:Section({ Title = "飞行类" })
    section:Toggle({
        Title = "启用飞行",
        Icon = "plane",
        Default = false,
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
            Engine.setflyspeed(v)
        end,
    })
    section:Keybind({
        Title = "飞行开关",
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
