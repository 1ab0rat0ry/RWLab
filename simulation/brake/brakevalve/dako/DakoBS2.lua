local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Reservoir.out"
local Easings = require "Assets/1ab0rat0ry/RWLab/utils/Easings.out"
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"
local MovingAverage = require "Assets/1ab0rat0ry/RWLab/utils/math/MovingAverage.out"

local REFERENCE_PRESSURE = 5
local MIN_REDUCTION_PRESSURE_DROP = 0.3
local MAX_REDUCTION_PRESSURE_DROP = 2
local FULL_SERVICE_PRESSURE_DROP = 1.5

local CONTROL_RES_CAPACITY = 1
local CONTROL_RES_CHANGE_TIME = 3
local CONTROL_RES_CHANGE_RATE = FULL_SERVICE_PRESSURE_DROP / CONTROL_RES_CHANGE_TIME

local OVERCHARGE_PRESSURE = 5.4
local OVERCHGARGE_RES_CAPACITY = 5
local OVERCHARGE_RES_FILL_TIME = 8
local OVERCHARGE_RES_FILL_RATE = OVERCHARGE_PRESSURE / OVERCHARGE_RES_FILL_TIME

local DistributorValve = {
    MAX_HYSTERESIS = 0.1,
    hysteresis = 0,
    position = 0,
    controlChamber = {},
    average = {}
}
DistributorValve.__index = DistributorValve
DistributorValve.hysteresis = DistributorValve.MAX_HYSTERESIS

function DistributorValve:new()
    local obj = {
        controlChamber = Reservoir:new(0.3),
        average = MovingAverage:new(2)
    }
    obj = setmetatable(obj, self)
    obj.controlChamber.pressure = 5

    return obj
end

function DistributorValve:update(timeDelta, brakePipe, overchargePressure)
    local pressureDiff = self.controlChamber.pressure - brakePipe.pressure + overchargePressure / 12.5
    local positionTarget = MathUtil.clamp(3 * pressureDiff, -1, 1)
    local positionDelta = math.abs(positionTarget - self.position)

    if math.abs(self.position) < 0.001 and positionDelta < 0.001 then
        self.hysteresis = math.min(self.MAX_HYSTERESIS, self.hysteresis + timeDelta / 100)
    elseif positionDelta > 0.001 then
        self.hysteresis = math.max(0, self.hysteresis - math.sqrt(positionDelta) * timeDelta)
    end
    self.average:add(positionTarget)

    local positionDiff = self.average:get() - self.position

    if math.abs(self.position) < 0.001 and math.abs(positionTarget) < 0.001 then
        self.position = 0
    elseif self.position < positionTarget - self.hysteresis then
        self.position = self.position + MathUtil.clamp(positionDiff, -timeDelta, timeDelta)
    elseif self.position > positionTarget + self.hysteresis then
        self.position = self.position + MathUtil.clamp(positionDiff, -timeDelta, timeDelta)
    end
end

local Bs2 = {
    Notches = {
        RELEASE = 0,
        RUNNING = 0,
        NEUTRAL = 0,
        MIN_REDUCTION = 0,
        MAX_REDUCTION = 0,
        CUTOFF = 0,
        EMERGENCY = 0
    },
    Ranges = {
        RELEASE = 0,
        RUNNING = 0,
        NEUTRAL = 0,
        SERVICE = 0,
        CUTOFF = 0,
        EMERGENCY = 0
    },

    emergencyValve = false, -- false = closed, true = opened
    interruptValve = 0, -- 0 = closed, 1 = fully opened
    releaseValve = false, -- false = closed, true = opened
    distributorValve = {},

    setPressure = 0,
    controlRes = {},
    overchargeRes = {},

    hasOvercharge = false
}
Bs2.__index = Bs2

function Bs2:new(notches)
    local obj = {
        Notches = notches,
        distributorValve = DistributorValve:new(),
        controlRes = Reservoir:new(CONTROL_RES_CAPACITY),
        overchargeRes = Reservoir:new(OVERCHGARGE_RES_CAPACITY)
    }
    obj = setmetatable(obj, self)
    obj.Ranges.RELEASE = obj.Notches.RELEASE + (obj.Notches.RUNNING - obj.Notches.RELEASE) / 2
    obj.Ranges.RUNNING = obj.Notches.RUNNING + (obj.Notches.NEUTRAL - obj.Notches.RUNNING) / 2
    obj.Ranges.NEUTRAL = obj.Notches.NEUTRAL + (obj.Notches.MIN_REDUCTION - obj.Notches.NEUTRAL) / 2
    obj.Ranges.SERVICE = obj.Notches.MAX_REDUCTION + (obj.Notches.CUTOFF - obj.Notches.MAX_REDUCTION) / 2
    obj.Ranges.CUTOFF = obj.Notches.CUTOFF + (obj.Notches.EMERGENCY - obj.Notches.CUTOFF) / 2
    obj.Ranges.EMERGENCY = obj.Notches.EMERGENCY
    obj.controlRes.pressure = 5

    return obj
