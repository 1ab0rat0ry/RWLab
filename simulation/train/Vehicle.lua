local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Reservoir.out"
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"

local PIPE_DIAMETER = 0.3175 -- dm
local PIPE_RADIUS = PIPE_DIAMETER / 2
local PIPE_CROSS_SECTION_AREA = math.pi * PIPE_RADIUS ^ 2
local HOSE_LENGTH = 5 -- dm

local Vehicle = {}

Vehicle.length = 0
Vehicle.pipeCapacity = 0

Vehicle.brakePipe = {}
Vehicle.feedPipe = nil
Vehicle.brakeValve = nil
Vehicle.distributor = nil
Vehicle.accelerator = nil

function Vehicle:new(length)
    local o = setmetatable({}, self)

    self.__index = self
    self.pipeCapacity = (10 * length + 4 * HOSE_LENGTH) * PIPE_CROSS_SECTION_AREA
    o.brakePipe = Reservoir:new(self.pipeCapacity)
    o.length = length
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

function Vehicle:addFeedPipe(mainResCapacity)
    self.feedPipe = Reservoir:new(self.pipeCapacity + (mainResCapacity or 0))
end

function Vehicle:addDistributor(distributor)
    self.distributor = distributor
end

function Vehicle:addBrakeValve(brakeValve)
    self.brakeValve = brakeValve
end

function Vehicle:addAccelerator(accelerator)
    self.accelerator = accelerator
end

return Vehicle