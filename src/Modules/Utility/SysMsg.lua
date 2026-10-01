local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local SysMsg = {}
SysMsg.Title = "系统消息"

local textChatService = nil
pcall(function()
	textChatService = Services.Get("TextChatService")
end)
local isLegacyChat = false
if textChatService then
	isLegacyChat = textChatService.ChatVersion == Enum.ChatVersion.LegacyChatService
end

local message = ""
local msgType = "Info"

local function escape(text)
	return text:gsub("[<>&]", {
		["<"] = "&lt;",
		[">"] = "&gt;",
		["&"] = "&amp;",
	})
end

local function send(messageText, colorRGB, font, size)
	if isLegacyChat then
		local player = Services.Players.LocalPlayer
		if not player then
			return
		end
		local gui = player:WaitForChild("PlayerGui")
		pcall(function()
			gui:SetCore("ChatMakeSystemMessage", {
				Text = messageText,
				Color = colorRGB,
			})
		end)
	else
		if not textChatService then
			return
		end
		local channel = textChatService.TextChannels:FindFirstChild("RBXGeneral")
		if not channel then
			return
		end
		local r = math.floor(colorRGB.R * 255)
		local g = math.floor(colorRGB.G * 255)
		local b = math.floor(colorRGB.B * 255)
		local rich = string.format(
			"<font color=\"rgb(%d,%d,%d)\" face=\"%s\" size=\"%d\">%s</font>",
			r, g, b, font, size, escape(messageText))
		channel:DisplaySystemMessage(rich)
	end
end

local TYPE_MAP = {
	Info = { Color3.fromRGB(100, 150, 255), "SourceSans", 14 },
	Success = { Color3.fromRGB(0, 255, 0), "GothamBold", 18 },
	Warning = { Color3.fromRGB(255, 200, 0), "SourceSansBold", 16 },
	Error = { Color3.fromRGB(255, 0, 0), "GothamBold", 20 },
}

Unload.OnUnload(function()
end)

function SysMsg.Init(Tabs, ctx)
	local section = Tabs.Utility:Section({ Title = "系统消息" })
	section:Input({
		Title = "消息内容",
		Icon = "message-square",
		Placeholder = "输入要发送的内容",
		Callback = function(v)
			message = v
		end,
	})
	section:Dropdown({
		Title = "消息类型",
		Icon = "list",
		Values = { "Info", "Success", "Warning", "Error" },
		Value = "Info",
		Callback = function(v)
			msgType = v
		end,
	})
	section:Button({
		Title = "发送",
		Icon = "send",
		Callback = function()
			if message == "" then
				ctx.WindUI:Notify({ Title = "系统消息", Content = "请先输入内容", Duration = 3 })
				return
			end
			local preset = TYPE_MAP[msgType] or TYPE_MAP.Info
			send(message, preset[1], preset[2], preset[3])
		end,
	})
end

return SysMsg
