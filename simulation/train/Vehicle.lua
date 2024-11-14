---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/RWLab/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/RWLab/utils/math/MathUtil.out"

local PIPE_DIAMETER = 0.3175 --decimetres
local PIPE_RADIUS = PIPE_DIAMETER / 2 --decimetres
local PIPE_CROSS_SECTION_AREA = math.pi * PIPE_RADIUS ^ 2 --decimetres
local HOSE_LENGTH = 5 --decimetres

---@class Vehicle
---@field private length number
---@field private pipeCapcity number
---@field public brakePipe Reservoir
---@field private feedPipe Reservoir
---@field private brakeValve table
---@field private distributor table
---@field private accelerator table
local Vehicle = {
    length = 0,
    pipeCapacity = 0,
    --brakeBlocks = 0,
    --maxPressureForcePerBlock = 0,
    --maxBrakeForce = 0,

    brakePipe = {},
    feedPipe = nil,
    brakeValve = nil,
    distributor = nil,
    accelerator = nil
}
Vehicle.__index = Vehicle

---@param length number
---@return Vehicle
function Vehicle:new(length)
    ---@type Vehicle
    local obj = {
        length = length,
        pipeCapacity = (10 * length + 4 * HOSE_LENGTH) * PIPE_CROSS_SECTION_AREA,
        brakePipe = Reservoir:new((10 * length + 4 * HOSE_LENGTH) * PIPE_CROSS_SECTION_AREA),
    }
    obj = setmetatable(obj, self)
    obj.brakePipe.pressure = 5

    return obj
end

---Updates all systems and devices of vehicle.
---@param deltaTime number
function Vehicle:update(deltaTime)
    if self.brakeValve then self.brakeValve:update(deltaTime, self.feedPipe, self.brakePipe) end
    if self.distributor then self.distributor:update(deltaTime, self.brakePipe) end
    if self.accelerator then self.accelerator:update(deltaTime, self.brakePipe, self.distributor) end
end

---Calculates brake force.
---@return number brake force expressed as number between `0` and `1`
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

---@param mainResCapacity number
function Vehicle:addFeedPipe(mainResCapacity)
    self.feedPipe = Reservoir:new(self.pipeCapacity + (mainResCapacity or 0))
end

---@param distributor table
function Vehicle:addDistributor(distributor)
    self.distributor = distributor
end

---@param brakeValve table
function Vehicle:addBrakeValve(brakeValve)
    self.brakeValve = brakeValve
end

---@param accelerator table
function Vehicle:addAccelerator(accelerator)
    self.accelerator = accelerator
end

return Vehicle