local Logger = require "Assets/1ab0rat0ry/RWLab/utils/Logger.out"
local ArrayList = require "Assets/1ab0rat0ry/RWLab/utils/ArrayList.out"

local logger = Logger:new(false, "BrakePipe.log")

local Consist = {
    length = 0,
    vehicleCount = 0,
    vehicles = ArrayList
}

function Consist:new()
    local o = setmetatable({}, self)
    self.__index = self
    o.vehicles = ArrayList:new()

    return o
end

function Consist:addVehicle(vehicle)
    self.vehicleCount = self.vehicleCount + 1
    self.vehicles:add(vehicle)
end

function Consist:update(timeDelta)
    local simulationSteps = math.floor(60 * timeDelta)
    local simulationPartialSteps = 60 * timeDelta - simulationSteps

    for j, vehicle in ipairs(self.vehicles:reversed()) do
        local nextVehicle = self.vehicles.elements[self.vehicleCount - j]

        if nextVehicle == nil then break end
        vehicle.brakePipe:equalize(nextVehicle.brakePipe, timeDelta, nil, 100)
        logger:info("K: "..j.." V: "..vehicle.brakePipe.pressure.." NV: "..nextVehicle.brakePipe.pressure.." NVA: "..nextVehicle.distributor.accelerationChamber.pressure)
    end

    for _, vehicle in ipairs(self.vehicles.elements) do
        vehicle:update(timeDelta)
    end
    logger:info("")
end

function Consist:getBrakeControl()
    local brakeControlSum = 0

    for _, v in ipairs(self.vehicles.elements) do
        brakeControlSum = brakeControlSum + v:getBrakeControl()
    end
    return brakeControlSum / self.vehicleCount
end

return Consist