-- Creator: Arif Rahman
-- Copyright (c) 2025 Arif Rahman. All rights reserved.

return [[local function ___()
	local c1, c2, c3
	local collectgarbage, getmetatable, setmetatable, coroutine, _VERSION, loadfile, tostring, tonumber, rawequal, package, require, xpcall, ipairs, dofile, string, rawset, rawlen, assert, select, rawget, print, pcall, debug, bit32, pairs, error, table, type, next, utf8, math, load, arg, os, io, _G = collectgarbage, getmetatable, setmetatable, coroutine, _VERSION, loadfile, tostring, tonumber, rawequal, package, require, xpcall, ipairs, dofile, string, rawset, rawlen, assert, select, rawget, print, pcall, debug, bit32, pairs, error, table, type, next, utf8, math, load, arg, os, io, _G
	local c4 = string.char
	local c5 = {}
	local c6 = {}
	local c7 = {}
	local c8 = 1
	local c9 = {}
	c9[1] = function(...)
		local n = {...}
		for i, v in n[4], n[1], nil do
			n[3] = n[3] .. c4[v + 1]
		end
		return n[3]
	end
	c1 = function(s)
		local m = s
		local v = m[#m - 1]
		local k = m[#m]
		m[#m - 1], m[#m] = nil, nil
		if not c5[v] then
			c5[v] = c9[c8](m, k, '', next)
		end
		return c5[v]
	end
	if not c2 then
		c2 = c7
	end
	return -- content()
end
return ___()]]