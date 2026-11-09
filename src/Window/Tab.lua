local Util = require("Core/Util")
local Scroll = require("Components/Scroll")
local Popover = require("Components/Popover")
local Section = require("Window/Section")

local Tab = {}
Tab.__index = Tab

function Tab.new(window, opts)
	if type(opts) == "string" then
		opts = { Title = opts }
	end
	opts = opts or {}

	local title = tostring(opts.Title or opts.Name or "Tab")
	local icon = opts.Icon or "layers"
	local badge = opts.Badge

	local scroll = Scroll.create({
		Name = "Page_" .. title,
		Parent = window.PagesContainer,
		Visible = false,
		Spacing = 10,
		Padding = { Top = 0, Right = 2, Bottom = 12, Left = 0 },
	})

	scroll.Scrolled:Connect(function()
		Popover.close()
	end)

	local self = setmetatable({
		Title = title,
		Icon = icon,
		Window = window,
		Scroll = scroll,
		Page = scroll.Frame,
		Sections = {},
		_sectionOrder = 0,
		_defaultSection = nil,
	}, Tab)

	function self:ApplyFilter(rawQuery)
		local q = tostring(rawQuery or ""):gsub("^%s*(.-)%s*$", "%1")
		for _, sec in ipairs(self.Sections) do
			local anyVisible = false
			for _, child in ipairs(sec.Container:GetChildren()) do
				if child:IsA("GuiObject") and child.Name ~= "CardTitleRow" then
					if q == "" then
						child.Visible = true
						anyVisible = true
					else
						local score = Util.fuzzyScore(q, child.Name)
						if not score then
							local t = child:FindFirstChild("Title", true)
							if t and t:IsA("TextLabel") then
								score = Util.fuzzyScore(q, t.Text)
							end
						end
						local show = score ~= nil
						child.Visible = show
						if show then
							anyVisible = true
						end
					end
				end
			end
			sec.Root.Visible = (q == "") or anyVisible
		end
	end

	self.SidebarEntry = window.Sidebar:AddTabButton(self, icon, badge)
	return self
end

function Tab:_nextSectionOrder()
	self._sectionOrder += 1
	return self._sectionOrder
end

function Tab:Section(opts)
	local sec = Section.new(self, opts)
	self.Sections[#self.Sections + 1] = sec
	return sec
end
Tab.AddSection = Tab.Section
Tab.CreateSection = Tab.Section

function Tab:_ensureDefaultSection()
	if not self._defaultSection then
		self._defaultSection = self:Section({ Title = "" })
	end
	return self._defaultSection
end

local forwarded = {
	"Button",
	"Toggle",
	"Checkbox",
	"Slider",
	"RangeSlider",
	"Dropdown",
	"Input",
	"Keybind",
	"ColorPicker",
	"Segmented",
	"Stepper",
	"RadioGroup",
	"ProgressBar",
	"Stat",
	"Label",
	"Paragraph",
	"Divider",
	"Image",
	"CodeBlock",
}
for _, method in ipairs(forwarded) do
	Tab[method] = function(self, opts)
		return self:_ensureDefaultSection()[method](self:_ensureDefaultSection(), opts)
	end
end

function Tab:Select()
	self.Window:SelectTab(self)
end

return Tab
