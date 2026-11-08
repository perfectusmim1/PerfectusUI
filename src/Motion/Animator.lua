local Services = require("Core/Services")
local Spring = require("Motion/Spring")

local Animator = {
	Speed = 1,
	ReducedMotion = false,
}

function Animator.tween(inst, props, duration, easingStyle, easingDirection, onComplete)
	if typeof(inst) ~= "Instance" or type(props) ~= "table" then
		return nil
	end
	local speed = math.clamp(Animator.Speed or 1, 0.25, 4)
	local d = (duration or 0.18) / speed
	if Animator.ReducedMotion or d <= 0.01 or not Services.TweenService then
		for k, v in pairs(props) do
			pcall(function()
				inst[k] = v
			end)
		end
		if onComplete then
			task.spawn(onComplete)
		end
		return nil
	end

	local info = TweenInfo.new(d, easingStyle or Enum.EasingStyle.Quint, easingDirection or Enum.EasingDirection.Out)
	local ok, tw = pcall(Services.TweenService.Create, Services.TweenService, inst, info, props)
	if ok and tw then
		if onComplete then
			tw.Completed:Once(function()
				onComplete()
			end)
		end
		tw:Play()
		return tw
	else
		for k, v in pairs(props) do
			pcall(function()
				inst[k] = v
			end)
		end
		if onComplete then
			task.spawn(onComplete)
		end
		return nil
	end
end

function Animator.spring(inst, prop, goalValue, opts)
	if typeof(inst) ~= "Instance" then
		return
	end
	if Animator.ReducedMotion then
		Spring.stop(inst, prop)
		pcall(function()
			inst[prop] = goalValue
		end)
		if opts and opts.onComplete then
			task.spawn(opts.onComplete)
		end
		return
	end
	local speed = math.clamp(Animator.Speed or 1, 0.25, 4)
	local adjusted = {
		frequency = ((opts and opts.frequency) or 14) * speed,
		damping = (opts and opts.damping) or 0.88,
		onComplete = opts and opts.onComplete,
	}
	Spring.target(inst, prop, goalValue, adjusted)
end

function Animator.pulseHighlight(rowFrame)
	if typeof(rowFrame) ~= "Instance" then
		return
	end
	local stroke = rowFrame:FindFirstChild("_PulseStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = "_PulseStroke"
		stroke.Thickness = 1.5
		stroke.Transparency = 1
		stroke.Parent = rowFrame
	end
	local ThemeManager = require("Theme/ThemeManager")
	stroke.Color = ThemeManager:Get("Accent")
	stroke.Transparency = 0.05
	Animator.tween(stroke, { Transparency = 1 }, 0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

return Animator
