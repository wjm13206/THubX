local Config = require("../Core/Config")
local Services = require("../Core/Services")
local Utils = require("../Core/Utils")

local WindowLoader = {}

function WindowLoader.LoadWindUI()
	if _G.THubXWindUI then
		return _G.THubXWindUI
	end
	local src = Utils.HttpGetWithRetry(Config.WindUIUrl, 3)
	local fn, err = loadstring(src)
	if not fn then
		error("[THubX] WindUI 解析失败: " .. tostring(err))
	end
	local WindUI = fn()
	_G.THubXWindUI = WindUI
	return WindUI
end

function WindowLoader.Create()
	local WindUI = WindowLoader.LoadWindUI()

	local Window = WindUI:CreateWindow({
		Title = Config.Title,
		Icon = "rocket",
		Author = Config.Author,
		Folder = Config.Folder,
		Theme = Config.Theme,
		Size = UDim2.fromOffset(580, 460),
		MinSize = Vector2.new(560, 350),
		MaxSize = Vector2.new(850, 560),
		ToggleKey = Enum.KeyCode.RightShift,
		Transparent = true,
		Resizable = true,
		SideBarWidth = 200,
		ScrollBarEnabled = true,
		HideSearchBar = false,
	})

	local Tabs = {
		Movement = Window:Tab({ Title = "移动", Icon = "bird" }),
		Visual = Window:Tab({ Title = "视觉", Icon = "eye" }),
		Combat = Window:Tab({ Title = "战斗", Icon = "swords" }),
		Hanker = Window:Tab({ Title = "恶劣", Icon = "shield-alert" }),
		Utility = Window:Tab({ Title = "实用", Icon = "wrench" }),
		Chat = Window:Tab({ Title = "聊天", Icon = "message-circle" }),
		Games = Window:Tab({ Title = "游戏", Icon = "gamepad-2" }),
		Basic = Window:Tab({ Title = "基础设置", Icon = "pencil-ruler" }),
		ScriptHub = Window:Tab({ Title = "脚本中心", Icon = "computer" }),
		Audio = Window:Tab({ Title = "音频", Icon = "audio-waveform" }),
		Filter = Window:Tab({ Title = "滤镜", Icon = "sparkles" }),
		Settings = Window:Tab({ Title = "设置", Icon = "settings" }),
	}

	-- 设置页：界面 + 系统，分 Section 组织，符合WindUI 规范
	local uiSection = Tabs.Settings:Section({ Title = "界面" })
	uiSection:Keybind({
		Title = "界面开关按键",
		Icon = "keyboard",
		Value = "RightShift",
		Callback = function(v)
			local code = Enum.KeyCode[v]
			if code then
				pcall(function()
					Window:SetToggleKey(code)
				end)
			end
		end,
	})
	uiSection:Dropdown({
		Title = "主题",
		Icon = "palette",
		Values = (function()
			local ok, themes = pcall(function()
				return WindUI:GetThemes()
			end)
			if ok and type(themes) == "table" then
				local names = {}
				for name in pairs(themes) do
					table.insert(names, name)
				end
				table.sort(names)
				if #names > 0 then
					return names
				end
			end
			return { "Dark", "Light" }
		end)(),
		Value = (function()
			local ok, current = pcall(function()
				return WindUI:GetCurrentTheme()
			end)
			if ok and type(current) == "string" then
				return current
			end
			return Config.Theme
		end)(),
		Callback = function(v)
			pcall(function()
				WindUI:SetTheme(v)
			end)
		end,
	})

	local sysSection = Tabs.Settings:Section({ Title = "系统" })
	sysSection:Button({
		Title = "卸载 THubX",
		Icon = "trash-2",
		Callback = function()
			local Unload = require("../Core/Unload")
			pcall(function()
				Window:Destroy()
			end)
			Unload.Run()
			Utils.Info("已卸载")
		end,
	})

	-- 窗口关闭/销毁时自动清理，避免残留连接与 ESP
	pcall(function()
		if Window.OnClose then
			Window:OnClose(function()
				local Unload = require("../Core/Unload")
				Unload.Run()
			end)
		end
	end)
	pcall(function()
		if Window.OnDestroy then
			Window:OnDestroy(function()
				local Unload = require("../Core/Unload")
				Unload.Run()
			end)
		end
	end)

	return WindUI, Window, Tabs
end

return WindowLoader
