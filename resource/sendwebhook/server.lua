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
    if data.anticheat then data.webhook = 'anticheat' end

    local _webhook = (data.webhook):find('https://') ~= nil and data.webhook or Config.Webhooks[data.webhook]
    local _color = data.color

    if type(data.color) ~= 'number' then _color = Config.DiscordColors[data.color] or Config.DiscordColors['default'] end
    if GetConvarInt('test_server', 0) == 1 and (data.bypasstest == nil or data.bypasstest == false) then
        _webhook = Config.Webhooks['testwebhook']; data.title = '(TEST) '..(data.title or 'No Title')
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
                ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ')
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

        embed[1]["footer"] = {["text"] = 'd_lib @ '..Config.ServerName,["icon_url"] = "https://assets.dracomail.net/draco-fire.png"}
        PerformHttpRequest(_webhook, function(err, text, headers) end, 'POST', json.encode({
            username = data.username or Config.ServerName.." Logs",
            avatar_url = (data.anticheat and 'https://assets.dracomail.net/ghost.png' or Config.ServerLogo),
            embeds = embed
        }), { ['Content-Type'] = 'application/json'})
    end
end