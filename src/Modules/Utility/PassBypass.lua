local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local PassBypass = {}
PassBypass.Title = "通行证领取"

local productCache = {}
local gamepassCache = {}
local manualId = ""

local function fireProductPurchase(productId)
	return pcall(function()
		Services.MarketplaceService:SignalPromptProductPurchaseFinished(
			Services.Players.LocalPlayer.UserId, productId, true)
	end)
end

local function fireGamepassPurchase(passId)
	return pcall(function()
		Services.MarketplaceService:SignalPromptGamePassPurchaseFinished(
			Services.Players.LocalPlayer, passId, true)
	end)
end

local function refreshProducts(ctx)
	table.clear(productCache)
	local ok, pages = pcall(function()
		return Services.MarketplaceService:GetDeveloperProductsAsync()
	end)
	if not ok or not pages then
		ctx.WindUI:Notify({ Title = "通行证领取", Content = "开发者产品列表获取失败", Duration = 3 })
		return
	end
	while true do
		local okPage, items = pcall(function()
			return pages:GetCurrentPage()
		end)
		if okPage and items then
			for _, product in ipairs(items) do
				pcall(function()
					productCache[product.Name] = product.ProductId
				end)
			end
		end
		local isFinished = true
		pcall(function()
			isFinished = pages.IsFinished
		end)
		if isFinished then
			break
		end
		local okNext = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not okNext then
			break
		end
	end
	local count = 0
	for _ in pairs(productCache) do
		count = count + 1
	end
	ctx.WindUI:Notify({ Title = "通行证领取", Content = "开发者产品 " .. count .. " 个", Duration = 3 })
end

local function getUniverseId()
	local url = "https://apis.roblox.com/universes/v1/places/" .. tostring(game.PlaceId) .. "/universe"
	local ok, res = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok or not res then
		return nil
	end
	local ok2, data = pcall(Services.HttpService.JSONDecode, Services.HttpService, res)
	if ok2 and data and data.universeId then
		return data.universeId
	end
	return nil
end

local function refreshGamepasses(ctx)
	table.clear(gamepassCache)
	local universeId = getUniverseId()
	if not universeId then
		ctx.WindUI:Notify({ Title = "通行证领取", Content = "UniverseId 获取失败", Duration = 3 })
		return
	end
	local url = "https://apis.roblox.com/game-passes/v1/universes/" .. tostring(universeId)
		.. "/game-passes?passView=Full&pageSize=100"
	local ok, res = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok or not res then
		ctx.WindUI:Notify({ Title = "通行证领取", Content = "通行证列表获取失败", Duration = 3 })
		return
	end
	local ok2, data = pcall(Services.HttpService.JSONDecode, Services.HttpService, res)
	if ok2 and data and data.data then
		for _, gp in ipairs(data.data) do
			pcall(function()
				local displayName = gp.displayName or gp.name or ("Pass_" .. tostring(gp.id))
				gamepassCache[displayName] = gp.id
			end)
		end
	end
	local count = 0
	for _ in pairs(gamepassCache) do
		count = count + 1
	end
	ctx.WindUI:Notify({ Title = "通行证领取", Content = "游戏通行证 " .. count .. " 个", Duration = 3 })
end

Unload.OnUnload(function()
	table.clear(productCache)
	table.clear(gamepassCache)
end)

function PassBypass.Init(Tabs, ctx)

	Tabs.Utility:Button({
		Title = "刷新开发者产品",
		Icon = "refresh-ccw",
		Callback = function()
			task.spawn(function()
				refreshProducts(ctx)
			end)
		end,
	})
	Tabs.Utility:Button({
		Title = "刷新游戏通行证",
		Icon = "refresh-ccw",
		Callback = function()
			task.spawn(function()
				refreshGamepasses(ctx)
			end)
		end,
	})
	Tabs.Utility:Input({
		Title = "通行证/产品名称",
		Icon = "ticket",
		Placeholder = "输入刷新到的名称",
		Callback = function(v)
			manualId = v
		end,
	})
	Tabs.Utility:Button({
		Title = "领取所填项",
		Icon = "key",
		Callback = function()
			if manualId == "" then
				ctx.WindUI:Notify({ Title = "通行证领取", Content = "请先输入名称", Duration = 3 })
				return
			end
			if productCache[manualId] then
				fireProductPurchase(productCache[manualId])
				ctx.WindUI:Notify({ Title = "通行证领取", Content = "已发送产品购买信号", Duration = 3 })
			elseif gamepassCache[manualId] then
				fireGamepassPurchase(gamepassCache[manualId])
				ctx.WindUI:Notify({ Title = "通行证领取", Content = "已发送通行证购买信号", Duration = 3 })
			else
				ctx.WindUI:Notify({ Title = "通行证领取", Content = "未找到该名称，请先刷新", Duration = 3 })
			end
		end,
	})
	Tabs.Utility:Button({
		Title = "一键全领",
		Icon = "zap",
		Callback = function()
			task.spawn(function()
				local count = 0
				for _, id in pairs(productCache) do
					if fireProductPurchase(id) then
						count = count + 1
					end
					task.wait(0.5)
				end
				for _, id in pairs(gamepassCache) do
					if fireGamepassPurchase(id) then
						count = count + 1
					end
					task.wait(0.5)
				end
				ctx.WindUI:Notify({ Title = "通行证领取", Content = "已发送 " .. count .. " 个信号", Duration = 3 })
			end)
		end,
	})
end

return PassBypass
