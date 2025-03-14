local logQueue = {}

local function sendLogQueue(name)
    local queue = logQueue[name] or {}
    if #queue > 0 then
        local postData = {
            username = Config.ServerName.." Logs",
            avatar_url = (name == 'anticheat' and 'https://assets.dracomail.net/ghost.png' or Config.ServerLogo),
            embeds = {}
        }
        for i = 1, #queue do
            table.insert(postData.embeds, queue[i].data[1])
        end
        PerformHttpRequest(queue[1].webhook, function(err, text, headers) end, 'POST', json.encode(postData), { ['Content-Type'] = 'application/json' })
        logQueue[name] = {}
    end
end

dlib.SendWebhook = function(data)
    --[[
        data = {
            webhook = 'default',
            anticheat = false,
            color = 16711680,
            title = 'Title',
            desc = 'description',
            image = 'https://assets.dracomail.net/draco-fire.png',
            author = {
                name = 'Draco'
            },
            source = source
        }
    ]]
    local FiveManageAPIKey = GetConvar('FIVEMANAGE_LOGS_API_KEY', 'false')
    if FiveManageAPIKey == 'false' then
        if data.anticheat then data.webhook = 'anticheat' end

        local _webhook = (data.webhook):find('https://') ~= nil and data.webhook or Config.Webhooks[data.webhook]
        local _color = data.color

        if type(data.color) ~= 'number' then _color = Config.DiscordColors[data.color] or Config.DiscordColors['default'] end
        if GetConvarInt('test_server', 0) == 1 and (data.bypasstest == nil or data.bypasstest == false) then
            data.webhook = 'testwebhook'
            data.title = '(TEST) '..(data.title or 'No Title')
            _webhook = Config.Webhooks['testwebhook'];
        end

        if not _webhook then
            _webhook = Config.Webhooks['default']
            dlib.print.warn("Webhook '"..data.webhook.."' does not exists")
        end

        if _webhook and _webhook ~= "" and data.desc ~= nil then
            local embed = {
                {
                    ["color"] = (data.anticheat and Config.DiscordColors['purple'] or _color),
                    ["title"] = "**".. (data.title or 'No Title') .."**",
                    ["description"] = data.desc or 'No Description',
                    ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ'),
                    ["footer"] = {["text"] = 'd_lib @ '..Config.ServerName,["icon_url"] = "https://assets.dracomail.net/draco-fire.png"}
                }
            }
            if data.author?.name then
                embed[1]["author"] = {
                    ["name"] = data.author.identifier and '<@'..data.author.identifier..'>' or data.author.name,
                    ["url"] = data.author.url or nil
                }
            elseif data.source then
                embed[1]["author"] = {
                    ["name"] = GetPlayerName(data.source).. "("..data.source..")"
                }
            end
            if data.thumbnail then
                embed[1]["thumbnail"] = {
                    ["url"] = data.thumbnail
                }
            end
            if data.image then
                embed[1]["image"] = {
                    ["url"] = data.image
                }
            end

            if type(data.source) == 'number' then
                local fields = {}
                local charData = dlib.framework.PlayerData(data.source)
                local ident = dlib.framework.GetIdentifier(data.source)
                local steam = dlib.identifier.LoadSteamIdent(data.source, true, true)
                local disc = dlib.identifier.LoadDiscordIdent(data.source, true)

                if charData?.firstname and charData?.lastname then
                    table.insert(fields, { name = 'Name', value = charData.firstname ..' '.. charData.lastname, inline = true })
                end
                if charData?.job?.label then
                    if charData.job.grade?.name and charData.job.grade?.level then
                        table.insert(fields, { name = 'Job', value = charData.job.label ..' - '.. charData.job.grade.name.. ' ('..charData.job.grade.level..')', inline = true })
                    elseif charData.job.grade?.name then
                        table.insert(fields, { name = 'Job', value = charData.job.label ..' - '.. charData.job.grade.name, inline = true })
                    else
                        table.insert(fields, { name = 'Job', value = charData.job.label, inline = true })
                    end
                end
                if charData?.gang?.label and charData?.gang?.name ~= 'none' then
                    table.insert(fields, { name = 'Gang', value = charData.gang.label ..' - '.. charData.gang.grade.name.. ' ('..charData.gang.grade.level..')', inline = true })
                end
                if ident then
                    table.insert(fields, { name = Config.Framework == 'QBCore' and 'CitizenID' or 'Identifier', value = ident, inline = true })
                end
                if steam then
                    table.insert(fields, { name = 'Steam', value = steam, inline = true })
                end
                if disc then
                    table.insert(fields, { name = 'Discord', value = '<@'..disc..'>', inline = true })
                end

                if next(fields) then
                    embed[1]["fields"] = fields
                end
            end

            if Config. data.webhook == nil or data.anticheat then 
                PerformHttpRequest(_webhook, function(err, text, headers) end, 'POST', json.encode({
                    username = data.username or Config.ServerName.." Logs",
                    avatar_url = (data.anticheat and 'https://assets.dracomail.net/ghost.png' or Config.ServerLogo),
                    embeds = embed
                }), { ['Content-Type'] = 'application/json'})
            else
                if not logQueue[data.webhook] then logQueue[data.webhook] = {} end
                table.insert(logQueue[data.webhook], { webhook = webHook, data = embed })

                if #logQueue[data.webhook] >= 10 then
                    sendLogQueue(data.webhook)
                end
            end
        end
    else
        local extraData = {
            level = data.tagEveryone and 'warn' or 'info', -- info, warn, error or debug
            message = data.title or 'No Title',       -- any string
            metadata = {                              -- a table or object with any properties you want
                description = data.desc or 'No Description',
                playerId = data.source,
            },
            resource = GetInvokingResource(),
        }

        if type(data.source) == 'number' then
            local charData = dlib.framework.PlayerData(data.source)
            local ident = dlib.framework.GetIdentifier(data.source)
            local steam = dlib.identifier.LoadSteamIdent(data.source, true, true)
            local disc = dlib.identifier.LoadDiscordIdent(data.source, true)

            if charData?.firstname and charData?.lastname then
                extraData.metadata['charName'] = charData.firstname ..' '.. charData.lastname
            end
            if charData?.job?.label then
                if charData.job.grade?.name and charData.job.grade?.level then
                    extraData.metadata['charJob'] = charData.job.label ..' - '.. charData.job.grade.name.. ' ('..charData.job.grade.level..')'
                elseif charData.job.grade?.name then
                    extraData.metadata['charJob'] = charData.job.label ..' - '.. charData.job.grade.name
                else
                    extraData.metadata['charJob'] = charData.job.label
                end
            end
            if charData?.gang?.label and charData?.gang?.name ~= 'none' then
                extraData.metadata['charGang'] = charData.gang.label ..' - '.. charData.gang.grade.name.. ' ('..charData.gang.grade.level..')'
            end
            if ident then
                extraData.metadata[(Config.Framework == 'QBCore' and 'CitizenID' or 'Identifier')] = ident
            end
            if steam then
                extraData.metadata['playerSteam'] = steam
            end
            if disc then
                extraData.metadata['playerDiscord'] = disc
            end

            extraData.metadata['playerLicense'] = GetPlayerIdentifierByType(data.source, 'license')
        end


        PerformHttpRequest('https://api.fivemanage.com/api/logs', function(statusCode, response, headers)
            -- Uncomment the following line to enable debugging
            -- print(statusCode, response, json.encode(headers))
        end, 'POST', json.encode(extraData), {
            ['Authorization'] = FiveManageAPIKey,
            ['Content-Type'] = 'application/json',
        })
    end
end

dlib.cron.new('* * * * *', function() -- Post the logs every minute
    for name, queue in pairs(logQueue) do
        sendLogQueue(name)
    end
end)

dlib.addCommand('dlibtestwebhook', {
    help = 'Test Your Discord Webhook For Logs',
    params = {},
    restricted = 'group.admin'
}, function(source, args, raw)
    dlib.SendWebhook({
        webhook = 'testwebhook',
        color = 16711680,
        title = 'Test Webhook',
        desc = 'Webhook setup successfully',
        image = 'https://assets.dracomail.net/draco-fire.png',
        author = {
            name = 'Draco'
        },
        source = source
    })
end)
