dlib.callback.register('d-lib:server:getPlayerNamesNearby', function(source, players)
    local tbl = {}
    for k, v in pairs(players) do
        local PlayerData = dlib.framework.PlayerData(v.id)
        table.insert(tbl, {
            ['name'] = PlayerData.firstname .. ' ' .. PlayerData.lastname,
            ['id'] = v.id,
            ['cid'] = PlayerData.citizenid,
            ['identifier'] = PlayerData.license,
            ['gang'] = PlayerData.gang,
            ['job'] = PlayerData.job
        })
    end
    return tbl
end)
