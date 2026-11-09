--!nocheck
-- ============================================================================
-- Perfectus UI — Standalone Showcase & Example Hub (Bundled Single-File)
-- Execute this script directly in Roblox to launch the full showcase UI.
-- ============================================================================

local PerfectusUI = (function()
-- ============================================================================

local __modules = {}
local __cache = {}
local __loading = {}

local function __require(name)
    local cached = __cache[name]
    if cached ~= nil then
        return cached
    end
    if __loading[name] then
        error("[PerfectusUI] Circular require at runtime: " .. tostring(name), 2)
    end
    local loader = __modules[name]
    if not loader then
        error("[PerfectusUI] Missing module: " .. tostring(name), 2)
    end
    __loading[name] = true
    local ok, result = xpcall(loader, function(err)
        return debug.traceback("[PerfectusUI:" .. tostring(name) .. "] " .. tostring(err), 2)
    end, __require)
    __loading[name] = nil
    if not ok then
        error(result, 0)
    end
    __cache[name] = if result == nil then true else result
    return result
end

-- [[ Module: Core/Services ]]
__modules["Core/Services"] = function(require)
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
end

-- [[ Module: Core/Env ]]
__modules["Core/Env"] = function(require)
local Services = require("Core/Services")

local Env = {}

local uis = Services.UserInputService
Env.IsMobile = uis ~= nil and uis.TouchEnabled and not uis.KeyboardEnabled

function Env.getGlobalEnv()
	if type(getgenv) == "function" then
		local ok, g = pcall(getgenv)
		if ok and type(g) == "table" then
			return g
		end
	end
	return _G
end

function Env.restoreIdentity()
	local set = setthreadidentity or setidentity or (type(syn) == "table" and syn.set_thread_identity)
	if type(set) == "function" then
		pcall(set, 8)
	end
end

function Env.mountGui(screenGui)
	Env.restoreIdentity()
	if type(syn) == "table" and type(syn.protect_gui) == "function" then
		pcall(syn.protect_gui, screenGui)
	elseif type(protect_gui) == "function" then
		pcall(protect_gui, screenGui)
	elseif type(protectgui) == "function" then
		pcall(protectgui, screenGui)
	end

	local targets = {}
	if type(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and typeof(hui) == "Instance" then
			targets[#targets + 1] = hui
		end
	end
	if Services.CoreGui then
		targets[#targets + 1] = Services.CoreGui
	end
	local lp = Services.Players and Services.Players.LocalPlayer
	if lp then
		local okPg, pg = pcall(function()
			return lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 2)
		end)
		if okPg and pg then
			targets[#targets + 1] = pg
		end
	end

	for _, parent in ipairs(targets) do
		local ok = pcall(function()
			screenGui.Parent = parent
		end)
		if ok and screenGui.Parent == parent then
			return parent
		end
	end
	return nil
end

Env.HasFileSystem = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"

function Env.ensureFolder(path)
	if not path or path == "" then
		return false
	end
	if type(makefolder) ~= "function" or type(isfolder) ~= "function" then
		return false
	end
	local current = nil
	for part in tostring(path):gmatch("[^/\\]+") do
		current = current and (current .. "/" .. part) or part
		local ok, exists = pcall(isfolder, current)
		if ok and not exists then
			pcall(makefolder, current)
		end
	end
	return true
end

function Env.writeFile(path, content)
	if not Env.HasFileSystem then
		return false
	end
	local folder = tostring(path):match("^(.*)[/\\][^/\\]+$")
	if folder then
		Env.ensureFolder(folder)
	end
	local ok = pcall(writefile, path, tostring(content))
	return ok
end

function Env.readFile(path)
	if not Env.HasFileSystem then
		return nil
	end
	local okExists, exists = pcall(isfile, path)
	if not (okExists and exists) then
		return nil
	end
	local okRead, data = pcall(readfile, path)
	if okRead and type(data) == "string" then
		return data
	end
	return nil
end

function Env.deleteFile(path)
	if not Env.HasFileSystem or type(delfile) ~= "function" then
		return false
	end
	local okExists, exists = pcall(isfile, path)
	if okExists and exists then
		return (pcall(delfile, path))
	end
	return false
end

function Env.listFiles(folder)
	if not Env.HasFileSystem or type(listfiles) ~= "function" or type(isfolder) ~= "function" then
		return {}
	end
	local okFolder, exists = pcall(isfolder, folder)
	if not (okFolder and exists) then
		return {}
	end
	local okList, list = pcall(listfiles, folder)
	if okList and type(list) == "table" then
		return list
	end
	return {}
end

function Env.setClipboard(text)
	local fn = setclipboard or toclipboard or set_clipboard or (type(Clipboard) == "table" and Clipboard.set)
	if type(fn) == "function" then
		local ok = pcall(fn, tostring(text))
		return ok
	end
	return false
end

return Env
end

-- [[ Module: Theme/Themes ]]
__modules["Theme/Themes"] = function(require)
local Themes = {}

Themes.Accents = {
	Indigo = Color3.fromRGB(99, 102, 241),
	Cyan = Color3.fromRGB(56, 189, 248),
	Violet = Color3.fromRGB(168, 85, 247),
	Emerald = Color3.fromRGB(16, 185, 129),
	Rose = Color3.fromRGB(244, 63, 94),
	Amber = Color3.fromRGB(245, 158, 11),
	Blue = Color3.fromRGB(59, 130, 246),
}

Themes.AccentOrder = { "Indigo", "Cyan", "Violet", "Emerald", "Rose", "Amber", "Blue" }

Themes.Palettes = {
	Obsidian = {
		Name = "Obsidian",
		IsDark = true,
		WindowBg = Color3.fromRGB(13, 15, 22),
		SidebarBg = Color3.fromRGB(19, 22, 32),
		SidebarCardActive = Color3.fromRGB(34, 40, 58),
		SidebarCardInactive = Color3.fromRGB(19, 22, 32),
		SidebarIconActive = Color3.fromRGB(129, 140, 248),
		SidebarIconInactive = Color3.fromRGB(116, 126, 152),
		TitleBarBg = Color3.fromRGB(19, 22, 32),
		TitleText = Color3.fromRGB(244, 246, 255),
		ContentBg = Color3.fromRGB(13, 15, 22),
		SectionBg = Color3.fromRGB(19, 22, 32),
		SectionHeader = Color3.fromRGB(148, 160, 190),
		RowBg = Color3.fromRGB(25, 29, 42),
		RowHover = Color3.fromRGB(31, 36, 52),
		RowPress = Color3.fromRGB(22, 26, 38),
		ControlBg = Color3.fromRGB(32, 38, 54),
		ControlHover = Color3.fromRGB(40, 47, 66),
		ControlActive = Color3.fromRGB(50, 58, 80),
		InputBg = Color3.fromRGB(17, 20, 29),
		PopoverBg = Color3.fromRGB(22, 26, 38),
		Outline = Color3.fromRGB(38, 45, 64),
		Border = Color3.fromRGB(38, 45, 64),
		InnerStroke = Color3.fromRGB(52, 62, 88),
		Divider = Color3.fromRGB(34, 40, 56),
		Text = Color3.fromRGB(242, 245, 252),
		TextSecondary = Color3.fromRGB(148, 158, 184),
		TextMuted = Color3.fromRGB(98, 108, 134),
		ValueText = Color3.fromRGB(129, 140, 248),
		OnAccent = Color3.fromRGB(255, 255, 255),
		SwitchOff = Color3.fromRGB(40, 47, 66),
		Knob = Color3.fromRGB(255, 255, 255),
		Shadow = Color3.fromRGB(0, 0, 0),
		Success = Color3.fromRGB(16, 185, 129),
		Warning = Color3.fromRGB(245, 158, 11),
		Error = Color3.fromRGB(244, 63, 94),
		Info = Color3.fromRGB(99, 102, 241),
		TrafficClose = Color3.fromRGB(244, 63, 94),
		TrafficMin = Color3.fromRGB(245, 158, 11),
		TrafficMax = Color3.fromRGB(16, 185, 129),
	},
	Midnight = {
		Name = "Midnight",
		IsDark = true,
		WindowBg = Color3.fromRGB(9, 10, 15),
		SidebarBg = Color3.fromRGB(14, 16, 24),
		SidebarCardActive = Color3.fromRGB(28, 32, 48),
		SidebarCardInactive = Color3.fromRGB(14, 16, 24),
		SidebarIconActive = Color3.fromRGB(56, 189, 248),
		SidebarIconInactive = Color3.fromRGB(104, 114, 140),
		TitleBarBg = Color3.fromRGB(14, 16, 24),
		TitleText = Color3.fromRGB(244, 247, 255),
		ContentBg = Color3.fromRGB(9, 10, 15),
		SectionBg = Color3.fromRGB(14, 16, 24),
		SectionHeader = Color3.fromRGB(134, 146, 176),
		RowBg = Color3.fromRGB(20, 23, 34),
		RowHover = Color3.fromRGB(26, 30, 44),
		RowPress = Color3.fromRGB(18, 20, 30),
		ControlBg = Color3.fromRGB(26, 30, 44),
		ControlHover = Color3.fromRGB(34, 39, 56),
		ControlActive = Color3.fromRGB(42, 48, 68),
		InputBg = Color3.fromRGB(12, 14, 21),
		PopoverBg = Color3.fromRGB(18, 21, 32),
		Outline = Color3.fromRGB(30, 36, 52),
		Border = Color3.fromRGB(30, 36, 52),
		InnerStroke = Color3.fromRGB(44, 52, 74),
		Divider = Color3.fromRGB(26, 31, 45),
		Text = Color3.fromRGB(242, 245, 252),
		TextSecondary = Color3.fromRGB(140, 150, 176),
		TextMuted = Color3.fromRGB(90, 100, 124),
		ValueText = Color3.fromRGB(56, 189, 248),
		OnAccent = Color3.fromRGB(255, 255, 255),
		SwitchOff = Color3.fromRGB(34, 40, 56),
		Knob = Color3.fromRGB(255, 255, 255),
		Shadow = Color3.fromRGB(0, 0, 0),
		Success = Color3.fromRGB(16, 185, 129),
		Warning = Color3.fromRGB(245, 158, 11),
		Error = Color3.fromRGB(244, 63, 94),
		Info = Color3.fromRGB(56, 189, 248),
		TrafficClose = Color3.fromRGB(244, 63, 94),
		TrafficMin = Color3.fromRGB(245, 158, 11),
		TrafficMax = Color3.fromRGB(16, 185, 129),
	},
	Light = {
		Name = "Light",
		IsDark = false,
		WindowBg = Color3.fromRGB(243, 245, 250),
		SidebarBg = Color3.fromRGB(255, 255, 255),
		SidebarCardActive = Color3.fromRGB(235, 238, 252),
		SidebarCardInactive = Color3.fromRGB(255, 255, 255),
		SidebarIconActive = Color3.fromRGB(79, 70, 229),
		SidebarIconInactive = Color3.fromRGB(124, 134, 158),
		TitleBarBg = Color3.fromRGB(255, 255, 255),
		TitleText = Color3.fromRGB(20, 24, 36),
		ContentBg = Color3.fromRGB(243, 245, 250),
		SectionBg = Color3.fromRGB(255, 255, 255),
		SectionHeader = Color3.fromRGB(100, 110, 136),
		RowBg = Color3.fromRGB(247, 249, 253),
		RowHover = Color3.fromRGB(240, 243, 250),
		RowPress = Color3.fromRGB(232, 236, 246),
		ControlBg = Color3.fromRGB(232, 236, 245),
		ControlHover = Color3.fromRGB(222, 227, 238),
		ControlActive = Color3.fromRGB(210, 216, 230),
		InputBg = Color3.fromRGB(242, 244, 250),
		PopoverBg = Color3.fromRGB(255, 255, 255),
		Outline = Color3.fromRGB(218, 224, 236),
		Border = Color3.fromRGB(218, 224, 236),
		InnerStroke = Color3.fromRGB(204, 212, 228),
		Divider = Color3.fromRGB(226, 231, 242),
		Text = Color3.fromRGB(22, 26, 38),
		TextSecondary = Color3.fromRGB(96, 106, 130),
		TextMuted = Color3.fromRGB(140, 148, 170),
		ValueText = Color3.fromRGB(79, 70, 229),
		OnAccent = Color3.fromRGB(255, 255, 255),
		SwitchOff = Color3.fromRGB(212, 218, 230),
		Knob = Color3.fromRGB(255, 255, 255),
		Shadow = Color3.fromRGB(20, 26, 44),
		Success = Color3.fromRGB(16, 185, 129),
		Warning = Color3.fromRGB(234, 138, 0),
		Error = Color3.fromRGB(225, 29, 72),
		Info = Color3.fromRGB(79, 70, 229),
		TrafficClose = Color3.fromRGB(225, 29, 72),
		TrafficMin = Color3.fromRGB(245, 158, 11),
		TrafficMax = Color3.fromRGB(16, 185, 129),
	},
}

Themes.Palettes.Dark = Themes.Palettes.Obsidian
Themes.Palettes.Graphite = Themes.Palettes.Midnight
Themes.Palettes.Cream = Themes.Palettes.Light
Themes.ThemeOrder = { "Obsidian", "Midnight", "Light" }

return Themes
end

-- [[ Module: Core/Signal ]]
__modules["Core/Signal"] = function(require)
local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
	return setmetatable({
		Connected = true,
		_signal = signal,
		_fn = fn,
	}, Connection)
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false
	local list = self._signal._listeners
	for i = #list, 1, -1 do
		if list[i] == self then
			table.remove(list, i)
			break
		end
	end
end

Connection.Destroy = Connection.Disconnect

function Signal.new()
	return setmetatable({
		_listeners = {},
	}, Signal)
end

function Signal:Connect(fn)
	assert(type(fn) == "function", "Signal:Connect expects a function")
	local conn = Connection.new(self, fn)
	self._listeners[#self._listeners + 1] = conn
	return conn
end

function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		if conn then
			conn:Disconnect()
		end
		fn(...)
	end)
	return conn
end

function Signal:Fire(...)
	local snapshot = table.clone(self._listeners)
	for i = 1, #snapshot do
		local conn = snapshot[i]
		if conn.Connected then
			task.spawn(conn._fn, ...)
		end
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	self:Once(function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Destroy()
	local list = self._listeners
	self._listeners = {}
	for i = 1, #list do
		list[i].Connected = false
	end
end

return Signal
end

-- [[ Module: Core/Util ]]
__modules["Core/Util"] = function(require)
local Services = require("Core/Services")

local Util = {}

function Util.round(value, step)
	step = step or 1
	if step <= 0 then
		return value
	end
	local inv = 1 / step
	local rounded = math.floor(value * inv + 0.5) / inv
	local decimals = math.max(0, math.ceil(-math.log10(step) - 1e-9))
	if decimals > 0 then
		return tonumber(string.format("%." .. tostring(decimals) .. "f", rounded)) or rounded
	end
	return math.floor(rounded + 0.5)
end

function Util.clamp(val, min, max)
	if min and val < min then
		return min
	end
	if max and val > max then
		return max
	end
	return val
end

function Util.lerp(a, b, t)
	return a + (b - a) * t
end

function Util.lerpColor(c1, c2, t)
	return Color3.new(c1.R + (c2.R - c1.R) * t, c1.G + (c2.G - c1.G) * t, c1.B + (c2.B - c1.B) * t)
end

function Util.colorToHex(color)
	if typeof(color) ~= "Color3" then
		return "#FFFFFF"
	end
	local r = math.clamp(math.floor(color.R * 255 + 0.5), 0, 255)
	local g = math.clamp(math.floor(color.G * 255 + 0.5), 0, 255)
	local b = math.clamp(math.floor(color.B * 255 + 0.5), 0, 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

function Util.hexToColor(hex)
	if type(hex) ~= "string" then
		return nil
	end
	local cleaned = hex:gsub("^%s*#?", ""):gsub("%s*$", "")
	if #cleaned == 3 then
		local r = tonumber(cleaned:sub(1, 1) .. cleaned:sub(1, 1), 16)
		local g = tonumber(cleaned:sub(2, 2) .. cleaned:sub(2, 2), 16)
		local b = tonumber(cleaned:sub(3, 3) .. cleaned:sub(3, 3), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	elseif #cleaned == 6 then
		local r = tonumber(cleaned:sub(1, 2), 16)
		local g = tonumber(cleaned:sub(3, 4), 16)
		local b = tonumber(cleaned:sub(5, 6), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	end
	return nil
end

function Util.measureText(text, size, font, maxWidth)
	local ts = Services.TextService
	if not ts then
		return Vector2.new(#tostring(text) * (size * 0.55), size + 4)
	end
	local ok, bounds = pcall(function()
		return ts:GetTextSize(
			tostring(text or ""),
			size or 14,
			font or Enum.Font.BuilderSans,
			Vector2.new(maxWidth or 10000, 10000)
		)
	end)
	if ok and bounds then
		return bounds
	end
	return Vector2.new(#tostring(text) * (size * 0.55), size + 4)
end

function Util.fuzzyScore(query, candidate)
	query = tostring(query or ""):lower():gsub("^%s*(.-)%s*$", "%1")
	candidate = tostring(candidate or ""):lower()
	if query == "" then
		return 1
	end
	if candidate == query then
		return 1000
	end
	local plainStart = candidate:find(query, 1, true)
	if plainStart then
		return 500 - plainStart
	end
	local score = 0
	local qIdx = 1
	local qLen = #query
	local streak = 0
	for cIdx = 1, #candidate do
		if candidate:sub(cIdx, cIdx) == query:sub(qIdx, qIdx) then
			qIdx += 1
			streak += 1
			score += 10 + streak * 5 - math.min(cIdx, 30) * 0.2
			if qIdx > qLen then
				return score
			end
		else
			streak = 0
		end
	end
	return nil
end

function Util.formatKeyName(key)
	if key == nil then
		return "None"
	end
	if typeof(key) == "EnumItem" then
		key = key.Name
	end
	local name = tostring(key)
	local map = {
		RightShift = "RShift",
		LeftShift = "LShift",
		RightControl = "RCtrl",
		LeftControl = "LCtrl",
		RightAlt = "RAlt",
		LeftAlt = "LAlt",
		MouseButton1 = "MB1",
		MouseButton2 = "MB2",
		MouseButton3 = "MB3",
		Backspace = "Bksp",
		Return = "Enter",
		Escape = "Esc",
		Space = "Space",
	}
	return map[name] or name
end

local reportedErrors = {}

function Util.safeCall(scope, fn, onErrorNotify, ...)
	if type(fn) ~= "function" then
		return true
	end
	local ok, res = xpcall(fn, function(err)
		return debug.traceback(tostring(err), 2)
	end, ...)
	if not ok then
		local firstLine = tostring(res):match("^[^\n]*") or tostring(res)
		local dedupeKey = tostring(scope) .. "|" .. firstLine
		if not reportedErrors[dedupeKey] then
			reportedErrors[dedupeKey] = true
			warn(string.format("[PerfectusUI] Error in %s:\n%s", tostring(scope), tostring(res)))
			if type(onErrorNotify) == "function" then
				pcall(onErrorNotify, tostring(scope), "Stopped after an error. Details in console (F9).")
			end
		end
		return false, res
	end
	return true, res
end

function Util.debounce(waitSeconds, fn)
	local pending = false
	local lastArgs = nil
	return function(...)
		lastArgs = table.pack(...)
		if pending then
			return
		end
		pending = true
		task.delay(waitSeconds, function()
			pending = false
			local args = lastArgs
			lastArgs = nil
			if args then
				fn(table.unpack(args, 1, args.n))
			end
		end)
	end
end

return Util
end

-- [[ Module: Theme/ThemeManager ]]
__modules["Theme/ThemeManager"] = function(require)
local Services = require("Core/Services")
local Signal = require("Core/Signal")
local Util = require("Core/Util")
local Themes = require("Theme/Themes")

local ThemeManager = {
	CurrentTheme = "Obsidian",
	CurrentAccent = "Indigo",
	CustomAccentColor = nil,
	Changed = Signal.new(),
	_bindings = {}, -- inst -> { prop = token }
}

local function computeDerivedAccent(baseAccent, isDark)
	local hover = Util.lerpColor(baseAccent, Color3.new(1, 1, 1), isDark and 0.14 or 0.1)
	local press = Util.lerpColor(baseAccent, Color3.new(0, 0, 0), 0.16)
	local soft =
		Util.lerpColor(baseAccent, isDark and Color3.fromRGB(24, 24, 28) or Color3.fromRGB(245, 245, 247), 0.78)
	return hover, press, soft
end

function ThemeManager:GetPalette()
	return Themes.Palettes[self.CurrentTheme] or Themes.Palettes.Dark
end

function ThemeManager:GetAccentColor()
	if self.CustomAccentColor then
		return self.CustomAccentColor
	end
	return Themes.Accents[self.CurrentAccent] or Themes.Accents.Blue
end

function ThemeManager:Get(token)
	if typeof(token) == "Color3" then
		return token
	end
	local palette = self:GetPalette()
	local accent = self:GetAccentColor()
	if token == "Accent" then
		return accent
	elseif token == "AccentHover" or token == "AccentPress" or token == "AccentSoft" then
		local hover, press, soft = computeDerivedAccent(accent, palette.IsDark)
		if token == "AccentHover" then
			return hover
		elseif token == "AccentPress" then
			return press
		else
			return soft
		end
	end
	return palette[token] or Themes.Palettes.Dark[token] or Color3.fromRGB(255, 255, 255)
end

function ThemeManager:Bind(inst, propMap)
	if typeof(inst) ~= "Instance" or type(propMap) ~= "table" then
		return
	end
	local entry = self._bindings[inst] or {}
	for prop, token in pairs(propMap) do
		entry[prop] = token
		local color = self:Get(token)
		pcall(function()
			inst[prop] = color
		end)
	end
	self._bindings[inst] = entry
end

function ThemeManager:Unbind(inst)
	self._bindings[inst] = nil
end

function ThemeManager:_refreshAll(animate)
	local tweenService = Services.TweenService
	local info = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	for inst, propMap in pairs(self._bindings) do
		if inst.Parent == nil then
			self._bindings[inst] = nil
		else
			local goal = {}
			for prop, token in pairs(propMap) do
				goal[prop] = self:Get(token)
			end
			if animate and tweenService then
				local ok, tw = pcall(tweenService.Create, tweenService, inst, info, goal)
				if ok and tw then
					tw:Play()
				else
					for prop, val in pairs(goal) do
						pcall(function()
							inst[prop] = val
						end)
					end
				end
			else
				for prop, val in pairs(goal) do
					pcall(function()
						inst[prop] = val
					end)
				end
			end
		end
	end
	self.Changed:Fire(self.CurrentTheme, self.CurrentAccent)
end

function ThemeManager:SetTheme(name, animate)
	if type(name) == "string" and Themes.Palettes[name] then
		self.CurrentTheme = name
		self:_refreshAll(animate ~= false)
	end
end

function ThemeManager:SetAccent(accentNameOrColor, animate)
	if typeof(accentNameOrColor) == "Color3" then
		self.CustomAccentColor = accentNameOrColor
		self:_refreshAll(animate ~= false)
	elseif type(accentNameOrColor) == "string" and Themes.Accents[accentNameOrColor] then
		self.CustomAccentColor = nil
		self.CurrentAccent = accentNameOrColor
		self:_refreshAll(animate ~= false)
	end
end

function ThemeManager:RegisterTheme(name, definition)
	if type(name) ~= "string" or type(definition) ~= "table" then
		return
	end
	local base = table.clone(Themes.Palettes.Dark)
	for k, v in pairs(definition) do
		base[k] = v
	end
	base.Name = name
	Themes.Palettes[name] = base
	if not table.find(Themes.ThemeOrder, name) then
		Themes.ThemeOrder[#Themes.ThemeOrder + 1] = name
	end
end

function ThemeManager:GetThemes()
	return table.clone(Themes.ThemeOrder)
end

function ThemeManager:GetAccents()
	return table.clone(Themes.AccentOrder)
end

return ThemeManager
end

-- [[ Module: Assets/Icons ]]
__modules["Assets/Icons"] = function(require)
local Icons = {}

Icons.Map = {
	["accessibility"] = "rbxassetid://10709751939",
	["activity"] = "rbxassetid://10709752035",
	["air-vent"] = "rbxassetid://10709752131",
	["airplay"] = "rbxassetid://10709752254",
	["alarm-check"] = "rbxassetid://10709752405",
	["alarm-clock"] = "rbxassetid://10709752630",
	["alarm-clock-off"] = "rbxassetid://10709752508",
	["alarm-minus"] = "rbxassetid://10709752732",
	["alarm-plus"] = "rbxassetid://10709752825",
	["album"] = "rbxassetid://10709752906",
	["alert-circle"] = "rbxassetid://10709752996",
	["alert-octagon"] = "rbxassetid://10709753064",
	["alert-triangle"] = "rbxassetid://10709753149",
	["align-center"] = "rbxassetid://10709753570",
	["align-center-horizontal"] = "rbxassetid://10709753272",
	["align-center-vertical"] = "rbxassetid://10709753421",
	["align-end-horizontal"] = "rbxassetid://10709753692",
	["align-end-vertical"] = "rbxassetid://10709753808",
	["align-horizontal-distribute-center"] = "rbxassetid://10747779791",
	["align-horizontal-distribute-end"] = "rbxassetid://10747784534",
	["align-horizontal-distribute-start"] = "rbxassetid://10709754118",
	["align-horizontal-justify-center"] = "rbxassetid://10709754204",
	["align-horizontal-justify-end"] = "rbxassetid://10709754317",
	["align-horizontal-justify-start"] = "rbxassetid://10709754436",
	["align-horizontal-space-around"] = "rbxassetid://10709754590",
	["align-horizontal-space-between"] = "rbxassetid://10709754749",
	["align-justify"] = "rbxassetid://10709759610",
	["align-left"] = "rbxassetid://10709759764",
	["align-right"] = "rbxassetid://10709759895",
	["align-start-horizontal"] = "rbxassetid://10709760051",
	["align-start-vertical"] = "rbxassetid://10709760244",
	["align-vertical-distribute-center"] = "rbxassetid://10709760351",
	["align-vertical-distribute-end"] = "rbxassetid://10709760434",
	["align-vertical-distribute-start"] = "rbxassetid://10709760612",
	["align-vertical-justify-center"] = "rbxassetid://10709760814",
	["align-vertical-justify-end"] = "rbxassetid://10709761003",
	["align-vertical-justify-start"] = "rbxassetid://10709761176",
	["align-vertical-space-around"] = "rbxassetid://10709761324",
	["align-vertical-space-between"] = "rbxassetid://10709761434",
	["anchor"] = "rbxassetid://10709761530",
	["angry"] = "rbxassetid://10709761629",
	["annoyed"] = "rbxassetid://10709761722",
	["aperture"] = "rbxassetid://10709761813",
	["apple"] = "rbxassetid://10709761889",
	["archive"] = "rbxassetid://10709762233",
	["archive-restore"] = "rbxassetid://10709762058",
	["armchair"] = "rbxassetid://10709762327",
	["arrow-big-down"] = "rbxassetid://10747796644",
	["arrow-big-left"] = "rbxassetid://10709762574",
	["arrow-big-right"] = "rbxassetid://10709762727",
	["arrow-big-up"] = "rbxassetid://10709762879",
	["arrow-down"] = "rbxassetid://10709767827",
	["arrow-down-circle"] = "rbxassetid://10709763034",
	["arrow-down-left"] = "rbxassetid://10709767656",
	["arrow-down-right"] = "rbxassetid://10709767750",
	["arrow-left"] = "rbxassetid://10709768114",
	["arrow-left-circle"] = "rbxassetid://10709767936",
	["arrow-left-right"] = "rbxassetid://10709768019",
	["arrow-right"] = "rbxassetid://10709768347",
	["arrow-right-circle"] = "rbxassetid://10709768226",
	["arrow-up"] = "rbxassetid://10709768939",
	["arrow-up-circle"] = "rbxassetid://10709768432",
	["arrow-up-down"] = "rbxassetid://10709768538",
	["arrow-up-left"] = "rbxassetid://10709768661",
	["arrow-up-right"] = "rbxassetid://10709768787",
	["asterisk"] = "rbxassetid://10709769095",
	["at-sign"] = "rbxassetid://10709769286",
	["award"] = "rbxassetid://10709769406",
	["axe"] = "rbxassetid://10709769508",
	["axis-3d"] = "rbxassetid://10709769598",
	["baby"] = "rbxassetid://10709769732",
	["backpack"] = "rbxassetid://10709769841",
	["baggage-claim"] = "rbxassetid://10709769935",
	["banana"] = "rbxassetid://10709770005",
	["banknote"] = "rbxassetid://10709770178",
	["bar-chart"] = "rbxassetid://10709773755",
	["bar-chart-2"] = "rbxassetid://10709770317",
	["bar-chart-3"] = "rbxassetid://10709770431",
	["bar-chart-4"] = "rbxassetid://10709770560",
	["bar-chart-horizontal"] = "rbxassetid://10709773669",
	["barcode"] = "rbxassetid://10747360675",
	["baseline"] = "rbxassetid://10709773863",
	["bath"] = "rbxassetid://10709773963",
	["battery"] = "rbxassetid://10709774640",
	["battery-charging"] = "rbxassetid://10709774068",
	["battery-full"] = "rbxassetid://10709774206",
	["battery-low"] = "rbxassetid://10709774370",
	["battery-medium"] = "rbxassetid://10709774513",
	["beaker"] = "rbxassetid://10709774756",
	["bed"] = "rbxassetid://10709775036",
	["bed-double"] = "rbxassetid://10709774864",
	["bed-single"] = "rbxassetid://10709774968",
	["beer"] = "rbxassetid://10709775167",
	["bell"] = "rbxassetid://10709775704",
	["bell-minus"] = "rbxassetid://10709775241",
	["bell-off"] = "rbxassetid://10709775320",
	["bell-plus"] = "rbxassetid://10709775448",
	["bell-ring"] = "rbxassetid://10709775560",
	["bike"] = "rbxassetid://10709775894",
	["binary"] = "rbxassetid://10709776050",
	["bitcoin"] = "rbxassetid://10709776126",
	["bluetooth"] = "rbxassetid://10709776655",
	["bluetooth-connected"] = "rbxassetid://10709776240",
	["bluetooth-off"] = "rbxassetid://10709776344",
	["bluetooth-searching"] = "rbxassetid://10709776501",
	["bold"] = "rbxassetid://10747813908",
	["bomb"] = "rbxassetid://10709781460",
	["bone"] = "rbxassetid://10709781605",
	["book"] = "rbxassetid://10709781824",
	["book-open"] = "rbxassetid://10709781717",
	["bookmark"] = "rbxassetid://10709782154",
	["bookmark-minus"] = "rbxassetid://10709781919",
	["bookmark-plus"] = "rbxassetid://10709782044",
	["bot"] = "rbxassetid://10709782230",
	["box"] = "rbxassetid://10709782497",
	["box-select"] = "rbxassetid://10709782342",
	["boxes"] = "rbxassetid://10709782582",
	["briefcase"] = "rbxassetid://10709782662",
	["brush"] = "rbxassetid://10709782758",
	["bug"] = "rbxassetid://10709782845",
	["building"] = "rbxassetid://10709783051",
	["building-2"] = "rbxassetid://10709782939",
	["bus"] = "rbxassetid://10709783137",
	["cake"] = "rbxassetid://10709783217",
	["calculator"] = "rbxassetid://10709783311",
	["calendar"] = "rbxassetid://10709789505",
	["calendar-check"] = "rbxassetid://10709783474",
	["calendar-check-2"] = "rbxassetid://10709783392",
	["calendar-clock"] = "rbxassetid://10709783577",
	["calendar-days"] = "rbxassetid://10709783673",
	["calendar-heart"] = "rbxassetid://10709783835",
	["calendar-minus"] = "rbxassetid://10709783959",
	["calendar-off"] = "rbxassetid://10709788784",
	["calendar-plus"] = "rbxassetid://10709788937",
	["calendar-range"] = "rbxassetid://10709789053",
	["calendar-search"] = "rbxassetid://10709789200",
	["calendar-x"] = "rbxassetid://10709789407",
	["calendar-x-2"] = "rbxassetid://10709789329",
	["camera"] = "rbxassetid://10709789686",
	["camera-off"] = "rbxassetid://10747822677",
	["car"] = "rbxassetid://10709789810",
	["carrot"] = "rbxassetid://10709789960",
	["cast"] = "rbxassetid://10709790097",
	["charge"] = "rbxassetid://10709790202",
	["check"] = "rbxassetid://10709790644",
	["check-circle"] = "rbxassetid://10709790387",
	["check-circle-2"] = "rbxassetid://10709790298",
	["check-square"] = "rbxassetid://10709790537",
	["chef-hat"] = "rbxassetid://10709790757",
	["cherry"] = "rbxassetid://10709790875",
	["chevron-down"] = "rbxassetid://10709790948",
	["chevron-first"] = "rbxassetid://10709791015",
	["chevron-last"] = "rbxassetid://10709791130",
	["chevron-left"] = "rbxassetid://10709791281",
	["chevron-right"] = "rbxassetid://10709791437",
	["chevron-up"] = "rbxassetid://10709791523",
	["chevrons-down"] = "rbxassetid://10709796864",
	["chevrons-down-up"] = "rbxassetid://10709791632",
	["chevrons-left"] = "rbxassetid://10709797151",
	["chevrons-left-right"] = "rbxassetid://10709797006",
	["chevrons-right"] = "rbxassetid://10709797382",
	["chevrons-right-left"] = "rbxassetid://10709797274",
	["chevrons-up"] = "rbxassetid://10709797622",
	["chevrons-up-down"] = "rbxassetid://10709797508",
	["chrome"] = "rbxassetid://10709797725",
	["circle"] = "rbxassetid://10709798174",
	["circle-dot"] = "rbxassetid://10709797837",
	["circle-ellipsis"] = "rbxassetid://10709797985",
	["circle-slashed"] = "rbxassetid://10709798100",
	["citrus"] = "rbxassetid://10709798276",
	["clapperboard"] = "rbxassetid://10709798350",
	["clipboard"] = "rbxassetid://10709799288",
	["clipboard-check"] = "rbxassetid://10709798443",
	["clipboard-copy"] = "rbxassetid://10709798574",
	["clipboard-edit"] = "rbxassetid://10709798682",
	["clipboard-list"] = "rbxassetid://10709798792",
	["clipboard-signature"] = "rbxassetid://10709798890",
	["clipboard-type"] = "rbxassetid://10709798999",
	["clipboard-x"] = "rbxassetid://10709799124",
	["clock"] = "rbxassetid://10709805144",
	["clock-1"] = "rbxassetid://10709799535",
	["clock-10"] = "rbxassetid://10709799718",
	["clock-11"] = "rbxassetid://10709799818",
	["clock-12"] = "rbxassetid://10709799962",
	["clock-2"] = "rbxassetid://10709803876",
	["clock-3"] = "rbxassetid://10709803989",
	["clock-4"] = "rbxassetid://10709804164",
	["clock-5"] = "rbxassetid://10709804291",
	["clock-6"] = "rbxassetid://10709804435",
	["clock-7"] = "rbxassetid://10709804599",
	["clock-8"] = "rbxassetid://10709804784",
	["clock-9"] = "rbxassetid://10709804996",
	["cloud"] = "rbxassetid://10709806740",
	["cloud-cog"] = "rbxassetid://10709805262",
	["cloud-drizzle"] = "rbxassetid://10709805371",
	["cloud-fog"] = "rbxassetid://10709805477",
	["cloud-hail"] = "rbxassetid://10709805596",
	["cloud-lightning"] = "rbxassetid://10709805727",
	["cloud-moon"] = "rbxassetid://10709805942",
	["cloud-moon-rain"] = "rbxassetid://10709805838",
	["cloud-off"] = "rbxassetid://10709806060",
	["cloud-rain"] = "rbxassetid://10709806277",
	["cloud-rain-wind"] = "rbxassetid://10709806166",
	["cloud-snow"] = "rbxassetid://10709806374",
	["cloud-sun"] = "rbxassetid://10709806631",
	["cloud-sun-rain"] = "rbxassetid://10709806475",
	["cloudy"] = "rbxassetid://10709806859",
	["clover"] = "rbxassetid://10709806995",
	["code"] = "rbxassetid://10709810463",
	["code-2"] = "rbxassetid://10709807111",
	["codepen"] = "rbxassetid://10709810534",
	["codesandbox"] = "rbxassetid://10709810676",
	["coffee"] = "rbxassetid://10709810814",
	["cog"] = "rbxassetid://10709810948",
	["coins"] = "rbxassetid://10709811110",
	["columns"] = "rbxassetid://10709811261",
	["command"] = "rbxassetid://10709811365",
	["compass"] = "rbxassetid://10709811445",
	["component"] = "rbxassetid://10709811595",
	["concierge-bell"] = "rbxassetid://10709811706",
	["connection"] = "rbxassetid://10747361219",
	["contact"] = "rbxassetid://10709811834",
	["contrast"] = "rbxassetid://10709811939",
	["cookie"] = "rbxassetid://10709812067",
	["copy"] = "rbxassetid://10709812159",
	["copyleft"] = "rbxassetid://10709812251",
	["copyright"] = "rbxassetid://10709812311",
	["corner-down-left"] = "rbxassetid://10709812396",
	["corner-down-right"] = "rbxassetid://10709812485",
	["corner-left-down"] = "rbxassetid://10709812632",
	["corner-left-up"] = "rbxassetid://10709812784",
	["corner-right-down"] = "rbxassetid://10709812939",
	["corner-right-up"] = "rbxassetid://10709813094",
	["corner-up-left"] = "rbxassetid://10709813185",
	["corner-up-right"] = "rbxassetid://10709813281",
	["cpu"] = "rbxassetid://10709813383",
	["croissant"] = "rbxassetid://10709818125",
	["crop"] = "rbxassetid://10709818245",
	["cross"] = "rbxassetid://10709818399",
	["crosshair"] = "rbxassetid://10709818534",
	["crown"] = "rbxassetid://10709818626",
	["cup-soda"] = "rbxassetid://10709818763",
	["curly-braces"] = "rbxassetid://10709818847",
	["currency"] = "rbxassetid://10709818931",
	["database"] = "rbxassetid://10709818996",
	["delete"] = "rbxassetid://10709819059",
	["diamond"] = "rbxassetid://10709819149",
	["dice-1"] = "rbxassetid://10709819266",
	["dice-2"] = "rbxassetid://10709819361",
	["dice-3"] = "rbxassetid://10709819508",
	["dice-4"] = "rbxassetid://10709819670",
	["dice-5"] = "rbxassetid://10709819801",
	["dice-6"] = "rbxassetid://10709819896",
	["dices"] = "rbxassetid://10723343321",
	["diff"] = "rbxassetid://10723343416",
	["disc"] = "rbxassetid://10723343537",
	["divide"] = "rbxassetid://10723343805",
	["divide-circle"] = "rbxassetid://10723343636",
	["divide-square"] = "rbxassetid://10723343737",
	["dollar-sign"] = "rbxassetid://10723343958",
	["download"] = "rbxassetid://10723344270",
	["download-cloud"] = "rbxassetid://10723344088",
	["droplet"] = "rbxassetid://10723344432",
	["droplets"] = "rbxassetid://10734883356",
	["drumstick"] = "rbxassetid://10723344737",
	["edit"] = "rbxassetid://10734883598",
	["edit-2"] = "rbxassetid://10723344885",
	["edit-3"] = "rbxassetid://10723345088",
	["egg"] = "rbxassetid://10723345518",
	["egg-fried"] = "rbxassetid://10723345347",
	["electricity"] = "rbxassetid://10723345749",
	["electricity-off"] = "rbxassetid://10723345643",
	["equal"] = "rbxassetid://10723345990",
	["equal-not"] = "rbxassetid://10723345866",
	["eraser"] = "rbxassetid://10723346158",
	["euro"] = "rbxassetid://10723346372",
	["expand"] = "rbxassetid://10723346553",
	["external-link"] = "rbxassetid://10723346684",
	["eye"] = "rbxassetid://10723346959",
	["eye-off"] = "rbxassetid://10723346871",
	["factory"] = "rbxassetid://10723347051",
	["fan"] = "rbxassetid://10723354359",
	["fast-forward"] = "rbxassetid://10723354521",
	["feather"] = "rbxassetid://10723354671",
	["figma"] = "rbxassetid://10723354801",
	["file"] = "rbxassetid://10723374641",
	["file-archive"] = "rbxassetid://10723354921",
	["file-audio"] = "rbxassetid://10723355148",
	["file-audio-2"] = "rbxassetid://10723355026",
	["file-axis-3d"] = "rbxassetid://10723355272",
	["file-badge"] = "rbxassetid://10723355622",
	["file-badge-2"] = "rbxassetid://10723355451",
	["file-bar-chart"] = "rbxassetid://10723355887",
	["file-bar-chart-2"] = "rbxassetid://10723355746",
	["file-box"] = "rbxassetid://10723355989",
	["file-check"] = "rbxassetid://10723356210",
	["file-check-2"] = "rbxassetid://10723356100",
	["file-clock"] = "rbxassetid://10723356329",
	["file-code"] = "rbxassetid://10723356507",
	["file-cog"] = "rbxassetid://10723356830",
	["file-cog-2"] = "rbxassetid://10723356676",
	["file-diff"] = "rbxassetid://10723357039",
	["file-digit"] = "rbxassetid://10723357151",
	["file-down"] = "rbxassetid://10723357322",
	["file-edit"] = "rbxassetid://10723357495",
	["file-heart"] = "rbxassetid://10723357637",
	["file-image"] = "rbxassetid://10723357790",
	["file-input"] = "rbxassetid://10723357933",
	["file-json"] = "rbxassetid://10723364435",
	["file-json-2"] = "rbxassetid://10723364361",
	["file-key"] = "rbxassetid://10723364605",
	["file-key-2"] = "rbxassetid://10723364515",
	["file-line-chart"] = "rbxassetid://10723364725",
	["file-lock"] = "rbxassetid://10723364957",
	["file-lock-2"] = "rbxassetid://10723364861",
	["file-minus"] = "rbxassetid://10723365254",
	["file-minus-2"] = "rbxassetid://10723365086",
	["file-output"] = "rbxassetid://10723365457",
	["file-pie-chart"] = "rbxassetid://10723365598",
	["file-plus"] = "rbxassetid://10723365877",
	["file-plus-2"] = "rbxassetid://10723365766",
	["file-question"] = "rbxassetid://10723365987",
	["file-scan"] = "rbxassetid://10723366167",
	["file-search"] = "rbxassetid://10723366550",
	["file-search-2"] = "rbxassetid://10723366340",
	["file-signature"] = "rbxassetid://10723366741",
	["file-spreadsheet"] = "rbxassetid://10723366962",
	["file-symlink"] = "rbxassetid://10723367098",
	["file-terminal"] = "rbxassetid://10723367244",
	["file-text"] = "rbxassetid://10723367380",
	["file-type"] = "rbxassetid://10723367606",
	["file-type-2"] = "rbxassetid://10723367509",
	["file-up"] = "rbxassetid://10723367734",
	["file-video"] = "rbxassetid://10723373884",
	["file-video-2"] = "rbxassetid://10723367834",
	["file-volume"] = "rbxassetid://10723374172",
	["file-volume-2"] = "rbxassetid://10723374030",
	["file-warning"] = "rbxassetid://10723374276",
	["file-x"] = "rbxassetid://10723374544",
	["file-x-2"] = "rbxassetid://10723374378",
	["files"] = "rbxassetid://10723374759",
	["film"] = "rbxassetid://10723374981",
	["filter"] = "rbxassetid://10723375128",
	["fingerprint"] = "rbxassetid://10723375250",
	["flag"] = "rbxassetid://10723375890",
	["flag-off"] = "rbxassetid://10723375443",
	["flag-triangle-left"] = "rbxassetid://10723375608",
	["flag-triangle-right"] = "rbxassetid://10723375727",
	["flame"] = "rbxassetid://10723376114",
	["flashlight"] = "rbxassetid://10723376471",
	["flashlight-off"] = "rbxassetid://10723376365",
	["flask-conical"] = "rbxassetid://10734883986",
	["flask-round"] = "rbxassetid://10723376614",
	["flip-horizontal"] = "rbxassetid://10723376884",
	["flip-horizontal-2"] = "rbxassetid://10723376745",
	["flip-vertical"] = "rbxassetid://10723377138",
	["flip-vertical-2"] = "rbxassetid://10723377026",
	["flower"] = "rbxassetid://10747830374",
	["flower-2"] = "rbxassetid://10723377305",
	["focus"] = "rbxassetid://10723377537",
	["folder"] = "rbxassetid://10723387563",
	["folder-archive"] = "rbxassetid://10723384478",
	["folder-check"] = "rbxassetid://10723384605",
	["folder-clock"] = "rbxassetid://10723384731",
	["folder-closed"] = "rbxassetid://10723384893",
	["folder-cog"] = "rbxassetid://10723385213",
	["folder-cog-2"] = "rbxassetid://10723385036",
	["folder-down"] = "rbxassetid://10723385338",
	["folder-edit"] = "rbxassetid://10723385445",
	["folder-heart"] = "rbxassetid://10723385545",
	["folder-input"] = "rbxassetid://10723385721",
	["folder-key"] = "rbxassetid://10723385848",
	["folder-lock"] = "rbxassetid://10723386005",
	["folder-minus"] = "rbxassetid://10723386127",
	["folder-open"] = "rbxassetid://10723386277",
	["folder-output"] = "rbxassetid://10723386386",
	["folder-plus"] = "rbxassetid://10723386531",
	["folder-search"] = "rbxassetid://10723386787",
	["folder-search-2"] = "rbxassetid://10723386674",
	["folder-symlink"] = "rbxassetid://10723386930",
	["folder-tree"] = "rbxassetid://10723387085",
	["folder-up"] = "rbxassetid://10723387265",
	["folder-x"] = "rbxassetid://10723387448",
	["folders"] = "rbxassetid://10723387721",
	["form-input"] = "rbxassetid://10723387841",
	["forward"] = "rbxassetid://10723388016",
	["frame"] = "rbxassetid://10723394389",
	["framer"] = "rbxassetid://10723394565",
	["frown"] = "rbxassetid://10723394681",
	["fuel"] = "rbxassetid://10723394846",
	["function-square"] = "rbxassetid://10723395041",
	["gamepad"] = "rbxassetid://10723395457",
	["gamepad-2"] = "rbxassetid://10723395215",
	["gauge"] = "rbxassetid://10723395708",
	["gavel"] = "rbxassetid://10723395896",
	["gem"] = "rbxassetid://10723396000",
	["ghost"] = "rbxassetid://10723396107",
	["gift"] = "rbxassetid://10723396402",
	["gift-card"] = "rbxassetid://10723396225",
	["git-branch"] = "rbxassetid://10723396676",
	["git-branch-plus"] = "rbxassetid://10723396542",
	["git-commit"] = "rbxassetid://10723396812",
	["git-compare"] = "rbxassetid://10723396954",
	["git-fork"] = "rbxassetid://10723397049",
	["git-merge"] = "rbxassetid://10723397165",
	["git-pull-request"] = "rbxassetid://10723397431",
	["git-pull-request-closed"] = "rbxassetid://10723397268",
	["git-pull-request-draft"] = "rbxassetid://10734884302",
	["glass"] = "rbxassetid://10723397788",
	["glass-2"] = "rbxassetid://10723397529",
	["glass-water"] = "rbxassetid://10723397678",
	["glasses"] = "rbxassetid://10723397895",
	["globe"] = "rbxassetid://10723404337",
	["globe-2"] = "rbxassetid://10723398002",
	["grab"] = "rbxassetid://10723404472",
	["graduation-cap"] = "rbxassetid://10723404691",
	["grape"] = "rbxassetid://10723404822",
	["grid"] = "rbxassetid://10723404936",
	["grip-horizontal"] = "rbxassetid://10723405089",
	["grip-vertical"] = "rbxassetid://10723405236",
	["hammer"] = "rbxassetid://10723405360",
	["hand"] = "rbxassetid://10723405649",
	["hand-metal"] = "rbxassetid://10723405508",
	["hard-drive"] = "rbxassetid://10723405749",
	["hard-hat"] = "rbxassetid://10723405859",
	["hash"] = "rbxassetid://10723405975",
	["haze"] = "rbxassetid://10723406078",
	["headphones"] = "rbxassetid://10723406165",
	["heart"] = "rbxassetid://10723406885",
	["heart-crack"] = "rbxassetid://10723406299",
	["heart-handshake"] = "rbxassetid://10723406480",
	["heart-off"] = "rbxassetid://10723406662",
	["heart-pulse"] = "rbxassetid://10723406795",
	["help-circle"] = "rbxassetid://10723406988",
	["hexagon"] = "rbxassetid://10723407092",
	["highlighter"] = "rbxassetid://10723407192",
	["history"] = "rbxassetid://10723407335",
	["home"] = "rbxassetid://10723407389",
	["hourglass"] = "rbxassetid://10723407498",
	["ice-cream"] = "rbxassetid://10723414308",
	["image"] = "rbxassetid://10723415040",
	["image-minus"] = "rbxassetid://10723414487",
	["image-off"] = "rbxassetid://10723414677",
	["image-plus"] = "rbxassetid://10723414827",
	["import"] = "rbxassetid://10723415205",
	["inbox"] = "rbxassetid://10723415335",
	["indent"] = "rbxassetid://10723415494",
	["indian-rupee"] = "rbxassetid://10723415642",
	["infinity"] = "rbxassetid://10723415766",
	["info"] = "rbxassetid://10723415903",
	["inspect"] = "rbxassetid://10723416057",
	["italic"] = "rbxassetid://10723416195",
	["japanese-yen"] = "rbxassetid://10723416363",
	["joystick"] = "rbxassetid://10723416527",
	["key"] = "rbxassetid://10723416652",
	["keyboard"] = "rbxassetid://10723416765",
	["lamp"] = "rbxassetid://10723417513",
	["lamp-ceiling"] = "rbxassetid://10723416922",
	["lamp-desk"] = "rbxassetid://10723417016",
	["lamp-floor"] = "rbxassetid://10723417131",
	["lamp-wall-down"] = "rbxassetid://10723417240",
	["lamp-wall-up"] = "rbxassetid://10723417356",
	["landmark"] = "rbxassetid://10723417608",
	["languages"] = "rbxassetid://10723417703",
	["laptop"] = "rbxassetid://10723423881",
	["laptop-2"] = "rbxassetid://10723417797",
	["lasso"] = "rbxassetid://10723424235",
	["lasso-select"] = "rbxassetid://10723424058",
	["laugh"] = "rbxassetid://10723424372",
	["layers"] = "rbxassetid://10723424505",
	["layout"] = "rbxassetid://10723425376",
	["layout-dashboard"] = "rbxassetid://10723424646",
	["layout-grid"] = "rbxassetid://10723424838",
	["layout-list"] = "rbxassetid://10723424963",
	["layout-template"] = "rbxassetid://10723425187",
	["leaf"] = "rbxassetid://10723425539",
	["library"] = "rbxassetid://10723425615",
	["life-buoy"] = "rbxassetid://10723425685",
	["lightbulb"] = "rbxassetid://10723425852",
	["lightbulb-off"] = "rbxassetid://10723425762",
	["line-chart"] = "rbxassetid://10723426393",
	["link"] = "rbxassetid://10723426722",
	["link-2"] = "rbxassetid://10723426595",
	["link-2-off"] = "rbxassetid://10723426513",
	["list"] = "rbxassetid://10723433811",
	["list-checks"] = "rbxassetid://10734884548",
	["list-end"] = "rbxassetid://10723426886",
	["list-minus"] = "rbxassetid://10723426986",
	["list-music"] = "rbxassetid://10723427081",
	["list-ordered"] = "rbxassetid://10723427199",
	["list-plus"] = "rbxassetid://10723427334",
	["list-start"] = "rbxassetid://10723427494",
	["list-video"] = "rbxassetid://10723427619",
	["list-x"] = "rbxassetid://10723433655",
	["loader"] = "rbxassetid://10723434070",
	["loader-2"] = "rbxassetid://10723433935",
	["locate"] = "rbxassetid://10723434557",
	["locate-fixed"] = "rbxassetid://10723434236",
	["locate-off"] = "rbxassetid://10723434379",
	["lock"] = "rbxassetid://10723434711",
	["log-in"] = "rbxassetid://10723434830",
	["log-out"] = "rbxassetid://10723434906",
	["luggage"] = "rbxassetid://10723434993",
	["magnet"] = "rbxassetid://10723435069",
	["mail"] = "rbxassetid://10734885430",
	["mail-check"] = "rbxassetid://10723435182",
	["mail-minus"] = "rbxassetid://10723435261",
	["mail-open"] = "rbxassetid://10723435342",
	["mail-plus"] = "rbxassetid://10723435443",
	["mail-question"] = "rbxassetid://10723435515",
	["mail-search"] = "rbxassetid://10734884739",
	["mail-warning"] = "rbxassetid://10734885015",
	["mail-x"] = "rbxassetid://10734885247",
	["mails"] = "rbxassetid://10734885614",
	["map"] = "rbxassetid://10734886202",
	["map-pin"] = "rbxassetid://10734886004",
	["map-pin-off"] = "rbxassetid://10734885803",
	["maximize"] = "rbxassetid://10734886735",
	["maximize-2"] = "rbxassetid://10734886496",
	["medal"] = "rbxassetid://10734887072",
	["megaphone"] = "rbxassetid://10734887454",
	["megaphone-off"] = "rbxassetid://10734887311",
	["meh"] = "rbxassetid://10734887603",
	["menu"] = "rbxassetid://10734887784",
	["message-circle"] = "rbxassetid://10734888000",
	["message-square"] = "rbxassetid://10734888228",
	["mic"] = "rbxassetid://10734888864",
	["mic-2"] = "rbxassetid://10734888430",
	["mic-off"] = "rbxassetid://10734888646",
	["microscope"] = "rbxassetid://10734889106",
	["microwave"] = "rbxassetid://10734895076",
	["milestone"] = "rbxassetid://10734895310",
	["minimize"] = "rbxassetid://10734895698",
	["minimize-2"] = "rbxassetid://10734895530",
	["minus"] = "rbxassetid://10734896206",
	["minus-circle"] = "rbxassetid://10734895856",
	["minus-square"] = "rbxassetid://10734896029",
	["monitor"] = "rbxassetid://10734896881",
	["monitor-off"] = "rbxassetid://10734896360",
	["monitor-speaker"] = "rbxassetid://10734896512",
	["moon"] = "rbxassetid://10734897102",
	["more-horizontal"] = "rbxassetid://10734897250",
	["more-vertical"] = "rbxassetid://10734897387",
	["mountain"] = "rbxassetid://10734897956",
	["mountain-snow"] = "rbxassetid://10734897665",
	["mouse"] = "rbxassetid://10734898592",
	["mouse-pointer"] = "rbxassetid://10734898476",
	["mouse-pointer-2"] = "rbxassetid://10734898194",
	["mouse-pointer-click"] = "rbxassetid://10734898355",
	["move"] = "rbxassetid://10734900011",
	["move-3d"] = "rbxassetid://10734898756",
	["move-diagonal"] = "rbxassetid://10734899164",
	["move-diagonal-2"] = "rbxassetid://10734898934",
	["move-horizontal"] = "rbxassetid://10734899414",
	["move-vertical"] = "rbxassetid://10734899821",
	["music"] = "rbxassetid://10734905958",
	["music-2"] = "rbxassetid://10734900215",
	["music-3"] = "rbxassetid://10734905665",
	["music-4"] = "rbxassetid://10734905823",
	["navigation"] = "rbxassetid://10734906744",
	["navigation-2"] = "rbxassetid://10734906332",
	["navigation-2-off"] = "rbxassetid://10734906144",
	["navigation-off"] = "rbxassetid://10734906580",
	["network"] = "rbxassetid://10734906975",
	["newspaper"] = "rbxassetid://10734907168",
	["octagon"] = "rbxassetid://10734907361",
	["option"] = "rbxassetid://10734907649",
	["outdent"] = "rbxassetid://10734907933",
	["package"] = "rbxassetid://10734909540",
	["package-2"] = "rbxassetid://10734908151",
	["package-check"] = "rbxassetid://10734908384",
	["package-minus"] = "rbxassetid://10734908626",
	["package-open"] = "rbxassetid://10734908793",
	["package-plus"] = "rbxassetid://10734909016",
	["package-search"] = "rbxassetid://10734909196",
	["package-x"] = "rbxassetid://10734909375",
	["paint-bucket"] = "rbxassetid://10734909847",
	["paintbrush"] = "rbxassetid://10734910187",
	["paintbrush-2"] = "rbxassetid://10734910030",
	["palette"] = "rbxassetid://10734910430",
	["palmtree"] = "rbxassetid://10734910680",
	["paperclip"] = "rbxassetid://10734910927",
	["party-popper"] = "rbxassetid://10734918735",
	["pause"] = "rbxassetid://10734919336",
	["pause-circle"] = "rbxassetid://10735024209",
	["pause-octagon"] = "rbxassetid://10734919143",
	["pen-tool"] = "rbxassetid://10734919503",
	["pencil"] = "rbxassetid://10734919691",
	["percent"] = "rbxassetid://10734919919",
	["person-standing"] = "rbxassetid://10734920149",
	["phone"] = "rbxassetid://10734921524",
	["phone-call"] = "rbxassetid://10734920305",
	["phone-forwarded"] = "rbxassetid://10734920508",
	["phone-incoming"] = "rbxassetid://10734920694",
	["phone-missed"] = "rbxassetid://10734920845",
	["phone-off"] = "rbxassetid://10734921077",
	["phone-outgoing"] = "rbxassetid://10734921288",
	["pie-chart"] = "rbxassetid://10734921727",
	["piggy-bank"] = "rbxassetid://10734921935",
	["pin"] = "rbxassetid://10734922324",
	["pin-off"] = "rbxassetid://10734922180",
	["pipette"] = "rbxassetid://10734922497",
	["pizza"] = "rbxassetid://10734922774",
	["plane"] = "rbxassetid://10734922971",
	["play"] = "rbxassetid://10734923549",
	["play-circle"] = "rbxassetid://10734923214",
	["plus"] = "rbxassetid://10734924532",
	["plus-circle"] = "rbxassetid://10734923868",
	["plus-square"] = "rbxassetid://10734924219",
	["podcast"] = "rbxassetid://10734929553",
	["pointer"] = "rbxassetid://10734929723",
	["pound-sterling"] = "rbxassetid://10734929981",
	["power"] = "rbxassetid://10734930466",
	["power-off"] = "rbxassetid://10734930257",
	["printer"] = "rbxassetid://10734930632",
	["puzzle"] = "rbxassetid://10734930886",
	["quote"] = "rbxassetid://10734931234",
	["radio"] = "rbxassetid://10734931596",
	["radio-receiver"] = "rbxassetid://10734931402",
	["rectangle-horizontal"] = "rbxassetid://10734931777",
	["rectangle-vertical"] = "rbxassetid://10734932081",
	["recycle"] = "rbxassetid://10734932295",
	["redo"] = "rbxassetid://10734932822",
	["redo-2"] = "rbxassetid://10734932586",
	["refresh-ccw"] = "rbxassetid://10734933056",
	["refresh-cw"] = "rbxassetid://10734933222",
	["refrigerator"] = "rbxassetid://10734933465",
	["regex"] = "rbxassetid://10734933655",
	["repeat"] = "rbxassetid://10734933966",
	["repeat-1"] = "rbxassetid://10734933826",
	["reply"] = "rbxassetid://10734934252",
	["reply-all"] = "rbxassetid://10734934132",
	["rewind"] = "rbxassetid://10734934347",
	["rocket"] = "rbxassetid://10734934585",
	["rocking-chair"] = "rbxassetid://10734939942",
	["rotate-3d"] = "rbxassetid://10734940107",
	["rotate-ccw"] = "rbxassetid://10734940376",
	["rotate-cw"] = "rbxassetid://10734940654",
	["rss"] = "rbxassetid://10734940825",
	["ruler"] = "rbxassetid://10734941018",
	["russian-ruble"] = "rbxassetid://10734941199",
	["sailboat"] = "rbxassetid://10734941354",
	["save"] = "rbxassetid://10734941499",
	["scale"] = "rbxassetid://10734941912",
	["scale-3d"] = "rbxassetid://10734941739",
	["scaling"] = "rbxassetid://10734942072",
	["scan"] = "rbxassetid://10734942565",
	["scan-face"] = "rbxassetid://10734942198",
	["scan-line"] = "rbxassetid://10734942351",
	["scissors"] = "rbxassetid://10734942778",
	["screen-share"] = "rbxassetid://10734943193",
	["screen-share-off"] = "rbxassetid://10734942967",
	["scroll"] = "rbxassetid://10734943448",
	["search"] = "rbxassetid://10734943674",
	["send"] = "rbxassetid://10734943902",
	["separator-horizontal"] = "rbxassetid://10734944115",
	["separator-vertical"] = "rbxassetid://10734944326",
	["server"] = "rbxassetid://10734949856",
	["server-cog"] = "rbxassetid://10734944444",
	["server-crash"] = "rbxassetid://10734944554",
	["server-off"] = "rbxassetid://10734944668",
	["settings"] = "rbxassetid://10734950309",
	["settings-2"] = "rbxassetid://10734950020",
	["share"] = "rbxassetid://10734950813",
	["share-2"] = "rbxassetid://10734950553",
	["sheet"] = "rbxassetid://10734951038",
	["shield"] = "rbxassetid://10734951847",
	["shield-alert"] = "rbxassetid://10734951173",
	["shield-check"] = "rbxassetid://10734951367",
	["shield-close"] = "rbxassetid://10734951535",
	["shield-off"] = "rbxassetid://10734951684",
	["shirt"] = "rbxassetid://10734952036",
	["shopping-bag"] = "rbxassetid://10734952273",
	["shopping-cart"] = "rbxassetid://10734952479",
	["shovel"] = "rbxassetid://10734952773",
	["shower-head"] = "rbxassetid://10734952942",
	["shrink"] = "rbxassetid://10734953073",
	["shrub"] = "rbxassetid://10734953241",
	["shuffle"] = "rbxassetid://10734953451",
	["sidebar"] = "rbxassetid://10734954301",
	["sidebar-close"] = "rbxassetid://10734953715",
	["sidebar-open"] = "rbxassetid://10734954000",
	["sigma"] = "rbxassetid://10734954538",
	["signal"] = "rbxassetid://10734961133",
	["signal-high"] = "rbxassetid://10734954807",
	["signal-low"] = "rbxassetid://10734955080",
	["signal-medium"] = "rbxassetid://10734955336",
	["signal-zero"] = "rbxassetid://10734960878",
	["siren"] = "rbxassetid://10734961284",
	["skip-back"] = "rbxassetid://10734961526",
	["skip-forward"] = "rbxassetid://10734961809",
	["skull"] = "rbxassetid://10734962068",
	["slack"] = "rbxassetid://10734962339",
	["slash"] = "rbxassetid://10734962600",
	["slice"] = "rbxassetid://10734963024",
	["sliders"] = "rbxassetid://10734963400",
	["sliders-horizontal"] = "rbxassetid://10734963191",
	["smartphone"] = "rbxassetid://10734963940",
	["smartphone-charging"] = "rbxassetid://10734963671",
	["smile"] = "rbxassetid://10734964441",
	["smile-plus"] = "rbxassetid://10734964188",
	["snowflake"] = "rbxassetid://10734964600",
	["sofa"] = "rbxassetid://10734964852",
	["sort-asc"] = "rbxassetid://10734965115",
	["sort-desc"] = "rbxassetid://10734965287",
	["speaker"] = "rbxassetid://10734965419",
	["sprout"] = "rbxassetid://10734965572",
	["square"] = "rbxassetid://10734965702",
	["star"] = "rbxassetid://10734966248",
	["star-half"] = "rbxassetid://10734965897",
	["star-off"] = "rbxassetid://10734966097",
	["stethoscope"] = "rbxassetid://10734966384",
	["sticker"] = "rbxassetid://10734972234",
	["sticky-note"] = "rbxassetid://10734972463",
	["stop-circle"] = "rbxassetid://10734972621",
	["stretch-horizontal"] = "rbxassetid://10734972862",
	["stretch-vertical"] = "rbxassetid://10734973130",
	["strikethrough"] = "rbxassetid://10734973290",
	["subscript"] = "rbxassetid://10734973457",
	["sun"] = "rbxassetid://10734974297",
	["sun-dim"] = "rbxassetid://10734973645",
	["sun-medium"] = "rbxassetid://10734973778",
	["sun-moon"] = "rbxassetid://10734973999",
	["sun-snow"] = "rbxassetid://10734974130",
	["sunrise"] = "rbxassetid://10734974522",
	["sunset"] = "rbxassetid://10734974689",
	["superscript"] = "rbxassetid://10734974850",
	["swiss-franc"] = "rbxassetid://10734975024",
	["switch-camera"] = "rbxassetid://10734975214",
	["sword"] = "rbxassetid://10734975486",
	["swords"] = "rbxassetid://10734975692",
	["syringe"] = "rbxassetid://10734975932",
	["table"] = "rbxassetid://10734976230",
	["table-2"] = "rbxassetid://10734976097",
	["tablet"] = "rbxassetid://10734976394",
	["tag"] = "rbxassetid://10734976528",
	["tags"] = "rbxassetid://10734976739",
	["target"] = "rbxassetid://10734977012",
	["tent"] = "rbxassetid://10734981750",
	["terminal"] = "rbxassetid://10734982144",
	["terminal-square"] = "rbxassetid://10734981995",
	["text-cursor"] = "rbxassetid://10734982395",
	["text-cursor-input"] = "rbxassetid://10734982297",
	["thermometer"] = "rbxassetid://10734983134",
	["thermometer-snowflake"] = "rbxassetid://10734982571",
	["thermometer-sun"] = "rbxassetid://10734982771",
	["thumbs-down"] = "rbxassetid://10734983359",
	["thumbs-up"] = "rbxassetid://10734983629",
	["ticket"] = "rbxassetid://10734983868",
	["timer"] = "rbxassetid://10734984606",
	["timer-off"] = "rbxassetid://10734984138",
	["timer-reset"] = "rbxassetid://10734984355",
	["toggle-left"] = "rbxassetid://10734984834",
	["toggle-right"] = "rbxassetid://10734985040",
	["tornado"] = "rbxassetid://10734985247",
	["toy-brick"] = "rbxassetid://10747361919",
	["train"] = "rbxassetid://10747362105",
	["trash"] = "rbxassetid://10747362393",
	["trash-2"] = "rbxassetid://10747362241",
	["tree-deciduous"] = "rbxassetid://10747362534",
	["tree-pine"] = "rbxassetid://10747362748",
	["trees"] = "rbxassetid://10747363016",
	["trending-down"] = "rbxassetid://10747363205",
	["trending-up"] = "rbxassetid://10747363465",
	["triangle"] = "rbxassetid://10747363621",
	["trophy"] = "rbxassetid://10747363809",
	["truck"] = "rbxassetid://10747364031",
	["tv"] = "rbxassetid://10747364593",
	["tv-2"] = "rbxassetid://10747364302",
	["type"] = "rbxassetid://10747364761",
	["umbrella"] = "rbxassetid://10747364971",
	["underline"] = "rbxassetid://10747365191",
	["undo"] = "rbxassetid://10747365484",
	["undo-2"] = "rbxassetid://10747365359",
	["unlink"] = "rbxassetid://10747365771",
	["unlink-2"] = "rbxassetid://10747397871",
	["unlock"] = "rbxassetid://10747366027",
	["upload"] = "rbxassetid://10747366434",
	["upload-cloud"] = "rbxassetid://10747366266",
	["usb"] = "rbxassetid://10747366606",
	["user"] = "rbxassetid://10747373176",
	["user-check"] = "rbxassetid://10747371901",
	["user-cog"] = "rbxassetid://10747372167",
	["user-minus"] = "rbxassetid://10747372346",
	["user-plus"] = "rbxassetid://10747372702",
	["user-x"] = "rbxassetid://10747372992",
	["users"] = "rbxassetid://10747373426",
	["utensils"] = "rbxassetid://10747373821",
	["utensils-crossed"] = "rbxassetid://10747373629",
	["venetian-mask"] = "rbxassetid://10747374003",
	["verified"] = "rbxassetid://10747374131",
	["vibrate"] = "rbxassetid://10747374489",
	["vibrate-off"] = "rbxassetid://10747374269",
	["video"] = "rbxassetid://10747374938",
	["video-off"] = "rbxassetid://10747374721",
	["view"] = "rbxassetid://10747375132",
	["voicemail"] = "rbxassetid://10747375281",
	["volume"] = "rbxassetid://10747376008",
	["volume-1"] = "rbxassetid://10747375450",
	["volume-2"] = "rbxassetid://10747375679",
	["volume-x"] = "rbxassetid://10747375880",
	["wallet"] = "rbxassetid://10747376205",
	["wand"] = "rbxassetid://10747376565",
	["wand-2"] = "rbxassetid://10747376349",
	["watch"] = "rbxassetid://10747376722",
	["waves"] = "rbxassetid://10747376931",
	["webcam"] = "rbxassetid://10747381992",
	["wifi"] = "rbxassetid://10747382504",
	["wifi-off"] = "rbxassetid://10747382268",
	["wind"] = "rbxassetid://10747382750",
	["wrap-text"] = "rbxassetid://10747383065",
	["wrench"] = "rbxassetid://10747383470",
	["x"] = "rbxassetid://10747384394",
	["x-circle"] = "rbxassetid://10747383819",
	["x-octagon"] = "rbxassetid://10747384037",
	["x-square"] = "rbxassetid://10747384217",
	["zoom-in"] = "rbxassetid://10747384552",
	["zoom-out"] = "rbxassetid://10747384679",
	["player"] = "rbxassetid://10747373176",
	["config"] = "rbxassetid://10723387563",
	["close"] = "rbxassetid://10747384394",
	["cog"] = "rbxassetid://10734950309",
	["combat"] = "rbxassetid://10734975692",
	["visuals"] = "rbxassetid://10723346959",
	["error"] = "rbxassetid://10709752996",
	["teleport"] = "rbxassetid://10734886004",
	["tick"] = "rbxassetid://10709790644",
	["warning"] = "rbxassetid://10709753149",
	["success"] = "rbxassetid://10709790298",
	["gear"] = "rbxassetid://10734950309",
	["farm"] = "rbxassetid://10734965572",
	["theme"] = "rbxassetid://10734910430",
	["house"] = "rbxassetid://10723407389",
	["sparkles"] = "rbxassetid://10747376349",
	["sparkle"] = "rbxassetid://10734966248",
	["zap"] = "rbxassetid://10723345749",
	["lightning"] = "rbxassetid://10723345749",
}

function Icons.resolve(icon)
	if icon == nil or icon == "" then
		return nil
	end
	if type(icon) == "number" then
		return "rbxassetid://" .. tostring(icon)
	end
	local s = tostring(icon)
	if s:find("^rbxassetid://") or s:find("^rbxthumb://") or s:find("^http") then
		return s
	end
	if s:find("^%d+$") then
		return "rbxassetid://" .. s
	end
	local clean = s:lower():gsub("^lucide%-", ""):gsub("_", "-"):gsub("^%s*(.-)%s*$", "%1")
	return Icons.Map[clean] or Icons.Map["star"]
end

return Icons
end

-- [[ Module: Core/Maid ]]
__modules["Core/Maid"] = function(require)
local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_items = {},
		_keyed = {},
	}, Maid)
end

local function cleanOne(item)
	if item == nil then
		return
	end
	local kind = typeof(item)
	pcall(function()
		if kind == "RBXScriptConnection" then
			item:Disconnect()
		elseif kind == "thread" then
			task.cancel(item)
		elseif kind == "function" then
			item()
		elseif kind == "Instance" then
			item:Destroy()
		elseif kind == "table" then
			if type(item.Destroy) == "function" then
				item:Destroy()
			elseif type(item.Clean) == "function" then
				item:Clean()
			elseif type(item.Disconnect) == "function" then
				item:Disconnect()
			end
		end
	end)
end

function Maid:Add(item, key)
	if item == nil then
		if key ~= nil and self._keyed[key] ~= nil then
			local old = self._keyed[key]
			self._keyed[key] = nil
			cleanOne(old)
		end
		return nil
	end
	if key ~= nil then
		local old = self._keyed[key]
		if old ~= nil and old ~= item then
			cleanOne(old)
		end
		self._keyed[key] = item
		return item
	end
	self._items[#self._items + 1] = item
	return item
end

function Maid:GiveTask(item)
	return self:Add(item)
end

function Maid:Clean()
	local keyed = self._keyed
	self._keyed = {}
	for _, item in pairs(keyed) do
		cleanOne(item)
	end

	local items = self._items
	self._items = {}
	for i = #items, 1, -1 do
		cleanOne(items[i])
	end
end

Maid.Destroy = Maid.Clean

return Maid
end

-- [[ Module: Motion/Spring ]]
__modules["Motion/Spring"] = function(require)
local Services = require("Core/Services")

local Spring = {}

local active = {} -- key -> state
local connection = nil

local EPSILON = 0.0008

local function packValue(val, kind)
	if kind == "number" then
		return { val }, { 0 }
	elseif kind == "Vector2" then
		return { val.X, val.Y }, { 0, 0 }
	elseif kind == "UDim2" then
		return { val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset }, { 0, 0, 0, 0 }
	elseif kind == "UDim" then
		return { val.Scale, val.Offset }, { 0, 0 }
	elseif kind == "Color3" then
		return { val.R, val.G, val.B }, { 0, 0, 0 }
	end
	return nil, nil
end

local function unpackValue(arr, kind)
	if kind == "number" then
		return arr[1]
	elseif kind == "Vector2" then
		return Vector2.new(arr[1], arr[2])
	elseif kind == "UDim2" then
		return UDim2.new(arr[1], math.floor(arr[2] + 0.5), arr[3], math.floor(arr[4] + 0.5))
	elseif kind == "UDim" then
		return UDim.new(arr[1], math.floor(arr[2] + 0.5))
	elseif kind == "Color3" then
		return Color3.new(math.clamp(arr[1], 0, 1), math.clamp(arr[2], 0, 1), math.clamp(arr[3], 0, 1))
	end
	return arr[1]
end

local function stepAll(dt)
	dt = math.min(dt, 1 / 20)
	local hasAny = false

	for key, state in pairs(active) do
		local inst = state.inst
		if inst == nil or (typeof(inst) == "Instance" and inst.Parent == nil) then
			active[key] = nil
		else
			local f = state.frequency * 2 * math.pi
			local d = state.damping
			local pos = state.pos
			local vel = state.vel
			local target = state.target
			local settled = true

			-- Substep twice if high frequency to guarantee stability
			local steps = f > 35 and 2 or 1
			local subDt = dt / steps
			for _ = 1, steps do
				for i = 1, #pos do
					local x = pos[i] - target[i]
					local v = vel[i]
					local accel = -f * f * x - 2 * d * f * v
					v = v + accel * subDt
					x = x + v * subDt
					pos[i] = target[i] + x
					vel[i] = v
				end
			end

			for i = 1, #pos do
				local eps = (state.kind == "UDim2" and (i == 2 or i == 4)) and 0.35 or EPSILON
				if math.abs(pos[i] - target[i]) > eps or math.abs(vel[i]) > eps * 4 then
					settled = false
					break
				end
			end

			if settled then
				for i = 1, #pos do
					pos[i] = target[i]
					vel[i] = 0
				end
			end

			local value = unpackValue(pos, state.kind)
			if state.setter then
				pcall(state.setter, value)
			else
				pcall(function()
					inst[state.prop] = value
				end)
			end

			if settled then
				active[key] = nil
				if state.onComplete then
					task.spawn(state.onComplete)
				end
			else
				hasAny = true
			end
		end
	end

	if not hasAny and connection then
		connection:Disconnect()
		connection = nil
	end
end

local function ensureLoop()
	if not connection and Services.RunService then
		connection = Services.RunService.Heartbeat:Connect(stepAll)
	end
end

function Spring.target(inst, prop, goalValue, opts)
	opts = opts or {}
	local kind = typeof(goalValue)
	local targetArr = packValue(goalValue, kind)
	if not targetArr then
		pcall(function()
			inst[prop] = goalValue
		end)
		return
	end

	local key = tostring(inst) .. ":" .. tostring(prop)
	local existing = active[key]
	local freq = opts.frequency or 14
	local damp = opts.damping or 0.88

	if existing and existing.kind == kind then
		existing.target = targetArr
		existing.frequency = freq
		existing.damping = damp
		existing.onComplete = opts.onComplete
	else
		local ok, current = pcall(function()
			return inst[prop]
		end)
		if not ok or typeof(current) ~= kind then
			current = goalValue
		end
		local posArr, velArr = packValue(current, kind)
		active[key] = {
			inst = inst,
			prop = prop,
			kind = kind,
			pos = posArr,
			vel = velArr,
			target = targetArr,
			frequency = freq,
			damping = damp,
			onComplete = opts.onComplete,
		}
	end
	ensureLoop()
end

function Spring.stop(inst, prop)
	if prop then
		active[tostring(inst) .. ":" .. tostring(prop)] = nil
	else
		local prefix = tostring(inst) .. ":"
		for k in pairs(active) do
			if k:sub(1, #prefix) == prefix then
				active[k] = nil
			end
		end
	end
end

function Spring.stopAll()
	table.clear(active)
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

return Spring
end

-- [[ Module: Motion/Animator ]]
__modules["Motion/Animator"] = function(require)
local Services = require("Core/Services")
local Spring = require("Motion/Spring")

local Animator = {
	Speed = 1,
	ReducedMotion = false,
}

function Animator.tween(inst, props, duration, easingStyle, easingDirection, onComplete)
	if typeof(inst) ~= "Instance" or type(props) ~= "table" then
		return nil
	end
	local speed = math.clamp(Animator.Speed or 1, 0.25, 4)
	local d = (duration or 0.18) / speed
	if Animator.ReducedMotion or d <= 0.01 or not Services.TweenService then
		for k, v in pairs(props) do
			pcall(function()
				inst[k] = v
			end)
		end
		if onComplete then
			task.spawn(onComplete)
		end
		return nil
	end

	local info = TweenInfo.new(d, easingStyle or Enum.EasingStyle.Quint, easingDirection or Enum.EasingDirection.Out)
	local ok, tw = pcall(Services.TweenService.Create, Services.TweenService, inst, info, props)
	if ok and tw then
		if onComplete then
			tw.Completed:Once(function()
				onComplete()
			end)
		end
		tw:Play()
		return tw
	else
		for k, v in pairs(props) do
			pcall(function()
				inst[k] = v
			end)
		end
		if onComplete then
			task.spawn(onComplete)
		end
		return nil
	end
end

function Animator.spring(inst, prop, goalValue, opts)
	if typeof(inst) ~= "Instance" then
		return
	end
	if Animator.ReducedMotion then
		Spring.stop(inst, prop)
		pcall(function()
			inst[prop] = goalValue
		end)
		if opts and opts.onComplete then
			task.spawn(opts.onComplete)
		end
		return
	end
	local speed = math.clamp(Animator.Speed or 1, 0.25, 4)
	local adjusted = {
		frequency = ((opts and opts.frequency) or 14) * speed,
		damping = (opts and opts.damping) or 0.88,
		onComplete = opts and opts.onComplete,
	}
	Spring.target(inst, prop, goalValue, adjusted)
end

function Animator.pulseHighlight(rowFrame)
	if typeof(rowFrame) ~= "Instance" then
		return
	end
	local stroke = rowFrame:FindFirstChild("_PulseStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = "_PulseStroke"
		stroke.Thickness = 1.5
		stroke.Transparency = 1
		stroke.Parent = rowFrame
	end
	local ThemeManager = require("Theme/ThemeManager")
	stroke.Color = ThemeManager:Get("Accent")
	stroke.Transparency = 0.05
	Animator.tween(stroke, { Transparency = 1 }, 0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

return Animator
end

-- [[ Module: Core/Creator ]]
__modules["Core/Creator"] = function(require)
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")

local Creator = {}

local DEFAULT_RESET = {
	Frame = {
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(28, 28, 30),
	},
	CanvasGroup = {
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(28, 28, 30),
	},
	ScrollingFrame = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ScrollBarImageTransparency = 0.4,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	},
	TextLabel = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSans,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(245, 245, 247),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "",
	},
	TextButton = {
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(245, 245, 247),
		Text = "",
	},
	TextBox = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = Enum.Font.BuilderSans,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(245, 245, 247),
		PlaceholderColor3 = Color3.fromRGB(115, 115, 124),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	},
	ImageLabel = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ImageColor3 = Color3.fromRGB(245, 245, 247),
	},
	ImageButton = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		ImageColor3 = Color3.fromRGB(245, 245, 247),
	},
	UIStroke = {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Thickness = 1,
	},
}

function Creator.new(className, props, children)
	local inst = Instance.new(className)
	local defaults = DEFAULT_RESET[className]
	if defaults then
		for k, v in pairs(defaults) do
			pcall(function()
				inst[k] = v
			end)
		end
	end

	local themeBind = nil
	local parent = nil

	if type(props) == "table" then
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			elseif k == "ThemeBind" then
				themeBind = v
			elseif type(k) == "number" and typeof(v) == "Instance" then
				v.Parent = inst
			else
				inst[k] = v
			end
		end
	end

	if type(children) == "table" then
		for _, child in ipairs(children) do
			if typeof(child) == "Instance" then
				child.Parent = inst
			end
		end
	end

	if type(themeBind) == "table" then
		ThemeManager:Bind(inst, themeBind)
	end

	if parent then
		inst.Parent = parent
	end

	return inst
end

function Creator.corner(radius, parent)
	return Creator.new("UICorner", {
		CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 8),
		Parent = parent,
	})
end

function Creator.stroke(themeTokenOrColor, thickness, transparency, parent)
	local isToken = type(themeTokenOrColor) == "string"
	local bind = isToken and { Color = themeTokenOrColor } or nil
	local color = not isToken and themeTokenOrColor or ThemeManager:Get(themeTokenOrColor or "Border")
	return Creator.new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ThemeBind = bind,
		Parent = parent,
	})
end

function Creator.padding(top, right, bottom, left, parent)
	if type(top) == "number" and right == nil then
		right, bottom, left = top, top, top
	elseif type(top) == "number" and type(right) == "number" and bottom == nil then
		-- padding(vertical, horizontal)
		local v, h = top, right
		top, bottom, left, right = v, v, h, h
	end
	return Creator.new("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		Parent = parent,
	})
end

function Creator.list(padding, fillDirection, hAlign, vAlign, parent)
	return Creator.new("UIListLayout", {
		Padding = UDim.new(0, padding or 0),
		FillDirection = fillDirection or Enum.FillDirection.Vertical,
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

function Creator.bindInteractive(guiObj, opts)
	opts = opts or {}
	local hoverToken = opts.HoverToken
	local normalToken = opts.NormalToken
	local pressScale = opts.PressScale
	local scaleInst = nil
	if pressScale then
		scaleInst = guiObj:FindFirstChildOfClass("UIScale") or Creator.new("UIScale", { Scale = 1, Parent = guiObj })
	end

	guiObj.MouseEnter:Connect(function()
		if hoverToken then
			Animator.tween(guiObj, { BackgroundColor3 = ThemeManager:Get(hoverToken) }, 0.14)
		end
		if opts.OnHover then
			opts.OnHover(true)
		end
	end)

	guiObj.MouseLeave:Connect(function()
		if normalToken then
			Animator.tween(guiObj, { BackgroundColor3 = ThemeManager:Get(normalToken) }, 0.16)
		end
		if scaleInst then
			Animator.spring(scaleInst, "Scale", 1, { frequency = 16, damping = 0.85 })
		end
		if opts.OnHover then
			opts.OnHover(false)
		end
	end)

	if scaleInst then
		guiObj.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				Animator.spring(scaleInst, "Scale", pressScale, { frequency = 20, damping = 0.85 })
			end
		end)
		guiObj.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				Animator.spring(scaleInst, "Scale", 1, { frequency = 16, damping = 0.8 })
			end
		end)
	end
end

return Creator
end

-- [[ Module: Components/Shadow ]]
__modules["Components/Shadow"] = function(require)
local Creator = require("Core/Creator")

local Shadow = {}

function Shadow.create(parent, spread, transparency, zIndex)
	spread = spread or 28
	transparency = transparency or 0.42
	return Creator.new("ImageLabel", {
		Name = "DropShadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 4),
		Size = UDim2.new(1, spread * 2, 1, spread * 2),
		BackgroundTransparency = 1,
		Image = "rbxassetid://8992230677",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = transparency,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ZIndex = zIndex or math.max(0, (parent and parent.ZIndex or 1) - 1),
		ThemeBind = { ImageColor3 = "Shadow" },
		Parent = parent,
	})
end

return Shadow
end

-- [[ Module: Components/Popover ]]
__modules["Components/Popover"] = function(require)
local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Animator = require("Motion/Animator")
local Shadow = require("Components/Shadow")

local Popover = {}

local activePopover = nil
local rootContainer = nil
local scaleRef = nil
local backdropBtn = nil

function Popover.init(overlayParent, uiScaleInstance)
	rootContainer = overlayParent
	scaleRef = uiScaleInstance

	if backdropBtn then
		backdropBtn:Destroy()
	end

	backdropBtn = Creator.new("TextButton", {
		Name = "PopoverBackdrop",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Visible = false,
		ZIndex = 190,
		Modal = false,
		Parent = rootContainer,
	})

	backdropBtn.MouseButton1Down:Connect(function()
		Popover.close()
	end)
end

function Popover.isOpen()
	return activePopover ~= nil
end

function Popover.close()
	if not activePopover then
		return
	end
	local current = activePopover
	activePopover = nil
	if backdropBtn then
		backdropBtn.Visible = false
	end
	if current.onClose then
		pcall(current.onClose)
	end
	if current.frame and current.frame.Parent then
		local f = current.frame
		Animator.tween(
			f,
			{ BackgroundTransparency = 1 },
			0.12,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			function()
				if f.Parent then
					f:Destroy()
				end
			end
		)
		for _, d in ipairs(f:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
				Animator.tween(d, { TextTransparency = 1 }, 0.1)
			elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
				Animator.tween(d, { ImageTransparency = 1 }, 0.1)
			elseif d:IsA("UIStroke") then
				Animator.tween(d, { Transparency = 1 }, 0.1)
			end
		end
	end
end

function Popover.open(opts)
	opts = opts or {}
	Popover.close()

	if not rootContainer then
		return nil
	end

	local width = opts.Width or 210
	local targetHeight = opts.Height or 180
	local anchor = opts.Anchor
	local scale = (scaleRef and scaleRef.Scale and scaleRef.Scale > 0) and scaleRef.Scale or 1

	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local xPos = 200
	local yPos = 200
	local openUpward = false

	if opts.Position then
		xPos = opts.Position.X / scale
		yPos = opts.Position.Y / scale
	elseif anchor and anchor.Parent then
		local absPos = anchor.AbsolutePosition
		local absSize = anchor.AbsoluteSize
		local rootAbsPos = rootContainer.AbsolutePosition
		local relX = (absPos.X - rootAbsPos.X) / scale
		local relY = (absPos.Y - rootAbsPos.Y) / scale
		local anchorW = absSize.X / scale
		local anchorH = absSize.Y / scale
		local maxVpX = vp.X / scale
		local maxVpY = vp.Y / scale

		xPos = math.clamp(relX + anchorW - width, 8, math.max(8, maxVpX - width - 8))
		if relY + anchorH + targetHeight + 12 > maxVpY and (relY - targetHeight - 6) > 8 then
			yPos = relY - targetHeight - 6
			openUpward = true
		else
			yPos = relY + anchorH + 6
		end
	end

	if backdropBtn then
		backdropBtn.Visible = true
	end

	local card = Creator.new("Frame", {
		Name = opts.Name or "PopoverCard",
		Position = UDim2.fromOffset(math.floor(xPos), math.floor(openUpward and (yPos + 10) or math.max(8, yPos - 6))),
		Size = UDim2.fromOffset(width, targetHeight),
		BackgroundTransparency = 0,
		ClipsDescendants = false,
		ZIndex = 200,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = rootContainer,
	}, {
		Creator.corner(12),
		Creator.stroke("Outline", 1.2, 0),
	})

	Shadow.create(card, 20, 0.45, 199)

	local inner = Creator.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 201,
		Parent = card,
	}, {
		Creator.corner(10),
	})

	Animator.spring(card, "Position", UDim2.fromOffset(math.floor(xPos), math.floor(yPos)), {
		frequency = 18,
		damping = 0.86,
	})

	local handle = {
		frame = card,
		content = inner,
		onClose = opts.OnClose,
		SetHeight = function(_, newHeight)
			targetHeight = newHeight
			Animator.spring(card, "Size", UDim2.fromOffset(width, newHeight), {
				frequency = 18,
				damping = 0.88,
			})
		end,
		Close = function()
			Popover.close()
		end,
	}

	activePopover = handle
	return handle
end

Services.UserInputService.InputBegan:Connect(function(input, processed)
	if not activePopover then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape then
		Popover.close()
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local f = activePopover.frame
		if f and f.Parent then
			local pos = input.Position
			local absPos = f.AbsolutePosition
			local absSize = f.AbsoluteSize
			local inside = pos.X >= absPos.X
				and pos.X <= (absPos.X + absSize.X)
				and pos.Y >= absPos.Y
				and pos.Y <= (absPos.Y + absSize.Y)
			if not inside and not processed then
				Popover.close()
			end
		end
	end
end)

return Popover
end

-- [[ Module: Window/TitleBar ]]
__modules["Window/TitleBar"] = function(require)
local Services = require("Core/Services")
local Creator = require("Core/Creator")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Popover = require("Components/Popover")

local TitleBar = {}

function TitleBar.create(window, opts)
	opts = opts or {}

	-- Floating Top Header Island (inset 10px from top/left/right)
	local bar = Creator.new("Frame", {
		Name = "TitleBar",
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 0, 44),
		BackgroundTransparency = 0,
		Active = true,
		ZIndex = 10,
		ThemeBind = { BackgroundColor3 = "TitleBarBg" },
		Parent = window.Chrome,
	}, {
		Creator.corner(12),
		Creator.stroke("Outline", 1.2, 0),
	})

	-- Signature Gradient Brand Prism Badge ("P")
	local badge = Creator.new("Frame", {
		Name = "BrandBadge",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 12,
		Parent = bar,
	}, {
		Creator.corner(8),
		Creator.new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 189, 248)),
			}),
			Rotation = 45,
		}),
		Creator.new("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Font = Enum.Font.BuilderSansExtraBold,
			TextSize = 15,
			Text = "P",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 13,
		}),
	})

	local titleLabel = Creator.new("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 44, 0.5, 0),
		Size = UDim2.fromOffset(105, 22),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 15,
		Text = tostring(opts.Title or "Perfectus"),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 12,
		ThemeBind = { TextColor3 = "TitleText" },
		Parent = bar,
	})

	-- Subtle vertical separator + Active Tab breadcrumb pill
	local sep = Creator.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 122, 0.5, 0),
		Size = UDim2.fromOffset(1, 16),
		ZIndex = 12,
		ThemeBind = { BackgroundColor3 = "Divider" },
		Parent = bar,
	})

	local activeTabLabel = Creator.new("TextLabel", {
		Name = "ActiveTabTitle",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 134, 0.5, 0),
		Size = UDim2.fromOffset(140, 20),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 14,
		Text = "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 12,
		ThemeBind = { TextColor3 = "ValueText" },
		Parent = bar,
	})

	-- Right Cluster: Compact Inline Search Box + Theme Toggle + Minimize + Close
	local rightCluster = Creator.new("Frame", {
		Name = "RightActions",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(256, 28),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = bar,
	}, {
		Creator.list(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center),
	})

	-- Inline Search Pill
	local searchWrap = Creator.new("Frame", {
		Name = "SearchPill",
		Size = UDim2.fromOffset(152, 28),
		LayoutOrder = 1,
		ZIndex = 13,
		ThemeBind = { BackgroundColor3 = "InputBg" },
		Parent = rightCluster,
	}, {
		Creator.corner(8),
		Creator.stroke("Outline", 1, 0),
		Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(13, 13),
			Image = Icons.resolve("search") or "",
			ZIndex = 14,
			ThemeBind = { ImageColor3 = "TextMuted" },
		}),
	})

	local searchBox = Creator.new("TextBox", {
		Name = "SearchBox",
		Position = UDim2.fromOffset(26, 0),
		Size = UDim2.new(1, -32, 1, 0),
		Font = Enum.Font.BuilderSans,
		TextSize = 13,
		Text = "",
		PlaceholderText = "Search...",
		ClearTextOnFocus = false,
		ZIndex = 14,
		ThemeBind = {
			TextColor3 = "Text",
			PlaceholderColor3 = "TextMuted",
		},
		Parent = searchWrap,
	})

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		window:FilterActiveTab(searchBox.Text)
	end)

	local function makeHeaderIconBtn(name, order, iconName, hoverColorToken, callback)
		local btn = Creator.new("TextButton", {
			Name = name,
			Size = UDim2.fromOffset(28, 28),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order,
			ZIndex = 13,
			ThemeBind = { BackgroundColor3 = "RowBg" },
			Parent = rightCluster,
		}, {
			Creator.corner(8),
			Creator.stroke("Outline", 1, 0),
		})

		local ico = Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			Image = Icons.resolve(iconName) or "",
			ZIndex = 14,
			ThemeBind = { ImageColor3 = "TextSecondary" },
			Parent = btn,
		})

		btn.MouseEnter:Connect(function()
			Animator.tween(btn, { BackgroundColor3 = ThemeManager:Get(hoverColorToken or "RowHover") }, 0.12)
			Animator.tween(
				ico,
				{ ImageColor3 = ThemeManager:Get(hoverColorToken == "Error" and "OnAccent" or "Text") },
				0.12
			)
		end)
		btn.MouseLeave:Connect(function()
			Animator.tween(btn, { BackgroundColor3 = ThemeManager:Get("RowBg") }, 0.14)
			Animator.tween(ico, { ImageColor3 = ThemeManager:Get("TextSecondary") }, 0.14)
		end)
		btn.Activated:Connect(callback)
		return btn, ico
	end

	-- Theme Quick Cycle Button (Obsidian <-> Light)
	makeHeaderIconBtn("ThemeBtn", 2, "sun", "RowHover", function()
		local nextTheme = ThemeManager.CurrentTheme == "Light" and "Obsidian" or "Light"
		ThemeManager:SetTheme(nextTheme, true)
	end)

	-- Minimize to Floating Pill Button
	makeHeaderIconBtn("MinimizeBtn", 3, "minus", "RowHover", function()
		window:MinimizeToPill(true)
	end)

	-- Close / Unload Button
	makeHeaderIconBtn("CloseBtn", 4, "x", "Error", function()
		window:PromptClose()
	end)

	-- Smooth, Full-Screen Window Dragging (UP, DOWN, LEFT, RIGHT)
	local dragging = false
	local dragStart = Vector2.zero
	local startCenter = Vector2.zero

	local function beginDrag(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			Popover.close()
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			local pos = window.Root.Position
			startCenter = Vector2.new(pos.X.Scale * vp.X + pos.X.Offset, pos.Y.Scale * vp.Y + pos.Y.Offset)
		end
	end

	bar.InputBegan:Connect(beginDrag)
	badge.InputBegan:Connect(beginDrag)
	titleLabel.InputBegan:Connect(beginDrag)
	sep.InputBegan:Connect(beginDrag)
	activeTabLabel.InputBegan:Connect(beginDrag)

	window.Maid:Add(Services.UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			local newX = math.clamp(startCenter.X + delta.X, 60, vp.X - 60)
			local newY = math.clamp(startCenter.Y + delta.Y, 40, vp.Y - 40)
			window.Root.Position = UDim2.fromOffset(math.floor(newX + 0.5), math.floor(newY + 0.5))
		end
	end))

	window.Maid:Add(Services.UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end))

	return {
		Frame = bar,
		TitleLabel = titleLabel,
		SearchBox = searchBox,
		SetTitle = function(_, t)
			titleLabel.Text = tostring(t or "")
		end,
		SetActiveTabTitle = function(_, tabName)
			activeTabLabel.Text = tostring(tabName or "")
			if searchBox.Text ~= "" then
				searchBox.Text = ""
			end
		end,
		SetSubtitle = function() end,
		UpdateKeyText = function() end,
	}
