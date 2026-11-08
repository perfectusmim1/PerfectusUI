-- Perfectus UI Adapter — PerfectusUI (https://github.com/perfectusmim1/PerfectusUI)
-- Paste the body below into section 6 of references/core-template.lua.

local PerfectusUI =
	loadLibrary("PerfectusUI", "https://raw.githubusercontent.com/perfectusmim1/PerfectusUI/main/dist/PerfectusUI.lua")

local Window = PerfectusUI:CreateWindow({
	Title = Config.GameName,
	SubTitle = "by Perfectus",
	Theme = "Dark",
	Accent = "Blue",
	ToggleKey = Enum.KeyCode.LeftControl,
	Watermark = true,
	ShowKeybindList = false,
	LoadingScreen = true,
	SettingsTab = false,
	AutoLoadConfig = false,
	ConfigFolder = Config.Folder,
})
restoreIdentity()

Root:Add(function()
	if type(PerfectusUI.Destroy) == "function" then
		pcall(PerfectusUI.Destroy, PerfectusUI)
	elseif type(Window.Destroy) == "function" then
		pcall(Window.Destroy, Window)
	end
end)

local function ensureSection(target)
	if type(target) == "table" and type(target.Toggle) ~= "function" and type(target.Section) == "function" then
		target._defaultSection = target._defaultSection or target:Section({ Title = target.Title or "General" })
		return target._defaultSection
	end
	return target
end

Lib = {
	themes = PerfectusUI.Themes or { "Dark", "Midnight", "Graphite", "Light" },
	defaultTheme = "Dark",
	setTheme = function(name)
		PerfectusUI:SetTheme(name)
	end,
	setTransparency = function(on)
		Window:SetTransparency(on == true)
	end,
	toggleVisible = function()
		Window:ToggleVisibility()
	end,
	notify = function(title, content)
		Window:Notify({ Title = title, Content = content, Duration = 4, Type = "Info" })
	end,
	ready = function()
		Window:Ready()
		Window:SelectTab(1)
	end,
	tab = function(name, icon)
		local tab = Window:Tab({ Title = name, Icon = icon or "layers" })
		restoreIdentity()
		return tab
	end,
	section = function(tab, name)
		local sec = tab:Section({ Title = name })
		restoreIdentity()
		return sec
	end,
	toggle = function(sec, o, value, cb)
		return ensureSection(sec):Toggle({
			Title = o.Title,
			Default = value,
			Callback = cb,
		})
	end,
	slider = function(sec, o, value, cb)
		return ensureSection(sec):Slider({
			Title = o.Title,
			Default = value,
			Min = o.Min,
			Max = o.Max,
			Step = o.Step or 1,
			Suffix = o.Suffix or "",
			Callback = cb,
		})
	end,
	dropdown = function(sec, o, value, cb)
		return ensureSection(sec):Dropdown({
			Title = o.Title,
			Values = o.Options or {},
			Multi = o.Multi == true,
			Default = value,
			Searchable = true,
			Callback = cb,
		})
	end,
	input = function(sec, o, value, cb)
		return ensureSection(sec):Input({
			Title = o.Title,
			Default = value,
			Placeholder = o.Placeholder or o.Title,
			Finished = false,
			Callback = cb,
		})
	end,
	keybind = function(sec, o, cb)
		return ensureSection(sec):Keybind({
			Title = o.Title,
			Default = o.Key,
			Mode = "Toggle",
			Callback = function()
				cb()
			end,
		})
	end,
	button = function(sec, o, cb)
		return ensureSection(sec):Button({
			Title = o.Title,
			Callback = cb,
		})
	end,
	set = function(ctrl, kind, value)
		if type(ctrl) == "table" and type(ctrl.Set) == "function" then
			ctrl:Set(value, true)
		end
	end,
	refresh = function(ctrl, options)
		if type(ctrl) == "table" and type(ctrl.Refresh) == "function" then
			ctrl:Refresh(options)
		end
	end,
}
