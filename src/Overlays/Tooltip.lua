local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local Animator = require("Motion/Animator")

local Tooltip = {}
Tooltip.__index = Tooltip

function Tooltip.new(screenGui)
	local pill = Creator.new("Frame", {
		Name = "TooltipCard",
		Size = UDim2.fromOffset(120, 26),
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 300,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = screenGui,
	}, {
		Creator.corner(6),
		Creator.stroke("InnerStroke", 1, 0.25),
		Creator.padding(4, 8, 4, 8),
	})

	local label = Creator.new("TextLabel", {
		Name = "Text",
		Size = UDim2.new(1, 0, 1, 0),
		Font = Enum.Font.BuilderSans,
		TextSize = 12,
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
	guiObj.MouseEnter:Connect(function()
		if self._hoverThread then
			pcall(task.cancel, self._hoverThread)
		end
		self._hoverThread = task.delay(0.45, function()
			local text = type(textOrProvider) == "function" and textOrProvider() or textOrProvider
			if not text or text == "" then
				return
			end
			local bounds = Util.measureText(text, 12, Enum.Font.BuilderSans, 260)
			local w = math.clamp(math.ceil(bounds.X) + 18, 48, 280)
			local h = math.max(24, math.ceil(bounds.Y) + 10)
			self.Label.Text = tostring(text)
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
