dlib.BlockPool = function(centerPoint, prisonMin, prisonMax, radius)
    if type(centerPoint) == 'vector3' and type(prisonMin) == 'vector3' and type(prisonMax) == 'vector3' then
        local radiusSize = (type(radius) == 'number' and radius or 20.0)

        ClearAreaOfPeds(centerPoint.x, centerPoint.y, centerPoint.z, radiusSize * 10, false)
        if not DoesScenarioBlockingAreaExist(prisonMin, prisonMax) then
            AddScenarioBlockingArea(centerPoint - radiusSize, centerPoint + radiusSize, false, true, true, true)
            AddPopMultiplierArea(centerPoint - radiusSize, centerPoint + radiusSize, 0.0, 0.0, false)
            SetPedNonCreationArea(centerPoint - radiusSize, centerPoint + radiusSize)
            SetAllVehicleGeneratorsActiveInArea(prisonMin, prisonMax, false, false)
            ClearAreaOfPeds(centerPoint.x, centerPoint.y, centerPoint.z, radiusSize * 10, false)
        end
    end
end

CreateThread(function()
    for i, v in ipairs(Config.BlockPool) do
        dlib.BlockPool(v.center, v.min, v.max, v.radius)
    end
end)
