local MathUtil = require "utils.math.MathUtil"

local DOUBLE_PI = 2 * math.pi
local SECONDS_IN_DAY = 86400
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
local Temperatures = {
    SPRING = {min = 8, max = 15},
    SUMMER = {min = 25, max = 35},
    AUTUMN = {min = 5, max = 13},
    WINTER = {min = -10, max = 3}
}
local TempModifiers = {
    RAIN = {min = -5, max = 0},
    SLEET = {min = -6, max = -2},
    HAIL = {min = -7, max = -3},
    SNOW = {min = -3, max = 2}
}

local Environment = {
    season = -1,
    timeOfDay = -1, -- 0 to 1
    precipitationType = -1,
    precipitationIntensity = -1,

    minDayTemp = -1,
    maxDayTemp = -1,
    tempChangeCoeff = -1,
    tempChangeCoeffTarget = -1,
    tempChangeRate = -1,
    tempChangeRateTarget = -1,
    temperature = -1
}

function Environment:initialise()
    self.season = SysCall("ScenarioManager:GetSeason")

    -- self.tempTarget = -math.cos(DOUBLE_PI * (self.timeOfDay - 0.16))
    self.tempChangeCoeffTarget = MathUtil.randomFloat(0.9, 1.1)
    self.tempChangeCoeff = MathUtil.randomFloat(0.9, 1.1)
    self.tempChangeRateTarget = DOUBLE_PI * math.sin(DOUBLE_PI * (self.timeOfDay - 0.16))
    self.tempChangeRate = self.tempChangeRateTarget * self.tempChangeCoeff
    self.temperature = self.tempTarget
end

function Environment:update(deltaTime)
    self.timeOfDay = SysCall("ScenarioManager:GetTimeOfDay") / SECONDS_IN_DAY
    self.precipitationType = SysCall("WeatherController:GetCurrentPrecipitationType")
    self.precipitationIntensity = SysCall("WeatherController:GetPrecipitationDensity")

    -- self.tempTarget = -math.cos(DOUBLE_PI * (self.timeOfDay - 0.16))
    self.tempChangeRateTarget = DOUBLE_PI * math.sin(DOUBLE_PI * (self.timeOfDay - 0.16))
    self.tempChangeRate = self.tempChangeRateTarget * MathUtil.randomFloat(0.9, 1.1)
    self.temperature = self.temperature + self.tempChangeRate
end
