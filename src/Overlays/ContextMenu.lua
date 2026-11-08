local Env = require("Core/Env")
local Creator = require("Core/Creator")
local ThemeManager = require("Theme/ThemeManager")
local Icons = require("Assets/Icons")
local Popover = require("Components/Popover")

local ContextMenu = {}

function ContextMenu.bind(window, rowGui, control)
	rowGui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			ContextMenu.open(window, control, Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
end

function ContextMenu.open(window, control, screenPos)
	local items = {}

	if control.Default ~= nil and control.Set then
		items[#items + 1] = {
			Title = "Reset to Default",
			Icon = "rotate-ccw",
			Action = function()
				control:Set(control.Default, false)
			end,
		}
	end

	if control.Get then
		items[#items + 1] = {
			Title = "Copy Current Value",
			Icon = "copy",
			Action = function()
				local v = control:Get()
				Env.setClipboard(tostring(v))
				window:Notify({
					Title = "Copied",
					Content = "Copied value to clipboard.",
					Type = "Info",
					Duration = 2.5,
				})
			end,
		}
	end

	if control.Flag then
		items[#items + 1] = {
			Title = "Copy Flag ID (" .. tostring(control.Flag) .. ")",
			Icon = "tag",
			Action = function()
				Env.setClipboard(tostring(control.Flag))
				window:Notify({
					Title = "Copied",
					Content = "Copied flag ID to clipboard.",
					Type = "Info",
					Duration = 2.5,
				})
			end,
		}
	end

	items[#items + 1] = {
		Title = "Highlight Row",
		Icon = "sparkles",
		Action = function()
			if control.Highlight then
				control:Highlight()
			end
		end,
	}

	local pop = Popover.open({
		Name = "ContextMenuPopover",
		Position = screenPos,
		Width = 186,
		Height = #items * 28 + 10,
	})
	if not pop then
		return
	end

	Creator.padding(5, 5, 5, 5, pop.content)
	Creator.list(2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, pop.content)

	for idx, item in ipairs(items) do
		local btn = Creator.new("TextButton", {
			Name = "CtxItem_" .. idx,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			LayoutOrder = idx,
			ZIndex = 203,
			ThemeBind = { BackgroundColor3 = "RowHover" },
			Parent = pop.content,
		}, {
			Creator.corner(6),
			Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				Size = UDim2.fromOffset(13, 13),
				Image = Icons.resolve(item.Icon) or "",
				ZIndex = 204,
				ThemeBind = { ImageColor3 = "TextSecondary" },
			}),
			Creator.new("TextLabel", {
				Position = UDim2.fromOffset(27, 0),
				Size = UDim2.new(1, -32, 1, 0),
				Font = Enum.Font.BuilderSans,
				TextSize = 12,
				Text = item.Title,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 204,
				ThemeBind = { TextColor3 = "Text" },
			}),
		})

		btn.MouseEnter:Connect(function()
			btn.BackgroundTransparency = 0.2
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundTransparency = 1
		end)
		btn.Activated:Connect(function()
			Popover.close()
			item.Action()
		end)
	end
end

return ContextMenu
