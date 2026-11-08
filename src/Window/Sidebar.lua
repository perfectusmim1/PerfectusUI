local Services = require("Core/Services")
local Creator = require("Core/Creator")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")

local Sidebar = {}

function Sidebar.create(window, opts)
	opts = opts or {}
	local expandedWidth = opts.Width or 178
	local collapsedWidth = 54
	local collapsed = false

	local container = Creator.new("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(0, expandedWidth, 1, -44),
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "SidebarBg" },
		Parent = window.Chrome,
	}, {
		Creator.new("Frame", {
			Name = "RightBorder",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 1, 1, 0),
			ZIndex = 8,
			ThemeBind = { BackgroundColor3 = "Border" },
		}),
	})

	-- Tab list container with floating active pill indicator
	local listWrapper = Creator.new("Frame", {
		Name = "TabListWrapper",
		Position = UDim2.fromOffset(0, 10),
		Size = UDim2.new(1, 0, 1, -64),
		BackgroundTransparency = 1,
		ZIndex = 6,
		Parent = container,
	})

	local activeIndicator = Creator.new("Frame", {
		Name = "ActivePill",
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -16, 0, 32),
		BackgroundTransparency = 0.86,
		Visible = false,
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "Accent" },
		Parent = listWrapper,
	}, {
		Creator.corner(8),
		Creator.new("Frame", {
			Name = "AccentBar",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(3, 16),
			ZIndex = 7,
			ThemeBind = { BackgroundColor3 = "Accent" },
		}, {
			Creator.corner(2),
		}),
	})

	local tabScroll = Creator.new("ScrollingFrame", {
		Name = "TabScroll",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 2,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 7,
		Parent = listWrapper,
	}, {
		Creator.padding(0, 8, 8, 8),
		Creator.list(4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	-- User Footer Profile Card (macOS System Settings style)
	local lp = Services.Players and Services.Players.LocalPlayer
	local displayName = (lp and lp.DisplayName) or "Perfectus"
	local username = (lp and ("@" .. lp.Name)) or "@user"
	local avatarImg = ""
	if lp and lp.UserId and lp.UserId > 0 then
		avatarImg = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", lp.UserId)
	end

	local footer = Creator.new("Frame", {
		Name = "UserFooter",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		ZIndex = 7,
		Parent = container,
	}, {
		Creator.new("Frame", {
			Name = "TopDivider",
			Size = UDim2.new(1, -16, 0, 1),
			Position = UDim2.fromOffset(8, 0),
			ZIndex = 7,
			ThemeBind = { BackgroundColor3 = "Border" },
		}),
	})

	Creator.new("ImageLabel", {
		Name = "Avatar",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 1),
		Size = UDim2.fromOffset(28, 28),
		Image = avatarImg,
		ZIndex = 8,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = footer,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Border", 1, 0.25),
	})

	local userTextCol = Creator.new("Frame", {
		Name = "UserText",
		Position = UDim2.fromOffset(48, 10),
		Size = UDim2.new(1, -56, 0, 32),
		BackgroundTransparency = 1,
		ZIndex = 8,
		Parent = footer,
	})

	Creator.new("TextLabel", {
		Name = "DisplayName",
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 13,
		Text = displayName,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 8,
		ThemeBind = { TextColor3 = "Text" },
		Parent = userTextCol,
	})

	Creator.new("TextLabel", {
		Name = "Username",
		Position = UDim2.fromOffset(0, 15),
		Size = UDim2.new(1, 0, 0, 14),
		Font = Enum.Font.BuilderSans,
		TextSize = 11,
		Text = username,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 8,
		ThemeBind = { TextColor3 = "TextMuted" },
		Parent = userTextCol,
	})

	local orderCounter = 0
	local tabButtons = {}
	local groupLabels = {}

	local sidebarObj = {
		Frame = container,
		TabScroll = tabScroll,
		ExpandedWidth = expandedWidth,
		CollapsedWidth = collapsedWidth,
	}

	function sidebarObj:AddGroupHeader(title)
		orderCounter += 1
		local lbl = Creator.new("TextLabel", {
			Name = "Group_" .. tostring(title),
			Size = UDim2.new(1, 0, 0, 20),
			Font = Enum.Font.BuilderSansBold,
			TextSize = 10,
			Text = string.upper(tostring(title or "")),
			LayoutOrder = orderCounter,
			Visible = not collapsed,
			ZIndex = 7,
			ThemeBind = { TextColor3 = "SectionHeader" },
			Parent = tabScroll,
		}, {
			Creator.padding(4, 8, 0, 8),
		})
		groupLabels[#groupLabels + 1] = lbl
		return lbl
	end

	function sidebarObj:AddTabButton(tab, icon, badgeText)
		orderCounter += 1
		local btn = Creator.new("TextButton", {
			Name = "TabBtn_" .. tostring(tab.Title),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			Text = "",
			LayoutOrder = orderCounter,
			ZIndex = 8,
			Parent = tabScroll,
		}, {
			Creator.corner(8),
		})

		local iconImg = Creator.new("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			Image = Icons.resolve(icon or "circle") or "",
			ZIndex = 9,
			ThemeBind = { ImageColor3 = "TextSecondary" },
			Parent = btn,
		})

		local titleLbl = Creator.new("TextLabel", {
			Name = "Title",
			Position = UDim2.fromOffset(34, 0),
			Size = UDim2.new(1, -42, 1, 0),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 13,
			Text = tostring(tab.Title),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Visible = not collapsed,
			ZIndex = 9,
			ThemeBind = { TextColor3 = "TextSecondary" },
			Parent = btn,
		})

		local badge = nil
		if badgeText and badgeText ~= "" then
			badge = Creator.new("TextLabel", {
				Name = "Badge",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.fromOffset(22, 16),
				Font = Enum.Font.BuilderSansBold,
				TextSize = 10,
				Text = tostring(badgeText),
				TextXAlignment = Enum.TextXAlignment.Center,
				Visible = not collapsed,
				ZIndex = 9,
				ThemeBind = {
					BackgroundColor3 = "ControlBg",
					TextColor3 = "TextSecondary",
				},
				Parent = btn,
			}, {
				Creator.corner(UDim.new(1, 0)),
			})
		end

		btn.MouseEnter:Connect(function()
			if window.ActiveTab ~= tab then
				Animator.tween(btn, { BackgroundTransparency = 0.92 }, 0.12)
			end
		end)

		btn.MouseLeave:Connect(function()
			Animator.tween(btn, { BackgroundTransparency = 1 }, 0.14)
		end)

		btn.Activated:Connect(function()
			window:SelectTab(tab)
		end)

		local entry = {
			Tab = tab,
			Button = btn,
			Icon = iconImg,
			Title = titleLbl,
			Badge = badge,
		}
		tabButtons[#tabButtons + 1] = entry
		return entry
	end

	function sidebarObj:UpdateActive(selectedTab)
		for _, entry in ipairs(tabButtons) do
			local isCurrent = (entry.Tab == selectedTab)
			ThemeManager:Bind(entry.Icon, { ImageColor3 = isCurrent and "Accent" or "TextSecondary" })
			ThemeManager:Bind(entry.Title, { TextColor3 = isCurrent and "Text" or "TextSecondary" })
			entry.Title.Font = isCurrent and Enum.Font.BuilderSansBold or Enum.Font.BuilderSansMedium

			if isCurrent then
				activeIndicator.Visible = true
				task.defer(function()
					if entry.Button.Parent and listWrapper.Parent then
						local relY = entry.Button.AbsolutePosition.Y - listWrapper.AbsolutePosition.Y
						local scale = (window.UIScale and window.UIScale.Scale > 0) and window.UIScale.Scale or 1
						Animator.spring(
							activeIndicator,
							"Position",
							UDim2.fromOffset(8, math.floor(relY / scale + 0.5)),
							{ frequency = 18, damping = 0.84 }
						)
					end
				end)
			end
		end
	end

	function sidebarObj:SetCollapsed(state)
		collapsed = state == true
		local targetW = collapsed and collapsedWidth or expandedWidth
		userTextCol.Visible = not collapsed
		for _, g in ipairs(groupLabels) do
			g.Visible = not collapsed
		end
		for _, entry in ipairs(tabButtons) do
			entry.Title.Visible = not collapsed
			if entry.Badge then
				entry.Badge.Visible = not collapsed
			end
		end
		Animator.spring(container, "Size", UDim2.new(0, targetW, 1, -44), { frequency = 18, damping = 0.86 })
		return targetW
	end

	function sidebarObj:IsCollapsed()
		return collapsed
	end

	return sidebarObj
end

return Sidebar
