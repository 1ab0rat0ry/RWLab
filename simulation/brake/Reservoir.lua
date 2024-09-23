-- Adapted from: https://github.com/mspielberg/dv-airbrake --

local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"

local AIR_DENSITY = 0.0121 --kg/m^3

local Reservoir = {}

Reservoir.pressure = 0
Reservoir.capacity = 0

function Reservoir:new(capacity, pressure)
    local o = setmetatable({}, self)
    self.__index = self

    if not pressure then pressure = 0 end
    o.pressure = pressure
    o.capacity = capacity
    return o
end

function Reservoir:adjustPressure(flow, minPressure, maxPressure)
    self.pressure = MathUtil.clamp(self.pressure + flow / self.capacity, minPressure, maxPressure)
end

function Reservoir:transferVolume(reservoir, maxFlow)
    if self.pressure > reservoir.pressure then
        reservoir:transferVolume(self, maxFlow)
        return
    end

    local capacitySum = self.capacity + reservoir.capacity
    local equilibriumPressure = (self:getVolume() + reservoir:getVolume()) / capacitySum
    local volumeToTransfer = (equilibriumPressure - self.pressure) * self.capacity
    local flow = MathUtil.clamp(volumeToTransfer, -maxFlow, maxFlow)

    self:adjustPressure(flow, self.pressure, equilibriumPressure)
    reservoir:adjustPressure(-flow, equilibriumPressure, reservoir.pressure)
end

function Reservoir:equalize(reservoir, timeDelta, maxPressureChangeRate, flowCoef)
    maxPressureChangeRate = maxPressureChangeRate or 1e6
    flowCoef = flowCoef or 1

    local pressureCoef = math.sqrt(math.abs(self.pressure - reservoir.pressure))
    local maxFlow = self.capacity * maxPressureChangeRate
    local flow = pressureCoef * flowCoef

    flow = math.min(flow, maxFlow) * timeDelta
    self:transferVolume(reservoir, flow)
end

function Reservoir:fillFrom(source, timeDelta, maxPressureChangeRate, flowMultiplier)
    if source.pressure <= self.pressure then return
    end
    self:equalize(source, timeDelta, maxPressureChangeRate, flowMultiplier)
end

function Reservoir:vent(timeDelta, maxPressureChangeRate, flowMultiplier)
    self.atmosphere.pressure = 0
    self:equalize(self.atmosphere, timeDelta, maxPressureChangeRate, flowMultiplier)
end

function Reservoir:getVolume()
    return self.pressure * self.capacity
end

Reservoir.atmosphere = Reservoir:new(1e10)

return Reservoir