---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Reservoir.out"
local Cylinder = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Cylinder.out"
local Easings = require "Assets/1ab0rat0ry/RWLab/utils/Easings.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"
---@type MovingAverage
local MovingAverage = require "Assets/1ab0rat0ry/RWLab/utils/math/MovingAverage.out"
local Stopwatch = require "Assets/1ab0rat0ry/RWLab/utils/Stopwatch.out"

local REFERENCE_PRESSURE = 5

local DIST_RES_FILL_TIME = 180
local DIST_RES_FILL_RATE = REFERENCE_PRESSURE / DIST_RES_FILL_TIME
local DIST_RES_CAPACITY = 9

local AUX_RES_FILL_TIME = 180
local AUX_RES_FILL_RATE = REFERENCE_PRESSURE / AUX_RES_FILL_TIME
local AUX_RES_REFILL_TIME = 19
local AUX_RES_REFILL_RATE = 1 / AUX_RES_REFILL_TIME

local CYLINDER_MAX_PRESSURE = 3.8
local CYLINDER_PRESSURE_COEF = 2.533
local CYLINDER_INSHOT_PRESSURE = 0.69
local CYLINDER_FILL_TIME = 3.6
local CYLINDER_EMPTY_TIME = 16
local CYLINDER_FILL_RATE = 0.95 * CYLINDER_MAX_PRESSURE / CYLINDER_FILL_TIME
local CYLINDER_EMPTY_RATE = 0.895 * CYLINDER_MAX_PRESSURE / CYLINDER_EMPTY_TIME

local ACCEL_CHAMBER_CAPACITY = 0.46
local ACCEL_VALVE_HYSTERESIS = 0.1

local VENT_VALVE_CLOSE_PRESSURE = 0.4
local VENT_VALVE_OPEN_PRESSURE = 0.2

local DISTRIBUTOR_SENSITIVITY = 0.1
local DISTRIBUTOR_HYSTERESIS = 0.007

---@class DistributorValv
---@field MAX_HYSTERESIS number
---@field hysteresis number
---@field position number
---@field brakePipePressureLast number
---@field cylinderPressureTarget number
---@field average MovingAverage
local DistributorValve = {
    MAX_HYSTERESIS = 0.1,
    hysteresis = 0,
    position = 0,
    brakePipePressureLast = 0,
    cylinderPressureTarget = 0,
    average = {}
}
DistributorValve.__index = DistributorValve
DistributorValve.hysteresis = DistributorValve.MAX_HYSTERESIS

---Creates new instance of distributor valve.
---@return DistributorValv
function DistributorValve:new()
    ---@type DistributorValv
    local obj = {
        average = MovingAverage:new(2),
        inshotStopwatch = Stopwatch:new(1)
    }
    obj = setmetatable(obj, self)

    return obj
end

---Calculates target cylinder pressure and updates position accordingly.
---@param timeDelta number
---@param brakePipe Reservoir
---@param distributor Bv1
function DistributorValve:update(timeDelta, brakePipe, distributor)
    ---@type number
    local cylinderPressureCalculated = (distributor.distributorRes.pressure - brakePipe.pressure) * CYLINDER_PRESSURE_COEF

    if brakePipe.pressure < self.brakePipePressureLast - DISTRIBUTOR_SENSITIVITY * timeDelta then
        self.cylinderPressureTarget = math.max(cylinderPressureCalculated, CYLINDER_INSHOT_PRESSURE)
    else
        self.cylinderPressureTarget = cylinderPressureCalculated
    end
    self.brakePipePressureLast = brakePipe.pressure

    local pressureDiff = self.cylinderPressureTarget - distributor.cylinder.pressure
    local pressureLimit = Easings.sineOut(CYLINDER_MAX_PRESSURE - distributor.cylinder.pressure)
    local positionTarget = MathUtil.clamp(2 * pressureDiff, -1, pressureLimit)
    local positionDelta = math.abs(positionTarget - self.position)

    if math.abs(self.position) < 0.001 and positionDelta < 0.001 then
        self.hysteresis = math.min(self.MAX_HYSTERESIS, self.hysteresis + timeDelta / 10)
    elseif positionDelta > 0.001 then
        self.hysteresis = math.max(0, self.hysteresis - math.sqrt(positionDelta) * timeDelta)
    end
    self.average:sample(positionTarget)

    local positionDiff = self.average:get() - self.position

    if math.abs(self.position) < 0.001 and math.abs(positionTarget) < 0.001 then
        self.position = 0
    elseif self.position < positionTarget - self.hysteresis then
        self.position = self.position + MathUtil.clamp(positionDiff, -timeDelta, timeDelta)
    elseif self.position > positionTarget + self.hysteresis then
        self.position = self.position + MathUtil.clamp(positionDiff, -timeDelta, timeDelta)
    end
end

