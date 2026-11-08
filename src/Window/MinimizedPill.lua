local Creator = require("Core/Creator")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local MinimizedPill = {}

function MinimizedPill.create(window, opts)
	opts = opts or {}

	local pill = Creator.new("TextButton", {
		Name = "DynamicIslandPill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -48),
		Size = UDim2.fromOffset(186, 34),
		BackgroundTransparency = 0.04,
		Visible = false,
		Text = "",
		ZIndex = 180,
		ThemeBind = { BackgroundColor3 = "TitleBarBg" },
		Parent = window.ScreenGui,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("InnerStroke", 1, 0.25),
		Creator.new("UIScale", { Scale = 1 }),
	})

	Shadow.create(pill, 18, 0.45, 179)

	Creator.new("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(15, 15),
		Image = Icons.resolve(opts.Icon or "sparkles") or "",
		ZIndex = 181,
		ThemeBind = { ImageColor3 = "Accent" },
		Parent = pill,
	})

	local label = Creator.new("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(33, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 13,
		Text = tostring(opts.Title or "Perfectus"),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 181,
		ThemeBind = { TextColor3 = "Text" },
		Parent = pill,
	})

	Creator.new("ImageLabel", {
		Name = "ExpandIcon",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = Icons.resolve("maximize-2") or "",
		ZIndex = 181,
		ThemeBind = { ImageColor3 = "TextSecondary" },
		Parent = pill,
	})

	Creator.bindInteractive(pill, {
		NormalToken = "TitleBarBg",
		HoverToken = "RowHover",
		PressScale = 0.96,
	})

	pill.Activated:Connect(function()
		window:MinimizeToPill(false)
	end)

	return {
		Frame = pill,
		Show = function()
			pill.Visible = true
			Animator.spring(pill, "Position", UDim2.new(0.5, 0, 0, 12), { frequency = 16, damping = 0.82 })
		end,
		Hide = function()
			Animator.spring(pill, "Position", UDim2.new(0.5, 0, 0, -48), {
				frequency = 18,
				damping = 0.88,
				onComplete = function()
					pill.Visible = false
				end,
			})
		end,
		SetTitle = function(_, t)
			label.Text = tostring(t or "Perfectus")
		end,
	}
end

return MinimizedPill
