local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation//brake/Reservoir.out"
local Easings = require "Assets/1ab0rat0ry/RWLab/utils/Easings.out"
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"
local MovingAverage = require "Assets/1ab0rat0ry/RWLab/utils/math/MovingAverage.out"
local Stopwatch = require "Assets/1ab0rat0ry/RWLab/utils/Stopwatch.out"

local REFERENCE_PRESSURE = 5

local DIST_RES_FILL_TIME = 180
local DIST_RES_FILL_RATE = REFERENCE_PRESSURE / DIST_RES_FILL_TIME

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

local Bv1 = {}
local DistributorValve = {}

DistributorValve.maxHysteresis = 0
DistributorValve.hysteresis = 0
DistributorValve.position = 0
DistributorValve.cylinderPressureTarget = 0
DistributorValve.cylinderPressureCalculatedLast = 0
DistributorValve.inshotStopwatch = {}
DistributorValve.average = {}

function DistributorValve:new(maxHysteresis, inshotDelay)
    local o = setmetatable({}, self)
    self.__index = self
    o.maxHysteresis = maxHysteresis
    o.hysteresis = maxHysteresis
    o.average = MovingAverage:new(2)
    o.inshotStopwatch = Stopwatch:new(inshotDelay)
    return o
end

Bv1.turnOffValve = true
Bv1.distributorValve = DistributorValve
Bv1.inshotValve = 1
Bv1.ventilationValve = 1
Bv1.acceleratorValve = 0

Bv1.accelerationChamber = Reservoir
Bv1.distributorRes = Reservoir
Bv1.auxiliaryRes = Reservoir
Bv1.cylinder = Reservoir

function Bv1:new()
    local o = setmetatable({}, self)
    self.__index = self
    o.distributorValve = DistributorValve:new(0.1, 1)
    o.accelerationChamber = Reservoir:new(0.46)
    o.distributorRes = Reservoir:new(9)
    o.auxiliaryRes = Reservoir:new(100)
    o.cylinder = Reservoir:new(10)
    o.distributorRes.pressure = 5
    o.auxiliaryRes.pressure = 5
    return o
end

function Bv1:update(timeDelta, brakePipe)
    local brakePipe = self.turnOffValve and brakePipe or Reservoir.atmosphere

    self:updateAcceleratorMechanism(timeDelta, brakePipe)
    self:updateEqualizingMechanism(timeDelta, brakePipe)
    self:updateConnectingMechanism(timeDelta, brakePipe)
    self:updateDistributorMechanism(timeDelta, brakePipe)
end

function Bv1:updateAcceleratorMechanism(timeDelta, brakePipe)
    if self.auxiliaryRes.pressure - brakePipe.pressure > 0.1 * timeDelta then
        self.acceleratorValve = math.min(1, self.acceleratorValve + 5 * timeDelta)
    else
        self.acceleratorValve = math.max(0, self.acceleratorValve - timeDelta)
    end

    if self.cylinder.pressure > 0.4 then
        self.ventilationValve = math.max(0, self.ventilationValve - timeDelta)
    elseif self.cylinder.pressure < 0.2 then
        self.ventilationValve = math.min(1, self.ventilationValve + timeDelta)
    end

    self.accelerationChamber:equalize(brakePipe, timeDelta, 10 * Easings.sineOut(self.acceleratorValve), 10)
    self.accelerationChamber:vent(timeDelta, 5 * Easings.sineOut(self.ventilationValve), 5)
end

function Bv1:updateEqualizingMechanism(timeDelta, brakePipe)
    if self.cylinder.pressure > 0.05 then return end
    self.auxiliaryRes:equalize(brakePipe, timeDelta, AUX_RES_FILL_RATE, 100)
    self.distributorRes:equalize(brakePipe, timeDelta, DIST_RES_FILL_RATE, 9)
end

function Bv1:updateConnectingMechanism(timeDelta, brakePipe)
    if self.auxiliaryRes.pressure + 0.001 < self.distributorRes.pressure then
        self.auxiliaryRes:fillFrom(brakePipe, timeDelta, AUX_RES_REFILL_RATE, 100)
    end
end

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

function Bv1.distributorValve:update(timeDelta, brakePipe, bv1)
    local cylinderPressureCalculated = (bv1.distributorRes.pressure - brakePipe.pressure) * CYLINDER_PRESSURE_COEF

    if cylinderPressureCalculated > self.cylinderPressureCalculatedLast then
        if self.inshotStopwatch:hasFinished() and cylinderPressureCalculated > self.cylinderPressureCalculatedLast + 0.01 * timeDelta then
            self.cylinderPressureTarget = math.max(cylinderPressureCalculated, CYLINDER_INSHOT_PRESSURE)
        else
            self.cylinderPressureTarget = cylinderPressureCalculated
        end
    elseif cylinderPressureCalculated < self.cylinderPressureCalculatedLast then
        if cylinderPressureCalculated < CYLINDER_INSHOT_PRESSURE then
            self.inshotStopwatch:reset()
        end
        self.cylinderPressureTarget = cylinderPressureCalculated
    end
    self.cylinderPressureCalculatedLast = cylinderPressureCalculated

    local pressureDiff = self.cylinderPressureTarget - bv1.cylinder.pressure
    local pressureLimit = Easings.sineOut(CYLINDER_MAX_PRESSURE - bv1.cylinder.pressure)
    local positionTarget = MathUtil.clamp(2 * pressureDiff, -1, pressureLimit)
    local positionDelta = math.abs(positionTarget - self.position)

    if math.abs(self.position) < 0.001 and positionDelta < 0.001 then
        self.hysteresis = math.min(self.maxHysteresis, self.hysteresis + timeDelta / 100)
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

return Bv1