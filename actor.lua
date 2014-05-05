local Util = require "core.util"
local EventSource = require "core.eventsource"
local InputBus = require "core.inputbus"

local Actor = Util.newClass()
Actor.ebus = EventSource:new()
Actor.inputBus = InputBus:new()

Actor.pendings = {}
Actor.newid = 1

Actor.flush = function ()
    while #Actor.pendings > 0 do
        local l = Actor.pendings
        Actor.pendings = {}
        for i = 1, #l do
            l[i]()
        end
    end
end

Actor.logMsg = function(self, msg)
    local name = self.name or 'unnamed'
    return 'Actor '..self.id..' '..name..' '..msg
end

Actor.init = function (self, f, ...)
    local args
    if select('#', ...) > 0 then
        args = Util.packn(...)
    end
    local g = function(...)
        if args then
            f(self, Util.unpackn(args), ...)
        else
            f(self, ...)
        end
        if self.parent then
            local p = self.parent
            p.waiting.n = p.waiting.n - 1
            p.waiting[self] = nil
            if p.waiting.n == 0 then
                p:schedule()
            end
        end
    end
    self.id = Actor.newid
    Actor.newid = Actor.newid + 1
    self.co = coroutine.wrap(g)
end

Actor.abort = function (self, reason, ...)
    if self.aborted then
        return
    end
    self.aborted = true
    if self.onAbort then
        self:onAbort(reason, ...)
    end
end

Actor.wait = function (self, child)
    child.parent = self
    local w = {}
    w[child] = true
    w.n = 1
    self.waiting = w

    child:schedule()
    coroutine.yield()
    assert(w.n == 0)
    self.waiting = nil
end

Actor.waitAll = function (self, children)
    local w = {}
    for i = 1, #children do
        children[i].parent = self
        w[children[i]] = true
        children[i]:schedule()
    end
    w.n = #children
    self.waiting = w
    coroutine.yield()
    assert(w.n == 0)
    self.waiting = nil
end

Actor.notify = function(self, msg, ...)
    Actor.ebus:emit(msg, ...)
end

Actor.request = function(self, msg, ...)
    local args = Util.packn(...)
    args.n = args.n + 1
    args[args.n] = Util.bind(self.scheduleAndRun, self)

    Actor.pendings[#Actor.pendings+1] = function()
        Actor.ebus:emit(msg, Util.unpackn(args))
    end
    return coroutine.yield()
end

local unpack = table.unpack or unpack

Actor.getInput = function (self, inputs)
    for i = 1, #inputs do
        Actor.inputBus:on(inputs[i], self)
    end
    return coroutine.yield()
end

local unpack = table.unpack or unpack

Actor.react = function(self, inputs)
    local events = {}
    for e, f in pairs(inputs) do
        events[#events + 1] = e
    end
    local args = Util.packn(self:getInput(events))
    local f = inputs[args[1]]
    if f then
        return args[1], f(unpack(args, 2, args.n))
    else
        return args[1]
    end
end

Actor.schedule = function (self, ...)
    if self.aborted then
        return
    end
    if select('#', ...) > 0 then
        Actor.pendings[#Actor.pendings+1] = Util.bind(self.co, ...)
    else
        Actor.pendings[#Actor.pendings+1] = self.co
    end
end

Actor.scheduleAndRun = function(self, ...)
    self:schedule(...)
    Actor.flush--[[static]]()
end

return Actor
