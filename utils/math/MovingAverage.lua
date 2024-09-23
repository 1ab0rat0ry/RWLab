local MovingAverage = {}

MovingAverage.sampleSize = 0
MovingAverage.sampleIndex = 1
MovingAverage.samples = {}

function MovingAverage:new(sampleSize)
    local o = setmetatable({}, self)
    self.__index = self
    o.sampleSize = sampleSize
    o.samples = {}
    return o
end

function MovingAverage:add(sample)
    self.samples[self.sampleIndex] = sample
    self.sampleIndex = self.sampleIndex == self.sampleSize and 1 or self.sampleIndex + 1
end

function MovingAverage:get()
    local sum = 0
    local k = 1

    while self.samples[k] ~= nil do
        sum = sum + self.samples[k]
        k = k + 1
    end
    return sum / (k - 1)
end

return MovingAverage