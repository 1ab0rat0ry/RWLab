---@type ArrayList
local ArrayList = require "Assets/1ab0rat0ry/RWLab/utils/ArrayList.out"
local Logger = require "Assets/1ab0rat0ry/RWLab/utils/Logger.out"

local DEBUG = false

local logger = Logger:new(DEBUG, "BrakePipe.log")

---@class Consist
---@field public length number
---@field public vehicleCount number
---@field public vehicles ArrayList
local Consist = {
    length = 0,
    vehicleCount = 0,
    vehicles = ArrayList
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
---@param deltaTime number
function Consist:update(deltaTime)
    for i, vehicle in ipairs(self.vehicles:reversed()) do
        local nextVehicle = self.vehicles.elements[self.vehicleCount - i]

        if nextVehicle == nil then break end
        vehicle.brakePipe:equalize(nextVehicle.brakePipe, deltaTime, 100)
        logger:info("I: "..i.." BPP: "..vehicle.brakePipe.pressure.." CP: "..vehicle.distributor.cylinder.pressure.." ARP: "..vehicle.distributor.auxiliaryRes.pressure.." ACP: "..vehicle.distributor.accelerationChamber.pressure)
    end

    for _, vehicle in ipairs(self.vehicles.elements) do
        vehicle:update(deltaTime)
    end
    logger:info("")
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