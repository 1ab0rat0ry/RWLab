---@type Easings
local Easings = require "Assets/1ab0rat0ry/RWLab/utils/Easings.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"
---@type MovingAverage
local MovingAverage = require "Assets/1ab0rat0ry/RWLab/utils/math/MovingAverage.out"

local REFERENCE_PRESSURE = 5

---@class DakoDistributorValve
---@field private MAX_HYSTERESIS number
---@field private hysteresis number
---@field public position number
---@field private brakePipePressureLast number
---@field private releasePressureDelta number
---@field private pressureCoef number
---@field private pressureTarget number
---@field private inshotPressure number
---@field private maxPressure number
---@field private average MovingAverage
local DakoDistributorValve = {
    MAX_HYSTERESIS = 0.1,
    hysteresis = 0,
    sensitivity = 0,
    insensitivity = 0,
    position = 0,
    brakePipePressureLast = 0,
    releasePressureDelta = 0,
    pressureCoef = 0,
    pressureTarget = 0,
    inshotPressure = 0,
    maxPressure = 0,
    average = {}
}
DakoDistributorValve.__index = DakoDistributorValve
DakoDistributorValve.hysteresis = DakoDistributorValve.MAX_HYSTERESIS

---@param pressureCoef number
---@param inshotPressure number
---@param maxPressure number
---@param releasePressure number pressure at which distributor switches to charging position when brake pipe pressure before braking was `5 bar`
---@param sensitivity number
---@param insensitivity number
function DakoDistributorValve:new(pressureCoef, inshotPressure, maxPressure, releasePressure, sensitivity, insensitivity)
    ---@type DakoDistributorValve
    local obj = {
        sensitivity = sensitivity,
        insensitivity = insensitivity,
        releasePressureDelta = REFERENCE_PRESSURE - releasePressure,
        pressureCoef = pressureCoef,
        inshotPressure = inshotPressure,
        maxPressure = maxPressure,
        average = MovingAverage:new(2)
    }
    obj = setmetatable(obj, self)

    return obj
end

---Calculates target cylinder pressure and updates position accordingly.
---@param deltaTime number
---@param brakePipe Reservoir
---@param distributor DakoBv1
function DakoDistributorValve:update(deltaTime, brakePipe, distributor)
    local releasePressure = math.max(0, distributor.distributorRes.pressure - self.releasePressureDelta)
    local pressureCalculated = (distributor.distributorRes.pressure - brakePipe.pressure) * self.pressureCoef

    if brakePipe.pressure < self.brakePipePressureLast then
        self.pressureTarget = pressureCalculated
    elseif brakePipe.pressure > releasePressure then
        self.pressureTarget = 0
    elseif brakePipe.pressure > self.brakePipePressureLast then
        self.pressureTarget = pressureCalculated
    end
    self.brakePipePressureLast = brakePipe.pressure

    local inshot = MathUtil.inverseLerp(distributor.cylinder.pressure, self.inshotPressure, self.inshotPressure - 0.1)
    local pressureDiff = self.pressureTarget - distributor.cylinder.pressure
    local pressureLimit = Easings.sineOut(self.maxPressure - distributor.cylinder.pressure)
    local positionTarget = MathUtil.clamp((2 + inshot) * pressureDiff, -1, pressureLimit + inshot)

    self.average:sample(positionTarget)

    if math.abs(self.position) < 0.001 and math.abs(positionTarget) < 0.001 then
        self.position = 0
    else
        self.position = MathUtil.towards(self.position, self.average:get(), deltaTime)
    end
end

return DakoDistributorValve