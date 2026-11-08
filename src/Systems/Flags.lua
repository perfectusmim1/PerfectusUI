local Util = require("Core/Util")
local Signal = require("Core/Signal")

local Flags = {}
Flags.__index = Flags

function Flags.new()
	local self = setmetatable({
		_controls = {},
		_values = {},
		Changed = Signal.new(),
		_onDirty = nil,
	}, Flags)

	return setmetatable(self, {
		__index = function(tbl, key)
			local method = Flags[key]
			if method ~= nil then
				return method
			end
			return tbl._controls[key]
		end,
	})
end

function Flags:_register(flagName, control)
	if not flagName or flagName == "" then
		return
	end
	self._controls[flagName] = control
	if control.Get then
		self._values[flagName] = control:Get()
	end
end

function Flags:_setRaw(flagName, value, silent)
	if not flagName or flagName == "" then
		return
	end
	self._values[flagName] = value
	if not silent then
		self.Changed:Fire(flagName, value)
		if self._onDirty then
			self._onDirty(flagName, value)
		end
	end
end

function Flags:Get(flagName)
	local ctrl = self._controls[flagName]
	if ctrl and ctrl.Get then
		return ctrl:Get()
	end
	return self._values[flagName]
end

function Flags:Set(flagName, value, silent)
	local ctrl = self._controls[flagName]
	if ctrl and ctrl.Set then
		ctrl:Set(value, silent)
	else
		self:_setRaw(flagName, value, silent)
	end
end

function Flags:Export()
	local data = {}
	for flag, ctrl in pairs(self._controls) do
		if ctrl.Get then
			local val = ctrl:Get()
			if typeof(val) == "Color3" then
				data[flag] = { __type = "Color3", hex = Util.colorToHex(val) }
			elseif typeof(val) == "EnumItem" then
				data[flag] = { __type = "EnumItem", name = val.Name }
			else
				data[flag] = val
			end
		end
	end
	return data
end

function Flags:Import(data, silent)
	if type(data) ~= "table" then
		return false
	end
	for flag, raw in pairs(data) do
		local ctrl = self._controls[flag]
		if ctrl and ctrl.Set then
			local val = raw
			if type(raw) == "table" then
				if raw.__type == "Color3" and raw.hex then
					val = Util.hexToColor(raw.hex) or Color3.fromRGB(10, 132, 255)
				elseif raw.__type == "EnumItem" and raw.name then
					local ok, item = pcall(function()
						return Enum.KeyCode[raw.name]
					end)
					val = ok and item or raw.name
				end
			end
			pcall(ctrl.Set, ctrl, val, silent == true)
		end
	end
	return true
end

function Flags:ResetAll()
	for _, ctrl in pairs(self._controls) do
		if ctrl.Default ~= nil and ctrl.Set then
			pcall(ctrl.Set, ctrl, ctrl.Default, false)
		end
	end
end

return Flags
