local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")

local Creator = {}

local DEFAULT_RESET = {
	Frame = {
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(28, 28, 30),
	},
	CanvasGroup = {
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(28, 28, 30),
	},
	ScrollingFrame = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ScrollBarImageTransparency = 0.4,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	},
	TextLabel = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSans,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(245, 245, 247),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "",
	},
	TextButton = {
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(245, 245, 247),
		Text = "",
	},
	TextBox = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = Enum.Font.BuilderSans,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(245, 245, 247),
		PlaceholderColor3 = Color3.fromRGB(115, 115, 124),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	},
	ImageLabel = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ImageColor3 = Color3.fromRGB(245, 245, 247),
	},
	ImageButton = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		ImageColor3 = Color3.fromRGB(245, 245, 247),
	},
	UIStroke = {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Thickness = 1,
	},
}

function Creator.new(className, props, children)
	local inst = Instance.new(className)
	local defaults = DEFAULT_RESET[className]
	if defaults then
		for k, v in pairs(defaults) do
			pcall(function()
				inst[k] = v
			end)
		end
	end

	local themeBind = nil
	local parent = nil

	if type(props) == "table" then
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			elseif k == "ThemeBind" then
				themeBind = v
			elseif type(k) == "number" and typeof(v) == "Instance" then
				v.Parent = inst
			else
				inst[k] = v
			end
		end
	end

	if type(children) == "table" then
		for _, child in ipairs(children) do
			if typeof(child) == "Instance" then
				child.Parent = inst
			end
		end
	end

	if type(themeBind) == "table" then
		ThemeManager:Bind(inst, themeBind)
	end

	if parent then
		inst.Parent = parent
	end

	return inst
end

function Creator.corner(radius, parent)
	return Creator.new("UICorner", {
		CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 8),
		Parent = parent,
	})
end

function Creator.stroke(themeTokenOrColor, thickness, transparency, parent)
	local isToken = type(themeTokenOrColor) == "string"
	local bind = isToken and { Color = themeTokenOrColor } or nil
	local color = not isToken and themeTokenOrColor or ThemeManager:Get(themeTokenOrColor or "Border")
	return Creator.new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ThemeBind = bind,
		Parent = parent,
	})
end

function Creator.padding(top, right, bottom, left, parent)
	if type(top) == "number" and right == nil then
		right, bottom, left = top, top, top
	elseif type(top) == "number" and type(right) == "number" and bottom == nil then
		-- padding(vertical, horizontal)
		local v, h = top, right
		top, bottom, left, right = v, v, h, h
	end
	return Creator.new("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		Parent = parent,
	})
end

function Creator.list(padding, fillDirection, hAlign, vAlign, parent)
	return Creator.new("UIListLayout", {
		Padding = UDim.new(0, padding or 0),
		FillDirection = fillDirection or Enum.FillDirection.Vertical,
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

function Creator.bindInteractive(guiObj, opts)
	opts = opts or {}
	local hoverToken = opts.HoverToken
	local normalToken = opts.NormalToken
	local pressScale = opts.PressScale
	local scaleInst = nil
	if pressScale then
		scaleInst = guiObj:FindFirstChildOfClass("UIScale") or Creator.new("UIScale", { Scale = 1, Parent = guiObj })
	end

	guiObj.MouseEnter:Connect(function()
		if hoverToken then
			Animator.tween(guiObj, { BackgroundColor3 = ThemeManager:Get(hoverToken) }, 0.14)
		end
		if opts.OnHover then
			opts.OnHover(true)
		end
	end)

	guiObj.MouseLeave:Connect(function()
		if normalToken then
			Animator.tween(guiObj, { BackgroundColor3 = ThemeManager:Get(normalToken) }, 0.16)
		end
		if scaleInst then
			Animator.spring(scaleInst, "Scale", 1, { frequency = 16, damping = 0.85 })
		end
		if opts.OnHover then
			opts.OnHover(false)
		end
	end)

	if scaleInst then
		guiObj.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				Animator.spring(scaleInst, "Scale", pressScale, { frequency = 20, damping = 0.85 })
			end
		end)
		guiObj.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				Animator.spring(scaleInst, "Scale", 1, { frequency = 16, damping = 0.8 })
			end
		end)
	end
end

return Creator
