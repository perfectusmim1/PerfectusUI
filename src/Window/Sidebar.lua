local Creator = require("Core/Creator")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")

local Sidebar = {}

function Sidebar.create(window, opts)
	opts = opts or {}
	local dockWidth = 56
	local collapsed = false

	-- Floating Left Capsule Dock (inset 10px from left & bottom, below the 44px Floating Header)
	local container = Creator.new("Frame", {
		Name = "FloatingDock",
		Position = UDim2.fromOffset(10, 62),
		Size = UDim2.new(0, dockWidth, 1, -72),
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "SidebarBg" },
		Parent = window.Chrome,
	}, {
		Creator.corner(14),
		Creator.stroke("Outline", 1.2, 0),
	})

	-- Sliding Active Pill with Signature Indigo->Cyan Gradient + Left Glow Bar
	local activePill = Creator.new("Frame", {
		Name = "ActiveDockPill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Visible = false,
		ZIndex = 7,
		Parent = container,
	}, {
		Creator.corner(11),
		Creator.new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 189, 248)),
			}),
			Rotation = 45,
		}),
	})

	local tabScroll = Creator.new("ScrollingFrame", {
		Name = "TabScroll",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 8,
		Parent = container,
	}, {
		Creator.padding(8, 0, 8, 0),
		Creator.list(8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top),
	})

	local orderCounter = 0
	local tabButtons = {}

	local sidebarObj = {
		Frame = container,
		TabScroll = tabScroll,
		ExpandedWidth = dockWidth,
		CollapsedWidth = 0,
	}

	function sidebarObj:AddGroupHeader()
		return nil
	end

	function sidebarObj:AddTabButton(tab, icon)
		orderCounter += 1
		local btn = Creator.new("TextButton", {
			Name = "TabBtn_" .. tostring(tab.Title),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = orderCounter,
			ZIndex = 9,
			ThemeBind = { BackgroundColor3 = "RowHover" },
			Parent = tabScroll,
		}, {
			Creator.corner(11),
		})

		local scale = Creator.new("UIScale", { Scale = 1, Parent = btn })

		local iconImg = Creator.new("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			Image = Icons.resolve(icon or "layers") or "",
			ZIndex = 10,
			ThemeBind = { ImageColor3 = "SidebarIconInactive" },
			Parent = btn,
		})

		btn.MouseEnter:Connect(function()
			Animator.spring(scale, "Scale", 1.1, { frequency = 20, damping = 0.78 })
			if window.ActiveTab ~= tab then
				Animator.tween(btn, { BackgroundTransparency = 0.45 }, 0.12)
			end
		end)

		btn.MouseLeave:Connect(function()
			Animator.spring(scale, "Scale", 1, { frequency = 18, damping = 0.82 })
			Animator.tween(btn, { BackgroundTransparency = 1 }, 0.14)
		end)

		btn.Activated:Connect(function()
			Animator.spring(scale, "Scale", 0.9, { frequency = 24, damping = 0.8 })
			task.delay(0.08, function()
				if scale.Parent then
					Animator.spring(scale, "Scale", 1, { frequency = 18, damping = 0.76 })
				end
			end)
			window:SelectTab(tab)
		end)

		local entry = {
			Tab = tab,
			Button = btn,
			Icon = iconImg,
		}
		tabButtons[#tabButtons + 1] = entry
		return entry
	end

	function sidebarObj:UpdateActive(selectedTab)
		for _, entry in ipairs(tabButtons) do
			local isCurrent = (entry.Tab == selectedTab)
			if isCurrent then
				ThemeManager:Unbind(entry.Icon)
				entry.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
				activePill.Visible = true
				task.defer(function()
					if entry.Button.Parent and container.Parent then
						local relY = entry.Button.AbsolutePosition.Y - container.AbsolutePosition.Y
						local scale = (window.UIScale and window.UIScale.Scale > 0) and window.UIScale.Scale or 1
						Animator.spring(
							activePill,
							"Position",
							UDim2.new(0.5, 0, 0, math.floor(relY / scale + 0.5)),
							{ frequency = 20, damping = 0.82 }
						)
					end
				end)
			else
				ThemeManager:Bind(entry.Icon, { ImageColor3 = "SidebarIconInactive" })
			end
		end
	end

	function sidebarObj:SetCollapsed(state)
		collapsed = state == true
		local targetW = collapsed and 0 or dockWidth
		Animator.spring(container, "Size", UDim2.new(0, targetW, 1, -72), { frequency = 18, damping = 0.86 })
		return targetW
	end

	function sidebarObj:IsCollapsed()
		return collapsed
	end

	return sidebarObj
end

return Sidebar
