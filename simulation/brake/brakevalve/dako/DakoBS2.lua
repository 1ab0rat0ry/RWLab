---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"
---@type MovingAverage
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
local OVERCHARGE_RES_EMPTY_RATE = 0.03

local FILL_RATE = 30
local EMPTY_RATE = 20
local EMERGENCY_EMPTY_RATE = 70

---Regulates pressure in brake pipe based on the pressure in control chamber.
---@class DistributorValve
---@field private MAX_HYSTERESIS number
---@field private hysteresis number
---@field public position number
---@field public controlChamber Reservoir
---@field private average MovingAverage
local DistributorValve = {
    MAX_HYSTERESIS = 0.1,
    MIN_HYSTERESIS = 0.003,
    hysteresis = 0,
    position = 0,
    controlChamber = {},
    average = {}
}
DistributorValve.__index = DistributorValve
DistributorValve.hysteresis = DistributorValve.MAX_HYSTERESIS

---@return DistributorValve
function DistributorValve:new()
    ---@type DistributorValve
    local obj = {
        controlChamber = Reservoir:new(0.3),
        average = MovingAverage:new(3)
    }
    obj = setmetatable(obj, self)
    obj.controlChamber.pressure = 5

    return obj
end

---Updates position accordingly to pressure in control chamber and overcharge reservoir.
---@param deltaTime number
---@param brakePipe Reservoir
---@param overchargePressure number
function DistributorValve:update(deltaTime, brakePipe, overchargePressure)
    local pressureDiff = self.controlChamber.pressure - brakePipe.pressure + overchargePressure / 12.5
    local positionTarget = MathUtil.clamp(3 * pressureDiff, -1, 1)
    local positionDelta = math.abs(positionTarget - self.position)

    if math.abs(self.position) < 0.001 and positionDelta < 0.001 then
        self.hysteresis = math.min(self.MAX_HYSTERESIS, self.hysteresis + deltaTime / 10)
    elseif positionDelta > 0.001 then
        self.hysteresis = math.max(self.MIN_HYSTERESIS, self.hysteresis - math.sqrt(positionDelta) * deltaTime)
    end
    self.average:sample(positionTarget)

    if math.abs(self.position) < 0.001 and math.abs(positionTarget) < 0.001 then
        self.position = 0
    elseif self.position < positionTarget - self.hysteresis then
        self.position = MathUtil.towards(self.position, self.average:get(), deltaTime)
    elseif self.position > positionTarget + self.hysteresis then
        self.position = MathUtil.towards(self.position, self.average:get(), deltaTime)
    end
end


---Selflapping driver's brake valve used mainly on older locomotives.
---@class DakoBs2
---@field private emergencyValve boolean
---@field private interruptValve number
---@field private releaseValve boolean
---@field private distributorValve DistributorValve
---@field private setPressure number
---@field private controlRes Reservoir
---@field private overchargeRes Reservoir
local DakoBs2 = {
    notches = {
        RELEASE = 0,
        RUNNING = 0,
        NEUTRAL = 0,
        MIN_REDUCTION = 0,
        MAX_REDUCTION = 0,
        CUTOFF = 0,
        EMERGENCY = 0
    },
    ranges = {
        RELEASE = 0,
        RUNNING = 0,
        NEUTRAL = 0,
        SERVICE = 0,
        CUTOFF = 0,
        EMERGENCY = 0
    },

    emergencyValve = false,
    interruptValve = 0,
    releaseValve = false,
    distributorValve = {},

    setPressure = 0,
    controlRes = {},
    overchargeRes = {},

    hasOvercharge = false
}
DakoBs2.__index = DakoBs2

---@param notches table
---@return DakoBs2
function DakoBs2:new(notches)
    ---@type DakoBs2
    local obj = {
        notches = notches,
        distributorValve = DistributorValve:new(),
        controlRes = Reservoir:new(CONTROL_RES_CAPACITY),
        overchargeRes = Reservoir:new(OVERCHGARGE_RES_CAPACITY)
    }
    obj = setmetatable(obj, self)
    obj.ranges.RELEASE = obj.notches.RELEASE + (obj.notches.RUNNING - obj.notches.RELEASE) / 2
    obj.ranges.RUNNING = obj.notches.RUNNING + (obj.notches.NEUTRAL - obj.notches.RUNNING) / 2
    obj.ranges.NEUTRAL = obj.notches.NEUTRAL + (obj.notches.MIN_REDUCTION - obj.notches.NEUTRAL) / 2
    obj.ranges.SERVICE = obj.notches.MAX_REDUCTION + (obj.notches.CUTOFF - obj.notches.MAX_REDUCTION) / 2
    obj.ranges.CUTOFF = obj.notches.CUTOFF + (obj.notches.EMERGENCY - obj.notches.CUTOFF) / 2
    obj.ranges.EMERGENCY = obj.notches.EMERGENCY
    obj.controlRes.pressure = 5

    return obj
