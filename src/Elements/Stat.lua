local Creator = require("Core/Creator")
local RowBase = require("Components/RowBase")

local Stat = {}

function Stat.create(section, opts)
	opts = opts or {}
	local currentVal = tostring(opts.Value or opts.Default or "—")

	local control = RowBase.create(section, {
		Title = opts.Title or "Metric",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		RightWidth = 150,
		MinHeight = 38,
		Clickable = false,
	})
	control.Kind = "Stat"

	local valueLabel = Creator.new("TextLabel", {
		Name = "MetricValue",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.RobotoMono,
		TextSize = 13,
		Text = currentVal,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
		ThemeBind = { TextColor3 = opts.ColorToken or "Accent" },
		Parent = control.RightSlot,
	})

	function control:Get()
		return currentVal
	end

	function control:Set(newVal)
		currentVal = tostring(newVal or "")
		valueLabel.Text = currentVal
		self.Changed:Fire(currentVal)
	end

	control.SetValue = control.Set
	return control
end

return Stat
