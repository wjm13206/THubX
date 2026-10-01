if not game:IsLoaded() then
	game.Loaded:Wait()
end

local BASE = "https://raw.githubusercontent.com/wjm13206/THubX/refs/heads/main"

return loadstring(game:HttpGet(BASE .. "/dist/THubX.lua"))()
