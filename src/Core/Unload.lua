local UnloadCallbacks = {}

local Unload = {}

function Unload.OnUnload(fn)
	table.insert(UnloadCallbacks, fn)
end

function Unload.Run()
	for i = #UnloadCallbacks, 1, -1 do
		pcall(UnloadCallbacks[i])
	end
	table.clear(UnloadCallbacks)
	_G.THUbXLoaded = false
	_G.THUbXLoading = false
end

return Unload
