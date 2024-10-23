--Adapted from: https://github.com/mspielberg/dv-airbrake
--Original author: mspielberg

---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"

---@class Reservoir
---@field public pressure number
---@field public capacity number
local Reservoir = {
    pressure = 0,
    capacity = 0
}
Reservoir.__index = Reservoir

---@param capacity number
---@param pressure number
---@return Reservoir
function Reservoir:new(capacity, pressure)
    ---@type Reservoir
    local obj = {
        capacity = capacity,
        pressure = pressure or 0
    }
    obj = setmetatable(obj, self)

    return obj
end

---Changes pressure in reservoir based on volumetric flow.
---@protected
---@param flow number
---@param minPressure number
---@param maxPressure number
function Reservoir:changePressure(flow, minPressure, maxPressure)
    -- self.pressure = MathUtil.clamp(self.pressure + flow / self.capacity, minPressure, maxPressure)
    self.pressure = self.pressure + flow / self.capacity
end

---Handles volume transfer between reservoirs.
---@private
---@param reservoir Reservoir
---@param maxFlow number
function Reservoir:transferVolume(reservoir, maxFlow)
    if self.pressure > reservoir.pressure then
        reservoir:transferVolume(self, maxFlow)
        return
    end

    local capacitySum = self.capacity + reservoir.capacity
    local equilibriumPressure = (self:getVolume() + reservoir:getVolume()) / capacitySum
    local volumeToTransfer = (equilibriumPressure - self.pressure) * self.capacity
    local flow = MathUtil.clamp(volumeToTransfer, -maxFlow, maxFlow)

    self:changePressure(flow, self.pressure, equilibriumPressure)
    reservoir:changePressure(-flow, equilibriumPressure, reservoir.pressure)
end

---Equalizes pressure in two reservoirs.
---@param reservoir Reservoir
---@param deltaTime number
---@param maxPressureChangeRate number
---@param flowCoef number
function Reservoir:equalize(reservoir, deltaTime, flowCoef, maxPressureChangeRate)
    flowCoef = flowCoef or 1
    maxPressureChangeRate = maxPressureChangeRate or 1e10

    local pressureCoef = math.sqrt(math.abs(self.pressure - reservoir.pressure))
    local maxFlow = self.capacity * maxPressureChangeRate
    local flow = pressureCoef * flowCoef

    flow = math.min(flow, maxFlow) * deltaTime
    self:transferVolume(reservoir, flow)
end

---Fills reservoir on which it is called from `source`.
---@param source Reservoir
---@param deltaTime number
---@param maxPressureChangeRate number
---@param flowMultiplier number
function Reservoir:fillFrom(source, deltaTime, flowCoef, maxPressureChangeRate)
    if source.pressure <= self.pressure then return end
    self:equalize(source, deltaTime, flowCoef, maxPressureChangeRate)
end

---Empties reservoir.
---@param deltaTime number
---@param maxPressureChangeRate number
---@param flowMultiplier number
function Reservoir:vent(deltaTime, flowCoef, maxPressureChangeRate)
    self.atmosphere.pressure = 0
    self:equalize(self.atmosphere, deltaTime, flowCoef, maxPressureChangeRate)
end

---Gets volume of air in reservoir.
---@return number
function Reservoir:getVolume()
    return self.pressure * self.capacity
end

Reservoir.atmosphere = Reservoir:new(1e10)

return Reservoir