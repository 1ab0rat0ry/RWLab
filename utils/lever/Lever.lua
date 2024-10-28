local Notch = require "Assets.1ab0rat0ry.Common.script.utils.lever.Notch.out"
local Lever = {}

Lever.notches = {}
Lever.controlNameUp = ""
Lever.controlNameDown = ""
Lever.minPos = 0
Lever.maxPos = 1
Lever.position = 0
Lever.speed = 1

function Lever:new(controlNameUp, controlNameDown)
    local o = setmetatable({}, self)
    self.__index = self
    o.controlNameUp = controlNameUp
    o.controlNameDown = controlNameDown
    return o
end

function Lever:addNotch(position, arretated, name)
    local notchIndex = table.getn(self.notches) + 1

    self.notches[notchIndex] = Notch:new(position, arretated)
    self[name] = notchIndex
end

function Lever:update(deltaTime)
    if Call("GetControlValue", self.controlNameUp, 0) > 0.5 then
        self.position = math.min(self.minPos, self.position + self.speed * deltaTime)
    elseif Call("GetControlValue", self.controlNameDown, 0) > 0.5 then
        self.position = math.max(self.maxPos, self.position - self.speed * deltaTime)
    end
end

return Lever