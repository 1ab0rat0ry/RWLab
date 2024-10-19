---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Reservoir.out"
---@type Cylinder
local Cylinder = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Cylinder.out"
---@type Easings
local Easings = require "Assets/1ab0rat0ry/RWLab/utils/Easings.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"
---@type MovingAverage
local MovingAverage = require "Assets/1ab0rat0ry/RWLab/utils/math/MovingAverage.out"
---@type Stopwatch
local Stopwatch = require "Assets/1ab0rat0ry/RWLab/utils/Stopwatch.out"
---@type DakoDistributorValve
local DakoDistributorValve = require "Assets/1ab0rat0ry/RWLab/simulation/brake/dako/DakoDistributorValve.out"

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

local SENSITIVITY = 0.1
local HYSTERESIS = 0.007

---@class DakoBv1
---@field private turnOffValve boolean
---@field private distributorValve DakoDistributorValve
---@field private inshotValve number
---@field private ventilationValve number
---@field private acceleratorValve number
---@field private accelerationChamber Reservoir
---@field private distributorRes Reservoir
---@field private auxiliaryRes Reservoir
---@field public cylinder Reservoir
local DakoBv1 = {
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
DakoBv1.__index = DakoBv1

---@param auxResCapacity number
---@param cylinderCapacity number
---@return DakoBv1
function DakoBv1:new(auxResCapacity, cylinderCapacity)
    ---@type DakoBv1
    local obj = {
        distributorValve = DakoDistributorValve:new(CYLINDER_PRESSURE_COEF, CYLINDER_INSHOT_PRESSURE, CYLINDER_MAX_PRESSURE, SENSITIVITY, HYSTERESIS),
        accelerationChamber = Reservoir:new(ACCEL_CHAMBER_CAPACITY),
        distributorRes = Reservoir:new(DIST_RES_CAPACITY),
        auxiliaryRes = Reservoir:new(auxResCapacity),
        cylinder = Cylinder:new(cylinderCapacity, CYLINDER_MAX_PRESSURE)
    }
    obj = setmetatable(obj, self)
    obj.distributorRes.pressure = 5
    obj.auxiliaryRes.pressure = 5

    return obj
end

---Updates the whole distributor.
---@param timeDelta number
---@param brakePipe Reservoir
function DakoBv1:update(timeDelta, brakePipe)
    local brakePipeChamber = self.turnOffValve and brakePipe or Reservoir.atmosphere

    self:updateAcceleratorMechanism(timeDelta, brakePipeChamber)
    self:updateEqualizingMechanism(timeDelta, brakePipeChamber)
    self:updateConnectingMechanism(timeDelta, brakePipeChamber)
    self:updateDistributorMechanism(timeDelta, brakePipeChamber)
end

---Accelerates propagation of the lower pressure waveby taking air from brake pipe into acceleration chamber.
---@private
---@param timeDelta number
---@param brakePipe Reservoir
function DakoBv1:updateAcceleratorMechanism(timeDelta, brakePipe)
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
---@private
---@param timeDelta number
---@param brakePipe Reservoir
function DakoBv1:updateEqualizingMechanism(timeDelta, brakePipe)
    if self.cylinder.pressure > 0.05 then return end
    self.auxiliaryRes:equalize(brakePipe, timeDelta, AUX_RES_FILL_RATE, 100)
    self.distributorRes:equalize(brakePipe, timeDelta, DIST_RES_FILL_RATE, 9)
end

---Refills auxiliary reservoir.
---@private
---@param timeDelta number
---@param brakePipe Reservoir
function DakoBv1:updateConnectingMechanism(timeDelta, brakePipe)
    if self.auxiliaryRes.pressure + 0.01 < self.distributorRes.pressure then
        self.auxiliaryRes:fillFrom(brakePipe, timeDelta, AUX_RES_REFILL_RATE, 100)
    end
end

---Regulates pressure in brake cylinder.
---@private
---@param timeDelta number
---@param brakePipe Reservoir
function DakoBv1:updateDistributorMechanism(timeDelta, brakePipe)
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

return DakoBv1