local Services = require("Core/Services")

local Spring = {}

local active = {} -- key -> state
local connection = nil

local EPSILON = 0.0008

local function packValue(val, kind)
	if kind == "number" then
		return { val }, { 0 }
	elseif kind == "Vector2" then
		return { val.X, val.Y }, { 0, 0 }
	elseif kind == "UDim2" then
		return { val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset }, { 0, 0, 0, 0 }
	elseif kind == "UDim" then
		return { val.Scale, val.Offset }, { 0, 0 }
	elseif kind == "Color3" then
		return { val.R, val.G, val.B }, { 0, 0, 0 }
	end
	return nil, nil
end

local function unpackValue(arr, kind)
	if kind == "number" then
		return arr[1]
	elseif kind == "Vector2" then
		return Vector2.new(arr[1], arr[2])
	elseif kind == "UDim2" then
		return UDim2.new(arr[1], math.floor(arr[2] + 0.5), arr[3], math.floor(arr[4] + 0.5))
	elseif kind == "UDim" then
		return UDim.new(arr[1], math.floor(arr[2] + 0.5))
	elseif kind == "Color3" then
		return Color3.new(math.clamp(arr[1], 0, 1), math.clamp(arr[2], 0, 1), math.clamp(arr[3], 0, 1))
	end
	return arr[1]
end

local function stepAll(dt)
	dt = math.min(dt, 1 / 20)
	local hasAny = false

	for key, state in pairs(active) do
		local inst = state.inst
		if inst == nil or (typeof(inst) == "Instance" and inst.Parent == nil) then
			active[key] = nil
		else
			local f = state.frequency * 2 * math.pi
			local d = state.damping
			local pos = state.pos
			local vel = state.vel
			local target = state.target
			local settled = true

			-- Substep twice if high frequency to guarantee stability
			local steps = f > 35 and 2 or 1
			local subDt = dt / steps
			for _ = 1, steps do
				for i = 1, #pos do
					local x = pos[i] - target[i]
					local v = vel[i]
					local accel = -f * f * x - 2 * d * f * v
					v = v + accel * subDt
					x = x + v * subDt
					pos[i] = target[i] + x
					vel[i] = v
				end
			end

			for i = 1, #pos do
				local eps = (state.kind == "UDim2" and (i == 2 or i == 4)) and 0.35 or EPSILON
				if math.abs(pos[i] - target[i]) > eps or math.abs(vel[i]) > eps * 4 then
					settled = false
					break
				end
			end

			if settled then
				for i = 1, #pos do
					pos[i] = target[i]
					vel[i] = 0
				end
			end

			local value = unpackValue(pos, state.kind)
			if state.setter then
				pcall(state.setter, value)
			else
				pcall(function()
					inst[state.prop] = value
				end)
			end

			if settled then
				active[key] = nil
				if state.onComplete then
					task.spawn(state.onComplete)
				end
			else
				hasAny = true
			end
		end
	end

	if not hasAny and connection then
		connection:Disconnect()
		connection = nil
	end
end

local function ensureLoop()
	if not connection and Services.RunService then
		connection = Services.RunService.Heartbeat:Connect(stepAll)
	end
end

function Spring.target(inst, prop, goalValue, opts)
	opts = opts or {}
	local kind = typeof(goalValue)
	local targetArr = packValue(goalValue, kind)
	if not targetArr then
		pcall(function()
			inst[prop] = goalValue
		end)
		return
	end

	local key = tostring(inst) .. ":" .. tostring(prop)
	local existing = active[key]
	local freq = opts.frequency or 14
	local damp = opts.damping or 0.88

	if existing and existing.kind == kind then
		existing.target = targetArr
		existing.frequency = freq
		existing.damping = damp
		existing.onComplete = opts.onComplete
	else
		local ok, current = pcall(function()
			return inst[prop]
		end)
		if not ok or typeof(current) ~= kind then
			current = goalValue
		end
		local posArr, velArr = packValue(current, kind)
		active[key] = {
			inst = inst,
			prop = prop,
			kind = kind,
			pos = posArr,
			vel = velArr,
			target = targetArr,
			frequency = freq,
			damping = damp,
			onComplete = opts.onComplete,
		}
	end
	ensureLoop()
end

function Spring.stop(inst, prop)
	if prop then
		active[tostring(inst) .. ":" .. tostring(prop)] = nil
	else
		local prefix = tostring(inst) .. ":"
		for k in pairs(active) do
			if k:sub(1, #prefix) == prefix then
				active[k] = nil
			end
		end
	end
end

function Spring.stopAll()
	table.clear(active)
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

return Spring