---@class Bv1
---@field turnOffValve boolean
---@field distributorValve DistributorValv
---@field inshotValve number
---@field ventilationValve number
---@field acceleratorValve number
---@field accelerationChamber Reservoir
---@field distributorRes Reservoir
---@field auxiliaryRes Reservoir
---@field cylinder Reservoir
local Bv1 = {
    turnOffValve = true,
    distributorValve = {},
    inshotValve = 1,
    ventilationValve = 1,
    acceleratorValve = 0,
    accelerationChamber = {},
    distributorRes = {},
    auxiliaryRes = {},
    cylinder = {}
}
Bv1.__index = Bv1

---Creates new instance of Dako BV1 distributor.
---@param auxResCapacity number
---@param cylinderCapacity number
---@return Bv1
function Bv1:new(auxResCapacity, cylinderCapacity)
    ---@type Bv1
    local obj = {
        distributorValve = DistributorValve:new(),
        accelerationChamber = Reservoir:new(ACCEL_CHAMBER_CAPACITY),
        distributorRes = Reservoir:new(DIST_RES_CAPACITY),
        auxiliaryRes = Reservoir:new(auxResCapacity or 100),
        cylinder = Cylinder:new(cylinderCapacity or 10, CYLINDER_MAX_PRESSURE)
    }
    obj = setmetatable(obj, self)
    obj.distributorRes.pressure = 5
    obj.auxiliaryRes.pressure = 5

    return obj
end

---Updates the whole distributor.
---@param timeDelta number
---@param brakePipe Reservoir
function Bv1:update(timeDelta, brakePipe)
    local brakePipeChamber = self.turnOffValve and brakePipe or Reservoir.atmosphere

    self:updateAcceleratorMechanism(timeDelta, brakePipeChamber)
    self:updateEqualizingMechanism(timeDelta, brakePipeChamber)
    self:updateConnectingMechanism(timeDelta, brakePipeChamber)
    self:updateDistributorMechanism(timeDelta, brakePipeChamber)
end

---Accelerates propagation of the lower pressure waveby taking air from brake pipe into acceleration chamber.
---@param timeDelta number
---@param brakePipe Reservoir
function Bv1:updateAcceleratorMechanism(timeDelta, brakePipe)
    if self.auxiliaryRes.pressure - brakePipe.pressure > ACCEL_VALVE_HYSTERESIS * timeDelta then
         self.acceleratorValve = math.min(1, self.acceleratorValve + 5 * timeDelta)
    else
        self.acceleratorValve = math.max(0, self.acceleratorValve - timeDelta)
    end

    if self.cylinder.pressure > VENT_VALVE_CLOSE_PRESSURE then
        self.ventilationValve = math.max(0, self.ventilationValve - timeDelta)
    elseif self.cylinder.pressure < VENT_VALVE_OPEN_PRESSURE then
        self.ventilationValve = math.min(1, self.ventilationValve + timeDelta)
    end

    self.accelerationChamber:equalize(brakePipe, timeDelta, 10 * Easings.sineOut(self.acceleratorValve), 10)
    self.accelerationChamber:vent(timeDelta, 5 * Easings.sineOut(self.ventilationValve), 5)
end

---Controls filling of distributor and auxiliary reservoir.
---@param timeDelta number
---@param brakePipe Reservoir
function Bv1:updateEqualizingMechanism(timeDelta, brakePipe)
    if self.cylinder.pressure > 0.05 then return end
    self.auxiliaryRes:equalize(brakePipe, timeDelta, AUX_RES_FILL_RATE, 100)
    self.distributorRes:equalize(brakePipe, timeDelta, DIST_RES_FILL_RATE, 9)
end

---Refills auxiliary reservoir.
---@param timeDelta number
---@param brakePipe Reservoir
function Bv1:updateConnectingMechanism(timeDelta, brakePipe)
    if self.auxiliaryRes.pressure + 0.01 < self.distributorRes.pressure then
        self.auxiliaryRes:fillFrom(brakePipe, timeDelta, AUX_RES_REFILL_RATE, 100)
    end
end

---Regulates pressure in brake cylinder.
---@param timeDelta number
---@param brakePipe Reservoir
function Bv1:updateDistributorMechanism(timeDelta, brakePipe)
    self.distributorValve:update(timeDelta, brakePipe, self)

    local inshotValve = MathUtil.inverseLerp(self.cylinder.pressure, CYLINDER_INSHOT_PRESSURE, CYLINDER_INSHOT_PRESSURE - 0.1)

    if self.distributorValve.position > 0 then
        local fillRate = math.min(CYLINDER_FILL_RATE, 2 * Easings.sineOut(math.abs(self.distributorValve.position))) + 10 * Easings.sineOut(self.distributorValve.position * inshotValve)
        self.cylinder:equalize(self.auxiliaryRes, timeDelta, fillRate, 20)
    elseif self.distributorValve.position < 0 then
        local emptyRate = math.min(CYLINDER_EMPTY_RATE, 2 * Easings.sineOut(math.abs(self.distributorValve.position)))
        self.cylinder:vent(timeDelta, emptyRate, 10)
    end
end

return Bv1