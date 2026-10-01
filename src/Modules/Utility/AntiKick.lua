local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "反踢出"

local cloneref = Services.cloneref or clonereference or function(obj) return obj end

local enabled = false
local loaded = false
local supported = nil
local hooksInstalled = false

local oldhmmi = nil
local oldhmmnc = nil
local oldKickFunction = nil
local hookedLocalPlayer = nil

local function checkSupport()
	if supported ~= nil then
		return supported
	end
	if not hookmetamethod then
		supported = false
		return false
	end
	local ok = pcall(function()
		return cloneref(game:GetService("Players")).LocalPlayer
	end)
	if not ok then
		supported = false
		return false
	end
	supported = true
	return true
end

local function installHooks()
	if hooksInstalled then return true end
	local LocalPlayer = cloneref(game:GetService("Players")).LocalPlayer
	if not LocalPlayer then return false end
	oldhmmi = hookmetamethod(game, "__index", function(self, method)
		if enabled and self == LocalPlayer and type(method) == "string" and method:lower() == "kick" then
			return error("Expected ':' not '.' calling member function Kick", 2)
		end
		return oldhmmi(self, method)
	end)
	oldhmmnc = hookmetamethod(game, "__namecall", function(self, ...)
		if enabled and self == LocalPlayer and getnamecallmethod():lower() == "kick" then
			return
		end
		return oldhmmnc(self, ...)
	end)
	if hookfunction then
		hookedLocalPlayer = LocalPlayer
		oldKickFunction = hookfunction(LocalPlayer.Kick, function(...)
			if enabled then return end
			return oldKickFunction(...)
		end)
	end
	hooksInstalled = true
	return true
end

local function enable()
	if not checkSupport() then
		enabled = false
		loaded = false
		return false, "当前执行器不支持 hookmetamethod"
	end
	if enabled then
		return true, "反踢出已在运行"
	end
	if not installHooks() then
		enabled = false
		return false, "钩子安装失败"
	end
	enabled = true
	loaded = true
	return true, "反踢出已开启"
end

local function disable()
	enabled = false
	return true, "反踢出已关闭"
end

local function fullUnload()
	enabled = false
	if oldhmmi then
		pcall(hookmetamethod, game, "__index", oldhmmi)
	end
	if oldhmmnc then
		pcall(hookmetamethod, game, "__namecall", oldhmmnc)
	end
	if oldKickFunction and hookfunction and hookedLocalPlayer then
		pcall(hookfunction, hookedLocalPlayer.Kick, oldKickFunction)
	end
	oldhmmi = nil
	oldhmmnc = nil
	oldKickFunction = nil
	hookedLocalPlayer = nil
	hooksInstalled = false
	loaded = false
end

Unload.OnUnload(fullUnload)

function M.Init(Tabs, ctx)
	local section = Tabs.Utility:Section({ Title = "反踢出", Icon = "shield" })
	local tg
	tg = section:Toggle({
		Title = "开启反踢出",
		Icon = "shield",
		Default = false,
		Callback = function(state)
			if state then
				local ok, msg = enable()
				pcall(function()
					ctx.WindUI:Notify({ Title = "反踢出", Content = msg, Duration = 3 })
				end)
				if not ok then
					pcall(function() tg:Set(false) end)
				end
			else
				disable()
			end
		end,
	})
end

return M
