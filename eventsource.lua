local Util = require "core.util"

local EventSource = Util.newClass()

--- Initialize EventSource object
-- Sub class's init should call super class's init
-- @param o     Table. The object to be initialized
-- @param opt   Table. Options
EventSource.init = function (self)
    self.events = {}
end

--- Add an event listener
-- @param e         String. Event name
-- @param listener  Callable. Event handler
EventSource.addListener = function (self, e, listener)
    local l = self.events[e]
    if not l then
        self.events[e] = listener
        return
    end
    if type(l) == "table" then
        l[#l + 1] = listener
    else
        self.events[e] = {l, listener}
    end
end

--- Shortcut of addListener
EventSource.on = EventSource.addListener

EventSource.once = function (self, e, listener)
    local g
    g = function (...)
        self:removeListener(e, g)
        listener(...)
    end
    self:on(e, g)
end

--- Remove an event listener
-- @param e         String. Event name
-- @param listener  Callable. Event listener to be removed
EventSource.removeListener = function (self, e, listener)
    local l = self.events[e]
    if l == listener then
        self.events[e] = nil
        return
    end
    if type(l) == "table" then
        for i = 1, #l do
            if l[i] == listener then
                table.remove(l, i)
                return
            end
        end
    end
end


EventSource.removeAllListeners = function (self, e)
    if not e then
        self.events = {}
        return
    end
    self.events[e] = nil
end

--- Emit an event
-- @param e     String. Event name
EventSource.emit = function (self, e, ...)
    local l = self.events[e]
    if not l then
        return
    end
    if type(l) == "function" then
        l(...)
        return
    end

    local f = {}
    for i = 1, #l do
        f[i] = l[i]
    end
    for i = 1, #f do
        f[i](...)
    end
end

EventSource.emitOnce = function (self, e, ...)
    local l = self.events[e]
    if not l then
        return
    end

    if type(l) == "function" then
        l(...)
        return
    end

    local f = {}
    for i = 1, #l do
        f[i] = l[i]
    end
    for i = 1, #l do
        if f[i](...) then
            return
        end
    end
end

return EventSource
