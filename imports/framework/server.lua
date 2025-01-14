dlib.framework = {}

local QBCore
local ESX
TriggerEvent("__cfx_export_qb-core_GetCoreObject", function(getCore) QBCore = getCore() end)
TriggerEvent("__cfx_export_es_extended_getSharedObject", function(getCore) ESX = getCore() end)

---Give Item
---@param source any
---@param item string
---@param amount number
---@param slot? number|false
---@param info? table
---@return boolean
function dlib.framework.AddItem(source, item, amount, slot, info)
    local _amount = amount and tonumber(amount) or 1
    if _amount < 1 then return end
    if GetResourceState('qs-inventory') == 'started' then
        return exports['qs-inventory']:AddItem(source, item, _amount, slot, info)
    elseif GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:AddItem(source, item, _amount, info, slot)
    else
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        -- TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[item], "add")
        return qbPlayer.Functions.AddItem(item, _amount, slot, info)
    end
end

---Remove Item
---@param source any
---@param item string
---@param amount number
---@param slot? number|false
---@return boolean
function dlib.framework.RemoveItem(source, item, amount, slot)
    local _amount = amount and tonumber(amount) or 1
    if _amount < 1 then return end
    if GetResourceState('qs-inventory') == 'started' then
        return exports['qs-inventory']:RemoveItem(source, item, _amount, slot)
    elseif GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:RemoveItem(source, item, _amount, false, slot)
    else
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        -- TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[item], "remove")
        return qbPlayer.Functions.RemoveItem(item, _amount, slot)
    end
end

---Get Money
---@param source any
---@param moneytype string cash, bank
---@return number
function dlib.framework.GetMoney(source, moneytype)
    if QBCore then
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        return qbPlayer.Functions.GetMoney(moneytype) or 0
    elseif ESX then
        if moneytype == 'cash' then moneytype = 'money' end
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.getAccount(moneytype)?.money or 0
    end
end

---Add Money
---@param source any
---@param moneytype string cash, bank
---@param amount number
---@param reason string
---@return boolean
function dlib.framework.AddMoney(source, moneytype, amount, reason)
    if type(amount) ~= "number" or amount < 1 then return end
    if QBCore then
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        return qbPlayer.Functions.AddMoney(moneytype, amount, reason)
    elseif ESX then
        if moneytype == 'cash' then moneytype = 'money' end
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.addAccountMoney(moneytype, amount)
        return true
    end
end

---Remove Money
---@param source any
---@param moneytype string cash, bank
---@param amount number
---@param reason string
---@return boolean
function dlib.framework.RemoveMoney(source, moneytype, amount, reason)
    if type(amount) ~= "number" or amount < 1 then return end
    if QBCore then
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        return qbPlayer.Functions.RemoveMoney(moneytype, amount, reason)
    elseif ESX then
        if moneytype == 'cash' then moneytype = 'money' end
        local xPlayer = ESX.GetPlayerFromId(source)
        if dlib.framework.GetMoney(source, moneytype) >= amount then
            xPlayer.removeAccountMoney(moneytype, amount)
            return true
        end

        return false
    end
end

---Get Item By Name
---@param source any
---@param item table
function dlib.framework.GetItemByName(source, item)
    local _item

    if GetResourceState('ox_inventory') == 'started' then
        _item = exports['ox_inventory']:Search(source, 1, item)
        _item.info = _item.info or _item.metadata
    elseif QBCore then
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        _item = qbPlayer.Functions.GetItemByName(item)
    end

    return _item
end

---Set Item Metadata
---@param source any
---@param slot integer
---@param info table
function dlib.framework.SetItemMetadata(source, slot, info)
    if QBCore and GetResourceState('qb-inventory') == 'started' or
       GetResourceState('ps-inventory') == 'started' then
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        qbPlayer.PlayerData.items[slot].info = info
    elseif GetResourceState('qs-inventory') == 'started' then
        exports['qs-inventory']:SetItemMetadata(source, slot, info)
    elseif GetResourceState('ox_inventory') == 'started' then
        exports['ox_inventory']:SetMetadata(source, slot, info)
    else
        return
    end
end

---Get Identifier
---@param source any
---@return string
function dlib.framework.GetIdentifier(source)
    if QBCore then
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        return qbPlayer?.PlayerData?.citizenid
    end

    return dlib.identifier.GetIdent(source).license
end

---Get Source From Identifier
---@param identifier string
---@return number
function dlib.framework.IdentifierToSource(identifier)
    if QBCore then
        local qbPlayer = QBCore.Functions.GetPlayerByCitizenId(identifier)
        return qbPlayer?.PlayerData?.source
    end

    for _, src in ipairs(GetPlayers()) do
        local ident = dlib.identifier.GetIdent(src)
        if ident.license == identifier then
            return src
        end
    end
end

