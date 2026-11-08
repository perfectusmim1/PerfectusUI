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
