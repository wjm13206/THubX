local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local ServerFinder = {}
ServerFinder.Title = "找服"

local servers = {}
local scanning = false

local function fetchPage(placeId, cursor)
	local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Desc&limit=100"
	if cursor and cursor ~= "null" then
		url = url .. "&cursor=" .. cursor
	end
	local success, result = pcall(function()
		return Services.HttpService:JSONDecode(game:HttpGet(url))
	end)
	if not success then
		return nil
	end
	return result
end

local function refreshServers(ctx)
	if scanning then
		return
	end
	scanning = true
	servers = {}
	local cursor = nil
	while true do
		local page = fetchPage(game.PlaceId, cursor)
		if not page then
			break
		end
		if page.data then
			for _, server in ipairs(page.data) do
				table.insert(servers, server)
			end
		end
		cursor = page.nextPageCursor
		if not cursor or cursor == "null" then
			break
		end
		task.wait()
	end
	scanning = false
	ctx.WindUI:Notify({ Title = "找服", Content = "找到 " .. #servers .. " 个服务器", Duration = 3 })
end

local function joinServer(serverId)
	local teleportService = Services.Get("TeleportService")
	pcall(function()
		teleportService:TeleportToPlaceInstance(game.PlaceId, serverId, Services.Players.LocalPlayer)
	end)
end

Unload.OnUnload(function()
	servers = {}
end)

function ServerFinder.Init(Tabs, ctx)

	Tabs.Teleport:Button({
		Title = "刷新服务器列表",
		Icon = "refresh-ccw",
		Callback = function()
			task.spawn(function()
				refreshServers(ctx)
			end)
		end,
	})
	Tabs.Teleport:Button({
		Title = "加入人数最少的服",
		Icon = "users",
		Callback = function()
			if #servers == 0 then
				ctx.WindUI:Notify({ Title = "找服", Content = "请先刷新列表", Duration = 3 })
				return
			end
			local best = nil
			for _, server in ipairs(servers) do
				if server.playing < server.maxPlayers then
					if not best or server.playing < best.playing then
						best = server
					end
				end
			end
			if best then
				joinServer(best.id)
			else
				ctx.WindUI:Notify({ Title = "找服", Content = "没有可加入的服", Duration = 3 })
			end
		end,
	})
	Tabs.Teleport:Button({
		Title = "随机换服",
		Icon = "shuffle",
		Callback = function()
			if #servers == 0 then
				ctx.WindUI:Notify({ Title = "找服", Content = "请先刷新列表", Duration = 3 })
				return
			end
			local pick = servers[math.random(1, #servers)]
			joinServer(pick.id)
		end,
	})
end

return ServerFinder
