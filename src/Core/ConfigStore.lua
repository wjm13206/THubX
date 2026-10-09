-- 当前设置（WindUI ConfigManager 教程做法）：按游戏隔离，静默自动保存
-- 设置文件存于执行器 Workspace/WindUI/THubX/config/Game_<PlaceId>.json
-- 用法：
--   ConfigStore.Setup(Window)      -- 建窗口后调用一次，创建本游戏配置
--   ConfigStore.WrapTabs(Tabs)     -- 模块加载前调用，给无 Flag 的元素自动注入唯一 Flag
--   ConfigStore.WrapObject(folder, prefix) -- 给后建 Folder（含子 Folder）补 Flag
--   ConfigStore.Load()             -- 模块加载完后调用，应用已保存的值
local ConfigStore = {}

local current = nil
local gameKey = nil

-- 参与保存的六种元素（与 ConfigManager.Parser 对应）
local STATE_METHODS = {
	Toggle = true,
	Slider = true,
	Dropdown = true,
	Keybind = true,
	Input = true,
	Colorpicker = true,
}

local counters = {}
local wrapped = setmetatable({}, { __mode = "k" })

function ConfigStore.GameKey()
	if gameKey then
		return gameKey
	end
	local id = 0
	pcall(function()
		id = game.PlaceId or 0
	end)
	gameKey = "Game_" .. tostring(id)
	return gameKey
end

function ConfigStore.IsAvailable()
	return current ~= nil
end

local function ensureFlag(opts, prefix)
	if type(opts) ~= "table" then
		return opts
	end
	if opts.Flag == nil then
		counters[prefix] = (counters[prefix] or 0) + 1
		opts.Flag = prefix .. "_" .. tostring(opts.Title or "opt") .. "_" .. tostring(counters[prefix])
	end
	return opts
end

-- 给 Tab/Section/Folder 的元素构造方法包一层，缺 Flag 时自动补唯一 Flag（已有 Flag 不动）
-- Folder 导航（见 API.md）：Tab 为根页面，Folder 为子目录，元素 inline 挂在返回值上。
-- 此处同时处理 Section 与 Folder，保证后建的 Folder/子 Folder 自动补 Flag。
function ConfigStore.WrapObject(obj, prefix)
	if type(obj) ~= "table" or wrapped[obj] then
		return obj
	end
	wrapped[obj] = true
	for name in pairs(STATE_METHODS) do
		local orig = obj[name]
		if type(orig) == "function" then
			obj[name] = function(self, opts)
				return orig(self, ensureFlag(opts, prefix))
			end
		end
	end
	local origSection = obj.Section
	if type(origSection) == "function" then
		obj.Section = function(self, opts)
			local sec = origSection(self, opts)
			local sub = prefix
			if type(opts) == "table" and opts.Title ~= nil then
				sub = prefix .. "_" .. tostring(opts.Title)
			end
			ConfigStore.WrapObject(sec, sub)
			return sec
		end
	end
	local origFolder = obj.Folder
	if type(origFolder) == "function" then
		obj.Folder = function(self, opts)
			local folder = origFolder(self, opts)
			local sub = prefix
			if type(opts) == "table" and opts.Title ~= nil then
				sub = prefix .. "_" .. tostring(opts.Title)
			end
			ConfigStore.WrapObject(folder, sub)
			return folder
		end
	end
	return obj
end

function ConfigStore.WrapTabs(Tabs)
	if type(Tabs) ~= "table" then
		return
	end
	for tabName, tab in pairs(Tabs) do
		if type(tab) == "table" then
			ConfigStore.WrapObject(tab, "THX_" .. tostring(tabName))
		end
	end
end

function ConfigStore.Setup(Window)
	gameKey = nil
	current = nil
	local key = ConfigStore.GameKey()
	local ok, cfg = pcall(function()
		local mgr = Window.ConfigManager
		if type(mgr) ~= "table" then
			error("no ConfigManager")
		end
		return mgr:CreateConfig(key)
	end)
	if ok and cfg then
		current = cfg
		return true
	end
	return false
end

function ConfigStore.Save()
	if not current then
		return false
	end
	local ok = pcall(function()
		current:Save()
	end)
	return ok
end

function ConfigStore.Load()
	if not current then
		return false
	end
	local ok = pcall(function()
		current:Load()
	end)
	return ok
end

function ConfigStore.Delete()
	if not current then
		return false
	end
	local ok = pcall(function()
		current:Delete()
	end)
	return ok
end

return ConfigStore
