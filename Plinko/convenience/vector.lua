Vector2 = { 
    x=0, y=0 
}

function Vector2: init (xp, yp)
    local v = {}
    setmetatable(v, self)
    self.__index = self
    v.x = xp
    v.y = yp
    return v
end

function Vector2.zero() return Vector2: init (0, 0) end
function Vector2.one() return Vector2: init (1, 1) end

function Vector2.__add (v1, v2)
    return Vector2: init ( v1.x + v2.x, v1.y + v2.y )
end

function Vector2.__sub (v1, v2)
    return Vector2: init ( v1.x - v2.x, v1.y - v2.y )
end

function Vector2.__eq (v1, v2)
    return (v1.x == v2.x) and (v1.y == v2.y)
end

function Vector2.__unm (v)
    return Vector2: init ( -v.x, -v.y )
end

function Vector2: scale (a)
    return Vector2: init ( a * self.x, a * self.y )
end

function Vector2.__mul (v1, v2)
    return v1.x * v2.x + v1.y * v2.y 
end

function Vector2.__div (v, a)
    return Vector2: init ( v.x / a, v.y / a )
end

function Vector2: intensity()
    return math.sqrt( Vector2: power() )
end

-- we will avoid using sqrt whenever possible
function Vector2: power()
    return self.x * self.x + self.y * self.y
end

function Vector2: normalized() 
    local i = Vector2: intensity()
    return Vector2: init (self.x / i, self.y / i)
end
