local Services = require("../../Core/Services")

local GameTP = {}
GameTP.Title = "游戏传送"

local TeleportService = Services.Get("TeleportService")
local HttpService = Services.HttpService
local Players = Services.Players

local function getRootPlaceId(universeId)
	local url = "https://games.roblox.com/v1/games?universeIds=" .. universeId
	local ok, res = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then
		return nil
	end
	local data = HttpService:JSONDecode(res)
	if data and data.data and #data.data > 0 then
		return data.data[1].rootPlaceId
	end
	return nil
end

function GameTP.Init(Tabs, ctx)

	local universeId = ""
	Tabs.Utility:Input({
		Title = "游戏ID(universeId)",
		Icon = "hash",
		Placeholder = "输入数字ID",
		Callback = function(v)
			universeId = v
		end,
	})
	Tabs.Utility:Button({
		Title = "传送",
		Icon = "send",
		Callback = function()
			if universeId == "" then
				ctx.WindUI:Notify({ Title = "游戏传送", Content = "先输入游戏ID", Duration = 3 })
				return
			end
			local placeId = getRootPlaceId(universeId)
			if not placeId then
				ctx.WindUI:Notify({ Title = "游戏传送", Content = "取不到根场景ID", Duration = 3 })
				return
			end
			local ok, err = pcall(function()
				TeleportService:Teleport(placeId, Players.LocalPlayer)
			end)
			if not ok then
				ctx.WindUI:Notify({ Title = "游戏传送", Content = "传送失败", Duration = 3 })
			end
		end,
	})
end

return GameTP
