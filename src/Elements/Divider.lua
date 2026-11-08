local Creator = require("Core/Creator")
local Util = require("Core/Util")

local Divider = {}

function Divider.create(section, opts)
	local text = nil
	if type(opts) == "string" then
		text = opts
	elseif type(opts) == "table" then
		text = opts.Text or opts.Title
	end

	local holder = Creator.new("Frame", {
		Name = "Divider",
		Size = UDim2.new(1, 0, 0, text and 20 or 9),
		BackgroundTransparency = 1,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		Parent = section.Container,
	}, {
		Creator.padding(0, 8, 0, 8),
	})

	local label = nil
	local line = nil

	if text and text ~= "" then
		local upperText = string.upper(tostring(text))
		local textW = math.ceil(Util.measureText(upperText, 10, Enum.Font.BuilderSansBold, 400).X) + 12
		label = Creator.new("TextLabel", {
			Name = "Label",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(textW, 14),
			Font = Enum.Font.BuilderSansBold,
			TextSize = 10,
			Text = upperText,
			ZIndex = 4,
			ThemeBind = { TextColor3 = "SectionHeader" },
			Parent = holder,
		})
		line = Creator.new("Frame", {
			Name = "Line",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, textW, 0.5, 0),
			Size = UDim2.new(1, -textW, 0, 1),
			ZIndex = 3,
			ThemeBind = { BackgroundColor3 = "Divider" },
			Parent = holder,
		})
	else
		line = Creator.new("Frame", {
			Name = "Line",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 3,
			ThemeBind = { BackgroundColor3 = "Divider" },
			Parent = holder,
		})
	end

	return {
		Kind = "Divider",
		Row = holder,
		Set = function(_, newText)
			if label and line then
				local upper = string.upper(tostring(newText or ""))
				local w = math.ceil(Util.measureText(upper, 10, Enum.Font.BuilderSansBold, 400).X) + 12
				label.Text = upper
				label.Size = UDim2.fromOffset(w, 14)
				line.Position = UDim2.new(0, w, 0.5, 0)
				line.Size = UDim2.new(1, -w, 0, 1)
			end
		end,
		SetVisible = function(_, vis)
			holder.Visible = vis == true
		end,
		Destroy = function()
			holder:Destroy()
		end,
	}
end

return Divider
