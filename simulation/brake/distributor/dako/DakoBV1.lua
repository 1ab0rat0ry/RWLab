---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Reservoir.out"
---@type Cylinder
local Cylinder = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Cylinder.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"
---@type Easings
local Easings = require "Assets/1ab0rat0ry/RWLab/utils/Easings.out"
---@type DakoDistributorValve
local DakoDistributorValve = require "Assets/1ab0rat0ry/RWLab/simulation/brake/distributor/dako/DakoDistributorValve.out"

local REFERENCE_PRESSURE = 5

local DIST_RES_FILL_TIME = 180
local DIST_RES_FILL_RATE = REFERENCE_PRESSURE / DIST_RES_FILL_TIME
local DIST_RES_CAPACITY = 9

local AUX_RES_FILL_TIME = 180
local AUX_RES_FILL_RATE = REFERENCE_PRESSURE / AUX_RES_FILL_TIME
local AUX_RES_REFILL_TIME = 19
local AUX_RES_REFILL_RATE = 1 / AUX_RES_REFILL_TIME
local AUX_RES_REFILL_THRESHOLD = 0.1

local CYLINDER_MAX_PRESSURE = 3.8
local CYLINDER_PRESSURE_COEF = 2.533
local CYLINDER_INSHOT_PRESSURE = 0.69
local CYLINDER_FILL_TIME = 3.6
local CYLINDER_EMPTY_TIME = 16
local CYLINDER_FILL_RATE = 0.95 * CYLINDER_MAX_PRESSURE / CYLINDER_FILL_TIME
local CYLINDER_EMPTY_RATE = 0.895 * CYLINDER_MAX_PRESSURE / CYLINDER_EMPTY_TIME

local ACCEL_CHAMBER_CAPACITY = 0.46
local ACCEL_VALVE_HYSTERESIS = 0.02

local VENT_VALVE_CLOSE_THRESHOLD = 0.4
local VENT_VALVE_OPEN_THRESHOLD = 0.2

local CHARGE_THRESHOLD = 0.1
local RELEASE_THRESHOLD = 4.84

---@class DakoBv1
---@field private turnOffValve boolean
---@field private distributorValve DakoDistributorValve
---@field private inshotValve number
---@field private ventilationValve number
---@field private acceleratorValve number
---@field private accelerationChamber Reservoir
---@field public distributorRes Reservoir
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
        distributorValve = DakoDistributorValve:new(CYLINDER_PRESSURE_COEF, CYLINDER_INSHOT_PRESSURE, RELEASE_THRESHOLD),
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
---@param deltaTime number
---@param brakePipe Reservoir
function DakoBv1:update(deltaTime, brakePipe)
    local brakePipeChamber = self.turnOffValve and brakePipe or Reservoir.atmosphere

    self:updateAcceleratorMechanism(deltaTime, brakePipeChamber)
    self:updateEqualizingMechanism(deltaTime, brakePipeChamber)
    self:updateConnectingMechanism(deltaTime, brakePipeChamber)
    self:updateDistributorMechanism(deltaTime, brakePipeChamber)
end

---Accelerates propagation of the lower pressure wave by taking air from brake pipe into acceleration chamber.
---@private
---@param deltaTime number
---@param brakePipe Reservoir
function DakoBv1:updateAcceleratorMechanism(deltaTime, brakePipe)
    self.acceleratorValve = MathUtil.inverseLerp(self.auxiliaryRes.pressure - brakePipe.pressure, ACCEL_VALVE_HYSTERESIS, 0.1)

    if self.cylinder.pressure > VENT_VALVE_CLOSE_THRESHOLD then
        self.ventilationValve = math.max(0, self.ventilationValve - deltaTime)
    elseif self.cylinder.pressure < VENT_VALVE_OPEN_THRESHOLD then
        self.ventilationValve = math.min(1, self.ventilationValve + deltaTime)
    end
    self.accelerationChamber:equalize(brakePipe, deltaTime, 2 * self.acceleratorValve)
    self.accelerationChamber:vent(deltaTime, self.ventilationValve)
end

---Controls filling of distributor and auxiliary reservoir.
---@private
---@param deltaTime number
---@param brakePipe Reservoir
function DakoBv1:updateEqualizingMechanism(deltaTime, brakePipe)
    local openingForce = brakePipe.pressure / RELEASE_THRESHOLD + 3
    local closingForce = self.cylinder.pressure / CHARGE_THRESHOLD
    local equalizingValve = MathUtil.clamp(openingForce - closingForce, 0, 1)

    self.auxiliaryRes:equalize(brakePipe, deltaTime, 1.863 * equalizingValve)
    self.distributorRes:equalize(brakePipe, deltaTime, 0.168 * equalizingValve)
end

---Refills auxiliary reservoir.
---@private
---@param deltaTime number
---@param brakePipe Reservoir
function DakoBv1:updateConnectingMechanism(deltaTime, brakePipe)
    if self.auxiliaryRes.pressure + AUX_RES_REFILL_THRESHOLD < self.distributorRes.pressure then
        self.auxiliaryRes:fillFrom(brakePipe, deltaTime, 9.5, AUX_RES_REFILL_RATE)
    end
end

---Regulates pressure in brake cylinder.
---@private
---@param deltaTime number
---@param brakePipe Reservoir
function DakoBv1:updateDistributorMechanism(deltaTime, brakePipe)
    self.distributorValve:update(deltaTime, brakePipe, self)

    local inshotValve = MathUtil.inverseLerp(self.cylinder.pressure, CYLINDER_INSHOT_PRESSURE, CYLINDER_INSHOT_PRESSURE - 0.1)

    if self.distributorValve.position > 0 then
        local pressureLimit = Easings.sineOut(CYLINDER_MAX_PRESSURE - self.cylinder.pressure)
        local fillRate = math.min(CYLINDER_FILL_RATE, 2 * math.abs(self.distributorValve.position) * pressureLimit) + 10 * self.distributorValve.position * inshotValve
        self.cylinder:equalize(self.auxiliaryRes, deltaTime, 20, fillRate)
    elseif self.distributorValve.position < 0 then
        local emptyRate = math.min(CYLINDER_EMPTY_RATE, 2 * math.abs(self.distributorValve.position))
        self.cylinder:vent(deltaTime, 10, emptyRate)
    end
end

return DakoBv1