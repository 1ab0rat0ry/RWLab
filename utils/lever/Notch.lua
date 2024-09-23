local Notch = {}

Notch.position = 0
Notch.minRange = 0
Notch.maxRange = 0
Notch.arretated = true

function Notch:new(position, arretated)
    local o = setmetatable({}, self)
    self.__index = self
    o.position = position
    o.arretated = arretated
    return o
end

return Notch