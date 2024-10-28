---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"
---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Reservoir.out"

---@class Cylinder : Reservoir
---@field private maxCapacity number
---@field private maxPressure number
local Cylinder = {
    maxCapacity = 0,
    maxPressure = 0
}

---@param capacity number
---@param maxPressure number
---@return Cylinder
function Cylinder:new(capacity, maxPressure)
    ---@type Cylinder
    local obj = Reservoir:new(capacity)
    obj.maxCapacity = capacity
    obj.maxPressure = maxPressure

    return obj
end

---Changes pressure in reservoir based on volumetric flow.
---@private
---@param flow number
---@param minPressure number
---@param maxPressure number
function Cylinder:changePressure(flow, minPressure, maxPressure)
    self.pressure = MathUtil.clamp(self.pressure + flow / self.capacity, minPressure, maxPressure)
    self.capacity = MathUtil.map(self.pressure, 0, self.maxPressure, self.maxPressure / 50, self.maxCapacity)
    self.capacity = math.min(self.maxCapacity, self.capacity)
end

return Cylinder