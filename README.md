# Perfectus UI — Premium macOS & iOS Style UI Library for Roblox (Luau)

A modular, high-performance, zero-overlap Luau UI framework inspired by **macOS Sonoma/Sequoia** window chrome and **iOS Settings** grouped card hierarchy. Built for clean multi-file development under `src/` with a zero-dependency Node.js bundler (`build/build.mjs`) that compiles all 55 modules into a single standalone file (`dist/PerfectusUI.lua`) plus a ready-to-execute showcase (`dist/Example.lua`).

---

## Quick Start

### Load Library Only
```lua
local PerfectusUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/perfectusmim1/PerfectusUI/main/dist/PerfectusUI.lua"))()

local Window = PerfectusUI:CreateWindow({
	Title = "Perfectus Hub",
	Subtitle = "by Perfectus",
	Theme = "Dark",          -- "Dark" | "Midnight" | "Graphite" | "Light"
	Accent = "Blue",         -- "Blue" | "Purple" | "Indigo" | "Pink" | "Orange" | "Green" | "Teal" | "Red"
	ToggleKey = Enum.KeyCode.RightShift,
	Watermark = true,
	ShowKeybindList = true,
	SettingsTab = true,
	AutoLoadConfig = true,
	ConfigFolder = "PerfectusUI",
})

local MainTab = Window:Tab({ Title = "Main", Icon = "zap", Badge = "NEW" })
local Section = MainTab:Section({ Title = "Automation", Icon = "cpu" })

Section:Toggle({
	Title = "Auto Farm",
	Flag = "AutoFarm",
	Icon = "flame",
	Default = false,
	Key = Enum.KeyCode.F,
	Callback = function(state)
		print("Auto Farm:", state)
	end,
})

Window:Ready()
```

