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
Utils.Info("开始初始化 v" .. Config.Version)

local WindowLoader = require("./UI/Window")
local ok, WindUI, Window, Tabs = pcall(WindowLoader.Create)
if not ok then
	Utils.NotifyFallback("THubX", "WindUI 加载失败，请重试")
	;(_G as any).THubXLoading = false
	error(tostring(WindUI))
end

local Registry = require("./Modules/Registry")
local ctx = {
	WindUI = WindUI,
	Window = Window,
	Config = Config,
	Services = Services,
	Utils = Utils,
}
for _, mod in Registry do
	local okMod, err = pcall(function()
		(mod :: any).Init(Tabs, ctx)
	end)
	if not okMod then
		warn("[THubX] 模块注册失败: " .. tostring((mod :: any).Title) .. " " .. tostring(err))
	end
	task.wait()
end

local cost = string.format("%.2f", tick() - startTime)
WindUI:Notify({
	Title = "THubX",
	Content = "启动成功，用时 " .. cost .. "s",
	Duration = 5,
})
Utils.Info("加载成功，用时 " .. cost .. "s")
;(_G as any).THubXLoaded = true
;(_G as any).THubXLoading = false
