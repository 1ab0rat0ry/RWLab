-- Adapted from: 

local Logger = require "Assets/1ab0rat0ry/RWLab/utils/Logger.out"
local logger = Logger:new(false, "BrakePipe.log")

local Consist = {}

Consist.length = 0
Consist.vehicleCount = 0
Consist.vehicles = {}

function Consist:new()
    local o = setmetatable({}, self)
    self.__index = self
    o.vehicles = {}
    return o
end

function Consist:addVehicle(vehicle)
    self.vehicleCount = self.vehicleCount + 1
    self.vehicles[self.vehicleCount] = vehicle
end

function Consist:update(timeDelta)
    local simulationSteps = math.floor(60 * timeDelta)
    local simulationPartialSteps = 60 * timeDelta - simulationSteps

    for i = 1, simulationSteps, 1 do
        for k, vehicle in ipairs(self.vehicles) do
            local nextVehicle = self.vehicles[k + 1]

            if nextVehicle == nil then break end
            vehicle.brakePipe:equalize(nextVehicle.brakePipe, timeDelta, nil, 100)
            -- logger:info("K: "..k.." V: "..vehicle.brakePipe.pressure.." NV: "..nextVehicle.brakePipe.pressure.." NVA: "..nextVehicle.distributor.accelerationChamber.pressure)
        end
    end

    for k, vehicle in ipairs(self.vehicles) do
        local nextVehicle = self.vehicles[k + 1]

        if nextVehicle == nil then break end
        vehicle.brakePipe:equalize(nextVehicle.brakePipe, simulationPartialSteps, nil, 100)
        -- logger:info("K: "..k.." V: "..vehicle.brakePipe.pressure.." NV: "..nextVehicle.brakePipe.pressure.." NVA: "..nextVehicle.distributor.accelerationChamber.pressure)
    end

    for _, vehicle in ipairs(self.vehicles) do
        vehicle:update(timeDelta)
    end
    logger:info("")
end

function Consist:getBrakeControl()
    local brakeControlSum = 0

    for _, v in ipairs(self.vehicles) do
        brakeControlSum = brakeControlSum + v:getBrakeControl()
    end
    return brakeControlSum / self.vehicleCount
end

return Consist