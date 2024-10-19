---@type ArrayList
local ArrayList = require "Assets/1ab0rat0ry/RWLab/utils/ArrayList.out"

---@class Consist
---@field public length number
---@field public vehicleCount number
---@field public vehicles ArrayList
local Consist = {
    length = 0,
    vehicleCount = 0,
    vehicles = {}
}
Consist.__index = Consist

---@return Consist
function Consist:new()
    ---@type Consist
    local obj = {
        vehicles = ArrayList:new()
    }
    obj = setmetatable(obj, self)

    return obj
end

---Adds vehicle to the end.
---@param vehicle Vehicle
function Consist:addVehicle(vehicle)
    self.vehicleCount = self.vehicleCount + 1
    self.vehicles:add(vehicle)
end

---Updates all vehicles in consist and propagates brake pipe.
---@param timeDelta number
function Consist:update(timeDelta)
    local simulationSteps = math.floor(60 * timeDelta)
    local simulationPartialSteps = 60 * timeDelta - simulationSteps

    for i, vehicle in ipairs(self.vehicles:reversed()) do
        local nextVehicle = self.vehicles.elements[self.vehicleCount - i]

        if nextVehicle == nil then break end
        vehicle.brakePipe:equalize(nextVehicle.brakePipe, timeDelta, nil, 100)
    end

    for _, vehicle in ipairs(self.vehicles.elements) do
        vehicle:update(timeDelta)
    end
end

---Calculates brake force of the whole consist.
---@return number brake force as number between `0` and `1`
function Consist:getBrakeControl()
    local brakeControlSum = 0

    for _, v in ipairs(self.vehicles.elements) do
        brakeControlSum = brakeControlSum + v:getBrakeControl()
    end

    return brakeControlSum / self.vehicleCount
end

return Consist