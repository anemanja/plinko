require("game/gameObject")
require("game/physics")
require("convenience/rect")
require("convenience/vector")
require("plinkoBoard")

-- some constants and convenience functions here, should probably be moved to a separate file or module
imageResourcePNG = function (name) return "resources/images/"..name..".png" end
soundResource = function (name) return "resources/sounds/"..name end
pi_half = math.pi/2

local scene
local disc 
local peg

local sprite = love.graphics.newImage(imageResourcePNG("disc"))

local screen = Vector2: init(600, 900)

function love.load(arg)
    if arg[#arg] == "-debug" then require("mobdebug").start() end

    love.window.setMode( screen.x, screen.y, {highdpi = true, msaa = 2} )
    love.mouse.setVisible(false)

    --World.drawBoundingBoxes = true

    scene = PlinkoBoard: init { 
        position = Vector2:init( 0, 0 ),
        size = Vector2:init( screen.x, screen.y ),
        imageName = imageResourcePNG("scene"),
        levels = {}
    }
    --[[
    scene.levels[1] = {
        score = 0,
        winningScore = 5,
        discsCount = 5,
        name = "Level II",
        rows = 10,
        rewards = { 1, 2, 3, 0, 10, 0, 3, 2, 1 }
    }
    scene.levels[2] = {
        score = 0,
        winningScore = 30,
        discsCount = 5,
        name = "Level Grand",
        rows = 30,
        rewards = { 1, 2, 3, 0, 10, 0, 3, 2, 1, 2, 3, 6, 0, 50, 0, 6, 3, 2, 1, 2, 3, 0, 10, 0, 3, 2, 1 }
    }
    scene.levels[2] = {
        score = 0,
        winningScore = 10,
        discsCount = 2,
        name = "Level III",
        rows = 10,
        rewards = { 1, -1, 5, -1, 15, -1, 5, -1, 1 }
    }
    ]]--
    scene:load()
end

function love.update(dt)
    scene:update(dt)
    World.update(dt)
end

function love.draw()
    scene: draw()
end

function love.mousepressed(x, y, button, istouch)
    scene: onPressed(x, y, button, istouch)
 end
