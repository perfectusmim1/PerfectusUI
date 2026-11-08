local Services = require("Core/Services")
local Env = require("Core/Env")
local Creator = require("Core/Creator")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local MobileToggle = {}

function MobileToggle.create(window, opts)
	opts = opts or {}
	if not Env.IsMobile and not opts.ForceMobileButton then
		return nil
	end

	local btn = Creator.new("TextButton", {
		Name = "MobileToggleBtn",
		Position = UDim2.new(0, 14, 0.5, -22),
		Size = UDim2.fromOffset(44, 44),
		Text = "",
		ZIndex = 250,
		ThemeBind = { BackgroundColor3 = "TitleBarBg" },
		Parent = window.ScreenGui,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("Accent", 1.5, 0.2),
		Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(20, 20),
			Image = Icons.resolve(opts.Icon or "sparkles") or "",
			ZIndex = 251,
			ThemeBind = { ImageColor3 = "Accent" },
		}),
	})

	Shadow.create(btn, 14, 0.4, 249)

	local dragging = false
	local moved = false
	local startInput = Vector2.zero
	local startPos = btn.Position

	btn.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			dragging = true
			moved = false
			startInput = Vector2.new(input.Position.X, input.Position.Y)
			startPos = btn.Position
		end
	end)

	window.Maid:Add(Services.UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseMovement
		then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - startInput
			if delta.Magnitude > 6 then
				moved = true
			end
			btn.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))

	window.Maid:Add(Services.UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			if dragging and not moved then
				window:ToggleVisibility()
			end
			dragging = false
		end
	end))

	return btn
end

return MobileToggle
