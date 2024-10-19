---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"

---@class Easings
local Easings = {}

---@param factor number
---@return number
function Easings.sineIn(factor)
    return 1 - math.cos(MathUtil.clamp(factor, 0, 1) * math.pi / 2)
end

---@param factor number
---@return number
function Easings.sineOut(factor)
    return math.sin(MathUtil.clamp(factor, 0, 1) * math.pi / 2)
end

---@param factor number
---@return number
function Easings.quadIn(factor)
    return MathUtil.clamp(factor, 0, 1) ^ 2
end

---@param factor number
---@return number
function Easings.quadOut(factor)
    return 1 - (1 - MathUtil.clamp(factor, 0, 1)) ^ 2
end

---@param factor number
---@return number
function Easings.cubicIn(factor)
    return MathUtil.clamp(factor, 0, 1) ^ 3
end

---@param factor number
---@return number
function Easings.cubicOut(factor)
    return 1 - (1 - MathUtil.clamp(factor, 0, 1)) ^ 3
end

---@param factor number
---@return number
function Easings.quartIn(factor)
    return MathUtil.clamp(factor, 0, 1) ^ 4
end

---@param factor number
---@return number
function Easings.quartOut(factor)
    return 1 - (1 - MathUtil.clamp(factor, 0, 1)) ^ 4
end

---@param factor number
---@return number
function Easings.quintIn(factor)
    return MathUtil.clamp(factor, 0, 1) ^ 5
end

---@param factor number
---@return number
function Easings.quintOut(factor)
    return 1 - (1 - MathUtil.clamp(factor, 0, 1)) ^ 5
end

---@param factor number
---@return number
function Easings.expIn(factor)
    factor = MathUtil.clamp(factor, 0, 1)
    return factor == 0 and 0 or 2 ^ (10 * factor - 10)
end

---@param factor number
---@param start number
---@param finish number
---@param control number
function Easings.bezier(factor, start, finish, control)
    factor = MathUtil.clamp(factor, 0, 1)
    return (1 - factor) ^ 2 * start + 2 * (1 - factor) * factor * control + factor ^ 2 * finish
end

---@param factor number
---@return number
function Easings.expOut(factor)
    factor = MathUtil.clamp(factor, 0, 1)
    return factor ~= 0 and 1 - 2 ^ (-10 * factor) or 0
end

---@param factor number
---@return number
function Easings.circIn(factor)
    return 1 - math.sqrt(1 - MathUtil.clamp(factor, 0, 1) ^ 2)
end

---@param factor number
---@return number
function Easings.circOut(factor)
    return math.sqrt(1 - (MathUtil.clamp(factor, 0, 1) - 1) ^ 2)
end

---@param factor number
---@return number
function Easings.elasticOut(factor)
    factor = MathUtil.clamp(factor, 0, 1)
    return 2 ^ (-10 * factor) * math.sin(math.pi * (6 * factor - 0.5)) + 1
end

-- function Easings.ElasticOut:ease(old, new, duration, time)
--     local factor = MathUtil.clamp(time / duration, 0, 1)
--     local animation = 2 ^ (-10 * factor) * math.sin(math.pi * (self.frequency * factor - 0.5)) + 1
--     return animation * (new - old) + old
-- end

return Easings