dlib.lootmaker = {}

---@param t table
---@return number
---@return table
function dlib.lootmaker.createprocents(t)
    local s = dlib.table.shuffle(t)

    local _cache = 0
    for k,v in ipairs(s) do
        local _b = math.ceil(_cache + (v.procent*10))
        s[k].probability = {a=_cache, b=_b}
        _cache = _b
    end

    return s, _cache
end

---Get item from loot table
---@param t table loot table
---@return string|false item
---@return number qty
---@return table|false info
---@return table|false loottable
function dlib.lootmaker.createloot(t)
    if not t[1]?.probability then
        t = dlib.lootmaker.createprocents(t)
    end

    local rnd = math.random(1, 1000)
    local randItem, quantity, info, tab = false, 1, false, false
    for _,v in ipairs(t) do
        if (rnd > v.probability.a) and (rnd <= v.probability.b) then
            tab = v
            randItem = v.item
            if type(v.amount) == 'table' then
                quantity = math.random(v.amount[1],v.amount[2])
            elseif type(v.amount) == 'number' then
                quantity = v.amount
            end

            if v.metadata then info = v.metadata end
            break
        end
        Wait(1)
    end

    return randItem, quantity, info, tab
end

return dlib.lootmaker