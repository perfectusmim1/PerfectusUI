local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local RowBase = require("Components/RowBase")

local Input = {}

function Input.create(section, opts)
	opts = opts or {}
	local isNumeric = opts.Numeric == true
	local maxLength = tonumber(opts.MaxLength)
	local finishedOnly = opts.Finished == true
	local pattern = opts.Pattern

	local initial = opts.Default ~= nil and tostring(opts.Default) or ""
	if isNumeric then
		initial = initial:gsub("[^%d.-]", "")
	end
	if maxLength and #initial > maxLength then
		initial = initial:sub(1, maxLength)
	end
	local currentText = initial

	local control = RowBase.create(section, {
		Title = opts.Title or "Input",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = currentText,
		RightWidth = 175,
		Clickable = false,
	})
	control.Kind = "Input"

	local container = Creator.new("Frame", {
		Name = "InputContainer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(175, 28),
		BackgroundColor3 = ThemeManager:Get("InputBg"),
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "InputBg" },
		Parent = control.RightSlot,
	}, {
		Creator.corner(7),
	})

	local stroke = Creator.stroke("Border", 1, 0.35, container)

	local clearBtn = Creator.new("ImageButton", {
		Name = "ClearButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Image = Icons.resolve("x") or "",
		Visible = #currentText > 0,
		ZIndex = 8,
		ThemeBind = { ImageColor3 = "TextMuted" },
		Parent = container,
	})

	local textBox = Creator.new("TextBox", {
		Name = "TextBox",
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Font = Enum.Font.BuilderSans,
		TextSize = 13,
		Text = currentText,
		PlaceholderText = opts.Placeholder or "Type here...",
		ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
		ThemeBind = {
			TextColor3 = "Text",
			PlaceholderColor3 = "TextMuted",
		},
		Parent = container,
	})

	local function shakeError()
		stroke.Color = ThemeManager:Get("Error")
		stroke.Transparency = 0
		local origPos = container.Position
		task.spawn(function()
			for _ = 1, 3 do
				container.Position = origPos + UDim2.fromOffset(4, 0)
				task.wait(0.04)
				container.Position = origPos + UDim2.fromOffset(-4, 0)
				task.wait(0.04)
			end
			container.Position = origPos
			Animator.tween(stroke, { Color = ThemeManager:Get("Border"), Transparency = 0.35 }, 0.25)
		end)
	end

	local function setValue(val, silent)
		val = tostring(val or "")
		if isNumeric then
			val = val:gsub("[^%d.-]", "")
		end
		if maxLength and #val > maxLength then
			val = val:sub(1, maxLength)
		end

		local changed = (currentText ~= val)
		currentText = val
		textBox.Text = currentText
		clearBtn.Visible = #currentText > 0

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, currentText, silent)
		end
		if not silent then
			control.Changed:Fire(currentText)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					currentText
				)
			end
		end
		return changed
	end

	textBox.Focused:Connect(function()
		if control:IsLocked() then
			textBox:ReleaseFocus()
			return
		end
		Animator.tween(stroke, { Color = ThemeManager:Get("Accent"), Transparency = 0 }, 0.15)
	end)

	textBox.FocusLost:Connect(function()
		Animator.tween(stroke, { Color = ThemeManager:Get("Border"), Transparency = 0.35 }, 0.15)
		local text = textBox.Text
		if isNumeric then
			text = text:gsub("[^%d.-]", "")
		end
		if maxLength and #text > maxLength then
			text = text:sub(1, maxLength)
		end

		if pattern and #text > 0 then
			local ok, matched = pcall(function()
				return string.match(text, pattern)
			end)
			if not ok or not matched then
				shakeError()
				return
			end
		end

		setValue(text, false)
	end)

	if not finishedOnly then
		textBox:GetPropertyChangedSignal("Text"):Connect(function()
			local raw = textBox.Text
			if isNumeric then
				local filtered = raw:gsub("[^%d.-]", "")
				if filtered ~= raw then
					textBox.Text = filtered
					raw = filtered
				end
			end
			if maxLength and #raw > maxLength then
				raw = raw:sub(1, maxLength)
				textBox.Text = raw
			end
			clearBtn.Visible = #raw > 0
			if currentText ~= raw then
				currentText = raw
				if control.Flag and control.Window and control.Window.Flags then
					control.Window.Flags:_setRaw(control.Flag, currentText, false)
				end
				control.Changed:Fire(currentText)
				if type(opts.Callback) == "function" then
					task.spawn(
						Util.safeCall,
						control.Title,
						opts.Callback,
						control.Window and control.Window._notifyError,
						currentText
					)
				end
			end
		end)
	end

	clearBtn.Activated:Connect(function()
		if control:IsLocked() then
			return
		end
		setValue("", false)
	end)

	function control:Get()
		return currentText
	end

	function control:Set(str, silent)
		setValue(str, silent)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	return control
end

return Input
