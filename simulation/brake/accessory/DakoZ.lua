---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"

local CONTROL_VALVE_CLOSE_THRESHOLD = -0.1
local CONTROL_VALVE_OPEN_THRESHOLD = 0

local VENTILATION_VALVE_CLOSE_THRESHOLD = 0.075
local VENTILATION_VALVE_OPEN_THRESHOLD = 0.08

local CONTROL_CHOKE = 0.5
local VENTILATION_CHOKE = 40

---@class DakoZ
---@field public turnOffValve boolean
---@field private controlChamber Reservoir
---@field private expansionRes Reservoir
local DakoZ = {
    turnOffValve = true,
    controlChamber = {},
    expansionRes = {}
}
DakoZ.__index = DakoZ

---@return DakoZ
function DakoZ:new()
    ---@type DakoZ
    local obj = {
        controlChamber = Reservoir:new(0.3),
        expansionRes = Reservoir:new(10)
    }
    obj = setmetatable(obj, self)
    obj.controlChamber.pressure = 5

    return obj
end

---@param deltaTime number
---@param brakePipe Reservoir
---@param auxiliaryRes Reservoir
function DakoZ:update(deltaTime, brakePipe, distributor)
    local controlValve = MathUtil.inverseLerp(
        distributor.auxiliaryRes.pressure - brakePipe.pressure,
        CONTROL_VALVE_CLOSE_THRESHOLD,
        CONTROL_VALVE_OPEN_THRESHOLD
    )
    local ventilationValve = MathUtil.inverseLerp(
        self.controlChamber.pressure - brakePipe.pressure,
        VENTILATION_VALVE_CLOSE_THRESHOLD,
        VENTILATION_VALVE_OPEN_THRESHOLD
    )

    self.controlChamber:equalize(brakePipe, deltaTime, CONTROL_CHOKE * controlValve)
    brakePipe:equalize(self.expansionRes, deltaTime, VENTILATION_CHOKE * ventilationValve)
    self.expansionRes:vent(deltaTime)
end

return DakoZ