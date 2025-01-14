-- Add additional functions to the standard table library

---@class dtable : tablelib
dlib.table = table
local pairs = pairs

---@param tbl table
---@param value any
---@return boolean
---Checks if tbl contains the given values. Only intended for simple values and unnested tables.
local function contains(tbl, value)
	if type(value) ~= 'table' then
		for _, v in pairs(tbl) do
			if v == value then return true end
		end
	else
		local matched_values = 0
		local values = 0
		for _, v1 in pairs(value) do
			values += 1

			for _, v2 in pairs(tbl) do
				if v1 == v2 then matched_values += 1 end
			end
		end
		if matched_values == values then return true end
	end

	return false
end

---@param t1 any
---@param t2 any
---@return boolean
---Compares if two values are equal, iterating over tables and matching both keys and values.
local function table_matches(t1, t2)
	local type1, type2 = type(t1), type(t2)

	if type1 ~= type2 then return false end
	if type1 ~= 'table' and type2 ~= 'table' then return t1 == t2 end

	for k1,v1 in pairs(t1) do
	   local v2 = t2[k1]
	   if v2 == nil or not table_matches(v1,v2) then return false end
	end

	for k2,v2 in pairs(t2) do
	   local v1 = t1[k2]
	   if v1 == nil or not table_matches(v1,v2) then return false end
	end

	return true
end

---@generic T
---@param tbl T
---@return T
---Recursively clones a table to ensure no table references.
local function table_deepclone(tbl)
	tbl = table.clone(tbl)

	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			tbl[k] = table_deepclone(v)
		end
	end

	return tbl
end

---@param t1 table
---@param t2 table
---@param addDuplicateNumbers boolean? add duplicate number keys together if true, replace if false. Defaults to true.
---@return table
---Merges two tables together. Defaults to adding duplicate keys together if they are numbers, otherwise they are overriden.
local function table_merge(t1, t2, addDuplicateNumbers)
    if addDuplicateNumbers == nil then addDuplicateNumbers = true end
    for k, v in pairs(t2) do
        local type1 = type(t1[k])
        local type2 = type(v)

		if type1 == 'table' and type2 == 'table' then
            table_merge(t1[k], v, addDuplicateNumbers)
        elseif addDuplicateNumbers and (type1 == 'number' and type2 == 'number') then
            t1[k] += v
		else
			t1[k] = v
        end
    end

    return t1
end

local frozenNewIndex = function(self) error(('cannot set values on a frozen table (%s)'):format(self), 2) end
local _rawset = rawset

---@param tbl table
---@param index any
---@param value any
---@return table
function rawset(tbl, index, value)
    if table.isfrozen(tbl) then
        frozenNewIndex(tbl)
    end

    return _rawset(tbl, index, value)
end

---Makes a table read-only, preventing further modification. Unfrozen tables stored within `tbl` are still mutable.
---@generic T : table
---@param tbl T
---@return T
local function table_freeze(tbl)
    local copy = table.clone(tbl)
    local metatbl = getmetatable(tbl)

    table.wipe(tbl)
    setmetatable(tbl, {
        __index = metatbl and setmetatable(copy, metatbl) or copy,
        __metatable = 'readonly',
        __newindex = frozenNewIndex,
        __len = function() return #copy end,
        ---@diagnostic disable-next-line: redundant-return-value
        __pairs = function() return next, copy end,
    })

    return tbl
end

---Return true if `tbl` is set as read-only.
---@param tbl table
---@return boolean
local function table_isfrozen(tbl)
    return getmetatable(tbl) == 'readonly'
end

---Shuffle table
---@param t table
---@return table
function table_shuffle(tbl)
	local s = {}
	for i = 1, #tbl do s[i] = tbl[i] end
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		s[i], s[j] = s[j], s[i]
	end
	return s
end

-- For ox_lib compatibility
if not table.contains then table.contains = contains end
if not table.matches then table.matches = table_matches end
if not table.deepclone then table.deepclone = table_deepclone end
if not table.merge then table.merge = table_merge end
if not table.freeze then table.freeze = table_freeze end
if not table.isfrozen then table.isfrozen = table_isfrozen end
if not table.shuffle then table.shuffle = table_shuffle end

return dlib.table
