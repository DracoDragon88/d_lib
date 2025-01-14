-- Auto Detector
Citizen.CreateThread(function() -- Wait for all resources to be started
    if not Config.Framework then
        if GetResourceState('qb-core') == 'started' then
            Config.Framework = 'QBCore'
        elseif GetResourceState('es_extended') == 'started' then
            Config.Framework = 'ESX'
        else
            Config.Framework = "Standalone"
        end
    end

    if not Config.Inventory then
        if GetResourceState('qb-inventory') == 'started' then
            Config.Inventory = 'qb-inventory'
        elseif GetResourceState('qs-inventory') == 'started' then
            Config.Inventory = 'qs-inventory'
        elseif GetResourceState('ps-inventory') == 'started' then
            Config.Inventory = 'ps-inventory'
        elseif GetResourceState('ox_inventory') == 'started' then
            Config.Inventory = 'ox_inventory'
        else
            Config.Inventory = "Standalone"
        end
    end

    if not Config.FuelSystem then
        if GetResourceState('LegacyFuel') == 'started' then
            Config.FuelSystem = "LegacyFuel"
        elseif GetResourceState('ps-fuel') == 'started' then
            Config.FuelSystem = "ps-fuel"
        elseif GetResourceState('lj-fuel') == 'started' then
            Config.FuelSystem = "lj-fuel"
        elseif GetResourceState('cdn-fuel') == 'started' then
            Config.FuelSystem = "cdn-fuel"
        elseif GetResourceState('hyon_gas_station') == 'started' then
            Config.FuelSystem = "hyon_gas_station"
        elseif GetResourceState('okokGasStation') == 'started' then
            Config.FuelSystem = "okokGasStation"
        elseif GetResourceState('nd_fuel') == 'started' then
            Config.FuelSystem = "nd_fuel"
        elseif GetResourceState('myFuel') == 'started' then
            Config.FuelSystem = "myFuel"
        elseif GetResourceState('ox_fuel') == 'started' then
            Config.FuelSystem = "ox_fuel"
        else
            Config.FuelSystem = "Standalone"
        end
    end

    if not Config.VehicleKeys then
        if GetResourceState('qb-vehiclekeys') == 'started' then
            Config.VehicleKeys = "qb-vehiclekeys"
        elseif GetResourceState('jaksam-vehicles-keys') == 'started' then
            Config.VehicleKeys = "jaksam-vehicles-keys"
        elseif GetResourceState('mk_vehiclekeys') == 'started' then
            Config.VehicleKeys = "mk_vehiclekeys"
        elseif GetResourceState('qs-vehiclekeys') == 'started' then
            Config.VehicleKeys = "qs-vehiclekeys"
        elseif GetResourceState('wasabi_carlock') == 'started' then
            Config.VehicleKeys = "wasabi_carlock"
        elseif GetResourceState('cd_garage') == 'started' then
            Config.VehicleKeys = "cd_garage"
        elseif GetResourceState('qb-inventory') == 'started' then
            Config.VehicleKeys = "okokGarage"
        elseif GetResourceState('t1ger_keys') == 'started' then
            Config.VehicleKeys = "t1ger_keys"
        else
            Config.VehicleKeys = "Standalone"
        end
    end

    if IsDuplicityVersion() then
        local dlibLocale = GetConvar('dlib_locale', 'nil')
        if dlibLocale == 'nil' then
            dlibLocale = GetConvar('qb_locale', 'en')
            SetConvar('dlib_locale', dlibLocale)
            SetConvarReplicated('dlib_locale', dlibLocale)
            dlib.print.info('Creating Convar dlib_locale', dlibLocale)
        else
            dlib.print.info('Using Convar dlib_locale', dlibLocale)
        end

        dlib.print.info("^1[d_lib] ^3Framework: ^5"..Config.Framework.."^7")
        dlib.print.info("^1[d_lib] ^3Inventory: ^5"..Config.Inventory.."^7")
        dlib.print.info("^1[d_lib] ^3FuelSystem: ^5"..Config.FuelSystem.."^7")
        dlib.print.info("^1[d_lib] ^3VehicleKeys: ^5"..Config.VehicleKeys.."^7")
    end
end)