---Create Framwork Command
---@param name string
---@param help string
---@param arguments table
---@param argsrequired boolean
---@param callback fun(source: number, args: table, raw: string)
---@param permission any
---@param ... args
function dlib.framework.AddCommand(name, help, arguments, argsrequired, callback, permission, ...)
    if QBCore then
        QBCore.Commands.Add(name, help, arguments, argsrequired, callback, permission, ...)
    else
        dlib.addCommand(name, {help = help,params = arguments,restricted = 'group.'..permission}, callback, ...)
    end
end

---Framework Notify
---@param source any
---@param type string
---@param title string
---@param text string
---@param length? number
function dlib.framework.Notify(source, type, title, text, length)
    if QBCore then
        TriggerClientEvent("QBCore:Notify", source, text, type, length)
    elseif ESX then

    else

    end
end

---Create Useable Item
---@param item string
---@param cb function
function dlib.framework.CreateUseableItem(item, cb)
    if QBCore then
        QBCore.Functions.CreateUseableItem(item, cb)
    elseif ESX then
        ESX.RegisterUsableItem(item, cb)
    else

    end
end

function dlib.framework.GetCurrentCops()
    local amount = 0
    if QBCore then
        local qbPlayers = QBCore.Functions.GetQBPlayers()
        for _, qb in pairs(qbPlayers) do
            if qb and qb.PlayerData.job.type == 'leo' and qb.PlayerData.job.onduty then
                amount += 1
            end
        end
    elseif ESX then
        for _, src in ipairs(GetPlayers()) do
            local PlyData = ESX.GetPlayerFromId(src)
            if PlyData.job.name == 'police' then
                amount += 1
            end
        end
    else
        -- Standalone
    end
    return amount
end

---Get PlayerData
---@param source any
---@return table
function dlib.framework.PlayerData(source)
    local PlayerData = {}
    if QBCore then
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        if not qbPlayer then return {} end

        PlayerData = {
            firstname = qbPlayer.PlayerData.charinfo.firstname,
            lastname = qbPlayer.PlayerData.charinfo.lastname,
            gender = qbPlayer.PlayerData.charinfo.gender,
            job = qbPlayer.PlayerData.job,
            gang = qbPlayer.PlayerData.gang,
            citizenid = qbPlayer.PlayerData.citizenid,
            license = qbPlayer.PlayerData.license,
            source = qbPlayer.PlayerData.source,
            injail = qbPlayer.PlayerData.metadata['injail'],
            ishandcuffed = qbPlayer.PlayerData.metadata['ishandcuffed'],
            isdead = qbPlayer.PlayerData.metadata['isdead'],
            inlaststand = qbPlayer.PlayerData.metadata['inlaststand']
        }
    elseif ESX then
        local PlyData = ESX.GetPlayerFromId(source)
        if not PlyData then return {} end

        PlayerData = {
            firstname = PlyData.variables.firstName,
            lastname = PlyData.variables.lastName,
            gender = 1,
            job = PlyData.job,
            gang = nil,
            citizenid = PlyData.identifier,
            license = PlyData.identifier,
            source = source,
            injail = Player(source).state.injail or false,
            ishandcuffed = Player(source).state.ishandcuffed or false,
            isdead = Player(source).state.isdead or false,
            inlaststand = Player(source).state.inlaststand or false
        }
    end

    return PlayerData
end

function dlib.framework.HasPermission(source, permission)
    if QBCore then
        return QBCore.Functions.HasPermission(source, permission)
    end

    return IsPlayerAceAllowed(source, permission)
end

--- Returns the amount of cops online and on duty
---@return integer number - amount of cops
function dlib.framework.GetCurrentCops()
    local amount = 0
    if QBCore then
        local qbPlayers = QBCore.Functions.GetQBPlayers()
        for _, qb in pairs(qbPlayers) do
            if qb and qb.PlayerData.job.type == 'leo' and qb.PlayerData.job.onduty then
                amount += 1
            end
        end
    elseif ESX then
        for _, src in ipairs(GetPlayers()) do
            local PlyData = ESX.GetPlayerFromId(src)
            if PlyData.job.name == 'police' then
                amount += 1
            end
        end
    else
        -- Standalone
    end
    return amount
end

---@param item string
---@return string
function dlib.framework.ItemLabel(item)
    if QBCore then
        return QBCore.Shared.Items[item]?.label or '*'..item
    elseif ESX then
        return ESX.GetItemLabel(item)
    end

    return item
end

---@param model string
---@return string
function dlib.framework.VehicleLabel(model)
    if QBCore then
        return QBCore.Shared.Vehicles[model]?.name
    end

    return model
end

---@param weapon_hash any
---@return string
function dlib.framework.WeaponType(weapon_hash)
    if QBCore then
        return QBCore.Shared.Weapons[weapon_hash]?.weapontype or "none"
    end

    local Config = dlib.config()
    return Config.WeaponsList[weapon_hash]?.weapontype or "none"
end

return dlib.framework