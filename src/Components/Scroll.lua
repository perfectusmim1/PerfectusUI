local Creator = require("Core/Creator")
local Signal = require("Core/Signal")

local Scroll = {}

function Scroll.create(props)
	props = props or {}
	local scrolled = Signal.new()

	local frame = Creator.new("ScrollingFrame", {
		Name = props.Name or "ScrollContainer",
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = props.ScrollBarThickness or 3,
		ScrollBarImageTransparency = 0.45,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true,
		Visible = props.Visible ~= false,
		ZIndex = props.ZIndex or 2,
		ThemeBind = { ScrollBarImageColor3 = "TextMuted" },
		Parent = props.Parent,
	})

	local pad = props.Padding or { Top = 14, Right = 16, Bottom = 18, Left = 16 }
	Creator.padding(pad.Top, pad.Right, pad.Bottom, pad.Left, frame)

	local list = Creator.list(
		props.Spacing or 12,
		Enum.FillDirection.Vertical,
		Enum.HorizontalAlignment.Left,
		Enum.VerticalAlignment.Top,
		frame
	)

	frame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		scrolled:Fire(frame.CanvasPosition)
	end)

	return {
		Frame = frame,
		ListLayout = list,
		Scrolled = scrolled,
	}
end

return Scroll