end

return TitleBar
end

-- [[ Module: Window/Sidebar ]]
__modules["Window/Sidebar"] = function(require)
local Creator = require("Core/Creator")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")

local Sidebar = {}

function Sidebar.create(window, opts)
	opts = opts or {}
	local dockWidth = 56
	local collapsed = false

	-- Floating Left Capsule Dock (inset 10px from left & bottom, below the 44px Floating Header)
	local container = Creator.new("Frame", {
		Name = "FloatingDock",
		Position = UDim2.fromOffset(10, 62),
		Size = UDim2.new(0, dockWidth, 1, -72),
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "SidebarBg" },
		Parent = window.Chrome,
	}, {
		Creator.corner(14),
		Creator.stroke("Outline", 1.2, 0),
	})

	-- Sliding Active Pill with Signature Indigo->Cyan Gradient + Left Glow Bar
	local activePill = Creator.new("Frame", {
		Name = "ActiveDockPill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Visible = false,
		ZIndex = 7,
		Parent = container,
	}, {
		Creator.corner(11),
		Creator.new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 189, 248)),
			}),
			Rotation = 45,
		}),
	})

	local tabScroll = Creator.new("ScrollingFrame", {
		Name = "TabScroll",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 8,
		Parent = container,
	}, {
		Creator.padding(8, 0, 8, 0),
		Creator.list(8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top),
	})

	local orderCounter = 0
	local tabButtons = {}

	local sidebarObj = {
		Frame = container,
		TabScroll = tabScroll,
		ExpandedWidth = dockWidth,
		CollapsedWidth = 0,
	}

	function sidebarObj:AddGroupHeader()
		return nil
	end

	function sidebarObj:AddTabButton(tab, icon)
		orderCounter += 1
		local btn = Creator.new("TextButton", {
			Name = "TabBtn_" .. tostring(tab.Title),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = orderCounter,
			ZIndex = 9,
			ThemeBind = { BackgroundColor3 = "RowHover" },
			Parent = tabScroll,
		}, {
			Creator.corner(11),
		})

		local scale = Creator.new("UIScale", { Scale = 1, Parent = btn })

		local iconImg = Creator.new("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			Image = Icons.resolve(icon or "layers") or "",
			ZIndex = 10,
			ThemeBind = { ImageColor3 = "SidebarIconInactive" },
			Parent = btn,
		})

		btn.MouseEnter:Connect(function()
			Animator.spring(scale, "Scale", 1.1, { frequency = 20, damping = 0.78 })
			if window.ActiveTab ~= tab then
				Animator.tween(btn, { BackgroundTransparency = 0.45 }, 0.12)
			end
		end)

		btn.MouseLeave:Connect(function()
			Animator.spring(scale, "Scale", 1, { frequency = 18, damping = 0.82 })
			Animator.tween(btn, { BackgroundTransparency = 1 }, 0.14)
		end)

		btn.Activated:Connect(function()
			Animator.spring(scale, "Scale", 0.9, { frequency = 24, damping = 0.8 })
			task.delay(0.08, function()
				if scale.Parent then
					Animator.spring(scale, "Scale", 1, { frequency = 18, damping = 0.76 })
				end
			end)
			window:SelectTab(tab)
		end)

		local entry = {
			Tab = tab,
			Button = btn,
			Icon = iconImg,
		}
		tabButtons[#tabButtons + 1] = entry
		return entry
	end

	function sidebarObj:UpdateActive(selectedTab)
		for _, entry in ipairs(tabButtons) do
			local isCurrent = (entry.Tab == selectedTab)
			if isCurrent then
				ThemeManager:Unbind(entry.Icon)
				entry.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
				activePill.Visible = true
				task.defer(function()
					if entry.Button.Parent and container.Parent then
						local relY = entry.Button.AbsolutePosition.Y - container.AbsolutePosition.Y
						local scale = (window.UIScale and window.UIScale.Scale > 0) and window.UIScale.Scale or 1
						Animator.spring(
							activePill,
							"Position",
							UDim2.new(0.5, 0, 0, math.floor(relY / scale + 0.5)),
							{ frequency = 20, damping = 0.82 }
						)
					end
				end)
			else
				ThemeManager:Bind(entry.Icon, { ImageColor3 = "SidebarIconInactive" })
			end
		end
	end

	function sidebarObj:SetCollapsed(state)
		collapsed = state == true
		local targetW = collapsed and 0 or dockWidth
		Animator.spring(container, "Size", UDim2.new(0, targetW, 1, -72), { frequency = 18, damping = 0.86 })
		return targetW
	end

	function sidebarObj:IsCollapsed()
		return collapsed
	end

	return sidebarObj
end

return Sidebar
end

-- [[ Module: Window/MinimizedPill ]]
__modules["Window/MinimizedPill"] = function(require)
local Creator = require("Core/Creator")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local MinimizedPill = {}

function MinimizedPill.create(window, opts)
	opts = opts or {}

	local pill = Creator.new("TextButton", {
		Name = "DynamicIslandPill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -48),
		Size = UDim2.fromOffset(186, 34),
		BackgroundTransparency = 0.04,
		Visible = false,
		Text = "",
		ZIndex = 180,
		ThemeBind = { BackgroundColor3 = "TitleBarBg" },
		Parent = window.ScreenGui,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("InnerStroke", 1, 0.25),
		Creator.new("UIScale", { Scale = 1 }),
	})

	Shadow.create(pill, 18, 0.45, 179)

	Creator.new("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(15, 15),
		Image = Icons.resolve(opts.Icon or "sparkles") or "",
		ZIndex = 181,
		ThemeBind = { ImageColor3 = "Accent" },
		Parent = pill,
	})

	local label = Creator.new("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(33, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 13,
		Text = tostring(opts.Title or "Perfectus"),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 181,
		ThemeBind = { TextColor3 = "Text" },
		Parent = pill,
	})

	Creator.new("ImageLabel", {
		Name = "ExpandIcon",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = Icons.resolve("maximize-2") or "",
		ZIndex = 181,
		ThemeBind = { ImageColor3 = "TextSecondary" },
		Parent = pill,
	})

	Creator.bindInteractive(pill, {
		NormalToken = "TitleBarBg",
		HoverToken = "RowHover",
		PressScale = 0.96,
	})

	pill.Activated:Connect(function()
		window:MinimizeToPill(false)
	end)

	return {
		Frame = pill,
		Show = function()
			pill.Visible = true
			Animator.spring(pill, "Position", UDim2.new(0.5, 0, 0, 12), { frequency = 16, damping = 0.82 })
		end,
		Hide = function()
			Animator.spring(pill, "Position", UDim2.new(0.5, 0, 0, -48), {
				frequency = 18,
				damping = 0.88,
				onComplete = function()
					pill.Visible = false
				end,
			})
		end,
		SetTitle = function(_, t)
			label.Text = tostring(t or "Perfectus")
		end,
	}
