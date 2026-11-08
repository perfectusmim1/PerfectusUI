local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Animator = require("Motion/Animator")
local Shadow = require("Components/Shadow")

local Popover = {}

local activePopover = nil
local rootContainer = nil
local scaleRef = nil
local backdropBtn = nil

function Popover.init(overlayParent, uiScaleInstance)
	rootContainer = overlayParent
	scaleRef = uiScaleInstance

	if backdropBtn then
		backdropBtn:Destroy()
	end

	backdropBtn = Creator.new("TextButton", {
		Name = "PopoverBackdrop",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Visible = false,
		ZIndex = 190,
		Modal = false,
		Parent = rootContainer,
	})

	backdropBtn.MouseButton1Down:Connect(function()
		Popover.close()
	end)
end

function Popover.isOpen()
	return activePopover ~= nil
end

function Popover.close()
	if not activePopover then
		return
	end
	local current = activePopover
	activePopover = nil
	if backdropBtn then
		backdropBtn.Visible = false
	end
	if current.onClose then
		pcall(current.onClose)
	end
	if current.frame and current.frame.Parent then
		local f = current.frame
		Animator.tween(
			f,
			{ BackgroundTransparency = 1 },
			0.12,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			function()
				if f.Parent then
					f:Destroy()
				end
			end
		)
		for _, d in ipairs(f:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
				Animator.tween(d, { TextTransparency = 1 }, 0.1)
			elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
				Animator.tween(d, { ImageTransparency = 1 }, 0.1)
			elseif d:IsA("UIStroke") then
				Animator.tween(d, { Transparency = 1 }, 0.1)
			end
		end
	end
end

function Popover.open(opts)
	opts = opts or {}
	Popover.close()

	if not rootContainer then
		return nil
	end

	local width = opts.Width or 210
	local targetHeight = opts.Height or 180
	local anchor = opts.Anchor
	local scale = (scaleRef and scaleRef.Scale and scaleRef.Scale > 0) and scaleRef.Scale or 1

	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local xPos = 200
	local yPos = 200
	local openUpward = false

	if opts.Position then
		xPos = opts.Position.X / scale
		yPos = opts.Position.Y / scale
	elseif anchor and anchor.Parent then
		local absPos = anchor.AbsolutePosition
		local absSize = anchor.AbsoluteSize
		local rootAbsPos = rootContainer.AbsolutePosition
		local relX = (absPos.X - rootAbsPos.X) / scale
		local relY = (absPos.Y - rootAbsPos.Y) / scale
		local anchorW = absSize.X / scale
		local anchorH = absSize.Y / scale
		local maxVpX = vp.X / scale
		local maxVpY = vp.Y / scale

		xPos = math.clamp(relX + anchorW - width, 8, math.max(8, maxVpX - width - 8))
		if relY + anchorH + targetHeight + 12 > maxVpY and (relY - targetHeight - 6) > 8 then
			yPos = relY - targetHeight - 6
			openUpward = true
		else
			yPos = relY + anchorH + 6
		end
	end

	if backdropBtn then
		backdropBtn.Visible = true
	end

	local card = Creator.new("Frame", {
		Name = opts.Name or "PopoverCard",
		Position = UDim2.fromOffset(math.floor(xPos), math.floor(openUpward and (yPos + 10) or math.max(8, yPos - 6))),
		Size = UDim2.fromOffset(width, targetHeight),
		BackgroundTransparency = 0.04,
		ClipsDescendants = false,
		ZIndex = 200,
		ThemeBind = { BackgroundColor3 = "PopoverBg" },
		Parent = rootContainer,
	}, {
		Creator.corner(10),
		Creator.stroke("InnerStroke", 1, 0.25),
	})

	Shadow.create(card, 20, 0.45, 199)

	local inner = Creator.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 201,
		Parent = card,
	}, {
		Creator.corner(10),
	})

	Animator.spring(card, "Position", UDim2.fromOffset(math.floor(xPos), math.floor(yPos)), {
		frequency = 18,
		damping = 0.86,
	})

	local handle = {
		frame = card,
		content = inner,
		onClose = opts.OnClose,
		SetHeight = function(_, newHeight)
			targetHeight = newHeight
			Animator.spring(card, "Size", UDim2.fromOffset(width, newHeight), {
				frequency = 18,
				damping = 0.88,
			})
		end,
		Close = function()
			Popover.close()
		end,
	}

	activePopover = handle
	return handle
end

Services.UserInputService.InputBegan:Connect(function(input, processed)
	if not activePopover then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape then
		Popover.close()
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local f = activePopover.frame
		if f and f.Parent then
			local pos = input.Position
			local absPos = f.AbsolutePosition
			local absSize = f.AbsoluteSize
			local inside = pos.X >= absPos.X
				and pos.X <= (absPos.X + absSize.X)
				and pos.Y >= absPos.Y
				and pos.Y <= (absPos.Y + absSize.Y)
			if not inside and not processed then
				Popover.close()
			end
		end
	end
end)

return Popover
