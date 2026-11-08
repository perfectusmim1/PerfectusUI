local PerfectusUI = require("init")

local Window = PerfectusUI:CreateWindow({
	Title = "Perfectus",
	Subtitle = "by Perfectus",
	Icon = "sparkles",
	Theme = "Dark",
	Accent = "Blue",
	ConfigFolder = "PerfectusHub/Showcase",
	ToggleKey = Enum.KeyCode.RightShift,
	LoadingScreen = true,
	SettingsTab = true,
	AutoLoadConfig = false,
	Watermark = true,
	ShowKeybindList = true,
})

-- ============================================================
-- Group 1: Overview & Automation
-- ============================================================
Window:TabGroup("Automation")

local DashboardTab = Window:Tab({
	Title = "Dashboard",
	Icon = "layout-dashboard",
	Badge = "NEW",
})

local TelemetrySec = DashboardTab:Section({ Title = "Live Session Telemetry", Icon = "activity" })
local StatusStat = TelemetrySec:Stat({
	Title = "Engine Status",
	Icon = "shield-check",
	Value = "Optimal (Zero Idle)",
	ColorToken = "Success",
})
local CoinsStat = TelemetrySec:Stat({
	Title = "Farming Yield / Min",
	Icon = "coins",
	Value = "24,850 / min",
	ColorToken = "Accent",
})
local MasteryProgress = TelemetrySec:ProgressBar({
	Title = "Season Pass Progression",
	Icon = "award",
	Default = 68,
	Max = 100,
	Suffix = "%",
	Tooltip = "Live animated spring progress bar",
})

TelemetrySec:Button({
	Title = "Simulate Progression Burst",
	Icon = "zap",
	Style = "Primary",
	ButtonText = "Boost +15%",
	Callback = function()
		local nextVal = (MasteryProgress:Get() + 15) % 105
		MasteryProgress:Set(math.min(100, nextVal))
		CoinsStat:Set(string.format("%d,400 / min", math.random(25, 89)))
		Window:Notify({
			Title = "Telemetry Updated",
			Content = "Progression bar updated to " .. tostring(math.floor(MasteryProgress:Get())) .. "%.",
			Type = "Success",
			Duration = 3,
		})
	end,
})

local QuickActionsSec =
	DashboardTab:Section({ Title = "System Controls & Dialogs", Icon = "command", Collapsible = true })

QuickActionsSec:Button({
	Title = "Open Spotlight Command Palette",
	Icon = "search",
	ButtonText = "Open ⌘K",
	Tooltip = "Fuzzy search every control across all tabs (or press Ctrl+K)",
	Callback = function()
		Window.CommandPalette:Show()
	end,
})

QuickActionsSec:Button({
	Title = "Trigger Modal Confirmation Dialog",
	Icon = "message-square",
	ButtonText = "Open Modal",
	Callback = function()
		Window:Dialog({
			Title = "Reset Session Metrics?",
			Content = "This will reset your session counters and recalibrate the farming rate estimator.",
			Buttons = {
				{ Title = "Cancel", Style = "Secondary" },
				{
					Title = "Recalibrate",
					Style = "Primary",
					Callback = function()
						CoinsStat:Set("0 / min")
						MasteryProgress:Set(0)
						Window:Notify({
							Title = "Session Reset",
							Content = "Telemetry counters have been reset.",
							Type = "Info",
						})
					end,
				},
			},
		})
	end,
})

QuickActionsSec:Button({
	Title = "Two-Step Destructive Action",
	Icon = "alert-triangle",
	Style = "Destructive",
	ButtonText = "Purge Cache",
	Confirm = true,
	Tooltip = "Requires a second click within 2.5s to confirm",
	Callback = function()
		Window:Notify({
			Title = "Cache Purged",
			Content = "Temporary session cache cleared cleanly.",
			Type = "Warning",
		})
	end,
})

-- ============================================================
-- Tab 2: Farming & Combat (Interactive Controls)
-- ============================================================
local MainTab = Window:Tab({
	Title = "Main & Farm",
	Icon = "sprout",
})

local AutoSec = MainTab:Section({ Title = "Automated Farming", Icon = "zap" })