end

return MinimizedPill
end

-- [[ Module: Window/MobileToggle ]]
__modules["Window/MobileToggle"] = function(require)
local Services = require("Core/Services")
local Env = require("Core/Env")
local Creator = require("Core/Creator")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local MobileToggle = {}

function MobileToggle.create(window, opts)
	opts = opts or {}
	if not Env.IsMobile and not opts.ForceMobileButton then
		return nil
	end

	local btn = Creator.new("TextButton", {
		Name = "MobileToggleBtn",
		Position = UDim2.new(0, 14, 0.5, -22),
		Size = UDim2.fromOffset(44, 44),
		Text = "",
		ZIndex = 250,
		ThemeBind = { BackgroundColor3 = "TitleBarBg" },
		Parent = window.ScreenGui,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Accent", 1.5, 0.2),
		Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(20, 20),
			Image = Icons.resolve(opts.Icon or "sparkles") or "",
			ZIndex = 251,
			ThemeBind = { ImageColor3 = "Accent" },
		}),
	})

	Shadow.create(btn, 14, 0.4, 249)

	local dragging = false
	local moved = false
	local startInput = Vector2.zero
	local startPos = btn.Position

	btn.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			dragging = true
			moved = false
			startInput = Vector2.new(input.Position.X, input.Position.Y)
			startPos = btn.Position
		end
	end)

	window.Maid:Add(Services.UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseMovement
		then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - startInput
			if delta.Magnitude > 6 then
				moved = true
			end
			btn.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))

	window.Maid:Add(Services.UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			if dragging and not moved then
				window:ToggleVisibility()
			end
			dragging = false
		end
	end))

	return btn
