local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"
local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Reservoir.out"

local Cylinder = {}

Cylinder.maxCapacity = 0
Cylinder.maxPressure = 0

function Cylinder:new(capacity, maxPressure)
    local o = Reservoir:new(capacity)
    o.maxCapacity = capacity
    o.maxPressure = maxPressure
    return o
end

function Cylinder:adjustPressure(flow, minPressure, maxPressure)
    self.pressure = MathUtil.clamp(self.pressure + flow / self.capacity, minPressure, maxPressure)

    local pressureFactor = MathUtil.inverseLerp(self.pressure, 0, self.maxPressure)
    self.capacity = MathUtil.lerp(pressureFactor, self.maxCapacity / 50, self.maxCapacity)
end

return Cylinder