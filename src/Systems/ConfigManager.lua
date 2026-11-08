local Services = require("Core/Services")
local Env = require("Core/Env")
local Util = require("Core/Util")
local ThemeManager = require("Theme/ThemeManager")

local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new(window, folder)
	folder = tostring(folder or "PerfectusUI/Default"):gsub("/+$", "")
	local self = setmetatable({
		Window = window,
		Folder = folder,
		ConfigsFolder = folder .. "/configs",
		AutoSavePath = folder .. "/autosave.json",
		AutoSaveEnabled = true,
		Loading = false,
		_memoryConfigs = {},
		_memoryAutoSave = nil,
	}, ConfigManager)

	self._debouncedAutoSave = Util.debounce(0.8, function()
		if self.AutoSaveEnabled and not self.Loading then
			self:SaveAutoSave()
		end
	end)

	if window.Flags then
		window.Flags._onDirty = function()
			self:_queueAutoSave()
		end
	end

	return self
end

function ConfigManager:_queueAutoSave()
	if self.Loading or not self.AutoSaveEnabled then
		return
	end
	self._debouncedAutoSave()
end

function ConfigManager:_sanitizeName(name)
	local clean = tostring(name or ""):gsub("[^%w_%- ]", ""):gsub("^%s*(.-)%s*$", "%1"):sub(1, 32)
	return clean ~= "" and clean or nil
end

function ConfigManager:Serialize()
	local payload = {
		version = 1,
		theme = ThemeManager.CurrentTheme,
		accent = ThemeManager.CurrentAccent,
		autoSave = self.AutoSaveEnabled,
		flags = self.Window.Flags and self.Window.Flags:Export() or {},
	}
	local ok, json = pcall(function()
		return Services.HttpService:JSONEncode(payload)
	end)
	return ok and json or "{}"
end

function ConfigManager:Deserialize(jsonStr, applyToCallback)
	if type(jsonStr) ~= "string" or jsonStr == "" then
		return false
	end
	local ok, decoded = pcall(function()
		return Services.HttpService:JSONDecode(jsonStr)
	end)
	if not (ok and type(decoded) == "table") then
		return false
	end
	self.Loading = true
	if type(decoded.theme) == "string" then
		ThemeManager:SetTheme(decoded.theme, true)
	end
	if type(decoded.accent) == "string" then
		ThemeManager:SetAccent(decoded.accent, true)
	end
	if type(decoded.flags) == "table" and self.Window.Flags then
		self.Window.Flags:Import(decoded.flags, applyToCallback == false)
	end
	self.Loading = false
	return true
end

function ConfigManager:Save(name)
	local clean = self:_sanitizeName(name)
	if not clean then
		return false, "Enter a valid config name."
	end
	local json = self:Serialize()
	self._memoryConfigs[clean] = json
	if Env.HasFileSystem then
		local path = self.ConfigsFolder .. "/" .. clean .. ".json"
		Env.writeFile(path, json)
	end
	return true, clean
end

function ConfigManager:Load(name)
	local clean = self:_sanitizeName(name)
	if not clean then
		return false, "Select a config to load."
	end
	local json = nil
	if Env.HasFileSystem then
		json = Env.readFile(self.ConfigsFolder .. "/" .. clean .. ".json")
	end
	if not json then
		json = self._memoryConfigs[clean]
	end
	if not json then
		return false, "Config not found."
	end
	local ok = self:Deserialize(json, true)
	return ok, ok and ("Loaded '" .. clean .. "'.") or "Corrupted config JSON."
end

function ConfigManager:Delete(name)
	local clean = self:_sanitizeName(name)
	if not clean then
		return false
	end
	self._memoryConfigs[clean] = nil
	if Env.HasFileSystem then
		Env.deleteFile(self.ConfigsFolder .. "/" .. clean .. ".json")
	end
	return true
end

function ConfigManager:List()
	local seen = {}
	local list = {}
	for k in pairs(self._memoryConfigs) do
		seen[k] = true
		list[#list + 1] = k
	end
	if Env.HasFileSystem then
		for _, file in ipairs(Env.listFiles(self.ConfigsFolder)) do
			local name = tostring(file):match("([^/\\]+)%.json$")
			if name and not seen[name] then
				seen[name] = true
				list[#list + 1] = name
			end
		end
	end
	table.sort(list)
	if #list == 0 then
		list[1] = "default"
	end
	return list
end

function ConfigManager:SaveAutoSave()
	local json = self:Serialize()
	self._memoryAutoSave = json
	if Env.HasFileSystem then
		Env.writeFile(self.AutoSavePath, json)
	end
end

function ConfigManager:LoadAutoSave()
	local json = Env.HasFileSystem and Env.readFile(self.AutoSavePath) or self._memoryAutoSave
	if not json then
		return false
	end
	return self:Deserialize(json, true)
end

function ConfigManager:ExportClipboard()
	local json = self:Serialize()
	local ok = Env.setClipboard(json)
	return ok, json
end

return ConfigManager
