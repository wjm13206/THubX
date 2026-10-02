local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local MusicPlayer = {}
MusicPlayer.Title = "音乐播放器"

local SoundService = Services.Get("SoundService")
local MarketplaceService = Services.MarketplaceService

-- 预设音乐 ID（移植自老项目）
local PRESETS = {
	"142376088", "1844108188", "1846368080", "5409360995", "1848354536", "1841647093",
	"1837879082", "1837768517", "9041745502", "9048375035", "1840684208",
	"118939739460633", "1846999567", "1840434670", "9046863253", "1848028342",
	"1843404009", "1845756489", "1846862303", "1841998846", "122600689240179",
	"1837101327", "125793633964645", "1846088038", "1845554017", "1838635121",
	"16190757458", "1846442964", "1839703786", "1839444520", "1838028467",
	"7028518546", "121336636707861", "87540733242308", "1838667168", "1838667680",
	"1845179120", "136598811626191", "79451196298919", "1837769001", "103086632976213",
	"120817494107898", "5410084188", "104483584177040", "7024220835", "1842976958",
	"7023635858", "1835782117", "7029024726", "7029017448", "5410085694",
	"1843471292", "7029005367", "131020134622685", "7024340270", "1836057733",
	"9047104336", "9047104411", "1843324336", "1845215540",
}

local MODES = { "normal", "single", "sequence", "random" }
local MODE_TEXT = {
	normal = "正常播放",
	single = "单曲循环",
	sequence = "顺序播放",
	random = "随机播放",
}

local CACHE_FOLDER = "THubX/music/cache"

local sound = Instance.new("Sound")
sound.Name = "THubXMusic"
sound.Volume = 0.5
sound.Looped = false
sound.Parent = SoundService

local WindUIRef = nil
local isPlay = false
local isPause = false
local playLocation = 0
local currentId = PRESETS[1]
local pendingLink = nil
local playMode = "normal"
local endedConn = nil

local function notify(title, content)
	if WindUIRef then
		pcall(function()
			WindUIRef:Notify({ Title = title, Content = content, Duration = 3 })
		end)
	end
end

-- 直链转资产（移植自老项目 ConfigModule.downloadAudio）
-- 返回码：0 成功(assetId)，1 非有效音频直链，2 下载/缓存失败，3 取资产ID失败
local function downloadAudio(url)
	if not url or url == "" then
		return 2
	end
	local lower = string.lower(url)
	local isDirect = false
	for _, ext in ipairs({ ".mp3", ".wav", ".ogg", ".flac", ".m4a", ".wma", ".aac" }) do
		if string.find(lower, ext, 1, true) then
			isDirect = true
			break
		end
	end
	if not isDirect then
		return 1
	end
	if type(isfolder) ~= "function" or type(writefile) ~= "function" or type(getcustomasset) ~= "function" then
		return 2
	end
	local okFolder = pcall(function()
		if not isfolder(CACHE_FOLDER) then
			makefolder(CACHE_FOLDER)
		end
	end)
	if not okFolder then
		return 2
	end
	local fileName = string.match(url, "/([^/]+)%?.*$") or string.match(url, "/([^/]+)$") or ("audio_" .. tostring(os.time()) .. ".mp3")
	local filePath = CACHE_FOLDER .. "/" .. fileName
	if isfile(filePath) then
		local okCache, assetId = pcall(getcustomasset, filePath)
		if okCache and assetId and assetId ~= "" then
			return 0, assetId
		end
		pcall(delfile, filePath)
	end
	local body = nil
	if type(request) == "function" then
		local okReq, res = pcall(request, { Url = url, Method = "GET" })
		if okReq and res then
			if type(res) == "table" then
				if res.Success == false then
					return 2
				end
				body = res.Body
			elseif type(res) == "string" then
				body = res
			end
		end
	else
		local okHttp, b = pcall(function()
			return game:HttpGet(url)
		end)
		if okHttp then
			body = b
		end
	end
	if not body or body == "" then
		return 2
	end
	local okSave = pcall(writefile, filePath, body)
	if not okSave then
		return 2
	end
	local okAsset, assetId = pcall(getcustomasset, filePath)
	if not okAsset or not assetId or assetId == "" then
		pcall(delfile, filePath)
		return 3
	end
	return 0, assetId
end

