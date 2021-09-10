require("game/gameObject")
require("game/physics")
require("convenience/rect")
require("convenience/vector")
require("plinkoBoard")

imageResource = function (name) return "resources/images/"..name..".png" end
soundResource = function (name) return "resources/sounds/"..name..".wav" end

local scene
local disc 
local peg

local sprite = love.graphics.newImage(imageResource("disc"))

local screen = Vector2: init(700, 900)

function love.load(arg)
    if arg[#arg] == "-debug" then require("mobdebug").start() end

    love.window.setMode( screen.x, screen.y, {highdpi = true, msaa = 2} )

    World.drawBoundingBoxes = true

    scene = PlinkoBoard: init { 
        position = Vector2:init( 0, 0 ),
        size = Vector2:init( screen.x, screen.y ),
        imageName = imageResource("scene"),
        levels = {}
    }
    scene.levels[1] = {
        score = 0,
        winningScore = 5,
        discs = 3,
        name = "Level III",
        rows = 10,
        rewards = { 1, 2, 3, 0, 10, 0, 3, 2, 1 }
    }
    
    scene:load()
end

function love.update(dt)
    scene:update(dt)
    World.update(dt)
end

function love.draw()
    scene: draw()
end
