local MathUtil = {}

function MathUtil.clamp(num, min, max)
    if num < min then return min
    elseif num > max then return max
    end
    return num
end

function MathUtil.randomFloat(min, max)
    return math.random() * (max - min) + min
end

function MathUtil.randomGaussian(mean, variance)
    return math.sqrt(-2 * variance * math.log(math.random())) * math.cos(2 * math.pi * math.random()) + mean
end

function MathUtil.sign(num)
    return num < 0 and -1 or 1
end

function MathUtil.signedSqrt(num)
    return math.sqrt(math.abs(num)) * MathUtil.sign(num)
end

function MathUtil.round(num, places)
    local multi = 10 ^ (places or 0)
    return math.floor(num * multi + 0.5) / multi
end

function MathUtil.lerp(progress, old, new)
    return old + (new - old) * MathUtil.clamp(progress, 0, 1)
end

function MathUtil.inverseLerp(value, min, max)
    return MathUtil.clamp((value - min) / (max - min), 0, 1)
end

function MathUtil.customSqrt(num, coef)
    local coefSquared = coef ^ 2
    return (math.sqrt(num + coefSquared) - coef) / (math.sqrt(1 + coefSquared) - coef)
end

return MathUtil