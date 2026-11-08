local Services = require("Core/Services")
local Env = require("Core/Env")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local Themes = require("Theme/Themes")
local ThemeManager = require("Theme/ThemeManager")
local Popover = require("Components/Popover")
local RowBase = require("Components/RowBase")

local ColorPicker = {}

local function normalizeColor(val, fallback)
	if typeof(val) == "Color3" then
		return val
	elseif type(val) == "string" then
		return Util.hexToColor(val) or fallback
	elseif type(val) == "table" then
		if val.hex then
			return Util.hexToColor(val.hex) or fallback
		elseif val[1] and val[2] and val[3] then
			local r, g, b = tonumber(val[1]) or 255, tonumber(val[2]) or 255, tonumber(val[3]) or 255
			if r <= 1 and g <= 1 and b <= 1 then
				return Color3.new(r, g, b)
			end
			return Color3.fromRGB(r, g, b)
		end
	end
	return fallback
end

function ColorPicker.create(section, opts)
	opts = opts or {}
	local defaultColor = normalizeColor(opts.Default, Color3.fromRGB(10, 132, 255))
	local currentColor = defaultColor
	local h, s, v = currentColor:ToHSV()
	local rainbow = false
	local rainbowConn = nil

	local control = RowBase.create(section, {
		Title = opts.Title or "Color Picker",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = currentColor,
		RightWidth = 116,
		Clickable = false,
	})
	control.Kind = "ColorPicker"

	local hexLabel = Creator.new("TextLabel", {
		Name = "HexText",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -42, 0.5, 0),
		Size = UDim2.fromOffset(70, 22),
		Font = Enum.Font.RobotoMono,
		TextSize = 11,
		Text = Util.colorToHex(currentColor),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 6,
		ThemeBind = { TextColor3 = "TextSecondary" },
		Parent = control.RightSlot,
	})

	local swatchBtn = Creator.new("TextButton", {
		Name = "Swatch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(34, 22),
		BackgroundColor3 = currentColor,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		Parent = control.RightSlot,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.2),
	})

	local activeUIUpdater = nil

	local function setValue(newCol, silent, fromHSV)
		if not fromHSV then
			currentColor = normalizeColor(newCol, currentColor)
			h, s, v = currentColor:ToHSV()
		else
			currentColor = Color3.fromHSV(h, s, v)
		end
		swatchBtn.BackgroundColor3 = currentColor
		hexLabel.Text = Util.colorToHex(currentColor)
		if activeUIUpdater then
			activeUIUpdater()
		end

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, currentColor, silent)
		end
		if not silent then
			control.Changed:Fire(currentColor)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					currentColor
				)
			end
		end
	end

	local function setRainbow(on)
		rainbow = on == true
		if rainbowConn then
			rainbowConn:Disconnect()
			rainbowConn = nil
		end
		if rainbow then
			rainbowConn = Services.RunService.Heartbeat:Connect(function(dt)
				if not control.Row.Parent then
					setRainbow(false)
					return
				end
				h = (h + dt * 0.18) % 1
				setValue(nil, false, true)
			end)
		end
	end

	local openPop = nil
	swatchBtn.Activated:Connect(function()
		if control:IsLocked() then
			return
		end
		if openPop then
			Popover.close()
			return
		end

		local pop = Popover.open({
			Name = "ColorPickerPopover",
			Anchor = swatchBtn,
			Width = 228,
			Height = 238,
			OnClose = function()
				openPop = nil
				activeUIUpdater = nil
			end,
		})
		if not pop then
			return
		end
		openPop = pop
		Creator.padding(10, 12, 10, 12, pop.content)

		-- 1. SV Square (204 x 116)
		local svBox = Creator.new("TextButton", {
			Name = "SVSquare",
			Size = UDim2.new(1, 0, 0, 114),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 202,
			Parent = pop.content,
		}, {
			Creator.corner(7),
			Creator.stroke("Border", 1, 0.3),
		})

		-- White -> Transparent horizontal saturation overlay
		Creator.new("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 203,
			Parent = svBox,
		}, {
			Creator.corner(7),
			Creator.new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})

		-- Transparent -> Black vertical value overlay
		Creator.new("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			ZIndex = 204,
			Parent = svBox,
		}, {
			Creator.corner(7),
			Creator.new("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				}),
			}),
		})

		local svCursor = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(s, 1 - v),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = currentColor,
			ZIndex = 205,
			Parent = svBox,
		}, {
			Creator.corner(UDim.new(1, 0)),
			Creator.new("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 2,
			}),
		})

		-- 2. Hue Rainbow Bar (204 x 14)
		local hueBar = Creator.new("TextButton", {
			Name = "HueBar",
			Position = UDim2.fromOffset(0, 124),
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 202,
			Parent = pop.content,
		}, {
			Creator.corner(UDim.new(1, 0)),
			Creator.stroke("Border", 1, 0.35),
			Creator.new("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
				}),
			}),
		})

		local hueKnob = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(h, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			ZIndex = 204,
			Parent = hueBar,
		}, {
			Creator.corner(UDim.new(1, 0)),
			Creator.new("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 2,
			}),
		})

		-- 3. Hex Input + Copy + Rainbow Row
		local hexBox = Creator.new("TextBox", {
			Position = UDim2.fromOffset(0, 148),
			Size = UDim2.fromOffset(88, 24),
			Font = Enum.Font.RobotoMono,
			TextSize = 12,
			Text = Util.colorToHex(currentColor),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 203,
			ThemeBind = {
				BackgroundColor3 = "InputBg",
				TextColor3 = "Text",
			},
			Parent = pop.content,
		}, {
			Creator.corner(6),
			Creator.stroke("Border", 1, 0.35),
		})

		local copyBtn = Creator.new("TextButton", {
			Position = UDim2.fromOffset(94, 148),
			Size = UDim2.fromOffset(48, 24),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 11,
			Text = "Copy",
			ZIndex = 203,
			ThemeBind = {
				BackgroundColor3 = "ControlBg",
				TextColor3 = "TextSecondary",
			},
			Parent = pop.content,
		}, {
			Creator.corner(6),
			Creator.stroke("Border", 1, 0.35),
		})

		local rainbowBtn = Creator.new("TextButton", {
			Position = UDim2.fromOffset(148, 148),
			Size = UDim2.fromOffset(56, 24),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 11,
			Text = "Rainbow",
			ZIndex = 203,
			BackgroundColor3 = ThemeManager:Get(rainbow and "Accent" or "ControlBg"),
			TextColor3 = ThemeManager:Get(rainbow and "OnAccent" or "TextSecondary"),
			Parent = pop.content,
		}, {
			Creator.corner(6),
			Creator.stroke("Border", 1, 0.35),
		})

		-- 4. Preset Swatches Row
		local swatchRow = Creator.new("Frame", {
			Position = UDim2.fromOffset(0, 182),
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			ZIndex = 203,
			Parent = pop.content,
		}, {
			Creator.list(
				6,
				Enum.FillDirection.Horizontal,
				Enum.HorizontalAlignment.Left,
				Enum.VerticalAlignment.Center
			),
		})

		for idx, accentName in ipairs(Themes.AccentOrder) do
			local presetColor = Themes.Accents[accentName]
			local pBtn = Creator.new("TextButton", {
				Size = UDim2.fromOffset(20, 20),
				BackgroundColor3 = presetColor,
				Text = "",
				LayoutOrder = idx,
				ZIndex = 204,
				Parent = swatchRow,
			}, {
				Creator.corner(UDim.new(1, 0)),
				Creator.stroke("Border", 1, 0.35),
			})
			pBtn.Activated:Connect(function()
				setRainbow(false)
				rainbowBtn.BackgroundColor3 = ThemeManager:Get("ControlBg")
				rainbowBtn.TextColor3 = ThemeManager:Get("TextSecondary")
				setValue(presetColor, false, false)
			end)
		end

		activeUIUpdater = function()
			if not svBox.Parent then
				return
			end
			svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svCursor.Position = UDim2.fromScale(s, 1 - v)
			svCursor.BackgroundColor3 = currentColor
			hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
			hueKnob.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			if not hexBox:IsFocused() then
				hexBox.Text = Util.colorToHex(currentColor)
			end
		end

		-- Drag SV & Hue
		local dragSV = false
		local dragHue = false
		local moveConn, endConn

		local function updateSV(pos)
			local absP = svBox.AbsolutePosition
			local absS = svBox.AbsoluteSize
			s = math.clamp((pos.X - absP.X) / math.max(1, absS.X), 0, 1)
			v = 1 - math.clamp((pos.Y - absP.Y) / math.max(1, absS.Y), 0, 1)
			setValue(nil, false, true)
		end

		local function updateHue(pos)
			local absP = hueBar.AbsolutePosition
			local absS = hueBar.AbsoluteSize
			h = math.clamp((pos.X - absP.X) / math.max(1, absS.X), 0, 1)
			setValue(nil, false, true)
		end

		local function bindDrag(startPos, isHue)
			if isHue then
				dragHue = true
				updateHue(startPos)
			else
				dragSV = true
				updateSV(startPos)
			end
			if moveConn then
				moveConn:Disconnect()
			end
			if endConn then
				endConn:Disconnect()
			end
			moveConn = Services.UserInputService.InputChanged:Connect(function(inp)
				if
					inp.UserInputType == Enum.UserInputType.MouseMovement
					or inp.UserInputType == Enum.UserInputType.Touch
				then
					if dragSV then
						updateSV(inp.Position)
					elseif dragHue then
						updateHue(inp.Position)
					end
				end
			end)
			endConn = Services.UserInputService.InputEnded:Connect(function(inp)
				if
					inp.UserInputType == Enum.UserInputType.MouseButton1
					or inp.UserInputType == Enum.UserInputType.Touch
				then
					dragSV = false
					dragHue = false
					if moveConn then
						moveConn:Disconnect()
						moveConn = nil
					end
					if endConn then
						endConn:Disconnect()
						endConn = nil
					end
				end
			end)
		end

		svBox.InputBegan:Connect(function(inp)
			if
				inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch
			then
				bindDrag(inp.Position, false)
			end
		end)

		hueBar.InputBegan:Connect(function(inp)
			if
				inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch
			then
				bindDrag(inp.Position, true)
			end
		end)

		hexBox.FocusLost:Connect(function()
			local parsed = Util.hexToColor(hexBox.Text)
			if parsed then
				setValue(parsed, false, false)
			else
				hexBox.Text = Util.colorToHex(currentColor)
			end
		end)

		copyBtn.Activated:Connect(function()
			Env.setClipboard(Util.colorToHex(currentColor))
			copyBtn.Text = "Copied"
			task.delay(1.2, function()
				if copyBtn.Parent then
					copyBtn.Text = "Copy"
				end
			end)
		end)

		rainbowBtn.Activated:Connect(function()
			setRainbow(not rainbow)
			rainbowBtn.BackgroundColor3 = ThemeManager:Get(rainbow and "Accent" or "ControlBg")
			rainbowBtn.TextColor3 = ThemeManager:Get(rainbow and "OnAccent" or "TextSecondary")
		end)
	end)

	function control:Get()
		return currentColor
	end

	function control:Set(col, silent)
		setValue(col, silent, false)
	end

	function control:SetRainbow(on)
		setRainbow(on)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	return control
end

return ColorPicker