end

return MobileToggle
end

-- [[ Module: Components/Scroll ]]
__modules["Components/Scroll"] = function(require)
local Creator = require("Core/Creator")
local Signal = require("Core/Signal")

local Scroll = {}

function Scroll.create(props)
	props = props or {}
	local scrolled = Signal.new()

	local frame = Creator.new("ScrollingFrame", {
		Name = props.Name or "ScrollContainer",
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = props.ScrollBarThickness or 3,
		ScrollBarImageTransparency = 0.45,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true,
		Visible = props.Visible ~= false,
		ZIndex = props.ZIndex or 2,
		ThemeBind = { ScrollBarImageColor3 = "TextMuted" },
		Parent = props.Parent,
	})

	local pad = props.Padding or { Top = 14, Right = 16, Bottom = 18, Left = 16 }
	Creator.padding(pad.Top, pad.Right, pad.Bottom, pad.Left, frame)

	local list = Creator.list(
		props.Spacing or 12,
		Enum.FillDirection.Vertical,
		Enum.HorizontalAlignment.Left,
		Enum.VerticalAlignment.Top,
		frame
	)

	frame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		scrolled:Fire(frame.CanvasPosition)
	end)

	return {
		Frame = frame,
		ListLayout = list,
		Scrolled = scrolled,
	}
end

return Scroll
end

-- [[ Module: Elements/Button ]]
__modules["Elements/Button"] = function(require)
local Creator = require("Core/Creator")
local Signal = require("Core/Signal")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")

local Button = {}

function Button.create(section, opts)
	opts = opts or {}
	local style = opts.Style or "Secondary" -- "Primary" | "Secondary" | "Destructive"
	local title = tostring(opts.Title or opts.ButtonText or "Button")
	local confirmRequired = opts.Confirm == true

	local bgToken = "RowBg"
	local hoverToken = "RowHover"
	local textToken = "Text"
	if style == "Primary" then
		bgToken = "Accent"
		hoverToken = "AccentHover"
		textToken = "OnAccent"
	elseif style == "Destructive" then
		bgToken = "Error"
		hoverToken = "Error"
		textToken = "OnAccent"
	end

	local btn = Creator.new("TextButton", {
		Name = "Row_" .. title,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 4,
		ThemeBind = { BackgroundColor3 = bgToken },
		Parent = section.Container,
	}, {
		Creator.corner(10),
		Creator.stroke("Outline", 1, 0),
		Creator.new("UIScale", { Scale = 1 }),
	})

	local titleLabel = Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 14,
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 5,
		ThemeBind = { TextColor3 = textToken },
		Parent = btn,
	})

	local scaleInst = btn:FindFirstChildOfClass("UIScale")
	local awaitingConfirm = false
	local confirmResetThread = nil
	local running = false
	local locked = false

	btn.MouseEnter:Connect(function()
		if not awaitingConfirm then
			Animator.tween(btn, { BackgroundColor3 = ThemeManager:Get(hoverToken) }, 0.12)
		end
	end)

	btn.MouseLeave:Connect(function()
		if not awaitingConfirm then
			Animator.tween(btn, { BackgroundColor3 = ThemeManager:Get(bgToken) }, 0.14)
		end
	end)

	local function resetConfirm()
		awaitingConfirm = false
		if confirmResetThread then
			pcall(task.cancel, confirmResetThread)
			confirmResetThread = nil
		end
		titleLabel.Text = title
		Animator.tween(btn, { BackgroundColor3 = ThemeManager:Get(bgToken) }, 0.16)
	end

	local control = {
		Kind = "Button",
		Row = btn,
		TitleLabel = titleLabel,
		Section = section,
		Window = section.Window,
		Title = title,
		Changed = Signal.new(),
		IsLocked = function()
			return locked
		end,
		Lock = function()
			locked = true
		end,
		Unlock = function()
			locked = false
		end,
		Highlight = function()
			Animator.pulseHighlight(btn)
		end,
		SetTitle = function(self, newTitle)
			self.Title = tostring(newTitle or "")
			title = self.Title
			titleLabel.Text = title
		end,
		SetButtonText = function(self, newTitle)
			self:SetTitle(newTitle)
		end,
		SetVisible = function(_, v)
			btn.Visible = v == true
		end,
		OnChanged = function(self, fn)
			return self.Changed:Connect(fn)
		end,
		Destroy = function(self)
			self.Changed:Destroy()
			if btn and btn.Parent then
				btn:Destroy()
			end
		end,
	}

	local function trigger()
		if locked or running then
			return
		end
		if confirmRequired and not awaitingConfirm then
			awaitingConfirm = true
			titleLabel.Text = "Confirm: " .. title
			Animator.tween(btn, { BackgroundColor3 = ThemeManager:Get("Warning") }, 0.14)
			confirmResetThread = task.delay(2.5, resetConfirm)
			return
		end
		if awaitingConfirm then
			resetConfirm()
		end

		if scaleInst then
			Animator.spring(scaleInst, "Scale", 0.97, { frequency = 24, damping = 0.8 })
			task.delay(0.08, function()
				if scaleInst.Parent then
					Animator.spring(scaleInst, "Scale", 1, { frequency = 18, damping = 0.78 })
				end
			end)
		end

		control.Changed:Fire()
		if type(opts.Callback) == "function" then
			running = true
			task.spawn(function()
				Util.safeCall(control.Title, opts.Callback, control.Window and control.Window._notifyError)
				running = false
			end)
		end
	end

	btn.Activated:Connect(trigger)
	control.Fire = trigger

	if section.Window and section.Window._registerSearchable then
		section.Window:_registerSearchable(control, section)
	end

	return control
end

return Button
end

-- [[ Module: Components/RowBase ]]
__modules["Components/RowBase"] = function(require)
local Creator = require("Core/Creator")
local Signal = require("Core/Signal")
local Icons = require("Assets/Icons")
local Animator = require("Motion/Animator")

local RowBase = {}

function RowBase.create(section, opts)
	opts = opts or {}
	local rightWidth = opts.RightWidth or 120
	local minHeight = opts.MinHeight or 42
	local clickable = opts.Clickable == true
	local framed = opts.Framed ~= false

	local rowClass = clickable and "TextButton" or "Frame"
	local rowProps = {
		Name = opts.Name or ("Row_" .. tostring(opts.Title or "Item")),
		Size = UDim2.new(1, 0, 0, minHeight),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = framed and 0 or 1,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		Parent = section.Container,
	}
	if framed then
		rowProps.ThemeBind = { BackgroundColor3 = "RowBg" }
	end
	if clickable then
		rowProps.Text = ""
		rowProps.AutoButtonColor = false
	end

	local children = {
		Creator.corner(10),
		Creator.padding(8, 12, 8, 12),
		Creator.new("UISizeConstraint", {
			MinSize = Vector2.new(0, minHeight),
		}),
	}
	if framed then
		table.insert(children, Creator.stroke("Outline", 1, 0))
	end

	local row = Creator.new(rowClass, rowProps, children)

	if framed then
		Creator.bindInteractive(row, {
			NormalToken = "RowBg",
			HoverToken = "RowHover",
		})
	end

	local hasIcon = opts.Icon ~= nil and opts.Icon ~= ""
	local iconOffset = hasIcon and 24 or 0

	local iconImage = nil
	if hasIcon then
		iconImage = Creator.new("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			Image = Icons.resolve(opts.Icon) or "",
			ZIndex = 4,
			ThemeBind = { ImageColor3 = opts.IconColorToken or "TextSecondary" },
			Parent = row,
		})
	end

	local textReserve = rightWidth > 0 and (rightWidth + 14 + iconOffset) or iconOffset
	local leftCol = Creator.new("Frame", {
		Name = "LeftColumn",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, iconOffset, 0.5, 0),
		Size = UDim2.new(1, -textReserve, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = row,
	}, {
		Creator.list(2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
	})

	local titleLabel = Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 14,
		Text = tostring(opts.Title or ""),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		ZIndex = 4,
		ThemeBind = { TextColor3 = opts.TitleColorToken or "Text" },
		Parent = leftCol,
	})

	local descLabel = nil
	local function ensureDescLabel()
		if not descLabel then
			descLabel = Creator.new("TextLabel", {
				Name = "Description",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Font = Enum.Font.BuilderSans,
				TextSize = 12,
				TextWrapped = true,
				Text = "",
				LayoutOrder = 2,
				ZIndex = 4,
				ThemeBind = { TextColor3 = "TextSecondary" },
				Parent = leftCol,
			})
		end
		return descLabel
	end

	if opts.Description and opts.Description ~= "" then
		local d = ensureDescLabel()
		d.Text = tostring(opts.Description)
	end

	local rightSlot = nil
	if rightWidth > 0 then
		rightSlot = Creator.new("Frame", {
			Name = "RightSlot",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(rightWidth, minHeight - 12),
			BackgroundTransparency = 1,
			ZIndex = 5,
			Parent = row,
		})
	end

	local locked = false
	local lockReason = nil
	local lockOverlay = nil

	local control = {
		Row = row,
		LeftColumn = leftCol,
		TitleLabel = titleLabel,
		RightSlot = rightSlot,
		IconImage = iconImage,
		Section = section,
		Window = section.Window,
		Flag = opts.Flag or opts.Id,
		Title = tostring(opts.Title or ""),
		Default = opts.Default,
		Changed = Signal.new(),
		IsLocked = function()
			return locked
		end,
	}

	function control:OnChanged(fn)
		return self.Changed:Connect(fn)
	end

	function control:SetTitle(newTitle)
		self.Title = tostring(newTitle or "")
		titleLabel.Text = self.Title
	end

	function control:SetDescription(newDesc)
		if newDesc == nil or newDesc == "" then
			if descLabel then
				descLabel.Visible = false
				descLabel.Text = ""
			end
		else
			local d = ensureDescLabel()
			d.Visible = true
			d.Text = tostring(newDesc)
		end
	end

	function control:SetVisible(vis)
		row.Visible = vis == true
	end

	function control:Lock(reason)
		locked = true
		lockReason = reason and tostring(reason) or "Locked"
		if not lockOverlay then
			lockOverlay = Creator.new("TextButton", {
				Name = "LockOverlay",
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 0.28,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 12,
				ThemeBind = { BackgroundColor3 = "SectionBg" },
				Parent = row,
			}, {
				Creator.corner(10),
				Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					Image = Icons.resolve("lock") or "",
					ZIndex = 13,
					ThemeBind = { ImageColor3 = "TextMuted" },
				}),
			})
		end
		lockOverlay.Visible = true
	end

	function control:Unlock()
		locked = false
		lockReason = nil
		if lockOverlay then
			lockOverlay.Visible = false
		end
	end

	function control:Highlight()
		Animator.pulseHighlight(row)
	end

	function control:Destroy()
		self.Changed:Destroy()
		if row and row.Parent then
			row:Destroy()
		end
	end

	if section.Window then
		if type(opts.Tooltip) == "string" and opts.Tooltip ~= "" and section.Window._registerTooltip then
			section.Window:_registerTooltip(row, opts.Tooltip)
		end
		if section.Window._registerContextMenu then
			section.Window:_registerContextMenu(row, control)
		end
		if section.Window._registerSearchable then
			section.Window:_registerSearchable(control, section)
		end
	end

	return control
end

return RowBase
end

-- [[ Module: Elements/Toggle ]]
__modules["Elements/Toggle"] = function(require)
local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Env = require("Core/Env")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local RowBase = require("Components/RowBase")

local Toggle = {}

local function parseKey(key)
	if key == nil or key == "" or key == "None" then
		return nil
	end
	if typeof(key) == "EnumItem" then
		return key
	end
	if type(key) == "string" then
		local ok, item = pcall(function()
			return Enum.KeyCode[key]
		end)
		if ok and item then
			return item
		end
	end
	return nil
end

function Toggle.create(section, opts)
	opts = opts or {}
	local state = opts.Default == true
	local currentKey = parseKey(opts.Key)
	local hasKeybindSlot = (opts.Key ~= nil or opts.AllowKeybind == true) and not Env.IsMobile

	local control = RowBase.create(section, {
		Title = opts.Title or "Toggle",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = state,
		RightWidth = hasKeybindSlot and 106 or 50,
		Clickable = true,
	})
	control.Kind = "Toggle"

	local keyBtn = nil
	local listeningKey = false
	if hasKeybindSlot then
		keyBtn = Creator.new("TextButton", {
			Name = "KeyChip",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -52, 0.5, 0),
			Size = UDim2.fromOffset(44, 24),
			Font = Enum.Font.BuilderSansBold,
			TextSize = 12,
			Text = Util.formatKeyName(currentKey),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 6,
			ThemeBind = {
				BackgroundColor3 = "ControlBg",
				TextColor3 = "Text",
			},
			Parent = control.RightSlot,
		}, {
			Creator.corner(6),
			Creator.stroke("Outline", 1, 0),
		})
	end

	-- Sleek Switch Track (44 x 24)
	local track = Creator.new("Frame", {
		Name = "SwitchTrack",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(44, 24),
		BackgroundColor3 = ThemeManager:Get(state and "Accent" or "SwitchOff"),
		ZIndex = 6,
		Parent = control.RightSlot,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Outline", 1, 0),
	})

	local knob = Creator.new("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 7,
		ThemeBind = { BackgroundColor3 = "Knob" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local function syncVisuals(animate)
		local targetColor = ThemeManager:Get(state and "Accent" or "SwitchOff")
		local targetPos = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		if animate ~= false then
			Animator.tween(track, { BackgroundColor3 = targetColor }, 0.18)
			Animator.spring(knob, "Position", targetPos, { frequency = 18, damping = 0.82 })
			Animator.spring(knob, "Size", UDim2.fromOffset(18, 18), { frequency = 18, damping = 0.82 })
		else
			track.BackgroundColor3 = targetColor
			knob.Position = targetPos
			knob.Size = UDim2.fromOffset(18, 18)
		end
	end

	ThemeManager.Changed:Connect(function()
		syncVisuals(true)
	end)

	local function setValue(newVal, silent)
		newVal = newVal == true
		local changed = (state ~= newVal)
		state = newVal
		syncVisuals(true)
		if control.Window and control.Window._updateKeybindEntry then
			control.Window:_updateKeybindEntry(control)
		end
		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, state, silent)
		end
		if not silent then
			control.Changed:Fire(state)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					state
				)
			end
		end
		return changed
	end

	control.Row.Activated:Connect(function()
		if control:IsLocked() or listeningKey then
			return
		end
		setValue(not state, false)
	end)

	function control:Get()
		return state
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	function control:GetKey()
		return currentKey
	end

	function control:SetKey(newKey)
		currentKey = parseKey(newKey)
		if keyBtn then
			keyBtn.Text = Util.formatKeyName(currentKey)
		end
		if control.Window and control.Window._updateKeybindEntry then
			control.Window:_updateKeybindEntry(control)
		end
	end

	if keyBtn then
		keyBtn.Activated:Connect(function()
			if control:IsLocked() then
				return
			end
			listeningKey = true
			keyBtn.Text = "..."
		end)

		Services.UserInputService.InputBegan:Connect(function(input, processed)
			if not control.Row.Parent then
				return
			end
			if listeningKey then
				if input.UserInputType == Enum.UserInputType.Keyboard then
					listeningKey = false
					if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
						control:SetKey(nil)
					else
						control:SetKey(input.KeyCode)
					end
				end
				return
			end
			if not processed and currentKey and input.KeyCode == currentKey then
				if Services.UserInputService:GetFocusedTextBox() == nil and not control:IsLocked() then
					setValue(not state, false)
				end
			end
		end)
	end

	if control.Window and control.Window._registerKeybindEntry and hasKeybindSlot then
		control.Window:_registerKeybindEntry(control)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncVisuals(false)
	return control
end

return Toggle
end

-- [[ Module: Elements/Checkbox ]]
__modules["Elements/Checkbox"] = function(require)
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local RowBase = require("Components/RowBase")

local Checkbox = {}

function Checkbox.create(section, opts)
	opts = opts or {}
	local state = opts.Default == true

	local control = RowBase.create(section, {
		Title = opts.Title or "Checkbox",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = state,
		RightWidth = 40,
		Clickable = true,
	})
	control.Kind = "Checkbox"

	local box = Creator.new("Frame", {
		Name = "CheckFrame",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = ThemeManager:Get(state and "Accent" or "ControlBg"),
		ZIndex = 6,
		Parent = control.RightSlot,
	}, {
		Creator.corner(8),
		Creator.stroke("Outline", 2, 0),
	})

	local icon = Creator.new("ImageLabel", {
		Name = "CheckIcon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Image = Icons.resolve("check") or "",
		ImageTransparency = state and 0 or 1,
		ZIndex = 7,
		ThemeBind = { ImageColor3 = "OnAccent" },
		Parent = box,
	})

	local iconScale = Creator.new("UIScale", {
		Scale = state and 1 or 0.75,
		Parent = icon,
	})

	local function syncVisuals(animate)
		local targetColor = ThemeManager:Get(state and "Accent" or "ControlBg")
		local targetTrans = state and 0 or 1
		local targetScale = state and 1 or 0.75

		if animate ~= false then
			Animator.tween(box, { BackgroundColor3 = targetColor }, 0.16)
			Animator.tween(icon, { ImageTransparency = targetTrans }, 0.14)
			Animator.spring(iconScale, "Scale", targetScale, { frequency = 20, damping = 0.8 })
		else
			box.BackgroundColor3 = targetColor
			icon.ImageTransparency = targetTrans
			iconScale.Scale = targetScale
		end
	end

	ThemeManager.Changed:Connect(function()
		syncVisuals(true)
	end)

	local function setValue(newVal, silent)
		newVal = newVal == true
		local changed = (state ~= newVal)
		state = newVal
		syncVisuals(true)

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, state, silent)
		end
		if not silent then
			control.Changed:Fire(state)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					state
				)
			end
		end
		return changed
	end

	control.Row.Activated:Connect(function()
		if control:IsLocked() then
			return
		end
		setValue(not state, false)
	end)

	function control:Get()
		return state
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncVisuals(false)
	return control
end

return Checkbox
end

-- [[ Module: Elements/Slider ]]
__modules["Elements/Slider"] = function(require)
local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Signal = require("Core/Signal")
local Util = require("Core/Util")
local Animator = require("Motion/Animator")

local Slider = {}

function Slider.create(section, opts)
	opts = opts or {}
	local minVal = tonumber(opts.Min) or 0
	local maxVal = tonumber(opts.Max) or 100
	if minVal > maxVal then
		minVal, maxVal = maxVal, minVal
	end
	local step = tonumber(opts.Step) or 1
	local suffix = opts.Suffix or ""
	local rawDefault = tonumber(opts.Default) or minVal
	local value = Util.round(Util.clamp(rawDefault, minVal, maxVal), step)
	local title = tostring(opts.Title or "Slider")

	-- Sleek Bento 2-Deck Slider Card
	local row = Creator.new("Frame", {
		Name = "Row_" .. title,
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 0,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		ThemeBind = { BackgroundColor3 = "RowBg" },
		Parent = section.Container,
	}, {
		Creator.corner(10),
		Creator.stroke("Outline", 1, 0),
		Creator.padding(8, 12, 10, 12),
	})

	local topRow = Creator.new("Frame", {
		Name = "TopHeader",
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = row,
	})

	local titleLabel = Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -84, 1, 0),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 14,
		Text = title,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		ThemeBind = { TextColor3 = "Text" },
		Parent = topRow,
	})

	local valueBox = Creator.new("TextBox", {
		Name = "ValueBox",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(78, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		ClearTextOnFocus = false,
		ZIndex = 5,
		ThemeBind = { TextColor3 = "ValueText" },
		Parent = topRow,
	})

	-- Full-width sleek pill track with Indigo->Cyan gradient fill
	local track = Creator.new("TextButton", {
		Name = "SliderTrack",
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, 0, 0, 8),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = row,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local fill = Creator.new("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 7,
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 189, 248)),
			}),
		}),
	})

	local knob = Creator.new("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		ZIndex = 8,
		ThemeBind = { BackgroundColor3 = "Knob" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke(Color3.fromRGB(99, 102, 241), 2, 0),
	})

	local locked = false
	local control = {
		Kind = "Slider",
		Row = row,
		TitleLabel = titleLabel,
		Section = section,
		Window = section.Window,
		Flag = opts.Flag or opts.Id,
		Title = title,
		Default = value,
		Changed = Signal.new(),
		IsLocked = function()
			return locked
		end,
		Lock = function()
			locked = true
		end,
		Unlock = function()
			locked = false
		end,
		Highlight = function()
			Animator.pulseHighlight(row)
		end,
		SetTitle = function(self, t)
			self.Title = tostring(t or "")
			titleLabel.Text = self.Title
		end,
		SetVisible = function(_, v)
			row.Visible = v == true
		end,
		OnChanged = function(self, fn)
			return self.Changed:Connect(fn)
		end,
		Destroy = function(self)
			self.Changed:Destroy()
			if row and row.Parent then
				row:Destroy()
			end
		end,
	}

	local function getRatio(val)
		if maxVal == minVal then
			return 0
		end
		return math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
	end

	local function syncVisuals(animate)
		local ratio = getRatio(value)
		if animate ~= false then
			Animator.spring(fill, "Size", UDim2.new(ratio, 0, 1, 0), { frequency = 24, damping = 0.85 })
			Animator.spring(knob, "Position", UDim2.new(ratio, 0, 0.5, 0), { frequency = 24, damping = 0.85 })
		else
			fill.Size = UDim2.new(ratio, 0, 1, 0)
			knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		end
		if not valueBox:IsFocused() then
			valueBox.Text = tostring(value) .. suffix
		end
	end

	local function setValue(newVal, silent)
		newVal = tonumber(newVal) or minVal
		newVal = Util.round(Util.clamp(newVal, minVal, maxVal), step)
		local changed = (value ~= newVal)
		value = newVal
		syncVisuals(true)

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, value, silent)
		end
		if not silent then
			control.Changed:Fire(value)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					value
				)
			end
		end
		return changed
	end

	local dragging = false
	local moveConn = nil
	local releaseConn = nil

	local function updateFromInput(input)
		local absX = track.AbsolutePosition.X
		local absW = track.AbsoluteSize.X
		if absW <= 0 then
			return
		end
		local rel = math.clamp((input.Position.X - absX) / absW, 0, 1)
		local raw = minVal + (maxVal - minVal) * rel
		setValue(raw, false)
	end

	local function startDragging(input)
		if locked then
			return
		end
		dragging = true
		Animator.spring(knob, "Size", UDim2.fromOffset(19, 19), { frequency = 22, damping = 0.82 })
		updateFromInput(input)

		if moveConn then
			moveConn:Disconnect()
		end
		if releaseConn then
			releaseConn:Disconnect()
		end

		moveConn = Services.UserInputService.InputChanged:Connect(function(moveInput)
			if
				dragging
				and (
					moveInput.UserInputType == Enum.UserInputType.MouseMovement
					or moveInput.UserInputType == Enum.UserInputType.Touch
				)
			then
				updateFromInput(moveInput)
			end
		end)

		releaseConn = Services.UserInputService.InputEnded:Connect(function(endInput)
			if
				endInput.UserInputType == Enum.UserInputType.MouseButton1
				or endInput.UserInputType == Enum.UserInputType.Touch
			then
				dragging = false
				Animator.spring(knob, "Size", UDim2.fromOffset(16, 16), { frequency = 20, damping = 0.85 })
				if moveConn then
					moveConn:Disconnect()
					moveConn = nil
				end
				if releaseConn then
					releaseConn:Disconnect()
					releaseConn = nil
				end
			end
		end)
	end

	track.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			startDragging(input)
		end
	end)

	valueBox.FocusLost:Connect(function()
		local rawText = valueBox.Text:gsub("[^%d.-]", "")
		local parsed = tonumber(rawText)
		if parsed then
			setValue(parsed, false)
		else
			syncVisuals(false)
		end
	end)

	function control:Get()
		return value
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	function control:SetMin(newMin)
		minVal = tonumber(newMin) or minVal
		setValue(value, true)
	end

	function control:SetMax(newMax)
		maxVal = tonumber(newMax) or maxVal
		setValue(value, true)
	end

	if section.Window then
		if section.Window._registerContextMenu then
			section.Window:_registerContextMenu(row, control)
		end
		if section.Window._registerSearchable then
			section.Window:_registerSearchable(control, section)
		end
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncVisuals(false)
	return control
end

return Slider
end

-- [[ Module: Elements/RangeSlider ]]
__modules["Elements/RangeSlider"] = function(require)
local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local RowBase = require("Components/RowBase")

local RangeSlider = {}

function RangeSlider.create(section, opts)
	opts = opts or {}
	local minVal = tonumber(opts.Min) or 0
	local maxVal = tonumber(opts.Max) or 100
	if minVal > maxVal then
		minVal, maxVal = maxVal, minVal
	end
	local step = tonumber(opts.Step) or 1
	local suffix = opts.Suffix or ""

	local def = type(opts.Default) == "table" and opts.Default
		or { minVal + (maxVal - minVal) * 0.2, minVal + (maxVal - minVal) * 0.8 }
	local lowVal = Util.round(Util.clamp(tonumber(def[1]) or minVal, minVal, maxVal), step)
	local highVal = Util.round(Util.clamp(tonumber(def[2]) or maxVal, minVal, maxVal), step)
	if lowVal > highVal then
		lowVal, highVal = highVal, lowVal
	end

	local control = RowBase.create(section, {
		Title = opts.Title or "Range Slider",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = { lowVal, highVal },
		RightWidth = 195,
		Clickable = false,
	})
	control.Kind = "RangeSlider"

	local trackWidth = 120

	local track = Creator.new("TextButton", {
		Name = "RangeTrack",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(trackWidth, 12),
		BackgroundColor3 = ThemeManager:Get("ControlBg"),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		Parent = control.RightSlot,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Outline", 2, 0),
	})

	local fill = Creator.new("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = ThemeManager:Get("Accent"),
		ZIndex = 7,
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local knobLow = Creator.new("Frame", {
		Name = "KnobLow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 8,
		ThemeBind = { BackgroundColor3 = "Knob" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Outline", 2, 0),
	})

	local knobHigh = Creator.new("Frame", {
		Name = "KnobHigh",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 8,
		ThemeBind = { BackgroundColor3 = "Knob" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Outline", 2, 0),
	})

	local valueLabel = Creator.new("TextLabel", {
		Name = "RangeLabel",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(68, 22),
		Font = Enum.Font.RobotoMono,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 6,
		ThemeBind = {
			BackgroundColor3 = "InputBg",
			TextColor3 = "Text",
		},
		Parent = control.RightSlot,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.35),
	})

	local function getRatio(val)
		if maxVal == minVal then
			return 0
		end
		return math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
	end

	local function syncVisuals(animate)
		local lowRatio = getRatio(lowVal)
		local highRatio = getRatio(highVal)
		fill.BackgroundColor3 = ThemeManager:Get("Accent")

		local fillPos = UDim2.new(lowRatio, 0, 0.5, 0)
		local fillSize = UDim2.new(math.max(0, highRatio - lowRatio), 0, 1, 0)
		local knobLowPos = UDim2.new(lowRatio, 0, 0.5, 0)
		local knobHighPos = UDim2.new(highRatio, 0, 0.5, 0)

		if animate ~= false then
			Animator.spring(fill, "Position", fillPos, { frequency = 24, damping = 0.85 })
			Animator.spring(fill, "Size", fillSize, { frequency = 24, damping = 0.85 })
			Animator.spring(knobLow, "Position", knobLowPos, { frequency = 24, damping = 0.85 })
			Animator.spring(knobHigh, "Position", knobHighPos, { frequency = 24, damping = 0.85 })
		else
			fill.Position = fillPos
			fill.Size = fillSize
			knobLow.Position = knobLowPos
			knobHigh.Position = knobHighPos
		end
		valueLabel.Text = string.format("%s - %s%s", tostring(lowVal), tostring(highVal), suffix)
	end

	ThemeManager.Changed:Connect(function()
		syncVisuals(true)
	end)

	local function setValue(newL, newH, silent)
		newL = tonumber(newL) or minVal
		newH = tonumber(newH) or maxVal
		newL = Util.round(Util.clamp(newL, minVal, maxVal), step)
		newH = Util.round(Util.clamp(newH, minVal, maxVal), step)
		if newL > newH then
			newL, newH = newH, newL
		end

		local changed = (lowVal ~= newL or highVal ~= newH)
		lowVal = newL
		highVal = newH
		syncVisuals(true)

		local resTbl = { lowVal, highVal }
		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, resTbl, silent)
		end
		if not silent then
			control.Changed:Fire(resTbl)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					resTbl
				)
			end
		end
		return changed
	end

	local activeThumb = nil
	local moveConn = nil
	local releaseConn = nil

	local function updateDragging(input)
		local absX = track.AbsolutePosition.X
		local absW = track.AbsoluteSize.X
		if absW <= 0 then
			return
		end
		local rel = math.clamp((input.Position.X - absX) / absW, 0, 1)
		local raw = minVal + (maxVal - minVal) * rel
		local rounded = Util.round(Util.clamp(raw, minVal, maxVal), step)

		if activeThumb == "low" then
			setValue(math.min(rounded, highVal), highVal, false)
		elseif activeThumb == "high" then
			setValue(lowVal, math.max(rounded, lowVal), false)
		end
	end

	local function startDragging(input)
		if control:IsLocked() then
			return
		end
		local absX = track.AbsolutePosition.X
		local absW = track.AbsoluteSize.X
		local rel = math.clamp((input.Position.X - absX) / math.max(1, absW), 0, 1)
		local lowRatio = getRatio(lowVal)
		local highRatio = getRatio(highVal)

		if math.abs(rel - lowRatio) <= math.abs(rel - highRatio) then
			activeThumb = "low"
			Animator.spring(knobLow, "Size", UDim2.fromOffset(17, 17), { frequency = 22, damping = 0.82 })
		else
			activeThumb = "high"
			Animator.spring(knobHigh, "Size", UDim2.fromOffset(17, 17), { frequency = 22, damping = 0.82 })
		end

		updateDragging(input)

		if moveConn then
			moveConn:Disconnect()
		end
		if releaseConn then
			releaseConn:Disconnect()
		end

		moveConn = Services.UserInputService.InputChanged:Connect(function(moveInput)
			if
				activeThumb
				and (
					moveInput.UserInputType == Enum.UserInputType.MouseMovement
					or moveInput.UserInputType == Enum.UserInputType.Touch
				)
			then
				updateDragging(moveInput)
			end
		end)

		releaseConn = Services.UserInputService.InputEnded:Connect(function(endInput)
			if
				endInput.UserInputType == Enum.UserInputType.MouseButton1
				or endInput.UserInputType == Enum.UserInputType.Touch
			then
				activeThumb = nil
				Animator.spring(knobLow, "Size", UDim2.fromOffset(14, 14), { frequency = 20, damping = 0.85 })
				Animator.spring(knobHigh, "Size", UDim2.fromOffset(14, 14), { frequency = 20, damping = 0.85 })
				if moveConn then
					moveConn:Disconnect()
					moveConn = nil
				end
				if releaseConn then
					releaseConn:Disconnect()
					releaseConn = nil
				end
			end
		end)
	end

	track.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			startDragging(input)
		end
	end)

	function control:Get()
		return { lowVal, highVal }
	end

	function control:Set(tbl, silent)
		if type(tbl) == "table" then
			setValue(tbl[1], tbl[2], silent)
		end
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncVisuals(false)
	return control
