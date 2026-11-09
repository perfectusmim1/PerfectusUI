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
