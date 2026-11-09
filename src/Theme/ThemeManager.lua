local Services = require("Core/Services")
local Signal = require("Core/Signal")
local Util = require("Core/Util")
local Themes = require("Theme/Themes")

local ThemeManager = {
	CurrentTheme = "Obsidian",
	CurrentAccent = "Indigo",
	CustomAccentColor = nil,
	Changed = Signal.new(),
	_bindings = {}, -- inst -> { prop = token }
}

local function computeDerivedAccent(baseAccent, isDark)
	local hover = Util.lerpColor(baseAccent, Color3.new(1, 1, 1), isDark and 0.14 or 0.1)
	local press = Util.lerpColor(baseAccent, Color3.new(0, 0, 0), 0.16)
	local soft =
		Util.lerpColor(baseAccent, isDark and Color3.fromRGB(24, 24, 28) or Color3.fromRGB(245, 245, 247), 0.78)
	return hover, press, soft
end

function ThemeManager:GetPalette()
	return Themes.Palettes[self.CurrentTheme] or Themes.Palettes.Dark
end

function ThemeManager:GetAccentColor()
	if self.CustomAccentColor then
		return self.CustomAccentColor
	end
	return Themes.Accents[self.CurrentAccent] or Themes.Accents.Blue
end

function ThemeManager:Get(token)
	if typeof(token) == "Color3" then
		return token
	end
	local palette = self:GetPalette()
	local accent = self:GetAccentColor()
	if token == "Accent" then
		return accent
	elseif token == "AccentHover" or token == "AccentPress" or token == "AccentSoft" then
		local hover, press, soft = computeDerivedAccent(accent, palette.IsDark)
		if token == "AccentHover" then
			return hover
		elseif token == "AccentPress" then
			return press
		else
			return soft
		end
	end
	return palette[token] or Themes.Palettes.Dark[token] or Color3.fromRGB(255, 255, 255)
end

function ThemeManager:Bind(inst, propMap)
	if typeof(inst) ~= "Instance" or type(propMap) ~= "table" then
		return
	end
	local entry = self._bindings[inst] or {}
	for prop, token in pairs(propMap) do
		entry[prop] = token
		local color = self:Get(token)
		pcall(function()
			inst[prop] = color
		end)
	end
	self._bindings[inst] = entry
end

function ThemeManager:Unbind(inst)
	self._bindings[inst] = nil
end

function ThemeManager:_refreshAll(animate)
	local tweenService = Services.TweenService
	local info = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	for inst, propMap in pairs(self._bindings) do
		if inst.Parent == nil then
			self._bindings[inst] = nil
		else
			local goal = {}
			for prop, token in pairs(propMap) do
				goal[prop] = self:Get(token)
			end
			if animate and tweenService then
				local ok, tw = pcall(tweenService.Create, tweenService, inst, info, goal)
				if ok and tw then
					tw:Play()
				else
					for prop, val in pairs(goal) do
						pcall(function()
							inst[prop] = val
						end)
					end
				end
			else
				for prop, val in pairs(goal) do
					pcall(function()
						inst[prop] = val
					end)
				end
			end
		end
	end
	self.Changed:Fire(self.CurrentTheme, self.CurrentAccent)
end

function ThemeManager:SetTheme(name, animate)
	if type(name) == "string" and Themes.Palettes[name] then
		self.CurrentTheme = name
		self:_refreshAll(animate ~= false)
	end
end

function ThemeManager:SetAccent(accentNameOrColor, animate)
	if typeof(accentNameOrColor) == "Color3" then
		self.CustomAccentColor = accentNameOrColor
		self:_refreshAll(animate ~= false)
	elseif type(accentNameOrColor) == "string" and Themes.Accents[accentNameOrColor] then
		self.CustomAccentColor = nil
		self.CurrentAccent = accentNameOrColor
		self:_refreshAll(animate ~= false)
	end
end

function ThemeManager:RegisterTheme(name, definition)
	if type(name) ~= "string" or type(definition) ~= "table" then
		return
	end
	local base = table.clone(Themes.Palettes.Dark)
	for k, v in pairs(definition) do
		base[k] = v
	end
	base.Name = name
	Themes.Palettes[name] = base
	if not table.find(Themes.ThemeOrder, name) then
		Themes.ThemeOrder[#Themes.ThemeOrder + 1] = name
	end
end

function ThemeManager:GetThemes()
	return table.clone(Themes.ThemeOrder)
end

function ThemeManager:GetAccents()
	return table.clone(Themes.AccentOrder)
end

return ThemeManager
