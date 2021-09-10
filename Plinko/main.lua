require("game/gameObject")
require("game/physics")
require("convenience/rect")
require("convenience/vector")

local imagePath = function (name) return "resources/images/"..name..".png" end

local scene
local disc 
local peg

local sprite = love.graphics.newImage(imagePath("disc"))

local screen = Vector2: init(700, 1000)

function love.load(arg)
    if arg[#arg] == "-debug" then require("mobdebug").start() end
    love.window.setMode( screen.x, screen.y, {highdpi = true, msaa = 2} )
    World.drawBoundingBoxes = true
    p = Vector2:init ( 20, 0 )
    s = Vector2:init ( 20, 20 )

    scene = GameObject: init { 
        position = Vector2:init( 0, 0 ),
        size = Vector2:init( screen.x, screen.y ),
        imageName = imagePath("scene")
    }

    disc = GameObject: init {
        position = Vector2:init( 300, 100 ),
        size = Vector2: init( 50, 50 ),
        zOrder = 1,
        imageName = imagePath("disc")
    }

    r = Rigidbody: init {
        gameObject = disc
    }

    peg = GameObject: init { 
        position = Vector2:init( 100, 300 ),
        size = Vector2:init( 50, 50 ),
        zOrder = 2,
        imageName = imagePath("peg")
    }

    scene:addChild(disc)
    scene:addChild(peg)
    scene:load()

    print (p)
end

function love.update(dt)
    scene:update(dt)
    World.update(dt)
end

function love.draw()
    scene: draw()
    love.graphics.draw(sprite, p.x, p.y)
    love.graphics.print(#scene.children, 5, 50, 0, 2, 2, 0, 0)
end
