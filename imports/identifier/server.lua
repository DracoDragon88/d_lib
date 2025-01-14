dlib.identifier = {}
---Get Player Identifiers
---@param source number
---@return table
dlib.identifier.GetIdent = function(source)
    local IDS = {}
    for k,v in pairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            IDS.steam = v
        elseif string.sub(v, 1, string.len("license:")) == "license:" then
            IDS.license = v
        elseif string.sub(v, 1, string.len("license2:")) == "license2:" then
            IDS.license2 = v
        elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
            IDS.xbl = v
        elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
            IDS.ip = v
        elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
            IDS.discord = v
        elseif string.sub(v, 1, string.len("live:")) == "live:" then
            IDS.live = v
        end
    end
    return IDS
end

---Get Players Steam Hex
---@param source number
---@param trim boolean Removes the 'steam:'
---@param toID boolean Converts to Steam64 ID
---@return string
dlib.identifier.LoadSteamIdent = function(source, trim, toID)
    local steam = dlib.identifier.GetIdent(source).steam

    if steam and (trim or toID) then
        steam = steam:gsub("steam:","")
        if toID then steam = tonumber(steam,16) end
    end

    return steam
end

---Get Players Discord Id
---@param source number
---@param trim boolean Removes the 'discord:' 
---@return string
dlib.identifier.LoadDiscordIdent = function(source, trim)
    local discord = dlib.identifier.GetIdent(source).discord

    if discord and trim then
        discord = discord:gsub("discord:","")
    end

    return discord
end

return dlib.identifier