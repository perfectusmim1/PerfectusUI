local Env = require("Core/Env")
local Creator = require("Core/Creator")
local ThemeManager = require("Theme/ThemeManager")
local Icons = require("Assets/Icons")

local CodeBlock = {}

function CodeBlock.create(section, opts)
	opts = opts or {}
	local codeText = tostring(opts.Code or opts.Text or "")
	local titleText = tostring(opts.Title or "Luau Snippet")

	local card = Creator.new("Frame", {
		Name = "CodeBlock",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = section:_nextOrder(),
		ZIndex = 3,
		ThemeBind = { BackgroundColor3 = "InputBg" },
		Parent = section.Container,
	}, {
		Creator.corner(8),
		Creator.stroke("Border", 1, 0.25),
		Creator.padding(8, 12, 10, 12),
		Creator.list(6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top),
	})

	local topBar = Creator.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		ZIndex = 4,
		Parent = card,
	})

	Creator.new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -70, 1, 0),
		Font = Enum.Font.RobotoMono,
		TextSize = 11,
		Text = titleText,
		ZIndex = 5,
		ThemeBind = { TextColor3 = "TextMuted" },
		Parent = topBar,
	})

	local copyBtn = Creator.new("TextButton", {
		Name = "CopyBtn",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(64, 22),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 11,
		Text = "  Copy",
		ZIndex = 5,
		ThemeBind = {
			BackgroundColor3 = "ControlBg",
			TextColor3 = "TextSecondary",
		},
		Parent = topBar,
	}, {
		Creator.corner(5),
		Creator.stroke("Border", 1, 0.35),
		Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.fromOffset(11, 11),
			Image = Icons.resolve("copy") or "",
			ZIndex = 6,
			ThemeBind = { ImageColor3 = "TextSecondary" },
		}),
	})

	local codeLabel = Creator.new("TextLabel", {
		Name = "Code",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.RobotoMono,
		TextSize = 12,
		Text = codeText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
		ZIndex = 4,
		ThemeBind = { TextColor3 = "Text" },
		Parent = card,
	})

	copyBtn.Activated:Connect(function()
		Env.setClipboard(codeText)
		copyBtn.Text = "  Copied"
		copyBtn.TextColor3 = ThemeManager:Get("Success")
		task.delay(1.4, function()
			if copyBtn.Parent then
				copyBtn.Text = "  Copy"
				copyBtn.TextColor3 = ThemeManager:Get("TextSecondary")
			end
		end)
	end)

	return {
		Kind = "CodeBlock",
		Row = card,
		Get = function()
			return codeText
		end,
		Set = function(_, newCode)
			codeText = tostring(newCode or "")
			codeLabel.Text = codeText
		end,
		SetCode = function(_, newCode)
			codeText = tostring(newCode or "")
			codeLabel.Text = codeText
		end,
		SetVisible = function(_, vis)
			card.Visible = vis == true
		end,
		Destroy = function()
			card:Destroy()
		end,
	}
end

return CodeBlock
