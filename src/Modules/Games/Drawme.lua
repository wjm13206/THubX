local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Drawme = {}
Drawme.Title = "Drawme绘画"

local URL = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/games/DrawmeModule.lua"
local loaded = nil

Unload.OnUnload(function()
	if loaded and loaded.unload then
		pcall(function()
			loaded:unload()
		end)
	end
	loaded = nil
end)

function Drawme.Init(Tabs, ctx)
	local WindUI = ctx.WindUI
	local section = Tabs.Games:Section({ Title = "Drawme" })
	section:Button({
		Title = "加载 Drawme 工具",
		Icon = "brush",
		Callback = function()
			if loaded then
				WindUI:Notify({ Title = "Drawme", Content = "已经加载过了", Duration = 3 })
				return
			end
			local ok, src = pcall(function()
				return game:HttpGet(URL)
			end)
			if not ok or not src or src == "" then
				WindUI:Notify({ Title = "Drawme", Content = "下载失败，请检查网络", Duration = 3 })
				return
			end
			local fn, err = loadstring(src)
			if not fn then
				WindUI:Notify({ Title = "Drawme", Content = "解析失败", Duration = 3 })
				return
			end
			local okRun, res = pcall(fn)
			if okRun then
				loaded = res
				if type(loaded) == "table" and loaded.enable then
					pcall(function()
						loaded:enable()
					end)
				end
				WindUI:Notify({ Title = "Drawme", Content = "加载成功", Duration = 3 })
			else
				WindUI:Notify({ Title = "Drawme", Content = "运行失败", Duration = 3 })
			end
		end,
	})
end

return Drawme
