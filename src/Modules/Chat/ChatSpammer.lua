local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local ChatSpammer = {}
ChatSpammer.Title = "自动喊话"

local TextChatService = Services.Get("TextChatService")
local ReplicatedStorage = Services.Get("ReplicatedStorage")

local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

local isActive = false
local messages = {}
local interval = 5
local isRandom = false
local currentIndex = 1
local loopThread = nil
local WindUI = nil

local function sendMessage(msg)
	pcall(function()
		if isLegacyChat then
			ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(tostring(msg), "All")
		else
			TextChatService.TextChannels.RBXGeneral:SendAsync(tostring(msg))
		end
	end)
end

local function startLoop()
	if loopThread then
		return
	end
	loopThread = task.spawn(function()
		while isActive do
			if #messages > 0 then
				local msg
				if isRandom then
					msg = messages[math.random(1, #messages)]
				else
					msg = messages[currentIndex]
					currentIndex = currentIndex % #messages + 1
				end
				sendMessage(msg)
			end
			task.wait(interval)
		end
		loopThread = nil
	end)
end

local function stopLoop()
	isActive = false
	if loopThread then
		pcall(task.cancel, loopThread)
		loopThread = nil
	end
end

local function parseMessages(text)
	local lines = {}
	for _, part in ipairs(tostring(text):split("|")) do
		for line in part:gmatch("[^\r\n]+") do
			local trimmed = line:match("^%s*(.-)%s*$")
			if trimmed and trimmed ~= "" then
				table.insert(lines, trimmed)
			end
		end
	end
	messages = lines
	currentIndex = 1
end

Unload.OnUnload(function()
	stopLoop()
	messages = {}
end)

function ChatSpammer.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Chat, ChatSpammer.Title, { Icon = "megaphone" })
	WindUI = ctx.WindUI
	local spamToggle = nil
	spamToggle = folder:Toggle({
		Title = "开始自动喊话",
		Icon = "megaphone",
		Value = false,
		Callback = function(state)
			if state then
				if #messages == 0 then
					WindUI:Notify({Title = "喊话器", Content = "请先填写喊话内容", Duration = 5})
					pcall(function()
						spamToggle:Set(false)
					end)
					return
				end
				if isActive then
					return
				end
				isActive = true
				currentIndex = 1
				startLoop()
			else
				stopLoop()
			end
		end,
	})
	folder:Input({
		Title = "喊话内容",
		Icon = "message-square",
		Placeholder = "多条用| 分隔",
		Callback = function(v)
			parseMessages(v)
		end,
	})
	folder:Slider({
		Title = "发送间隔秒",
		Icon = "timer",
		Step = 1,
		Value = {Min = 1, Max = 60, Default = 5},
		Callback = function(v)
			if type(v) == "number" and v >= 1 then
				interval = v
			end
		end,
	})
	folder:Toggle({
		Title = "随机顺序",
		Icon = "shuffle",
		Value = false,
		Callback = function(state)
			isRandom = state
		end,
	})
end

return ChatSpammer
