---@class Test
---@field private name string
---@field private timePassed number
---@field private timeSlice number
---@field private timeStep number
---@field private testFun function
local Test = {
    name = "",
    timePassed = 0,
    timeSlice = 0,
    timeStep = 0,
    terminate = false,
    testFun = nil
}

---@param name string
---@param testFun function
---@return Test
function Test:new(name, timeSlice, timeStep, testFun)
    ---@type Test
    local obj = {
        name = name,
        timePassed = 0,
        timeSlice = timeSlice,
        timeStep = timeStep,
        testFun = testFun
    }
    obj = setmetatable(obj, self)

    return obj
end

---run
function Test:run()
    local message = ""

    while self.timePassed < self.timeSlice do
        message = self:testFun(self.timeStep)

        if self.terminate then return end
        self.timePassed = self.timePassed + self.timeStep
    end
    self:failed(message)
end

---passed
---@param message string
function Test:passed(message)
    self.terminate = true
    SysCall("ScenarioManager:ShowMessage", "Test: "..self.name.." PASSED", "Time: "..self.timePassed.." "..message, 1)
end

---failed
---@param message string
function Test:failed(message)
    self.terminate = true
    SysCall("ScenarioManager:ShowMessage", "Test: "..self.name.." FAILED", "Time: "..self.timePassed.." "..message, 1)
end

return Test