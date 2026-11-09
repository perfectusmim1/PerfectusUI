local Services = require("Core/Services")
local Creator = require("Core/Creator")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")
local Animator = require("Motion/Animator")
local Icons = require("Assets/Icons")
local Popover = require("Components/Popover")
local RowBase = require("Components/RowBase")

local Dropdown = {}

function Dropdown.create(section, opts)
	opts = opts or {}
	local isMulti = opts.Multi == true
	local allowNone = opts.AllowNone == true
	local isPlayerList = (opts.Options == "Players" or opts.PlayerList == true)

	local function getRawOptions()
		if isPlayerList then
			local list = {}
			for _, p in ipairs(Services.Players:GetPlayers()) do
				table.insert(list, p.Name)
			end
			table.sort(list)
			return list
		end
		if type(opts.Options) == "table" then
			local list = {}
			for _, v in ipairs(opts.Options) do
				table.insert(list, tostring(v))
			end
			return list
		end
		return {}
	end

	local selected = nil
	if isMulti then
		selected = {}
		if type(opts.Default) == "table" then
			for _, v in ipairs(opts.Default) do
				table.insert(selected, tostring(v))
			end
		end
	else
		selected = opts.Default ~= nil and tostring(opts.Default) or nil
	end

	local control = RowBase.create(section, {
		Title = opts.Title or "Dropdown",
		Description = opts.Description,
		Icon = opts.Icon,
		Tooltip = opts.Tooltip,
		Flag = opts.Flag or opts.Id,
		Default = selected,
		RightWidth = 165,
		Clickable = false,
	})
	control.Kind = "Dropdown"

	local triggerBtn = Creator.new("TextButton", {
		Name = "TriggerButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(160, 28),
		BackgroundColor3 = ThemeManager:Get("ControlBg"),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		ThemeBind = { BackgroundColor3 = "ControlBg" },
		Parent = control.RightSlot,
	}, {
		Creator.corner(8),
		Creator.stroke("Outline", 1, 0),
	})

	local valueLabel = Creator.new("TextLabel", {
		Name = "SelectedText",
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Font = Enum.Font.BuilderSansMedium,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
		ThemeBind = { TextColor3 = "Text" },
		Parent = triggerBtn,
	})

	local chevron = Creator.new("ImageLabel", {
		Name = "Chevron",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = Icons.resolve("chevron-down") or "",
		ZIndex = 7,
		ThemeBind = { ImageColor3 = "TextSecondary" },
		Parent = triggerBtn,
	})

	local function formatDisplay()
		if isMulti then
			local count = type(selected) == "table" and #selected or 0
			if count == 0 then
				return "Select..."
			elseif count == 1 then
				return tostring(selected[1])
			else
				return string.format("%d Selected", count)
			end
		else
			if selected == nil or selected == "" then
				return "Select..."
			end
			return tostring(selected)
		end
	end

	local function syncDisplay()
		valueLabel.Text = formatDisplay()
	end

	local function isSelected(opt)
		if isMulti then
			if type(selected) ~= "table" then
				return false
			end
			for _, v in ipairs(selected) do
				if v == opt then
					return true
				end
			end
			return false
		else
			return selected == opt
		end
	end

	local activePopHandle = nil

	local function openDropdown()
		if control:IsLocked() then
			return
		end
		if activePopHandle then
			Popover.close()
			return
		end

		Animator.tween(chevron, { Rotation = 180 }, 0.16)

		local options = getRawOptions()
		local showSearch = opts.Search == true or (#options > 7)
		local itemHeight = 28
		local padding = 4
		local maxVisible = math.min(6, math.max(1, #options))
		local listHeight = maxVisible * (itemHeight + padding)
		local totalHeight = listHeight + (showSearch and 36 or 0) + 12

		local pop = Popover.open({
			Name = "DropdownPopover",
			Anchor = triggerBtn,
			Width = 190,
			Height = math.clamp(totalHeight, 60, 240),
			OnClose = function()
				activePopHandle = nil
				Animator.tween(chevron, { Rotation = 0 }, 0.16)
			end,
		})
		if not pop then
			return
		end
		activePopHandle = pop

		Creator.padding(6, 6, 6, 6, pop.content)

		local searchBox = nil
		if showSearch then
			local searchContainer = Creator.new("Frame", {
				Name = "SearchBox",
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = ThemeManager:Get("InputBg"),
				LayoutOrder = 1,
				ZIndex = 202,
				ThemeBind = { BackgroundColor3 = "InputBg" },
				Parent = pop.content,
			}, {
				Creator.corner(6),
				Creator.stroke("Border", 1, 0.3),
				Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 8, 0.5, 0),
					Size = UDim2.fromOffset(12, 12),
					Image = Icons.resolve("search") or "",
					ZIndex = 203,
					ThemeBind = { ImageColor3 = "TextMuted" },
				}),
			})

			searchBox = Creator.new("TextBox", {
				Position = UDim2.fromOffset(26, 0),
				Size = UDim2.new(1, -30, 1, 0),
				PlaceholderText = "Search...",
				Font = Enum.Font.BuilderSans,
				TextSize = 12,
				ZIndex = 203,
				ThemeBind = {
					TextColor3 = "Text",
					PlaceholderColor3 = "TextMuted",
				},
				Parent = searchContainer,
			})
		end

		local scroll = Creator.new("ScrollingFrame", {
			Name = "OptionList",
			Size = UDim2.new(1, 0, 1, showSearch and -32 or 0),
			Position = UDim2.fromOffset(0, showSearch and 32 or 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 3,
			ZIndex = 202,
			Parent = pop.content,
		}, {
			Creator.list(
				padding,
				Enum.FillDirection.Vertical,
				Enum.HorizontalAlignment.Left,
				Enum.VerticalAlignment.Top
			),
		})

		local optionRows = {}

		local function renderRows(filterQuery)
			for _, r in ipairs(optionRows) do
				r:Destroy()
			end
			table.clear(optionRows)

			for idx, opt in ipairs(options) do
				local score = 1
				if filterQuery and filterQuery ~= "" then
					score = Util.fuzzyScore(filterQuery, opt)
				end

				if score then
					local checked = isSelected(opt)
					local btn = Creator.new("TextButton", {
						Name = "Option_" .. tostring(opt),
						Size = UDim2.new(1, -2, 0, itemHeight),
						BackgroundColor3 = ThemeManager:Get("RowHover"),
						BackgroundTransparency = checked and 0.85 or 1,
						AutoButtonColor = false,
						LayoutOrder = math.floor(1000 - (score or 0)) + idx,
						ZIndex = 203,
						Parent = scroll,
					}, {
						Creator.corner(6),
					})

					local label = Creator.new("TextLabel", {
						Position = UDim2.fromOffset(8, 0),
						Size = UDim2.new(1, -32, 1, 0),
						Font = Enum.Font.BuilderSans,
						TextSize = 13,
						Text = opt,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ZIndex = 204,
						TextColor3 = ThemeManager:Get(checked and "Accent" or "Text"),
						Parent = btn,
					})

					local checkImg = Creator.new("ImageLabel", {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -8, 0.5, 0),
						Size = UDim2.fromOffset(13, 13),
						Image = Icons.resolve("check") or "",
						Visible = checked,
						ZIndex = 204,
						ThemeBind = { ImageColor3 = "Accent" },
						Parent = btn,
					})

					btn.MouseEnter:Connect(function()
						Animator.tween(btn, { BackgroundTransparency = 0.5 }, 0.12)
					end)
					btn.MouseLeave:Connect(function()
						Animator.tween(btn, { BackgroundTransparency = checked and 0.85 or 1 }, 0.14)
					end)

					btn.Activated:Connect(function()
						if isMulti then
							local foundIdx = nil
							for i, v in ipairs(selected) do
								if v == opt then
									foundIdx = i
									break
								end
							end
							if foundIdx then
								table.remove(selected, foundIdx)
							else
								table.insert(selected, opt)
							end
							checked = not checked
							checkImg.Visible = checked
							label.TextColor3 = ThemeManager:Get(checked and "Accent" or "Text")
							control:Set(selected, false)
						else
							if allowNone and selected == opt then
								control:Set(nil, false)
							else
								control:Set(opt, false)
							end
							Popover.close()
						end
					end)

					table.insert(optionRows, btn)
				end
			end
		end

		renderRows(nil)

		if searchBox then
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				renderRows(searchBox.Text)
			end)
		end
	end

	triggerBtn.Activated:Connect(openDropdown)

	local function setValue(newVal, silent)
		if isMulti then
			local tbl = {}
			if type(newVal) == "table" then
				for _, v in ipairs(newVal) do
					table.insert(tbl, tostring(v))
				end
			end
			selected = tbl
		else
			selected = newVal ~= nil and tostring(newVal) or nil
		end
		syncDisplay()

		if control.Flag and control.Window and control.Window.Flags then
			control.Window.Flags:_setRaw(control.Flag, selected, silent)
		end
		if not silent then
			control.Changed:Fire(selected)
			if type(opts.Callback) == "function" then
				task.spawn(
					Util.safeCall,
					control.Title,
					opts.Callback,
					control.Window and control.Window._notifyError,
					selected
				)
			end
		end
	end

	function control:Get()
		return selected
	end

	function control:Set(val, silent)
		setValue(val, silent)
	end

	function control:Refresh(newOptions, keepSelection)
		if type(newOptions) == "table" then
			opts.Options = newOptions
		end
		if not keepSelection then
			setValue(isMulti and {} or nil, true)
		else
			syncDisplay()
		end
	end

	if isPlayerList then
		Services.Players.PlayerAdded:Connect(function()
			if activePopHandle then
				openDropdown()
			end
		end)
		Services.Players.PlayerRemoving:Connect(function(player)
			if not isMulti and selected == player.Name then
				setValue(nil, false)
			elseif isMulti and type(selected) == "table" then
				for i, v in ipairs(selected) do
					if v == player.Name then
						table.remove(selected, i)
						setValue(selected, false)
						break
					end
				end
			end
			if activePopHandle then
				openDropdown()
			end
		end)
	end

	if control.Flag and control.Window and control.Window.Flags then
		control.Window.Flags:_register(control.Flag, control)
	end

	syncDisplay()
	return control
end

return Dropdown
