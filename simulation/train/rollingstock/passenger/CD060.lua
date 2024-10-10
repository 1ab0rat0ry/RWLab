local Vehicle = require "Assets/1ab0rat0ry/RWLab/simulation/train/Vehicle.out"
local Bv1 = require "Assets/1ab0rat0ry/RWLab/simulation/brake/distributor/dako/DakoBV1.out"

local LENGTH = 24.5

local Cd063 = {}

function Cd063:new()
    local o = Vehicle:new(LENGTH, Bv1:new())

    o:addFeedPipe()
    o:addDistributor(Bv1:new())

    return o
end

return Cd063