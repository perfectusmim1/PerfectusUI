local Creator = require("Core/Creator")
local Util = require("Core/Util")
local RowBase = require("Components/RowBase")

local Stepper = {}

function Stepper.create(section, opts)
	opts = opts or {}
	local minVal = tonumber(opts.Min) or 0
	local maxVal = tonumber(opts.Max) or 100
	local step = tonumber(opts.Step) or 1
	local suffix = opts.Suffix or ""
	local value = Util.round(Util.clamp(tonumber(opts.Default) or minVal, minVal, maxVal), step)

	local control = RowBase.create(section, {
		Title = opts.Title or "Stepper",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = value,
		RightWidth = 136,
		Clickable = false,
	})
	control.Kind = "Stepper"

	local valLabel = Creator.new("TextLabel", {
		Name = "ValueLabel",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -76, 0.5, 0),
		Size = UDim2.fromOffset(58, 22),
		Font = Enum.Font.RobotoMono,
		TextSize = 12,
		Text = tostring(value) .. suffix,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 6,
		ThemeBind = { TextColor3 = "Text" },
		Parent = control.RightSlot,
	})

	local capsule = Creator.new("Frame", {
		Name = "Capsule",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(68, 26),
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = control.RightSlot,
	}, {
		Creator.corner(7),
		Creator.stroke("Border", 1, 0.3),
		Creator.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(1, 14),
			ZIndex = 7,
			ThemeBind = { BackgroundColor3 = "Divider" },
		}),
	})

	local minusBtn = Creator.new("TextButton", {
		Name = "Minus",
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansBold,
		TextSize = 15,
		Text = "−",
		ZIndex = 8,
		ThemeBind = { TextColor3 = "Text" },
		Parent = capsule,
	})

	local plusBtn = Creator.new("TextButton", {
		Name = "Plus",
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansBold,
		TextSize = 15,
		Text = "+",
		ZIndex = 8,
		ThemeBind = { TextColor3 = "Text" },
		Parent = capsule,
	})

	local function setValue(newVal, silent)
		newVal = Util.round(Util.clamp(tonumber(newVal) or minVal, minVal, maxVal), step)
		value = newVal
		valLabel.Text = tostring(value) .. suffix

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
	end

	local function bindHold(btn, delta)
		local holding = false
		btn.InputBegan:Connect(function(input)
			if control:IsLocked() then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				holding = true
				setValue(value + delta, false)
				task.spawn(function()
					task.wait(0.38)
					while holding and btn.Parent and not control:IsLocked() do
						setValue(value + delta, false)
						task.wait(0.08)
					end
				end)
			end
		end)
		btn.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				holding = false
			end
		end)
		btn.MouseLeave:Connect(function()
			holding = false
		end)
	end

	bindHold(minusBtn, -step)
	bindHold(plusBtn, step)

	function control:Get()
		return value
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	return control
end

return Stepper
