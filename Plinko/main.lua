require("vector")
require("gameObject")

scene = GameObject: init { 
    position = Vector2: init( 300, 300 ),
    size = Vector2: init( 10, 10 ),
    zOrder = 0
 }

disc = GameObject: init {
    position = Vector2: init( 10, 10 ),
    size = Vector2: init( 2, 50 ),
    zOrder = 1
}

peg = GameObject: init { 
    position = Vector2: init( 10, -10 ),
    size = Vector2: init( 50, 2 ),
    zOrder = 2
 }

function love.load(arg)
    if arg[#arg] == "-debug" then require("mobdebug").start() end
    love.window.setMode( 700, 1000, {highdpi = true, msaa = 2} )
    p = Vector2:init ( 20, 0 )
    s = Vector2:init ( 20, 20 )

    scene: load()

    print (p)
end

local timePassed = 0
local discAdded = false
local pegAdded = false
function love.update(dt)
    scene: update()
    v = Vector2:init ( 1, 1 )
    p = p + v

    timePassed = timePassed + dt

    if not pegAdded then
        if timePassed > 1 then
            scene: addChild(peg)
            pegAdded = true
        end
    end

    if not discAdded then
        if timePassed > 3 then
            scene: addChild(disc)
            disc.position.x = disc.position.x + disc.parent.size.x
            discAdded = true
        end
    end
end

function love.draw()
    scene: draw()
    love.graphics.ellipse("fill", p.x, p.y, s.x, s.y)
    love.graphics.print(#scene.children, 5, 50, 0, 2, 2, 0, 0)
end
