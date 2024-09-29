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

local Bs2 = {}

Bs2.Positions = {
    RELEASE = 0,
    RUNNING = 0.1,
    NEUTRAL = 0.18,
    MIN_REDUCTION = 0.28,
    MAX_REDUCTION = 0.78,
    CUTOFF = 0.86,
    EMERGENCY = 1
}
Bs2.Ranges = {
    RELEASE = Bs2.Positions.RELEASE + (Bs2.Positions.RUNNING - Bs2.Positions.RELEASE) / 2,
    RUNNING = Bs2.Positions.RUNNING + (Bs2.Positions.NEUTRAL - Bs2.Positions.RUNNING) / 2,
    NEUTRAL = Bs2.Positions.NEUTRAL + (Bs2.Positions.MIN_REDUCTION - Bs2.Positions.NEUTRAL) / 2,
    SERVICE = Bs2.Positions.MAX_REDUCTION + (Bs2.Positions.CUTOFF - Bs2.Positions.MAX_REDUCTION) / 2,
    CUTOFF = Bs2.Positions.CUTOFF + (Bs2.Positions.EMERGENCY - Bs2.Positions.CUTOFF) / 2,
    EMERGENCY = Bs2.Positions.EMERGENCY
}

Bs2.emergencyValve = false -- false = closed, true = opened
Bs2.interruptValve = 0 -- 0 = closed, 1 = fully opened
Bs2.releaseValve = false -- false = closed, true = opened
Bs2.DistributorValve = {
    MAX_HYSTERESIS = 0.1,
    hysteresis = 0.1,
    position = 0,
    controlChamber = Reservoir:new(0.3),
    average = MovingAverage:new(2)
}
Bs2.DistributorValve.controlChamber.pressure = 5

Bs2.setPressure = 0
Bs2.controlRes = Reservoir:new(CONTROL_RES_CAPACITY)
Bs2.overchargeRes = Reservoir:new(OVERCHGARGE_RES_CAPACITY)

Bs2.hasOvercharge = false

function Bs2:new()
    local o = setmetatable({}, self)
    self.__index = self
    o.controlRes.pressure = 5
    return o
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
        local serviceRange = self.Positions.MAX_REDUCTION - self.Positions.MIN_REDUCTION
        local serviceProgress = (position - self.Positions.MIN_REDUCTION) / serviceRange
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
    if self.emergencyValve then
        local emptyRate = 70
        brakePipe:vent(timeDelta, nil, emptyRate)
    end

    if self.releaseValve then
        self.DistributorValve.controlChamber:equalize(feedPipe, timeDelta)
    else
        self.DistributorValve.controlChamber:equalize(self.controlRes, timeDelta)
    end

    if self.interruptValve > 0 then self:updateDistributorMechanism(timeDelta, feedPipe, brakePipe)
    -- else
    --     Call("SoundBrzdice:SetParameter", "MainPipeReleasing", 0)
    --     Call("SoundBrzdice:SetParameter", "MainPipeFilling", 0)
    end
end

function Bs2:updateDistributorMechanism(timeDelta, feedPipe, brakePipe)
    self.DistributorValve:update(timeDelta, brakePipe)

    if self.DistributorValve.position > 0 then
        local fillRate = 50 * Easings.sineOut(math.min(self.interruptValve, math.abs(self.DistributorValve.position))) / brakePipe.capacity
        brakePipe:equalize(feedPipe, timeDelta, fillRate, 50)
    elseif self.DistributorValve.position < 0 then
        local emptyRate = 30 * Easings.sineOut(math.abs(self.DistributorValve.position)) / brakePipe.capacity
        brakePipe:vent(timeDelta, emptyRate, 30)
    end
end

function Bs2:updateOvercharge(timeDelta, feedPipe, brakePipe)
    if self.overchargeRes.pressure > 0 then
        self.overchargeRes:vent(timeDelta, 0.03)
    end

    if self.DistributorValve.controlChamber.pressure > 5.1 and self.DistributorValve.position > 0.3 then
        local fillRate = 0.5
        self.overchargeRes:equalize(feedPipe, timeDelta, fillRate, OVERCHGARGE_RES_CAPACITY)
    elseif self.hasOvercharge and Call("GetControlValue", "Overcharge", 0) > 0.5 then
        self.overchargeRes:equalize(brakePipe, OVERCHARGE_RES_FILL_RATE, OVERCHGARGE_RES_CAPACITY)
    end
end

function Bs2.DistributorValve:update(timeDelta, brakePipe)
    local pressureDiff = self.controlChamber.pressure - brakePipe.pressure + Bs2.overchargeRes.pressure / 12.5
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

return Bs2