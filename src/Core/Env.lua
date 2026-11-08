local Services = require("Core/Services")

local Env = {}

local uis = Services.UserInputService
Env.IsMobile = uis ~= nil and uis.TouchEnabled and not uis.KeyboardEnabled

function Env.getGlobalEnv()
	if type(getgenv) == "function" then
		local ok, g = pcall(getgenv)
		if ok and type(g) == "table" then
			return g
		end
	end
	return _G
end

function Env.restoreIdentity()
	local set = setthreadidentity or setidentity or (type(syn) == "table" and syn.set_thread_identity)
	if type(set) == "function" then
		pcall(set, 8)
	end
end

function Env.mountGui(screenGui)
	Env.restoreIdentity()
	if type(syn) == "table" and type(syn.protect_gui) == "function" then
		pcall(syn.protect_gui, screenGui)
	elseif type(protect_gui) == "function" then
		pcall(protect_gui, screenGui)
	elseif type(protectgui) == "function" then
		pcall(protectgui, screenGui)
	end

	local targets = {}
	if type(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and typeof(hui) == "Instance" then
			targets[#targets + 1] = hui
		end
	end
	if Services.CoreGui then
		targets[#targets + 1] = Services.CoreGui
	end
	local lp = Services.Players and Services.Players.LocalPlayer
	if lp then
		local okPg, pg = pcall(function()
			return lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 2)
		end)
		if okPg and pg then
			targets[#targets + 1] = pg
		end
	end

	for _, parent in ipairs(targets) do
		local ok = pcall(function()
			screenGui.Parent = parent
		end)
		if ok and screenGui.Parent == parent then
			return parent
		end
	end
	return nil
end

Env.HasFileSystem = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"

function Env.ensureFolder(path)
	if not path or path == "" then
		return false
	end
	if type(makefolder) ~= "function" or type(isfolder) ~= "function" then
		return false
	end
	local current = nil
	for part in tostring(path):gmatch("[^/\\]+") do
		current = current and (current .. "/" .. part) or part
		local ok, exists = pcall(isfolder, current)
		if ok and not exists then
			pcall(makefolder, current)
		end
	end
	return true
end

function Env.writeFile(path, content)
	if not Env.HasFileSystem then
		return false
	end
	local folder = tostring(path):match("^(.*)[/\\][^/\\]+$")
	if folder then
		Env.ensureFolder(folder)
	end
	local ok = pcall(writefile, path, tostring(content))
	return ok
end

function Env.readFile(path)
	if not Env.HasFileSystem then
		return nil
	end
	local okExists, exists = pcall(isfile, path)
	if not (okExists and exists) then
		return nil
	end
	local okRead, data = pcall(readfile, path)
	if okRead and type(data) == "string" then
		return data
	end
	return nil
end

function Env.deleteFile(path)
	if not Env.HasFileSystem or type(delfile) ~= "function" then
		return false
	end
	local okExists, exists = pcall(isfile, path)
	if okExists and exists then
		return (pcall(delfile, path))
	end
	return false
end

function Env.listFiles(folder)
	if not Env.HasFileSystem or type(listfiles) ~= "function" or type(isfolder) ~= "function" then
		return {}
	end
	local okFolder, exists = pcall(isfolder, folder)
	if not (okFolder and exists) then
		return {}
	end
	local okList, list = pcall(listfiles, folder)
	if okList and type(list) == "table" then
		return list
	end
	return {}
end

function Env.setClipboard(text)
	local fn = setclipboard or toclipboard or set_clipboard or (type(Clipboard) == "table" and Clipboard.set)
	if type(fn) == "function" then
		local ok = pcall(fn, tostring(text))
		return ok
	end
	return false
end

return Env