end

return RangeSlider
end

-- [[ Module: Elements/Dropdown ]]
__modules["Elements/Dropdown"] = function(require)
local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Popover = require("Components/Popover")
local RowBase = require("Components/RowBase")

local Dropdown = {}

function Dropdown.create(section, opts)
	opts = opts or {}
	local isMulti = opts.Multi == true
	local allowNone = opts.AllowNone == true
	local isPlayerList = (opts.Options == "Players" or opts.PlayerList == true)

	local function getRawOptions()
		if isPlayerList then
			local list = {}
			for _, p in ipairs(Services.Players:GetPlayers()) do
				table.insert(list, p.Name)
			end
			table.sort(list)
			return list
		end
		if type(opts.Options) == "table" then
			local list = {}
			for _, v in ipairs(opts.Options) do
				table.insert(list, tostring(v))
			end
			return list
		end
		return {}
	end

	local selected = nil
	if isMulti then
		selected = {}
		if type(opts.Default) == "table" then
			for _, v in ipairs(opts.Default) do
				table.insert(selected, tostring(v))
			end
		end
	else
		selected = opts.Default ~= nil and tostring(opts.Default) or nil
	end

	local control = RowBase.create(section, {
		Title = opts.Title or "Dropdown",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = selected,
		RightWidth = 165,
		Clickable = false,
	})
	control.Kind = "Dropdown"

	local triggerBtn = Creator.new("TextButton", {
		Name = "TriggerButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(160, 28),
		BackgroundColor3 = ThemeManager:Get("ControlBg"),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = control.RightSlot,
	}, {
		Creator.corner(8),
		Creator.stroke("Outline", 1, 0),
	})

	local valueLabel = Creator.new("TextLabel", {
		Name = "SelectedText",
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
		ThemeBind = { TextColor3 = "Text" },
		Parent = triggerBtn,
	})

	local chevron = Creator.new("ImageLabel", {
		Name = "Chevron",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = Icons.resolve("chevron-down") or "",
		ZIndex = 7,
		ThemeBind = { ImageColor3 = "TextSecondary" },
		Parent = triggerBtn,
	})

	local function formatDisplay()
		if isMulti then
			local count = type(selected) == "table" and #selected or 0
			if count == 0 then
				return "Select..."
			elseif count == 1 then
				return tostring(selected[1])
			else
				return string.format("%d Selected", count)
			end
		else
			if selected == nil or selected == "" then
				return "Select..."
			end
			return tostring(selected)
		end
	end

	local function syncDisplay()
		valueLabel.Text = formatDisplay()
	end

	local function isSelected(opt)
		if isMulti then
			if type(selected) ~= "table" then
				return false
			end
			for _, v in ipairs(selected) do
				if v == opt then
					return true
				end
			end
			return false
		else
			return selected == opt
		end
	end

	local activePopHandle = nil

	local function openDropdown()
		if control:IsLocked() then
			return
		end
		if activePopHandle then
			Popover.close()
			return
		end

		Animator.tween(chevron, { Rotation = 180 }, 0.16)

		local options = getRawOptions()
		local showSearch = opts.Search == true or (#options > 7)
		local itemHeight = 28
		local padding = 4
		local maxVisible = math.min(6, math.max(1, #options))
		local listHeight = maxVisible * (itemHeight + padding)
		local totalHeight = listHeight + (showSearch and 36 or 0) + 12

		local pop = Popover.open({
			Name = "DropdownPopover",
			Anchor = triggerBtn,
			Width = 190,
			Height = math.clamp(totalHeight, 60, 240),
			OnClose = function()
				activePopHandle = nil
				Animator.tween(chevron, { Rotation = 0 }, 0.16)
			end,
		})
		if not pop then
			return
		end
		activePopHandle = pop

		Creator.padding(6, 6, 6, 6, pop.content)

		local searchBox = nil
		if showSearch then
			local searchContainer = Creator.new("Frame", {
				Name = "SearchBox",
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = ThemeManager:Get("InputBg"),
				LayoutOrder = 1,
				ZIndex = 202,
				ThemeBind = { BackgroundColor3 = "InputBg" },
				Parent = pop.content,
			}, {
				Creator.corner(6),
				Creator.stroke("Border", 1, 0.3),
				Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 8, 0.5, 0),
					Size = UDim2.fromOffset(12, 12),
					Image = Icons.resolve("search") or "",
					ZIndex = 203,
					ThemeBind = { ImageColor3 = "TextMuted" },
				}),
			})

			searchBox = Creator.new("TextBox", {
				Position = UDim2.fromOffset(26, 0),
				Size = UDim2.new(1, -30, 1, 0),
				PlaceholderText = "Search...",
				Font = Enum.Font.BuilderSans,
				TextSize = 12,
				ZIndex = 203,
				ThemeBind = {
					TextColor3 = "Text",
					PlaceholderColor3 = "TextMuted",
				},
				Parent = searchContainer,
			})
		end

		local scroll = Creator.new("ScrollingFrame", {
			Name = "OptionList",
			Size = UDim2.new(1, 0, 1, showSearch and -32 or 0),
			Position = UDim2.fromOffset(0, showSearch and 32 or 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 3,
			ZIndex = 202,
			Parent = pop.content,
		}, {
			Creator.list(
				padding,
				Enum.FillDirection.Vertical,
				Enum.HorizontalAlignment.Left,
				Enum.VerticalAlignment.Top
			),
		})

		local optionRows = {}

		local function renderRows(filterQuery)
			for _, r in ipairs(optionRows) do
				r:Destroy()
			end
			table.clear(optionRows)

			for idx, opt in ipairs(options) do
				local score = 1
				if filterQuery and filterQuery ~= "" then
					score = Util.fuzzyScore(filterQuery, opt)
				end

				if score then
					local checked = isSelected(opt)
					local btn = Creator.new("TextButton", {
						Name = "Option_" .. tostring(opt),
						Size = UDim2.new(1, -2, 0, itemHeight),
						BackgroundColor3 = ThemeManager:Get("RowHover"),
						BackgroundTransparency = checked and 0.85 or 1,
						AutoButtonColor = false,
						LayoutOrder = math.floor(1000 - (score or 0)) + idx,
						ZIndex = 203,
						Parent = scroll,
					}, {
						Creator.corner(6),
					})

					local label = Creator.new("TextLabel", {
						Position = UDim2.fromOffset(8, 0),
						Size = UDim2.new(1, -32, 1, 0),
						Font = Enum.Font.BuilderSans,
						TextSize = 13,
						Text = opt,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ZIndex = 204,
						TextColor3 = ThemeManager:Get(checked and "Accent" or "Text"),
						Parent = btn,
					})

					local checkImg = Creator.new("ImageLabel", {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -8, 0.5, 0),
						Size = UDim2.fromOffset(13, 13),
						Image = Icons.resolve("check") or "",
						Visible = checked,
						ZIndex = 204,
						ThemeBind = { ImageColor3 = "Accent" },
						Parent = btn,
					})

					btn.MouseEnter:Connect(function()
						Animator.tween(btn, { BackgroundTransparency = 0.5 }, 0.12)
					end)
					btn.MouseLeave:Connect(function()
						Animator.tween(btn, { BackgroundTransparency = checked and 0.85 or 1 }, 0.14)
					end)

					btn.Activated:Connect(function()
						if isMulti then
							local foundIdx = nil
							for i, v in ipairs(selected) do
								if v == opt then
									foundIdx = i
									break
								end
							end
							if foundIdx then
								table.remove(selected, foundIdx)
							else
								table.insert(selected, opt)
							end
							checked = not checked
							checkImg.Visible = checked
							label.TextColor3 = ThemeManager:Get(checked and "Accent" or "Text")
							control:Set(selected, false)
						else
							if allowNone and selected == opt then
								control:Set(nil, false)
							else
								control:Set(opt, false)
							end
							Popover.close()
						end
					end)

					table.insert(optionRows, btn)
				end
			end
		end

		renderRows(nil)

		if searchBox then
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				renderRows(searchBox.Text)
			end)
		end
	end

	triggerBtn.Activated:Connect(openDropdown)

	local function setValue(newVal, silent)
		if isMulti then
			local tbl = {}
			if type(newVal) == "table" then
				for _, v in ipairs(newVal) do
					table.insert(tbl, tostring(v))
				end
			end
			selected = tbl
		else
			selected = newVal ~= nil and tostring(newVal) or nil
		end
		syncDisplay()

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, selected, silent)
		end
		if not silent then
			control.Changed:Fire(selected)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					selected
				)
			end
		end
	end

	function control:Get()
		return selected
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	function control:Refresh(newOptions, keepSelection)
		if type(newOptions) == "table" then
			opts.Options = newOptions
		end
		if not keepSelection then
			setValue(isMulti and {} or nil, true)
		else
			syncDisplay()
		end
	end

	if isPlayerList then
		Services.Players.PlayerAdded:Connect(function()
			if activePopHandle then
				openDropdown()
			end
		end)
		Services.Players.PlayerRemoving:Connect(function(player)
			if not isMulti and selected == player.Name then
				setValue(nil, false)
			elseif isMulti and type(selected) == "table" then
				for i, v in ipairs(selected) do
					if v == player.Name then
						table.remove(selected, i)
						setValue(selected, false)
						break
					end
				end
			end
			if activePopHandle then
				openDropdown()
			end
		end)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncDisplay()
	return control
end

return Dropdown
end

-- [[ Module: Elements/Input ]]
__modules["Elements/Input"] = function(require)
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local RowBase = require("Components/RowBase")

local Input = {}

function Input.create(section, opts)
	opts = opts or {}
	local isNumeric = opts.Numeric == true
	local maxLength = tonumber(opts.MaxLength)
	local finishedOnly = opts.Finished == true
	local pattern = opts.Pattern

	local initial = opts.Default ~= nil and tostring(opts.Default) or ""
	if isNumeric then
		initial = initial:gsub("[^%d.-]", "")
	end
	if maxLength and #initial > maxLength then
		initial = initial:sub(1, maxLength)
	end
	local currentText = initial

	local control = RowBase.create(section, {
		Title = opts.Title or "Input",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = currentText,
		RightWidth = 175,
		Clickable = false,
	})
	control.Kind = "Input"

	local container = Creator.new("Frame", {
		Name = "InputContainer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(175, 30),
		BackgroundColor3 = ThemeManager:Get("InputBg"),
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "InputBg" },
		Parent = control.RightSlot,
	}, {
		Creator.corner(10),
	})

	local stroke = Creator.stroke("Outline", 2, 0, container)

	local clearBtn = Creator.new("ImageButton", {
		Name = "ClearButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Image = Icons.resolve("x") or "",
		Visible = #currentText > 0,
		ZIndex = 8,
		ThemeBind = { ImageColor3 = "TextMuted" },
		Parent = container,
	})

	local textBox = Creator.new("TextBox", {
		Name = "TextBox",
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Font = Enum.Font.BuilderSans,
		TextSize = 13,
		Text = currentText,
		PlaceholderText = opts.Placeholder or "Type here...",
		ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
		ThemeBind = {
			TextColor3 = "Text",
			PlaceholderColor3 = "TextMuted",
		},
		Parent = container,
	})

	local function shakeError()
		stroke.Color = ThemeManager:Get("Error")
		stroke.Transparency = 0
		local origPos = container.Position
		task.spawn(function()
			for _ = 1, 3 do
				container.Position = origPos + UDim2.fromOffset(4, 0)
				task.wait(0.04)
				container.Position = origPos + UDim2.fromOffset(-4, 0)
				task.wait(0.04)
			end
			container.Position = origPos
			Animator.tween(stroke, { Color = ThemeManager:Get("Border"), Transparency = 0.35 }, 0.25)
		end)
	end

	local function setValue(val, silent)
		val = tostring(val or "")
		if isNumeric then
			val = val:gsub("[^%d.-]", "")
		end
		if maxLength and #val > maxLength then
			val = val:sub(1, maxLength)
		end

		local changed = (currentText ~= val)
		currentText = val
		textBox.Text = currentText
		clearBtn.Visible = #currentText > 0

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, currentText, silent)
		end
		if not silent then
			control.Changed:Fire(currentText)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					currentText
				)
			end
		end
		return changed
	end

	textBox.Focused:Connect(function()
		if control:IsLocked() then
			textBox:ReleaseFocus()
			return
		end
		Animator.tween(stroke, { Color = ThemeManager:Get("Accent"), Transparency = 0 }, 0.15)
	end)

	textBox.FocusLost:Connect(function()
		Animator.tween(stroke, { Color = ThemeManager:Get("Border"), Transparency = 0.35 }, 0.15)
		local text = textBox.Text
		if isNumeric then
			text = text:gsub("[^%d.-]", "")
		end
		if maxLength and #text > maxLength then
			text = text:sub(1, maxLength)
		end

		if pattern and #text > 0 then
			local ok, matched = pcall(function()
				return string.match(text, pattern)
			end)
			if not ok or not matched then
				shakeError()
				return
			end
		end

		setValue(text, false)
	end)

	if not finishedOnly then
		textBox:GetPropertyChangedSignal("Text"):Connect(function()
			local raw = textBox.Text
			if isNumeric then
				local filtered = raw:gsub("[^%d.-]", "")
				if filtered ~= raw then
					textBox.Text = filtered
					raw = filtered
				end
			end
			if maxLength and #raw > maxLength then
				raw = raw:sub(1, maxLength)
				textBox.Text = raw
			end
			clearBtn.Visible = #raw > 0
			if currentText ~= raw then
				currentText = raw
				if control.Flag and control.Window and control.Window.Flags then
					control.Window.Flags:_setRaw(control.Flag, currentText, false)
				end
				control.Changed:Fire(currentText)
				if type(opts.Callback) == "function" then
					task.spawn(
						Util.safeCall,
						control.Title,
						opts.Callback,
						control.Window and control.Window._notifyError,
						currentText
					)
				end
			end
		end)
	end

	clearBtn.Activated:Connect(function()
		if control:IsLocked() then
			return
		end
		setValue("", false)
	end)

	function control:Get()
		return currentText
	end

	function control:Set(str, silent)
		setValue(str, silent)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	return control
end

return Input
end

-- [[ Module: Elements/Keybind ]]
__modules["Elements/Keybind"] = function(require)
local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local RowBase = require("Components/RowBase")

local Keybind = {}

local function parseKey(key)
	if key == nil or key == "" or key == "None" then
		return nil
	end
	if typeof(key) == "EnumItem" then
		return key
	end
	if type(key) == "string" then
		local ok, item = pcall(function()
			return Enum.KeyCode[key]
		end)
		if ok and item then
			return item
		end
		local okUser, itemUser = pcall(function()
			return Enum.UserInputType[key]
		end)
		if okUser and itemUser then
			return itemUser
		end
	end
	return nil
end

function Keybind.create(section, opts)
	opts = opts or {}
	local currentKey = parseKey(opts.Default or opts.Key)
	local mode = opts.Mode or "Toggle" -- "Toggle" | "Hold" | "Always"
	local allowModeChange = opts.AllowModeChange ~= false
	local active = mode == "Always"
	local listening = false

	local control = RowBase.create(section, {
		Title = opts.Title or "Keybind",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = currentKey and currentKey.Name or "None",
		RightWidth = 135,
		Clickable = false,
	})
	control.Kind = "Keybind"

	local modePill = Creator.new("TextButton", {
		Name = "ModePill",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -78, 0.5, 0),
		Size = UDim2.fromOffset(52, 22),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 11,
		Text = mode,
		AutoButtonColor = false,
		ZIndex = 6,
		ThemeBind = {
			BackgroundColor3 = "ControlBg",
			TextColor3 = "TextSecondary",
		},
		Parent = control.RightSlot,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.35),
	})

	local keyBtn = Creator.new("TextButton", {
		Name = "KeyButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(74, 24),
		Font = Enum.Font.RobotoMono,
		TextSize = 12,
		Text = Util.formatKeyName(currentKey),
		AutoButtonColor = false,
		ZIndex = 6,
		ThemeBind = {
			BackgroundColor3 = "ControlBg",
			TextColor3 = "Text",
		},
		Parent = control.RightSlot,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.35),
	})

	local function syncVisuals()
		keyBtn.Text = listening and "..." or Util.formatKeyName(currentKey)
		modePill.Text = mode
		keyBtn.TextColor3 = ThemeManager:Get(listening and "Accent" or "Text")
	end

	if allowModeChange then
		modePill.Activated:Connect(function()
			if control:IsLocked() then
				return
			end
			if mode == "Toggle" then
				mode = "Hold"
			elseif mode == "Hold" then
				mode = "Always"
			else
				mode = "Toggle"
			end
			active = (mode == "Always")
			syncVisuals()
			if control.Window and control.Window._updateKeybindEntry then
				control.Window:_updateKeybindEntry(control)
			end
		end)
	else
		modePill.Visible = false
		keyBtn.Position = UDim2.new(1, 0, 0.5, 0)
	end

	keyBtn.Activated:Connect(function()
		if control:IsLocked() then
			return
		end
		listening = true
		syncVisuals()
	end)

	Services.UserInputService.InputBegan:Connect(function(input, processed)
		if not control.Row.Parent then
			return
		end
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
					control:SetKey(nil)
				else
					control:SetKey(input.KeyCode)
				end
				syncVisuals()
			elseif
				input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3
			then
				listening = false
				control:SetKey(input.UserInputType)
				syncVisuals()
			end
			return
		end

		if processed or not currentKey or control:IsLocked() then
			return
		end
		if Services.UserInputService:GetFocusedTextBox() ~= nil then
			return
		end

		if input.KeyCode == currentKey or input.UserInputType == currentKey then
			if mode == "Toggle" then
				active = not active
			else
				active = true
			end
			if control.Window and control.Window._updateKeybindEntry then
				control.Window:_updateKeybindEntry(control)
			end
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					active,
					currentKey
				)
			end
			control.Changed:Fire(active, currentKey)
		end
	end)

	Services.UserInputService.InputEnded:Connect(function(input)
		if not control.Row.Parent or control:IsLocked() or not currentKey then
			return
		end
		if mode == "Hold" and (input.KeyCode == currentKey or input.UserInputType == currentKey) then
			active = false
			if control.Window and control.Window._updateKeybindEntry then
				control.Window:_updateKeybindEntry(control)
			end
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					false,
					currentKey
				)
			end
			control.Changed:Fire(false, currentKey)
		end
	end)

	function control:Get()
		return currentKey
	end

	function control:GetKey()
		return currentKey
	end

	function control:SetKey(newKey, silent)
		currentKey = parseKey(newKey)
		syncVisuals()
		local keyName = currentKey and currentKey.Name or "None"
		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, keyName, silent)
		end
		if control.Window and control.Window._updateKeybindEntry then
			control.Window:_updateKeybindEntry(control)
		end
		if not silent then
			control.Changed:Fire(active, currentKey)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					active,
					currentKey
				)
			end
		end
	end

	function control:Set(newKey, silent)
		self:SetKey(newKey, silent)
	end

	function control:GetMode()
		return mode
	end

	function control:SetMode(newMode)
		if newMode == "Toggle" or newMode == "Hold" or newMode == "Always" then
			mode = newMode
			active = (mode == "Always")
			syncVisuals()
			if control.Window and control.Window._updateKeybindEntry then
				control.Window:_updateKeybindEntry(control)
			end
		end
	end

	function control:IsActive()
		return active
	end

	if control.Window and control.Window._registerKeybindEntry then
		control.Window:_registerKeybindEntry(control)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncVisuals()
	return control
end

return Keybind
end

-- [[ Module: Elements/ColorPicker ]]
__modules["Elements/ColorPicker"] = function(require)
local Services = require("Core/Services")
local Env = require("Core/Env")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local Themes = require("Theme/Themes")
local ThemeManager = require("Theme/ThemeManager")
local Popover = require("Components/Popover")
local RowBase = require("Components/RowBase")

local ColorPicker = {}

local function normalizeColor(val, fallback)
	if typeof(val) == "Color3" then
		return val
	elseif type(val) == "string" then
		return Util.hexToColor(val) or fallback
	elseif type(val) == "table" then
		if val.hex then
			return Util.hexToColor(val.hex) or fallback
		elseif val[1] and val[2] and val[3] then
			local r, g, b = tonumber(val[1]) or 255, tonumber(val[2]) or 255, tonumber(val[3]) or 255
			if r <= 1 and g <= 1 and b <= 1 then
				return Color3.new(r, g, b)
			end
			return Color3.fromRGB(r, g, b)
		end
	end
	return fallback
end

function ColorPicker.create(section, opts)
	opts = opts or {}
	local defaultColor = normalizeColor(opts.Default, Color3.fromRGB(10, 132, 255))
	local currentColor = defaultColor
	local h, s, v = currentColor:ToHSV()
	local rainbow = false
	local rainbowConn = nil

	local control = RowBase.create(section, {
		Title = opts.Title or "Color Picker",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = currentColor,
		RightWidth = 116,
		Clickable = false,
	})
	control.Kind = "ColorPicker"

	local hexLabel = Creator.new("TextLabel", {
		Name = "HexText",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -42, 0.5, 0),
		Size = UDim2.fromOffset(70, 22),
		Font = Enum.Font.RobotoMono,
		TextSize = 11,
		Text = Util.colorToHex(currentColor),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 6,
		ThemeBind = { TextColor3 = "TextSecondary" },
		Parent = control.RightSlot,
	})

	local swatchBtn = Creator.new("TextButton", {
		Name = "Swatch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(34, 22),
		BackgroundColor3 = currentColor,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		Parent = control.RightSlot,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.2),
	})

	local activeUIUpdater = nil

	local function setValue(newCol, silent, fromHSV)
		if not fromHSV then
			currentColor = normalizeColor(newCol, currentColor)
			h, s, v = currentColor:ToHSV()
		else
			currentColor = Color3.fromHSV(h, s, v)
		end
		swatchBtn.BackgroundColor3 = currentColor
		hexLabel.Text = Util.colorToHex(currentColor)
		if activeUIUpdater then
			activeUIUpdater()
		end

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, currentColor, silent)
		end
		if not silent then
			control.Changed:Fire(currentColor)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					currentColor
				)
			end
		end
	end

	local function setRainbow(on)
		rainbow = on == true
		if rainbowConn then
			rainbowConn:Disconnect()
			rainbowConn = nil
		end
		if rainbow then
			rainbowConn = Services.RunService.Heartbeat:Connect(function(dt)
				if not control.Row.Parent then
					setRainbow(false)
					return
				end
				h = (h + dt * 0.18) % 1
				setValue(nil, false, true)
			end)
		end
	end

	local openPop = nil
	swatchBtn.Activated:Connect(function()
		if control:IsLocked() then
			return
		end
		if openPop then
			Popover.close()
			return
		end

		local pop = Popover.open({
			Name = "ColorPickerPopover",
			Anchor = swatchBtn,
			Width = 228,
			Height = 238,
			OnClose = function()
				openPop = nil
				activeUIUpdater = nil
			end,
		})
		if not pop then
			return
		end
		openPop = pop
		Creator.padding(10, 12, 10, 12, pop.content)

		-- 1. SV Square (204 x 116)
		local svBox = Creator.new("TextButton", {
			Name = "SVSquare",
			Size = UDim2.new(1, 0, 0, 114),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 202,
			Parent = pop.content,
		}, {
			Creator.corner(7),
			Creator.stroke("Border", 1, 0.3),
		})

		-- White -> Transparent horizontal saturation overlay
		Creator.new("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 203,
			Parent = svBox,
		}, {
			Creator.corner(7),
			Creator.new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})

		-- Transparent -> Black vertical value overlay
		Creator.new("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			ZIndex = 204,
			Parent = svBox,
		}, {
			Creator.corner(7),
			Creator.new("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				}),
			}),
		})

		local svCursor = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(s, 1 - v),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = currentColor,
			ZIndex = 205,
			Parent = svBox,
		}, {
			Creator.corner(UDim.new(1, 0)),
			Creator.new("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 2,
			}),
		})

		-- 2. Hue Rainbow Bar (204 x 14)
		local hueBar = Creator.new("TextButton", {
			Name = "HueBar",
			Position = UDim2.fromOffset(0, 124),
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 202,
			Parent = pop.content,
		}, {
			Creator.corner(UDim.new(1, 0)),
			Creator.stroke("Border", 1, 0.35),
			Creator.new("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
				}),
			}),
		})

		local hueKnob = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(h, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			ZIndex = 204,
			Parent = hueBar,
		}, {
			Creator.corner(UDim.new(1, 0)),
			Creator.new("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 2,
			}),
		})

		-- 3. Hex Input + Copy + Rainbow Row
		local hexBox = Creator.new("TextBox", {
			Position = UDim2.fromOffset(0, 148),
			Size = UDim2.fromOffset(88, 24),
			Font = Enum.Font.RobotoMono,
			TextSize = 12,
			Text = Util.colorToHex(currentColor),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 203,
			ThemeBind = {
				BackgroundColor3 = "InputBg",
				TextColor3 = "Text",
			},
			Parent = pop.content,
		}, {
			Creator.corner(6),
			Creator.stroke("Border", 1, 0.35),
		})

		local copyBtn = Creator.new("TextButton", {
			Position = UDim2.fromOffset(94, 148),
			Size = UDim2.fromOffset(48, 24),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 11,
			Text = "Copy",
			ZIndex = 203,
			ThemeBind = {
				BackgroundColor3 = "ControlBg",
				TextColor3 = "TextSecondary",
			},
			Parent = pop.content,
		}, {
			Creator.corner(6),
			Creator.stroke("Border", 1, 0.35),
		})

		local rainbowBtn = Creator.new("TextButton", {
			Position = UDim2.fromOffset(148, 148),
			Size = UDim2.fromOffset(56, 24),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 11,
			Text = "Rainbow",
			ZIndex = 203,
			BackgroundColor3 = ThemeManager:Get(rainbow and "Accent" or "ControlBg"),
			TextColor3 = ThemeManager:Get(rainbow and "OnAccent" or "TextSecondary"),
			Parent = pop.content,
		}, {
			Creator.corner(6),
			Creator.stroke("Border", 1, 0.35),
		})

		-- 4. Preset Swatches Row
		local swatchRow = Creator.new("Frame", {
			Position = UDim2.fromOffset(0, 182),
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			ZIndex = 203,
			Parent = pop.content,
		}, {
			Creator.list(
				6,
				Enum.FillDirection.Horizontal,
				Enum.HorizontalAlignment.Left,
				Enum.VerticalAlignment.Center
			),
		})

		for idx, accentName in ipairs(Themes.AccentOrder) do
			local presetColor = Themes.Accents[accentName]
			local pBtn = Creator.new("TextButton", {
				Size = UDim2.fromOffset(20, 20),
				BackgroundColor3 = presetColor,
				Text = "",
				LayoutOrder = idx,
				ZIndex = 204,
				Parent = swatchRow,
			}, {
				Creator.corner(UDim.new(1, 0)),
				Creator.stroke("Border", 1, 0.35),
			})
			pBtn.Activated:Connect(function()
				setRainbow(false)
				rainbowBtn.BackgroundColor3 = ThemeManager:Get("ControlBg")
				rainbowBtn.TextColor3 = ThemeManager:Get("TextSecondary")
				setValue(presetColor, false, false)
			end)
		end

		activeUIUpdater = function()
			if not svBox.Parent then
				return
			end
			svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svCursor.Position = UDim2.fromScale(s, 1 - v)
			svCursor.BackgroundColor3 = currentColor
			hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
			hueKnob.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			if not hexBox:IsFocused() then
				hexBox.Text = Util.colorToHex(currentColor)
			end
		end

		-- Drag SV & Hue
		local dragSV = false
		local dragHue = false
		local moveConn, endConn

		local function updateSV(pos)
			local absP = svBox.AbsolutePosition
			local absS = svBox.AbsoluteSize
			s = math.clamp((pos.X - absP.X) / math.max(1, absS.X), 0, 1)
			v = 1 - math.clamp((pos.Y - absP.Y) / math.max(1, absS.Y), 0, 1)
			setValue(nil, false, true)
		end

		local function updateHue(pos)
			local absP = hueBar.AbsolutePosition
			local absS = hueBar.AbsoluteSize
			h = math.clamp((pos.X - absP.X) / math.max(1, absS.X), 0, 1)
			setValue(nil, false, true)
		end

		local function bindDrag(startPos, isHue)
			if isHue then
				dragHue = true
				updateHue(startPos)
			else
				dragSV = true
				updateSV(startPos)
			end
			if moveConn then
				moveConn:Disconnect()
			end
			if endConn then
				endConn:Disconnect()
			end
			moveConn = Services.UserInputService.InputChanged:Connect(function(inp)
				if
					inp.UserInputType == Enum.UserInputType.MouseMovement
					or inp.UserInputType == Enum.UserInputType.Touch
				then
					if dragSV then
						updateSV(inp.Position)
					elseif dragHue then
						updateHue(inp.Position)
					end
				end
			end)
			endConn = Services.UserInputService.InputEnded:Connect(function(inp)
				if
					inp.UserInputType == Enum.UserInputType.MouseButton1
					or inp.UserInputType == Enum.UserInputType.Touch
				then
					dragSV = false
					dragHue = false
					if moveConn then
						moveConn:Disconnect()
						moveConn = nil
					end
					if endConn then
						endConn:Disconnect()
						endConn = nil
					end
				end
			end)
		end

		svBox.InputBegan:Connect(function(inp)
			if
				inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch
			then
				bindDrag(inp.Position, false)
			end
		end)

		hueBar.InputBegan:Connect(function(inp)
			if
				inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch
			then
				bindDrag(inp.Position, true)
			end
		end)

		hexBox.FocusLost:Connect(function()
			local parsed = Util.hexToColor(hexBox.Text)
			if parsed then
				setValue(parsed, false, false)
			else
				hexBox.Text = Util.colorToHex(currentColor)
			end
		end)

		copyBtn.Activated:Connect(function()
			Env.setClipboard(Util.colorToHex(currentColor))
			copyBtn.Text = "Copied"
			task.delay(1.2, function()
				if copyBtn.Parent then
					copyBtn.Text = "Copy"
				end
			end)
		end)

		rainbowBtn.Activated:Connect(function()
			setRainbow(not rainbow)
			rainbowBtn.BackgroundColor3 = ThemeManager:Get(rainbow and "Accent" or "ControlBg")
			rainbowBtn.TextColor3 = ThemeManager:Get(rainbow and "OnAccent" or "TextSecondary")
		end)
	end)

	function control:Get()
		return currentColor
	end

	function control:Set(col, silent)
		setValue(col, silent, false)
	end

	function control:SetRainbow(on)
		setRainbow(on)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	return control
end

return ColorPicker
end

-- [[ Module: Elements/Segmented ]]
__modules["Elements/Segmented"] = function(require)
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local RowBase = require("Components/RowBase")

local Segmented = {}

