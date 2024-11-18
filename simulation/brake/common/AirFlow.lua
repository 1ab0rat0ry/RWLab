local ATM_PRESSURE = 101325
local AIR_DENSITY = 1.204
local AIR_SPECIFIC_GAS_CONSTANT = 287.053
local HEAT_RATIO = 1.4
local HEAT_RATIO_INC = HEAT_RATIO + 1
local HEAT_RATIO_DEC = HEAT_RATIO - 1
local CRITICAL_PRESSURE_RATIO = (2 / HEAT_RATIO_INC) ^ (HEAT_RATIO / HEAT_RATIO_DEC)
local CORRECTION_COEF = 0.7
local CELSIUS_TO_KELVIN = 273.15
local BAR_TO_PASCAL = 1e5
local CUBIC_METRES_TO_LITRES = 1000

local DEBUG = false
local Logger = require "Assets/1ab0rat0ry/RWLab/utils/Logger.out"

local logger = Logger:new(DEBUG, "!Flow.log")

---@class AirFlow
local AirFlow = {}

---`Source:` https://en.wikipedia.org/wiki/Orifice_plate#Compressible_flow and
---https://en.wikipedia.org/wiki/Choked_flow#Choking_in_change_of_cross_section_flow
---@param pressure1 number
---@param pressure2 number
---@param area number
---@param temperature number
---@return number
function AirFlow:get(pressure1, pressure2, area, temperature)
    local pressureIn = math.max(pressure1, pressure2) * BAR_TO_PASCAL + ATM_PRESSURE
    local pressureOut = math.min(pressure1, pressure2) * BAR_TO_PASCAL + ATM_PRESSURE
    local pressureRatio = pressureOut / pressureIn
    local baseComponent = CORRECTION_COEF * area / AIR_DENSITY * CUBIC_METRES_TO_LITRES

    if pressureRatio > CRITICAL_PRESSURE_RATIO then
        local component1 = 2 * self:getDensity(pressureIn, temperature) * pressureIn * HEAT_RATIO / HEAT_RATIO_DEC
        local component2 = pressureRatio ^ (2 / HEAT_RATIO) - pressureRatio ^ (HEAT_RATIO_INC / HEAT_RATIO)

        return baseComponent * math.sqrt(component1 * component2)
    else
        return baseComponent * math.sqrt(HEAT_RATIO * self:getDensity(pressureIn, temperature) * pressureIn * CRITICAL_PRESSURE_RATIO)
    end
end

function AirFlow:getSpeedOfSound(temperature)
    return math.sqrt(1 + temperature / CELSIUS_TO_KELVIN)
end

function AirFlow:getDensity(pressure, temperature)
    return pressure / (AIR_SPECIFIC_GAS_CONSTANT * (temperature + CELSIUS_TO_KELVIN))
end

return AirFlow
