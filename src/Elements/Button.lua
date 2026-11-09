local Creator = require("Core/Creator")
local Signal = require("Core/Signal")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")

local Button = {}

function Button.create(section, opts)
	opts = opts or {}
	local style = opts.Style or "Secondary" -- "Primary" | "Secondary" | "Destructive"
	local title = tostring(opts.Title or opts.ButtonText or "Button")
	local confirmRequired = opts.Confirm == true

	local bgToken = "RowBg"
	local hoverToken = "RowHover"
	local textToken = "Text"
	if style == "Primary" then
		bgToken = "Accent"
		hoverToken = "AccentHover"
		textToken = "OnAccent"
	elseif style == "Destructive" then
		bgToken = "Error"
		hoverToken = "Error"
		textToken = "OnAccent"
	end

	local btn = Creator.new("TextButton", {
		Name = "Row_" .. title,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 4,
		ThemeBind = { BackgroundColor3 = bgToken },
		Parent = section.Container,
	}, {
		Creator.corner(10),
		Creator.stroke("Outline", 1, 0),
		Creator.new("UIScale", { Scale = 1 }),
	})

	local titleLabel = Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 14,
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 5,
		ThemeBind = { TextColor3 = textToken },
		Parent = btn,
	})

	local scaleInst = btn:FindFirstChildOfClass("UIScale")
	local awaitingConfirm = false
	local confirmResetThread = nil
	local running = false
	local locked = false

	btn.MouseEnter:Connect(function()
		if not awaitingConfirm then
			Animator.tween(btn, { BackgroundColor3 = ThemeManager:Get(hoverToken) }, 0.12)
		end
	end)

	btn.MouseLeave:Connect(function()
		if not awaitingConfirm then
			Animator.tween(btn, { BackgroundColor3 = ThemeManager:Get(bgToken) }, 0.14)
		end
	end)

	local function resetConfirm()
		awaitingConfirm = false
		if confirmResetThread then
			pcall(task.cancel, confirmResetThread)
			confirmResetThread = nil
		end
		titleLabel.Text = title
		Animator.tween(btn, { BackgroundColor3 = ThemeManager:Get(bgToken) }, 0.16)
	end

	local control = {
		Kind = "Button",
		Row = btn,
		TitleLabel = titleLabel,
		Section = section,
		Window = section.Window,
		Title = title,
		Changed = Signal.new(),
		IsLocked = function()
			return locked
		end,
		Lock = function()
			locked = true
		end,
		Unlock = function()
			locked = false
		end,
		Highlight = function()
			Animator.pulseHighlight(btn)
		end,
		SetTitle = function(self, newTitle)
			self.Title = tostring(newTitle or "")
			title = self.Title
			titleLabel.Text = title
		end,
		SetButtonText = function(self, newTitle)
			self:SetTitle(newTitle)
		end,
		SetVisible = function(_, v)
			btn.Visible = v == true
		end,
		OnChanged = function(self, fn)
			return self.Changed:Connect(fn)
		end,
		Destroy = function(self)
			self.Changed:Destroy()
			if btn and btn.Parent then
				btn:Destroy()
			end
		end,
	}

	local function trigger()
		if locked or running then
			return
		end
		if confirmRequired and not awaitingConfirm then
			awaitingConfirm = true
			titleLabel.Text = "Confirm: " .. title
			Animator.tween(btn, { BackgroundColor3 = ThemeManager:Get("Warning") }, 0.14)
			confirmResetThread = task.delay(2.5, resetConfirm)
			return
		end
		if awaitingConfirm then
			resetConfirm()
		end

		if scaleInst then
			Animator.spring(scaleInst, "Scale", 0.97, { frequency = 24, damping = 0.8 })
			task.delay(0.08, function()
				if scaleInst.Parent then
					Animator.spring(scaleInst, "Scale", 1, { frequency = 18, damping = 0.78 })
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

	btn.Activated:Connect(trigger)
	control.Fire = trigger

	if section.Window and section.Window._registerSearchable then
		section.Window:_registerSearchable(control, section)
	end

	return control
end

return Button