### Run Full Interactive Showcase (`dist/Example.lua`)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/perfectusmim1/PerfectusUI/main/dist/Example.lua"))()
```

---

## Modular Source Architecture (`55 Modules`)

```text
PerfectusUI/
├── build/
│   └── build.mjs                     # Topological module bundler -> dist/PerfectusUI.lua & dist/Example.lua
├── src/
│   ├── init.lua                      # Public API entrypoint
│   ├── Assets/
│   │   └── Icons.lua                 # 820+ verified Lucide rbxassetid:// icons + semantic aliases
│   ├── Core/
│   │   ├── Services.lua              # Cloned Roblox services (cloneref)
│   │   ├── Env.lua                   # UNC & executor capability shims (100% UNC + Xeno ~85% + Mobile)
│   │   ├── Maid.lua                  # Deterministic resource cleanup & hot-reload teardown
│   │   ├── Signal.lua                # Pure Luau signal dispatcher
│   │   ├── Util.lua                  # Text measurement, rounding, color math (HSV/HEX/RGB), ripple
│   │   └── Creator.lua               # Declarative instance builder + automatic theme binding
│   ├── Theme/
│   │   ├── Themes.lua                # 4 Apple themes (Dark, Midnight, Graphite, Light) + 8 accents
│   │   └── ThemeManager.lua          # Reactive live theme/accent switcher
│   ├── Motion/
│   │   ├── Spring.lua                # Critically-damped physics solver (auto-disconnects when idle)
│   │   └── Animator.lua              # Unified Spring & Tween helper
│   ├── Components/
│   │   ├── Shadow.lua                # 9-slice soft elevation shadow
│   │   ├── Scroll.lua                # Auto-fading inertial scroll container
│   │   ├── Popover.lua               # Top-level overlay manager (auto-flips upward near screen bottom)
│   │   └── RowBase.lua               # Standardized iOS Settings row with hairline divider & lock state
│   ├── Window/
│   │   ├── Window.lua                # Main window shell, UIScale, responsive viewport adapter
│   │   ├── TitleBar.lua              # Traffic-light controls, drag bar, Spotlight search trigger
│   │   ├── Sidebar.lua               # Collapsible sidebar with sliding spring pill & profile card
│   │   ├── Tab.lua                   # Tab page container with smooth spring transitions
│   │   ├── Section.lua               # Grouped card section with collapsible header & element factory
│   │   ├── MinimizedPill.lua         # Dynamic Island minimized pill bar
│   │   └── MobileToggle.lua          # Draggable floating mobile glass button
│   ├── Elements/                     # 19 UI Controls
│   │   ├── Button.lua                # Primary, Secondary, Destructive & Ghost buttons + Confirm mode
│   │   ├── Toggle.lua                # iOS spring pill switch + optional companion Keybind badge
│   │   ├── Checkbox.lua              # Rounded Apple checkbox with animated check icon
│   │   ├── Slider.lua                # Precision scrubbable slider + clickable direct numeric input
│   │   ├── RangeSlider.lua           # Dual-thumb Min/Max interval slider
│   │   ├── Dropdown.lua              # Searchable single & multi-select popover + live Player/Team lists
│   │   ├── Input.lua                 # Text/Number/Password input with clear & eye-reveal buttons
│   │   ├── Keybind.lua               # Keyboard & Mouse button binder with Hold / Toggle / Always modes
│   │   ├── ColorPicker.lua           # HSV saturation matrix, hue bar, alpha slider, HEX/RGB & Rainbow
│   │   ├── Segmented.lua             # Apple UISegmentedControl with sliding thumb
│   │   ├── Stepper.lua               # - / + incremental stepper control
│   │   ├── RadioGroup.lua            # Grouped mutually exclusive radio selector
│   │   ├── ProgressBar.lua           # Animated progress indicator with status & percentage
│   │   ├── Stat.lua                  # Live telemetry key-value metric row
│   │   ├── Label.lua                 # Dynamic single-line text & icon row
│   │   ├── Paragraph.lua             # Auto-sizing multi-line rich card
│   │   ├── Divider.lua               # Section separator with optional centered label
│   │   ├── Image.lua                 # Aspect-fit image preview card with caption
│   │   └── CodeBlock.lua             # Monospace code viewer with one-click Copy button
│   ├── Overlays/                     # 9 Top-Level Overlays
│   │   ├── Notifications.lua         # Stacked toast notifications with pause-on-hover & progress bar
│   │   ├── Dialog.lua                # Blurred modal confirmation dialog
│   │   ├── CommandPalette.lua        # Cmd+K / Ctrl+K Spotlight search across all tabs & controls
│   │   ├── ContextMenu.lua           # Right-click context menu (Reset, Copy Flag, Bind Key, Lock)
│   │   ├── Tooltip.lua               # Edge-clamped hover tooltip
│   │   ├── KeybindList.lua           # Draggable floating active keybinds HUD
│   │   ├── Watermark.lua             # Draggable live FPS / Ping / Time pill HUD
│   │   ├── LoadingScreen.lua         # Animated startup splash overlay
│   │   └── KeySystem.lua             # Optional license key gate overlay
│   └── Systems/
│       ├── Flags.lua                 # Reactive Window.Flags[flag] store & listener registry
│       ├── ConfigManager.lua         # JSON profile save/load/delete, clipboard import/export & autosave
│       ├── InputManager.lua          # Global shortcut router (ToggleKey, Ctrl+K, Keybinds)
│       └── SettingsTab.lua           # Built-in Settings tab generator
├── examples/
│   └── Example.lua                   # Comprehensive interactive showcase of all 19 elements & 9 overlays
├── adapters/
│   └── adapter-perfectus-ui.lua      # Drop-in adapter for Perfectus Script (core-template.lua)
└── dist/
    ├── PerfectusUI.lua               # Bundled standalone UI library
    └── Example.lua                   # Bundled standalone showcase script (Library + Example)
```

---

## Building from Source

```bash
# Format all Luau sources with StyLua
stylua src examples adapters

# Bundle src/**/*.lua into dist/PerfectusUI.lua and dist/Example.lua
node build/build.mjs
```
