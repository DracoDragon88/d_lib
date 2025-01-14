if not _VERSION:find('5.4') then error('Lua 5.4 must be enabled in the resource manifest!', 2) end

local resourceName = GetCurrentResourceName()
local d_lib = 'd_lib'

-- Some people have decided to load this file as part of d_lib's fxmanifest?
if resourceName == d_lib then return end

if dlib and dlib.name == d_lib then
    error(("Cannot load d_lib more than once.\n\tRemove any duplicate entries from '@%s/fxmanifest.lua'"):format(resourceName))
end

local export = exports[d_lib]

if GetResourceState(d_lib) ~= 'started' then
    error('^1d_lib must be started before this resource.^0', 0)
end

local status = export.hasLoaded()

if status ~= true then error(status, 2) end

-- Ignore invalid types during msgpack.pack (e.g. userdata)
msgpack.setoption('ignore_invalid', true)

-----------------------------------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------------------------------

local LoadResourceFile = LoadResourceFile
local context = IsDuplicityVersion() and 'server' or 'client'

function noop() end

local function loadModule(self, module)
    local dir = ('imports/%s'):format(module)

    local chunk = LoadResourceFile(d_lib, ('%s/%s.lua'):format(dir, context))
    local shared = LoadResourceFile(d_lib, ('%s/shared.lua'):format(dir))

    if shared then
        chunk = (chunk and ('%s\n%s'):format(shared, chunk)) or shared
    end

    if chunk then
        local fn, err = load(chunk, ('@@d_lib/imports/%s/%s.lua'):format(module, context))

        if not fn or err then
            return error(('\n^1Error importing module (%s): %s^0'):format(dir, err), 3)
        end

        local result = fn()
        self[module] = result or noop
        return self[module]
    end
end

-----------------------------------------------------------------------------------------------
-- API
-----------------------------------------------------------------------------------------------

local function call(self, index, ...)
    local module = rawget(self, index)

    if not module then
        self[index] = noop
        module = loadModule(self, index)

        if not module then
            local function method(...)
                return export[index](nil, ...)
            end

            if not ... then
                self[index] = method
            end

            return method
        end
    end

    return module
end

local dlib = setmetatable({
    name = d_lib,
    context = context,
    onCache = function(key, cb)
        AddEventHandler(('d_lib:cache:%s'):format(key), cb)
    end
}, {
    __index = call,
    __call = call,
})

_ENV.dlib = dlib

-- Override standard Lua require with our own.
require = dlib.require

local intervals = {}
--- Dream of a world where this PR gets accepted.
---@param callback function | number
---@param interval? number
---@param ... any
function SetInterval(callback, interval, ...)
    interval = interval or 0

    if type(interval) ~= 'number' then
        return error(('Interval must be a number. Received %s'):format(json.encode(interval --[[@as unknown]])))
    end

    local cbType = type(callback)

    if cbType == 'number' and intervals[callback] then
        intervals[callback] = interval or 0
        return
    end

    if cbType ~= 'function' then
        return error(('Callback must be a function. Received %s'):format(cbType))
    end

    local args, id = { ... }

    Citizen.CreateThreadNow(function(ref)
        id = ref
        intervals[id] = interval or 0
        repeat
            interval = intervals[id]
            Wait(interval)
            callback(table.unpack(args))
        until interval < 0
        intervals[id] = nil
    end)

    return id
end

---@param id number
function ClearInterval(id)
    if type(id) ~= 'number' then
        return error(('Interval id must be a number. Received %s'):format(json.encode(id --[[@as unknown]])))
    end

    if not intervals[id] then
        return error(('No interval exists with id %s'):format(id))
    end

    intervals[id] = -1
end

--[[
    lua language server doesn't support generics when using @overload
    see https://github.com/LuaLS/lua-language-server/issues/723
    this function stub allows the following to work

    local key = cache('key', function() return 'abc' end) -- fff: 'abc'
    local game = cache.game -- game: string
]]

---@generic T
---@param key string
---@param func fun(...: any): T
---@param timeout? number
---@return T
---Caches the result of a function, optionally clearing it after timeout ms.
function cache(key, func, timeout) end

local cache = setmetatable({ game = GetGameName(), resource = resourceName }, {
    __index = context == 'client' and function(self, key)
        AddEventHandler(('d_lib:cache:%s'):format(key), function(value)
            self[key] = value
        end)

        return rawset(self, key, export.cache(nil, key) or false)[key]
    end or nil,

    __call = function(self, key, func, timeout)
        local value = rawget(self, key)

        if not value then
            value = func()

            rawset(self, key, value)

            if timeout then SetTimeout(timeout, function() self[key] = nil end) end
        end

        return value
    end,
})

