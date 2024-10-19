---@class Stopwatch
---@field private lastReset number
---@field private delay number
local Stopwatch = {
    lastReset = 0,
    delay = 0
}
Stopwatch.__index = Stopwatch

---@param delay number
---@return Stopwatch
function Stopwatch:new(delay)
    ---@type Stopwatch
    local obj = {
        delay = delay or 0
    }
    obj = setmetatable(obj, self)

    return obj
end

---Returns true if more time has passed since last reset than delay.
---@param delay number
---@return boolean
function Stopwatch:hasFinished(delay)
    return self:getTime() >= (delay or self.delay)
end

---Resets stopwatch to zero.
function Stopwatch:reset()
    self.lastReset = os.clock()
end

---Return time since last reset.
---@return number
function Stopwatch:getTime()
    return os.clock() - self.lastReset
end

return Stopwatch