local function OnPlayerLoaded()
    TriggerEvent('d-lib:Client:OnPlayerLoaded')
    TriggerServerEvent('d-lib:Server:OnPlayerLoaded')
end

local function OnPlayerUnload()
    TriggerServerEvent('d-lib:Server:OnPlayerUnload')
    TriggerEvent('d-lib:Client:OnPlayerUnload')
end

-- QBCore
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', OnPlayerLoaded)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', OnPlayerUnload)

-- ESX
RegisterNetEvent("esx:playerLoaded", OnPlayerLoaded)
RegisterNetEvent("esx:onPlayerLogout", OnPlayerUnload)

-- Standalone
CreateThread(function()
    repeat Wait(100) until Config.Framework
    if Config.Framework == 'Standalone' then
        Wait(25000) OnPlayerLoaded()
    end
end)
