local Util = {}

local packn = function (...)
  return {n = select('#', ...), ...}
end

local unpackn = function (t)
  return (table.unpack or unpack)(t, 1, t.n)
end

local merge = function (ta, tb)
    local tr = {n = ta.n + tb.n}
    for i = 1, ta.n do
        tr[i] = ta[i]
    end
    local na = ta.n
    for j = 1, tb.n do
        tr[na + j] = tb[j]
    end
    return tr
end

Util.packn = packn
Util.unpackn = unpackn

Util.bind = function (f, ...)
    local pack = table.pack or packn
    local unpack = table.unpack or unpackn
    local a = pack(...)
    return function (...)
        local b = merge(a, pack(...))
        return f(unpack(b, 1, b.n))
    end
end

local BaseClass = {}
BaseClass.__index = BaseClass

BaseClass.new = function (self, ...)
    local o = {}
    setmetatable(o, self)
    o.init(o, ...)
    return o
end

BaseClass.init = function ()
end

Util.extend = function (base)
    local sub = base:new()
    sub.__index = sub
    return sub
end

Util.newClass = function ()
    return Util.extend(BaseClass)
end

Util.addEventListeners = function (stub)
    for i = 1, #stub do
        stub[i][1]:on(stub[i][2], stub[i][3])
    end
end

Util.removeEventListeners = function (stub)
    for i = 1, #stub do
        stub[i][1]:removeListener(stub[i][2], stub[i][3])
    end
end

return Util
