local Config = require("../Core/Config")
local Services = require("../Core/Services")
local Utils = require("../Core/Utils")

local WindowLoader = {}

function WindowLoader.LoadWindUI()
	if _G.THUbXWindUI then
		return _G.THUbXWindUI
	end
	local src = Utils.HttpGetWithRetry(Config.WindUIUrl, 3)
	local fn, err = loadstring(src)
	if not fn then
		error("[THubX] WindUI 解析失败: " .. tostring(err))
	end
	local WindUI = fn()
	_G.THUbXWindUI = WindUI
	return WindUI
end

function WindowLoader.Create()
	local WindUI = WindowLoader.LoadWindUI()

	local Window = WindUI:CreateWindow({
		Title = Config.Title .. " v" .. Config.Version,
		Author = Config.Author,
		Folder = Config.Folder,
		Theme = Config.Theme,
		Size = UDim2.fromOffset(580, 460),
		Transparent = true,
	})

	local Tabs = {
		Movement = Window:Tab({ Title = "移动", Icon = "bird" }),
		Visual = Window:Tab({ Title = "视觉", Icon = "eye" }),
		Combat = Window:Tab({ Title = "战斗", Icon = "swords" }),
		Utility = Window:Tab({ Title = "实用", Icon = "wrench" }),
		Chat = Window:Tab({ Title = "聊天", Icon = "message-circle" }),
		Games = Window:Tab({ Title = "游戏", Icon = "gamepad-2" }),
		Settings = Window:Tab({ Title = "设置", Icon = "settings" }),
	}

	Tabs.Settings:Button({
		Title = "卸载 THubX",
		Callback = function()
			local Unload = require("../Core/Unload")
			pcall(function()
				Window:Destroy()
			end)
			Unload.Run()
			Utils.Info("已卸载")
		end,
	})

	return WindUI, Window, Tabs
end

return WindowLoader
