local RowBase = require("Components/RowBase")

local Label = {}

function Label.create(section, opts)
	if type(opts) == "string" then
		opts = { Title = opts }
	end
	opts = opts or {}

	local control = RowBase.create(section, {
		Title = opts.Title or opts.Text or "Label",
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		RightWidth = 0,
		MinHeight = 34,
		TitleColorToken = opts.ColorToken or "TextSecondary",
		Clickable = false,
	})
	control.Kind = "Label"

	function control:Get()
		return self.Title
	end

	function control:Set(newText)
		self:SetTitle(newText)
		self.Changed:Fire(self.Title)
	end

	return control
end

return Label
