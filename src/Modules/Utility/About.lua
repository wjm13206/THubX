local Services = require("../../Core/Services")

local M = {}
M.Title = "关于"

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer

local function getMemoryMB()
	local ok, kb = pcall(collectgarbage, "count")
	if ok and kb then
		return kb / 1024
	end
	return 0
end

local function maskMiddle(s)
	if type(s) ~= "string" or #s <= 6 then
		return tostring(s or "未知")
	end
	return string.sub(s, 1, 3) .. "****" .. string.sub(s, -3)
end

function M.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Settings, M.Title, { Icon = "info" })
	local WindUI = ctx.WindUI
	folder:Button({
		Title = "版本信息",
		Icon = "info",
		Callback = function()
			WindUI:Notify({
				Title = "关于 THubX",
				Content = "请合理使用，了解规则",
				Duration = 6,
			})
		end,
	})
	folder:Button({
		Title = "复制 HWID",
		Icon = "fingerprint",
		Callback = function()
			if gethwid then
				local ok, hwid = pcall(gethwid)
				if ok and hwid then
					if setclipboard then
						setclipboard(tostring(hwid))
					end
					WindUI:Notify({ Title = "HWID", Content = maskMiddle(tostring(hwid)), Duration = 4 })
				else
					WindUI:Notify({ Title = "HWID", Content = "获取失败", Duration = 3 })
				end
			else
				WindUI:Notify({ Title = "HWID", Content = "执行器不支持", Duration = 3 })
			end
		end,
	})
	folder:Button({
		Title = "查看状态（延迟/内存）",
		Icon = "activity",
		Callback = function()
			local ping = 0
			pcall(function()
				ping = math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5)
			end)
			WindUI:Notify({
				Title = "状态",
				Content = string.format("网络延迟: %dms\n内存占用: %.2f MB", ping, getMemoryMB()),
				Duration = 5,
			})
		end,
	})
	folder:Button({
		Title = "强制内存垃圾回收",
		Icon = "trash-2",
		Callback = function()
			collectgarbage("collect")
			WindUI:Notify({
				Title = "内存",
				Content = string.format("已回收，当前: %.2f MB", getMemoryMB()),
				Duration = 3,
			})
		end,
	})
end

return M
