local RaycastTrace = {
    tileids = {}
}

function RaycastTrace:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RaycastTrace:clear()
    self.tileids = {}
end

function RaycastTrace:add_tileid(tileid)
    self.tileids[tileid] = true
end

function RaycastTrace:add_traces(other_raycast_trace)
    for other_tileid in pairs(other_raycast_trace.tileids) do
        self.tileids[other_tileid] = true
    end
end

function RaycastTrace:is_tileid_recorded(tileid)
    return self.tileids[tileid] ~= nil
end

return RaycastTrace