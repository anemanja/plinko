require("vector")

GameObject = {}

function GameObject: init ( g )
    local g = g or {}
    setmetatable(g, self)
    self.__index = self
    if (g.children == nil) or (#g.children == 0) then
        g.children = {}
    end
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
            child = nil 
            g.parent = nil
        end
    end
end

function GameObject: load()
    for _, child in ipairs(self.children) do
        child: load()
    end
end

function GameObject: update()
    for _, child in ipairs(self.children) do
        child: update()
    end
end

function GameObject: draw()
    local parentPosition
    if self.parent == nil then 
        parentPosition = Vector2.zero
    else
        parentPosition = self.parent.position
    end

    local relativePosition = parentPosition + self.position
    love.graphics.ellipse("fill", relativePosition.x, relativePosition.y, self.size.x, self.size.y)
    for _, child in ipairs(self.children) do
        child: draw()
    end
end