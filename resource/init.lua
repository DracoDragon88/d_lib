local debug_getinfo = debug.getinfo

function noop() end

dlib = setmetatable({
    name = 'd_lib',
    context = IsDuplicityVersion() and 'server' or 'client',
}, {
    __newindex = function(self, key, fn)
        rawset(self, key, fn)

        if debug_getinfo(2, 'S').short_src:find('@d_lib/resource') then
            exports(key, fn)
        end
    end,

    __index = function(self, key)
        local dir = ('imports/%s'):format(key)

        local chunk = LoadResourceFile(self.name, ('%s/%s.lua'):format(dir, self.context))
        local shared = LoadResourceFile(self.name, ('%s/shared.lua'):format(dir))

        if shared then
            chunk = (chunk and ('%s\n%s'):format(shared, chunk)) or shared
        end

        if chunk then
            local fn, err = load(chunk, ('@@d_lib/%s/%s.lua'):format(key, self.context))

            if not fn or err then
                return error(('\n^1Error importing module (%s): %s^0'):format(dir, err), 3)
            end

            rawset(self, key, fn() or noop)

            return self[key]
        end
    end
})

cache = {
    resource = dlib.name,
    game = GetGameName(),
}

if not LoadResourceFile(dlib.name, 'html/index.html') then
    local err =
    '^1Unable to load UI. Download the latest release.'
    function dlib.hasLoaded() return err end

    error(err)
end

function dlib.hasLoaded() return true end

require = dlib.require
