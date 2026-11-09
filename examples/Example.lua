-- Perfectus UI — Clean, Minimal Showcase Example
local PerfectusUI = require("init")

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
