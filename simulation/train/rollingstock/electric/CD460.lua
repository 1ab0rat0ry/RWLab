---@type Vehicle
local Vehicle = require "Assets/1ab0rat0ry/RWLab/simulation/train/Vehicle.out"
---@type DakoBv1
local DakoBv1 = require "Assets/1ab0rat0ry/RWLab/simulation/brake/distributor/dako/DakoBV1.out"
---@type DakoBs2
local DakoBs2 = require "Assets/1ab0rat0ry/RWLab/simulation/brake/brakevalve/dako/DakoBS2.out"

local LENGTH = 24.5
local MAIN_RES_CAPACITY = 400
local AUX_RES_CAPACITY = 100
local CYLINDER_CAPACITY = 10
local BS2_NOTCHES = {
    RELEASE = 0,
    RUNNING = 0.1,
    NEUTRAL = 0.18,
    MIN_REDUCTION = 0.28,
    MAX_REDUCTION = 0.78,
    CUTOFF = 0.86,
    EMERGENCY = 1
}

---@class Cd460 : Vehicle
local Cd460 = {}

---@return Cd460
function Cd460:new()
    ---@type Cd460
    local obj = Vehicle:new(LENGTH)

    obj:addFeedPipe(MAIN_RES_CAPACITY)
    obj:addDistributor(DakoBv1:new(AUX_RES_CAPACITY, CYLINDER_CAPACITY))
    obj:addBrakeValve(DakoBs2:new(BS2_NOTCHES))

    return obj
end

return Cd460