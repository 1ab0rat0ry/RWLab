---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"
---@type MovingAverage
local MovingAverage = require "Assets/1ab0rat0ry/RWLab/utils/math/MovingAverage.out"

local MAX_HYSTERESIS = 0.1
local MIN_HYSTERESIS = 0.001

---@class DakoDistributorValve
---@field private MAX_HYSTERESIS number
---@field private hysteresis number
---@field public position number
---@field private pressureCoef number
---@field private average MovingAverage
local DakoDistributorValve = {
    hysteresis = MAX_HYSTERESIS,
    position = 0,
    pressureCoef = 0,
    average = {}
}
DakoDistributorValve.__index = DakoDistributorValve

---@param pressureCoef number
---@param inshotPressure number
---@param releasePressure number pressure at which distributor switches to charging position when brake pipe pressure before braking was `5 bar`
function DakoDistributorValve:new(pressureCoef)
    ---@type DakoDistributorValve
    local obj = {
        pressureCoef = pressureCoef,
        average = MovingAverage:new(3)
    }
    obj = setmetatable(obj, self)

    return obj
end

---Calculates target cylinder pressure and updates position accordingly.
---@param deltaTime number
---@param brakePipe Reservoir
---@param distributor DakoBv1
function DakoDistributorValve:update(deltaTime, brakePipe, distributor)
    local pressureCalculated = (distributor.distributorRes.pressure - brakePipe.pressure) * self.pressureCoef
    local pressureDiff = pressureCalculated - distributor.cylinder.pressure
    local positionTarget = MathUtil.clamp(3 * pressureDiff, -1, 1)
    local positionDelta = math.abs(positionTarget - self.position)

    if math.abs(self.position) < 0.001 and positionDelta < 0.001 then
        self.hysteresis = math.min(MAX_HYSTERESIS, self.hysteresis + deltaTime / 10)
    elseif positionDelta > 0.001 then
        self.hysteresis = math.max(MIN_HYSTERESIS, self.hysteresis - math.sqrt(positionDelta) * deltaTime)
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

return DakoDistributorValve