function Segmented.create(section, opts)
	opts = opts or {}
	local options = type(opts.Options) == "table" and #opts.Options > 0 and opts.Options or { "One", "Two" }
	local selected = opts.Default or options[1]

	local control = RowBase.create(section, {
		Title = opts.Title or "Segmented",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = selected,
		RightWidth = 192,
		Clickable = false,
	})
	control.Kind = "Segmented"

	local track = Creator.new("Frame", {
		Name = "SegmentTrack",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(186, 28),
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "InputBg" },
		Parent = control.RightSlot,
	}, {
		Creator.corner(8),
		Creator.stroke("Outline", 1, 0),
		Creator.padding(2, 2, 2, 2),
	})

	local thumb = Creator.new("Frame", {
		Name = "Thumb",
		Size = UDim2.new(1 / #options, 0, 1, 0),
		ZIndex = 7,
		ThemeBind = { BackgroundColor3 = "Accent" },
		Parent = track,
	}, {
		Creator.corner(6),
	})

	local btnHolder = Creator.new("Frame", {
		Name = "Buttons",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 8,
		Parent = track,
	})

	local buttons = {}

	local function syncVisuals(animate)
		local n = math.max(1, #options)
		local activeIndex = 1
		for i, opt in ipairs(options) do
			if tostring(opt) == tostring(selected) then
				activeIndex = i
				break
			end
		end

		local targetSize = UDim2.new(1 / n, 0, 1, 0)
		local targetPos = UDim2.new((activeIndex - 1) / n, 0, 0, 0)
		if animate ~= false then
			Animator.spring(thumb, "Size", targetSize, { frequency = 20, damping = 0.85 })
			Animator.spring(thumb, "Position", targetPos, { frequency = 20, damping = 0.85 })
		else
			thumb.Size = targetSize
			thumb.Position = targetPos
		end

		for i, btn in ipairs(buttons) do
			local isCurrent = (i == activeIndex)
			btn.Font = isCurrent and Enum.Font.BuilderSansBold or Enum.Font.BuilderSansMedium
			btn.TextColor3 = ThemeManager:Get(isCurrent and "OnAccent" or "TextSecondary")
		end
	end

	local function setValue(val, silent)
		val = tostring(val or options[1])
		selected = val
		syncVisuals(true)

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, selected, silent)
		end
		if not silent then
			control.Changed:Fire(selected)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					selected
				)
			end
		end
	end

	local function rebuildButtons()
		for _, b in ipairs(buttons) do
			b:Destroy()
		end
		table.clear(buttons)
		local n = math.max(1, #options)
		for i, opt in ipairs(options) do
			local label = tostring(opt)
			local btn = Creator.new("TextButton", {
				Name = "Seg_" .. label,
				Position = UDim2.new((i - 1) / n, 0, 0, 0),
				Size = UDim2.new(1 / n, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.BuilderSansMedium,
				TextSize = 13,
				Text = label,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 9,
				Parent = btnHolder,
			})
			btn.Activated:Connect(function()
				if control:IsLocked() then
					return
				end
				setValue(label, false)
			end)
			buttons[i] = btn
		end
		syncVisuals(false)
	end

	ThemeManager.Changed:Connect(function()
		syncVisuals(false)
	end)

	function control:Get()
		return selected
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	function control:Refresh(newOpts)
		if type(newOpts) == "table" and #newOpts > 0 then
			options = newOpts
			selected = options[1]
			rebuildButtons()
		end
	end

	rebuildButtons()

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	return control
end

return Segmented
end

-- [[ Module: Elements/Stepper ]]
__modules["Elements/Stepper"] = function(require)
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local RowBase = require("Components/RowBase")

local Stepper = {}

function Stepper.create(section, opts)
	opts = opts or {}
	local minVal = tonumber(opts.Min) or 0
	local maxVal = tonumber(opts.Max) or 100
	local step = tonumber(opts.Step) or 1
	local suffix = opts.Suffix or ""
	local value = Util.round(Util.clamp(tonumber(opts.Default) or minVal, minVal, maxVal), step)

	local control = RowBase.create(section, {
		Title = opts.Title or "Stepper",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = value,
		RightWidth = 136,
		Clickable = false,
	})
	control.Kind = "Stepper"

	local valLabel = Creator.new("TextLabel", {
		Name = "ValueLabel",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -76, 0.5, 0),
		Size = UDim2.fromOffset(58, 22),
		Font = Enum.Font.RobotoMono,
		TextSize = 12,
		Text = tostring(value) .. suffix,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 6,
		ThemeBind = { TextColor3 = "Text" },
		Parent = control.RightSlot,
	})

	local capsule = Creator.new("Frame", {
		Name = "Capsule",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(68, 28),
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = control.RightSlot,
	}, {
		Creator.corner(9),
		Creator.stroke("Outline", 2, 0),
		Creator.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(2, 16),
			ZIndex = 7,
			ThemeBind = { BackgroundColor3 = "Outline" },
		}),
	})

	local minusBtn = Creator.new("TextButton", {
		Name = "Minus",
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansBold,
		TextSize = 15,
		Text = "−",
		ZIndex = 8,
		ThemeBind = { TextColor3 = "Text" },
		Parent = capsule,
	})

	local plusBtn = Creator.new("TextButton", {
		Name = "Plus",
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansBold,
		TextSize = 15,
		Text = "+",
		ZIndex = 8,
		ThemeBind = { TextColor3 = "Text" },
		Parent = capsule,
	})

	local function setValue(newVal, silent)
		newVal = Util.round(Util.clamp(tonumber(newVal) or minVal, minVal, maxVal), step)
		value = newVal
		valLabel.Text = tostring(value) .. suffix

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, value, silent)
		end
		if not silent then
			control.Changed:Fire(value)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					value
				)
			end
		end
	end

	local function bindHold(btn, delta)
		local holding = false
		btn.InputBegan:Connect(function(input)
			if control:IsLocked() then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				holding = true
				setValue(value + delta, false)
				task.spawn(function()
					task.wait(0.38)
					while holding and btn.Parent and not control:IsLocked() do
						setValue(value + delta, false)
						task.wait(0.08)
					end
				end)
			end
		end)
		btn.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				holding = false
			end
		end)
		btn.MouseLeave:Connect(function()
			holding = false
		end)
	end

	bindHold(minusBtn, -step)
	bindHold(plusBtn, step)

	function control:Get()
		return value
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	return control
end

return Stepper
end

-- [[ Module: Elements/RadioGroup ]]
__modules["Elements/RadioGroup"] = function(require)
local Creator = require("Core/Creator")
local Signal = require("Core/Signal")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")

local RadioGroup = {}

function RadioGroup.create(section, opts)
	opts = opts or {}
	local options = type(opts.Options) == "table" and #opts.Options > 0 and opts.Options or { "Option 1", "Option 2" }
	local selected = tostring(opts.Default or options[1])

	local card = Creator.new("Frame", {
		Name = "RadioGroup_" .. tostring(opts.Title or "Radio"),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		ThemeBind = { BackgroundColor3 = "RowBg" },
		Parent = section.Container,
	}, {
		Creator.corner(8),
		Creator.padding(10, 12, 10, 12),
		Creator.list(6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local titleLabel = Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 14,
		Text = tostring(opts.Title or "Select Option"),
		LayoutOrder = 1,
		ZIndex = 4,
		ThemeBind = { TextColor3 = "Text" },
		Parent = card,
	})

	local itemsContainer = Creator.new("Frame", {
		Name = "Items",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 4,
		Parent = card,
	}, {
		Creator.list(4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local locked = false
	local itemNodes = {}

	local control = {
		Kind = "RadioGroup",
		Row = card,
		TitleLabel = titleLabel,
		Section = section,
		Window = section.Window,
		Flag = opts.Flag or opts.Id,
		Title = tostring(opts.Title or "RadioGroup"),
		Default = selected,
		Changed = Signal.new(),
		IsLocked = function()
			return locked
		end,
	}

	local function syncVisuals(animate)
		for _, node in ipairs(itemNodes) do
			local isCurrent = (node.value == selected)
			local ringColor = ThemeManager:Get(isCurrent and "Accent" or "ControlBg")
			local dotSize = isCurrent and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0)
			node.label.TextColor3 = ThemeManager:Get(isCurrent and "Text" or "TextSecondary")
			if animate ~= false then
				Animator.tween(node.ring, { BackgroundColor3 = ringColor }, 0.15)
				Animator.spring(node.dot, "Size", dotSize, { frequency = 20, damping = 0.8 })
			else
				node.ring.BackgroundColor3 = ringColor
				node.dot.Size = dotSize
			end
		end
	end

	local function setValue(val, silent)
		selected = tostring(val or options[1])
		syncVisuals(true)

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, selected, silent)
		end
		if not silent then
			control.Changed:Fire(selected)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					selected
				)
			end
		end
	end

	local function rebuildItems()
		for _, node in ipairs(itemNodes) do
			node.btn:Destroy()
		end
		table.clear(itemNodes)

		for idx, opt in ipairs(options) do
			local valStr = tostring(opt)
			local btn = Creator.new("TextButton", {
				Name = "Radio_" .. valStr,
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				Text = "",
				LayoutOrder = idx,
				ZIndex = 5,
				Parent = itemsContainer,
			})

			local ring = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 2, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				ZIndex = 6,
				Parent = btn,
			}, {
				Creator.corner(UDim.new(1, 0)),
				Creator.stroke("Border", 1, 0.3),
			})

			local dot = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(0, 0),
				ZIndex = 7,
				ThemeBind = { BackgroundColor3 = "OnAccent" },
				Parent = ring,
			}, {
				Creator.corner(UDim.new(1, 0)),
			})

			local lbl = Creator.new("TextLabel", {
				Position = UDim2.fromOffset(26, 0),
				Size = UDim2.new(1, -28, 1, 0),
				Font = Enum.Font.BuilderSans,
				TextSize = 13,
				Text = valStr,
				ZIndex = 6,
				Parent = btn,
			})

			btn.Activated:Connect(function()
				if not locked then
					setValue(valStr, false)
				end
			end)

			itemNodes[#itemNodes + 1] = {
				value = valStr,
				btn = btn,
				ring = ring,
				dot = dot,
				label = lbl,
			}
		end
		syncVisuals(false)
	end

	ThemeManager.Changed:Connect(function()
		syncVisuals(false)
	end)

	function control:Get()
		return selected
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	function control:Refresh(newOpts)
		if type(newOpts) == "table" and #newOpts > 0 then
			options = newOpts
			selected = tostring(options[1])
			rebuildItems()
		end
	end

	function control:OnChanged(fn)
		return self.Changed:Connect(fn)
	end

	function control:SetTitle(t)
		self.Title = tostring(t or "")
		titleLabel.Text = self.Title
	end

	function control:SetVisible(v)
		card.Visible = v == true
	end

	function control:Lock()
		locked = true
	end

	function control:Unlock()
		locked = false
	end

	function control:Highlight()
		Animator.pulseHighlight(card)
	end

	function control:Destroy()
		self.Changed:Destroy()
		card:Destroy()
	end

	rebuildItems()

	if section.Window and section.Window._registerSearchable then
		section.Window:_registerSearchable(control, section)
	end
	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	return control
end

return RadioGroup
end

-- [[ Module: Elements/ProgressBar ]]
__modules["Elements/ProgressBar"] = function(require)
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local Animator = require("Motion/Animator")
local RowBase = require("Components/RowBase")

local ProgressBar = {}

function ProgressBar.create(section, opts)
	opts = opts or {}
	local maxVal = tonumber(opts.Max) or 100
	local suffix = opts.Suffix or "%"
	local current = Util.clamp(tonumber(opts.Default) or 0, 0, maxVal)
	local statusText = opts.StatusText

	local control = RowBase.create(section, {
		Title = opts.Title or "Progress",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		RightWidth = 175,
		Clickable = false,
	})
	control.Kind = "ProgressBar"

	local pctLabel = Creator.new("TextLabel", {
		Name = "StatusText",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Size = UDim2.new(1, 0, 0, 14),
		Font = Enum.Font.RobotoMono,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 6,
		ThemeBind = { TextColor3 = "TextSecondary" },
		Parent = control.RightSlot,
	})

	local track = Creator.new("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, -3),
		Size = UDim2.fromOffset(165, 7),
		ClipsDescendants = true,
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "InputBg" },
		Parent = control.RightSlot,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Border", 1, 0.35),
	})

	local fill = Creator.new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		ZIndex = 7,
		ThemeBind = { BackgroundColor3 = "Accent" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local function sync(animate)
		local ratio = maxVal > 0 and math.clamp(current / maxVal, 0, 1) or 0
		pctLabel.Text = statusText and tostring(statusText) or (tostring(Util.round(current, 1)) .. suffix)
		if animate ~= false then
			Animator.spring(fill, "Size", UDim2.fromScale(ratio, 1), { frequency = 16, damping = 0.85 })
		else
			fill.Size = UDim2.fromScale(ratio, 1)
		end
	end

	function control:Get()
		return current
	end

	function control:Set(val, customStatus)
		current = Util.clamp(tonumber(val) or 0, 0, maxVal)
		if customStatus ~= nil then
			statusText = customStatus
		end
		sync(true)
		self.Changed:Fire(current)
	end

	function control:SetStatus(text)
		statusText = text
		sync(false)
	end

	sync(false)
	return control
end

return ProgressBar
end

-- [[ Module: Elements/Stat ]]
__modules["Elements/Stat"] = function(require)
local Creator = require("Core/Creator")
local RowBase = require("Components/RowBase")

local Stat = {}

function Stat.create(section, opts)
	opts = opts or {}
	local currentVal = tostring(opts.Value or opts.Default or "—")

	local control = RowBase.create(section, {
		Title = opts.Title or "Metric",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		RightWidth = 150,
		MinHeight = 38,
		Clickable = false,
	})
	control.Kind = "Stat"

	local valueLabel = Creator.new("TextLabel", {
		Name = "MetricValue",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.RobotoMono,
		TextSize = 13,
		Text = currentVal,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
		ThemeBind = { TextColor3 = opts.ColorToken or "Accent" },
		Parent = control.RightSlot,
	})

	function control:Get()
		return currentVal
	end

	function control:Set(newVal)
		currentVal = tostring(newVal or "")
		valueLabel.Text = currentVal
		self.Changed:Fire(currentVal)
	end

	control.SetValue = control.Set
	return control
end

return Stat
end

-- [[ Module: Elements/Label ]]
__modules["Elements/Label"] = function(require)
local RowBase = require("Components/RowBase")

local Label = {}

function Label.create(section, opts)
	if type(opts) == "string" then
		opts = { Title = opts }
	end
	opts = opts or {}

	local control = RowBase.create(section, {
		Title = opts.Title or opts.Text or "Label",
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		RightWidth = 0,
		MinHeight = 34,
		TitleColorToken = opts.ColorToken or "TextSecondary",
		Clickable = false,
	})
	control.Kind = "Label"

	function control:Get()
		return self.Title
	end

	function control:Set(newText)
		self:SetTitle(newText)
		self.Changed:Fire(self.Title)
	end

	return control
end

return Label
end

-- [[ Module: Elements/Paragraph ]]
__modules["Elements/Paragraph"] = function(require)
local RowBase = require("Components/RowBase")

local Paragraph = {}

function Paragraph.create(section, opts)
	opts = opts or {}
	local content = tostring(opts.Content or opts.Description or opts.Text or "")

	local control = RowBase.create(section, {
		Title = opts.Title or "Information",
		Description = content,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		RightWidth = 0,
		MinHeight = 48,
		Clickable = false,
	})
	control.Kind = "Paragraph"

	function control:Get()
		return content
	end

	function control:Set(val)
		if type(val) == "table" then
			if val.Title then
				self:SetTitle(val.Title)
			end
			content = tostring(val.Content or val.Description or val.Text or content)
			self:SetDescription(content)
		else
			content = tostring(val or "")
			self:SetDescription(content)
		end
		self.Changed:Fire(content)
	end

	function control:SetContent(text)
		self:Set(text)
	end

	return control
end

return Paragraph
end

-- [[ Module: Elements/Divider ]]
__modules["Elements/Divider"] = function(require)
local Creator = require("Core/Creator")
local Util = require("Core/Util")

local Divider = {}

function Divider.create(section, opts)
	local text = nil
	if type(opts) == "string" then
		text = opts
	elseif type(opts) == "table" then
		text = opts.Text or opts.Title
	end

	local holder = Creator.new("Frame", {
		Name = "Divider",
		Size = UDim2.new(1, 0, 0, text and 20 or 9),
		BackgroundTransparency = 1,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		Parent = section.Container,
	}, {
		Creator.padding(0, 8, 0, 8),
	})

	local label = nil
	local line = nil

	if text and text ~= "" then
		local upperText = string.upper(tostring(text))
		local textW = math.ceil(Util.measureText(upperText, 10, Enum.Font.BuilderSansBold, 400).X) + 12
		label = Creator.new("TextLabel", {
			Name = "Label",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(textW, 14),
			Font = Enum.Font.BuilderSansBold,
			TextSize = 10,
			Text = upperText,
			ZIndex = 4,
			ThemeBind = { TextColor3 = "SectionHeader" },
			Parent = holder,
		})
		line = Creator.new("Frame", {
			Name = "Line",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, textW, 0.5, 0),
			Size = UDim2.new(1, -textW, 0, 1),
			ZIndex = 3,
			ThemeBind = { BackgroundColor3 = "Divider" },
			Parent = holder,
		})
	else
		line = Creator.new("Frame", {
			Name = "Line",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 3,
			ThemeBind = { BackgroundColor3 = "Divider" },
			Parent = holder,
		})
	end

	return {
		Kind = "Divider",
		Row = holder,
		Set = function(_, newText)
			if label and line then
				local upper = string.upper(tostring(newText or ""))
				local w = math.ceil(Util.measureText(upper, 10, Enum.Font.BuilderSansBold, 400).X) + 12
				label.Text = upper
				label.Size = UDim2.fromOffset(w, 14)
				line.Position = UDim2.new(0, w, 0.5, 0)
				line.Size = UDim2.new(1, -w, 0, 1)
			end
		end,
		SetVisible = function(_, vis)
			holder.Visible = vis == true
		end,
		Destroy = function()
			holder:Destroy()
		end,
	}
end

return Divider
end

-- [[ Module: Elements/Image ]]
__modules["Elements/Image"] = function(require)
local Creator = require("Core/Creator")
local Icons = require("Assets/Icons")

local Image = {}

function Image.create(section, opts)
	opts = opts or {}
	local height = tonumber(opts.Height) or 110
	local title = opts.Title

	local card = Creator.new("Frame", {
		Name = "ImageCard",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		ThemeBind = { BackgroundColor3 = "RowBg" },
		Parent = section.Container,
	}, {
		Creator.corner(8),
		Creator.padding(8, 10, 8, 10),
		Creator.list(6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local titleLabel = nil
	if title and title ~= "" then
		titleLabel = Creator.new("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, 0, 0, 16),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 13,
			Text = tostring(title),
			LayoutOrder = 1,
			ZIndex = 4,
			ThemeBind = { TextColor3 = "Text" },
			Parent = card,
		})
	end

	local img = Creator.new("ImageLabel", {
		Name = "BannerImage",
		Size = UDim2.new(1, 0, 0, height),
		Image = Icons.resolve(opts.Image or "sparkles") or "",
		ScaleType = opts.ScaleType or Enum.ScaleType.Fit,
		LayoutOrder = 2,
		ZIndex = 4,
		ThemeBind = { BackgroundColor3 = "InputBg" },
		BackgroundTransparency = 0,
		Parent = card,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.35),
	})

	return {
		Kind = "Image",
		Row = card,
		ImageLabel = img,
		SetImage = function(_, newImg)
			img.Image = Icons.resolve(newImg) or ""
		end,
		SetTitle = function(_, newTitle)
			if titleLabel then
				titleLabel.Text = tostring(newTitle or "")
			end
		end,
		SetVisible = function(_, vis)
			card.Visible = vis == true
		end,
		Destroy = function()
			card:Destroy()
		end,
	}
end

return Image
end

-- [[ Module: Elements/CodeBlock ]]
__modules["Elements/CodeBlock"] = function(require)
local Env = require("Core/Env")
local Creator = require("Core/Creator")
local ThemeManager = require("Theme/ThemeManager")
local Icons = require("Assets/Icons")

local CodeBlock = {}

function CodeBlock.create(section, opts)
	opts = opts or {}
	local codeText = tostring(opts.Code or opts.Text or "")
	local titleText = tostring(opts.Title or "Luau Snippet")

	local card = Creator.new("Frame", {
		Name = "CodeBlock",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		ThemeBind = { BackgroundColor3 = "InputBg" },
		Parent = section.Container,
	}, {
		Creator.corner(8),
		Creator.stroke("Border", 1, 0.25),
		Creator.padding(8, 12, 10, 12),
		Creator.list(6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local topBar = Creator.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		ZIndex = 4,
		Parent = card,
	})

	Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -70, 1, 0),
		Font = Enum.Font.RobotoMono,
		TextSize = 11,
		Text = titleText,
		ZIndex = 5,
		ThemeBind = { TextColor3 = "TextMuted" },
		Parent = topBar,
	})

	local copyBtn = Creator.new("TextButton", {
		Name = "CopyBtn",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(64, 22),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 11,
		Text = "  Copy",
		ZIndex = 5,
		ThemeBind = {
			BackgroundColor3 = "ControlBg",
			TextColor3 = "TextSecondary",
		},
		Parent = topBar,
	}, {
		Creator.corner(5),
		Creator.stroke("Border", 1, 0.35),
		Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.fromOffset(11, 11),
			Image = Icons.resolve("copy") or "",
			ZIndex = 6,
			ThemeBind = { ImageColor3 = "TextSecondary" },
		}),
	})

	local codeLabel = Creator.new("TextLabel", {
		Name = "Code",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.RobotoMono,
		TextSize = 12,
		Text = codeText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
		ZIndex = 4,
		ThemeBind = { TextColor3 = "Text" },
		Parent = card,
	})

	copyBtn.Activated:Connect(function()
		Env.setClipboard(codeText)
		copyBtn.Text = "  Copied"
		copyBtn.TextColor3 = ThemeManager:Get("Success")
		task.delay(1.4, function()
			if copyBtn.Parent then
				copyBtn.Text = "  Copy"
				copyBtn.TextColor3 = ThemeManager:Get("TextSecondary")
			end
		end)
	end)

	return {
		Kind = "CodeBlock",
		Row = card,
		Get = function()
			return codeText
		end,
		Set = function(_, newCode)
			codeText = tostring(newCode or "")
			codeLabel.Text = codeText
		end,
		SetCode = function(_, newCode)
			codeText = tostring(newCode or "")
			codeLabel.Text = codeText
		end,
		SetVisible = function(_, vis)
			card.Visible = vis == true
		end,
		Destroy = function()
			card:Destroy()
		end,
	}
end

return CodeBlock
end

-- [[ Module: Window/Section ]]
__modules["Window/Section"] = function(require)
local Creator = require("Core/Creator")
local Icons = require("Assets/Icons")

local Button = require("Elements/Button")
local Toggle = require("Elements/Toggle")
local Checkbox = require("Elements/Checkbox")
local Slider = require("Elements/Slider")
local RangeSlider = require("Elements/RangeSlider")
local Dropdown = require("Elements/Dropdown")
local Input = require("Elements/Input")
local Keybind = require("Elements/Keybind")
local ColorPicker = require("Elements/ColorPicker")
local Segmented = require("Elements/Segmented")
local Stepper = require("Elements/Stepper")
local RadioGroup = require("Elements/RadioGroup")
local ProgressBar = require("Elements/ProgressBar")
local Stat = require("Elements/Stat")
local Label = require("Elements/Label")
local Paragraph = require("Elements/Paragraph")
local Divider = require("Elements/Divider")
local Image = require("Elements/Image")
local CodeBlock = require("Elements/CodeBlock")

local Section = {}
Section.__index = Section

