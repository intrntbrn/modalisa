-- the mod map keeps track of all root modifier states
local M = {}

local dump = require("modalisa.lib.vim").inspect

local function set(self, key, mods, overwrite_only)
	for _, mod in pairs(mods) do
		if not overwrite_only or not (self.map[mod] == nil) then
			self.map[mod] = true
		end
	end
	local converted_key = self.conversion[key]

	-- key is actually a mod (e.g. Super_L -> Mod4)
	if converted_key then
		if not overwrite_only or not (self.map[converted_key] == nil) then
			self.map[converted_key] = true
		end
	end
end

function M:new(key, mods, modmap)
	local inst = {}
	inst.map = {}
	inst.conversion = modmap
	set(inst, key, mods, false)
	return setmetatable(inst, {
		__index = M,
	})
end

function M:press(key, mods)
	-- do not set pressed for mods that we don't care about
	return set(self, key, mods, true)
end

function M:release(key)
	local converted_key = self.conversion[key]
	-- key is actually a mod (e.g. Super_L -> Mod4)
	if converted_key then
		if not (self.map[converted_key] == nil) then
			self.map[converted_key] = false
		end
	end
end

function M:has_pressed_mods()
	for _, m in pairs(self.map) do
		if m then
			return true
		end
	end
	return false
end

function M:get_pressed_mods()
	local pressed_mods = {}
	for mod, is_pressed in pairs(self.map or {}) do
		if is_pressed then
			table.insert(pressed_mods, mod)
		end
	end
	return pressed_mods
end

return setmetatable(M, {
	__call = function(self, ...)
		return self:new(...)
	end,
	__tostring = function()
		if M.mod then
			return dump(M.mod)
		end
		return "nil"
	end,
})
