local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local ChatControl = {}
ChatControl.Title = "聊天控制"

local Players = Services.Players
local TextChatService = Services.Get("TextChatService")
local ReplicatedStorage = Services.Get("ReplicatedStorage")

local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

local connections = {}
local showIncoming = false
local WindUI = nil

local function chat(str)
	str = tostring(str)
	local ok, err = pcall(function()
		if not isLegacyChat then
			TextChatService.TextChannels.RBXGeneral:SendAsync(str)
		else
			ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "All")
		end
	end)
	return ok, err
end

local function startReceiver()
	local conn = TextChatService.MessageReceived:Connect(function(message)
		if not showIncoming then
			return
		end
		if not message.TextSource then
			return
		end
		local player = Players:GetPlayerByUserId(message.TextSource.UserId)
		if not player then
			return
		end
		local messagetext = message.Text
		pcall(function()
			if message.WasRewritten then
				messagetext = "(已编辑 " .. message.RewrittenText
			end
		end)
		if WindUI then
			WindUI:Notify({Title = player.DisplayName .. " (" .. player.Name .. ")", Content = messagetext, Duration = 5})
		end
	end)
	table.insert(connections, conn)
end

local function stopReceiver()
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)
end

Unload.OnUnload(function()
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	connections = {}
end)

function ChatControl.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Chat, ChatControl.Title, { Icon = "message-square" })
	WindUI = ctx.WindUI
	local pendingText = ""
	folder:Input({
		Title = "发送内容",
		Icon = "message-square",
		Placeholder = "输入要发送的消息",
		Callback = function(v)
			pendingText = tostring(v)
		end,
	})
	folder:Button({
		Title = "发送消息",
		Icon = "send",
		Callback = function()
			if pendingText ~= "" then
				chat(pendingText)
			end
		end,
	})
	folder:Toggle({
		Title = "通知显示收到的消息",
		Icon = "bell",
		Value = false,
		Callback = function(state)
			showIncoming = state
			if state then
				stopReceiver()
				startReceiver()
			else
				stopReceiver()
			end
		end,
	})
end

return ChatControl
