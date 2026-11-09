local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local RowBase = require("Components/RowBase")

local RangeSlider = {}

function RangeSlider.create(section, opts)
	opts = opts or {}
	local minVal = tonumber(opts.Min) or 0
	local maxVal = tonumber(opts.Max) or 100
	if minVal > maxVal then
		minVal, maxVal = maxVal, minVal
	end
	local step = tonumber(opts.Step) or 1
	local suffix = opts.Suffix or ""

	local def = type(opts.Default) == "table" and opts.Default
		or { minVal + (maxVal - minVal) * 0.2, minVal + (maxVal - minVal) * 0.8 }
	local lowVal = Util.round(Util.clamp(tonumber(def[1]) or minVal, minVal, maxVal), step)
	local highVal = Util.round(Util.clamp(tonumber(def[2]) or maxVal, minVal, maxVal), step)
	if lowVal > highVal then
		lowVal, highVal = highVal, lowVal
	end

	local control = RowBase.create(section, {
		Title = opts.Title or "Range Slider",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = { lowVal, highVal },
		RightWidth = 195,
		Clickable = false,
	})
	control.Kind = "RangeSlider"

	local trackWidth = 120

	local track = Creator.new("TextButton", {
		Name = "RangeTrack",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(trackWidth, 12),
		BackgroundColor3 = ThemeManager:Get("ControlBg"),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		Parent = control.RightSlot,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Outline", 2, 0),
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

	local knobLow = Creator.new("Frame", {
		Name = "KnobLow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 8,
		ThemeBind = { BackgroundColor3 = "Knob" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Outline", 2, 0),
	})

	local knobHigh = Creator.new("Frame", {
		Name = "KnobHigh",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 8,
		ThemeBind = { BackgroundColor3 = "Knob" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Outline", 2, 0),
	})

	local valueLabel = Creator.new("TextLabel", {
		Name = "RangeLabel",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(68, 22),
		Font = Enum.Font.RobotoMono,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
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
		local lowRatio = getRatio(lowVal)
		local highRatio = getRatio(highVal)
		fill.BackgroundColor3 = ThemeManager:Get("Accent")

		local fillPos = UDim2.new(lowRatio, 0, 0.5, 0)
		local fillSize = UDim2.new(math.max(0, highRatio - lowRatio), 0, 1, 0)
		local knobLowPos = UDim2.new(lowRatio, 0, 0.5, 0)
		local knobHighPos = UDim2.new(highRatio, 0, 0.5, 0)

		if animate ~= false then
			Animator.spring(fill, "Position", fillPos, { frequency = 24, damping = 0.85 })
			Animator.spring(fill, "Size", fillSize, { frequency = 24, damping = 0.85 })
			Animator.spring(knobLow, "Position", knobLowPos, { frequency = 24, damping = 0.85 })
			Animator.spring(knobHigh, "Position", knobHighPos, { frequency = 24, damping = 0.85 })
		else
			fill.Position = fillPos
			fill.Size = fillSize
			knobLow.Position = knobLowPos
			knobHigh.Position = knobHighPos
		end
		valueLabel.Text = string.format("%s - %s%s", tostring(lowVal), tostring(highVal), suffix)
	end

	ThemeManager.Changed:Connect(function()
		syncVisuals(true)
	end)

	local function setValue(newL, newH, silent)
		newL = tonumber(newL) or minVal
		newH = tonumber(newH) or maxVal
		newL = Util.round(Util.clamp(newL, minVal, maxVal), step)
		newH = Util.round(Util.clamp(newH, minVal, maxVal), step)
		if newL > newH then
			newL, newH = newH, newL
		end

		local changed = (lowVal ~= newL or highVal ~= newH)
		lowVal = newL
		highVal = newH
		syncVisuals(true)

		local resTbl = { lowVal, highVal }
		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, resTbl, silent)
		end
		if not silent then
			control.Changed:Fire(resTbl)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					resTbl
				)
			end
		end
		return changed
	end

	local activeThumb = nil
	local moveConn = nil
	local releaseConn = nil

	local function updateDragging(input)
		local absX = track.AbsolutePosition.X
		local absW = track.AbsoluteSize.X
		if absW <= 0 then
			return
		end
		local rel = math.clamp((input.Position.X - absX) / absW, 0, 1)
		local raw = minVal + (maxVal - minVal) * rel
		local rounded = Util.round(Util.clamp(raw, minVal, maxVal), step)

		if activeThumb == "low" then
			setValue(math.min(rounded, highVal), highVal, false)
		elseif activeThumb == "high" then
			setValue(lowVal, math.max(rounded, lowVal), false)
		end
	end

	local function startDragging(input)
		if control:IsLocked() then
			return
		end
		local absX = track.AbsolutePosition.X
		local absW = track.AbsoluteSize.X
		local rel = math.clamp((input.Position.X - absX) / math.max(1, absW), 0, 1)
		local lowRatio = getRatio(lowVal)
		local highRatio = getRatio(highVal)

		if math.abs(rel - lowRatio) <= math.abs(rel - highRatio) then
			activeThumb = "low"
			Animator.spring(knobLow, "Size", UDim2.fromOffset(17, 17), { frequency = 22, damping = 0.82 })
		else
			activeThumb = "high"
			Animator.spring(knobHigh, "Size", UDim2.fromOffset(17, 17), { frequency = 22, damping = 0.82 })
		end

		updateDragging(input)

		if moveConn then
			moveConn:Disconnect()
		end
		if releaseConn then
			releaseConn:Disconnect()
		end

		moveConn = Services.UserInputService.InputChanged:Connect(function(moveInput)
			if
				activeThumb
				and (
					moveInput.UserInputType == Enum.UserInputType.MouseMovement
					or moveInput.UserInputType == Enum.UserInputType.Touch
				)
			then
				updateDragging(moveInput)
			end
		end)

		releaseConn = Services.UserInputService.InputEnded:Connect(function(endInput)
			if
				endInput.UserInputType == Enum.UserInputType.MouseButton1
				or endInput.UserInputType == Enum.UserInputType.Touch
			then
				activeThumb = nil
				Animator.spring(knobLow, "Size", UDim2.fromOffset(14, 14), { frequency = 20, damping = 0.85 })
				Animator.spring(knobHigh, "Size", UDim2.fromOffset(14, 14), { frequency = 20, damping = 0.85 })
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

	function control:Get()
		return { lowVal, highVal }
	end

	function control:Set(tbl, silent)
		if type(tbl) == "table" then
			setValue(tbl[1], tbl[2], silent)
		end
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncVisuals(false)
	return control
end

return RangeSlider
