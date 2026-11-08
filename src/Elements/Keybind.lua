local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local RowBase = require("Components/RowBase")

local Keybind = {}

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
		local okUser, itemUser = pcall(function()
			return Enum.UserInputType[key]
		end)
		if okUser and itemUser then
			return itemUser
		end
	end
	return nil
end

function Keybind.create(section, opts)
	opts = opts or {}
	local currentKey = parseKey(opts.Default or opts.Key)
	local mode = opts.Mode or "Toggle" -- "Toggle" | "Hold" | "Always"
	local allowModeChange = opts.AllowModeChange ~= false
	local active = mode == "Always"
	local listening = false

	local control = RowBase.create(section, {
		Title = opts.Title or "Keybind",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = currentKey and currentKey.Name or "None",
		RightWidth = 135,
		Clickable = false,
	})
	control.Kind = "Keybind"

	local modePill = Creator.new("TextButton", {
		Name = "ModePill",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -78, 0.5, 0),
		Size = UDim2.fromOffset(52, 22),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 11,
		Text = mode,
		AutoButtonColor = false,
		ZIndex = 6,
		ThemeBind = {
			BackgroundColor3 = "ControlBg",
			TextColor3 = "TextSecondary",
		},
		Parent = control.RightSlot,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.35),
	})

	local keyBtn = Creator.new("TextButton", {
		Name = "KeyButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(74, 24),
		Font = Enum.Font.RobotoMono,
		TextSize = 12,
		Text = Util.formatKeyName(currentKey),
		AutoButtonColor = false,
		ZIndex = 6,
		ThemeBind = {
			BackgroundColor3 = "ControlBg",
			TextColor3 = "Text",
		},
		Parent = control.RightSlot,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.35),
	})

	local function syncVisuals()
		keyBtn.Text = listening and "..." or Util.formatKeyName(currentKey)
		modePill.Text = mode
		keyBtn.TextColor3 = ThemeManager:Get(listening and "Accent" or "Text")
	end

	if allowModeChange then
		modePill.Activated:Connect(function()
			if control:IsLocked() then
				return
			end
			if mode == "Toggle" then
				mode = "Hold"
			elseif mode == "Hold" then
				mode = "Always"
			else
				mode = "Toggle"
			end
			active = (mode == "Always")
			syncVisuals()
			if control.Window and control.Window._updateKeybindEntry then
				control.Window:_updateKeybindEntry(control)
			end
		end)
	else
		modePill.Visible = false
		keyBtn.Position = UDim2.new(1, 0, 0.5, 0)
	end

	keyBtn.Activated:Connect(function()
		if control:IsLocked() then
			return
		end
		listening = true
		syncVisuals()
	end)

	Services.UserInputService.InputBegan:Connect(function(input, processed)
		if not control.Row.Parent then
			return
		end
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
					control:SetKey(nil)
				else
					control:SetKey(input.KeyCode)
				end
				syncVisuals()
			elseif
				input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3
			then
				listening = false
				control:SetKey(input.UserInputType)
				syncVisuals()
			end
			return
		end

		if processed or not currentKey or control:IsLocked() then
			return
		end
		if Services.UserInputService:GetFocusedTextBox() ~= nil then
			return
		end

		if input.KeyCode == currentKey or input.UserInputType == currentKey then
			if mode == "Toggle" then
				active = not active
			else
				active = true
			end
			if control.Window and control.Window._updateKeybindEntry then
				control.Window:_updateKeybindEntry(control)
			end
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					active,
					currentKey
				)
			end
			control.Changed:Fire(active, currentKey)
		end
	end)

	Services.UserInputService.InputEnded:Connect(function(input)
		if not control.Row.Parent or control:IsLocked() or not currentKey then
			return
		end
		if mode == "Hold" and (input.KeyCode == currentKey or input.UserInputType == currentKey) then
			active = false
			if control.Window and control.Window._updateKeybindEntry then
				control.Window:_updateKeybindEntry(control)
			end
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					false,
					currentKey
				)
			end
			control.Changed:Fire(false, currentKey)
		end
	end)

	function control:Get()
		return currentKey
	end

	function control:GetKey()
		return currentKey
	end

	function control:SetKey(newKey, silent)
		currentKey = parseKey(newKey)
		syncVisuals()
		local keyName = currentKey and currentKey.Name or "None"
		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, keyName, silent)
		end
		if control.Window and control.Window._updateKeybindEntry then
			control.Window:_updateKeybindEntry(control)
		end
		if not silent then
			control.Changed:Fire(active, currentKey)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					active,
					currentKey
				)
			end
		end
	end

	function control:Set(newKey, silent)
		self:SetKey(newKey, silent)
	end

	function control:GetMode()
		return mode
	end

	function control:SetMode(newMode)
		if newMode == "Toggle" or newMode == "Hold" or newMode == "Always" then
			mode = newMode
			active = (mode == "Always")
			syncVisuals()
			if control.Window and control.Window._updateKeybindEntry then
				control.Window:_updateKeybindEntry(control)
			end
		end
	end

	function control:IsActive()
		return active
	end

	if control.Window and control.Window._registerKeybindEntry then
		control.Window:_registerKeybindEntry(control)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncVisuals()
	return control
end

return Keybind
