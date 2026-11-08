local Creator = require("Core/Creator")
local Icons = require("Assets/Icons")

local Image = {}

function Image.create(section, opts)
	opts = opts or {}
	local height = tonumber(opts.Height) or 110
	local title = opts.Title

	local card = Creator.new("Frame", {
		Name = "ImageCard",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		ThemeBind = { BackgroundColor3 = "RowBg" },
		Parent = section.Container,
	}, {
		Creator.corner(8),
		Creator.padding(8, 10, 8, 10),
		Creator.list(6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local titleLabel = nil
	if title and title ~= "" then
		titleLabel = Creator.new("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, 0, 0, 16),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 13,
			Text = tostring(title),
			LayoutOrder = 1,
			ZIndex = 4,
			ThemeBind = { TextColor3 = "Text" },
			Parent = card,
		})
	end

	local img = Creator.new("ImageLabel", {
		Name = "BannerImage",
		Size = UDim2.new(1, 0, 0, height),
		Image = Icons.resolve(opts.Image or "sparkles") or "",
		ScaleType = opts.ScaleType or Enum.ScaleType.Fit,
		LayoutOrder = 2,
		ZIndex = 4,
		ThemeBind = { BackgroundColor3 = "InputBg" },
		BackgroundTransparency = 0,
		Parent = card,
	}, {
		Creator.corner(6),
		Creator.stroke("Border", 1, 0.35),
	})

	return {
		Kind = "Image",
		Row = card,
		ImageLabel = img,
		SetImage = function(_, newImg)
			img.Image = Icons.resolve(newImg) or ""
		end,
		SetTitle = function(_, newTitle)
			if titleLabel then
				titleLabel.Text = tostring(newTitle or "")
			end
		end,
		SetVisible = function(_, vis)
			card.Visible = vis == true
		end,
		Destroy = function()
			card:Destroy()
		end,
	}
end

return Image
