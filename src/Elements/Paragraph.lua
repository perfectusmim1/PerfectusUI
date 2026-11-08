local RowBase = require("Components/RowBase")

local Paragraph = {}

function Paragraph.create(section, opts)
	opts = opts or {}
	local content = tostring(opts.Content or opts.Description or opts.Text or "")

	local control = RowBase.create(section, {
		Title = opts.Title or "Information",
		Description = content,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		RightWidth = 0,
		MinHeight = 48,
		Clickable = false,
	})
	control.Kind = "Paragraph"

	function control:Get()
		return content
	end

	function control:Set(val)
		if type(val) == "table" then
			if val.Title then
				self:SetTitle(val.Title)
			end
			content = tostring(val.Content or val.Description or val.Text or content)
			self:SetDescription(content)
		else
			content = tostring(val or "")
			self:SetDescription(content)
		end
		self.Changed:Fire(content)
	end

	function control:SetContent(text)
		self:Set(text)
	end

	return control
end

return Paragraph
