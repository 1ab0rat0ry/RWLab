local ArrayList = {}

function ArrayList:add(element)
    self[table.getn(self) + 1] = element
end

function ArrayList:clear()
    for k, _ in ipairs(self) do
        self[k] = nil
    end
end