local ATM_PRESSURE = 101325 --Pa
local AIR_DENSITY = 1.204 -- kg/m^3, at 20°C and 101 325 Pa
local HEAT_RATIO = 1.4
local CELSIUS_TO_KELVIN = 273.15
local BAR_TO_PASCAL = 1e5

local DEBUG = false
local Logger = require "Assets/1ab0rat0ry/RWLab/utils/Logger.out"

local logger = Logger:new(DEBUG, "!Flow.log")

---@class AirFlow
local AirFlow = {}

function AirFlow:get(pressure1, pressure2, area, temperature)
    if pressure2 > pressure1 then return self:get(pressure2, pressure1, area, temperature) end
    pressure1 = pressure1 * BAR_TO_PASCAL + ATM_PRESSURE
    pressure2 = pressure2 * BAR_TO_PASCAL + ATM_PRESSURE

    local pressureRatio = pressure2 / pressure1;
    local heatRatioInc = HEAT_RATIO + 1
    local heatRatioDec = HEAT_RATIO - 1
    local threshold = (2 * HEAT_RATIO / heatRatioInc) ^ (HEAT_RATIO / heatRatioDec)
    local baseComponent = pressure1 * area / self:getSpeedOfSound(temperature) / AIR_DENSITY

    if pressureRatio > threshold then
        local component1 = (2 * HEAT_RATIO ^ 2) / heatRatioDec
        local component2 = pressureRatio ^ (2 / HEAT_RATIO)
        local component3 = 1 - pressureRatio ^ (heatRatioDec / HEAT_RATIO)
        logger:info("Subsonic P1: "..pressure1.." P2: "..pressure2.." R: "..pressureRatio.." T: "..threshold.." Flow: "..baseComponent * math.sqrt(component1 * component2 * component3))

        return baseComponent * math.sqrt(component1 * component2 * component3)
    else
        logger:info("Choked P1: "..pressure1.." P2: "..pressure2.." R: "..pressureRatio.." T: "..threshold.." Flow: "..baseComponent * HEAT_RATIO * (2 / heatRatioInc) ^ (heatRatioInc / (2 * heatRatioDec)))
        return baseComponent * HEAT_RATIO * (2 / heatRatioInc) ^ (heatRatioInc / (2 * heatRatioDec))
    end
end

function AirFlow:getSpeedOfSound(temperature)
    return math.sqrt(1 + temperature / CELSIUS_TO_KELVIN)
end

return AirFlow
