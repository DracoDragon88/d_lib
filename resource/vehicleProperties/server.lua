---@param vehicle number
---@param props VehicleProperties
---@diagnostic disable-next-line: duplicate-set-field
function dlib.setVehicleProperties(vehicle, props)
    Entity(vehicle).state:set('d_lib:setVehicleProperties', props, true)
end
