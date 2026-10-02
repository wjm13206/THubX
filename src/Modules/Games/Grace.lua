local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local M = {}
M.Title = "格蕾丝"

local Players = Services.Players
local Workspace = Services.Get("Workspace")
local RunService = Services.RunService

local LocalPlayer = Players.LocalPlayer

-- 自动拉杆
local leverConn = nil
local leverCount = 0
local leverOn = false
local WindUIRef = nil

local function setAutoLever(on)
	leverOn = on
	if on then
		if leverConn then
			return
		end
		leverCount = 0
		leverConn = Workspace.DescendantAdded:Connect(function(inst)
			if not leverOn then
				return
			end
			if inst.Name == "base" and inst:IsA("BasePart") then
				local char = LocalPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					inst.CFrame = root.CFrame
					leverCount = leverCount + 1
					if leverCount >= 3 then
						leverCount = 0
						if WindUIRef then
							WindUIRef:Notify({ Title = "格蕾丝", Content = "全部拉杆已被激活，门已打开", Duration = 5 })
						end
					end
					task.wait(1)
					pcall(function()
						inst.CFrame = root.CFrame
					end)
				end
			end
		end)
	else
		if leverConn then
			leverConn:Disconnect()
			leverConn = nil
		end
	end
end

-- 删除全部实体（一次性）
local function deleteEntities()
	local guiNames = {
		"eyegui",
		"smilegui",
		"SendRush",
		"SendWorm",
		"SendSorrow",
		"Worm",
		"elkman",
	}
	local ReplicatedStorage = Services.Get("ReplicatedStorage")
	for _, name in ipairs(guiNames) do
		pcall(function()
			ReplicatedStorage[name]:Destroy()
		end)
	end
	pcall(function()
		local qn = ReplicatedStorage:FindFirstChild("QuickNotes")
		if qn then
			for _, name in ipairs({ "Eye", "Rush", "Sorrow", "elkman", "EyePrime", "SlugFish", "FakeDoor", "SleepyHead" }) do
				local child = qn:FindFirstChild(name)
				if child then
					child:Destroy()
				end
			end
		end
	end)
	pcall(function()
		local smile = LocalPlayer.PlayerGui:FindFirstChild("smilegui")
		if smile then
			smile:Destroy()
		end
	end)
end

Unload.OnUnload(function()
	setAutoLever(false)
end)

function M.Init(Tabs, ctx)
	WindUIRef = ctx.WindUI
	Tabs.Games:Toggle({
		Title = "自动拉杆",
		Icon = "anchor",
		Value = false,
		Callback = function(state)
			setAutoLever(state)
		end,
	})
	Tabs.Games:Button({
		Title = "删除全部实体",
		Icon = "trash-2",
		Callback = function()
			deleteEntities()
			WindUIRef:Notify({ Title = "格蕾丝", Content = "已删除全部实体", Duration = 3 })
		end,
	})
end

return M
