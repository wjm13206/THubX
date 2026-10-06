local Config = require("../Core/Config")
local Services = require("../Core/Services")
local Utils = require("../Core/Utils")
local Confirm = require("../Core/Confirm")
local ConfigStore = require("../Core/ConfigStore")

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
		-- 最小化/关闭后的悬浮重开按钮：默认 WindUI 只在移动端显示，
		-- 强制 PC 也显示
		OpenButton = {
			Title = Config.Title,
			Icon = "rocket",
			Enabled = true,
			Draggable = true,
			OnlyMobile = false,
			CornerRadius = UDim.new(1, 0),
			StrokeThickness = 2,
		},
	})

	-- 兼容处理
	pcall(function()
		if Window.EditOpenButton then
			Window:EditOpenButton({
				Title = Config.Title,
				Icon = "rocket",
				Enabled = true,
				Draggable = true,
				OnlyMobile = false,
				CornerRadius = UDim.new(1, 0),
				StrokeThickness = 2,
			})
		end
	end)

	local Tabs = {
		Movement = Window:Tab({ Title = "移动", Icon = "bird" }),
		Flight = Window:Tab({ Title = "飞行", Icon = "plane" }),
		ESP = Window:Tab({ Title = "透视", Icon = "eye" }),
		Visual = Window:Tab({ Title = "视觉", Icon = "palette" }),
		Combat = Window:Tab({ Title = "战斗", Icon = "swords" }),
		Hanker = Window:Tab({ Title = "恶劣", Icon = "shield-alert" }),
		Teleport = Window:Tab({ Title = "传送", Icon = "map-pin" }),
		Interact = Window:Tab({ Title = "互动", Icon = "mouse-pointer-click" }),
		Protect = Window:Tab({ Title = "防护", Icon = "shield" }),
		Camera = Window:Tab({ Title = "视角", Icon = "video" }),
		Data = Window:Tab({ Title = "数据", Icon = "database" }),
		Chat = Window:Tab({ Title = "聊天", Icon = "message-circle" }),
		Games = Window:Tab({ Title = "游戏", Icon = "gamepad-2" }),
		Basic = Window:Tab({ Title = "基础设置", Icon = "pencil-ruler" }),
		ScriptHub = Window:Tab({ Title = "脚本中心", Icon = "computer" }),
		Audio = Window:Tab({ Title = "音频", Icon = "audio-waveform" }),
		Filter = Window:Tab({ Title = "滤镜", Icon = "sparkles" }),
		FeatureSettings = Window:Tab({ Title = "功能设置", Icon = "sliders-horizontal" }),
		Settings = Window:Tab({ Title = "设置", Icon = "settings" }),
	}

	-- 当前设置：先建本游戏配置，再给元素自动补 Flag（模块加载时注册进配置）
	pcall(function()
		ConfigStore.Setup(Window)
		ConfigStore.WrapTabs(Tabs)
	end)

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
			Confirm.Show(Window, {
				Title = "卸载 THubX",
				Content = "确定要卸载并清理所有功能吗？界面将关闭且无法恢复。",
				ConfirmText = "卸载",
				OnConfirm = function()
					local Unload = require("../Core/Unload")
					pcall(function()
						Window:Destroy()
					end)
					Unload.Run()
					Utils.Info("已卸载")
				end,
			})
		end,
	})

	-- 界面设置：按游戏隔离，存于 WindUI/THubX/config/Game_<PlaceId>.json
	-- 保存是静默自动的（卸载时自动保存），这里只提供删除
	local saveSection = Tabs.Settings:Section({ Title = "当前设置" })
	pcall(function()
		if saveSection.Paragraph then
			saveSection:Paragraph({
				Title = "本游戏设置",
				Desc = ConfigStore.GameKey() .. "（每个游戏独立保存，卸载时自动写入）",
			})
		end
	end)
	saveSection:Button({
		Title = "删除本游戏已保存设置",
		Icon = "trash",
		Callback = function()
			Confirm.Show(Window, {
				Title = "删除已保存设置",
				Content = "确定要删除当前游戏已保存的界面设置吗？删除后下次启动恢复默认设置。",
				ConfirmText = "删除",
				OnConfirm = function()
					if ConfigStore.Delete() then
						Utils.Info("已保存设置已删除")
					else
						Utils.NotifyFallback("THubX", "当前执行器不支持设置保存")
					end
				end,
			})
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
