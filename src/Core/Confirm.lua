-- 危险操作二次确认（WindUI Window:Dialog 教程做法）
-- 用法：Confirm.Show(ctx.Window, { Title=..., Content=..., ConfirmText=..., OnConfirm=function() ... end })
local Confirm = {}

function Confirm.Show(Window, opts)
	opts = opts or {}
	local onConfirm = opts.OnConfirm
	if type(onConfirm) ~= "function" then
		return false
	end

	local ok, dialog = pcall(function()
		return Window:Dialog({
			Icon = opts.Icon or "triangle-alert",
			Title = opts.Title or "确认操作",
			Content = opts.Content or "确定要继续吗？",
			Buttons = {
				{
					Title = opts.ConfirmText or "确认",
					Callback = function()
						pcall(onConfirm)
					end,
				},
				{
					Title = opts.CancelText or "取消",
					Callback = function() end,
				},
			},
		})
	end)
	if ok and dialog then
		pcall(function()
			dialog:Show()
		end)
		return true
	end

	-- 旧版 WindUI 没有 Dialog 时直接执行，保证功能不中断
	pcall(onConfirm)
	return false
end

return Confirm
