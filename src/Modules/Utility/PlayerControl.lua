local PlayerControl = {}
PlayerControl.Title = "玩家控制面板"

local URL = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/utility/PlayerControl.lua"
local loaded = false

function PlayerControl.Init(Tabs, ctx)
	local WindUI = ctx.WindUI

	Tabs.Utility:Button({
		Title = "打开玩家控制面板",
		Icon = "users",
		Callback = function()
			if loaded then
				WindUI:Notify({ Title = "玩家控制", Content = "已经打开过了", Duration = 3 })
				return
			end
			local ok, src = pcall(function()
				return game:HttpGet(URL)
			end)
			if not ok or not src or src == "" then
				WindUI:Notify({ Title = "玩家控制", Content = "下载失败，请检查网络", Duration = 3 })
				return
			end
			local fn, err = loadstring(src)
			if not fn then
				WindUI:Notify({ Title = "玩家控制", Content = "解析失败", Duration = 3 })
				return
			end
			if pcall(fn) then
				loaded = true
				WindUI:Notify({ Title = "玩家控制", Content = "面板已打开", Duration = 3 })
			else
				WindUI:Notify({ Title = "玩家控制", Content = "运行失败", Duration = 3 })
			end
		end,
	})
end

return PlayerControl
