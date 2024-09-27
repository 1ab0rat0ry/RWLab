local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Reservoir.out"
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"

local PIPE_DIAMETER = 0.3175 -- unit: dm
local PIPE_RADIUS = PIPE_DIAMETER / 2

local Vehicle = {}

Vehicle.length = 0
Vehicle.feedPipe = nil
Vehicle.brakePipe = nil
Vehicle.distributor = nil
Vehicle.brakeValve = nil

function Vehicle:new(length, distributor, brakeValve)
    local o = setmetatable({}, self)
    self.__index = self

    o.length = length
    o.feedPipe = Reservoir:new((10 * length + 4 * 5) * math.pi * PIPE_RADIUS ^ 2 + 400)
    o.brakePipe = Reservoir:new((10 * length + 4 * 5) * math.pi * PIPE_RADIUS ^ 2)
    o.distributor = distributor
    o.brakeValve = brakeValve
    o.brakePipe.pressure = 5
    return o
end

function Vehicle:update(timeDelta)
    if self.brakeValve then self.brakeValve:update(timeDelta, self.feedPipe, self.brakePipe) end
    if self.distributor then self.distributor:update(timeDelta, self.brakePipe) end
end

function Vehicle:getBrakeControl()
    -- local cylinderDiameter = 60.96 --cm
    -- local cylinderRadius = cylinderDiameter / 2 --cm
    -- local pistonSurface = math.pi * cylinderRadius ^ 2
    -- local speed = math.abs(Call("GetSpeed")) * 3.6
    local brakePadPressure = MathUtil.inverseLerp(self.distributor.cylinder.pressure, 0.2, 3.8)
    -- local pressureComponent = (16 * brakePadPressure + 100) / (80 * brakePadPressure + 100)
    -- local speedComponent = (speed + 100) / (5 * speed + 100)
    -- local frictionCoef = 0.6 * pressureComponent * speedComponent
    -- local brakeForce = brakePadPressure * frictionCoef
    return brakePadPressure
end

return Vehicle