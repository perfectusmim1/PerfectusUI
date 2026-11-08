local Creator = require("Core/Creator")
local Signal = require("Core/Signal")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")

local RadioGroup = {}

function RadioGroup.create(section, opts)
	opts = opts or {}
	local options = type(opts.Options) == "table" and #opts.Options > 0 and opts.Options or { "Option 1", "Option 2" }
	local selected = tostring(opts.Default or options[1])

	local card = Creator.new("Frame", {
		Name = "RadioGroup_" .. tostring(opts.Title or "Radio"),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		ThemeBind = { BackgroundColor3 = "RowBg" },
		Parent = section.Container,
	}, {
		Creator.corner(8),
		Creator.padding(10, 12, 10, 12),
		Creator.list(6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local titleLabel = Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 14,
		Text = tostring(opts.Title or "Select Option"),
		LayoutOrder = 1,
		ZIndex = 4,
		ThemeBind = { TextColor3 = "Text" },
		Parent = card,
	})

	local itemsContainer = Creator.new("Frame", {
		Name = "Items",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 4,
		Parent = card,
	}, {
		Creator.list(4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local locked = false
	local itemNodes = {}

	local control = {
		Kind = "RadioGroup",
		Row = card,
		TitleLabel = titleLabel,
		Section = section,
		Window = section.Window,
		Flag = opts.Flag or opts.Id,
		Title = tostring(opts.Title or "RadioGroup"),
		Default = selected,
		Changed = Signal.new(),
		IsLocked = function()
			return locked
		end,
	}

	local function syncVisuals(animate)
		for _, node in ipairs(itemNodes) do
			local isCurrent = (node.value == selected)
			local ringColor = ThemeManager:Get(isCurrent and "Accent" or "ControlBg")
			local dotSize = isCurrent and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0)
			node.label.TextColor3 = ThemeManager:Get(isCurrent and "Text" or "TextSecondary")
			if animate ~= false then
				Animator.tween(node.ring, { BackgroundColor3 = ringColor }, 0.15)
				Animator.spring(node.dot, "Size", dotSize, { frequency = 20, damping = 0.8 })
			else
				node.ring.BackgroundColor3 = ringColor
				node.dot.Size = dotSize
			end
		end
	end

	local function setValue(val, silent)
		selected = tostring(val or options[1])
		syncVisuals(true)

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, selected, silent)
		end
		if not silent then
			control.Changed:Fire(selected)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					selected
				)
			end
		end
	end

	local function rebuildItems()
		for _, node in ipairs(itemNodes) do
			node.btn:Destroy()
		end
		table.clear(itemNodes)

		for idx, opt in ipairs(options) do
			local valStr = tostring(opt)
			local btn = Creator.new("TextButton", {
				Name = "Radio_" .. valStr,
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				Text = "",
				LayoutOrder = idx,
				ZIndex = 5,
				Parent = itemsContainer,
			})

			local ring = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 2, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				ZIndex = 6,
				Parent = btn,
			}, {
				Creator.corner(UDim.new(1, 0)),
				Creator.stroke("Border", 1, 0.3),
			})

			local dot = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(0, 0),
				ZIndex = 7,
				ThemeBind = { BackgroundColor3 = "OnAccent" },
				Parent = ring,
			}, {
				Creator.corner(UDim.new(1, 0)),
			})

			local lbl = Creator.new("TextLabel", {
				Position = UDim2.fromOffset(26, 0),
				Size = UDim2.new(1, -28, 1, 0),
				Font = Enum.Font.BuilderSans,
				TextSize = 13,
				Text = valStr,
				ZIndex = 6,
				Parent = btn,
			})

			btn.Activated:Connect(function()
				if not locked then
					setValue(valStr, false)
				end
			end)

			itemNodes[#itemNodes + 1] = {
				value = valStr,
				btn = btn,
				ring = ring,
				dot = dot,
				label = lbl,
			}
		end
		syncVisuals(false)
	end

	ThemeManager.Changed:Connect(function()
		syncVisuals(false)
	end)

	function control:Get()
		return selected
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	function control:Refresh(newOpts)
		if type(newOpts) == "table" and #newOpts > 0 then
			options = newOpts
			selected = tostring(options[1])
			rebuildItems()
		end
	end

	function control:OnChanged(fn)
		return self.Changed:Connect(fn)
	end

	function control:SetTitle(t)
		self.Title = tostring(t or "")
		titleLabel.Text = self.Title
	end

	function control:SetVisible(v)
		card.Visible = v == true
	end

	function control:Lock()
		locked = true
	end

	function control:Unlock()
		locked = false
	end

	function control:Highlight()
		Animator.pulseHighlight(card)
	end

	function control:Destroy()
		self.Changed:Destroy()
		card:Destroy()
	end

	rebuildItems()

	if section.Window and section.Window._registerSearchable then
		section.Window:_registerSearchable(control, section)
	end
	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	return control
end

return RadioGroup
