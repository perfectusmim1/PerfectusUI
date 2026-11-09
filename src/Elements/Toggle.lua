local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Env = require("Core/Env")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local RowBase = require("Components/RowBase")

local Toggle = {}

local function parseKey(key)
	if key == nil or key == "" or key == "None" then
		return nil
	end
	if typeof(key) == "EnumItem" then
		return key
	end
	if type(key) == "string" then
		local ok, item = pcall(function()
			return Enum.KeyCode[key]
		end)
		if ok and item then
			return item
		end
	end
	return nil
end

function Toggle.create(section, opts)
	opts = opts or {}
	local state = opts.Default == true
	local currentKey = parseKey(opts.Key)
	local hasKeybindSlot = (opts.Key ~= nil or opts.AllowKeybind == true) and not Env.IsMobile

	local control = RowBase.create(section, {
		Title = opts.Title or "Toggle",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = state,
		RightWidth = hasKeybindSlot and 106 or 50,
		Clickable = true,
	})
	control.Kind = "Toggle"

	local keyBtn = nil
	local listeningKey = false
	if hasKeybindSlot then
		keyBtn = Creator.new("TextButton", {
			Name = "KeyChip",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -52, 0.5, 0),
			Size = UDim2.fromOffset(44, 24),
			Font = Enum.Font.BuilderSansBold,
			TextSize = 12,
			Text = Util.formatKeyName(currentKey),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 6,
			ThemeBind = {
				BackgroundColor3 = "ControlBg",
				TextColor3 = "Text",
			},
			Parent = control.RightSlot,
		}, {
			Creator.corner(6),
			Creator.stroke("Outline", 1, 0),
		})
	end

	-- Sleek Switch Track (44 x 24)
	local track = Creator.new("Frame", {
		Name = "SwitchTrack",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(44, 24),
		BackgroundColor3 = ThemeManager:Get(state and "Accent" or "SwitchOff"),
		ZIndex = 6,
		Parent = control.RightSlot,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Outline", 1, 0),
	})

	local knob = Creator.new("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 7,
		ThemeBind = { BackgroundColor3 = "Knob" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local function syncVisuals(animate)
		local targetColor = ThemeManager:Get(state and "Accent" or "SwitchOff")
		local targetPos = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		if animate ~= false then
			Animator.tween(track, { BackgroundColor3 = targetColor }, 0.18)
			Animator.spring(knob, "Position", targetPos, { frequency = 18, damping = 0.82 })
			Animator.spring(knob, "Size", UDim2.fromOffset(18, 18), { frequency = 18, damping = 0.82 })
		else
			track.BackgroundColor3 = targetColor
			knob.Position = targetPos
			knob.Size = UDim2.fromOffset(18, 18)
		end
	end

	ThemeManager.Changed:Connect(function()
		syncVisuals(true)
	end)

	local function setValue(newVal, silent)
		newVal = newVal == true
		local changed = (state ~= newVal)
		state = newVal
		syncVisuals(true)
		if control.Window and control.Window._updateKeybindEntry then
			control.Window:_updateKeybindEntry(control)
		end
		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, state, silent)
		end
		if not silent then
			control.Changed:Fire(state)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					state
				)
			end
		end
		return changed
	end

	control.Row.Activated:Connect(function()
		if control:IsLocked() or listeningKey then
			return
		end
		setValue(not state, false)
	end)

	function control:Get()
		return state
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	function control:GetKey()
		return currentKey
	end

	function control:SetKey(newKey)
		currentKey = parseKey(newKey)
		if keyBtn then
			keyBtn.Text = Util.formatKeyName(currentKey)
		end
		if control.Window and control.Window._updateKeybindEntry then
			control.Window:_updateKeybindEntry(control)
		end
	end

	if keyBtn then
		keyBtn.Activated:Connect(function()
			if control:IsLocked() then
				return
			end
			listeningKey = true
			keyBtn.Text = "..."
		end)

		Services.UserInputService.InputBegan:Connect(function(input, processed)
			if not control.Row.Parent then
				return
			end
			if listeningKey then
				if input.UserInputType == Enum.UserInputType.Keyboard then
					listeningKey = false
					if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
						control:SetKey(nil)
					else
						control:SetKey(input.KeyCode)
					end
				end
				return
			end
			if not processed and currentKey and input.KeyCode == currentKey then
				if Services.UserInputService:GetFocusedTextBox() == nil and not control:IsLocked() then
					setValue(not state, false)
				end
			end
		end)
	end

	if control.Window and control.Window._registerKeybindEntry and hasKeybindSlot then
		control.Window:_registerKeybindEntry(control)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncVisuals(false)
	return control
end

return Toggle
