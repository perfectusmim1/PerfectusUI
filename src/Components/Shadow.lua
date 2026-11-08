local Creator = require("Core/Creator")

local Shadow = {}

function Shadow.create(parent, spread, transparency, zIndex)
	spread = spread or 28
	transparency = transparency or 0.42
	return Creator.new("ImageLabel", {
		Name = "DropShadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 4),
		Size = UDim2.new(1, spread * 2, 1, spread * 2),
		BackgroundTransparency = 1,
		Image = "rbxassetid://8992230677",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = transparency,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ZIndex = zIndex or math.max(0, (parent and parent.ZIndex or 1) - 1),
		ThemeBind = { ImageColor3 = "Shadow" },
		Parent = parent,
	})
end

return Shadow
