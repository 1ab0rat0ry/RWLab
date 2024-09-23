local Stopwatch = {}

Stopwatch.lastReset = 0
Stopwatch.delay = 0

function Stopwatch:new(delay)
    local o = setmetatable({}, self)
    self.__index = self
    o.delay = delay or 0
    return o
end

function Stopwatch:hasFinished(delay)
    delay = delay or self.delay
    return self:getTime() >= delay
end

function Stopwatch:reset()
    self.lastReset = os.clock()
end

function Stopwatch:getTime()
    return os.clock() - self.lastReset
end

return Stopwatch