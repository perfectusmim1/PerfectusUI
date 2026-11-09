local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local RowBase = require("Components/RowBase")

local Segmented = {}

function Segmented.create(section, opts)
	opts = opts or {}
	local options = type(opts.Options) == "table" and #opts.Options > 0 and opts.Options or { "One", "Two" }
	local selected = opts.Default or options[1]

	local control = RowBase.create(section, {
		Title = opts.Title or "Segmented",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = selected,
		RightWidth = 192,
		Clickable = false,
	})
	control.Kind = "Segmented"

	local track = Creator.new("Frame", {
		Name = "SegmentTrack",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(186, 28),
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "InputBg" },
		Parent = control.RightSlot,
	}, {
		Creator.corner(8),
		Creator.stroke("Outline", 1, 0),
		Creator.padding(2, 2, 2, 2),
	})

	local thumb = Creator.new("Frame", {
		Name = "Thumb",
		Size = UDim2.new(1 / #options, 0, 1, 0),
		ZIndex = 7,
		ThemeBind = { BackgroundColor3 = "Accent" },
		Parent = track,
	}, {
		Creator.corner(6),
	})

	local btnHolder = Creator.new("Frame", {
		Name = "Buttons",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 8,
		Parent = track,
	})

	local buttons = {}

	local function syncVisuals(animate)
		local n = math.max(1, #options)
		local activeIndex = 1
		for i, opt in ipairs(options) do
			if tostring(opt) == tostring(selected) then
				activeIndex = i
				break
			end
		end

		local targetSize = UDim2.new(1 / n, 0, 1, 0)
		local targetPos = UDim2.new((activeIndex - 1) / n, 0, 0, 0)
		if animate ~= false then
			Animator.spring(thumb, "Size", targetSize, { frequency = 20, damping = 0.85 })
			Animator.spring(thumb, "Position", targetPos, { frequency = 20, damping = 0.85 })
		else
			thumb.Size = targetSize
			thumb.Position = targetPos
		end

		for i, btn in ipairs(buttons) do
			local isCurrent = (i == activeIndex)
			btn.Font = isCurrent and Enum.Font.BuilderSansBold or Enum.Font.BuilderSansMedium
			btn.TextColor3 = ThemeManager:Get(isCurrent and "OnAccent" or "TextSecondary")
		end
	end

	local function setValue(val, silent)
		val = tostring(val or options[1])
		selected = val
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

	local function rebuildButtons()
		for _, b in ipairs(buttons) do
			b:Destroy()
		end
		table.clear(buttons)
		local n = math.max(1, #options)
		for i, opt in ipairs(options) do
			local label = tostring(opt)
			local btn = Creator.new("TextButton", {
				Name = "Seg_" .. label,
				Position = UDim2.new((i - 1) / n, 0, 0, 0),
				Size = UDim2.new(1 / n, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.BuilderSansMedium,
				TextSize = 13,
				Text = label,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 9,
				Parent = btnHolder,
			})
			btn.Activated:Connect(function()
				if control:IsLocked() then
					return
				end
				setValue(label, false)
			end)
			buttons[i] = btn
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
			selected = options[1]
			rebuildButtons()
		end
	end

	rebuildButtons()

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	return control
end

return Segmented
