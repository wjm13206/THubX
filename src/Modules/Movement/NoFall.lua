local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Players = Services.Players
local RunService = Services.RunService

local player = Players.LocalPlayer

local heartbeatConnection = nil
local character = nil
local humanoid = nil
local rootPart = nil
local enabled = false
local wasFalling = false

local function onHeartbeat()
    if not humanoid or not humanoid.Parent then return end
    if not rootPart or not rootPart.Parent then return end

    local state = humanoid:GetState()

    if state == Enum.HumanoidStateType.Freefall then
        wasFalling = true
        local velocity = rootPart.AssemblyLinearVelocity
        if velocity.Y < -50 then
            rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X, -50, velocity.Z)
        end
    elseif wasFalling and state == Enum.HumanoidStateType.Landed then
        wasFalling = false
    end
end

local function startHeartbeat()
    if heartbeatConnection then return end
    heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)
end

local function stopHeartbeat()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
end

local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    wasFalling = false
    if enabled then
        startHeartbeat()
    end
end

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

local Engine = {}

function Engine.enable()
    if enabled then return end
    enabled = true
    if character then
        startHeartbeat()
    end
end

function Engine.disable()
    enabled = false
    stopHeartbeat()
end

local M = {}
M.Title = "防摔落"

function M.Init(Tabs, ctx)
    local section = Tabs.Movement:Section({ Title = "保护" })
    section:Toggle({
        Title = "防摔落",
        Icon = "shield",
        Value = false,
        Callback = function(state)
            if state then
                Engine.enable()
            else
                Engine.disable()
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
