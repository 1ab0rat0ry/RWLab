local ArrayList = {
    length = 0,
    elements = {}
}

function ArrayList:new()
    local o = setmetatable({}, self)
    self.__index = self

    return o
end

function ArrayList:add(element)
    self.elements[self.length + 1] = element
end

function ArrayList:remove(element)
    for i, v in pairs(self.elements) do
        if v == element then v = nil end
        if v == nil then
            v = self.elements[i + 1]
            self.elements[i + 1] = nil
        end
    end
end

function ArrayList:reversed()
    local reversedList = {}

    for i, v in ipairs(self.elements) do
        reversedList[self.length - i + 1] = v
    end

    return reversedList
end

function ArrayList:getAt(index)
    return self.elements[index]
end

function ArrayList:get(element)
    for _, v in pairs(self.elements) do
        if v == element then return v end
    end
end

function ArrayList:clear()
    for _, v in pairs(self.elements) do v = nil end
end

return ArrayList