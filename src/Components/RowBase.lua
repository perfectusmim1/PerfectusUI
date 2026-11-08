local Creator = require("Core/Creator")
local Signal = require("Core/Signal")
local Icons = require("Assets/Icons")
local Animator = require("Motion/Animator")

local RowBase = {}

function RowBase.create(section, opts)
	opts = opts or {}
	local rightWidth = opts.RightWidth or 120
	local minHeight = opts.MinHeight or 42
	local clickable = opts.Clickable == true

	local rowClass = clickable and "TextButton" or "Frame"
	local rowProps = {
		Name = opts.Name or ("Row_" .. tostring(opts.Title or "Item")),
		Size = UDim2.new(1, 0, 0, minHeight),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		ThemeBind = { BackgroundColor3 = "RowBg" },
		Parent = section.Container,
	}
	if clickable then
		rowProps.Text = ""
		rowProps.AutoButtonColor = false
	end

	local row = Creator.new(rowClass, rowProps, {
		Creator.corner(8),
		Creator.padding(8, 12, 8, 12),
		Creator.new("UISizeConstraint", {
			MinSize = Vector2.new(0, minHeight),
		}),
	})

	Creator.bindInteractive(row, {
		NormalToken = "RowBg",
		HoverToken = "RowHover",
	})

	local hasIcon = opts.Icon ~= nil and opts.Icon ~= ""
	local iconOffset = hasIcon and 26 or 0

	local iconImage = nil
	if hasIcon then
		iconImage = Creator.new("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			Image = Icons.resolve(opts.Icon) or "",
			ZIndex = 4,
			ThemeBind = { ImageColor3 = opts.IconColorToken or "TextSecondary" },
			Parent = row,
		})
	end

	local textReserve = rightWidth > 0 and (rightWidth + 14 + iconOffset) or iconOffset
	local leftCol = Creator.new("Frame", {
		Name = "LeftColumn",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, iconOffset, 0.5, 0),
		Size = UDim2.new(1, -textReserve, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = row,
	}, {
		Creator.list(2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
	})

	local titleLabel = Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 14,
		Text = tostring(opts.Title or ""),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		ZIndex = 4,
		ThemeBind = { TextColor3 = opts.TitleColorToken or "Text" },
		Parent = leftCol,
	})

	local descLabel = nil
	local function ensureDescLabel()
		if not descLabel then
			descLabel = Creator.new("TextLabel", {
				Name = "Description",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Font = Enum.Font.BuilderSans,
				TextSize = 12,
				TextWrapped = true,
				Text = "",
				LayoutOrder = 2,
				ZIndex = 4,
				ThemeBind = { TextColor3 = "TextSecondary" },
				Parent = leftCol,
			})
		end
		return descLabel
	end

	if opts.Description and opts.Description ~= "" then
		local d = ensureDescLabel()
		d.Text = tostring(opts.Description)
	end

	local rightSlot = nil
	if rightWidth > 0 then
		rightSlot = Creator.new("Frame", {
			Name = "RightSlot",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(rightWidth, minHeight - 12),
			BackgroundTransparency = 1,
			ZIndex = 5,
			Parent = row,
		})
	end

	-- Lock overlay
	local locked = false
	local lockReason = nil
	local lockOverlay = nil

	local control = {
		Row = row,
		LeftColumn = leftCol,
		TitleLabel = titleLabel,
		RightSlot = rightSlot,
		IconImage = iconImage,
		Section = section,
		Window = section.Window,
		Flag = opts.Flag or opts.Id,
		Title = tostring(opts.Title or ""),
		Default = opts.Default,
		Changed = Signal.new(),
		IsLocked = function()
			return locked
		end,
	}

	function control:OnChanged(fn)
		return self.Changed:Connect(fn)
	end

	function control:SetTitle(newTitle)
		self.Title = tostring(newTitle or "")
		titleLabel.Text = self.Title
	end

	function control:SetDescription(newDesc)
		if newDesc == nil or newDesc == "" then
			if descLabel then
				descLabel.Visible = false
				descLabel.Text = ""
			end
		else
			local d = ensureDescLabel()
			d.Visible = true
			d.Text = tostring(newDesc)
		end
	end

	function control:SetVisible(vis)
		row.Visible = vis == true
	end

	function control:Lock(reason)
		locked = true
		lockReason = reason and tostring(reason) or "Locked"
		if not lockOverlay then
			lockOverlay = Creator.new("TextButton", {
				Name = "LockOverlay",
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 0.32,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 12,
				ThemeBind = { BackgroundColor3 = "SectionBg" },
				Parent = row,
			}, {
				Creator.corner(8),
				Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -6, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					Image = Icons.resolve("lock") or "",
					ZIndex = 13,
					ThemeBind = { ImageColor3 = "TextMuted" },
				}),
			})
		end
		lockOverlay.Visible = true
	end

	function control:Unlock()
		locked = false
		lockReason = nil
		if lockOverlay then
			lockOverlay.Visible = false
		end
	end

	function control:Highlight()
		Animator.pulseHighlight(row)
	end

	function control:Destroy()
		self.Changed:Destroy()
		if row and row.Parent then
			row:Destroy()
		end
	end

	-- Register Tooltip & ContextMenu & CommandPalette entry if Window provides hooks
	if section.Window then
		if opts.Tooltip and section.Window._registerTooltip then
			section.Window:_registerTooltip(row, function()
				if locked and lockReason then
					return tostring(opts.Tooltip) .. " (" .. lockReason .. ")"
				end
				return tostring(opts.Tooltip)
			end)
		else
			if section.Window._registerTooltip then
				section.Window:_registerTooltip(row, function()
					if locked and lockReason then
						return lockReason
					end
					return nil
				end)
			end
		end
		if section.Window._registerContextMenu then
			section.Window:_registerContextMenu(row, control)
		end
		if section.Window._registerSearchable then
			section.Window:_registerSearchable(control, section)
		end
	end

	return control
end

return RowBase