end

---Updates the whole brake valve.
---@param deltaTime number
---@param feedPipe Reservoir
---@param brakePipe Reservoir
function DakoBs2:update(deltaTime, feedPipe, brakePipe)
    self:updateControlMechanism(deltaTime, Call("GetControlValue", "VirtualBrake", 0), feedPipe, brakePipe)
    self:updateDistributorMechanism(deltaTime, feedPipe, brakePipe)
    self:updateOvercharge(deltaTime, feedPipe, brakePipe)
end

---Regulates pressure in control reservoir (control pressure)
---and operates release, interrupt and emergency valves based on handle position.
---@private
---@param deltaTime number
---@param position number
---@param feedPipe Reservoir
---@param brakePipe Reservoir
function DakoBs2:updateControlMechanism(deltaTime, position, feedPipe, brakePipe)
    if position <= self.ranges.RELEASE then
        --fully open release valve to allow quick filling of brake pipe
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 1, 2 * deltaTime)
        self.releaseValve = true
    elseif position <= self.ranges.RUNNING then
        --fill brake pipe through choked connection
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 0.3, 2 * deltaTime)
        self.releaseValve = false
        self.setPressure = REFERENCE_PRESSURE
    elseif position <= self.ranges.NEUTRAL then
        --isolate brake pipe
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 0, 2 * deltaTime)
        self.releaseValve = false
    elseif position <= self.ranges.SERVICE then
        --determine pressure for current brake notch
        local pressureDrop = MathUtil.map(position, self.notches.MIN_REDUCTION, self.notches.MAX_REDUCTION, MIN_REDUCTION_PRESSURE_DROP, MAX_REDUCTION_PRESSURE_DROP)

        --allow filling and emptying through choked connection
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 0.3, 2 * deltaTime)
        self.releaseValve = false
        self.setPressure = REFERENCE_PRESSURE - pressureDrop
    elseif position <= self.ranges.CUTOFF then
        --isolate brake pipe
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 0, 2 * deltaTime)
        self.releaseValve = false
    elseif position <= self.ranges.EMERGENCY then
        --open emergency valve, close interrupt valve to prevent unwanted refilling
        self.emergencyValve = true
        self.interruptValve = MathUtil.towards(self.interruptValve, 0, 2 * deltaTime)
        self.releaseValve = false
    end

    local changeRate = CONTROL_RES_CHANGE_RATE * 4 * math.abs(self.setPressure - self.controlRes.pressure)

    --equalize control reservoir to set pressure
    if self.setPressure > self.controlRes.pressure then
        self.controlRes:equalize(feedPipe, deltaTime, 1, changeRate)
    elseif self.setPressure < self.controlRes.pressure then
        self.controlRes:vent(deltaTime, 1, changeRate)
    end

    --quickly vent brake pipe
    if self.emergencyValve then brakePipe:vent(deltaTime, EMERGENCY_EMPTY_RATE) end
    --connect control chamber with feed pipe or control reservoir
    if self.releaseValve then self.distributorValve.controlChamber:equalize(feedPipe, deltaTime)
    else self.distributorValve.controlChamber:equalize(self.controlRes, deltaTime)
    end
end

---Fills, empties and maintains pressure in brake pipe.
---@private
---@param deltaTime number
---@param feedPipe Reservoir
---@param brakePipe Reservoir
function DakoBs2:updateDistributorMechanism(deltaTime, feedPipe, brakePipe)
    self.distributorValve:update(deltaTime, brakePipe, self.overchargeRes.pressure)

    if self.distributorValve.position > 0 then
        local fillRate = FILL_RATE * math.min(self.interruptValve, self.distributorValve.position)
        brakePipe:equalize(feedPipe, deltaTime, fillRate)
    elseif self.distributorValve.position < 0 then
        local emptyRate = EMPTY_RATE * math.abs(self.distributorValve.position)
        brakePipe:vent(deltaTime, emptyRate)
    end
end

---Fills overcharge reservoir when high-pressure release is active or overcharge button is pressed.
---Slowly bleeds pressure from the reservoir to remove overcharge in brake pipe.
---@private
---@param deltaTime number
---@param feedPipe Reservoir
---@param brakePipe Reservoir
function DakoBs2:updateOvercharge(deltaTime, feedPipe, brakePipe)
    if self.overchargeRes.pressure > 0 then self.overchargeRes:vent(deltaTime, 1, OVERCHARGE_RES_EMPTY_RATE) end
    if self.distributorValve.controlChamber.pressure > 5.1 and self.distributorValve.position > 0.3 then
        self.overchargeRes:equalize(feedPipe, deltaTime, 0.335)
    elseif self.hasOvercharge and Call("GetControlValue", "Overcharge", 0) > 0.5 then
        self.overchargeRes:equalize(brakePipe, deltaTime, 0.335)
    end
end

return DakoBs2