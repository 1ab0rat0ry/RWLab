local MathUtil = require "Assets/1ab0rat0ry/Common/script/utils/math/MathUtil.out"
local Stopwatch = require "Assets/1ab0rat0ry/Common/script/utils/Stopwatch.out"
local Logger = require "Assets/1ab0rat0ry/Common/script/utils/Logger.out"
local logger = Logger:new(false, "Adhesion.log")

local Seasons = {
    SPRING = 0,
    SUMMER = 1,
    AUTUMN = 2,
    WINTER = 3
}
local Precipitation = {
    RAIN = 0,
    SLEET = 1,
    HAIL = 2,
    SNOW = 3
}
local CoefValues = {
    CLEAR = 1.0,
    WET = 0.6,
    RAIN = 0.9,
    WINTER = 0.9,
    SNOW = 0.8,
    ICE = 0.5,
    LEAVES = 0.5
}
local CoefTimes = {
    CLEAR = 600,
    WET = 120,
    RAIN = 300,
    SNOW = 360,
    ICE = 300
}

local TUNNEL_DIST_FOR_MAX_COEF = 15
local SANDING_DIST_FOR_MAX_COEF = 5
local SANDING_COEF_MAX_ADDITION = 0.2
local COEF_LOSE_RATE = 5
local COEF_RECOVER_RATE = 0.5
local MAX_WHEEL_COEF = 0.78
local MIN_WHEEL_COEF = 0.6
local WHEEL_DIRT_DIST = 1000
local WHEEL_CLEAN_DIST = 5000

local Adhesion = {}

Adhesion.tunnelTime = 0
Adhesion.sandingTime = 0

Adhesion.environmentCoef = 1
Adhesion.environmentCoefTarget = 1
Adhesion.lastEnvironmentCoefTarget = 1
Adhesion.ambientCoef = 1
Adhesion.sandingCoef = 0
Adhesion.wheelCoef = 0.78

Adhesion.randomStopwatch = Stopwatch:new()
Adhesion.randomDelay = math.random(60, 180)
Adhesion.randomCoefTarget = 0
Adhesion.randomCoef = 0

Adhesion.oscillationStopwatch = Stopwatch:new()
Adhesion.oscillationDelay = math.random(1, 10)
Adhesion.oscillationCoefTarget = 1
Adhesion.oscillationCoef = 1

Adhesion.totalCoef = 1

function Adhesion:initialise(temperature, precipitationType, precipitationDensity)
    if precipitationDensity > 0 then
        if precipitationType == Precipitation.SNOW then
            self.environmentCoefTarget = temperature <= 0 and CoefValues.ICE or CoefValues.SNOW
        else
            self.environmentCoefTarget = precipitationDensity < 0.3 and CoefValues.WET or CoefValues.RAIN
        end
    else self.environmentCoefTarget = CoefValues.CLEAR
    end
    self.environmentCoef = self.environmentCoefTarget
    self.randomCoefTarget = MathUtil.randomFloat(-0.05, 0.05)
    self.randomCoef = MathUtil.randomFloat(-0.05, 0.05)
end

function Adhesion:update(deltaTime, temperature, precipitationType, precipitationDensity)
    self:updateEnvironmentCoef(deltaTime, temperature, precipitationType, precipitationDensity)
    self:updateAmbientCoef(deltaTime, precipitationDensity)
    self:updateSandingCoef(deltaTime)

    self.totalCoef = self.ambientCoef + self.sandingCoef
end

function Adhesion:getEnvironmentCoefTarget(temperature, precipitationType, precipitationDensity)
    if precipitationDensity > 0.01 then
        if precipitationDensity < 0.3 and self.environmentCoef > 0.97 then
            return CoefValues.WET, CoefTimes.WET / (1 + precipitationDensity)
        else
            return CoefValues.RAIN, CoefTimes.RAIN / (1 + precipitationDensity)
        end
    end
    return CoefValues.CLEAR, CoefTimes.CLEAR
end

