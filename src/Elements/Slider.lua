local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local RowBase = require("Components/RowBase")

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

	local control = RowBase.create(section, {
		Title = opts.Title or "Slider",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = value,
		RightWidth = 190,
		Clickable = false,
	})
	control.Kind = "Slider"

	local trackWidth = 122

	local track = Creator.new("TextButton", {
		Name = "SliderTrack",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(trackWidth, 6),
		BackgroundColor3 = ThemeManager:Get("ControlBg"),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		Parent = control.RightSlot,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Border", 1, 0.4),
	})

	local fill = Creator.new("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = ThemeManager:Get("Accent"),
		ZIndex = 7,
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local knob = Creator.new("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 8,
		ThemeBind = { BackgroundColor3 = "Knob" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Border", 1, 0.3),
	})

	local valueBox = Creator.new("TextBox", {
		Name = "ValueBox",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(60, 22),
		Font = Enum.Font.RobotoMono,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		ClearTextOnFocus = false,
		ZIndex = 6,
		ThemeBind = {
			BackgroundColor3 = "InputBg",
			TextColor3 = "Text",
		},
		Parent = control.RightSlot,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.35),
	})

	local function getRatio(val)
		if maxVal == minVal then
			return 0
		end
		return math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
	end

	local function syncVisuals(animate)
		local ratio = getRatio(value)
		fill.BackgroundColor3 = ThemeManager:Get("Accent")

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

	ThemeManager.Changed:Connect(function()
		syncVisuals(true)
	end)

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
		if control:IsLocked() then
			return
		end
		dragging = true
		Animator.spring(knob, "Size", UDim2.fromOffset(17, 17), { frequency = 22, damping = 0.82 })
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
				Animator.spring(knob, "Size", UDim2.fromOffset(14, 14), { frequency = 20, damping = 0.85 })
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

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncVisuals(false)
	return control
end

return Slider
