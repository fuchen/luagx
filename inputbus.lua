local Util = require "core.util"
local EventSource = require "core.eventsource"

local InputBus = Util.newClass()

InputBus.init = function(self)
    self.events = {}
end

InputBus.on = function(self, input, actor)
    if not self.events[input] then
        self.events[input] = { actor }
    else
        local a = self.events[input]
        a[#a + 1] = actor
    end
end

InputBus.removeActor = function(self, actor)
    for e,arr in pairs(self.events) do
        for i = #arr, 1 do
            if arr[i] == actor then
                table.remove(arr, i)
            end
        end
    end
end

InputBus.emit = function (self, event, ...)
    local arr = self.events[event]
    if not arr or #arr == 0 then
        return
    end
    local target = arr[1]
    self:removeActor(target)
    target:scheduleAndRun(event, ...)
end

InputBus.emitShared = function(self, event, ...)
    local arr = self.events[event]
    if not arr or #arr == 0 then
        return
    end
    local targets = {}
    for i = 1, #arr do
        targets[i] = arr[i]
    end
    for i = 1, #targets do
        self:removeActor(targets[i])
    end
    for i = 1, #targets do
        targets[i]:scheduleAndRun(event, ...)
    end
end

return InputBus
