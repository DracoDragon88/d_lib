dlib.framework = {}

local QBCore
local ESX
TriggerEvent("__cfx_export_qb-core_GetCoreObject", function(getCore) QBCore = getCore() end)
TriggerEvent("__cfx_export_es_extended_getSharedObject", function(getCore) ESX = getCore() end)

function dlib.framework.Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    if QBCore then
        QBCore.Functions.Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    else
        dlib.progressbar.Progress({ name = name:lower(), duration = duration, label = label, useWhileDead = useWhileDead, canCancel = canCancel, controlDisables = disableControls,
            animation = animation, prop = prop, propTwo = propTwo }, function(cancelled)
            if not cancelled then
                if onFinish then
                    onFinish()
                end
            else
                if onCancel then
                    onCancel()
                end
            end
        end)
    end
end

---Has Item Amount in Inventory
---@param item string
---@param amount integer
---@return boolean
function dlib.framework.HasItem(item, amount)
    if amount == nil then amount = 1 end

    if GetResourceState('qb-inventory') == 'started' or
       GetResourceState('ps-inventory') == 'started' then
        return QBCore.Functions.HasItem(item, amount)
    elseif GetResourceState('qs-inventory') == 'started' then
        return exports['qs-inventory']:Search(item) >= amount
    elseif GetResourceState('ox_inventory') == 'started' then
        return exports['ox_inventory']:GetItemCount(item) >= amount
    end

    return false
end

---Send Framework Notify
---@param type string
---@param title string
---@param text string
---@param length integer
function dlib.framework.Notify(type, title, text, length)
    if QBCore then
        QBCore.Functions.Notify(text, type, length)
    else

    end
end

---Get PlayerData
---@return table
function dlib.framework.PlayerData()
    local PlayerData = {}
    if QBCore then
        local PlyData = QBCore.Functions.GetPlayerData()
        if not PlyData?.charinfo?.firstname then return PlayerData end

        PlayerData.firstname = PlyData.charinfo?.firstname
        PlayerData.lastname = PlyData.charinfo?.lastname
        PlayerData.gender = PlyData.charinfo?.gender
        PlayerData.job = PlyData.job
        PlayerData.gang = PlyData.gang
        PlayerData.citizenid = PlyData.citizenid
        PlayerData.license = PlyData.license
        PlayerData.injail = PlyData.metadata?['injail']
        PlayerData.ishandcuffed = PlyData.metadata?['ishandcuffed']
        PlayerData.isdead = PlyData.metadata?['isdead']
        PlayerData.inlaststand = PlyData.metadata?['inlaststand']
    else
        local PlyData = ESX.GetPlayerData()
        if not PlyData?.firstName then return PlayerData end

        PlayerData.firstname = PlyData.firstName
        PlayerData.lastname = PlyData.lastName
        PlayerData.gender = PlyData.sex
        PlayerData.job = PlyData.job
        PlayerData.gang = PlyData.gang or nil
        PlayerData.citizenid = PlyData.identifier
        PlayerData.license = PlyData.identifier
        PlayerData.injail = LocalPlayer.state.injail or false
        PlayerData.ishandcuffed = LocalPlayer.state.isHandcuffed or false
        PlayerData.isdead = LocalPlayer.state.isDead or false
        PlayerData.inlaststand = LocalPlayer.state.isLaststand or false
    end
    return PlayerData
end

function dlib.framework.ToggleDuty()
    if QBCore then
        TriggerServerEvent("QBCore:ToggleDuty")
    else

    end
end

---Get Framework Plate
---@param veh entity
---@return string
function dlib.framework.GetPlate(veh)
    if QBCore then
        return QBCore.Functions.GetPlate(veh)
    else
        local plate = GetVehicleNumberPlateText(veh)
        return string.gsub(plate, '^%s*(.-)%s*$', '%1')
    end
end

---Set Vehicle Fuel Level
---@param vehicle any
---@param fuel any
---@return boolean
function dlib.framework.VehicleSetFuel(vehicle, fuel)
    if not DoesEntityExist(vehicle) then return false end

    if GetResourceState('LegacyFuel') == 'started' then
        exports['LegacyFuel']:SetFuel(vehicle, fuel)
    elseif GetResourceState('ps-fuel') == 'started' then
        exports['ps-fuel']:SetFuel(vehicle, fuel)
    elseif GetResourceState('lj-fuel') == 'started' then
        exports['lj-fuel']:SetFuel(vehicle, fuel)
    elseif GetResourceState('cdn-fuel') == 'started' then
        exports['cdn-fuel']:SetFuel(vehicle, fuel)
    elseif GetResourceState('hyon_gas_station') == 'started' then
        exports['hyon_gas_station']:SetFuel(vehicle, fuel)
    elseif GetResourceState('okokGasStation') == 'started' then
        exports['okokGasStation']:SetFuel(vehicle, fuel)
    elseif GetResourceState('nd_fuel') == 'started' then
        exports['nd_fuel']:SetFuel(vehicle, fuel)
    elseif GetResourceState('myFuel') == 'started' then
        exports['myFuel']:SetFuel(vehicle, fuel)
    elseif GetResourceState('ox_fuel') == 'started' then
        Entity(vehicle).state.fuel = fuel
    end

    SetVehicleFuelLevel(vehicle, fuel + 0.0)
end

---Give Key to Vehicle
---@param plate string
---@param vehicleEntity any
function dlib.framework.VehicleGiveKeys(plate, vehicleEntity)
    if GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerEvent("vehiclekeys:client:SetOwner", plate)
    elseif GetResourceState('jaksam-vehicles-keys') == 'started' then
        TriggerServerEvent("vehicles_keys:selfGiveVehicleKeys", plate)
    elseif GetResourceState('mk_vehiclekeys') == 'started' then
        exports["mk_vehiclekeys"]:AddKey(vehicleEntity)
    elseif GetResourceState('qs-vehiclekeys') == 'started' then
        local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicleEntity))
        exports['qs-vehiclekeys']:GiveKeys(plate, model)
    elseif GetResourceState('wasabi_carlock') == 'started' then
        exports['wasabi_carlock']:GiveKey(plate)
    elseif GetResourceState('cd_garage') == 'started' then
        TriggerEvent('cd_garage:AddKeys', plate)
    elseif GetResourceState('qb-inventory') == 'started' then
        TriggerServerEvent("okokGarage:GiveKeys", plate)
    elseif GetResourceState('t1ger_keys') == 'started' then
        TriggerServerEvent('t1ger_keys:updateOwnedKeys', plate, true)
    end

    -- Standalone
end

---@param item string
---@return string
function dlib.framework.ItemLabel(item)
    if QBCore then
        return QBCore.Shared.Items[item]?.label or '*'..item
    end

    return item
end

---@param model string
---@return string
function dlib.framework.VehicleLabel(model)
    if QBCore then
        return QBCore.Shared.Vehicles[model]?.name
    end

    return GetDisplayNameFromVehicleModel(model)
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