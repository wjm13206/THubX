local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Translator = {}
Translator.Title = "界面翻译"

local enabled = false
local connection = nil
local taskQueue = {}
local originalTexts = {}
local lastTaskTime = 0
local translatedCount = 0

local TEXT_PROPERTIES = {
	BillboardGui = "Text",
	ImageLabel = "ToolTip",
	ImageButton = "ToolTip",
	TextLabel = "Text",
	TextBox = "Text",
	TextButton = "Text",
	ViewportFrame = "Text",
}

local function containsChinese(text)
	if string.find(text, "[\226-\239][\128-\191][\128-\191]") then
		return true
	end
	if string.find(text, "[\240][\160-\191][\128-\191][\128-\191]") then
		return true
	end
	return false
end

local function shouldTranslate(text)
	if not text or type(text) ~= "string" or text == "" then
		return false
	end
	if containsChinese(text) then
		return false
	end
	return true
end

local function scanInstances(parent, depth)
	depth = depth or 0
	if depth > 50 then
		return
	end
	for _, child in ipairs(parent:GetChildren()) do
		local prop = TEXT_PROPERTIES[child.ClassName]
		if prop then
			local success, text = pcall(function()
				return child[prop]
			end)
			if success and type(text) == "string" and text ~= "" then
				if shouldTranslate(text) and not originalTexts[child] then
					table.insert(taskQueue, {
						instance = child,
						property = prop,
						originalValue = text,
					})
					originalTexts[child] = text
				end
			end
		end
		scanInstances(child, depth + 1)
	end
end

local function processTask(task)
	pcall(function()
		local url = "https://api.52vmy.cn/api/query/fanyi/youdao?msg=" .. Services.HttpService:UrlEncode(task.originalValue)
		local jsonStr = game:HttpGet(url)
		if not jsonStr or jsonStr == "" then
			return
		end
		local res = Services.HttpService:JSONDecode(jsonStr)
		if res and res.code == 200 and res.data and res.data.target then
			if task.instance and task.instance.Parent and task.instance[task.property] == task.originalValue then
				task.instance[task.property] = res.data.target
				translatedCount = translatedCount + 1
			end
		end
	end)
end

local function onHeartbeat()
	if not enabled then
		return
	end
	if #taskQueue == 0 then
		return
	end
	local now = tick()
	if now - lastTaskTime >= 0.6 then
		local task = table.remove(taskQueue, 1)
		lastTaskTime = now
		task.spawn(function()
			processTask(task)
		end)
	end
end

local function setEnabled(on)
	if on and enabled then
		return
	end
	if not on and not enabled then
		return
	end
	enabled = on
	if on then
		lastTaskTime = tick()
		translatedCount = 0
		connection = Services.RunService.Heartbeat:Connect(onHeartbeat)
		pcall(function()
			scanInstances(game)
		end)
	else
		if connection then
			connection:Disconnect()
			connection = nil
		end
		for inst, originalText in pairs(originalTexts) do
			pcall(function()
				if inst and inst.Parent then
					local prop = TEXT_PROPERTIES[inst.ClassName]
					if prop then
						inst[prop] = originalText
					end
				end
			end)
		end
		taskQueue = {}
		originalTexts = {}
	end
end

Unload.OnUnload(function()
	setEnabled(false)
end)

function Translator.Init(Tabs, ctx)
	local folder = ctx.Folder(Tabs.Data, Translator.Title, { Icon = "languages" })

	folder:Toggle({
		Title = "启用翻译",
		Icon = "languages",
		Value = false,
		Callback = function(state)
			setEnabled(state)
		end,
	})
	folder:Button({
		Title = "查看翻译状态",
		Icon = "info",
		Callback = function()
			ctx.WindUI:Notify({
				Title = "界面翻译",
				Content = "待翻译" .. #taskQueue .. " 条，已翻译" .. translatedCount .. " 条",
				Duration = 3,
			})
		end,
	})
end

return Translator
