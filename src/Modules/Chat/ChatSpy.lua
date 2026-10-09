local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local ChatSpy = {}
ChatSpy.Title = "聊天偷听"

local Players = Services.Players
local TextChatService = Services.Get("TextChatService")
local LocalPlayer = Players.LocalPlayer

local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

local enabled = false
local connections = {}
local spyOnSelf = false
local publicMode = false
local ignoreList = {
	{Message = ":part/1/1/1", ExactMatch = true},
	{Message = ":part/10/10/10", ExactMatch = true},
	{Message = "A?????????", ExactMatch = false},
	{Message = ":colorshifttop 10000 0 0", ExactMatch = true},
	{Message = ":colorshiftbottom 10000 0 0", ExactMatch = true},
	{Message = ":colorshifttop 0 10000 0", ExactMatch = true},
	{Message = ":colorshiftbottom 0 0 10000", ExactMatch = true},
	{Message = ":colorshifttop 0 0 10000", ExactMatch = true},
	{Message = ":colorshiftbottom 0 0 10000", ExactMatch = true},
}

local WindUI = nil
local generalChannel = nil

local function getGeneralChannel()
	if not generalChannel then
		generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
	end
	return generalChannel
end

local function notify(text)
	if WindUI then
		WindUI:Notify({Title = "ChatSpy", Content = text, Duration = 5})
	end
end

local function isIgnored(message)
	for _, v in ipairs(ignoreList) do
		if v.ExactMatch and message == v.Message then
			return true
		elseif not v.ExactMatch and message:find(v.Message) then
			return true
		end
	end
	return false
end

local function sendSpyMessage(text)
	local messageText = "[SPY] - " .. text
	if publicMode then
		local channel = getGeneralChannel()
		if channel then
			channel:SendAsync(messageText)
		elseif isLegacyChat then
			local ReplicatedStorage = Services.Get("ReplicatedStorage")
			local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
			if chatEvents then
				local sayRequest = chatEvents:FindFirstChild("SayMessageRequest")
				if sayRequest then
					sayRequest:FireServer(messageText, "All")
				end
			end
		end
	else
		if isLegacyChat then
			Services.Get("StarterGui"):SetCore("ChatMakeSystemMessage", {
				Text = messageText,
				Color = Color3.fromRGB(255, 0, 0),
			})
		else
			notify(messageText)
		end
	end
end

local function onMessageReceived(message, channel)
	if not enabled then
		return
	end
	local sender = message.TextSource
	local player = sender and Players:GetPlayerByUserId(sender.UserId)
	if not player then
		return
	end
	if not spyOnSelf and player == LocalPlayer then
		return
	end
	local rawText = message.Text
	pcall(function()
		if message.WasRewritten then
			rawText = "(已编辑 " .. message.RewrittenText
		end
	end)
	local cleanedMessage = rawText:gsub("[\n\r]", ""):gsub("\t", " "):gsub("[ ]+", " ")
	if #cleanedMessage == 0 or isIgnored(cleanedMessage) then
		return
	end
	if #cleanedMessage > 1200 then
		cleanedMessage = cleanedMessage:sub(1, 1200) .. "..."
	end
	local channelPrefix = ""
	if channel.Name == "RBXTeam" then
		channelPrefix = "[Team] "
	end
	sendSpyMessage(channelPrefix .. player.Name .. ": " .. cleanedMessage)
end

local function setupNewChatListener()
	local channel = getGeneralChannel()
	if not channel then
		task.wait(1)
		if not enabled then
			return
		end
		setupNewChatListener()
		return
	end
	local generalConn = channel.MessageReceived:Connect(function(msg)
		onMessageReceived(msg, channel)
	end)
	table.insert(connections, generalConn)
	local teamChannel = TextChatService.TextChannels:FindFirstChild("RBXTeam")
	if teamChannel then
		local teamConn = teamChannel.MessageReceived:Connect(function(msg)
			onMessageReceived(msg, teamChannel)
		end)
		table.insert(connections, teamConn)
	end
end

local function clearAllConnections()
	for _, conn in ipairs(connections) do
		if conn then
			conn:Disconnect()
		end
	end
	connections = {}
end

local function setEnabled(state)
	if state then
		if enabled then
			return
		end
		enabled = true
		clearAllConnections()
		if isLegacyChat then
			notify("旧版聊天暂不支持")
			return
		end
		setupNewChatListener()
		notify("已启用")
	else
		if not enabled then
			return
		end
		enabled = false
		clearAllConnections()
		notify("已停用")
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function ChatSpy.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Chat, ChatSpy.Title, { Icon = "eye" })
	WindUI = ctx.WindUI
	folder:Toggle({
		Title = "启用聊天偷听",
		Icon = "eye",
		Value = false,
		Callback = function(state)
			setEnabled(state)
		end,
	})
	folder:Toggle({
		Title = "偷听自己的消息",
		Icon = "user",
		Value = false,
		Callback = function(state)
			spyOnSelf = state
		end,
	})
	folder:Toggle({
		Title = "公开广播",
		Icon = "megaphone",
		Value = false,
		Callback = function(state)
			publicMode = state
		end,
	})
end

return ChatSpy
