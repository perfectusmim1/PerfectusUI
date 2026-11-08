local Creator = require("Core/Creator")
local Util = require("Core/Util")
local Animator = require("Motion/Animator")
local Shadow = require("Components/Shadow")

local Dialog = {}

function Dialog.show(window, opts)
	opts = opts or {}
	local title = tostring(opts.Title or "Confirm Action")
	local content = tostring(opts.Content or opts.Text or "")
	local buttons = type(opts.Buttons) == "table" and #opts.Buttons > 0 and opts.Buttons
		or {
			{ Title = "Cancel", Style = "Secondary" },
			{ Title = "Confirm", Style = "Primary" },
		}

	local backdrop = Creator.new("TextButton", {
		Name = "DialogBackdrop",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 230,
		Parent = window.OverlayLayer,
	}, {
		Creator.corner(14),
	})

	local textBounds = content ~= "" and Util.measureText(content, 13, Enum.Font.BuilderSans, 288) or Vector2.zero
	local modalHeight = 96 + (content ~= "" and (math.ceil(textBounds.Y) + 12) or 0)

	local modal = Creator.new("Frame", {
		Name = "DialogModal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(320, modalHeight),
		ZIndex = 231,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = backdrop,
	}, {
		Creator.corner(12),
		Creator.stroke("InnerStroke", 1, 0.2),
		Creator.new("UIScale", { Scale = 0.92 }),
	})

	Shadow.create(modal, 24, 0.4, 230)

	local inner = Creator.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 232,
		Parent = modal,
	}, {
		Creator.padding(16, 16, 14, 16),
		Creator.list(10, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 15,
		Text = title,
		LayoutOrder = 1,
		ZIndex = 233,
		ThemeBind = { TextColor3 = "Text" },
		Parent = inner,
	})

	if content ~= "" then
		Creator.new("TextLabel", {
			Name = "Body",
			Size = UDim2.new(1, 0, 0, math.ceil(textBounds.Y) + 2),
			Font = Enum.Font.BuilderSans,
			TextSize = 13,
			Text = content,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 2,
			ZIndex = 233,
			ThemeBind = { TextColor3 = "TextSecondary" },
			Parent = inner,
		})
	end

	local btnRow = Creator.new("Frame", {
		Name = "Buttons",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		ZIndex = 233,
		Parent = inner,
	}, {
		Creator.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center),
	})

	local scaleInst = modal:FindFirstChildOfClass("UIScale")
	local closed = false

	local function closeDialog()
		if closed then
			return
		end
		closed = true
		if scaleInst then
			Animator.spring(scaleInst, "Scale", 0.92, { frequency = 20, damping = 0.88 })
		end
		Animator.tween(
			backdrop,
			{ BackgroundTransparency = 1 },
			0.14,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			function()
				if backdrop.Parent then
					backdrop:Destroy()
				end
			end
		)
	end

	for idx, bDef in ipairs(buttons) do
		local style = bDef.Style or (idx == #buttons and "Primary" or "Secondary")
		local bgToken = "ControlBg"
		local txtToken = "Text"
		if style == "Primary" then
			bgToken = "Accent"
			txtToken = "OnAccent"
		elseif style == "Destructive" then
			bgToken = "Error"
			txtToken = "OnAccent"
		end

		local btn = Creator.new("TextButton", {
			Name = "Btn_" .. tostring(bDef.Title or idx),
			Size = UDim2.fromOffset(88, 28),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 12,
			Text = tostring(bDef.Title or "OK"),
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = idx,
			ZIndex = 234,
			ThemeBind = {
				BackgroundColor3 = bgToken,
				TextColor3 = txtToken,
			},
			Parent = btnRow,
		}, {
			Creator.corner(7),
			Creator.stroke("Border", 1, style == "Secondary" and 0.3 or 0.7),
		})

		btn.Activated:Connect(function()
			closeDialog()
			if type(bDef.Callback) == "function" then
				task.spawn(Util.safeCall, title, bDef.Callback, window._notifyError)
			end
		end)
	end

	Animator.tween(backdrop, { BackgroundTransparency = 0.45 }, 0.16)
	if scaleInst then
		Animator.spring(scaleInst, "Scale", 1, { frequency = 18, damping = 0.82 })
	end

	return {
		Close = closeDialog,
	}
end

return Dialog