end

function Bs2:update(timeDelta, feedPipe, brakePipe)
    self:updateControlMechanism(timeDelta, Call("GetControlValue", "VirtualBrake", 0), feedPipe)
    self:updateValves(timeDelta, feedPipe, brakePipe)
    self:updateOvercharge(timeDelta, feedPipe, brakePipe)
end

function Bs2:updateControlMechanism(timeDelta, position, feedPipe)
    if position <= self.Ranges.RELEASE then
        self.emergencyValve = false
        self.interruptValve = 1
        self.releaseValve = true
    elseif position <= self.Ranges.RUNNING then
        self.emergencyValve = false
        self.interruptValve = 0.3
        self.releaseValve = false
        self.setPressure = REFERENCE_PRESSURE
    elseif position <= self.Ranges.NEUTRAL then
        self.emergencyValve = false
        self.interruptValve = 0
        self.releaseValve = false
    elseif position <= self.Ranges.SERVICE then
        local serviceRange = self.Notches.MAX_REDUCTION - self.Notches.MIN_REDUCTION
        local serviceProgress = (position - self.Notches.MIN_REDUCTION) / serviceRange
        local pressureDropRange = MAX_REDUCTION_PRESSURE_DROP - MIN_REDUCTION_PRESSURE_DROP
        local pressureDrop = MIN_REDUCTION_PRESSURE_DROP + pressureDropRange * serviceProgress

        self.emergencyValve = false
        self.interruptValve = 0.3
        self.releaseValve = false
        self.setPressure = REFERENCE_PRESSURE - pressureDrop
    elseif position <= self.Ranges.CUTOFF then
        self.emergencyValve = false
        self.interruptValve = 0
        self.releaseValve = false
    elseif position <= self.Ranges.EMERGENCY then
        self.emergencyValve = true
        self.interruptValve = 0
        self.releaseValve = false
    end

    local changeRate = CONTROL_RES_CHANGE_RATE * Easings.sineOut(4 * math.abs(self.setPressure - self.controlRes.pressure))

    if self.setPressure > self.controlRes.pressure then
        self.controlRes:equalize(feedPipe, timeDelta, changeRate)
    elseif self.setPressure < self.controlRes.pressure then
        self.controlRes:vent(timeDelta, changeRate)
    end
end

function Bs2:updateValves(timeDelta, feedPipe, brakePipe)
    if self.emergencyValve then brakePipe:vent(timeDelta, nil, 70) end
    if self.releaseValve then self.distributorValve.controlChamber:equalize(feedPipe, timeDelta)
    else self.distributorValve.controlChamber:equalize(self.controlRes, timeDelta)
    end
    self:updateDistributorMechanism(timeDelta, feedPipe, brakePipe)
end

function Bs2:updateDistributorMechanism(timeDelta, feedPipe, brakePipe)
    self.distributorValve:update(timeDelta, brakePipe, self.overchargeRes.pressure)

    if self.distributorValve.position > 0 then
        local fillRate = 30 * Easings.sineOut(math.min(self.interruptValve, math.abs(self.distributorValve.position)))
        brakePipe:equalize(feedPipe, timeDelta, nil, fillRate)
    elseif self.distributorValve.position < 0 then
        local emptyRate = 20 * Easings.sineOut(math.abs(self.distributorValve.position))
        brakePipe:vent(timeDelta, nil, emptyRate)
    end
end

function Bs2:updateOvercharge(timeDelta, feedPipe, brakePipe)
    if self.overchargeRes.pressure > 0 then
        self.overchargeRes:vent(timeDelta, 0.03)
    end

    if self.distributorValve.controlChamber.pressure > 5.1 and self.distributorValve.position > 0.3 then
        local fillRate = 0.5
        self.overchargeRes:equalize(feedPipe, timeDelta, fillRate, OVERCHGARGE_RES_CAPACITY)
    elseif self.hasOvercharge and Call("GetControlValue", "Overcharge", 0) > 0.5 then
        self.overchargeRes:equalize(brakePipe, OVERCHARGE_RES_FILL_RATE, OVERCHGARGE_RES_CAPACITY)
    end
end

return Bs2