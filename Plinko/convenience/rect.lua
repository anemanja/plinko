require("convenience/vector")

Rect2 = { 
    x=0, y=0, 
    width=0, height=0 
}

function Rect2.zero() return Rect2: init(0, 0, 0, 0) end

function Rect2: init (x, y, w, h)
    local r = {}
    setmetatable(r, self)
    self.__index = self
    r.x = x
    r.y = y
    r.width = w
    r.height = h
    return r
end

function Rect2: getCenterPoint () 
    return Vector2: init(
        self.x + self.width/2,
        self.y + self.height/2
    )
end

function Rect2: getNearestPoint () 
    return Vector2: init( 
        self.x,
        self.y
    )
end

function Rect2: getFarthestPoint () 
    return Vector2: init( 
        self.x + self.width,
        self.y + self.height
    )
end

function Rect2.__eq (r1, r2)
    local d1 = r1: getNearestPoint() - r2: getFarthestPoint()
    local d2 = r2: getNearestPoint() - r1: getFarthestPoint()

    if d1.x > 0 or d1.y > 0 then return false end
    if d2.x > 0 or d2.y > 0 then return false end

    return true
end
