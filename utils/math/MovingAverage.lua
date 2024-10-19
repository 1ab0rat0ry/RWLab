---@class MovingAverage
---@field sampleSize number
---@field sampleIndex number
---@field samples table
local MovingAverage = {
    sampleSize = 0,
    sampleIndex = 1,
    samples = {}
}
MovingAverage.__index = MovingAverage

---@param sampleSize number
---@return MovingAverage
function MovingAverage:new(sampleSize)
    ---@type MovingAverage
    local obj = {
        sampleSize = sampleSize,
        samples = {}
    }
    obj = setmetatable(obj, self)

    return obj
end

---Takes sample for calculating moving average.
---@param sample number
function MovingAverage:sample(sample)
    self.samples[self.sampleIndex] = sample
    self.sampleIndex = self.sampleIndex == self.sampleSize and 1 or self.sampleIndex + 1
end

---Calculates moving average from samples.
---@return number
function MovingAverage:get()
    local sum, i = 0, 1

    while self.samples[i] ~= nil do
        sum = sum + self.samples[i]
        i = i + 1
    end

    return sum / (i - 1)
end

return MovingAverage