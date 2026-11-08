local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local Icons = require("Assets/Icons")
local Shadow = require("Components/Shadow")

local Watermark = {}
Watermark.__index = Watermark

function Watermark.new(window, opts)
	opts = opts or {}
	local title = tostring(opts.Title or "Perfectus UI")
	local visible = opts.Visible == true

	local pill = Creator.new("Frame", {
		Name = "WatermarkHUD",
		Position = UDim2.fromOffset(18, 58),
		Size = UDim2.fromOffset(250, 28),
		BackgroundTransparency = 0.06,
		Visible = visible,
		ZIndex = 170,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = window.ScreenGui,
	}, {
		Creator.corner(UDim.new(1, 0)),
		Creator.stroke("InnerStroke", 1, 0.25),
	})

	Shadow.create(pill, 14, 0.45, 169)

	local content = Creator.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 171,
		Parent = pill,
	}, {
		Creator.padding(0, 12, 0, 12),
		Creator.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
	})

	Creator.new("ImageLabel", {
		Size = UDim2.fromOffset(14, 14),
		Image = Icons.resolve(opts.Icon or "sparkles") or "",
		LayoutOrder = 1,
		ZIndex = 172,
		ThemeBind = { ImageColor3 = "Accent" },
		Parent = content,
	})

	local textLabel = Creator.new("TextLabel", {
		Size = UDim2.new(1, -22, 1, 0),
		Font = Enum.Font.RobotoMono,
		TextSize = 11,
		Text = title .. "  •  60 FPS  •  0 ms",
		LayoutOrder = 2,
		ZIndex = 172,
		ThemeBind = { TextColor3 = "Text" },
		Parent = content,
	})

	-- Draggable
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = pill.Position
	pill.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(inp.Position.X, inp.Position.Y)
			startPos = pill.Position
		end
	end)
	window.Maid:Add(Services.UserInputService.InputChanged:Connect(function(inp)
		if
			dragging
			and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch)
		then
			local d = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
			pill.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
	window.Maid:Add(Services.UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	local self = setmetatable({
		Frame = pill,
		Label = textLabel,
		Title = title,
		_loopThread = nil,
	}, Watermark)

	function self:_updateText(str)
		self.Label.Text = str
		local bounds = Util.measureText(str, 11, Enum.Font.RobotoMono, 1000)
		self.Frame.Size = UDim2.fromOffset(math.ceil(bounds.X) + 48, 28)
	end

	self:_updateText(title .. "  •  60 FPS  •  0 ms")

	if visible then
		self:_startLoop()
	end

	return self
end

function Watermark:_startLoop()
	if self._loopThread then
		return
	end
	self._loopThread = task.spawn(function()
		while self.Frame.Parent and self.Frame.Visible do
			local dt = Services.RunService.RenderStepped:Wait()
			local fps = math.clamp(math.floor(1 / math.max(0.001, dt) + 0.5), 1, 999)
			local ping = 0
			pcall(function()
				ping = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
			end)
			local clockStr = os.date("%H:%M:%S")
			self:_updateText(string.format("%s  •  %d FPS  •  %d ms  •  %s", self.Title, fps, ping, clockStr))
			task.wait(0.5)
		end
		self._loopThread = nil
	end)
end

function Watermark:SetVisible(vis)
	self.Frame.Visible = vis == true
	if vis then
		self:_startLoop()
	end
end

function Watermark:IsVisible()
	return self.Frame.Visible
end

function Watermark:SetTitle(newTitle)
	self.Title = tostring(newTitle or "Perfectus UI")
end

return Watermark
