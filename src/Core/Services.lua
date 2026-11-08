local Services = {}

local cache = {}

local function get(name)
	local cached = cache[name]
	if cached then
		return cached
	end
	local ok, svc = pcall(function()
		local raw = game:GetService(name)
		if type(cloneref) == "function" then
			local okClone, cloned = pcall(cloneref, raw)
			if okClone and cloned then
				return cloned
			end
		end
		return raw
	end)
	if ok and svc then
		cache[name] = svc
		return svc
	end
	return nil
end

Services.Players = get("Players")
Services.RunService = get("RunService")
Services.TweenService = get("TweenService")
Services.UserInputService = get("UserInputService")
Services.GuiService = get("GuiService")
Services.TextService = get("TextService")
Services.HttpService = get("HttpService")
Services.Stats = get("Stats")
Services.CoreGui = get("CoreGui")
Services.Lighting = get("Lighting")
Services.StarterGui = get("StarterGui")
Services.TeleportService = get("TeleportService")

setmetatable(Services, {
	__index = function(_, key)
		return get(key)
	end,
})

return Services
