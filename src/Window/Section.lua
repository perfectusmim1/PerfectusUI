local Creator = require("Core/Creator")
local Icons = require("Assets/Icons")
local Animator = require("Motion/Animator")

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
	local collapsible = opts.Collapsible == true
	local collapsed = opts.Collapsed == true

	local root = Creator.new("Frame", {
		Name = "Section_" .. (title ~= "" and title or "Group"),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = tab:_nextSectionOrder(),
		ZIndex = 2,
		Parent = tab.Scroll.Frame,
	}, {
		Creator.list(6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local headerBtn = nil
	local chevronImg = nil
	if title ~= "" then
		headerBtn = Creator.new("TextButton", {
			Name = "SectionHeader",
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = "",
			LayoutOrder = 1,
			ZIndex = 3,
			Parent = root,
		}, {
			Creator.padding(0, 4, 0, 4),
		})

		local iconOffset = 0
		if opts.Icon then
			iconOffset = 18
			Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(13, 13),
				Image = Icons.resolve(opts.Icon) or "",
				ZIndex = 3,
				ThemeBind = { ImageColor3 = "SectionHeader" },
				Parent = headerBtn,
			})
		end

		Creator.new("TextLabel", {
			Name = "HeaderTitle",
			Position = UDim2.fromOffset(iconOffset, 0),
			Size = UDim2.new(1, -(iconOffset + 20), 1, 0),
			Font = Enum.Font.BuilderSansBold,
			TextSize = 11,
			Text = string.upper(title),
			ZIndex = 3,
			ThemeBind = { TextColor3 = "SectionHeader" },
			Parent = headerBtn,
		})

		if collapsible then
			chevronImg = Creator.new("ImageLabel", {
				Name = "Chevron",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(13, 13),
				Image = Icons.resolve("chevron-down") or "",
				Rotation = collapsed and -90 or 0,
				ZIndex = 3,
				ThemeBind = { ImageColor3 = "SectionHeader" },
				Parent = headerBtn,
			})
		end
	end

	-- Grouped iOS Settings Card container
	local card = Creator.new("Frame", {
		Name = "GroupCard",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		Visible = not collapsed,
		LayoutOrder = 2,
		ZIndex = 2,
		ThemeBind = { BackgroundColor3 = "SectionBg" },
		Parent = root,
	}, {
		Creator.corner(10),
		Creator.stroke("Border", 1, 0.2),
		Creator.padding(4, 4, 4, 4),
		Creator.list(2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	if collapsible and headerBtn then
		headerBtn.Activated:Connect(function()
			collapsed = not collapsed
			card.Visible = not collapsed
			if chevronImg then
				Animator.tween(chevronImg, { Rotation = collapsed and -90 or 0 }, 0.16)
			end
		end)
	end

	local self = setmetatable({
		Title = title,
		Tab = tab,
		Window = tab.Window,
		Root = root,
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
