Rigidbody {}

Rigidbody.prototype = {r = 0}

Rigidbody.mt = {}

function Rigidbody.new (o)
    setmetatable( o, Rigidbody.mt )
    return o
end

Rigidbody.mt.__index = function (table, key)
    return Rigidbody.prototype[key]
end

