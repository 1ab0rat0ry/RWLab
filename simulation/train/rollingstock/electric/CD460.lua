local Vehicle = require "Assets/1ab0rat0ry/RWLab/simulation/train/Vehicle.out"
local Bv1 = require "Assets/1ab0rat0ry/RWLab/simulation/brake/distributor/dako/DakoBV1.out"
local Bs2 = require "Assets/1ab0rat0ry/RWLab/simulation/brake/brakevalve/dako/DakoBS2.out"

local LENGTH = 24.5
local MAIN_RES_CAPACITY = 400
local BS2_NOTCHES = {
    RELEASE = 0,
    RUNNING = 0.1,
    NEUTRAL = 0.18,
    MIN_REDUCTION = 0.28,
    MAX_REDUCTION = 0.78,
    CUTOFF = 0.86,
    EMERGENCY = 1
}

local Cd460 = {}

function Cd460:new()
    local o = Vehicle:new(LENGTH, MAIN_RES_CAPACITY)

    o:addFeedPipe(MAIN_RES_CAPACITY)
    o:addDistributor(Bv1:new())
    o:addBrakeValve(Bs2:new(BS2_NOTCHES))

    return o
end

return Cd460