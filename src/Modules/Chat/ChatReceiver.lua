local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "聊天接收"

local Players = Services.Players
local TextChatService = Services.Get("TextChatService")

local LocalPlayer = Players.LocalPlayer

local CHAT_MAX = 100
local enabled = false
local messages = {}
local conn = nil
local WindUIRef = nil

local function pushMessage(sender, text)
	table.insert(messages, { Sender = sender, Text = text })
	if #messages > CHAT_MAX then
		table.remove(messages, 1)
	end
	if WindUIRef then
		WindUIRef:Notify({ Title = sender, Content = text, Duration = 5 })
	end
end

local function startReceiver()
	if conn then
		return
	end
	conn = TextChatService.MessageReceived:Connect(function(message)
		if not enabled then
			return
		end
		if not message.TextSource then
			return
		end
		local player = Players:GetPlayerByUserId(message.TextSource.UserId)
		if not player then
			return
		end
		local text = message.Text
		pcall(function()
			if message.WasRewritten then
				text = "(已编辑) " .. message.RewrittenText
			end
		end)
		pushMessage(player.DisplayName .. " (" .. player.Name .. ")", text)
	end)
end

Unload.OnUnload(function()
	if conn then
		conn:Disconnect()
		conn = nil
	end
	table.clear(messages)
end)

function M.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Chat, M.Title, { Icon = "bell" })
	WindUIRef = ctx.WindUI

	folder:Toggle({
		Title = "启用聊天接收",
		Icon = "bell",
		Value = false,
		Callback = function(state)
			enabled = state
			if state then
				startReceiver()
			else
				if conn then
					conn:Disconnect()
					conn = nil
				end
			end
		end,
	})
	folder:Button({
		Title = "复制最近 10 条消息",
		Icon = "clipboard",
		Callback = function()
			if #messages == 0 then
				WindUIRef:Notify({ Title = "聊天接收", Content = "暂无消息", Duration = 3 })
				return
			end
			local lines = {}
			local start = math.max(1, #messages - 9)
			for i = start, #messages do
				table.insert(lines, messages[i].Sender .. ": " .. messages[i].Text)
			end
			if setclipboard then
				setclipboard(table.concat(lines, "\n"))
				WindUIRef:Notify({ Title = "聊天接收", Content = "已复制 " .. #lines .. " 条消息", Duration = 3 })
			else
				WindUIRef:Notify({ Title = "聊天接收", Content = "执行器不支持复制", Duration = 3 })
			end
		end,
	})
	folder:Button({
		Title = "清空消息记录",
		Icon = "trash-2",
		Callback = function()
			table.clear(messages)
			WindUIRef:Notify({ Title = "聊天接收", Content = "已清空", Duration = 2 })
		end,
	})
end

return M
