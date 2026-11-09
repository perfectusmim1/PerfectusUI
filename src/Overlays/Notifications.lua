local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local Notifications = {}
Notifications.__index = Notifications

local TYPE_CONFIG = {
	Info = { Icon = "info", Token = "Info" },
	Success = { Icon = "check-circle-2", Token = "Success" },
	Warning = { Icon = "alert-triangle", Token = "Warning" },
	Error = { Icon = "alert-circle", Token = "Error" },
}

function Notifications.new(screenGui)
	local holder = Creator.new("Frame", {
		Name = "NotificationsHost",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -18),
		Size = UDim2.fromOffset(296, 420),
		BackgroundTransparency = 1,
		ZIndex = 260,
		Parent = screenGui,
	}, {
		Creator.list(8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom),
	})

	return setmetatable({
		Holder = holder,
		Active = {},
		Corner = "BottomRight",
	}, Notifications)
end

function Notifications:SetPosition(corner)
	self.Corner = corner or "BottomRight"
	local layout = self.Holder:FindFirstChildOfClass("UIListLayout")
	if self.Corner == "TopRight" then
		self.Holder.AnchorPoint = Vector2.new(1, 0)
		self.Holder.Position = UDim2.new(1, -18, 0, 18)
		if layout then
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			layout.VerticalAlignment = Enum.VerticalAlignment.Top
		end
	elseif self.Corner == "BottomLeft" then
		self.Holder.AnchorPoint = Vector2.new(0, 1)
		self.Holder.Position = UDim2.new(0, 18, 1, -18)
		if layout then
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		end
	else
		self.Holder.AnchorPoint = Vector2.new(1, 1)
		self.Holder.Position = UDim2.new(1, -18, 1, -18)
		if layout then
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		end
	end
end

function Notifications:Notify(opts)
	if type(opts) == "string" then
		opts = { Title = "Notification", Content = opts }
	end
	opts = opts or {}

	local kind = opts.Type or "Info"
	local cfg = TYPE_CONFIG[kind] or TYPE_CONFIG.Info
	local duration = tonumber(opts.Duration) or 4
	local title = tostring(opts.Title or "Notification")
	local content = tostring(opts.Content or opts.Text or "")

	while #self.Active >= 5 do
		local oldest = table.remove(self.Active, 1)
		if oldest and oldest.Dismiss then
			oldest.Dismiss()
		end
	end

	local bodyBounds = content ~= "" and Util.measureText(content, 12, Enum.Font.BuilderSans, 240) or Vector2.zero
	local cardHeight = math.max(52, 34 + (content ~= "" and (math.ceil(bodyBounds.Y) + 8) or 0))

	local wrapper = Creator.new("Frame", {
		Name = "ToastWrapper",
		Size = UDim2.new(1, 0, 0, cardHeight),
		BackgroundTransparency = 1,
		ZIndex = 261,
		Parent = self.Holder,
	})

	local card = Creator.new("TextButton", {
		Name = "ToastCard",
		Position = UDim2.fromOffset(self.Corner == "BottomLeft" and -40 or 40, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 262,
		ThemeBind = { BackgroundColor3 = "RowBg" },
		Parent = wrapper,
	}, {
		Creator.corner(12),
		Creator.stroke("Outline", 1.2, 0),
	})

	Shadow.create(card, 16, 0.45, 261)

	local iconBox = Creator.new("Frame", {
		Name = "IconBox",
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(32, 32),
		ZIndex = 263,
		ThemeBind = { BackgroundColor3 = "SectionBg" },
		Parent = card,
	}, {
		Creator.corner(8),
		Creator.stroke("Outline", 1, 0),
	})

	Creator.new("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		Image = Icons.resolve(opts.Icon or cfg.Icon) or "",
		ZIndex = 264,
		ThemeBind = { ImageColor3 = cfg.Token },
		Parent = iconBox,
	})

	Creator.new("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(50, 9),
		Size = UDim2.new(1, -60, 0, 18),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 15,
		Text = title,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 264,
		ThemeBind = { TextColor3 = "Text" },
		Parent = card,
	})

	if content ~= "" then
		Creator.new("TextLabel", {
			Name = "Body",
			Position = UDim2.fromOffset(50, 27),
			Size = UDim2.new(1, -60, 0, math.ceil(bodyBounds.Y) + 2),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 12,
			Text = content,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 264,
			ThemeBind = { TextColor3 = "TextSecondary" },
			Parent = card,
		})
	end

	local progressTrack = Creator.new("Frame", {
		Name = "ProgressTrack",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -3),
		Size = UDim2.new(1, -20, 0, 2),
		ZIndex = 264,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = card,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	local progressFill = Creator.new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 265,
		ThemeBind = { BackgroundColor3 = cfg.Token },
		Parent = progressTrack,
	}, {
		Creator.corner(UDim.new(1, 0)),
	})

	Animator.spring(card, "Position", UDim2.fromOffset(0, 0), { frequency = 18, damping = 0.84 })

	local dismissed = false
	local paused = false
	local elapsed = 0
	local hbConn = nil

	local entry = {}
	function entry.Dismiss()
		if dismissed then
			return
		end
		dismissed = true
		if hbConn then
			hbConn:Disconnect()
			hbConn = nil
		end
		for i = #self.Active, 1, -1 do
			if self.Active[i] == entry then
				table.remove(self.Active, i)
				break
			end
		end
		if card.Parent then
			Animator.tween(
				card,
				{
					Position = UDim2.fromOffset(self.Corner == "BottomLeft" and -50 or 50, 0),
					BackgroundTransparency = 1,
				},
				0.16,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In,
				function()
					if wrapper.Parent then
						wrapper:Destroy()
					end
				end
			)
		end
	end

	card.MouseEnter:Connect(function()
		paused = true
	end)
	card.MouseLeave:Connect(function()
		paused = false
	end)
	card.Activated:Connect(function()
		entry.Dismiss()
	end)

	hbConn = Services.RunService.Heartbeat:Connect(function(dt)
		if dismissed or not wrapper.Parent then
			if hbConn then
				hbConn:Disconnect()
				hbConn = nil
			end
			return
		end
		if not paused then
			elapsed += dt
			local ratio = math.clamp(1 - (elapsed / duration), 0, 1)
			progressFill.Size = UDim2.fromScale(ratio, 1)
			if elapsed >= duration then
				entry.Dismiss()
			end
		end
	end)

	self.Active[#self.Active + 1] = entry
	return entry
end

return Notifications