AutoSec:Toggle({
	Title = "Auto Farm Nearest Target",
	Flag = "AutoFarm",
	Icon = "swords",
	Default = true,
	Key = Enum.KeyCode.F,
	Tooltip = "Right-click any row for context actions (Reset, Copy Value, Copy Flag)",
	Callback = function(state)
		StatusStat:Set(state and "Farming Active" or "Idle")
	end,
})

AutoSec:Toggle({
	Title = "Auto Collect Orbs & Loot",
	Flag = "AutoCollect",
	Icon = "sparkles",
	Default = false,
	Key = Enum.KeyCode.G,
})

AutoSec:Checkbox({
	Title = "Prioritize Boss Entities",
	Flag = "PrioritizeBosses",
	Icon = "crown",
	Default = true,
})

AutoSec:Segmented({
	Title = "Attack Mode",
	Flag = "AttackMode",
	Icon = "crosshair",
	Options = { "Legit", "Fast", "Instant" },
	Default = "Fast",
})

AutoSec:Dropdown({
	Title = "Target World Zone",
	Flag = "TargetZone",
	Icon = "map-pin",
	Options = {
		"Zone 1 - Sakura Grove",
		"Zone 2 - Cyber District",
		"Zone 3 - Obsidian Citadel",
		"Zone 4 - Astral Sanctum",
		"Zone 5 - Void Singularity",
		"Zone 6 - Celestial Spire",
		"Zone 7 - Chrono Vault",
		"Zone 8 - Sovereign Throne",
	},
	Default = "Zone 2 - Cyber District",
	Search = true,
})

AutoSec:Dropdown({
	Title = "Auto-Upgrade Attributes",
	Flag = "UpgradeStats",
	Icon = "trending-up",
	Multi = true,
	Options = { "Damage", "Critical Chance", "Attack Speed", "Luck Multiplier", "Movement Speed" },
	Default = { "Damage", "Luck Multiplier" },
})

local TuningSec = MainTab:Section({ Title = "Precision Tuning", Icon = "sliders" })

TuningSec:Slider({
	Title = "Engagement Radius",
	Flag = "EngageRadius",
	Icon = "radar",
	Min = 10,
	Max = 250,
	Step = 5,
	Default = 85,
	Suffix = " studs",
})

TuningSec:RangeSlider({
	Title = "Reaction Delay Window",
	Flag = "ReactionWindow",
	Icon = "clock",
	Min = 10,
	Max = 500,
	Step = 10,
	Default = { 60, 180 },
	Suffix = " ms",
})

TuningSec:Stepper({
	Title = "Multi-Target Batch Limit",
	Flag = "BatchLimit",
	Icon = "layers",
	Min = 1,
	Max = 20,
	Step = 1,
	Default = 4,
	Suffix = " mobs",
})

-- ============================================================
-- Group 2: Character & Visuals
-- ============================================================
Window:TabGroup("Character & Visuals")

local PlayerTab = Window:Tab({
	Title = "Player",
	Icon = "user",
})

local MoveSec = PlayerTab:Section({ Title = "Movement & Physics", Icon = "wind" })

MoveSec:Toggle({
	Title = "WalkSpeed Override",
	Flag = "WalkSpeedToggle",
	Icon = "footprints",
	Default = false,
	Key = Enum.KeyCode.V,
})

MoveSec:Slider({
	Title = "WalkSpeed Value",
	Flag = "WalkSpeedVal",
	Min = 16,
	Max = 350,
	Step = 1,
	Default = 64,
	Suffix = " ws",
})

MoveSec:Toggle({
	Title = "Omnidirectional Flight",
	Flag = "FlyToggle",
	Icon = "plane",
	Default = false,
	Key = Enum.KeyCode.X,
})

MoveSec:Slider({
	Title = "Flight Velocity",
	Flag = "FlySpeedVal",
	Min = 20,
	Max = 400,
	Step = 5,
	Default = 110,
	Suffix = " studs/s",
})

local UtilSec = PlayerTab:Section({ Title = "Player Utilities", Icon = "compass" })

UtilSec:Dropdown({
	Title = "Spectate / Teleport to Player",
	Flag = "TargetPlayer",
	Icon = "users",
	Options = "Players",
	AllowNone = true,
})

UtilSec:Keybind({
	Title = "Quick Dash Hotkey",
	Flag = "DashKey",
	Icon = "zap",
	Default = Enum.KeyCode.Q,
	Mode = "Hold",
})

