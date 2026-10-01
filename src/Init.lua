if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Config = require("./Core/Config")
local Services = require("./Core/Services")
local Utils = require("./Core/Utils")

if not Utils.EnsureSingleRun("THubXLoaded") then
	return
end

local startTime = tick()
Utils.Info("开始初始化")

local WindowLoader = require("./UI/Window")
local ok, WindUI, Window, Tabs = pcall(WindowLoader.Create)
if not ok then
	Utils.NotifyFallback("THubX", "WindUI 加载失败，请重试")
	_G.THubXLoading = false
	error(tostring(WindUI))
end
if (not Window) or (not Tabs) then
	Utils.NotifyFallback("THubX", "WindUI window is nil")
	_G.THubXLoading = false
	error("WindUI window is nil")
end

local Registry = require("./Modules/Registry")
local ctx = {
	WindUI = WindUI,
	Window = Window,
	Config = Config,
	Services = Services,
	Utils = Utils,
}
local failed = {}
for _, item in Registry do
	local okLoad, mod = pcall(item.Load)
	if not okLoad then
		table.insert(failed, item.Name)
		warn("[THubX] 模块加载失败: " .. item.Name .. " " .. tostring(mod))
	else
		if type(mod) ~= "table" or type(mod.Init) ~= "function" then
			table.insert(failed, item.Name)
			warn("[THubX] 模块无效: " .. item.Name .. " (" .. type(mod) .. ")")
		else
			local okMod, err = pcall(function()
				mod.Init(Tabs, ctx)
			end)
			if not okMod then
				table.insert(failed, item.Name)
				warn("[THubX] 模块注册失败: " .. item.Name .. " " .. tostring(err))
			end
		end
	end
	task.wait()
end

-- WindUI: default select first tab
pcall(function()
	if Tabs and Tabs.Movement and Tabs.Movement.Select then
		Tabs.Movement:Select()
	end
end)

local cost = string.format("%.2f", tick() - startTime)
if #failed > 0 then
	WindUI:Notify({
		Title = "THubX",
		Content = "启动完成，用时" .. cost .. "s！" .. #failed .. " 个模块失败" .. table.concat(failed, ","),
		Duration = 10,
	})
else
	WindUI:Notify({
		Title = "THubX",
		Content = "启动成功，用时" .. cost .. "s",
		Duration = 5,
	})
end
Utils.Info("加载成功，用时" .. cost .. "s")
_G.THubXLoaded = true
_G.THubXLoading = false
