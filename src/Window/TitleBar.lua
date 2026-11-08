local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Popover = require("Components/Popover")

local TitleBar = {}

function TitleBar.create(window, opts)
	opts = opts or {}

	local bar = Creator.new("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 0,
		ZIndex = 10,
		ThemeBind = { BackgroundColor3 = "TitleBarBg" },
		Parent = window.Chrome,
	}, {
		Creator.new("Frame", {
			Name = "BottomBorder",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 11,
			ThemeBind = { BackgroundColor3 = "Border" },
		}),
	})

	-- macOS Traffic Lights container (Red = Close, Yellow = Minimize to Dynamic Island pill, Green = Collapse Sidebar)
	local trafficHolder = Creator.new("Frame", {
		Name = "TrafficLights",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(56, 16),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = bar,
	})

	local glyphs = {}

	local function makeTrafficDot(name, xOffset, colorToken, glyphText, onClick)
		local btn = Creator.new("TextButton", {
			Name = name,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, xOffset, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
			Text = "",
			ZIndex = 13,
			ThemeBind = { BackgroundColor3 = colorToken },
			Parent = trafficHolder,
		}, {
			Creator.corner(UDim.new(1, 0)),
			Creator.stroke("Border", 1, 0.65),
		})

		local glyph = Creator.new("TextLabel", {
			Name = "Glyph",
			Size = UDim2.new(1, 0, 1, -1),
			Font = Enum.Font.BuilderSansBold,
			TextSize = 10,
			Text = glyphText,
			TextColor3 = Color3.fromRGB(30, 30, 34),
			TextTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 14,
			Parent = btn,
		})
		glyphs[#glyphs + 1] = glyph

		btn.Activated:Connect(onClick)
		return btn
	end

	makeTrafficDot("Close", 0, "TrafficClose", "×", function()
		window:PromptClose()
	end)

	makeTrafficDot("Minimize", 20, "TrafficMin", "−", function()
		window:MinimizeToPill(true)
	end)

	makeTrafficDot("SidebarToggle", 40, "TrafficMax", "⇄", function()
		window:ToggleSidebar()
	end)

	trafficHolder.MouseEnter:Connect(function()
		for _, g in ipairs(glyphs) do
			Animator.tween(g, { TextTransparency = 0.15 }, 0.12)
		end
	end)

	trafficHolder.MouseLeave:Connect(function()
		for _, g in ipairs(glyphs) do
			Animator.tween(g, { TextTransparency = 1 }, 0.14)
		end
	end)

	-- Brand Icon + Title + Subtitle
	local titleCluster = Creator.new("Frame", {
		Name = "TitleCluster",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 84, 0.5, 0),
		Size = UDim2.new(1, -240, 0, 26),
		BackgroundTransparency = 1,
		ZIndex = 11,
		Parent = bar,
	}, {
		Creator.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
	})

	if opts.Icon then
		Creator.new("ImageLabel", {
			Name = "BrandIcon",
			Size = UDim2.fromOffset(16, 16),
			Image = Icons.resolve(opts.Icon) or "",
			LayoutOrder = 1,
			ZIndex = 12,
			ThemeBind = { ImageColor3 = "Accent" },
			Parent = titleCluster,
		})
	end

	local titleLabel = Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		Font = Enum.Font.BuilderSansBold,
		TextSize = 14,
		Text = tostring(opts.Title or "Perfectus"),
		LayoutOrder = 2,
		ZIndex = 12,
		ThemeBind = { TextColor3 = "Text" },
		Parent = titleCluster,
	})

	local subtitleLabel = Creator.new("TextLabel", {
		Name = "Subtitle",
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Font = Enum.Font.BuilderSans,
		TextSize = 12,
		Text = tostring(opts.Subtitle or opts.SubTitle or "by Perfectus"),
		LayoutOrder = 3,
		ZIndex = 12,
		ThemeBind = { TextColor3 = "TextMuted" },
		Parent = titleCluster,
	})

	-- Right-side Spotlight Command Palette pill + Menu Key indicator
	local rightActions = Creator.new("Frame", {
		Name = "RightActions",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(150, 26),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = bar,
	}, {
		Creator.list(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center),
	})

	local searchBtn = Creator.new("TextButton", {
		Name = "SpotlightBtn",
		Size = UDim2.fromOffset(92, 24),
		LayoutOrder = 1,
		ZIndex = 13,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = rightActions,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.35),
		Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 7, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
			Image = Icons.resolve("search") or "",
			ZIndex = 14,
			ThemeBind = { ImageColor3 = "TextMuted" },
		}),
		Creator.new("TextLabel", {
			Position = UDim2.fromOffset(23, 0),
			Size = UDim2.new(1, -26, 1, 0),
			Font = Enum.Font.BuilderSans,
			TextSize = 11,
			Text = "Search  ⌘K",
			ZIndex = 14,
			ThemeBind = { TextColor3 = "TextSecondary" },
		}),
	})

	Creator.bindInteractive(searchBtn, {
		NormalToken = "ControlBg",
		HoverToken = "ControlHover",
		PressScale = 0.96,
	})

	searchBtn.Activated:Connect(function()
		if window.CommandPalette then
			window.CommandPalette:Toggle()
		end
	end)

	local keyPill = Creator.new("TextButton", {
		Name = "HidePill",
		Size = UDim2.fromOffset(48, 24),
		Font = Enum.Font.RobotoMono,
		TextSize = 11,
		Text = Util.formatKeyName(window.ToggleKey),
		LayoutOrder = 2,
		ZIndex = 13,
		ThemeBind = {
			BackgroundColor3 = "ControlBg",
			TextColor3 = "TextMuted",
		},
		Parent = rightActions,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.35),
	})

	keyPill.Activated:Connect(function()
		window:ToggleVisibility()
	end)

	-- Smooth Window Dragging (clamped to screen bounds)
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.new()

	bar.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			Popover.close()
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPos = window.Root.Position
		end
	end)

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
			local w = window.Root.AbsoluteSize.X
			local h = window.Root.AbsoluteSize.Y
			local newX = math.clamp(startPos.X.Offset + delta.X, math.floor(w * 0.5) - w + 60, vp.X - 60)
			local newY = math.clamp(startPos.Y.Offset + delta.Y, math.floor(h * 0.5) + 4, vp.Y - 40)
			window.Root.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
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
		SubtitleLabel = subtitleLabel,
		KeyPill = keyPill,
		SetTitle = function(_, t)
			titleLabel.Text = tostring(t or "")
		end,
		SetSubtitle = function(_, s)
			subtitleLabel.Text = tostring(s or "")
		end,
		UpdateKeyText = function(_, k)
			keyPill.Text = Util.formatKeyName(k)
		end,
	}
end

return TitleBar
