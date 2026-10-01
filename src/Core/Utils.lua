local Services = require("./Services")

local Utils = {}

function Utils.EnsureSingleRun(flag: string): boolean
	if (_G as any)[flag] then
		warn("[THubX] 已经加载了，请不要重复执行。")
		return false
	end
	if (_G as any).THubXLoading then
		warn("[THubX] 正在加载中，请勿频繁执行。")
		return false
	end
	(_G as any).THubXLoading = true
	return true
end

function Utils.Info(msg: string)
	pcall(function()
		Services.LogService:Info("[THubX] " .. msg)
	end)
end

function Utils.NotifyFallback(title: string, text: string)
	pcall(function()
		Services.StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 5,
		})
	end)
end

function Utils.HttpGetWithRetry(url: string, retries: number?): string
	local left = retries or 3
	local lastErr = ""
	for i = 1, left do
		local ok, res = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(res) == "string" and #res > 0 then
			return res
		else
			lastErr = tostring(res)
			task.wait(1)
		end
	end
	error("[THubX] HttpGet 失败: " .. url .. " " .. lastErr)
end

return Utils
