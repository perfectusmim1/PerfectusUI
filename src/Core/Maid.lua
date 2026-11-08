local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_items = {},
		_keyed = {},
	}, Maid)
end

local function cleanOne(item)
	if item == nil then
		return
	end
	local kind = typeof(item)
	pcall(function()
		if kind == "RBXScriptConnection" then
			item:Disconnect()
		elseif kind == "thread" then
			task.cancel(item)
		elseif kind == "function" then
			item()
		elseif kind == "Instance" then
			item:Destroy()
		elseif kind == "table" then
			if type(item.Destroy) == "function" then
				item:Destroy()
			elseif type(item.Clean) == "function" then
				item:Clean()
			elseif type(item.Disconnect) == "function" then
				item:Disconnect()
			end
		end
	end)
end

function Maid:Add(item, key)
	if item == nil then
		if key ~= nil and self._keyed[key] ~= nil then
			local old = self._keyed[key]
			self._keyed[key] = nil
			cleanOne(old)
		end
		return nil
	end
	if key ~= nil then
		local old = self._keyed[key]
		if old ~= nil and old ~= item then
			cleanOne(old)
		end
		self._keyed[key] = item
		return item
	end
	self._items[#self._items + 1] = item
	return item
end

function Maid:GiveTask(item)
	return self:Add(item)
end

function Maid:Clean()
	local keyed = self._keyed
	self._keyed = {}
	for _, item in pairs(keyed) do
		cleanOne(item)
	end

	local items = self._items
	self._items = {}
	for i = #items, 1, -1 do
		cleanOne(items[i])
	end
end

Maid.Destroy = Maid.Clean

return Maid
