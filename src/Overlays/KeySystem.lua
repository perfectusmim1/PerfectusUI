local Env = require("Core/Env")
local Creator = require("Core/Creator")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")

local KeySystem = {}

function KeySystem.gate(window, cfg, onUnlocked)
	if type(cfg) ~= "table" or cfg.Enabled == false then
		onUnlocked()
		return
	end

	local savePath = (window.ConfigFolder or "PerfectusUI") .. "/saved_key.txt"
	local function checkKey(candidate)
		candidate = tostring(candidate or ""):gsub("^%s*(.-)%s*$", "%1")
		if candidate == "" then
			return false
		end
		if type(cfg.Validate) == "function" then
			local ok, res = pcall(cfg.Validate, candidate)
			return ok and res == true
		end
		if type(cfg.Keys) == "table" then
			for _, k in ipairs(cfg.Keys) do
				if tostring(k) == candidate then
					return true
				end
			end
		elseif type(cfg.Key) == "string" then
			return candidate == cfg.Key
		end
		return false
	end

	if cfg.Remember ~= false and Env.HasFileSystem then
		local saved = Env.readFile(savePath)
		if saved and checkKey(saved) then
			onUnlocked()
			return
		end
	end

	local gate = Creator.new("Frame", {
		Name = "KeySystemGate",
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 245,
		ThemeBind = { BackgroundColor3 = "WindowBg" },
		Parent = window.OverlayLayer,
	}, {
		Creator.corner(14),
	})

	local card = Creator.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(320, 200),
		ZIndex = 246,
		ThemeBind = { BackgroundColor3 = "SectionBg" },
		Parent = gate,
	}, {
		Creator.corner(12),
		Creator.stroke("Border", 1, 0.2),
		Creator.padding(18, 18, 16, 18),
		Creator.list(10, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top),
	})

	Creator.new("ImageLabel", {
		Size = UDim2.fromOffset(24, 24),
		Image = Icons.resolve("key") or "",
		LayoutOrder = 1,
		ZIndex = 247,
		ThemeBind = { ImageColor3 = "Accent" },
		Parent = card,
	})

	Creator.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 15,
		Text = tostring(cfg.Title or "Key Verification"),
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		ZIndex = 247,
		ThemeBind = { TextColor3 = "Text" },
		Parent = card,
	})

	local statusLbl = Creator.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		Font = Enum.Font.BuilderSans,
		TextSize = 12,
		Text = tostring(cfg.Subtitle or "Enter your access key to continue."),
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 3,
		ZIndex = 247,
		ThemeBind = { TextColor3 = "TextSecondary" },
		Parent = card,
	})

	local keyInput = Creator.new("TextBox", {
		Size = UDim2.new(1, 0, 0, 32),
		Font = Enum.Font.RobotoMono,
		TextSize = 12,
		PlaceholderText = "Paste license key...",
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 4,
		ZIndex = 247,
		ThemeBind = {
			BackgroundColor3 = "InputBg",
			TextColor3 = "Text",
			PlaceholderColor3 = "TextMuted",
		},
		Parent = card,
	}, {
		Creator.corner(7),
		Creator.stroke("Border", 1, 0.3),
	})

	local btnRow = Creator.new("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		ZIndex = 247,
		Parent = card,
	}, {
		Creator.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
	})

	if cfg.Link then
		local getBtn = Creator.new("TextButton", {
			Size = UDim2.fromOffset(110, 28),
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 12,
			Text = "Copy Key Link",
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 1,
			ZIndex = 248,
			ThemeBind = {
				BackgroundColor3 = "ControlBg",
				TextColor3 = "Text",
			},
			Parent = btnRow,
		}, {
			Creator.corner(7),
			Creator.stroke("Border", 1, 0.35),
		})
		getBtn.Activated:Connect(function()
			Env.setClipboard(tostring(cfg.Link))
			statusLbl.Text = "Key link copied to clipboard."
		end)
	end

	local verifyBtn = Creator.new("TextButton", {
		Size = UDim2.fromOffset(110, 28),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 12,
		Text = "Unlock",
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		ZIndex = 248,
		ThemeBind = {
			BackgroundColor3 = "Accent",
			TextColor3 = "OnAccent",
		},
		Parent = btnRow,
	}, {
		Creator.corner(7),
	})

	verifyBtn.Activated:Connect(function()
		if checkKey(keyInput.Text) then
			if cfg.Remember ~= false and Env.HasFileSystem then
				Env.writeFile(savePath, keyInput.Text)
			end
			Animator.tween(
				gate,
				{ BackgroundTransparency = 1 },
				0.18,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out,
				function()
					if gate.Parent then
						gate:Destroy()
					end
				end
			)
			onUnlocked()
		else
			statusLbl.Text = "Invalid key. Please try again."
			statusLbl.TextColor3 = ThemeManager:Get("Error")
		end
	end)
end

return KeySystem
