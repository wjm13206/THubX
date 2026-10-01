local Unload = require("../../Core/Unload")

local FullESP = {}
FullESP.Title = "完整ESP面板"

local URL = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/visual/ESP.lua"
local loadedGui = nil

local function unloadGui()
	local cg = game:GetService("CoreGui")
	for _, name in pairs({ "UESP1" }) do
		pcall(function()
			local g = cg:FindFirstChild(name)
			if g then
				g:Destroy()
			end
		end)
	end
	loadedGui = nil
end

Unload.OnUnload(function()
	unloadGui()
end)

function FullESP.Init(Tabs, ctx)
	local WindUI = ctx.WindUI
	local section = Tabs.Visual:Section({ Title = "完整ESP" })
	section:Button({
		Title = "打开完整ESP面板",
		Icon = "layout-dashboard",
		Callback = function()
			if loadedGui then
				WindUI:Notify({ Title = "完整ESP", Content = "已经打开过了", Duration = 3 })
				return
			end
			local ok, src = pcall(function()
				return game:HttpGet(URL)
			end)
			if not ok or not src or src == "" then
				WindUI:Notify({ Title = "完整ESP", Content = "下载失败，请检查网络", Duration = 3 })
				return
			end
			local fn, err = loadstring(src)
			if not fn then
				WindUI:Notify({ Title = "完整ESP", Content = "解析失败", Duration = 3 })
				return
			end
			if pcall(fn) then
				loadedGui = true
				WindUI:Notify({ Title = "完整ESP", Content = "面板已打开", Duration = 3 })
			else
				WindUI:Notify({ Title = "完整ESP", Content = "运行失败", Duration = 3 })
			end
		end,
	})
	section:Button({
		Title = "关闭完整ESP面板",
		Icon = "x",
		Callback = function()
			unloadGui()
		end,
	})
end

return FullESP
