local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local ChatTag = {}
ChatTag.Title = "聊天标签"

local Players = Services.Players
local TextChatService = Services.Get("TextChatService")

local activeTags = {}
local listenerOn = false

local function color3ToHex(color)
	return string.format("#%02X%02X%02X",
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255))
end

local function buildTagText(config, rainbowHex)
	local parts = {}
	local fontTag = config.font and string.format(' font="%s"', config.font) or ""
	if config.rainbow then
		table.insert(parts, string.format('<font color="%s"%s>', rainbowHex or "#FFFFFF", fontTag))
	elseif config.color then
		table.insert(parts, string.format('<font color="%s"%s>', config.color, fontTag))
	else
		table.insert(parts, string.format("<font%s>", fontTag))
	end
	if config.bold then
		table.insert(parts, "<b>")
	end
	if config.italic then
		table.insert(parts, "<i>")
	end
	table.insert(parts, config.text or "[VIP]")
	if config.italic then
		table.insert(parts, "</i>")
	end
	if config.bold then
		table.insert(parts, "</b>")
	end
	table.insert(parts, "</font>")
	table.insert(parts, " ")
	return table.concat(parts)
end

local function onMessage(message)
	if not message.TextSource then
		return nil
	end
	local userId = message.TextSource.UserId
	local tag = activeTags[userId]
	if tag and tag.enabled then
		local rainbowHex = nil
		if tag.config.rainbow then
			local hue = (os.clock() * (tag.config.speed or 2)) % 1
			rainbowHex = color3ToHex(Color3.fromHSV(hue, 1, 1))
		end
		message.PrefixText = buildTagText(tag.config, rainbowHex) .. (message.PrefixText or "")
	end
	return nil
end

local function ensureListener()
	if listenerOn then
		return
	end
	TextChatService.OnIncomingMessage = onMessage
	listenerOn = true
end

local function applyTag(player, config)
	if not player then
		return false
	end
	ensureListener()
	activeTags[player.UserId] = { enabled = true, config = config }
	return true
end

local function removeTag(player)
	if player then
		activeTags[player.UserId] = nil
	end
end

local function clearAll()
	for k in pairs(activeTags) do
		activeTags[k] = nil
	end
	if listenerOn then
		pcall(function()
			TextChatService.OnIncomingMessage = nil
		end)
		listenerOn = false
	end
end

Unload.OnUnload(clearAll)

function ChatTag.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Chat, ChatTag.Title, { Icon = "user" })
	local targetName = ""
	local tagText = "[VIP]"
	local tagColor = Color3.fromRGB(255, 215, 0)
	local rainbow = false
	local toggleObj = nil

	folder:Input({
		Title = "目标玩家名",
		Icon = "user",
		Placeholder = "留空=自己",
		Callback = function(v)
			targetName = v
		end,
	})
	folder:Input({
		Title = "标签文字",
		Icon = "tag",
		Value = "[VIP]",
		Callback = function(v)
			tagText = v
		end,
	})
	folder:Colorpicker({
		Title = "标签颜色",
		Icon = "palette",
		Default = Color3.fromRGB(255, 215, 0),
		Callback = function(v)
			tagColor = v
		end,
	})
	folder:Toggle({
		Title = "彩虹色",
		Icon = "rainbow",
		Value = false,
		Callback = function(v)
			rainbow = v
		end,
	})
	folder:Button({
		Title = "应用标签",
		Icon = "check",
		Callback = function()
			local player = Players.LocalPlayer
			if targetName ~= "" then
				player = Players:FindFirstChild(targetName)
				if not player then
					ctx.WindUI:Notify({ Title = "聊天标签", Content = "找不到玩家", Duration = 3 })
					return
				end
			end
			applyTag(player, {
				text = tagText,
				color = color3ToHex(tagColor),
				rainbow = rainbow,
			})
			ctx.WindUI:Notify({ Title = "聊天标签", Content = "已应用", Duration = 3 })
		end,
	})
	folder:Button({
		Title = "清除全部标签",
		Icon = "trash-2",
		Callback = function()
			clearAll()
			if toggleObj then
				toggleObj:Set(false)
			end
		end,
	})
end

return ChatTag
