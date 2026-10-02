local WorldShader = {}
WorldShader.Title = "世界着色器"

local URL = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/visual/WorldShader.lua"

function WorldShader.Init(Tabs, ctx)
	local WindUI = ctx.WindUI
	Tabs.Visual:Button({
		Title = "应用世界着色器",
		Icon = "palette",
		Callback = function()
			local ok, src = pcall(function()
				return game:HttpGet(URL)
			end)
			if not ok or not src or src == "" then
				WindUI:Notify({ Title = "着色器", Content = "下载失败，请检查网络", Duration = 3 })
				return
			end
			local fn, err = loadstring(src)
			if not fn then
				WindUI:Notify({ Title = "着色器", Content = "解析失败", Duration = 3 })
				return
			end
			if pcall(fn) then
				WindUI:Notify({ Title = "着色器", Content = "已应用", Duration = 3 })
			else
				WindUI:Notify({ Title = "着色器", Content = "运行失败", Duration = 3 })
			end
		end,
	})
end

return WorldShader
