local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Signal = require("Core/Signal")
local Util = require("Core/Util")
local Animator = require("Motion/Animator")

local Slider = {}

function Slider.create(section, opts)
	opts = opts or {}
	local minVal = tonumber(opts.Min) or 0
	local maxVal = tonumber(opts.Max) or 100
	if minVal > maxVal then
		minVal, maxVal = maxVal, minVal
	end
	local step = tonumber(opts.Step) or 1
	local suffix = opts.Suffix or ""
	local rawDefault = tonumber(opts.Default) or minVal
	local value = Util.round(Util.clamp(rawDefault, minVal, maxVal), step)
	local title = tostring(opts.Title or "Slider")

	-- Sleek Bento 2-Deck Slider Card
	local row = Creator.new("Frame", {
		Name = "Row_" .. title,
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 0,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		ThemeBind = { BackgroundColor3 = "RowBg" },
		Parent = section.Container,
	}, {
		Creator.corner(10),
		Creator.stroke("Outline", 1, 0),
		Creator.padding(8, 12, 10, 12),
	})

	local topRow = Creator.new("Frame", {
		Name = "TopHeader",
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = row,
	})

	local titleLabel = Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -84, 1, 0),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 14,
		Text = title,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		ThemeBind = { TextColor3 = "Text" },
		Parent = topRow,
	})

	local valueBox = Creator.new("TextBox", {
		Name = "ValueBox",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(78, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		ClearTextOnFocus = false,
		ZIndex = 5,
		ThemeBind = { TextColor3 = "ValueText" },
		Parent = topRow,
	})

	-- Full-width sleek pill track with Indigo->Cyan gradient fill
	local track = Creator.new("TextButton", {
		Name = "SliderTrack",
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, 0, 0, 8),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = row,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local fill = Creator.new("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 7,
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 189, 248)),
			}),
		}),
	})

	local knob = Creator.new("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		ZIndex = 8,
		ThemeBind = { BackgroundColor3 = "Knob" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke(Color3.fromRGB(99, 102, 241), 2, 0),
	})

	local locked = false
	local control = {
		Kind = "Slider",
		Row = row,
		TitleLabel = titleLabel,
		Section = section,
		Window = section.Window,
		Flag = opts.Flag or opts.Id,
		Title = title,
		Default = value,
		Changed = Signal.new(),
		IsLocked = function()
			return locked
		end,
		Lock = function()
			locked = true
		end,
		Unlock = function()
			locked = false
		end,
		Highlight = function()
			Animator.pulseHighlight(row)
		end,
		SetTitle = function(self, t)
			self.Title = tostring(t or "")
			titleLabel.Text = self.Title
		end,
		SetVisible = function(_, v)
			row.Visible = v == true
		end,
		OnChanged = function(self, fn)
			return self.Changed:Connect(fn)
		end,
		Destroy = function(self)
			self.Changed:Destroy()
			if row and row.Parent then
				row:Destroy()
			end
		end,
	}

	local function getRatio(val)
		if maxVal == minVal then
			return 0
		end
		return math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
	end

	local function syncVisuals(animate)
		local ratio = getRatio(value)
		if animate ~= false then
			Animator.spring(fill, "Size", UDim2.new(ratio, 0, 1, 0), { frequency = 24, damping = 0.85 })
			Animator.spring(knob, "Position", UDim2.new(ratio, 0, 0.5, 0), { frequency = 24, damping = 0.85 })
		else
			fill.Size = UDim2.new(ratio, 0, 1, 0)
			knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		end
		if not valueBox:IsFocused() then
			valueBox.Text = tostring(value) .. suffix
		end
	end

	local function setValue(newVal, silent)
		newVal = tonumber(newVal) or minVal
		newVal = Util.round(Util.clamp(newVal, minVal, maxVal), step)
		local changed = (value ~= newVal)
		value = newVal
		syncVisuals(true)

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, value, silent)
		end
		if not silent then
			control.Changed:Fire(value)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					value
				)
			end
		end
		return changed
	end

	local dragging = false
	local moveConn = nil
	local releaseConn = nil

	local function updateFromInput(input)
		local absX = track.AbsolutePosition.X
		local absW = track.AbsoluteSize.X
		if absW <= 0 then
			return
		end
		local rel = math.clamp((input.Position.X - absX) / absW, 0, 1)
		local raw = minVal + (maxVal - minVal) * rel
		setValue(raw, false)
	end

	local function startDragging(input)
		if locked then
			return
		end
		dragging = true
		Animator.spring(knob, "Size", UDim2.fromOffset(19, 19), { frequency = 22, damping = 0.82 })
		updateFromInput(input)

		if moveConn then
			moveConn:Disconnect()
		end
		if releaseConn then
			releaseConn:Disconnect()
		end

		moveConn = Services.UserInputService.InputChanged:Connect(function(moveInput)
			if
				dragging
				and (
					moveInput.UserInputType == Enum.UserInputType.MouseMovement
					or moveInput.UserInputType == Enum.UserInputType.Touch
				)
			then
				updateFromInput(moveInput)
			end
		end)

		releaseConn = Services.UserInputService.InputEnded:Connect(function(endInput)
			if
				endInput.UserInputType == Enum.UserInputType.MouseButton1
				or endInput.UserInputType == Enum.UserInputType.Touch
			then
				dragging = false
				Animator.spring(knob, "Size", UDim2.fromOffset(16, 16), { frequency = 20, damping = 0.85 })
				if moveConn then
					moveConn:Disconnect()
					moveConn = nil
				end
				if releaseConn then
					releaseConn:Disconnect()
					releaseConn = nil
				end
			end
		end)
	end

	track.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			startDragging(input)
		end
	end)

	valueBox.FocusLost:Connect(function()
		local rawText = valueBox.Text:gsub("[^%d.-]", "")
		local parsed = tonumber(rawText)
		if parsed then
			setValue(parsed, false)
		else
			syncVisuals(false)
		end
	end)

	function control:Get()
		return value
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	function control:SetMin(newMin)
		minVal = tonumber(newMin) or minVal
		setValue(value, true)
	end

	function control:SetMax(newMax)
		maxVal = tonumber(newMax) or maxVal
		setValue(value, true)
	end

	if section.Window then
		if section.Window._registerContextMenu then
			section.Window:_registerContextMenu(row, control)
		end
		if section.Window._registerSearchable then
			section.Window:_registerSearchable(control, section)
		end
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncVisuals(false)
	return control
end

return Slider
