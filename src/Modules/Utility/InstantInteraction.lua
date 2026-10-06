local Unload = require("../../Core/Unload")

local M = {}
M.Title = "秒交互"

local enabled = false
local connection = nil
local originals = {}

local function enable()
	if enabled then return end
	enabled = true
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") then
			originals[v] = v.HoldDuration
			v.HoldDuration = 0
		end
	end
	connection = workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			originals[descendant] = descendant.HoldDuration
			descendant.HoldDuration = 0
		end
	end)
end

local function disable()
	if not enabled then return end
	enabled = false
	if connection then
		connection:Disconnect()
		connection = nil
	end
	for prompt, originalDuration in pairs(originals) do
		if prompt and prompt.Parent then
			prompt.HoldDuration = originalDuration
		end
	end
	table.clear(originals)
end

Unload.OnUnload(disable)

function M.Init(Tabs, ctx)

	Tabs.Interact:Toggle({
		Title = "长按交互改为秒按",
		Icon = "zap",
		Value = false,
		Callback = function(state)
			if state then
				enable()
			else
				disable()
			end
		end,
	})
end

return M
