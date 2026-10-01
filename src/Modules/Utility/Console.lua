local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Console = {}
Console.Title = "控制台"

local gui = nil
local listFrame = nil
local layout = nil
local msgConn = nil
local autoScroll = true
local lineCount = 0
local maxLines = 200

local function makeGui()
	if gui then
		return
	end
	local parent = nil
	pcall(function()
		if gethui then
			parent = gethui()
		end
	end)
	if not parent then
		parent = Services.CoreGui
	end
	if not parent then
		parent = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "THubXConsole"
	gui.ResetOnSpawn = false
	gui.Parent = parent

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(0, 520, 0, 340)
	main.Position = UDim2.new(0.5, -260, 0.5, -170)
	main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = gui

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, 0, 0, 28)
	bar.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	bar.BorderSizePixel = 0
	bar.Parent = main

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -120, 1, 0)
	title.Position = UDim2.new(0, 8, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "THubX 控制台"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 14
	title.Font = Enum.Font.SourceSansBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = bar

	local function makeBtn(name, text, x)
		local b = Instance.new("TextButton")
		b.Name = name
		b.Size = UDim2.new(0, 52, 1, -6)
		b.Position = UDim2.new(1, x, 0, 3)
		b.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.TextSize = 13
		b.Font = Enum.Font.SourceSans
		b.Text = text
		b.Parent = bar
		return b
	end

	local closeBtn = makeBtn("Close", "关闭", -58)
	local clearBtn = makeBtn("Clear", "清空", -116)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Logs"
	scroll.Size = UDim2.new(1, -12, 1, -40)
	scroll.Position = UDim2.new(0, 6, 0, 34)
	scroll.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.Parent = main

	layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = scroll

	listFrame = scroll

	closeBtn.MouseButton1Click:Connect(function()
		if gui then
			gui.Enabled = false
		end
	end)
	clearBtn.MouseButton1Click:Connect(function()
		if listFrame then
			for _, c in listFrame:GetChildren() do
				if c:IsA("TextLabel") then
					c:Destroy()
				end
			end
			lineCount = 0
		end
	end)
end

local function addLine(text, color)
	makeGui()
	if not listFrame then
		return
	end
	lineCount = lineCount + 1
	local label = Instance.new("TextLabel")
	label.Name = "L" .. lineCount
	label.Size = UDim2.new(1, -8, 0, 16)
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
	label.TextSize = 13
	label.Font = Enum.Font.Code
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	label.LayoutOrder = lineCount
	label.Parent = listFrame
	local children = 0
	for _, c in listFrame:GetChildren() do
		if c:IsA("TextLabel") then
			children = children + 1
		end
	end
	if children > maxLines then
		for _, c in listFrame:GetChildren() do
			if c:IsA("TextLabel") and c.LayoutOrder <= lineCount - maxLines then
				c:Destroy()
			end
		end
	end
	if autoScroll then
		task.defer(function()
			if listFrame then
				listFrame.CanvasPosition = Vector2.new(0, listFrame.AbsoluteCanvasSize.Y)
			end
		end)
	end
end

local function startListen()
	if msgConn then
		return
	end
	msgConn = Services.LogService.MessageOut:Connect(function(msg, msgType)
		local color = Color3.fromRGB(200, 200, 200)
		if msgType == Enum.MessageType.MessageError then
			color = Color3.fromRGB(255, 110, 110)
		end
		if msgType == Enum.MessageType.MessageWarning then
			color = Color3.fromRGB(255, 210, 110)
		end
		addLine("[" .. tostring(msgType) .. "] " .. tostring(msg), color)
	end)
end

local function disable()
	if msgConn then
		msgConn:Disconnect()
		msgConn = nil
	end
	if gui then
		gui:Destroy()
		gui = nil
		listFrame = nil
		layout = nil
	end
	lineCount = 0
end

Unload.OnUnload(disable)

function Console.Init(Tabs, ctx)
	startListen()
	local section = Tabs.Utility:Section({
		Title = "控制台",
		Icon = "terminal",
	})
	section:Button({
		Title = "打开控制台",
		Icon = "terminal",
		Callback = function()
			makeGui()
			startListen()
			if gui then
				gui.Enabled = true
			end
		end,
	})
	section:Toggle({
		Title = "自动滚动",
		Icon = "arrow-down",
		Default = true,
		Callback = function(state)
			autoScroll = state
		end,
	})
	section:Button({
		Title = "清空日志",
		Icon = "trash-2",
		Callback = function()
			if listFrame then
				for _, c in listFrame:GetChildren() do
					if c:IsA("TextLabel") then
						c:Destroy()
					end
				end
				lineCount = 0
			end
		end,
	})
end

return Console
