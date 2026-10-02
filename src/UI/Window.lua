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

	-- 最小化
	local reopenGui = nil
	local reopenConns = {}
	local function setReopenVisible(v)
		pcall(function()
			if reopenGui then
				reopenGui.Enabled = v
			end
		end)
	end
	local function destroyReopen()
		for _, c in ipairs(reopenConns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		table.clear(reopenConns)
		if reopenGui then
			pcall(function()
				reopenGui:Destroy()
			end)
			reopenGui = nil
		end
	end
	pcall(function()
		local uiParent
		do
			local okHui, hui = pcall(function()
				return (gethui and gethui()) or nil
			end)
			if okHui and hui then
				uiParent = hui
			else
				local plr = Services.Players.LocalPlayer
				uiParent = plr and plr:FindFirstChildOfClass("PlayerGui") or Services.CoreGui
			end
		end
		reopenGui = Instance.new("ScreenGui")
		reopenGui.Name = "THubXReopen"
		reopenGui.ResetOnSpawn = false
		reopenGui.DisplayOrder = 999
		reopenGui.IgnoreGuiInset = true
		reopenGui.Enabled = false
		pcall(function()
			if protectgui then
				protectgui(reopenGui)
			elseif syn and syn.protect_gui then
				syn.protect_gui(reopenGui)
			end
		end)
		reopenGui.Parent = uiParent

		local btn = Instance.new("TextButton")
		btn.Name = "Open"
		btn.Size = UDim2.fromOffset(56, 56)
		btn.Position = UDim2.new(1, -72, 0.5, -28)
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = "THubX"
		btn.TextSize = 13
		btn.Font = Enum.Font.GothamBold
		btn.AutoButtonColor = true
		btn.Parent = reopenGui
		pcall(function()
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 12)
			corner.Parent = btn
		end)

		-- 点按重开窗口，按住拖动换位置(拖动不触发打开)
		local dragging = false
		local dragStart = nil
		local startPos = nil
		local moved = false
		table.insert(reopenConns, btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				moved = false
				dragStart = input.Position
				startPos = btn.Position
			end
		end))
		table.insert(reopenConns, Services.UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				if delta.Magnitude > 8 then
					moved = true
				end
				btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end))
		table.insert(reopenConns, Services.UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local wasDrag = moved
				dragging = false
				moved = false
				if not wasDrag then
					pcall(function()
						Window:Open()
					end)
				end
			end
		end))
	end)

	-- 最小化只切换悬浮按钮显隐，不卸载任何功能
	pcall(function()
		if Window.OnClose then
			Window:OnClose(function()
				setReopenVisible(true)
			end)
		end
	end)
	pcall(function()
		if Window.OnOpen then
			Window:OnOpen(function()
				setReopenVisible(false)
			end)
		end
	end)
	-- 只有真正销毁窗口时才清理(卸载按钮会显式调 Unload.Run，这里是兜底)
	pcall(function()
		if Window.OnDestroy then
			Window:OnDestroy(function()
				local Unload = require("../Core/Unload")
				Unload.Run()
			end)
		end
	end)
	-- 卸载时销毁悬浮按钮，避免残留
	pcall(function()
		local Unload = require("../Core/Unload")
		Unload.OnUnload(destroyReopen)
	end)

	return WindUI, Window, Tabs
end

return WindowLoader
