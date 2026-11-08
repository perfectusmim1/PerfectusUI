local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
	return setmetatable({
		Connected = true,
		_signal = signal,
		_fn = fn,
	}, Connection)
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false
	local list = self._signal._listeners
	for i = #list, 1, -1 do
		if list[i] == self then
			table.remove(list, i)
			break
		end
	end
end

Connection.Destroy = Connection.Disconnect

function Signal.new()
	return setmetatable({
		_listeners = {},
	}, Signal)
end

function Signal:Connect(fn)
	assert(type(fn) == "function", "Signal:Connect expects a function")
	local conn = Connection.new(self, fn)
	self._listeners[#self._listeners + 1] = conn
	return conn
end

function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		if conn then
			conn:Disconnect()
		end
		fn(...)
	end)
	return conn
end

function Signal:Fire(...)
	local snapshot = table.clone(self._listeners)
	for i = 1, #snapshot do
		local conn = snapshot[i]
		if conn.Connected then
			task.spawn(conn._fn, ...)
		end
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	self:Once(function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Destroy()
	local list = self._listeners
	self._listeners = {}
	for i = 1, #list do
		list[i].Connected = false
	end
end

return Signal