function Section.new(tab, opts)
	if type(opts) == "string" then
		opts = { Title = opts }
	end
	opts = opts or {}

	local title = tostring(opts.Title or opts.Name or "")
	local order = tab:_nextSectionOrder()

	-- Sleek Bento Section Card
	local card = Creator.new("Frame", {
		Name = "Section_" .. (title ~= "" and title or tostring(order)),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		LayoutOrder = order,
		ZIndex = 2,
		ThemeBind = { BackgroundColor3 = "SectionBg" },
		Parent = tab.Scroll.Frame,
	}, {
		Creator.corner(14),
		Creator.stroke("Outline", 1.2, 0),
		Creator.padding(12, 12, 12, 12),
		Creator.list(8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local showHeader = title ~= "" and not (order == 1 and string.upper(title) == string.upper(tab.Title))
	if showHeader then
		local headerRow = Creator.new("Frame", {
			Name = "CardTitleRow",
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			LayoutOrder = 0,
			ZIndex = 3,
			Parent = card,
		})

		local textOffset = 0
		if opts.Icon then
			textOffset = 22
			Creator.new("ImageLabel", {
				Name = "HeaderIcon",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				Image = Icons.resolve(opts.Icon) or "",
				ZIndex = 4,
				ThemeBind = { ImageColor3 = "Accent" },
				Parent = headerRow,
			})
		end

		Creator.new("TextLabel", {
			Name = "HeaderTitle",
			Position = UDim2.fromOffset(textOffset, 0),
			Size = UDim2.new(1, -textOffset, 1, 0),
			Font = Enum.Font.BuilderSansBold,
			TextSize = 13,
			Text = title,
			ZIndex = 4,
			ThemeBind = { TextColor3 = "SectionHeader" },
			Parent = headerRow,
		})
	end

	local self = setmetatable({
		Title = title,
		Tab = tab,
		Window = tab.Window,
		Root = card,
		Container = card,
		_itemOrder = 0,
	}, Section)

	return self
end

function Section:_nextOrder()
	self._itemOrder += 1
	return self._itemOrder
end

function Section:Button(opts)
	return Button.create(self, opts)
end
Section.AddButton = Section.Button
Section.CreateButton = Section.Button

function Section:Toggle(opts)
	return Toggle.create(self, opts)
end
Section.AddToggle = Section.Toggle
Section.CreateToggle = Section.Toggle

function Section:Checkbox(opts)
	return Checkbox.create(self, opts)
end
Section.AddCheckbox = Section.Checkbox

function Section:Slider(opts)
	return Slider.create(self, opts)
end
Section.AddSlider = Section.Slider
Section.CreateSlider = Section.Slider

function Section:RangeSlider(opts)
	return RangeSlider.create(self, opts)
end
Section.AddRangeSlider = Section.RangeSlider

function Section:Dropdown(opts)
	return Dropdown.create(self, opts)
end
Section.AddDropdown = Section.Dropdown
Section.CreateDropdown = Section.Dropdown

function Section:Input(opts)
	return Input.create(self, opts)
end
Section.AddInput = Section.Input
Section.CreateInput = Section.Input

function Section:Keybind(opts)
	return Keybind.create(self, opts)
end
Section.AddKeybind = Section.Keybind
Section.CreateKeybind = Section.Keybind

function Section:ColorPicker(opts)
	return ColorPicker.create(self, opts)
end
Section.AddColorPicker = Section.ColorPicker
Section.CreateColorPicker = Section.ColorPicker

function Section:Segmented(opts)
	return Segmented.create(self, opts)
end
Section.AddSegmented = Section.Segmented

function Section:Stepper(opts)
	return Stepper.create(self, opts)
end
Section.AddStepper = Section.Stepper

function Section:RadioGroup(opts)
	return RadioGroup.create(self, opts)
end
Section.AddRadioGroup = Section.RadioGroup

function Section:ProgressBar(opts)
	return ProgressBar.create(self, opts)
end
Section.AddProgressBar = Section.ProgressBar

function Section:Stat(opts)
	return Stat.create(self, opts)
end
Section.AddStat = Section.Stat

function Section:Label(opts)
	return Label.create(self, opts)
end
Section.AddLabel = Section.Label
Section.CreateLabel = Section.Label

function Section:Paragraph(opts)
	return Paragraph.create(self, opts)
end
Section.AddParagraph = Section.Paragraph
Section.CreateParagraph = Section.Paragraph

function Section:Divider(opts)
	return Divider.create(self, opts)
end
Section.AddDivider = Section.Divider

function Section:Image(opts)
	return Image.create(self, opts)
end
Section.AddImage = Section.Image

function Section:CodeBlock(opts)
	return CodeBlock.create(self, opts)
end
Section.AddCodeBlock = Section.CodeBlock

return Section
end

-- [[ Module: Window/Tab ]]
__modules["Window/Tab"] = function(require)
local Util = require("Core/Util")
local Scroll = require("Components/Scroll")
local Popover = require("Components/Popover")
local Section = require("Window/Section")

local Tab = {}
Tab.__index = Tab

function Tab.new(window, opts)
	if type(opts) == "string" then
		opts = { Title = opts }
	end
	opts = opts or {}

	local title = tostring(opts.Title or opts.Name or "Tab")
	local icon = opts.Icon or "layers"
	local badge = opts.Badge

	local scroll = Scroll.create({
		Name = "Page_" .. title,
		Parent = window.PagesContainer,
		Visible = false,
		Spacing = 10,
		Padding = { Top = 0, Right = 2, Bottom = 12, Left = 0 },
	})

	scroll.Scrolled:Connect(function()
		Popover.close()
	end)

	local self = setmetatable({
		Title = title,
		Icon = icon,
		Window = window,
		Scroll = scroll,
		Page = scroll.Frame,
		Sections = {},
		_sectionOrder = 0,
		_defaultSection = nil,
	}, Tab)

	function self:ApplyFilter(rawQuery)
		local q = tostring(rawQuery or ""):gsub("^%s*(.-)%s*$", "%1")
		for _, sec in ipairs(self.Sections) do
			local anyVisible = false
			for _, child in ipairs(sec.Container:GetChildren()) do
				if child:IsA("GuiObject") and child.Name ~= "CardTitleRow" then
					if q == "" then
						child.Visible = true
						anyVisible = true
					else
						local score = Util.fuzzyScore(q, child.Name)
						if not score then
							local t = child:FindFirstChild("Title", true)
							if t and t:IsA("TextLabel") then
								score = Util.fuzzyScore(q, t.Text)
							end
						end
						local show = score ~= nil
						child.Visible = show
						if show then
							anyVisible = true
						end
					end
				end
			end
			sec.Root.Visible = (q == "") or anyVisible
		end
	end

	self.SidebarEntry = window.Sidebar:AddTabButton(self, icon, badge)
	return self
end

function Tab:_nextSectionOrder()
	self._sectionOrder += 1
	return self._sectionOrder
end

function Tab:Section(opts)
	local sec = Section.new(self, opts)
	self.Sections[#self.Sections + 1] = sec
	return sec
end
Tab.AddSection = Tab.Section
Tab.CreateSection = Tab.Section

function Tab:_ensureDefaultSection()
	if not self._defaultSection then
		self._defaultSection = self:Section({ Title = "" })
	end
	return self._defaultSection
end

local forwarded = {
	"Button",
	"Toggle",
	"Checkbox",
	"Slider",
	"RangeSlider",
	"Dropdown",
	"Input",
	"Keybind",
	"ColorPicker",
	"Segmented",
	"Stepper",
	"RadioGroup",
	"ProgressBar",
	"Stat",
	"Label",
	"Paragraph",
	"Divider",
	"Image",
	"CodeBlock",
}
for _, method in ipairs(forwarded) do
	Tab[method] = function(self, opts)
		return self:_ensureDefaultSection()[method](self:_ensureDefaultSection(), opts)
	end
end

function Tab:Select()
	self.Window:SelectTab(self)
end

return Tab
end

-- [[ Module: Overlays/Notifications ]]
__modules["Overlays/Notifications"] = function(require)
local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local Notifications = {}
Notifications.__index = Notifications

local TYPE_CONFIG = {
	Info = { Icon = "info", Token = "Info" },
	Success = { Icon = "check-circle-2", Token = "Success" },
	Warning = { Icon = "alert-triangle", Token = "Warning" },
	Error = { Icon = "alert-circle", Token = "Error" },
}

function Notifications.new(screenGui)
	local holder = Creator.new("Frame", {
		Name = "NotificationsHost",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -18),
		Size = UDim2.fromOffset(296, 420),
		BackgroundTransparency = 1,
		ZIndex = 260,
		Parent = screenGui,
	}, {
		Creator.list(8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom),
	})

	return setmetatable({
		Holder = holder,
		Active = {},
		Corner = "BottomRight",
	}, Notifications)
end

function Notifications:SetPosition(corner)
	self.Corner = corner or "BottomRight"
	local layout = self.Holder:FindFirstChildOfClass("UIListLayout")
	if self.Corner == "TopRight" then
		self.Holder.AnchorPoint = Vector2.new(1, 0)
		self.Holder.Position = UDim2.new(1, -18, 0, 18)
		if layout then
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			layout.VerticalAlignment = Enum.VerticalAlignment.Top
		end
	elseif self.Corner == "BottomLeft" then
		self.Holder.AnchorPoint = Vector2.new(0, 1)
		self.Holder.Position = UDim2.new(0, 18, 1, -18)
		if layout then
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		end
	else
		self.Holder.AnchorPoint = Vector2.new(1, 1)
		self.Holder.Position = UDim2.new(1, -18, 1, -18)
		if layout then
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		end
	end
end

function Notifications:Notify(opts)
	if type(opts) == "string" then
		opts = { Title = "Notification", Content = opts }
	end
	opts = opts or {}

	local kind = opts.Type or "Info"
	local cfg = TYPE_CONFIG[kind] or TYPE_CONFIG.Info
	local duration = tonumber(opts.Duration) or 4
	local title = tostring(opts.Title or "Notification")
	local content = tostring(opts.Content or opts.Text or "")

	while #self.Active >= 5 do
		local oldest = table.remove(self.Active, 1)
		if oldest and oldest.Dismiss then
			oldest.Dismiss()
		end
	end

	local bodyBounds = content ~= "" and Util.measureText(content, 12, Enum.Font.BuilderSans, 240) or Vector2.zero
	local cardHeight = math.max(52, 34 + (content ~= "" and (math.ceil(bodyBounds.Y) + 8) or 0))

	local wrapper = Creator.new("Frame", {
		Name = "ToastWrapper",
		Size = UDim2.new(1, 0, 0, cardHeight),
		BackgroundTransparency = 1,
		ZIndex = 261,
		Parent = self.Holder,
	})

	local card = Creator.new("TextButton", {
		Name = "ToastCard",
		Position = UDim2.fromOffset(self.Corner == "BottomLeft" and -40 or 40, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 262,
		ThemeBind = { BackgroundColor3 = "RowBg" },
		Parent = wrapper,
	}, {
		Creator.corner(12),
		Creator.stroke("Outline", 1.2, 0),
	})

	Shadow.create(card, 16, 0.45, 261)

	local iconBox = Creator.new("Frame", {
		Name = "IconBox",
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(32, 32),
		ZIndex = 263,
		ThemeBind = { BackgroundColor3 = "SectionBg" },
		Parent = card,
	}, {
		Creator.corner(8),
		Creator.stroke("Outline", 1, 0),
	})

	Creator.new("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		Image = Icons.resolve(opts.Icon or cfg.Icon) or "",
		ZIndex = 264,
		ThemeBind = { ImageColor3 = cfg.Token },
		Parent = iconBox,
	})

	Creator.new("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(50, 9),
		Size = UDim2.new(1, -60, 0, 18),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 15,
		Text = title,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 264,
		ThemeBind = { TextColor3 = "Text" },
		Parent = card,
	})

	if content ~= "" then
		Creator.new("TextLabel", {
			Name = "Body",
			Position = UDim2.fromOffset(50, 27),
			Size = UDim2.new(1, -60, 0, math.ceil(bodyBounds.Y) + 2),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 12,
			Text = content,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 264,
			ThemeBind = { TextColor3 = "TextSecondary" },
			Parent = card,
		})
	end

	local progressTrack = Creator.new("Frame", {
		Name = "ProgressTrack",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -3),
		Size = UDim2.new(1, -20, 0, 2),
		ZIndex = 264,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = card,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local progressFill = Creator.new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 265,
		ThemeBind = { BackgroundColor3 = cfg.Token },
		Parent = progressTrack,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	Animator.spring(card, "Position", UDim2.fromOffset(0, 0), { frequency = 18, damping = 0.84 })

	local dismissed = false
	local paused = false
	local elapsed = 0
	local hbConn = nil

	local entry = {}
	function entry.Dismiss()
		if dismissed then
			return
		end
		dismissed = true
		if hbConn then
			hbConn:Disconnect()
			hbConn = nil
		end
		for i = #self.Active, 1, -1 do
			if self.Active[i] == entry then
				table.remove(self.Active, i)
				break
			end
		end
		if card.Parent then
			Animator.tween(
				card,
				{
					Position = UDim2.fromOffset(self.Corner == "BottomLeft" and -50 or 50, 0),
					BackgroundTransparency = 1,
				},
				0.16,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In,
				function()
					if wrapper.Parent then
						wrapper:Destroy()
					end
				end
			)
		end
	end

	card.MouseEnter:Connect(function()
		paused = true
	end)
	card.MouseLeave:Connect(function()
		paused = false
	end)
	card.Activated:Connect(function()
		entry.Dismiss()
	end)

	hbConn = Services.RunService.Heartbeat:Connect(function(dt)
		if dismissed or not wrapper.Parent then
			if hbConn then
				hbConn:Disconnect()
				hbConn = nil
			end
			return
		end
		if not paused then
			elapsed += dt
			local ratio = math.clamp(1 - (elapsed / duration), 0, 1)
			progressFill.Size = UDim2.fromScale(ratio, 1)
			if elapsed >= duration then
				entry.Dismiss()
			end
		end
	end)

	self.Active[#self.Active + 1] = entry
	return entry
end

return Notifications
end

-- [[ Module: Overlays/Dialog ]]
__modules["Overlays/Dialog"] = function(require)
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local Animator = require("Motion/Animator")
local Shadow = require("Components/Shadow")

local Dialog = {}

function Dialog.show(window, opts)
	opts = opts or {}
	local title = tostring(opts.Title or "Confirm Action")
	local content = tostring(opts.Content or opts.Text or "")
	local buttons = type(opts.Buttons) == "table" and #opts.Buttons > 0 and opts.Buttons
		or {
			{ Title = "Cancel", Style = "Secondary" },
			{ Title = "Confirm", Style = "Primary" },
		}

	local backdrop = Creator.new("TextButton", {
		Name = "DialogBackdrop",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 230,
		Parent = window.OverlayLayer,
	}, {
		Creator.corner(14),
	})

	local textBounds = content ~= "" and Util.measureText(content, 13, Enum.Font.BuilderSans, 288) or Vector2.zero
	local modalHeight = 96 + (content ~= "" and (math.ceil(textBounds.Y) + 12) or 0)

	local modal = Creator.new("Frame", {
		Name = "DialogModal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(320, modalHeight),
		ZIndex = 231,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = backdrop,
	}, {
		Creator.corner(12),
		Creator.stroke("InnerStroke", 1, 0.2),
		Creator.new("UIScale", { Scale = 0.92 }),
	})

	Shadow.create(modal, 24, 0.4, 230)

	local inner = Creator.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 232,
		Parent = modal,
	}, {
		Creator.padding(16, 16, 14, 16),
		Creator.list(10, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 15,
		Text = title,
		LayoutOrder = 1,
		ZIndex = 233,
		ThemeBind = { TextColor3 = "Text" },
		Parent = inner,
	})

	if content ~= "" then
		Creator.new("TextLabel", {
			Name = "Body",
			Size = UDim2.new(1, 0, 0, math.ceil(textBounds.Y) + 2),
			Font = Enum.Font.BuilderSans,
			TextSize = 13,
			Text = content,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 2,
			ZIndex = 233,
			ThemeBind = { TextColor3 = "TextSecondary" },
			Parent = inner,
		})
	end

	local btnRow = Creator.new("Frame", {
		Name = "Buttons",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		ZIndex = 233,
		Parent = inner,
	}, {
		Creator.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center),
	})

	local scaleInst = modal:FindFirstChildOfClass("UIScale")
	local closed = false

	local function closeDialog()
		if closed then
			return
		end
		closed = true
		if scaleInst then
			Animator.spring(scaleInst, "Scale", 0.92, { frequency = 20, damping = 0.88 })
		end
		Animator.tween(
			backdrop,
			{ BackgroundTransparency = 1 },
			0.14,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			function()
				if backdrop.Parent then
					backdrop:Destroy()
				end
			end
		)
	end

	for idx, bDef in ipairs(buttons) do
		local style = bDef.Style or (idx == #buttons and "Primary" or "Secondary")
		local bgToken = "ControlBg"
		local txtToken = "Text"
		if style == "Primary" then
			bgToken = "Accent"
			txtToken = "OnAccent"
		elseif style == "Destructive" then
			bgToken = "Error"
			txtToken = "OnAccent"
		end

		local btn = Creator.new("TextButton", {
			Name = "Btn_" .. tostring(bDef.Title or idx),
			Size = UDim2.fromOffset(88, 28),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 12,
			Text = tostring(bDef.Title or "OK"),
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = idx,
			ZIndex = 234,
			ThemeBind = {
				BackgroundColor3 = bgToken,
				TextColor3 = txtToken,
			},
			Parent = btnRow,
		}, {
			Creator.corner(7),
			Creator.stroke("Border", 1, style == "Secondary" and 0.3 or 0.7),
		})

		btn.Activated:Connect(function()
			closeDialog()
			if type(bDef.Callback) == "function" then
				task.spawn(Util.safeCall, title, bDef.Callback, window._notifyError)
			end
		end)
	end

	Animator.tween(backdrop, { BackgroundTransparency = 0.45 }, 0.16)
	if scaleInst then
		Animator.spring(scaleInst, "Scale", 1, { frequency = 18, damping = 0.82 })
	end

	return {
		Close = closeDialog,
	}
end

return Dialog
end

-- [[ Module: Overlays/CommandPalette ]]
__modules["Overlays/CommandPalette"] = function(require)
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local CommandPalette = {}
CommandPalette.__index = CommandPalette

function CommandPalette.new(window)
	local backdrop = Creator.new("TextButton", {
		Name = "SpotlightBackdrop",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Visible = false,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 220,
		Parent = window.OverlayLayer,
	}, {
		Creator.corner(14),
	})

	local panel = Creator.new("Frame", {
		Name = "SpotlightPanel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 46),
		Size = UDim2.fromOffset(390, 260),
		ZIndex = 221,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = backdrop,
	}, {
		Creator.corner(11),
		Creator.stroke("InnerStroke", 1, 0.2),
		Creator.new("UIScale", { Scale = 0.95 }),
	})

	Shadow.create(panel, 22, 0.42, 220)

	local searchHeader = Creator.new("Frame", {
		Name = "SearchBar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 222,
		Parent = panel,
	}, {
		Creator.new("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 222,
			ThemeBind = { BackgroundColor3 = "Border" },
		}),
		Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.fromOffset(15, 15),
			Image = Icons.resolve("search") or "",
			ZIndex = 223,
			ThemeBind = { ImageColor3 = "Accent" },
		}),
	})

	local searchBox = Creator.new("TextBox", {
		Name = "Input",
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -84, 1, 0),
		Font = Enum.Font.BuilderSans,
		TextSize = 14,
		PlaceholderText = "Search controls, tabs, or actions...",
		ClearTextOnFocus = false,
		ZIndex = 223,
		ThemeBind = {
			TextColor3 = "Text",
			PlaceholderColor3 = "TextMuted",
		},
		Parent = searchHeader,
	})

	Creator.new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(34, 18),
		Font = Enum.Font.RobotoMono,
		TextSize = 10,
		Text = "ESC",
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 223,
		ThemeBind = {
			BackgroundColor3 = "ControlBg",
			TextColor3 = "TextMuted",
		},
		Parent = searchHeader,
	}, {
		Creator.corner(4),
	})

	local resultsScroll = Creator.new("ScrollingFrame", {
		Name = "Results",
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, 0, 1, -44),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ZIndex = 222,
		Parent = panel,
	}, {
		Creator.padding(6, 8, 8, 8),
		Creator.list(4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local self = setmetatable({
		Window = window,
		Backdrop = backdrop,
		Panel = panel,
		SearchBox = searchBox,
		ResultsScroll = resultsScroll,
		Scale = panel:FindFirstChildOfClass("UIScale"),
		Entries = {},
		ResultButtons = {},
		IsOpen = false,
	}, CommandPalette)

	backdrop.Activated:Connect(function()
		self:Hide()
	end)

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if self.IsOpen then
			self:_renderResults(searchBox.Text)
		end
	end)

	searchBox.FocusLost:Connect(function(enterPressed)
		if enterPressed and self._topAction then
			self._topAction()
		end
	end)

	return self
end

function CommandPalette:Register(control, section)
	self.Entries[#self.Entries + 1] = {
		Control = control,
		Section = section,
		Tab = section.Tab,
	}
end

function CommandPalette:_renderResults(query)
	for _, b in ipairs(self.ResultButtons) do
		b:Destroy()
	end
	table.clear(self.ResultButtons)
	self._topAction = nil

	local scored = {}
	for _, item in ipairs(self.Entries) do
		local ctrl = item.Control
		if ctrl and ctrl.Row and ctrl.Row.Parent then
			local label = string.format(
				"%s › %s › %s",
				tostring(item.Tab.Title),
				tostring(item.Section.Title),
				tostring(ctrl.Title)
			)
			local s = Util.fuzzyScore(query, label) or Util.fuzzyScore(query, ctrl.Title)
			if s then
				scored[#scored + 1] = { item = item, score = s }
			end
		end
	end

	table.sort(scored, function(a, b)
		return a.score > b.score
	end)

	local count = math.min(#scored, 20)
	for i = 1, count do
		local entry = scored[i].item
		local ctrl = entry.Control
		local rowBtn = Creator.new("TextButton", {
			Name = "Result_" .. i,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = i == 1 and 0.86 or 1,
			LayoutOrder = i,
			ZIndex = 223,
			ThemeBind = { BackgroundColor3 = "Accent" },
			Parent = self.ResultsScroll,
		}, {
			Creator.corner(7),
			Creator.padding(0, 10, 0, 10),
		})

		Creator.new("TextLabel", {
			Size = UDim2.new(1, -90, 0, 18),
			Position = UDim2.fromOffset(0, 2),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 13,
			Text = tostring(ctrl.Title),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 224,
			ThemeBind = { TextColor3 = "Text" },
			Parent = rowBtn,
		})

		Creator.new("TextLabel", {
			Size = UDim2.new(1, -90, 0, 14),
			Position = UDim2.fromOffset(0, 18),
			Font = Enum.Font.BuilderSans,
			TextSize = 11,
			Text = string.format(
				"%s  •  %s",
				tostring(entry.Tab.Title),
				tostring(entry.Section.Title ~= "" and entry.Section.Title or "General")
			),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 224,
			ThemeBind = { TextColor3 = "TextMuted" },
			Parent = rowBtn,
		})

		Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(74, 20),
			Font = Enum.Font.RobotoMono,
			TextSize = 10,
			Text = tostring(ctrl.Kind or "Control"),
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 224,
			ThemeBind = { TextColor3 = "TextSecondary" },
			Parent = rowBtn,
		})

		local function activateResult()
			self:Hide()
			self.Window:SelectTab(entry.Tab)
			task.defer(function()
				if ctrl.Highlight then
					ctrl:Highlight()
				end
			end)
		end

		if i == 1 then
			self._topAction = activateResult
		end

		rowBtn.Activated:Connect(activateResult)
		rowBtn.MouseEnter:Connect(function()
			rowBtn.BackgroundTransparency = 0.85
		end)
		rowBtn.MouseLeave:Connect(function()
			rowBtn.BackgroundTransparency = i == 1 and 0.86 or 1
		end)

		self.ResultButtons[#self.ResultButtons + 1] = rowBtn
	end
end

function CommandPalette:Show()
	self.IsOpen = true
	self.Backdrop.Visible = true
	self.SearchBox.Text = ""
	self:_renderResults("")
	if self.Scale then
		self.Scale.Scale = 0.94
		Animator.spring(self.Scale, "Scale", 1, { frequency = 18, damping = 0.84 })
	end
	task.defer(function()
		if self.SearchBox.Parent then
			self.SearchBox:CaptureFocus()
		end
	end)
end

function CommandPalette:Hide()
	if not self.IsOpen then
		return
	end
	self.IsOpen = false
	self.Backdrop.Visible = false
end

function CommandPalette:Toggle()
	if self.IsOpen then
		self:Hide()
	else
		self:Show()
	end
end

return CommandPalette
end

-- [[ Module: Overlays/ContextMenu ]]
__modules["Overlays/ContextMenu"] = function(require)
local Env = require("Core/Env")
local Creator = require("Core/Creator")
local ThemeManager = require("Theme/ThemeManager")
local Icons = require("Assets/Icons")
local Popover = require("Components/Popover")

local ContextMenu = {}

function ContextMenu.bind(window, rowGui, control)
	rowGui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			ContextMenu.open(window, control, Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
end

function ContextMenu.open(window, control, screenPos)
	local items = {}

	if control.Default ~= nil and control.Set then
		items[#items + 1] = {
			Title = "Reset to Default",
			Icon = "rotate-ccw",
			Action = function()
				control:Set(control.Default, false)
			end,
		}
	end

	if control.Get then
		items[#items + 1] = {
			Title = "Copy Current Value",
			Icon = "copy",
			Action = function()
				local v = control:Get()
				Env.setClipboard(tostring(v))
				window:Notify({
					Title = "Copied",
					Content = "Copied value to clipboard.",
					Type = "Info",
					Duration = 2.5,
				})
			end,
		}
	end

	if control.Flag then
		items[#items + 1] = {
			Title = "Copy Flag ID (" .. tostring(control.Flag) .. ")",
			Icon = "tag",
			Action = function()
				Env.setClipboard(tostring(control.Flag))
				window:Notify({
					Title = "Copied",
					Content = "Copied flag ID to clipboard.",
					Type = "Info",
					Duration = 2.5,
				})
			end,
		}
	end

	items[#items + 1] = {
		Title = "Highlight Row",
		Icon = "sparkles",
		Action = function()
			if control.Highlight then
				control:Highlight()
			end
		end,
	}

	local pop = Popover.open({
		Name = "ContextMenuPopover",
		Position = screenPos,
		Width = 186,
		Height = #items * 28 + 10,
	})
	if not pop then
		return
	end

	Creator.padding(5, 5, 5, 5, pop.content)
	Creator.list(2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, pop.content)

	for idx, item in ipairs(items) do
		local btn = Creator.new("TextButton", {
			Name = "CtxItem_" .. idx,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			LayoutOrder = idx,
			ZIndex = 203,
			ThemeBind = { BackgroundColor3 = "RowHover" },
			Parent = pop.content,
		}, {
			Creator.corner(6),
			Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				Size = UDim2.fromOffset(13, 13),
				Image = Icons.resolve(item.Icon) or "",
				ZIndex = 204,
				ThemeBind = { ImageColor3 = "TextSecondary" },
			}),
			Creator.new("TextLabel", {
				Position = UDim2.fromOffset(27, 0),
				Size = UDim2.new(1, -32, 1, 0),
				Font = Enum.Font.BuilderSans,
				TextSize = 12,
				Text = item.Title,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 204,
				ThemeBind = { TextColor3 = "Text" },
			}),
		})

		btn.MouseEnter:Connect(function()
			btn.BackgroundTransparency = 0.2
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundTransparency = 1
		end)
		btn.Activated:Connect(function()
			Popover.close()
			item.Action()
		end)
	end
end

return ContextMenu
end

-- [[ Module: Overlays/Tooltip ]]
__modules["Overlays/Tooltip"] = function(require)
local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")

local Tooltip = {}
Tooltip.__index = Tooltip

function Tooltip.new(screenGui)
	local pill = Creator.new("Frame", {
		Name = "TooltipCard",
		Size = UDim2.fromOffset(120, 28),
		BackgroundTransparency = 0,
		Visible = false,
		ZIndex = 300,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = screenGui,
	}, {
		Creator.corner(8),
		Creator.stroke("Outline", 2, 0),
		Creator.padding(4, 10, 4, 10),
	})

	local label = Creator.new("TextLabel", {
		Name = "Text",
		Size = UDim2.new(1, 0, 1, 0),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 13,
		Text = "",
		ZIndex = 301,
		ThemeBind = { TextColor3 = "Text" },
		Parent = pill,
	})

	return setmetatable({
		Frame = pill,
		Label = label,
		_hoverThread = nil,
	}, Tooltip)
end

function Tooltip:Bind(guiObj, textOrProvider)
	if textOrProvider == nil then
		return
	end

	guiObj.MouseEnter:Connect(function()
		if self._hoverThread then
			pcall(task.cancel, self._hoverThread)
		end
		self._hoverThread = task.delay(0.45, function()
			local text = nil
			if type(textOrProvider) == "function" then
				local ok, res = pcall(textOrProvider)
				if ok and type(res) == "string" then
					text = res
				end
			elseif type(textOrProvider) == "string" then
				text = textOrProvider
			end

			if not text or text == "" then
				self.Frame.Visible = false
				return
			end

			local bounds = Util.measureText(text, 13, Enum.Font.BuilderSansBold, 260)
			local w = math.clamp(math.ceil(bounds.X) + 22, 48, 280)
			local h = math.max(26, math.ceil(bounds.Y) + 10)
			self.Label.Text = text
			self.Frame.Size = UDim2.fromOffset(w, h)

			local mPos = Services.UserInputService:GetMouseLocation()
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			local x = math.clamp(mPos.X + 12, 8, vp.X - w - 8)
			local y = math.clamp(mPos.Y - 18, 8, vp.Y - h - 8)
			self.Frame.Position = UDim2.fromOffset(x, y)
			self.Frame.Visible = true
		end)
	end)

	guiObj.MouseLeave:Connect(function()
		if self._hoverThread then
			pcall(task.cancel, self._hoverThread)
			self._hoverThread = nil
		end
		self.Frame.Visible = false
	end)
end

return Tooltip
end

-- [[ Module: Overlays/KeybindList ]]
__modules["Overlays/KeybindList"] = function(require)
local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local KeybindList = {}
KeybindList.__index = KeybindList

function KeybindList.new(window, visibleByDefault)
	local card = Creator.new("Frame", {
		Name = "KeybindListHUD",
		Position = UDim2.fromOffset(18, 94),
		Size = UDim2.fromOffset(192, 40),
		BackgroundTransparency = 0.06,
		Visible = visibleByDefault == true,
		ZIndex = 160,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = window.ScreenGui,
	}, {
		Creator.corner(10),
		Creator.stroke("InnerStroke", 1, 0.25),
	})

	Shadow.create(card, 16, 0.45, 159)

	local inner = Creator.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 161,
		Parent = card,
	}, {
		Creator.padding(8, 10, 8, 10),
		Creator.list(4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local header = Creator.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		ZIndex = 161,
		Parent = inner,
	})

	Creator.new("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(13, 13),
		Image = Icons.resolve("keyboard") or "",
		ZIndex = 162,
		ThemeBind = { ImageColor3 = "Accent" },
		Parent = header,
	})

	Creator.new("TextLabel", {
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -18, 1, 0),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 12,
		Text = "Active Keybinds",
		ZIndex = 162,
		ThemeBind = { TextColor3 = "Text" },
		Parent = header,
	})

	Creator.new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		LayoutOrder = 2,
		ZIndex = 161,
		ThemeBind = { BackgroundColor3 = "Border" },
		Parent = inner,
	})

	local listHolder = Creator.new("Frame", {
		Name = "Rows",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		ZIndex = 161,
		Parent = inner,
	}, {
		Creator.list(3, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	-- Draggable HUD
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = card.Position
	header.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(inp.Position.X, inp.Position.Y)
			startPos = card.Position
		end
	end)
	window.Maid:Add(Services.UserInputService.InputChanged:Connect(function(inp)
		if
			dragging
			and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch)
		then
			local d = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
			card.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
	window.Maid:Add(Services.UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	return setmetatable({
		Frame = card,
		ListHolder = listHolder,
		Controls = {},
		RowViews = {},
	}, KeybindList)
end

function KeybindList:Register(control)
	if not table.find(self.Controls, control) then
		self.Controls[#self.Controls + 1] = control
	end
	self:Refresh()
end

function KeybindList:Refresh()
	for _, v in ipairs(self.RowViews) do
		v:Destroy()
	end
	table.clear(self.RowViews)

	for idx, ctrl in ipairs(self.Controls) do
		local key = ctrl.GetKey and ctrl:GetKey() or nil
		if key ~= nil and ctrl.Row and ctrl.Row.Parent then
			local isActive = false
			if ctrl.Kind == "Toggle" and ctrl.Get then
				isActive = ctrl:Get() == true
			elseif ctrl.IsActive then
				isActive = ctrl:IsActive() == true
			end

			local row = Creator.new("Frame", {
				Name = "Bind_" .. idx,
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				LayoutOrder = idx,
				ZIndex = 162,
				Parent = self.ListHolder,
			})

			Creator.new("TextLabel", {
				Size = UDim2.new(1, -56, 1, 0),
				Font = Enum.Font.BuilderSans,
				TextSize = 11,
				Text = tostring(ctrl.Title),
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 163,
				TextColor3 = ThemeManager:Get(isActive and "Accent" or "TextSecondary"),
				Parent = row,
			})

			Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(52, 16),
				Font = Enum.Font.RobotoMono,
				TextSize = 10,
				Text = "[" .. Util.formatKeyName(key) .. "]",
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 163,
				TextColor3 = ThemeManager:Get(isActive and "Accent" or "TextMuted"),
				Parent = row,
			})

			self.RowViews[#self.RowViews + 1] = row
		end
	end

	local targetH = 38 + (#self.RowViews * 21)
	Animator.spring(self.Frame, "Size", UDim2.fromOffset(192, targetH), { frequency = 18, damping = 0.86 })
end

function KeybindList:SetVisible(vis)
	self.Frame.Visible = vis == true
	if vis then
		self:Refresh()
	end
end

function KeybindList:IsVisible()
	return self.Frame.Visible
end

return KeybindList
end

-- [[ Module: Overlays/Watermark ]]
__modules["Overlays/Watermark"] = function(require)
local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local Watermark = {}
Watermark.__index = Watermark

function Watermark.new(window, opts)
	opts = opts or {}
	local title = tostring(opts.Title or "Perfectus UI")
	local visible = opts.Visible == true

	local pill = Creator.new("Frame", {
		Name = "WatermarkHUD",
		Position = UDim2.fromOffset(18, 58),
		Size = UDim2.fromOffset(250, 28),
		BackgroundTransparency = 0.06,
		Visible = visible,
		ZIndex = 170,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = window.ScreenGui,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("InnerStroke", 1, 0.25),
	})

	Shadow.create(pill, 14, 0.45, 169)

	local content = Creator.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 171,
		Parent = pill,
	}, {
		Creator.padding(0, 12, 0, 12),
		Creator.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
	})

	Creator.new("ImageLabel", {
		Size = UDim2.fromOffset(14, 14),
		Image = Icons.resolve(opts.Icon or "sparkles") or "",
		LayoutOrder = 1,
		ZIndex = 172,
		ThemeBind = { ImageColor3 = "Accent" },
		Parent = content,
	})

	local textLabel = Creator.new("TextLabel", {
		Size = UDim2.new(1, -22, 1, 0),
		Font = Enum.Font.RobotoMono,
		TextSize = 11,
		Text = title .. "  •  60 FPS  •  0 ms",
		LayoutOrder = 2,
		ZIndex = 172,
		ThemeBind = { TextColor3 = "Text" },
		Parent = content,
	})

	-- Draggable
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = pill.Position
	pill.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(inp.Position.X, inp.Position.Y)
			startPos = pill.Position
		end
	end)
	window.Maid:Add(Services.UserInputService.InputChanged:Connect(function(inp)
		if
			dragging
			and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch)
		then
			local d = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
			pill.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
	window.Maid:Add(Services.UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	local self = setmetatable({
		Frame = pill,
		Label = textLabel,
		Title = title,
		_loopThread = nil,
	}, Watermark)

	function self:_updateText(str)
		self.Label.Text = str
		local bounds = Util.measureText(str, 11, Enum.Font.RobotoMono, 1000)
		self.Frame.Size = UDim2.fromOffset(math.ceil(bounds.X) + 48, 28)
	end

	self:_updateText(title .. "  •  60 FPS  •  0 ms")

	if visible then
		self:_startLoop()
	end

	return self
end

function Watermark:_startLoop()
	if self._loopThread then
		return
	end
	self._loopThread = task.spawn(function()
		while self.Frame.Parent and self.Frame.Visible do
			local dt = Services.RunService.RenderStepped:Wait()
			local fps = math.clamp(math.floor(1 / math.max(0.001, dt) + 0.5), 1, 999)
			local ping = 0
			pcall(function()
				ping = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
			end)
			local clockStr = os.date("%H:%M:%S")
			self:_updateText(string.format("%s  •  %d FPS  •  %d ms  •  %s", self.Title, fps, ping, clockStr))
			task.wait(0.5)
		end
		self._loopThread = nil
	end)
end

function Watermark:SetVisible(vis)
	self.Frame.Visible = vis == true
	if vis then
		self:_startLoop()
	end
end

function Watermark:IsVisible()
	return self.Frame.Visible
end

function Watermark:SetTitle(newTitle)
	self.Title = tostring(newTitle or "Perfectus UI")
end

return Watermark
end

-- [[ Module: Overlays/LoadingScreen ]]
__modules["Overlays/LoadingScreen"] = function(require)
local Creator = require("Core/Creator")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")

local LoadingScreen = {}

function LoadingScreen.play(window, opts)
	opts = opts or {}

	local cover = Creator.new("Frame", {
		Name = "LoadingOverlay",
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 240,
		ThemeBind = { BackgroundColor3 = "WindowBg" },
		Parent = window.OverlayLayer,
	}, {
		Creator.corner(14),
	})

	local center = Creator.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(240, 120),
		BackgroundTransparency = 1,
		ZIndex = 241,
		Parent = cover,
	}, {
		Creator.list(8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
	})

	Creator.new("ImageLabel", {
		Size = UDim2.fromOffset(32, 32),
		Image = Icons.resolve(opts.Icon or "sparkles") or "",
		LayoutOrder = 1,
		ZIndex = 242,
		ThemeBind = { ImageColor3 = "Accent" },
		Parent = center,
	})

	Creator.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 16,
		Text = tostring(opts.Title or "Perfectus UI"),
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		ZIndex = 242,
		ThemeBind = { TextColor3 = "Text" },
		Parent = center,
	})

	local sub = Creator.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		Font = Enum.Font.BuilderSans,
		TextSize = 12,
		Text = tostring(opts.Subtitle or "Initializing interface..."),
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 3,
		ZIndex = 242,
		ThemeBind = { TextColor3 = "TextMuted" },
		Parent = center,
	})

	local track = Creator.new("Frame", {
		Size = UDim2.fromOffset(160, 4),
		LayoutOrder = 4,
		ZIndex = 242,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = center,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local fill = Creator.new("Frame", {
		Size = UDim2.fromScale(0.08, 1),
		ZIndex = 243,
		ThemeBind = { BackgroundColor3 = "Accent" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	task.spawn(function()
		Animator.spring(fill, "Size", UDim2.fromScale(1, 1), { frequency = 6, damping = 0.9 })
		task.wait(0.42)
		sub.Text = "Ready"
		task.wait(0.15)
		Animator.tween(
			cover,
			{ BackgroundTransparency = 1 },
			0.22,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out,
			function()
				if cover.Parent then
					cover:Destroy()
				end
			end
		)
		for _, d in ipairs(cover:GetDescendants()) do
			if d:IsA("TextLabel") then
				Animator.tween(d, { TextTransparency = 1 }, 0.18)
			elseif d:IsA("ImageLabel") then
				Animator.tween(d, { ImageTransparency = 1 }, 0.18)
			elseif d:IsA("Frame") then
				Animator.tween(d, { BackgroundTransparency = 1 }, 0.18)
			end
		end
	end)
end

return LoadingScreen
end

-- [[ Module: Overlays/KeySystem ]]
__modules["Overlays/KeySystem"] = function(require)
local Env = require("Core/Env")
local Creator = require("Core/Creator")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")

local KeySystem = {}

function KeySystem.gate(window, cfg, onUnlocked)
	if type(cfg) ~= "table" or cfg.Enabled == false then
		onUnlocked()
		return
	end

	local savePath = (window.ConfigFolder or "PerfectusUI") .. "/saved_key.txt"
	local function checkKey(candidate)
		candidate = tostring(candidate or ""):gsub("^%s*(.-)%s*$", "%1")
		if candidate == "" then
			return false
		end
		if type(cfg.Validate) == "function" then
			local ok, res = pcall(cfg.Validate, candidate)
			return ok and res == true
		end
		if type(cfg.Keys) == "table" then
			for _, k in ipairs(cfg.Keys) do
				if tostring(k) == candidate then
					return true
				end
			end
		elseif type(cfg.Key) == "string" then
			return candidate == cfg.Key
		end
		return false
	end

	if cfg.Remember ~= false and Env.HasFileSystem then
		local saved = Env.readFile(savePath)
		if saved and checkKey(saved) then
			onUnlocked()
			return
		end
	end

	local gate = Creator.new("Frame", {
		Name = "KeySystemGate",
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 245,
		ThemeBind = { BackgroundColor3 = "WindowBg" },
		Parent = window.OverlayLayer,
	}, {
		Creator.corner(14),
	})

	local card = Creator.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(320, 200),
		ZIndex = 246,
		ThemeBind = { BackgroundColor3 = "SectionBg" },
		Parent = gate,
	}, {
		Creator.corner(12),
		Creator.stroke("Border", 1, 0.2),
		Creator.padding(18, 18, 16, 18),
		Creator.list(10, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top),
	})

	Creator.new("ImageLabel", {
		Size = UDim2.fromOffset(24, 24),
		Image = Icons.resolve("key") or "",
		LayoutOrder = 1,
		ZIndex = 247,
		ThemeBind = { ImageColor3 = "Accent" },
		Parent = card,
	})

	Creator.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 15,
		Text = tostring(cfg.Title or "Key Verification"),
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		ZIndex = 247,
		ThemeBind = { TextColor3 = "Text" },
		Parent = card,
	})

	local statusLbl = Creator.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		Font = Enum.Font.BuilderSans,
		TextSize = 12,
		Text = tostring(cfg.Subtitle or "Enter your access key to continue."),
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 3,
		ZIndex = 247,
		ThemeBind = { TextColor3 = "TextSecondary" },
		Parent = card,
	})

	local keyInput = Creator.new("TextBox", {
		Size = UDim2.new(1, 0, 0, 32),
		Font = Enum.Font.RobotoMono,
		TextSize = 12,
		PlaceholderText = "Paste license key...",
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 4,
		ZIndex = 247,
		ThemeBind = {
			BackgroundColor3 = "InputBg",
			TextColor3 = "Text",
			PlaceholderColor3 = "TextMuted",
		},
		Parent = card,
	}, {
		Creator.corner(7),
		Creator.stroke("Border", 1, 0.3),
	})

	local btnRow = Creator.new("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		ZIndex = 247,
		Parent = card,
	}, {
		Creator.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
	})

	if cfg.Link then
		local getBtn = Creator.new("TextButton", {
			Size = UDim2.fromOffset(110, 28),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 12,
			Text = "Copy Key Link",
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 1,
			ZIndex = 248,
			ThemeBind = {
				BackgroundColor3 = "ControlBg",
				TextColor3 = "Text",
			},
			Parent = btnRow,
		}, {
			Creator.corner(7),
			Creator.stroke("Border", 1, 0.35),
		})
		getBtn.Activated:Connect(function()
			Env.setClipboard(tostring(cfg.Link))
			statusLbl.Text = "Key link copied to clipboard."
		end)
	end

	local verifyBtn = Creator.new("TextButton", {
		Size = UDim2.fromOffset(110, 28),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 12,
		Text = "Unlock",
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		ZIndex = 248,
		ThemeBind = {
			BackgroundColor3 = "Accent",
			TextColor3 = "OnAccent",
		},
		Parent = btnRow,
	}, {
		Creator.corner(7),
	})

	verifyBtn.Activated:Connect(function()
		if checkKey(keyInput.Text) then
			if cfg.Remember ~= false and Env.HasFileSystem then
				Env.writeFile(savePath, keyInput.Text)
			end
			Animator.tween(
				gate,
				{ BackgroundTransparency = 1 },
				0.18,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out,
				function()
					if gate.Parent then
						gate:Destroy()
					end
				end
			)
			onUnlocked()
		else
			statusLbl.Text = "Invalid key. Please try again."
			statusLbl.TextColor3 = ThemeManager:Get("Error")
		end
	end)
end

return KeySystem
end

-- [[ Module: Systems/Flags ]]
__modules["Systems/Flags"] = function(require)
local Util = require("Core/Util")
local Signal = require("Core/Signal")

local Flags = {}
Flags.__index = Flags

function Flags.new()
	local self = setmetatable({
		_controls = {},
		_values = {},
		Changed = Signal.new(),
		_onDirty = nil,
	}, Flags)

	return setmetatable(self, {
		__index = function(tbl, key)
			local method = Flags[key]
			if method ~= nil then
				return method
			end
			return tbl._controls[key]
		end,
	})
end

function Flags:_register(flagName, control)
	if not flagName or flagName == "" then
		return
	end
	self._controls[flagName] = control
	if control.Get then
		self._values[flagName] = control:Get()
	end
end

function Flags:_setRaw(flagName, value, silent)
	if not flagName or flagName == "" then
		return
	end
	self._values[flagName] = value
	if not silent then
		self.Changed:Fire(flagName, value)
		if self._onDirty then
			self._onDirty(flagName, value)
		end
	end
end

function Flags:Get(flagName)
	local ctrl = self._controls[flagName]
	if ctrl and ctrl.Get then
		return ctrl:Get()
	end
	return self._values[flagName]
