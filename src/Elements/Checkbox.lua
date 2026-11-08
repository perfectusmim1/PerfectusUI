local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local RowBase = require("Components/RowBase")

local Checkbox = {}

function Checkbox.create(section, opts)
	opts = opts or {}
	local state = opts.Default == true

	local control = RowBase.create(section, {
		Title = opts.Title or "Checkbox",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = state,
		RightWidth = 40,
		Clickable = true,
	})
	control.Kind = "Checkbox"

	local box = Creator.new("Frame", {
		Name = "CheckFrame",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = ThemeManager:Get(state and "Accent" or "ControlBg"),
		ZIndex = 6,
		Parent = control.RightSlot,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.35),
	})

	local icon = Creator.new("ImageLabel", {
		Name = "CheckIcon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Image = Icons.resolve("check") or "",
		ImageTransparency = state and 0 or 1,
		ZIndex = 7,
		ThemeBind = { ImageColor3 = "OnAccent" },
		Parent = box,
	})

	local iconScale = Creator.new("UIScale", {
		Scale = state and 1 or 0.75,
		Parent = icon,
	})

	local function syncVisuals(animate)
		local targetColor = ThemeManager:Get(state and "Accent" or "ControlBg")
		local targetTrans = state and 0 or 1
		local targetScale = state and 1 or 0.75

		if animate ~= false then
			Animator.tween(box, { BackgroundColor3 = targetColor }, 0.16)
			Animator.tween(icon, { ImageTransparency = targetTrans }, 0.14)
			Animator.spring(iconScale, "Scale", targetScale, { frequency = 20, damping = 0.8 })
		else
			box.BackgroundColor3 = targetColor
			icon.ImageTransparency = targetTrans
			iconScale.Scale = targetScale
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
		if control:IsLocked() then
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

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncVisuals(false)
	return control
end

return Checkbox
