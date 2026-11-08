local Services = require("Core/Services")
local Popover = require("Components/Popover")

local InputManager = {}

function InputManager.attach(window)
	window.Maid:Add(Services.UserInputService.InputBegan:Connect(function(input, processed)
		local focused = Services.UserInputService:GetFocusedTextBox()
		if focused ~= nil then
			return
		end

		-- Ctrl+K or Cmd+K opens Command Palette
		if input.KeyCode == Enum.KeyCode.K then
			local ctrl = Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
				or Services.UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
				or Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftMeta)
			if ctrl and window.CommandPalette then
				Popover.close()
				window.CommandPalette:Toggle()
				return
			end
		end

		-- Toggle Window Visibility
		if not processed and window.ToggleKey and input.KeyCode == window.ToggleKey then
			window:ToggleVisibility()
		end
	end))
end

return InputManager
