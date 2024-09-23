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
    for k, vehicle in ipairs(self.vehicles) do
        local nextVehicle = self.vehicles[k + 1]

        if nextVehicle ~= nil then
            vehicle.brakePipe:equalize(nextVehicle.brakePipe, timeDelta, nil, 100)
        end
        vehicle:update(timeDelta)
        -- logger:info("K: "..k.." V: "..vehicle.brakePipe.pressure.." NV: "..nextVehicle.brakePipe.pressure.." NVA: "..nextVehicle.distributor.accelerationChamber.pressure)
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