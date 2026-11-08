local Services = require("Core/Services")

local Util = {}

function Util.round(value, step)
	step = step or 1
	if step <= 0 then
		return value
	end
	local inv = 1 / step
	local rounded = math.floor(value * inv + 0.5) / inv
	local decimals = math.max(0, math.ceil(-math.log10(step) - 1e-9))
	if decimals > 0 then
		return tonumber(string.format("%." .. tostring(decimals) .. "f", rounded)) or rounded
	end
	return math.floor(rounded + 0.5)
end

function Util.clamp(val, min, max)
	if min and val < min then
		return min
	end
	if max and val > max then
		return max
	end
	return val
end

function Util.lerp(a, b, t)
	return a + (b - a) * t
end

function Util.lerpColor(c1, c2, t)
	return Color3.new(c1.R + (c2.R - c1.R) * t, c1.G + (c2.G - c1.G) * t, c1.B + (c2.B - c1.B) * t)
end

function Util.colorToHex(color)
	if typeof(color) ~= "Color3" then
		return "#FFFFFF"
	end
	local r = math.clamp(math.floor(color.R * 255 + 0.5), 0, 255)
	local g = math.clamp(math.floor(color.G * 255 + 0.5), 0, 255)
	local b = math.clamp(math.floor(color.B * 255 + 0.5), 0, 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

function Util.hexToColor(hex)
	if type(hex) ~= "string" then
		return nil
	end
	local cleaned = hex:gsub("^%s*#?", ""):gsub("%s*$", "")
	if #cleaned == 3 then
		local r = tonumber(cleaned:sub(1, 1) .. cleaned:sub(1, 1), 16)
		local g = tonumber(cleaned:sub(2, 2) .. cleaned:sub(2, 2), 16)
		local b = tonumber(cleaned:sub(3, 3) .. cleaned:sub(3, 3), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	elseif #cleaned == 6 then
		local r = tonumber(cleaned:sub(1, 2), 16)
		local g = tonumber(cleaned:sub(3, 4), 16)
		local b = tonumber(cleaned:sub(5, 6), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	end
	return nil
end

function Util.measureText(text, size, font, maxWidth)
	local ts = Services.TextService
	if not ts then
		return Vector2.new(#tostring(text) * (size * 0.55), size + 4)
	end
	local ok, bounds = pcall(function()
		return ts:GetTextSize(
			tostring(text or ""),
			size or 14,
			font or Enum.Font.BuilderSans,
			Vector2.new(maxWidth or 10000, 10000)
		)
	end)
	if ok and bounds then
		return bounds
	end
	return Vector2.new(#tostring(text) * (size * 0.55), size + 4)
end

function Util.fuzzyScore(query, candidate)
	query = tostring(query or ""):lower():gsub("^%s*(.-)%s*$", "%1")
	candidate = tostring(candidate or ""):lower()
	if query == "" then
		return 1
	end
	if candidate == query then
		return 1000
	end
	local plainStart = candidate:find(query, 1, true)
	if plainStart then
		return 500 - plainStart
	end
	local score = 0
	local qIdx = 1
	local qLen = #query
	local streak = 0
	for cIdx = 1, #candidate do
		if candidate:sub(cIdx, cIdx) == query:sub(qIdx, qIdx) then
			qIdx += 1
			streak += 1
			score += 10 + streak * 5 - math.min(cIdx, 30) * 0.2
			if qIdx > qLen then
				return score
			end
		else
			streak = 0
		end
	end
	return nil
end

function Util.formatKeyName(key)
	if key == nil then
		return "None"
	end
	if typeof(key) == "EnumItem" then
		key = key.Name
	end
	local name = tostring(key)
	local map = {
		RightShift = "RShift",
		LeftShift = "LShift",
		RightControl = "RCtrl",
		LeftControl = "LCtrl",
		RightAlt = "RAlt",
		LeftAlt = "LAlt",
		MouseButton1 = "MB1",
		MouseButton2 = "MB2",
		MouseButton3 = "MB3",
		Backspace = "Bksp",
		Return = "Enter",
		Escape = "Esc",
		Space = "Space",
	}
	return map[name] or name
end

local reportedErrors = {}

function Util.safeCall(scope, fn, onErrorNotify, ...)
	if type(fn) ~= "function" then
		return true
	end
	local ok, res = xpcall(fn, function(err)
		return debug.traceback(tostring(err), 2)
	end, ...)
	if not ok then
		local firstLine = tostring(res):match("^[^\n]*") or tostring(res)
		local dedupeKey = tostring(scope) .. "|" .. firstLine
		if not reportedErrors[dedupeKey] then
			reportedErrors[dedupeKey] = true
			warn(string.format("[PerfectusUI] Error in %s:\n%s", tostring(scope), tostring(res)))
			if type(onErrorNotify) == "function" then
				pcall(onErrorNotify, tostring(scope), "Stopped after an error. Details in console (F9).")
			end
		end
		return false, res
	end
	return true, res
end

function Util.debounce(waitSeconds, fn)
	local pending = false
	local lastArgs = nil
	return function(...)
		lastArgs = table.pack(...)
		if pending then
			return
		end
		pending = true
		task.delay(waitSeconds, function()
			pending = false
			local args = lastArgs
			lastArgs = nil
			if args then
				fn(table.unpack(args, 1, args.n))
			end
		end)
	end
end

return Util