local function playNext()
	if playMode == "single" then
		sound:Stop()
		task.wait(0.1)
		sound.TimePosition = 0
		sound:Play()
		return true
	elseif playMode == "sequence" or playMode == "random" then
		local nextId = nil
		if playMode == "sequence" then
			local idx = table.find(PRESETS, currentId)
			if not idx or idx >= #PRESETS then
				return false
			end
			nextId = PRESETS[idx + 1]
		else
			nextId = PRESETS[1]
			if #PRESETS > 1 then
				for _ = 1, 20 do
					nextId = PRESETS[math.random(#PRESETS)]
					if nextId ~= currentId then
						break
					end
				end
			end
		end
		currentId = nextId
		sound.SoundId = "rbxassetid://" .. nextId
		local waited = 0
		while not sound.IsLoaded and waited < 5 do
			task.wait(0.1)
			waited = waited + 0.1
		end
		sound.TimePosition = 0
		sound:Play()
		isPlay = true
		isPause = false
		notify("正在播放", nextId)
		return true
	end
	return false
end

local function startPlay()
	local id = currentId
	if pendingLink then
		notify("提示", "正在读取链接内容，请稍等...")
		local code, result = downloadAudio(pendingLink)
		if code == 0 then
			id = result
			currentId = result
			pendingLink = nil
		elseif code == 1 then
			notify("播放失败", "不是一个有效的直链音频")
			return
		elseif code == 2 then
			notify("播放失败", "缓存文件失败，执行器可能不支持文件函数")
			return
		else
			notify("播放失败", "获取资产ID失败")
			return
		end
	end
	local sid = string.find(id, "rbxasset") and id or ("rbxassetid://" .. id)
	sound.SoundId = sid
	local ok, info = pcall(function()
		if string.find(id, "rbxasset") then
			return {}
		end
		return MarketplaceService:GetProductInfo(tonumber(id))
	end)
	if ok and info then
		sound.Looped = false
		sound:Play()
		sound.TimePosition = 0
		isPlay = true
		isPause = false
		notify("正在播放", (type(info) == "table" and info.Name) or id)
	else
		isPlay = false
		notify("播放失败", "无效的 rbxassetid")
	end
end

local function stopPlay()
	sound:Stop()
	isPlay = false
	isPause = false
	notify("已停止", "音乐播放已停止")
end

local function togglePause()
	if not isPlay then
		notify("无法操作", "请先播放音乐")
		return
	end
	if isPause then
		sound.TimePosition = playLocation
		sound:Play()
		isPause = false
		notify("继续播放", "音乐已恢复")
	else
		playLocation = sound.TimePosition
		sound:Stop()
		isPause = true
		notify("已暂停", "音乐已暂停")
	end
end

local function cycleMode()
	local idx = table.find(MODES, playMode) or 1
	idx = idx % #MODES + 1
	playMode = MODES[idx]
	sound.Looped = false
	notify("播放模式", MODE_TEXT[playMode])
end

local function cleanup()
	if endedConn then
		pcall(function()
			endedConn:Disconnect()
		end)
		endedConn = nil
	end
	pcall(function()
		sound:Stop()
	end)
	pcall(function()
		sound:Destroy()
	end)
	isPlay = false
	isPause = false
end

Unload.OnUnload(function()
	pcall(cleanup)
end)

function MusicPlayer.Init(Tabs, ctx)
	WindUIRef = ctx.WindUI
	local settings = ctx.FeatureSettings("音乐播放器")
	settings:Dropdown({
		Title = "预设音乐ID",
		Icon = "list",
		Values = PRESETS,
		Value = currentId,
		Callback = function(v)
			if v and v ~= "" then
				currentId = v
				pendingLink = nil
			end
		end,
	})
	Tabs.Audio:Input({
		Title = "自定义音乐ID",
		Icon = "music",
		Placeholder = "输入 rbxassetid，如 142376088",
		Callback = function(v)
			if v and v ~= "" then
				currentId = v
				pendingLink = nil
			end
		end,
	})
	Tabs.Audio:Input({
		Title = "音乐直链",
		Icon = "link",
		Placeholder = "输入音乐直链",
		Callback = function(v)
			if v and v ~= "" then
				pendingLink = v
			end
		end,
	})
	Tabs.Audio:Button({
		Title = "播放",
		Icon = "play",
		Callback = function()
			if isPlay then
				notify("提示", "正在播放中，先停止再换歌")
				return
			end
			startPlay()
		end,
	})
	Tabs.Audio:Button({
		Title = "停止",
		Icon = "square",
		Callback = function()
			stopPlay()
		end,
	})
	Tabs.Audio:Button({
		Title = "暂停 / 继续",
		Icon = "pause",
		Callback = function()
			togglePause()
		end,
	})
	Tabs.Audio:Button({
		Title = "切换播放模式",
		Icon = "repeat",
		Callback = function()
			cycleMode()
		end,
	})
	settings:Slider({
		Title = "音量",
		Icon = "volume-2",
		Step = 1,
		Value = { Min = 0, Max = 100, Default = 50 },
		Callback = function(v)
			if type(v) == "number" then
				sound.Volume = math.clamp(v / 100, 0, 1)
			end
		end,
	})
	settings:Slider({
		Title = "音高",
		Icon = "music",
		Step = 0.1,
		Value = { Min = 0.1, Max = 3, Default = 1 },
		Callback = function(v)
			if type(v) == "number" and v >= 0.1 then
				sound.Pitch = v
			end
		end,
	})
	if not endedConn then
		endedConn = sound.Ended:Connect(function()
			if not isPlay then
				return
			end
			if not playNext() then
				isPlay = false
				isPause = false
				notify("播放结束", "列表已播完")
			end
		end)
	end
end

return MusicPlayer
