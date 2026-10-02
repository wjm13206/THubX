local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "妄想办公室"

local Workspace = Services.Get("Workspace")
local TextChatService = Services.Get("TextChatService")
local ReplicatedStorage = Services.Get("ReplicatedStorage")

local ENTITYS = {
	NormalEntity = { Name = "EN-001", Tip = "立刻躲在柜子中！" },
	NormalEntityType2 = { Name = "EN-001-02", Tip = "立刻躲在柜子中！" },
	SnakeEntity = { Name = "EN-002", Tip = "多待在柜子里一会！" },
	TrainEntity = { Name = "EN-003", Tip = "不要犹豫，立刻躲起来！" },
	LateEntity = { Name = "EN-004", Tip = "稍后躲在柜子中！" },
	ReboundingEntity = { Name = "EN-005", Tip = "把握住进柜子的时间，他会来回冲！" },
	PeaceEntity = { Name = "EN-006", Tip = "千万不要躲在柜子中！" },
	VisionEntity = { Name = "EN-007", Tip = "不要躲在墙壁后！" },
	FocusEntity = { Name = "EN-008", Tip = "躲在柜子中，记住钥匙的位置！" },
	ShadowEntity = { Name = "EN-011", Tip = "他在黑暗中，不要看他！" },
	GhostEntity = { Name = "EN-012", Tip = "注意他的规则！" },
	UnknownEntity = { Name = "EN-013", Tip = "快点输入 staycalmstayfocused" },
	ChaserEntity = { Name = "EN-015", Tip = "快跑！" },
	DelmonEntity = { Name = "EN-0??", Tip = "暂未收录该数据" },
	DoorcamperEntity = { Name = "EN-017", Tip = "多注意门后！" },
}

local warningOn = false
local warnConn = nil
local tipOthers = false
local auto013 = false
local WindUIRef = nil

local function broadcast(text)
	pcall(function()
		if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
			ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(text, "All")
		else
			TextChatService.TextChannels.RBXGeneral:SendAsync(text)
		end
	end)
end

local function detectEntity(inst)
	local info = ENTITYS[inst.Name]
	if not info and inst:IsA("Model") then
		return
	end
	if not info then
		return
	end
	if WindUIRef then
		WindUIRef:Notify({ Title = "实体警告：" .. info.Name, Content = info.Tip, Duration = 10 })
	end
	if tipOthers then
		broadcast("[THubX] " .. info.Name .. " 出现了！" .. info.Tip)
	end
	if auto013 and inst.Name == "UnknownEntity" then
		broadcast("staycalmstayfocused")
	end
end

local function setWarning(on)
	warningOn = on
	if on then
		if warnConn then
			return
		end
		warnConn = Workspace.DescendantAdded:Connect(function(inst)
			if warningOn then
				detectEntity(inst)
			end
		end)
	else
		if warnConn then
			warnConn:Disconnect()
			warnConn = nil
		end
	end
end

Unload.OnUnload(function()
	setWarning(false)
end)

function M.Init(Tabs, ctx)
	WindUIRef = ctx.WindUI
	Tabs.Games:Toggle({
		Title = "实体警告",
		Icon = "siren",
		Value = false,
		Callback = function(state)
			setWarning(state)
		end,
	})
	Tabs.Games:Toggle({
		Title = "提醒其他玩家",
		Icon = "megaphone",
		Value = false,
		Callback = function(state)
			tipOthers = state
		end,
	})
	Tabs.Games:Toggle({
		Title = "自动应对 EN-013",
		Icon = "bot",
		Value = false,
		Callback = function(state)
			auto013 = state
			if state and not warningOn then
				setWarning(true)
			end
		end,
	})
end

return M
