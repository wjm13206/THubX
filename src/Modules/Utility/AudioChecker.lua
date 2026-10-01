local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "音频检查"

local SoundService = Services.Get("SoundService")
local RunService = Services.RunService
local MarketplaceService = Services.MarketplaceService

local threshold = 30
local scanning = false
local scanConn = nil
local lastScan = 0
local lastResults = {}
local selectedId = nil
local testSound = nil
local endedConn = nil
local isTesting = false
local WindUIRef = nil

local function extractId(soundId)
	if type(soundId) ~= "string" then
		return nil
	end
	return string.match(soundId, "rbxassetid://(%d+)")
end

local function stopTest()
	if testSound then
		pcall(function()
			testSound:Stop()
		end)
	end
	isTesting = false
end

local function doScan(notify)
	local found = {}
	for _, inst in ipairs(game:GetDescendants()) do
		if inst:IsA("Sound") then
			local ok, playing, loudness = pcall(function()
				return inst.IsPlaying, inst.PlaybackLoudness
			end)
			if ok and playing and loudness > threshold then
				table.insert(found, {
					Id = extractId(inst.SoundId) or inst.SoundId,
					Name = inst.Name,
					Loudness = loudness,
					From = inst.Parent and inst.Parent.Name or "?",
				})
			end
		end
	end
	lastResults = found
	if notify and WindUIRef then
		if #found == 0 then
			WindUIRef:Notify({ Title = "音频检查", Content = "未检测到超过阈值的音频", Duration = 3 })
		else
			local lines = {}
			for i = 1, math.min(5, #found) do
				local r = found[i]
				table.insert(lines, string.format("ID:%s 响度:%.1f 来源:%s", tostring(r.Id), r.Loudness, r.From))
			end
			if #found > 1 then
				selectedId = tostring(found[1].Id)
			end
			WindUIRef:Notify({
				Title = "音频检查",
				Content = string.format("检测到 %d 个音频（已选中第1个）\n%s", #found, table.concat(lines, "\n")),
				Duration = 8,
			})
		end
	end
end

local function setScanning(on)
	scanning = on
	if on then
		lastScan = 0
		if scanConn then
			scanConn:Disconnect()
		end
		scanConn = RunService.Heartbeat:Connect(function()
			if not scanning then
				return
			end
			local now = tick()
			if now - lastScan < 1 then
				return
			end
			lastScan = now
			doScan(false)
		end)
	else
		if scanConn then
			scanConn:Disconnect()
			scanConn = nil
		end
	end
end

Unload.OnUnload(function()
	setScanning(false)
	stopTest()
	if endedConn then
		endedConn:Disconnect()
		endedConn = nil
	end
	if testSound then
		pcall(function()
			testSound:Destroy()
		end)
		testSound = nil
	end
end)

function M.Init(Tabs, ctx)
	WindUIRef = ctx.WindUI
	testSound = Instance.new("Sound")
	testSound.Name = "THubXAudioTest"
	testSound.Volume = 0.5
	testSound.Parent = SoundService

	local section = Tabs.Audio:Section({ Title = "音频检查器" })
	section:Input({
		Title = "响度阈值",
		Icon = "volume-2",
		Value = "30",
		Placeholder = "输入阈值，例如: 30",
		Callback = function(text)
			local n = tonumber(text)
			if n then
				threshold = math.clamp(n, 0, 1000)
			end
		end,
	})
	section:Toggle({
		Title = "开始检测音频",
		Icon = "radar",
		Value = false,
		Callback = function(state)
			setScanning(state)
		end,
	})
	section:Button({
		Title = "立即扫描一次",
		Icon = "search",
		Callback = function()
			doScan(true)
		end,
	})
	section:Input({
		Title = "测试播放 ID",
		Icon = "music",
		Value = "",
		Placeholder = "输入 rbxassetid 数字",
		Callback = function(text)
			if text and text ~= "" then
				selectedId = string.match(text, "(%d+)") or text
			end
		end,
	})
	section:Button({
		Title = "播放 / 停止测试",
		Icon = "play",
		Callback = function()
			if isTesting then
				stopTest()
				WindUIRef:Notify({ Title = "音频检查", Content = "已停止", Duration = 2 })
				return
			end
			if not selectedId or selectedId == "" then
				WindUIRef:Notify({ Title = "音频检查", Content = "请先输入要测试的 ID", Duration = 3 })
				return
			end
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(tonumber(selectedId))
			end)
			if not ok or not info then
				WindUIRef:Notify({ Title = "音频检查", Content = "无效的音频 ID", Duration = 3 })
				return
			end
			testSound.SoundId = "rbxassetid://" .. selectedId
			testSound:Play()
			isTesting = true
			if endedConn then
				endedConn:Disconnect()
			end
			endedConn = testSound.Ended:Connect(function()
				isTesting = false
			end)
			WindUIRef:Notify({ Title = "正在播放", Content = tostring(info.Name or selectedId), Duration = 3 })
		end,
	})
	section:Button({
		Title = "复制选中 ID",
		Icon = "clipboard",
		Callback = function()
			if selectedId and setclipboard then
				setclipboard(selectedId)
				WindUIRef:Notify({ Title = "音频检查", Content = "已复制: " .. selectedId, Duration = 2 })
			else
				WindUIRef:Notify({ Title = "音频检查", Content = "无可复制的 ID", Duration = 2 })
			end
		end,
	})
end

return M
