local Utils = require("../../Core/Utils")

local M = {}
M.Title = "脚本中心"

local OLD_BASE = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main"

local ScriptList = {
	{ Name = "飞行V4", Link = OLD_BASE .. "/modules/movement/FlyV4.lua" },
	{ Name = "IY指令挂（汉化版）", Link = OLD_BASE .. "/modules/scripts/IY.lua" },
	{ Name = "Dex", Link = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua" },
	{ Name = "Dex++", Link = "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua" },
	{ Name = "BetterDex", Link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/betterdex.lua" },
	{ Name = "SolaraDex", Link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/solaradex.lua" },
	{ Name = "SecureDex", Link = "https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua" },
	{ Name = "DexDark", Link = OLD_BASE .. "/modules/scripts/DexDark.lua" },
	{ Name = "Cobalt", Link = "https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau" },
	{ Name = "SimpleSpy", Link = "https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua" },
	{ Name = "UNC测试", Link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/UNCCheckEnv.lua" },
	{ Name = "SUNC测试", Link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/sUNCm0m3n7.lua" },
	{ Name = "CUNC测试", Link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/cunc.lua" },
	{ Name = "身份测试", Link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/identitytest.lua" },
	{ Name = "更多UNCV1", Link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/moreuncv1.lua" },
	{ Name = "更多UNCV2", Link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/moreuncv2.lua" },
	{ Name = "更多UNCV3", Link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/moreuncv3.lua" },
	{ Name = "NPC自瞄", Link = "https://rawscripts.net/raw/Universal-Script-Npc-Aimbot-64954" },
	{ Name = "SolaraHub", Link = "https://raw.githubusercontent.com/samuraa1/Solara-Hub/refs/heads/main/SH.lua" },
	{ Name = "XAHub", Link = "https://raw.githubusercontent.com/XiaoLuau/Script/main/Loader.lua" },
	{ Name = "控制NPC", Link = "https://raw.githubusercontent.com/randomstring0/fe-source/refs/heads/main/NPC/source/main.Luau" },
	{ Name = "控制东西", Link = "https://pastebin.com/raw/VVWcfs9t" },
	{ Name = "OldMSPaint", Link = "https://raw.githubusercontent.com/notpoiu/mspaint/main/main.lua" },
	{ Name = "Doors扫描器", Link = OLD_BASE .. "/modules/games/DoorsNVC3000.lua" },
	{ Name = "玩家控制", Link = OLD_BASE .. "/modules/utility/PlayerControl.lua" },
	{ Name = "动画中心", Link = "https://raw.githubusercontent.com/GamingScripter/Animation-Hub/main/Animation%20Gui" },
	{ Name = "阿尔宙斯", Link = "https://raw.githubusercontent.com/AZYsGithub/chillz-workshop/main/Arceus%20X%20V3" },
	{ Name = "自瞄", Link = OLD_BASE .. "/modules/combat/Aimbot.lua" },
	{ Name = "ESP", Link = OLD_BASE .. "/modules/visual/ESP.lua" },
}

function M.Init(Tabs, ctx)
	local WindUI = ctx.WindUI

	for _, info in ipairs(ScriptList) do
		Tabs.ScriptHub:Button({
			Title = info.Name,
			Icon = "download",
			Callback = function()
				WindUI:Notify({ Title = "提示", Content = info.Name .. "正在启动，请耐心等待", Duration = 5 })
				local ok, src = pcall(function()
					return Utils.HttpGetWithRetry(info.Link, 2)
				end)
				if ok and src and src ~= "" then
					local fn, err = loadstring(src)
					if fn then
						local runOk, runErr = pcall(fn)
						if runOk then
							WindUI:Notify({ Title = "提示", Content = info.Name .. "启动成功", Duration = 5 })
						else
							WindUI:Notify({ Title = "提示", Content = info.Name .. "运行失败", Duration = 5 })
						end
					else
						WindUI:Notify({ Title = "提示", Content = info.Name .. "解析失败", Duration = 5 })
					end
				else
					WindUI:Notify({ Title = "提示", Content = info.Name .. "下载失败", Duration = 5 })
				end
			end,
		})
	end
end

return M
