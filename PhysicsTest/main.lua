require("game/gameObject")
require("game/physics")
require("convenience/rect")
require("convenience/vector")

-- some constants and convenience functions here, should probably be moved to a separate file or module
imageResourcePNG = function (name) return "resources/images/"..name..".png" end
soundResource = function (name) return "resources/sounds/"..name end
pi_half = math.pi/2

local scene
local disc 
local peg

local screen = Vector2: init(600, 900)

function love.load(arg)
    if arg[#arg] == "-debug" then require("mobdebug").start() end

    mouse = Vector2.zero()
    love.window.setMode( screen.x, screen.y, {highdpi = true, msaa = 2} )
    love.mouse.setVisible(false)

    World.drawBoundingBoxes = true

    scene = GameObject: init { 
        position = Vector2:init( 0, 0 ),
        size = Vector2:init( screen.x, screen.y )
    }

    large = GameObject: init {
        position = Vector2: init( 200, 200),
        size = Vector2:init( 200, 200 ),
        zOrder = 10,
        isColliding = false,
        update = function (self, dt)
            self.absolutePosition = self:updateAbsolutePosition()
            self.isColliding = false
        end,
        draw = function (self)
            local r, g, b, a = love.graphics.getColor() 
            local mode = "line"
            if self.isColliding then mode = "fill" end
            love.graphics.setColor(1, 0.5, 0, 1)
            love.graphics.circle(mode, self.absolutePosition.x + self.size.x/2, self.absolutePosition.y + self.size.x/2, self.size.x/2)
            love.graphics.setColor(r, g, b, a)
        end
    }

    largeR = Rigidbody: init {
        gameObject = large,
        collisionCategory = "a",
        collisionMask = { b = true },
        onCollide = function (self, r) 
            self.gameObject.isColliding = true
        end
    }

    small = GameObject: init {
        position = Vector2: init( 600, 900),
        size = Vector2:init( 100, 100 ),
        zOrder = 100,
        isColliding = false,
        disposition = Vector2:init(0, 0),
        bounce = Vector2:init(0, 0),
        shadow = Vector2:init(0, 0),
        update = function (self, dt)
            self.absolutePosition = self:updateAbsolutePosition()
            self.disposition = (self.position - mouse)
            self.isColliding = false
        end,
        draw = function (self)
            local r, g, b, a = love.graphics.getColor() 
            local mode = "line"
            if self.isColliding then mode = "fill" end
            love.graphics.setColor(0.3, 1, 0, 1)
            love.graphics.circle(mode, self.absolutePosition.x + self.size.x/2, self.absolutePosition.y + self.size.x/2, self.size.x/2)
            if self.isColliding then 
                love.graphics.setColor(0.73, 0.37, 1.0, 0.69)
                love.graphics.circle("fill", self.shadow.x, self.shadow.y, self.size.x/2)
                love.graphics.setColor(1, 0.5, 0.0, 1.0)
                love.graphics.line(self.shadow.x, self.shadow.y, self.shadow.x + self.bounce.x, self.shadow.y + self.bounce.y)
            end
            love.graphics.setColor(r, g, b, a)

        end
    }

    smallR = Rigidbody: init {
        gameObject = small,
        collisionCategory = "b",
        collisionMask = { a = true },
        onCollide = function (self, r) 
            self.gameObject.isColliding = true

            local d = self.absolutePosition - r.absolutePosition
            
            self.gameObject.bounce = self.gameObject.disposition - d:scale((self.gameObject.disposition * d) / d:power())

            local D = r.boundingBoxRadius + self.boundingBoxRadius + 1

            local dn = d:normalized()
            local disp = dn:scale(D)
            self.gameObject.shadow = r.absolutePosition + disp
        end
    }

    scene:addChild(large)
    scene:addChild(small)
    scene:load()
end

function love.update(dt)
    small.position = Vector2:init(love.mouse.getPosition())
    scene:update(dt)
    World.update(dt)
end

function love.draw()
    scene: draw()
    love.graphics.circle("line", mouse.x, mouse.y, 50)
    local mx, my = love.mouse.getPosition()

	love.graphics.line(mouse.x, mouse.y, mx+50, my+50)
end

function love.mousepressed(x, y, button, istouch)
    mouse = Vector2:init(x, y)
end