end

function Flags:Set(flagName, value, silent)
	local ctrl = self._controls[flagName]
	if ctrl and ctrl.Set then
		ctrl:Set(value, silent)
	else
		self:_setRaw(flagName, value, silent)
	end
end

function Flags:Export()
	local data = {}
	for flag, ctrl in pairs(self._controls) do
		if ctrl.Get then
			local val = ctrl:Get()
			if typeof(val) == "Color3" then
				data[flag] = { __type = "Color3", hex = Util.colorToHex(val) }
			elseif typeof(val) == "EnumItem" then
				data[flag] = { __type = "EnumItem", name = val.Name }
			else
				data[flag] = val
			end
		end
	end
	return data
end

function Flags:Import(data, silent)
	if type(data) ~= "table" then
		return false
	end
	for flag, raw in pairs(data) do
		local ctrl = self._controls[flag]
		if ctrl and ctrl.Set then
			local val = raw
			if type(raw) == "table" then
				if raw.__type == "Color3" and raw.hex then
					val = Util.hexToColor(raw.hex) or Color3.fromRGB(10, 132, 255)
				elseif raw.__type == "EnumItem" and raw.name then
					local ok, item = pcall(function()
						return Enum.KeyCode[raw.name]
					end)
					val = ok and item or raw.name
				end
			end
			pcall(ctrl.Set, ctrl, val, silent == true)
		end
	end
	return true
end

function Flags:ResetAll()
	for _, ctrl in pairs(self._controls) do
		if ctrl.Default ~= nil and ctrl.Set then
			pcall(ctrl.Set, ctrl, ctrl.Default, false)
		end
	end
end

return Flags
end

-- [[ Module: Systems/ConfigManager ]]
__modules["Systems/ConfigManager"] = function(require)
local Services = require("Core/Services")
local Env = require("Core/Env")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")

local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new(window, folder)
	folder = tostring(folder or "PerfectusUI/Default"):gsub("/+$", "")
	local self = setmetatable({
		Window = window,
		Folder = folder,
		ConfigsFolder = folder .. "/configs",
		AutoSavePath = folder .. "/autosave.json",
		AutoSaveEnabled = true,
		Loading = false,
		_memoryConfigs = {},
		_memoryAutoSave = nil,
	}, ConfigManager)

	self._debouncedAutoSave = Util.debounce(0.8, function()
		if self.AutoSaveEnabled and not self.Loading then
			self:SaveAutoSave()
		end
	end)

	if window.Flags then
		window.Flags._onDirty = function()
			self:_queueAutoSave()
		end
	end

	return self
end

function ConfigManager:_queueAutoSave()
	if self.Loading or not self.AutoSaveEnabled then
		return
	end
	self._debouncedAutoSave()
end

function ConfigManager:_sanitizeName(name)
	local clean = tostring(name or ""):gsub("[^%w_%- ]", ""):gsub("^%s*(.-)%s*$", "%1"):sub(1, 32)
	return clean ~= "" and clean or nil
end

function ConfigManager:Serialize()
	local payload = {
		version = 1,
		theme = ThemeManager.CurrentTheme,
		accent = ThemeManager.CurrentAccent,
		autoSave = self.AutoSaveEnabled,
		flags = self.Window.Flags and self.Window.Flags:Export() or {},
	}
	local ok, json = pcall(function()
		return Services.HttpService:JSONEncode(payload)
	end)
	return ok and json or "{}"
end

function ConfigManager:Deserialize(jsonStr, applyToCallback)
	if type(jsonStr) ~= "string" or jsonStr == "" then
		return false
	end
	local ok, decoded = pcall(function()
		return Services.HttpService:JSONDecode(jsonStr)
	end)
	if not (ok and type(decoded) == "table") then
		return false
	end
	self.Loading = true
	if type(decoded.theme) == "string" then
		ThemeManager:SetTheme(decoded.theme, true)
	end
	if type(decoded.accent) == "string" then
		ThemeManager:SetAccent(decoded.accent, true)
	end
	if type(decoded.flags) == "table" and self.Window.Flags then
		self.Window.Flags:Import(decoded.flags, applyToCallback == false)
	end
	self.Loading = false
	return true
end

function ConfigManager:Save(name)
	local clean = self:_sanitizeName(name)
	if not clean then
		return false, "Enter a valid config name."
	end
	local json = self:Serialize()
	self._memoryConfigs[clean] = json
	if Env.HasFileSystem then
		local path = self.ConfigsFolder .. "/" .. clean .. ".json"
		Env.writeFile(path, json)
	end
	return true, clean
end

function ConfigManager:Load(name)
	local clean = self:_sanitizeName(name)
	if not clean then
		return false, "Select a config to load."
	end
	local json = nil
	if Env.HasFileSystem then
		json = Env.readFile(self.ConfigsFolder .. "/" .. clean .. ".json")
	end
	if not json then
		json = self._memoryConfigs[clean]
	end
	if not json then
		return false, "Config not found."
	end
	local ok = self:Deserialize(json, true)
	return ok, ok and ("Loaded '" .. clean .. "'.") or "Corrupted config JSON."
end

function ConfigManager:Delete(name)
	local clean = self:_sanitizeName(name)
	if not clean then
		return false
	end
	self._memoryConfigs[clean] = nil
	if Env.HasFileSystem then
		Env.deleteFile(self.ConfigsFolder .. "/" .. clean .. ".json")
	end
	return true
end

function ConfigManager:List()
	local seen = {}
	local list = {}
	for k in pairs(self._memoryConfigs) do
		seen[k] = true
		list[#list + 1] = k
	end
	if Env.HasFileSystem then
		for _, file in ipairs(Env.listFiles(self.ConfigsFolder)) do
			local name = tostring(file):match("([^/\\]+)%.json$")
			if name and not seen[name] then
				seen[name] = true
				list[#list + 1] = name
			end
		end
	end
	table.sort(list)
	if #list == 0 then
		list[1] = "default"
	end
	return list
end

function ConfigManager:SaveAutoSave()
	local json = self:Serialize()
	self._memoryAutoSave = json
	if Env.HasFileSystem then
		Env.writeFile(self.AutoSavePath, json)
	end
end

function ConfigManager:LoadAutoSave()
	local json = Env.HasFileSystem and Env.readFile(self.AutoSavePath) or self._memoryAutoSave
	if not json then
		return false
	end
	return self:Deserialize(json, true)
end

function ConfigManager:ExportClipboard()
	local json = self:Serialize()
	local ok = Env.setClipboard(json)
	return ok, json
end

return ConfigManager
end

-- [[ Module: Systems/InputManager ]]
__modules["Systems/InputManager"] = function(require)
local Services = require("Core/Services")
local Popover = require("Components/Popover")

local InputManager = {}

function InputManager.attach(window)
	window.Maid:Add(Services.UserInputService.InputBegan:Connect(function(input, processed)
		local focused = Services.UserInputService:GetFocusedTextBox()
		if focused ~= nil then
			return
		end

		-- Ctrl+K or Cmd+K opens Command Palette
		if input.KeyCode == Enum.KeyCode.K then
			local ctrl = Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
				or Services.UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
				or Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftMeta)
			if ctrl and window.CommandPalette then
				Popover.close()
				window.CommandPalette:Toggle()
				return
			end
		end

		-- Toggle Window Visibility
		if not processed and window.ToggleKey and input.KeyCode == window.ToggleKey then
			window:ToggleVisibility()
		end
	end))
end

return InputManager
end

-- [[ Module: Systems/SettingsTab ]]
__modules["Systems/SettingsTab"] = function(require)
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")

local SettingsTab = {}

function SettingsTab.build(window)
	local tab = window:Tab({
		Title = "Settings",
		Icon = "settings",
	})

	-- 1. Appearance Section
	local appearance = tab:Section({ Title = "Appearance", Icon = "palette" })

	appearance:Dropdown({
		Title = "Theme",
		Flag = "__UI_Theme",
		Options = ThemeManager:GetThemes(),
		Default = ThemeManager.CurrentTheme,
		Callback = function(themeName)
			if themeName then
				ThemeManager:SetTheme(themeName, true)
			end
		end,
	})

	appearance:Dropdown({
		Title = "Accent Color",
		Flag = "__UI_Accent",
		Options = ThemeManager:GetAccents(),
		Default = ThemeManager.CurrentAccent,
		Callback = function(accentName)
			if accentName then
				ThemeManager:SetAccent(accentName, true)
			end
		end,
	})

	appearance:Slider({
		Title = "UI Scale",
		Flag = "__UI_Scale",
		Min = 75,
		Max = 125,
		Step = 5,
		Default = 100,
		Suffix = "%",
		Callback = function(pct)
			window:SetScale((tonumber(pct) or 100) / 100)
		end,
	})

	appearance:Toggle({
		Title = "Window Transparency",
		Flag = "__UI_Transparency",
		Default = false,
		Callback = function(on)
			window:SetTransparency(on)
		end,
	})

	appearance:Slider({
		Title = "Animation Speed",
		Flag = "__UI_AnimSpeed",
		Min = 50,
		Max = 200,
		Step = 10,
		Default = 100,
		Suffix = "%",
		Callback = function(pct)
			Animator.Speed = (tonumber(pct) or 100) / 100
		end,
	})

	appearance:Toggle({
		Title = "Reduced Motion",
		Flag = "__UI_ReducedMotion",
		Default = false,
		Callback = function(on)
			Animator.ReducedMotion = on == true
		end,
	})

	-- 2. Interface & HUD Section
	local iface = tab:Section({ Title = "Interface & Overlays", Icon = "layout" })

	iface:Keybind({
		Title = "Menu Toggle Key",
		Default = window.ToggleKey,
		AllowModeChange = false,
		Callback = function(_, newKey)
			if newKey then
				window:SetToggleKey(newKey)
			end
		end,
	})

	iface:Toggle({
		Title = "Show Watermark HUD",
		Flag = "__UI_Watermark",
		Default = window.Watermark ~= nil and window.Watermark:IsVisible() or false,
		Callback = function(on)
			if window.Watermark then
				window.Watermark:SetVisible(on)
			end
		end,
	})

	iface:Toggle({
		Title = "Show Active Keybinds HUD",
		Flag = "__UI_KeybindList",
		Default = window.KeybindList ~= nil and window.KeybindList:IsVisible() or false,
		Callback = function(on)
			if window.KeybindList then
				window.KeybindList:SetVisible(on)
			end
		end,
	})

	iface:Segmented({
		Title = "Notification Corner",
		Flag = "__UI_NotifyCorner",
		Options = { "BottomRight", "TopRight", "BottomLeft" },
		Default = "BottomRight",
		Callback = function(pos)
			if window.Notifications and pos then
				window.Notifications:SetPosition(pos)
			end
		end,
	})

	iface:Button({
		Title = "Open Spotlight Search",
		ButtonText = "Open ⌘K",
		Icon = "search",
		Callback = function()
			if window.CommandPalette then
				window.CommandPalette:Show()
			end
		end,
	})

	-- 3. Configuration Manager Section
	local cfgSec = tab:Section({ Title = "Configuration Manager", Icon = "folder" })
	local cfgName = "default"
	local selectedCfg = "default"

	cfgSec:Toggle({
		Title = "Auto Save",
		Flag = "__UI_AutoSave",
		Default = true,
		Callback = function(on)
			if window.ConfigManager then
				window.ConfigManager.AutoSaveEnabled = on == true
			end
		end,
	})

	cfgSec:Input({
		Title = "Config Name",
		Placeholder = "e.g. legit_profile",
		Default = "default",
		Callback = function(txt)
			cfgName = txt
		end,
	})

	local cfgDropdown = cfgSec:Dropdown({
		Title = "Saved Profiles",
		Options = window.ConfigManager and window.ConfigManager:List() or { "default" },
		Default = "default",
		Callback = function(val)
			selectedCfg = val
		end,
	})

	cfgSec:Button({
		Title = "Save Profile",
		ButtonText = "Save",
		Style = "Primary",
		Icon = "save",
		Callback = function()
			if not window.ConfigManager then
				return
			end
			local ok, msg = window.ConfigManager:Save(cfgName ~= "" and cfgName or selectedCfg)
			cfgDropdown:Refresh(window.ConfigManager:List(), true)
			window:Notify({
				Title = "Config Manager",
				Content = ok and ("Saved profile '" .. tostring(msg) .. "'.") or tostring(msg),
				Type = ok and "Success" or "Warning",
			})
		end,
	})

	cfgSec:Button({
		Title = "Load Selected Profile",
		ButtonText = "Load",
		Icon = "download",
		Callback = function()
			if not window.ConfigManager then
				return
			end
			local ok, msg = window.ConfigManager:Load(selectedCfg)
			window:Notify({
				Title = "Config Manager",
				Content = tostring(msg),
				Type = ok and "Info" or "Warning",
			})
		end,
	})

	cfgSec:Button({
		Title = "Delete Selected Profile",
		ButtonText = "Delete",
		Style = "Destructive",
		Confirm = true,
		Icon = "trash-2",
		Callback = function()
			if not window.ConfigManager then
				return
			end
			window.ConfigManager:Delete(selectedCfg)
			cfgDropdown:Refresh(window.ConfigManager:List(), false)
			window:Notify({
				Title = "Config Manager",
				Content = "Deleted profile '" .. tostring(selectedCfg) .. "'.",
				Type = "Info",
			})
		end,
	})

	cfgSec:Button({
		Title = "Export JSON to Clipboard",
		ButtonText = "Copy JSON",
		Icon = "copy",
		Callback = function()
			if not window.ConfigManager then
				return
			end
			local ok = window.ConfigManager:ExportClipboard()
			window:Notify({
				Title = "Config Export",
				Content = ok and "Copied configuration JSON to clipboard." or "Clipboard unavailable in this executor.",
				Type = ok and "Success" or "Warning",
			})
		end,
	})

	cfgSec:Button({
		Title = "Unload Interface",
		ButtonText = "Unload",
		Style = "Destructive",
		Confirm = true,
		Icon = "power",
		Callback = function()
			window:Destroy()
		end,
	})

	return tab
end

return SettingsTab
end

-- [[ Module: Window/Window ]]
__modules["Window/Window"] = function(require)
local Env = require("Core/Env")
local Maid = require("Core/Maid")
local Creator = require("Core/Creator")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Spring = require("Motion/Spring")
local Shadow = require("Components/Shadow")
local Popover = require("Components/Popover")

local TitleBar = require("Window/TitleBar")
local Sidebar = require("Window/Sidebar")
local MinimizedPill = require("Window/MinimizedPill")
local MobileToggle = require("Window/MobileToggle")
local Tab = require("Window/Tab")

local Notifications = require("Overlays/Notifications")
local Dialog = require("Overlays/Dialog")
local CommandPalette = require("Overlays/CommandPalette")
local ContextMenu = require("Overlays/ContextMenu")
local Tooltip = require("Overlays/Tooltip")
local KeybindList = require("Overlays/KeybindList")
local Watermark = require("Overlays/Watermark")
local LoadingScreen = require("Overlays/LoadingScreen")
local KeySystem = require("Overlays/KeySystem")

local Flags = require("Systems/Flags")
local ConfigManager = require("Systems/ConfigManager")
local InputManager = require("Systems/InputManager")
local SettingsTab = require("Systems/SettingsTab")

local Window = {}
Window.__index = Window

function Window.new(library, opts)
	opts = opts or {}

	if opts.Theme then
		ThemeManager:SetTheme(opts.Theme, false)
	end
	if opts.Accent then
		ThemeManager:SetAccent(opts.Accent, false)
	end

	local maid = Maid.new()

	local screenGui = Creator.new("ScreenGui", {
		Name = opts.Name or "PerfectusUI_Suite",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = 999,
	})
	Env.mountGui(screenGui)
	maid:Add(screenGui)

	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local baseW = opts.Width or 620
	local baseH = opts.Height or 420
	local autoScale = 1
	if Env.IsMobile or vp.X < 700 or vp.Y < 480 then
		autoScale = math.clamp(math.min((vp.X - 24) / baseW, (vp.Y - 24) / baseH), 0.65, 1)
	end

	local startX = math.floor(vp.X * 0.5)
	local startY = math.floor(vp.Y * 0.5)

	local root = Creator.new("Frame", {
		Name = "WindowRoot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(startX, startY),
		Size = UDim2.fromOffset(baseW, baseH),
		BackgroundTransparency = 0,
		ClipsDescendants = false,
		ZIndex = 1,
		ThemeBind = { BackgroundColor3 = "WindowBg" },
		Parent = screenGui,
	}, {
		Creator.corner(18),
		Creator.stroke("InnerStroke", 1.5, 0.15),
	})

	local uiScale = Creator.new("UIScale", {
		Scale = autoScale * 0.94,
		Parent = root,
	})

	Shadow.create(root, 32, 0.38, 0)

	local chrome = Creator.new("Frame", {
		Name = "Chrome",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = root,
	}, {
		Creator.corner(18),
	})

	local overlayLayer = Creator.new("Frame", {
		Name = "OverlayLayer",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 180,
		Parent = root,
	})

	Popover.init(overlayLayer, uiScale)

	-- Floating Bento Content Area (Right of the 56px Floating Capsule Dock, Below the 44px Floating Header)
	local pagesContainer = Creator.new("Frame", {
		Name = "PagesContainer",
		Position = UDim2.fromOffset(76, 62),
		Size = UDim2.new(1, -86, 1, -72),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = chrome,
	})

	local self = setmetatable({
		Library = library,
		Maid = maid,
		ScreenGui = screenGui,
		Root = root,
		Chrome = chrome,
		OverlayLayer = overlayLayer,
		PagesContainer = pagesContainer,
		UIScale = uiScale,
		BaseScale = autoScale,
		UserScale = 1,
		ToggleKey = opts.ToggleKey or opts.MinimizeKey or Enum.KeyCode.RightShift,
		ConfigFolder = opts.ConfigFolder or "PerfectusUI",
		Visible = true,
		Minimized = false,
		Transparent = false,
		Tabs = {},
		ActiveTab = nil,
		Flags = Flags.new(),
	}, Window)

	self._notifyError = function(scope, msg)
		self:Notify({
			Title = tostring(scope),
			Content = tostring(msg),
			Type = "Error",
			Duration = 5,
		})
	end

	self.Notifications = Notifications.new(screenGui)
	self.Tooltip = Tooltip.new(screenGui)
	self.CommandPalette = CommandPalette.new(self)
	self.KeybindList = KeybindList.new(self, opts.ShowKeybindList == true)
	self.Watermark = Watermark.new(self, {
		Title = opts.WatermarkTitle or opts.Title or "Perfectus",
		Icon = opts.Icon,
		Visible = opts.Watermark == true,
	})

	self.TitleBar = TitleBar.create(self, opts)
	self.Sidebar = Sidebar.create(self, opts)
	self.MinimizedPill = MinimizedPill.create(self, opts)
	self.MobileToggle = MobileToggle.create(self, opts)
	self.ConfigManager = ConfigManager.new(self, self.ConfigFolder)

	InputManager.attach(self)

	Animator.spring(uiScale, "Scale", autoScale, { frequency = 16, damping = 0.82 })

	if opts.LoadingScreen == true then
		LoadingScreen.play(self, opts)
	end

	if opts.KeySystem then
		KeySystem.gate(self, opts.KeySystem, function() end)
	end

	if opts.Transparency == true then
		self:SetTransparency(true)
	end

	self._autoSettingsTab = opts.SettingsTab == true
	self._autoLoadConfig = opts.AutoLoadConfig == true
	self._finalized = false

	task.defer(function()
		if not self._finalized and self.ScreenGui.Parent then
			self:Ready()
		end
	end)

	return self
end

function Window:_registerTooltip(guiObj, textOrProvider)
	if self.Tooltip and textOrProvider ~= nil then
		self.Tooltip:Bind(guiObj, textOrProvider)
	end
end

function Window:_registerContextMenu(guiObj, control)
	ContextMenu.bind(self, guiObj, control)
end

function Window:_registerSearchable(control, section)
	if self.CommandPalette then
		self.CommandPalette:Register(control, section)
	end
end

function Window:_registerKeybindEntry(control)
	if self.KeybindList then
		self.KeybindList:Register(control)
	end
end

function Window:_updateKeybindEntry()
	if self.KeybindList and self.KeybindList:IsVisible() then
		self.KeybindList:Refresh()
	end
end

function Window:TabGroup(title)
	return self.Sidebar:AddGroupHeader(title)
end

function Window:Tab(opts)
	local tab = Tab.new(self, opts)
	self.Tabs[#self.Tabs + 1] = tab
	if not self.ActiveTab then
		self:SelectTab(tab)
	end
	return tab
end
Window.AddTab = Window.Tab
Window.CreateTab = Window.Tab

function Window:SelectTab(tabOrIndex)
	Popover.close()
	local target = tabOrIndex
	if type(tabOrIndex) == "number" then
		target = self.Tabs[tabOrIndex]
	elseif type(tabOrIndex) == "string" then
		for _, t in ipairs(self.Tabs) do
			if t.Title == tabOrIndex then
				target = t
				break
			end
		end
	end
	if not target then
		return
	end

	self.ActiveTab = target
	for _, t in ipairs(self.Tabs) do
		local isCurrent = (t == target)
		t.Page.Visible = isCurrent
		if isCurrent then
			t.Page.Position = UDim2.fromOffset(0, 6)
			Animator.spring(t.Page, "Position", UDim2.fromOffset(0, 0), { frequency = 20, damping = 0.86 })
		end
	end
	self.Sidebar:UpdateActive(target)
	if self.TitleBar and self.TitleBar.SetActiveTabTitle then
		self.TitleBar:SetActiveTabTitle(target.Title)
	end
end

function Window:FilterActiveTab(query)
	if self.ActiveTab and self.ActiveTab.ApplyFilter then
		self.ActiveTab:ApplyFilter(query)
	end
end

function Window:ToggleSidebar()
	Popover.close()
	local newW = self.Sidebar:SetCollapsed(not self.Sidebar:IsCollapsed())
	local leftX = newW > 0 and (newW + 20) or 10
	Animator.spring(self.PagesContainer, "Position", UDim2.fromOffset(leftX, 62), { frequency = 18, damping = 0.86 })
	Animator.spring(
		self.PagesContainer,
		"Size",
		UDim2.new(1, -(leftX + 10), 1, -72),
		{ frequency = 18, damping = 0.86 }
	)
end

function Window:MinimizeToPill(minimize)
	Popover.close()
	self.Minimized = minimize == true
	if self.Minimized then
		Animator.spring(self.UIScale, "Scale", self.BaseScale * self.UserScale * 0.88, {
			frequency = 20,
			damping = 0.88,
			onComplete = function()
				if self.Minimized then
					self.Root.Visible = false
				end
			end,
		})
		self.MinimizedPill:Show()
	else
		self.MinimizedPill:Hide()
		self.Root.Visible = true
		self.Visible = true
		Animator.spring(self.UIScale, "Scale", self.BaseScale * self.UserScale, { frequency = 18, damping = 0.82 })
	end
end

function Window:SetVisible(vis)
	Popover.close()
	self.Visible = vis == true
	if self.Minimized and self.Visible then
		self:MinimizeToPill(false)
		return
	end
	if self.Visible then
		self.Root.Visible = true
		Animator.spring(self.UIScale, "Scale", self.BaseScale * self.UserScale, { frequency = 18, damping = 0.84 })
	else
		self.Root.Visible = false
	end
end

function Window:ToggleVisibility()
	self:SetVisible(not self.Visible)
end
Window.Minimize = Window.ToggleVisibility

function Window:SetScale(mult)
	self.UserScale = math.clamp(tonumber(mult) or 1, 0.7, 1.35)
	Animator.spring(self.UIScale, "Scale", self.BaseScale * self.UserScale, { frequency = 18, damping = 0.85 })
end

function Window:SetTransparency(on)
	self.Transparent = on == true
	local winTrans = self.Transparent and 0.14 or 0
	local sideTrans = self.Transparent and 0.18 or 0
	Animator.tween(self.Root, { BackgroundTransparency = winTrans }, 0.2)
	Animator.tween(self.Sidebar.Frame, { BackgroundTransparency = sideTrans }, 0.2)
end

function Window:SetToggleKey(newKey)
	self.ToggleKey = newKey
	if self.TitleBar and self.TitleBar.UpdateKeyText then
		self.TitleBar:UpdateKeyText(newKey)
	end
end

function Window:Notify(opts)
	return self.Notifications:Notify(opts)
end

function Window:Dialog(opts)
	return Dialog.show(self, opts)
end

function Window:PromptClose()
	self:Dialog({
		Title = "Close Interface",
		Content = "Minimize to the floating bar or unload the script?",
		Buttons = {
			{ Title = "Cancel", Style = "Secondary" },
			{
				Title = "Minimize",
				Style = "Primary",
				Callback = function()
					self:MinimizeToPill(true)
				end,
			},
			{
				Title = "Unload",
				Style = "Destructive",
				Callback = function()
					self:Destroy()
				end,
			},
		},
	})
end

function Window:Ready()
	if self._finalized then
		return
	end
	self._finalized = true
	if self._autoSettingsTab then
		SettingsTab.build(self)
	end
	if self._autoLoadConfig and self.ConfigManager then
		self.ConfigManager:LoadAutoSave()
	end
	if self.Tabs[1] and not self.ActiveTab then
		self:SelectTab(1)
	end
end

function Window:Destroy()
	Popover.close()
	Spring.stopAll()
	self.Maid:Clean()
end

return Window
end

-- [[ Module: init ]]
__modules["init"] = function(require)
local Env = require("Core/Env")
local Themes = require("Theme/Themes")
local ThemeManager = require("Theme/ThemeManager")
local Icons = require("Assets/Icons")
local Window = require("Window/Window")

local PerfectusUI = {
	Version = "1.0.0",
	Themes = Themes.ThemeOrder,
	Accents = Themes.AccentOrder,
	Icons = Icons,
	Flags = nil,
	ActiveWindow = nil,
}

function PerfectusUI:CreateWindow(opts)
	opts = opts or {}
	local genv = Env.getGlobalEnv()
	if type(genv.__PerfectusUICleanup) == "function" then
		pcall(genv.__PerfectusUICleanup)
	end

	local win = Window.new(self, opts)
	self.ActiveWindow = win
	self.Flags = win.Flags
	genv.PerfectusUI = self

	genv.__PerfectusUICleanup = function()
		if self.ActiveWindow == win then
			self.ActiveWindow = nil
		end
		pcall(function()
			win:Destroy()
		end)
	end
	if type(STATE) == "table" and type(STATE.onCleanup) == "function" then
		pcall(STATE.onCleanup, genv.__PerfectusUICleanup)
	end

	return win
end

function PerfectusUI:Notify(opts)
	if self.ActiveWindow then
		return self.ActiveWindow:Notify(opts)
	end
	return nil
end

function PerfectusUI:Dialog(opts)
	if self.ActiveWindow then
		return self.ActiveWindow:Dialog(opts)
	end
	return nil
end

function PerfectusUI:SetTheme(themeName)
	ThemeManager:SetTheme(themeName, true)
end

function PerfectusUI:SetAccent(accentNameOrColor)
	ThemeManager:SetAccent(accentNameOrColor, true)
end

function PerfectusUI:RegisterTheme(name, palette)
	ThemeManager:RegisterTheme(name, palette)
end

function PerfectusUI:ToggleTransparency(on)
	if self.ActiveWindow then
		self.ActiveWindow:SetTransparency(on == true)
	end
end

function PerfectusUI:Destroy()
	if self.ActiveWindow then
		self.ActiveWindow:Destroy()
		self.ActiveWindow = nil
	end
end

return PerfectusUI
end

    return __require("init")
end)()

-- Perfectus UI — Clean, Minimal Showcase Example
-- PerfectusUI inline above

local Window = PerfectusUI:CreateWindow({
	Title = "Perfectus",
	Theme = "Obsidian",
	Accent = "Indigo",
	Width = 620,
	Height = 420,
	ToggleKey = Enum.KeyCode.RightShift,
	Watermark = false,
	ShowKeybindList = false,
	LoadingScreen = false,
	SettingsTab = true,
	AutoLoadConfig = false,
	ConfigFolder = "PerfectusUI_Showcase",
})

-- ============================================================
-- Tab 1: Auto Farm
-- ============================================================
local FarmTab = Window:Tab({
	Title = "Auto Farm",
	Icon = "zap",
})

local MainCard = FarmTab:Section({ Title = "Auto Farm" })

MainCard:Toggle({
	Title = "Auto Farm",
	Flag = "AutoFarm",
	Default = true,
	Key = Enum.KeyCode.F,
})

MainCard:Toggle({
	Title = "Auto Collect",
	Flag = "AutoCollect",
	Default = true,
	Key = Enum.KeyCode.G,
})

MainCard:Slider({
	Title = "Attack Interval",
	Flag = "AttackInterval",
	Min = 0.01,
	Max = 1.00,
	Step = 0.01,
	Default = 0.05,
	Suffix = "s",
})

MainCard:Dropdown({
	Title = "Target Zone",
	Flag = "TargetZone",
	Options = {
		"Starter Meadow",
		"Crystal Cavern",
		"Obsidian Citadel",
		"Celestial Sanctum",
		"Abyssal Rift",
	},
	Default = "Starter Meadow",
})

MainCard:Segmented({
	Title = "Farm Mode",
	Flag = "FarmMode",
	Options = { "Legit", "Fast", "Instant" },
	Default = "Fast",
})

local ActionsCard = FarmTab:Section({ Title = "Quick Actions", Icon = "sparkles" })

ActionsCard:Button({
	Title = "Claim All Rewards",
	Style = "Primary",
	Callback = function()
		Window:Notify({
			Title = "Rewards Claimed",
			Content = "Collected all pending chests and daily rewards.",
			Type = "Success",
			Duration = 3,
		})
	end,
})

ActionsCard:Button({
	Title = "Reset Session Stats",
	Callback = function()
		Window:Notify({
			Title = "Stats Reset",
			Content = "Session counters have been cleared.",
			Type = "Info",
			Duration = 3,
		})
	end,
})

-- ============================================================
-- Tab 2: Combat & Upgrades
-- ============================================================
local CombatTab = Window:Tab({
	Title = "Combat",
	Icon = "swords",
})

local CombatCard = CombatTab:Section({ Title = "Combat" })

CombatCard:Checkbox({
	Title = "Auto Upgrade Equipped",
	Flag = "AutoUpgrade",
	Default = true,
})

CombatCard:Dropdown({
	Title = "Rarity Filter",
	Flag = "RarityFilter",
	Multi = true,
	Options = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" },
	Default = { "Legendary", "Mythic", "Secret" },
})

CombatCard:RangeSlider({
	Title = "Target Distance",
	Flag = "TargetRange",
	Min = 5,
	Max = 150,
	Step = 5,
	Default = { 15, 85 },
	Suffix = "m",
})

CombatCard:Stepper({
	Title = "Burst Count",
	Flag = "BurstCount",
	Min = 1,
	Max = 16,
	Step = 1,
	Default = 4,
	Suffix = "x",
})

-- ============================================================
-- Tab 3: Player
-- ============================================================
local PlayerTab = Window:Tab({
	Title = "Player",
	Icon = "user",
})

local MoveCard = PlayerTab:Section({ Title = "Player" })

MoveCard:Toggle({
	Title = "WalkSpeed",
	Flag = "WalkSpeedToggle",
	Default = false,
	Key = Enum.KeyCode.V,
})

MoveCard:Slider({
	Title = "Speed",
	Flag = "WalkSpeedVal",
	Min = 16,
	Max = 350,
	Step = 1,
	Default = 64,
	Suffix = " ws",
})

MoveCard:Toggle({
	Title = "Flight",
	Flag = "FlyToggle",
	Default = false,
	Key = Enum.KeyCode.X,
})

MoveCard:Slider({
	Title = "Flight Speed",
	Flag = "FlySpeedVal",
	Min = 20,
	Max = 400,
	Step = 5,
	Default = 110,
	Suffix = " studs/s",
})

MoveCard:Dropdown({
	Title = "Teleport to Player",
	Flag = "TargetPlayer",
	Options = "Players",
	AllowNone = true,
})

-- ============================================================
-- Tab 4: Visuals
-- ============================================================
local VisualsTab = Window:Tab({
	Title = "Visuals",
	Icon = "eye",
})

local EspCard = VisualsTab:Section({ Title = "Visuals" })

EspCard:Toggle({
	Title = "ESP Highlights",
	Flag = "EspEnabled",
	Default = true,
})

EspCard:ColorPicker({
	Title = "Ally Color",
	Flag = "AllyColor",
	Default = Color3.fromRGB(16, 185, 129),
})

EspCard:ColorPicker({
	Title = "Enemy Color",
	Flag = "EnemyColor",
	Default = Color3.fromRGB(244, 63, 94),
})

EspCard:RadioGroup({
	Title = "Tracer Origin",
	Flag = "TracerOrigin",
	Options = { "Bottom", "Center", "Mouse" },
	Default = "Center",
})

-- ============================================================
-- Tab 5: Elements
-- ============================================================
local ElementsTab = Window:Tab({
	Title = "Elements",
	Icon = "box",
})

local ExtraCard = ElementsTab:Section({ Title = "Elements" })

ExtraCard:Input({
	Title = "Webhook URL",
	Flag = "WebhookUrl",
	Placeholder = "https://discord.com/api/webhooks/...",
	Finished = true,
})

ExtraCard:Keybind({
	Title = "Dash Hotkey",
	Flag = "DashKey",
	Default = Enum.KeyCode.Q,
	Mode = "Hold",
})

ExtraCard:Stat({
	Title = "Session Rate",
	Value = "1,240 / hr",
})

ExtraCard:ProgressBar({
	Title = "Wave Progress",
	Default = 72,
	Status = "18 / 25",
})

Window:Ready()
Window:Notify({
	Title = "Perfectus Ready",
	Content = "Press RightShift to toggle menu.",
	Type = "Success",
	Duration = 3.5,
})
