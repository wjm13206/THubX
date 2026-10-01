local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local LocalPlayer = Services.Players.LocalPlayer
local RunService = Services.RunService

local floorPart = nil
local floorY = nil
local isActive = false

local heartbeatConnection = nil
local characterAddedConnection = nil
local diedConnection = nil

local function createFloor(character)
    if floorPart then return end

    local Humanoid = character:WaitForChild("Humanoid")
    local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")

    floorPart = Instance.new("Part")
    floorPart.Size = Vector3.new(10, 1, 10)
    floorPart.Transparency = 1
    floorPart.Anchored = true
    floorPart.CanCollide = true
    floorPart.Parent = workspace

    local glow = Instance.new("SurfaceGui", floorPart)
    glow.Face = Enum.NormalId.Top
    local frame = Instance.new("Frame", glow)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0, 1, 0)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0

    floorY = HumanoidRootPart.Position.Y - HumanoidRootPart.Size.Y / 2 - floorPart.Size.Y / 2 - 1.8
    floorPart.Position = Vector3.new(HumanoidRootPart.Position.X, floorY, HumanoidRootPart.Position.Z)
end

local function destroyFloor()
    if floorPart then
        floorPart:Destroy()
        floorPart = nil
    end
    floorY = nil
end

local function updateFloorPosition(character)
    if not floorPart or not floorY then return end
    local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
    floorPart.Position = Vector3.new(HumanoidRootPart.Position.X, floorY, HumanoidRootPart.Position.Z)
end

local function getCurrentCharacter()
    local char = LocalPlayer.Character
    if char then return char end
    return LocalPlayer.CharacterAdded:Wait()
end

local Engine = {}

local function onCharacterDied()
    if isActive then
        Engine.disable()
    end
end

local function setupCharacterEvents(character)
    local humanoid = character:WaitForChild("Humanoid")
    if diedConnection then
        diedConnection:Disconnect()
        diedConnection = nil
    end
    diedConnection = humanoid.Died:Connect(onCharacterDied)
end

function Engine.enable()
    if isActive then return end

    local character = getCurrentCharacter()
    if not character then return end

    createFloor(character)
    if not floorPart then return end

    isActive = true

    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if isActive and floorPart and LocalPlayer.Character then
            updateFloorPosition(LocalPlayer.Character)
        end
    end)

    if characterAddedConnection then
        characterAddedConnection:Disconnect()
    end
    characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        if isActive then
            destroyFloor()
            createFloor(newCharacter)
            setupCharacterEvents(newCharacter)
        end
    end)

    setupCharacterEvents(character)
end

function Engine.disable()
    if not isActive then return end

    isActive = false
    destroyFloor()

    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    if diedConnection then
        diedConnection:Disconnect()
        diedConnection = nil
    end
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
        characterAddedConnection = nil
    end
end

local M = {}
M.Title = "空中行走"

function M.Init(Tabs, ctx)
    local section = Tabs.Movement:Section({ Title = "行走" })
    section:Toggle({
        Title = "空中行走",
        Icon = "footprints",
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
