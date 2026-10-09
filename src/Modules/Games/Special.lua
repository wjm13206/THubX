local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")
local HighlightMod = require("../Visual/Highlight")
local NameTagMod = require("../Visual/NameTag")

local M = {}
M.Title = "游戏专属"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local ReplicatedStorage = Services.Get("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local HighlightEngine = HighlightMod.Engine
local NameTagEngine = NameTagMod.Engine

local handles = {}

local GamesTab = nil

local function track(key, handle)
	if handles[key] then
		pcall(function()
			if handles[key].destroy then
				handles[key]:destroy()
			end
			if handles[key].disable then
				handles[key]:disable()
			end
		end)
	end
	handles[key] = handle
end

local function untrack(key)
	local h = handles[key]
	handles[key] = nil
	if h then
		pcall(function()
			if h.destroy then
				h:destroy()
			end
			if h.disable then
				h:disable()
			end
		end)
	end
end

local function teleportTo(x, y, z)
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(x, y, z)
	end
end

local function addHighlightToggle(key, title, target, preset)
	GamesTab:Toggle({
		Title = title,
		Icon = "scan",
		Value = false,
		Callback = function(state)
			if state then
				local h = HighlightEngine.new(target, "fuzzy", preset or "item", 100)
				h.apply()
				track(key, h)
			else
				untrack(key)
			end
		end,
	})
end

local function addNameTagToggle(key, title, target, text)
	GamesTab:Toggle({
		Title = title,
		Icon = "tag",
		Value = false,
		Callback = function(state)
			if state then
				local h = NameTagEngine.new(target, "fuzzy", 20, true, text)
				h.enable()
				track(key, h)
			else
				untrack(key)
			end
		end,
	})
end

local function deleteModelsByName(modelName, notify)
	local count = 0
	for _, inst in ipairs(Workspace:GetDescendants()) do
		if inst:IsA("Model") and inst.Name == modelName then
			pcall(function()
				inst:Destroy()
			end)
			count = count + 1
		end
	end
	notify("已删除 " .. count .. " 个 " .. modelName)
end

Unload.OnUnload(function()
	for key in pairs(handles) do
		untrack(key)
	end
end)

function M.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Games, M.Title, { Icon = "scan" })
	local WindUI = ctx.WindUI
	GamesTab = Tabs.Games
	local function notify(text)
		WindUI:Notify({ Title = "游戏专属", Content = text, Duration = 3 })
	end

	-- 小屋角色扮演：快捷指令
	for _, cmd in ipairs({ "/re", "/kid", "/shark", "/dog", "/cat" }) do
		folder:Button({
			Title = "发送指令 " .. cmd,
			Icon = "message-square",
			Callback = function()
				pcall(function()
					local TextChatService = Services.Get("TextChatService")
					if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
						ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(cmd, "All")
					else
						TextChatService.TextChannels.RBXGeneral:SendAsync(cmd)
					end
				end)
			end,
		})
	end

	-- 南极探险队
	for _, pos in ipairs({
		{ "大本营", -6015, -158, -35 },
		{ "营地1", 0, 0, 0 },
		{ "营地2", 0, 0, 0 },
	}) do
		folder:Button({
			Title = "传送到" .. pos[1],
			Icon = "map-pin",
			Callback = function()
				teleportTo(pos[2], pos[3], pos[4])
			end,
		})
	end

	-- 西部森林
	addNameTagToggle("wood_monster", "怪物标签", "WendigoAI", "怪物")
	addNameTagToggle("wood_remake", "怪物标签（重制版）", "Wendigo", "怪物")
	addHighlightToggle("wood_remake_hl", "怪物透视（重制版）", "Wendigo", "hostileNpc")

	-- 警笛头：遗产
	addHighlightToggle("siren_crate", "透视盒子", "crate", "item")
	addNameTagToggle("siren_crate_nt", "盒子标签", "crate", "盒子")
	addHighlightToggle("siren_berry", "透视浆果", "berry", "item")
	addNameTagToggle("siren_berry_nt", "浆果标签", "berry", "浆果")
	folder:Button({
		Title = "传送到树顶",
		Icon = "map-pin",
		Callback = function()
			teleportTo(69, 206, -72)
		end,
	})

	-- 噩梦之行
	addHighlightToggle("nightmare_monster", "高亮怪物", "Monster", "hostileNpc")
	folder:Button({
		Title = "高亮芝士",
		Icon = "scan",
		Callback = function()
			local h = HighlightEngine.new("Cheese", "fuzzy", "item", 100)
			h.apply()
			notify("已高亮芝士")
		end,
	})

	-- 兽化项目
	for _, name in ipairs({ "__SnarePhysical", "Landmine", "__ClaymorePhysical" }) do
		folder:Button({
			Title = "删除 " .. name,
			Icon = "trash-2",
			Callback = function()
				deleteModelsByName(name, notify)
			end,
		})
	end
	addHighlightToggle("transfur_bot", "Bot兽透视", "Bot", "item")
	addNameTagToggle("transfur_bot_nt", "Bot兽标签", "Bot", "Bot兽")
	addHighlightToggle("transfur_small", "小保险箱透视", "__BasicSmallSafe", "item")
	addHighlightToggle("transfur_large", "大保险箱透视", "__BasicLargeSafe", "item")
	addHighlightToggle("transfur_golden", "金保险箱透视", "__LargeGoldenSafe", "item")
	addHighlightToggle("transfur_crate", "武器盒透视", "Surplus Crate", "item")
	addHighlightToggle("transfur_drop", "空投透视", "SupplyDrop", "item")

	-- 后院生存
	addHighlightToggle("yard_skin", "窃皮者透视", "Skin Stealer", "hostileNpc")
	addNameTagToggle("yard_skin_nt", "窃皮者标签", "Skin Stealer", "[敌对] 窃皮者")
	addHighlightToggle("yard_shrieker", "瞎子透视", "Shrieker", "hostileNpc")
	addNameTagToggle("yard_shrieker_nt", "瞎子标签", "Shrieker", "[敌对] 瞎子")
	addHighlightToggle("yard_wretch", "悲尸透视", "Wretch", "hostileNpc")
	addNameTagToggle("yard_wretch_nt", "悲尸标签", "Wretch", "[敌对] 悲尸")
	addHighlightToggle("yard_phantom", "梦魇透视", "Phantom", "hostileNpc")
	addNameTagToggle("yard_phantom_nt", "梦魇标签", "Phantom", "[敌对] 梦魇")
	addHighlightToggle("yard_bacteria", "细菌透视", "Bacteria", "hostileNpc")
	addHighlightToggle("yard_recon", "侦察兵透视", "Recon", "neutralNpc")
	addHighlightToggle("yard_mech", "修理工透视", "Mechanic", "neutralNpc")

	-- 最黑暗的时刻
	addHighlightToggle("dark_scrap", "收集物透视", "Scrap", "item")
	addNameTagToggle("dark_scrap_nt", "收集物标签", "Scrap", "[收集物]")

	-- 深渊
	folder:Button({
		Title = "传送灯笼商店",
		Icon = "map-pin",
		Callback = function()
			teleportTo(-375, -11932, -504)
		end,
	})

	-- 后悔电梯
	addHighlightToggle("reg_coins", "硬币透视", "Coin", "normal")
	addNameTagToggle("reg_coins_nt", "硬币标签", "Coin", "硬币")
	addHighlightToggle("reg_firewood", "木头透视", "Firewood", "item")
	addNameTagToggle("reg_firewood_nt", "木头标签", "Firewood", "[木头]")
end

return M
