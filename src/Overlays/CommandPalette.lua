local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local CommandPalette = {}
CommandPalette.__index = CommandPalette

function CommandPalette.new(window)
	local backdrop = Creator.new("TextButton", {
		Name = "SpotlightBackdrop",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Visible = false,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 220,
		Parent = window.OverlayLayer,
	}, {
		Creator.corner(14),
	})

	local panel = Creator.new("Frame", {
		Name = "SpotlightPanel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 46),
		Size = UDim2.fromOffset(390, 260),
		ZIndex = 221,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = backdrop,
	}, {
		Creator.corner(11),
		Creator.stroke("InnerStroke", 1, 0.2),
		Creator.new("UIScale", { Scale = 0.95 }),
	})

	Shadow.create(panel, 22, 0.42, 220)

	local searchHeader = Creator.new("Frame", {
		Name = "SearchBar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 222,
		Parent = panel,
	}, {
		Creator.new("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 222,
			ThemeBind = { BackgroundColor3 = "Border" },
		}),
		Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.fromOffset(15, 15),
			Image = Icons.resolve("search") or "",
			ZIndex = 223,
			ThemeBind = { ImageColor3 = "Accent" },
		}),
	})

	local searchBox = Creator.new("TextBox", {
		Name = "Input",
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -84, 1, 0),
		Font = Enum.Font.BuilderSans,
		TextSize = 14,
		PlaceholderText = "Search controls, tabs, or actions...",
		ClearTextOnFocus = false,
		ZIndex = 223,
		ThemeBind = {
			TextColor3 = "Text",
			PlaceholderColor3 = "TextMuted",
		},
		Parent = searchHeader,
	})

	Creator.new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(34, 18),
		Font = Enum.Font.RobotoMono,
		TextSize = 10,
		Text = "ESC",
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 223,
		ThemeBind = {
			BackgroundColor3 = "ControlBg",
			TextColor3 = "TextMuted",
		},
		Parent = searchHeader,
	}, {
		Creator.corner(4),
	})

	local resultsScroll = Creator.new("ScrollingFrame", {
		Name = "Results",
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, 0, 1, -44),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ZIndex = 222,
		Parent = panel,
	}, {
		Creator.padding(6, 8, 8, 8),
		Creator.list(4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local self = setmetatable({
		Window = window,
		Backdrop = backdrop,
		Panel = panel,
		SearchBox = searchBox,
		ResultsScroll = resultsScroll,
		Scale = panel:FindFirstChildOfClass("UIScale"),
		Entries = {},
		ResultButtons = {},
		IsOpen = false,
	}, CommandPalette)

	backdrop.Activated:Connect(function()
		self:Hide()
	end)

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if self.IsOpen then
			self:_renderResults(searchBox.Text)
		end
	end)

	searchBox.FocusLost:Connect(function(enterPressed)
		if enterPressed and self._topAction then
			self._topAction()
		end
	end)

	return self
end

function CommandPalette:Register(control, section)
	self.Entries[#self.Entries + 1] = {
		Control = control,
		Section = section,
		Tab = section.Tab,
	}
end

function CommandPalette:_renderResults(query)
	for _, b in ipairs(self.ResultButtons) do
		b:Destroy()
	end
	table.clear(self.ResultButtons)
	self._topAction = nil

	local scored = {}
	for _, item in ipairs(self.Entries) do
		local ctrl = item.Control
		if ctrl and ctrl.Row and ctrl.Row.Parent then
			local label = string.format(
				"%s › %s › %s",
				tostring(item.Tab.Title),
				tostring(item.Section.Title),
				tostring(ctrl.Title)
			)
			local s = Util.fuzzyScore(query, label) or Util.fuzzyScore(query, ctrl.Title)
			if s then
				scored[#scored + 1] = { item = item, score = s }
			end
		end
	end

	table.sort(scored, function(a, b)
		return a.score > b.score
	end)

	local count = math.min(#scored, 20)
	for i = 1, count do
		local entry = scored[i].item
		local ctrl = entry.Control
		local rowBtn = Creator.new("TextButton", {
			Name = "Result_" .. i,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = i == 1 and 0.86 or 1,
			LayoutOrder = i,
			ZIndex = 223,
			ThemeBind = { BackgroundColor3 = "Accent" },
			Parent = self.ResultsScroll,
		}, {
			Creator.corner(7),
			Creator.padding(0, 10, 0, 10),
		})

		Creator.new("TextLabel", {
			Size = UDim2.new(1, -90, 0, 18),
			Position = UDim2.fromOffset(0, 2),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 13,
			Text = tostring(ctrl.Title),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 224,
			ThemeBind = { TextColor3 = "Text" },
			Parent = rowBtn,
		})

		Creator.new("TextLabel", {
			Size = UDim2.new(1, -90, 0, 14),
			Position = UDim2.fromOffset(0, 18),
			Font = Enum.Font.BuilderSans,
			TextSize = 11,
			Text = string.format(
				"%s  •  %s",
				tostring(entry.Tab.Title),
				tostring(entry.Section.Title ~= "" and entry.Section.Title or "General")
			),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 224,
			ThemeBind = { TextColor3 = "TextMuted" },
			Parent = rowBtn,
		})

		Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(74, 20),
			Font = Enum.Font.RobotoMono,
			TextSize = 10,
			Text = tostring(ctrl.Kind or "Control"),
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 224,
			ThemeBind = { TextColor3 = "TextSecondary" },
			Parent = rowBtn,
		})

		local function activateResult()
			self:Hide()
			self.Window:SelectTab(entry.Tab)
			task.defer(function()
				if ctrl.Highlight then
					ctrl:Highlight()
				end
			end)
		end

		if i == 1 then
			self._topAction = activateResult
		end

		rowBtn.Activated:Connect(activateResult)
		rowBtn.MouseEnter:Connect(function()
			rowBtn.BackgroundTransparency = 0.85
		end)
		rowBtn.MouseLeave:Connect(function()
			rowBtn.BackgroundTransparency = i == 1 and 0.86 or 1
		end)

		self.ResultButtons[#self.ResultButtons + 1] = rowBtn
	end
end

function CommandPalette:Show()
	self.IsOpen = true
	self.Backdrop.Visible = true
	self.SearchBox.Text = ""
	self:_renderResults("")
	if self.Scale then
		self.Scale.Scale = 0.94
		Animator.spring(self.Scale, "Scale", 1, { frequency = 18, damping = 0.84 })
	end
	task.defer(function()
		if self.SearchBox.Parent then
			self.SearchBox:CaptureFocus()
		end
	end)
end

function CommandPalette:Hide()
	if not self.IsOpen then
		return
	end
	self.IsOpen = false
	self.Backdrop.Visible = false
end

function CommandPalette:Toggle()
	if self.IsOpen then
		self:Hide()
	else
		self:Show()
	end
end

return CommandPalette
