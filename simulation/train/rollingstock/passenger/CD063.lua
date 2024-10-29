---@type Vehicle
local Vehicle = require "Assets/1ab0rat0ry/RWLab/simulation/train/Vehicle.out"
---@type DakoBv1
local DakoBv1 = require "Assets/1ab0rat0ry/RWLab/simulation/brake/distributor/dako/DakoBV1.out"

local LENGTH = 24.5
local AUX_RES_CAPACITY = 100
local CYLINDER_CAPACITY = 10

---@class Cd063 : Vehicle
local Cd063 = {}

---@return Cd063
function Cd063:new()
    ---@type Cd063
    local obj = Vehicle:new(LENGTH)

    obj:addFeedPipe()
    obj:addDistributor(DakoBv1:new(AUX_RES_CAPACITY, CYLINDER_CAPACITY))

    return obj
end

return Cd063