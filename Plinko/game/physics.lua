require("convenience/rect")
require("convenience/vector")
require("game/gameObject")

--[[ 
    Rigidbody is attached to a clueless Game Object and, just as a Zombie fungus would, 
    it takes over some of the main functions of the object and does its sinister work on top of them.
--]]
Rigidbody = {
    shape = "circle",
    velocity = nil,
    boundingBoxAnchor = nil, -- determines at 
    boundingBoxSize = nil, -- used only when shape == "rect"
    boundingBoxRadius = nil, -- used only when shape == "circle"
    mass = 1,
    collisionCategory = nil,
    collisionMask = nil, -- denotes what categories of rigibodies affect this rigidbody when they collide
    onCollide = function (self, r) end,
    force = nil,
    gameObject = nil,
    gameObjectsUpdate = nil,
    gameObjectsDraw = nil
}

function Rigidbody: init ( r )
    local r = r or {}

    -- we don't want to play if there is no game object to infect
    if r.gameObject == nil then return nil end
    setmetatable(r, self)
    self.__index = self

    -- we currently only support circles and rects :) and of those circle is default
    if r.shape ~= nil then
        if r.shape ~= "circle" and r.shape ~= "rect" then
            r.shape = "circle"
        end
    end

    if r.shape == "circle" then
        -- set bounding box as a circle containing the game object
        r.boundingBoxAnchor = r.boundingBoxAnchor or Vector2:init(0.5, 0.5)
        if r.gameObject.size.y < r.gameObject.size.x then
            r.boundingBoxRadius = r.boundingBoxRadius or r.gameObject.size.x / 2
        else
            r.boundingBoxRadius = r.boundingBoxRadius or r.gameObject.size.y / 2
        end
    end

    -- set a circular reference to self. this might be a bad practice, but we solemnly swear never to reference gameObject.rigidbody outside of this file. Game Object knows nothing about it, the good zombie host that it is, so we should be fine.
    r.gameObject.rigidbody = r

    -- sustitute game object's update for rigidbody's own
    r.gameObjectsUpdate = r.gameObject.update
    r.gameObject.update = r.update

    -- rigidbody only usurps the game object's draw for debbugging purposes
    if World.drawBoundingBoxes then
        r.gameObjectsDraw = r.gameObject.draw
        r.gameObject.draw = r.draw
    end

    -- initilize some defaults based on the game object for convenience
    r.boundingBoxSize = r.boundingBoxSize or r.gameObject.size

    r.boundingBoxAnchor = r.boundingBoxAnchor or Vector2.zero()
    r.boundingBoxSize = r.boundingBoxSize or Vector2:init(unpack(r.gameObject.size))
    r.boundingBoxRadius = r.boundingBoxRadius or Vector2.zero()
    r.velocity = r.velocity or Vector2.zero()
    r.force = r.force or Vector2.zero()
    r.collisionCategory = r.collisionCategory or World.rigidbodyCategory
    r.collisionMask = r.collisionMask or { [World.allCategories] = true }
    r.absolutePosition = Vector2:init(unpack(r.gameObject:updateAbsolutePosition()))

    World.rigidbodies[#World.rigidbodies + 1] = r
    return r
end

-- WARNING: Zombie Mind Control Methods begin here. Not everything is what it looks like!

-- self is Game Object
function Rigidbody: update (dt) 
    -- physics updates
    local acceleration = self.rigidbody.force / self.rigidbody.mass
    self.rigidbody.velocity = self.rigidbody.velocity + acceleration:scale(dt)
    self.position = self.position + self.rigidbody.velocity:scale(dt)

    self.force = Vector2.zero()

    -- game object's update goes in the end
    self.rigidbody.gameObjectsUpdate(self, dt)
    self.rigidbody:updateAbsolutePosition()
end

-- self is Game Object
function Rigidbody: draw () 
    -- game object is drawn first
    self.rigidbody.gameObjectsDraw(self)

    red, green, blue, alpha = love.graphics.getColor()
    love.graphics.setColor(1, 0, 0, 1)

    local boundingBox = self.rigidbody:boundingBox()
    love.graphics.rectangle("line", boundingBox.x, boundingBox.y, boundingBox.width, boundingBox.height)

    love.graphics.setColor(red, green, blue, alpha)
end

-- END of WARNING!

function Rigidbody: applyForce (f)
    self.force = self.force or Vector2.zero()
    self.force = self.force + f
end

function Rigidbody: updateAbsolutePosition ()
    self.absolutePosition = Vector2:init(
        self.gameObject.absolutePosition.x + self.boundingBoxAnchor.x * self.gameObject.size.x, 
        self.gameObject.absolutePosition.y + self.boundingBoxAnchor.y * self.gameObject.size.y
    )
end

function Rigidbody: boundingBox ()
    if self.shape == "circle" then
        return Rect2:init(
            self.absolutePosition.x - self.boundingBoxRadius, self.absolutePosition.y - self.boundingBoxRadius,
            self.boundingBoxRadius * 2, self.boundingBoxRadius * 2
        )
    end
    return Rect2:init (
        self.absolutePosition.x, self.absolutePosition.y,
        self.boundingBoxSize.x, self.boundingBoxSize.y
    )
end

function Rigidbody: didCollide ( r )
    if self:boundingBox() == r:boundingBox()  then
        if self.shape == "circle" and  r.shape == "circle" then
            return self: didCircleCollideWithCircle(r)
        end
        if self.shape == "rect" and  r.shape == "rect" then
            return self: didSquareCollideWithSquare(r)
        end
        if self.shape == "circle" then
            return self: didCircleCollideWithSquare(r)
        end
        return r: didCircleCollideWithSquare(self)
    end
    return false
end

function Rigidbody: didCircleCollideWithCircle ( r )
    local radiuses = self.boundingBoxSize.x + r.boundingBoxSize.x
    local distance = self.gameObject.absolutePosition - r.gameObject.absolutePosition
    if radiuses * radiuses > distance:power() then 
        return true 
    end
    return false
end

function Rigidbody: didCircleCollideWithSquare ( r )
    return true -- for now we leave it just to the bounding boxes
end

function Rigidbody: didSquareCollideWithSquare ( r )
    return true -- for now we leave it just to the bounding boxes
end


--[[
    The world keeps track of all the rigidbodies and their interactions.
--]]

World = {
    rigidbodies = {},
    drawBoundingBoxes = false,
    gravity = Vector2:init(0, 9.81),
    collisionCategory = "world-category",
    rigidbodyCategory = "rigidbody-category",
    allCategories = "all-categories"
}

function World.update (dt) 
    -- check for collisions and call affected object's onCollide functions
    local collisionPairs = {}
    local num = #World.rigidbodies
    for _, r in pairs(World.rigidbodies) do
        if World.categoryAffectsMask(World.collisionCategory, r.collisionMask) then
            r:applyForce(World.gravity)
        end
        if World.hasMask(r.collisionMask) then -- objects with zero mask cannot be affected by colllisions with any category
            for _, c in  pairs(World.rigidbodies) do
                if r ~= c then
                    -- check if r can be affected by c's category
                    if World.categoryAffectsMask(c.collisionCategory, r.collisionMask) then
                        -- if we already know they collided, no need to calculate it again, just call the function
                        if collisionPairs[c] == r or r:didCollide(c) then
                            r:onCollide(c)
                            collisionPairs[r] = c
                        end
                    end
                end
            end
        end
    end
end

--[[ 
    This would have been done with bitwise operations: 
    each rigidbody would have
    - category that it belongs 
    - mask that tells what categories of rigidbodies can affect it in collision
    if the conjunction of affecting object's category, and affected object's mask is greater than zero it would mean that 
        the category bit of affecting object found a match with one of the bits in the affected object's mask and should affect it.

    I couldn't make bit32 work for some reason, and didn't want to waste any more time on this, so I did it this way
         - it shouldn't be a big problem since there is only a few categories
--]] 
function World.categoryAffectsMask ( category, mask )
    if mask[World.allCategories] then return true end
    if mask[category] then return true end
    return false
end

function World.hasMask (mask)
    if mask == nil then return false end
    for _, c in pairs(mask) do
        if c then return true end
    end
    return false
end

