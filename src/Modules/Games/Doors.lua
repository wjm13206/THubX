local Services = require("../../Core/Services")
local Unload = require("../../Core/Unload")

local Doors = {}
Doors.Title = "Doors扫描仪"

local Players = Services.Players
local player = Players.LocalPlayer
local fps = 120
local scanner = nil

local function giveScanner()
	if scanner and scanner.Parent then
		return true
	end
	_G.scanner_fps = fps
	local ok, result = pcall(function()
		return game:GetObjects("rbxassetid://12594482248")[1]
	end)
	if not ok or not result then
		return false
	end
	scanner = result
	scanner.Parent = player.Backpack
	local screenUI = scanner:FindFirstChild("Storage", true)
	if screenUI then
		screenUI = screenUI:FindFirstChild("ScreenUI", true)
	end
	return true
end

local function removeScanner()
	if scanner then
		pcall(function()
			scanner:Destroy()
		end)
		scanner = nil
	end
	for _, container in pairs({ player.Backpack, player.Character }) do
		if container then
			for _, item in pairs(container:GetChildren()) do
				if item.Name == "Scanner" and item:IsA("Tool") then
					pcall(function()
						item:Destroy()
					end)
				end
			end
		end
	end
end

Unload.OnUnload(function()
	removeScanner()
end)

function Doors.Init(Tabs, ctx)
	local WindUI = ctx.WindUI
	local section = Tabs.Games:Section({ Title = "Doors" })
	section:Slider({
		Title = "扫描仪帧率",
		Icon = "gauge",
		Step = 1,
		Value = { Min = 30, Max = 240, Default = 120 },
		Callback = function(v)
			fps = v
		end,
	})
	section:Button({
		Title = "获取扫描仪",
		Icon = "scan-line",
		Callback = function()
			if giveScanner() then
				WindUI:Notify({ Title = "Doors", Content = "扫描仪已发放到背包", Duration = 3 })
			else
				WindUI:Notify({ Title = "Doors", Content = "获取失败，请检查网络", Duration = 3 })
			end
		end,
	})
	section:Button({
		Title = "移除扫描仪",
		Icon = "trash-2",
		Callback = function()
			removeScanner()
		end,
	})
end

return Doors
