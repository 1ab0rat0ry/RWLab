---@class ArrayList
---@field public length number
---@field public elements table
local ArrayList = {
    length = 0,
    elements = {}
}
ArrayList.__index = ArrayList

---@return ArrayList
function ArrayList:new()
    ---@type ArrayList
    local obj = {}
    obj = setmetatable(obj, self)

    return obj
end

---Adds element to the end of array list.
---@param element any
function ArrayList:add(element)
    self.length = self.length + 1
    self.elements[self.length] = element
end

---Removes elemnt from array list.
---@param element any
function ArrayList:remove(element)
    for i, v in pairs(self.elements) do
        if v == element then v = nil end
        if v == nil then
            v = self.elements[i + 1]
            self.elements[i + 1] = nil
        end
    end
end

---Return reversed array list.
---@return ArrayList reversed array list
function ArrayList:reversed()
    ---@type ArrayList
    local reversedList = {}

    for i, v in ipairs(self.elements) do
        reversedList[self.length - i + 1] = v
    end

    return reversedList
end

---Returns element at specified index.
---@param index number
---@return any
function ArrayList:getAt(index)
    return self.elements[index]
end

---Return specified element.
---@param element any
---@return any
function ArrayList:get(element)
    for _, v in pairs(self.elements) do
        if v == element then return v end
    end
end

---Return first element.
---@return any
function ArrayList:getFirst()
    return self.elements[1]
end

---Returns last element.
---@return any
function ArrayList:getLast()
    return self.elements[self.length]
end

---Removes all elements from array list.
function ArrayList:clear()
    for _, v in pairs(self.elements) do v = nil end
end

return ArrayList