_ENV.cache = cache

for i = 1, GetNumResourceMetadata(cache.resource, 'd_lib') do
    local name = GetResourceMetadata(cache.resource, 'd_lib', i - 1)

    if not rawget(lib, name) then
        local module = loadModule(lib, name)

        if type(module) == 'function' then pcall(module) end
    end
end

if Locale then return end -- Don't load Locale if it allready exists

--- @class Locale
Locale = {}
Locale.__index = Locale

local function translateKey(phrase, subs)
    if type(phrase) ~= 'string' then
        error('TypeError: translateKey function expects arg #1 to be a string')
    end

    -- Substituions
    if not subs then
        return phrase
    end

    -- We should be escaping gsub just in case of any
    -- shenanigans with nested template patterns or injection

    -- Create and copy our return string
    local result = phrase

    -- Initial Scan over result looking for substituions
    for k, v in pairs(subs) do
        local templateToFind = '%%{' .. k .. '}'
        result = result:gsub(templateToFind, tostring(v)) -- string to allow all types
    end

    return result
end

--- Constructor function for a new Locale class instance
--- @param opts table<string, any> - Constructor opts param
--- @return Locale
function Locale.new(_, opts)
    local self = setmetatable({}, Locale)

    self.fallback = opts.fallbackLang and Locale:new({
        warnOnMissing = false,
        phrases = opts.fallbackLang.phrases,
    }) or false

    self.warnOnMissing = type(opts.warnOnMissing) ~= 'boolean' and true or opts.warnOnMissing

    self.phrases = {}
    self:extend(opts.phrases or {})

    return self
end

--- Method for extending an instances phrases map. This is also, used
--- internally for initial population of phrases field.
--- @param phrases table<string, string> - Table of phrase definitions
--- @param prefix string | nil - Optional prefix used for recursive calls
--- @return nil
function Locale:extend(phrases, prefix)
    for key, phrase in pairs(phrases) do
        local prefixKey = prefix and ('%s.%s'):format(prefix, key) or key
        -- If this is a nested table, we need to go reeeeeeeeeeeecursive
        if type(phrase) == 'table' then
            self:extend(phrase, prefixKey)
        else
            self.phrases[prefixKey] = phrase
        end
    end
end

--- Clear locale instance phrases
--- Might be useful for memory management of large phrase maps.
--- @return nil
function Locale:clear()
    self.phrases = {}
end

--- Clears all phrases and replaces it with the passed phrases table
--- @param phrases table<string, any>
function Locale:replace(phrases)
    phrases = phrases or {}
    self:clear()
    self:extend(phrases)
end

--- Gets & Sets a locale depending on if an argument is passed
--- @param newLocale string - Optional new locale to set
--- @return string
function Locale:locale(newLocale)
    if (newLocale) then
        self.currentLocale = newLocale
    end
    return self.currentLocale
end

--- Primary translation method for a phrase of given key
--- @param key string - The phrase key to target
--- @param subs table<string, any> | nil
--- @return string
function Locale:t(key, subs)
    local phrase, result
    subs = subs or {}

    -- See if the passed key resolves to a valid phrase string
    if type(self.phrases[key]) == 'string' then
        phrase = self.phrases[key]
        -- At this point we know whether the phrase does not exist for this key
    else
        if self.warnOnMissing then
            print(('^3Warning: Missing phrase for key: "%s"'):format(key))
        end
        if self.fallback then
            return self.fallback:t(key, subs)
        end
        result = key
    end

    if type(phrase) == 'string' then
        result = translateKey(phrase, subs)
    end

    return result
end

--- Check if a phrase key has already been defined within the Locale instance phrase maps.
--- @return boolean
function Locale:has(key)
    return self.phrases[key] ~= nil
end

--- Will remove phrase keys from a Locale instance, using recursion/
--- @param phraseTarget string | table
--- @param prefix string
function Locale:delete(phraseTarget, prefix)
    -- If the target is a string, we know that this is the end
    -- of nested table tree.
    if type(phraseTarget) == 'string' then
        self.phrases[phraseTarget] = nil
    else
        for key, phrase in pairs(phraseTarget) do
            local prefixKey = prefix and prefix .. '.' .. key or key

            if type(phrase) == 'table' then
                self:delete(phrase, prefixKey)
            else
                self.phrases[prefixKey] = nil
            end
        end
    end
end
