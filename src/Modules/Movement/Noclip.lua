local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local NoclipCam = {
    enabled = false,
    modifiedFunctions = {}
}

local function checkEnvironment()
    local sc = (debug and debug.setconstant) or setconstant
    local gc = (debug and debug.getconstants) or getconstants
    if not sc or not getgc or not gc then
        return false
    end
    return true, sc, gc
end

function NoclipCam.enable(speaker)
    if NoclipCam.enabled then return end

    local canRun, sc, gc = checkEnvironment()
    if not canRun then
        return
    end

    local pop = speaker.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper
    if not pop then
        return
    end

    for _, v in pairs(getgc()) do
        if type(v) == "function" and getfenv(v).script == pop then
            for i, v1 in pairs(gc(v)) do
                if tonumber(v1) == 0.25 then
                    sc(v, i, 0)
                    table.insert(NoclipCam.modifiedFunctions, {func = v, index = i, originalValue = 0.25})
                elseif tonumber(v1) == 0 then
                    sc(v, i, 0.25)
                    table.insert(NoclipCam.modifiedFunctions, {func = v, index = i, originalValue = 0})
                end
            end
        end
    end

    NoclipCam.enabled = true
end

function NoclipCam.disable()
    if not NoclipCam.enabled then return end

    local canRun, sc, gc = checkEnvironment()
    if not canRun then return end

    for _, record in ipairs(NoclipCam.modifiedFunctions) do
        sc(record.func, record.index, record.originalValue)
    end

    NoclipCam.modifiedFunctions = {}
    NoclipCam.enabled = false
end

local Engine = NoclipCam

local M = {}
M.Title = "相机穿墙"

function M.Init(Tabs, ctx)
    local section = Tabs.Movement:Section({ Title = "穿墙" })
    section:Toggle({
        Title = "相机穿墙",
        Icon = "ghost",
        Value = false,
        Callback = function(state)
            if state then
                Engine.enable(Services.Players.LocalPlayer)
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
