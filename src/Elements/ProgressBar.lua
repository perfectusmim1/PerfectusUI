local Creator = require("Core/Creator")
local Util = require("Core/Util")
local Animator = require("Motion/Animator")
local RowBase = require("Components/RowBase")

local ProgressBar = {}

function ProgressBar.create(section, opts)
	opts = opts or {}
	local maxVal = tonumber(opts.Max) or 100
	local suffix = opts.Suffix or "%"
	local current = Util.clamp(tonumber(opts.Default) or 0, 0, maxVal)
	local statusText = opts.StatusText

	local control = RowBase.create(section, {
		Title = opts.Title or "Progress",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		RightWidth = 175,
		Clickable = false,
	})
	control.Kind = "ProgressBar"

	local pctLabel = Creator.new("TextLabel", {
		Name = "StatusText",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Size = UDim2.new(1, 0, 0, 14),
		Font = Enum.Font.RobotoMono,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 6,
		ThemeBind = { TextColor3 = "TextSecondary" },
		Parent = control.RightSlot,
	})

	local track = Creator.new("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, -3),
		Size = UDim2.fromOffset(165, 7),
		ClipsDescendants = true,
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "InputBg" },
		Parent = control.RightSlot,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Border", 1, 0.35),
	})

	local fill = Creator.new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		ZIndex = 7,
		ThemeBind = { BackgroundColor3 = "Accent" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local function sync(animate)
		local ratio = maxVal > 0 and math.clamp(current / maxVal, 0, 1) or 0
		pctLabel.Text = statusText and tostring(statusText) or (tostring(Util.round(current, 1)) .. suffix)
		if animate ~= false then
			Animator.spring(fill, "Size", UDim2.fromScale(ratio, 1), { frequency = 16, damping = 0.85 })
		else
			fill.Size = UDim2.fromScale(ratio, 1)
		end
	end

	function control:Get()
		return current
	end

	function control:Set(val, customStatus)
		current = Util.clamp(tonumber(val) or 0, 0, maxVal)
		if customStatus ~= nil then
			statusText = customStatus
		end
		sync(true)
		self.Changed:Fire(current)
	end

	function control:SetStatus(text)
		statusText = text
		sync(false)
	end

	sync(false)
	return control
end

return ProgressBar
