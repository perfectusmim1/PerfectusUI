local Services = require("Core/Services")
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
	local baseW = opts.Width or 680
	local baseH = opts.Height or 460
	local autoScale = 1
	if Env.IsMobile or vp.X < 740 or vp.Y < 520 then
		autoScale = math.clamp(math.min((vp.X - 24) / baseW, (vp.Y - 24) / baseH), 0.65, 1)
	end

	local root = Creator.new("Frame", {
		Name = "WindowRoot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(baseW, baseH),
		BackgroundTransparency = 0,
		ClipsDescendants = false,
		ZIndex = 1,
		ThemeBind = { BackgroundColor3 = "WindowBg" },
		Parent = screenGui,
	}, {
		Creator.corner(14),
		Creator.stroke("InnerStroke", 1, 0.25),
	})

	local uiScale = Creator.new("UIScale", {
		Scale = autoScale * 0.96,
		Parent = root,
	})

	Shadow.create(root, 34, 0.36, 0)

	-- Clipped interior shell
	local chrome = Creator.new("Frame", {
		Name = "Chrome",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = root,
	}, {
		Creator.corner(14),
	})

	local overlayLayer = Creator.new("Frame", {
		Name = "OverlayLayer",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 180,
		Parent = root,
	})

	Popover.init(overlayLayer, uiScale)

	local sidebarWidth = opts.SidebarWidth or opts.TabWidth or 178

	local pagesContainer = Creator.new("Frame", {
		Name = "PagesContainer",
		Position = UDim2.fromOffset(sidebarWidth, 44),
		Size = UDim2.new(1, -sidebarWidth, 1, -44),
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		ZIndex = 2,
		ThemeBind = { BackgroundColor3 = "ContentBg" },
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
		Title = opts.WatermarkTitle or opts.Title or "Perfectus UI",
		Icon = opts.Icon,
		Visible = opts.Watermark == true,
	})

	self.TitleBar = TitleBar.create(self, opts)
	self.Sidebar = Sidebar.create(self, { Width = sidebarWidth })
	self.MinimizedPill = MinimizedPill.create(self, opts)
	self.MobileToggle = MobileToggle.create(self, opts)
	self.ConfigManager = ConfigManager.new(self, self.ConfigFolder)

	InputManager.attach(self)

	-- Opening spring animation
	Animator.spring(uiScale, "Scale", autoScale, { frequency = 16, damping = 0.82 })

	if opts.LoadingScreen ~= false then
		LoadingScreen.play(self, opts)
	end

	if opts.KeySystem then
		KeySystem.gate(self, opts.KeySystem, function() end)
	end

	if opts.Transparency == true then
		self:SetTransparency(true)
	end

	-- Auto-append Settings tab when Window:Ready() is called or deferred if SettingsTab = true
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
	if self.Tooltip then
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
			t.Page.Position = UDim2.fromOffset(0, 8)
			Animator.spring(t.Page, "Position", UDim2.fromOffset(0, 0), { frequency = 20, damping = 0.86 })
		end
	end
	self.Sidebar:UpdateActive(target)
end

function Window:ToggleSidebar()
	Popover.close()
	local newW = self.Sidebar:SetCollapsed(not self.Sidebar:IsCollapsed())
	Animator.spring(self.PagesContainer, "Position", UDim2.fromOffset(newW, 44), { frequency = 18, damping = 0.86 })
	Animator.spring(self.PagesContainer, "Size", UDim2.new(1, -newW, 1, -44), { frequency = 18, damping = 0.86 })
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
	local pageTrans = self.Transparent and 0.22 or 0
	Animator.tween(self.Root, { BackgroundTransparency = winTrans }, 0.2)
	Animator.tween(self.Sidebar.Frame, { BackgroundTransparency = sideTrans }, 0.2)
	Animator.tween(self.PagesContainer, { BackgroundTransparency = pageTrans }, 0.2)
end

function Window:SetToggleKey(newKey)
	self.ToggleKey = newKey
	if self.TitleBar then
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
		Content = "Do you want to minimize to the Dynamic Island pill or unload the script completely?",
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
