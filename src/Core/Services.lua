local cloneref = cloneref or clonereference or function(obj)
	return obj
end

local function Get(name)
	return cloneref(game:GetService(name))
end

return {
	cloneref = cloneref,
	Get = Get,
	Players = Get("Players"),
	RunService = Get("RunService"),
	UserInputService = Get("UserInputService"),
	TweenService = Get("TweenService"),
	HttpService = Get("HttpService"),
	CoreGui = Get("CoreGui"),
	StarterGui = Get("StarterGui"),
	LogService = Get("LogService"),
}
