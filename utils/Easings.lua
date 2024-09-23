MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"

local Easing = {}

function Easing:new()
    o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Easing.getProgress(duration, time)
    return MathUtil.clamp(time / duration, 0, 1)
end

local Easings = {
    Linear = Easing:new(),

    SineOut = Easing:new(),

    QuadraticIn = Easing:new(),

    ElasticOut = {
        frequency = 6,
        amplitude = 1
    }
}

function Easings.Linear:ease(old, new, duration, time)
    return self.getProgress(duration, time) * (new - old) + old
end


function Easings.sineIn(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return 1 - math.cos(progress * math.pi / 2)
end

function Easings.sineOut(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return math.sin(progress * math.pi / 2)
end

function Easings.quadIn(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return progress ^ 2
end

function Easings.quadOut(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return 1 - (1 - progress) ^ 2
end

function Easings.cubicIn(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return progress ^ 3
end

function Easings.cubicOut(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return 1 - (1 - progress) ^ 3
end

function Easings.quartIn(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return progress ^ 4
end

function Easings.quartOut(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return 1 - (1 - progress) ^ 4
end

function Easings.quintIn(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return progress ^ 5
end

function Easings.quintOut(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return 1 - (1 - progress) ^ 5
end

function Easing.expIn(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return progress == 0 and 0 or 2 ^ (10 * progress - 10)
end

function Easing.expOut(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return progress == 0 and 0 or 1 - 2 ^ (-10 * progress)
end

function Easing.circIn(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return 1 - math.sqrt(1 - progress ^ 2)
end

function Easing.circOut(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return math.sqrt(1 - (progress - 1) ^ 2)
end

function Easings.bezier(progress, start, finish, control)
    progress = MathUtil.clamp(progress, 0, 1)
    return (1 - progress) ^ 2 * start + 2 * (1 - progress) * progress * control + progress ^ 2 * finish
end

function Easings.elasticOut(progress)
    progress = MathUtil.clamp(progress, 0, 1)
    return 2 ^ (-10 * progress) * math.sin(math.pi * (6 * progress - 0.5)) + 1
end

-- function Easings.ElasticOut:ease(old, new, duration, time)
--     local progress = MathUtil.clamp(time / duration, 0, 1)
--     local animation = 2 ^ (-10 * progress) * math.sin(math.pi * (self.frequency * progress - 0.5)) + 1
--     return animation * (new - old) + old
-- end

return Easings