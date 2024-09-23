local Logger = {}

Logger.log = true
Logger.debug = true
Logger.file = "CD460.log"

function Logger:new(log, file)
    local o = setmetatable({}, self)
    self.__index = self
    o.log = log
    o.file = file or "CD460.log"
    return o
end

function Logger:info(message)
    if not self.log then return end
    local file = assert(io.open(self.file, "a"))

    file:write(message.."\n")
    file:close()
end

return Logger