local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")

local Tooltip = {}
Tooltip.__index = Tooltip

function Tooltip.new(screenGui)
	local pill = Creator.new("Frame", {
		Name = "TooltipCard",
		Size = UDim2.fromOffset(120, 28),
		BackgroundTransparency = 0,
		Visible = false,
		ZIndex = 300,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = screenGui,
	}, {
		Creator.corner(8),
		Creator.stroke("Outline", 2, 0),
		Creator.padding(4, 10, 4, 10),
	})

	local label = Creator.new("TextLabel", {
		Name = "Text",
		Size = UDim2.new(1, 0, 1, 0),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 13,
		Text = "",
		ZIndex = 301,
		ThemeBind = { TextColor3 = "Text" },
		Parent = pill,
	})

	return setmetatable({
		Frame = pill,
		Label = label,
		_hoverThread = nil,
	}, Tooltip)
end

function Tooltip:Bind(guiObj, textOrProvider)
	if textOrProvider == nil then
		return
	end

	guiObj.MouseEnter:Connect(function()
		if self._hoverThread then
			pcall(task.cancel, self._hoverThread)
		end
		self._hoverThread = task.delay(0.45, function()
			local text = nil
			if type(textOrProvider) == "function" then
				local ok, res = pcall(textOrProvider)
				if ok and type(res) == "string" then
					text = res
				end
			elseif type(textOrProvider) == "string" then
				text = textOrProvider
			end

			if not text or text == "" then
				self.Frame.Visible = false
				return
			end

			local bounds = Util.measureText(text, 13, Enum.Font.BuilderSansBold, 260)
			local w = math.clamp(math.ceil(bounds.X) + 22, 48, 280)
			local h = math.max(26, math.ceil(bounds.Y) + 10)
			self.Label.Text = text
			self.Frame.Size = UDim2.fromOffset(w, h)

			local mPos = Services.UserInputService:GetMouseLocation()
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			local x = math.clamp(mPos.X + 12, 8, vp.X - w - 8)
			local y = math.clamp(mPos.Y - 18, 8, vp.Y - h - 8)
			self.Frame.Position = UDim2.fromOffset(x, y)
			self.Frame.Visible = true
		end)
	end)

	guiObj.MouseLeave:Connect(function()
		if self._hoverThread then
			pcall(task.cancel, self._hoverThread)
			self._hoverThread = nil
		end
		self.Frame.Visible = false
	end)
end

return Tooltip
