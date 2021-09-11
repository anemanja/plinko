require("convenience/vector")

--[[ 
    Game object's main features are sticking to the load/update/draw rhytm and the family hierarchy, taking care of it's children.
    Any element that is drawn should be a game object.
--]]
GameObject = {
    position = Vector2.zero(),
    size = Vector2:scale(100, Vector2.one()),
    zOrder = 0,
    imageName = "resources/images/empty.png",
    rigidbody = nil,
    children = nil
}

function GameObject: init ( g )
    local g = g or {}
    setmetatable(g, self)
    self.__index = self

    -- children must be initialized
    g.children = g.children or {}
    g.absolutePosition = self:updateAbsolutePosition()

    return g
end

function GameObject: addChild ( g )
    g.parent = self
    local i = 1
    for _, child in ipairs(self.children) do 
        if child.zOrder > g.zOrder then 
            table.insert( self.children, i, g )
            return
        end
        i = i + 1
    end
    table.insert( self.children, g )
end

function GameObject: removeChild (g)
    for _, child in ipairs(self.children) do
        if child == g then 
            child.parent = nil
            child = nil 
        end
    end
end

function GameObject: updateAbsolutePosition ()
    if self.parent == nil then return self.position end
    return self.position + self.parent:updateAbsolutePosition()
end

function GameObject: getRelativePositionOfAbsolute(newAbsolutePosition)
    local parentAbsolutePosition = Vector2:init(unpack(self.position))
    if parent then parentAbsolutePosition = parent.absolutePosition end
    return newAbsolutePosition - parentAbsolutePosition
end

function GameObject: load()
    -- image must be ready for drawing
    self.imageName = self.imageName or "resources/images/empty.png"
    self.image = love.graphics.newImage(self.imageName)

    -- prepare scale for drawing the image in the game object's size
    local imageW, imageH = self.image:getDimensions()
    self.imageScale = Vector2: init (self.size.x / imageW, self.size.y / imageH)

    -- call load for each child
    for _, child in ipairs(self.children) do
        child: load()
    end
end

function GameObject: update(dt)

    self.absolutePosition = self:updateAbsolutePosition()
    -- call load for each child
    for _, child in ipairs(self.children) do
        child: update(dt)
    end
end

function GameObject: draw()
    love.graphics.draw(self.image, self.absolutePosition.x, self.absolutePosition.y, 0, self.imageScale.x, self.imageScale.y)
    for _, child in ipairs(self.children) do
        child: draw()
    end
end