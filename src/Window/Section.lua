local Creator = require("Core/Creator")
local Icons = require("Assets/Icons")

local Button = require("Elements/Button")
local Toggle = require("Elements/Toggle")
local Checkbox = require("Elements/Checkbox")
local Slider = require("Elements/Slider")
local RangeSlider = require("Elements/RangeSlider")
local Dropdown = require("Elements/Dropdown")
local Input = require("Elements/Input")
local Keybind = require("Elements/Keybind")
local ColorPicker = require("Elements/ColorPicker")
local Segmented = require("Elements/Segmented")
local Stepper = require("Elements/Stepper")
local RadioGroup = require("Elements/RadioGroup")
local ProgressBar = require("Elements/ProgressBar")
local Stat = require("Elements/Stat")
local Label = require("Elements/Label")
local Paragraph = require("Elements/Paragraph")
local Divider = require("Elements/Divider")
local Image = require("Elements/Image")
local CodeBlock = require("Elements/CodeBlock")

local Section = {}
Section.__index = Section

function Section.new(tab, opts)
	if type(opts) == "string" then
		opts = { Title = opts }
	end
	opts = opts or {}

	local title = tostring(opts.Title or opts.Name or "")
	local order = tab:_nextSectionOrder()

	-- Sleek Bento Section Card
	local card = Creator.new("Frame", {
		Name = "Section_" .. (title ~= "" and title or tostring(order)),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		LayoutOrder = order,
		ZIndex = 2,
		ThemeBind = { BackgroundColor3 = "SectionBg" },
		Parent = tab.Scroll.Frame,
	}, {
		Creator.corner(14),
		Creator.stroke("Outline", 1.2, 0),
		Creator.padding(12, 12, 12, 12),
		Creator.list(8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local showHeader = title ~= "" and not (order == 1 and string.upper(title) == string.upper(tab.Title))
	if showHeader then
		local headerRow = Creator.new("Frame", {
			Name = "CardTitleRow",
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			LayoutOrder = 0,
			ZIndex = 3,
			Parent = card,
		})

		local textOffset = 0
		if opts.Icon then
			textOffset = 22
			Creator.new("ImageLabel", {
				Name = "HeaderIcon",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				Image = Icons.resolve(opts.Icon) or "",
				ZIndex = 4,
				ThemeBind = { ImageColor3 = "Accent" },
				Parent = headerRow,
			})
		end

		Creator.new("TextLabel", {
			Name = "HeaderTitle",
			Position = UDim2.fromOffset(textOffset, 0),
			Size = UDim2.new(1, -textOffset, 1, 0),
			Font = Enum.Font.BuilderSansBold,
			TextSize = 13,
			Text = title,
			ZIndex = 4,
			ThemeBind = { TextColor3 = "SectionHeader" },
			Parent = headerRow,
		})
	end

	local self = setmetatable({
		Title = title,
		Tab = tab,
		Window = tab.Window,
		Root = card,
		Container = card,
		_itemOrder = 0,
	}, Section)

	return self
end

function Section:_nextOrder()
	self._itemOrder += 1
	return self._itemOrder
end

function Section:Button(opts)
	return Button.create(self, opts)
end
Section.AddButton = Section.Button
Section.CreateButton = Section.Button

function Section:Toggle(opts)
	return Toggle.create(self, opts)
end
Section.AddToggle = Section.Toggle
Section.CreateToggle = Section.Toggle

function Section:Checkbox(opts)
	return Checkbox.create(self, opts)
end
Section.AddCheckbox = Section.Checkbox

function Section:Slider(opts)
	return Slider.create(self, opts)
end
Section.AddSlider = Section.Slider
Section.CreateSlider = Section.Slider

function Section:RangeSlider(opts)
	return RangeSlider.create(self, opts)
end
Section.AddRangeSlider = Section.RangeSlider

function Section:Dropdown(opts)
	return Dropdown.create(self, opts)
end
Section.AddDropdown = Section.Dropdown
Section.CreateDropdown = Section.Dropdown

function Section:Input(opts)
	return Input.create(self, opts)
end
Section.AddInput = Section.Input
Section.CreateInput = Section.Input

function Section:Keybind(opts)
	return Keybind.create(self, opts)
end
Section.AddKeybind = Section.Keybind
Section.CreateKeybind = Section.Keybind

function Section:ColorPicker(opts)
	return ColorPicker.create(self, opts)
end
Section.AddColorPicker = Section.ColorPicker
Section.CreateColorPicker = Section.ColorPicker

function Section:Segmented(opts)
	return Segmented.create(self, opts)
end
Section.AddSegmented = Section.Segmented

function Section:Stepper(opts)
	return Stepper.create(self, opts)
end
Section.AddStepper = Section.Stepper

function Section:RadioGroup(opts)
	return RadioGroup.create(self, opts)
end
Section.AddRadioGroup = Section.RadioGroup

function Section:ProgressBar(opts)
	return ProgressBar.create(self, opts)
end
Section.AddProgressBar = Section.ProgressBar

function Section:Stat(opts)
	return Stat.create(self, opts)
end
Section.AddStat = Section.Stat

function Section:Label(opts)
	return Label.create(self, opts)
end
Section.AddLabel = Section.Label
Section.CreateLabel = Section.Label

function Section:Paragraph(opts)
	return Paragraph.create(self, opts)
end
Section.AddParagraph = Section.Paragraph
Section.CreateParagraph = Section.Paragraph

function Section:Divider(opts)
	return Divider.create(self, opts)
end
Section.AddDivider = Section.Divider

function Section:Image(opts)
	return Image.create(self, opts)
end
Section.AddImage = Section.Image

function Section:CodeBlock(opts)
	return CodeBlock.create(self, opts)
end
Section.AddCodeBlock = Section.CodeBlock

return Section