function Adhesion:updateEnvironmentCoef(deltaTime, temperature, precipitationType, precipitationDensity)
    local newEnvironmentCoefTarget, coefChangeTime = self:getEnvironmentCoefTarget(temperature, precipitationType, precipitationDensity)

    if self.environmentCoefTarget ~= newEnvironmentCoefTarget then
        self.lastEnvironmentCoefTarget = self.environmentCoefTarget
        self.environmentCoefTarget = newEnvironmentCoefTarget
    end
    coefChangeTime = coefChangeTime / math.abs(self.lastEnvironmentCoefTarget - self.environmentCoefTarget)

    if self.environmentCoef ~= self.environmentCoefTarget then
        local coefDiff = self.environmentCoefTarget - self.environmentCoef
        local coefChangeRate = deltaTime / coefChangeTime
        self.environmentCoef = self.environmentCoef + MathUtil.clamp(coefDiff, -coefChangeRate, coefChangeRate)
    end
end

function Adhesion:updateWheelCoef(deltaTime)
    
end

function Adhesion:updateAmbientCoef(deltaTime, precipitationDensity)
    local oscillationChance = (0.1 + precipitationDensity) * math.abs(Call("GetSpeed")) * 3.6 / 500
    self.ambientCoef = self.environmentCoef

    if Call("GetIsInTunnel") > 0 then
        local maxTunnelTime = TUNNEL_DIST_FOR_MAX_COEF / math.abs(Call("GetSpeed"))
        self.tunnelTime = math.min(maxTunnelTime, self.tunnelTime + deltaTime)
    else self.tunnelTime = math.max(0, self.tunnelTime - deltaTime)
    end

    if self.tunnelTime > 0 then
        local tunnelDist = math.abs(Call("GetSpeed")) * self.tunnelTime
        local tunnelProgress = tunnelDist / TUNNEL_DIST_FOR_MAX_COEF
        self.ambientCoef = MathUtil.lerp(tunnelProgress, self.environmentCoef, CoefValues.CLEAR)
    end

    if self.randomStopwatch:hasFinished(self.randomDelay) then
        self.randomDelay = math.random(60, 180)
        self.randomCoefTarget = MathUtil.randomFloat(-0.05, 0.05)
        self.randomStopwatch:reset()
    end

    if self.randomCoef ~= self.randomCoefTarget then
        local coefDiff = self.randomCoefTarget - self.randomCoef
        local changeRate = deltaTime / 1000
        self.randomCoef = self.randomCoef + MathUtil.clamp(coefDiff, -changeRate, changeRate)
    end

    -- if math.random() < 0.1 * math.abs(Call("GetSpeed")) * 3.6 / 200 then
    --     self.oscillationCoefTarget = MathUtil.randomFloat(1.1, 1.2)
    -- end

    if math.random() < oscillationChance and self.oscillationStopwatch:hasFinished(self.oscillationDelay) then
        self.oscillationCoefTarget = MathUtil.randomFloat(0.8, 0.99) * self.ambientCoef
        self.oscillationDelay = math.random(1, 10)
        self.oscillationStopwatch:reset()
    end

    if self.oscillationCoef ~= self.oscillationCoefTarget then
        local coefDiff = self.oscillationCoefTarget - self.oscillationCoef
        local changeRate = coefDiff < 0 and COEF_LOSE_RATE or COEF_RECOVER_RATE

        changeRate = changeRate * (math.abs(coefDiff) + 0.5) * math.random() * deltaTime
        self.oscillationCoef = self.oscillationCoef + MathUtil.clamp(coefDiff, -changeRate, changeRate)
    else self.oscillationCoefTarget = 1
    end

    -- self.ambientCoef = self.ambientCoef + self.randomCoef
    self.ambientCoef = self.ambientCoef * self.oscillationCoef * self.wheelCoef
end

function Adhesion:updateSandingCoef(deltaTime)
    if self.sanding then
        local maxSandingTime = SANDING_DIST_FOR_MAX_COEF / math.abs(Call("GetSpeed"))
        self.sandingTime = math.min(maxSandingTime, self.sandingTime + deltaTime)
    else self.sandingTime = math.max(0, self.sandingTime - deltaTime)
    end

    local sandingDist = math.abs(Call("GetSpeed")) * self.sandingTime
    local sandingProgress = sandingDist / SANDING_DIST_FOR_MAX_COEF
    self.sandingCoef = MathUtil.lerp(sandingProgress, 0, SANDING_COEF_MAX_ADDITION)
end

return Adhesion