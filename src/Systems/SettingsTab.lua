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
