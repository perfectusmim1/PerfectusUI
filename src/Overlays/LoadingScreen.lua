local Creator = require("Core/Creator")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")

local LoadingScreen = {}

function LoadingScreen.play(window, opts)
	opts = opts or {}

	local cover = Creator.new("Frame", {
		Name = "LoadingOverlay",
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 240,
		ThemeBind = { BackgroundColor3 = "WindowBg" },
		Parent = window.OverlayLayer,
	}, {
		Creator.corner(14),
	})

	local center = Creator.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(240, 120),
		BackgroundTransparency = 1,
		ZIndex = 241,
		Parent = cover,
	}, {
		Creator.list(8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
	})

	Creator.new("ImageLabel", {
		Size = UDim2.fromOffset(32, 32),
		Image = Icons.resolve(opts.Icon or "sparkles") or "",
		LayoutOrder = 1,
		ZIndex = 242,
		ThemeBind = { ImageColor3 = "Accent" },
		Parent = center,
	})

	Creator.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 16,
		Text = tostring(opts.Title or "Perfectus UI"),
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		ZIndex = 242,
		ThemeBind = { TextColor3 = "Text" },
		Parent = center,
	})

	local sub = Creator.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		Font = Enum.Font.BuilderSans,
		TextSize = 12,
		Text = tostring(opts.Subtitle or "Initializing interface..."),
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 3,
		ZIndex = 242,
		ThemeBind = { TextColor3 = "TextMuted" },
		Parent = center,
	})

	local track = Creator.new("Frame", {
		Size = UDim2.fromOffset(160, 4),
		LayoutOrder = 4,
		ZIndex = 242,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = center,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local fill = Creator.new("Frame", {
		Size = UDim2.fromScale(0.08, 1),
		ZIndex = 243,
		ThemeBind = { BackgroundColor3 = "Accent" },
		Parent = track,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	task.spawn(function()
		Animator.spring(fill, "Size", UDim2.fromScale(1, 1), { frequency = 6, damping = 0.9 })
		task.wait(0.42)
		sub.Text = "Ready"
		task.wait(0.15)
		Animator.tween(
			cover,
			{ BackgroundTransparency = 1 },
			0.22,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out,
			function()
				if cover.Parent then
					cover:Destroy()
				end
			end
		)
		for _, d in ipairs(cover:GetDescendants()) do
			if d:IsA("TextLabel") then
				Animator.tween(d, { TextTransparency = 1 }, 0.18)
			elseif d:IsA("ImageLabel") then
				Animator.tween(d, { ImageTransparency = 1 }, 0.18)
			elseif d:IsA("Frame") then
				Animator.tween(d, { BackgroundTransparency = 1 }, 0.18)
			end
		end
	end)
end

return LoadingScreen
