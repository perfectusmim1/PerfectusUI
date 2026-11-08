local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local RowBase = require("Components/RowBase")

local Button = {}

function Button.create(section, opts)
	opts = opts or {}
	local style = opts.Style or "Secondary" -- "Primary" | "Secondary" | "Destructive"
	local buttonLabel = opts.ButtonText or (style == "Destructive" and "Run" or "Execute")
	local confirmRequired = opts.Confirm == true

	local control = RowBase.create(section, {
		Title = opts.Title or "Button",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		RightWidth = 104,
		Clickable = true,
		TitleColorToken = style == "Destructive" and "Error" or "Text",
		IconColorToken = style == "Destructive" and "Error" or "TextSecondary",
	})
	control.Kind = "Button"

	local bgToken = "ControlBg"
	local textToken = "Text"
	if style == "Primary" then
		bgToken = "Accent"
		textToken = "OnAccent"
	elseif style == "Destructive" then
		bgToken = "Error"
		textToken = "OnAccent"
	end

	local actionPill = Creator.new("Frame", {
		Name = "ActionPill",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(88, 26),
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = bgToken },
		Parent = control.RightSlot,
	}, {
		Creator.corner(7),
		Creator.stroke("Border", 1, style == "Secondary" and 0.25 or 0.7),
		Creator.new("UIScale", { Scale = 1 }),
	})

	local pillLabel = Creator.new("TextLabel", {
		Name = "PillText",
		Size = UDim2.new(1, -22, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 12,
		Text = buttonLabel,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 7,
		ThemeBind = { TextColor3 = textToken },
		Parent = actionPill,
	})

	local chevron = Creator.new("ImageLabel", {
		Name = "Arrow",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		Image = Icons.resolve(opts.ActionIcon or "chevron-right") or "",
		ZIndex = 7,
		ThemeBind = { ImageColor3 = textToken },
		Parent = actionPill,
	})

	local scaleInst = actionPill:FindFirstChildOfClass("UIScale")
	local awaitingConfirm = false
	local confirmResetThread = nil
	local running = false

	local function resetConfirm()
		awaitingConfirm = false
		if confirmResetThread then
			pcall(task.cancel, confirmResetThread)
			confirmResetThread = nil
		end
		pillLabel.Text = buttonLabel
		Animator.tween(actionPill, { BackgroundColor3 = ThemeManager:Get(bgToken) }, 0.16)
	end

	local function trigger()
		if control:IsLocked() or running then
			return
		end
		if confirmRequired and not awaitingConfirm then
			awaitingConfirm = true
			pillLabel.Text = "Confirm?"
			Animator.tween(actionPill, { BackgroundColor3 = ThemeManager:Get("Warning") }, 0.14)
			confirmResetThread = task.delay(2.5, resetConfirm)
			return
		end
		if awaitingConfirm then
			resetConfirm()
		end

		if scaleInst then
			Animator.spring(scaleInst, "Scale", 0.94, { frequency = 22, damping = 0.8 })
			task.delay(0.09, function()
				if scaleInst.Parent then
					Animator.spring(scaleInst, "Scale", 1, { frequency = 16, damping = 0.78 })
				end
			end)
		end

		control.Changed:Fire()
		if type(opts.Callback) == "function" then
			running = true
			task.spawn(function()
				Util.safeCall(control.Title, opts.Callback, control.Window and control.Window._notifyError)
				running = false
			end)
		end
	end

	control.Row.Activated:Connect(trigger)

	function control:Fire()
		trigger()
	end

	function control:SetButtonText(text)
		buttonLabel = tostring(text or "Execute")
		if not awaitingConfirm then
			pillLabel.Text = buttonLabel
		end
	end

	return control
end

return Button