local VisualsTab = Window:Tab({
	Title = "Visuals & ESP",
	Icon = "eye",
})

local EspSec = VisualsTab:Section({ Title = "Highlight & ESP Customization", Icon = "palette" })

EspSec:Toggle({
	Title = "Enable Entity Highlights",
	Flag = "EspEnabled",
	Icon = "eye",
	Default = true,
})

EspSec:ColorPicker({
	Title = "Ally Highlight Color",
	Flag = "AllyColor",
	Icon = "shield",
	Default = Color3.fromRGB(48, 209, 88),
})

EspSec:ColorPicker({
	Title = "Enemy Highlight Color",
	Flag = "EnemyColor",
	Icon = "flame",
	Default = Color3.fromRGB(255, 69, 58),
})

EspSec:RadioGroup({
	Title = "Tracer Origin Mode",
	Flag = "TracerOrigin",
	Options = { "Screen Bottom", "Screen Center (Crosshair)", "Mouse Cursor" },
	Default = "Screen Center (Crosshair)",
})

-- ============================================================
-- Group 3: Components & Developer Reference
-- ============================================================
Window:TabGroup("Developer")

local ShowcaseTab = Window:Tab({
	Title = "All Elements",
	Icon = "box",
})

local InputSec = ShowcaseTab:Section({ Title = "Text Inputs & Validation", Icon = "type" })

InputSec:Input({
	Title = "Webhook Notification URL",
	Flag = "WebhookUrl",
	Icon = "webhook",
	Placeholder = "https://discord.com/api/webhooks/...",
	Finished = true,
})

InputSec:Input({
	Title = "Numeric Threshold Filter",
	Flag = "NumericThreshold",
	Icon = "hash",
	Numeric = true,
	Default = "1500",
})

local LockedDemo = InputSec:Toggle({
	Title = "Premium Experimental Feature",
	Icon = "lock",
	Default = false,
})
LockedDemo:Lock("Unlock via toggle below")

InputSec:Toggle({
	Title = "Unlock Experimental Control Above",
	Icon = "unlock",
	Default = false,
	Callback = function(unlocked)
		if unlocked then
			LockedDemo:Unlock()
		else
			LockedDemo:Lock("Unlock via toggle below")
		end
	end,
})

local RichSec = ShowcaseTab:Section({ Title = "Rich Display Elements", Icon = "code-2" })

RichSec:Label({
	Title = "Single-column iOS grouped card layout with zero text overlap.",
	Icon = "check-circle-2",
})

RichSec:Divider("Documentation & Code")

RichSec:Paragraph({
	Title = "Architecture Overview",
	Content = "Every control reserves its exact right-hand slot width and truncates or wraps text cleanly on the left. Popovers render in a dedicated top-level layer that automatically flips upward near screen edges.",
	Icon = "info",
})

RichSec:CodeBlock({
	Title = "Quick Start Usage",
	Code = [[local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/perfectusmim1/PerfectusUI/main/dist/PerfectusUI.lua"))()
local Window = UI:CreateWindow({ Title = "Perfectus", Subtitle = "by Perfectus" })
local Main = Window:Tab({ Title = "Main", Icon = "home" })
Main:Section("Farming"):Toggle({ Title = "Auto Farm", Flag = "AutoFarm", Key = "F" })]],
})

local ToastSec = ShowcaseTab:Section({ Title = "Notification Showcase", Icon = "bell" })

ToastSec:Button({
	Title = "Send Info / Success / Warning / Error Toasts",
	Icon = "bell-ring",
	Style = "Primary",
	ButtonText = "Send All",
	Callback = function()
		Window:Notify({
			Title = "Information",
			Content = "Spotlight search is available via Ctrl+K.",
			Type = "Info",
			Duration = 3.5,
		})
		task.wait(0.15)
		Window:Notify({
			Title = "Configuration Saved",
			Content = "Your profile was synced to disk.",
			Type = "Success",
			Duration = 4,
		})
		task.wait(0.15)
		Window:Notify({
			Title = "High Ping Detected",
			Content = "Server latency exceeded 180ms.",
			Type = "Warning",
			Duration = 4.5,
		})
	end,
})

Window:Ready()
Window:Notify({
	Title = "Perfectus UI Ready",
	Content = "Press RightShift to toggle menu or Ctrl+K for Spotlight search.",
	Type = "Success",
	Duration = 4.5,
})
