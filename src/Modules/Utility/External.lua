local External = {}
External.Title = "外部脚本"

local OLD_BASE = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main"

local function loadRemote(path, title, ctx)
	local ok, err = pcall(function()
		local src = game:HttpGet(OLD_BASE .. path)
		local fn = loadstring(src)
		fn()
	end)
	if ctx and ctx.WindUI then
		if ok then
			ctx.WindUI:Notify({ Title = title, Content = "已加载", Duration = 3 })
		else
			ctx.WindUI:Notify({ Title = title, Content = "加载失败", Duration = 3 })
		end
	end
end

function External.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Data, External.Title, { Icon = "database" })

	folder:Button({
		Title = "打开 Dex",
		Icon = "database",
		Callback = function()
			loadRemote("/modules/scripts/DexDark.lua", "Dex", ctx)
		end,
	})
	folder:Button({
		Title = "打开 IY 指令",
		Icon = "terminal",
		Callback = function()
			loadRemote("/modules/scripts/IY.lua", "IY", ctx)
		end,
	})
end

return External
