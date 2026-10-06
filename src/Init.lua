if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Config = require("./Core/Config")
local Services = require("./Core/Services")
local Utils = require("./Core/Utils")
local Unload = require("./Core/Unload")
local ConfigStore = require("./Core/ConfigStore")

if not Utils.EnsureSingleRun("THubXLoaded") then
	return
end

local startTime = tick()
Utils.Info("开始初始化")

-- 加载超时保护：60 秒还没走完则放行重复执行并通知
local loadDone = false
task.spawn(function()
	task.wait(60)
	if not loadDone then
		_G.THubXLoading = false
		Utils.NotifyFallback("THubX", "加载超时，请重试")
		Utils.Info("加载超时，请重试")
	end
end)

local WindowLoader = require("./UI/Window")
local ok, WindUI, Window, Tabs = pcall(WindowLoader.Create)
if not ok then
	Utils.NotifyFallback("THubX", "WindUI 加载失败，请重试")
	_G.THubXLoading = false
	loadDone = true
	error(tostring(WindUI))
end
if (not Window) or (not Tabs) then
	Utils.NotifyFallback("THubX", "WindUI window is nil")
	_G.THubXLoading = false
	loadDone = true
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


local settingsSections = {}
ctx.FeatureSettings = function(title)
	if settingsSections[title] then
		return settingsSections[title]
	end
	local host = Tabs.FeatureSettings or Tabs.Settings
	local sec = host:Section({ Title = title })
	settingsSections[title] = sec
	return sec
end
-- 卸载时静默自动保存本游戏界面设置（执行器不支持文件时跳过）
Unload.OnUnload(function()
	ConfigStore.Save()
end)

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

-- 模块全部注册完后，应用本游戏已保存的界面设置
pcall(function()
	ConfigStore.Load()
end)

-- WindUI: default select first tab
pcall(function()
	if Tabs and Tabs.Movement and Tabs.Movement.Select then
		Tabs.Movement:Select()
	end
end)

local cost = string.format("%.2f", tick() - startTime)
loadDone = true
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
