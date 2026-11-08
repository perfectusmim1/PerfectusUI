local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local KeybindList = {}
KeybindList.__index = KeybindList

function KeybindList.new(window, visibleByDefault)
	local card = Creator.new("Frame", {
		Name = "KeybindListHUD",
		Position = UDim2.fromOffset(18, 94),
		Size = UDim2.fromOffset(192, 40),
		BackgroundTransparency = 0.06,
		Visible = visibleByDefault == true,
		ZIndex = 160,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = window.ScreenGui,
	}, {
		Creator.corner(10),
		Creator.stroke("InnerStroke", 1, 0.25),
	})

	Shadow.create(card, 16, 0.45, 159)

	local inner = Creator.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 161,
		Parent = card,
	}, {
		Creator.padding(8, 10, 8, 10),
		Creator.list(4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local header = Creator.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		ZIndex = 161,
		Parent = inner,
	})

	Creator.new("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(13, 13),
		Image = Icons.resolve("keyboard") or "",
		ZIndex = 162,
		ThemeBind = { ImageColor3 = "Accent" },
		Parent = header,
	})

	Creator.new("TextLabel", {
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -18, 1, 0),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 12,
		Text = "Active Keybinds",
		ZIndex = 162,
		ThemeBind = { TextColor3 = "Text" },
		Parent = header,
	})

	Creator.new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		LayoutOrder = 2,
		ZIndex = 161,
		ThemeBind = { BackgroundColor3 = "Border" },
		Parent = inner,
	})

	local listHolder = Creator.new("Frame", {
		Name = "Rows",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		ZIndex = 161,
		Parent = inner,
	}, {
		Creator.list(3, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	-- Draggable HUD
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = card.Position
	header.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(inp.Position.X, inp.Position.Y)
			startPos = card.Position
		end
	end)
	window.Maid:Add(Services.UserInputService.InputChanged:Connect(function(inp)
		if
			dragging
			and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch)
		then
			local d = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
			card.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
	window.Maid:Add(Services.UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	return setmetatable({
		Frame = card,
		ListHolder = listHolder,
		Controls = {},
		RowViews = {},
	}, KeybindList)
end

function KeybindList:Register(control)
	if not table.find(self.Controls, control) then
		self.Controls[#self.Controls + 1] = control
	end
	self:Refresh()
end

function KeybindList:Refresh()
	for _, v in ipairs(self.RowViews) do
		v:Destroy()
	end
	table.clear(self.RowViews)

	for idx, ctrl in ipairs(self.Controls) do
		local key = ctrl.GetKey and ctrl:GetKey() or nil
		if key ~= nil and ctrl.Row and ctrl.Row.Parent then
			local isActive = false
			if ctrl.Kind == "Toggle" and ctrl.Get then
				isActive = ctrl:Get() == true
			elseif ctrl.IsActive then
				isActive = ctrl:IsActive() == true
			end

			local row = Creator.new("Frame", {
				Name = "Bind_" .. idx,
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				LayoutOrder = idx,
				ZIndex = 162,
				Parent = self.ListHolder,
			})

			Creator.new("TextLabel", {
				Size = UDim2.new(1, -56, 1, 0),
				Font = Enum.Font.BuilderSans,
				TextSize = 11,
				Text = tostring(ctrl.Title),
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 163,
				TextColor3 = ThemeManager:Get(isActive and "Accent" or "TextSecondary"),
				Parent = row,
			})

			Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(52, 16),
				Font = Enum.Font.RobotoMono,
				TextSize = 10,
				Text = "[" .. Util.formatKeyName(key) .. "]",
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 163,
				TextColor3 = ThemeManager:Get(isActive and "Accent" or "TextMuted"),
				Parent = row,
			})

			self.RowViews[#self.RowViews + 1] = row
		end
	end

	local targetH = 38 + (#self.RowViews * 21)
	Animator.spring(self.Frame, "Size", UDim2.fromOffset(192, targetH), { frequency = 18, damping = 0.86 })
end

function KeybindList:SetVisible(vis)
	self.Frame.Visible = vis == true
	if vis then
		self:Refresh()
	end
end

function KeybindList:IsVisible()
	return self.Frame.Visible
end

return KeybindList
