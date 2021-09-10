require("game/gameObject")
require("game/physics")
require("convenience/functions")

PlinkoBoard = GameObject:init()

PlinkoBoardStates = enum {
    "PLAYER",
    "PEGS",
    "REWARDS",
    "TRANSITION"
}

function PlinkoBoard: load()
    self:loadLevel(self.levels[1])
    GameObject.load(self)
end

function PlinkoBoard: loadLevel(level)
    level = level or {} 
    self.score = level.score or 0
    self.winningScore = level.winningScore or 1
    self.discs = level.discs or 1
    self.name = level.name or "Default Level"
    self.rows = level.rows or 0
    self.rewards = level.rewards or {1}
    self.state = PlinkoBoardStates.TRANSITION
    self.children = {}

    self:setupPlayerArea()
    self:setupPegArea()
    --self:setupRewardsArea()
end

function PlinkoBoard: setupPlayerArea()
    local disc = GameObject: init {
        position = Vector2:init( 350, 10 ),
        size = Vector2: init( 50, 50 ),
        zOrder = 1,
        imageName = imageResource("disc")
    }

    local r = Rigidbody: init {
        gameObject = disc,
        mass = 5,
        collisionCategory = "discsCategory"
    }

    self:addChild(disc)
end

function PlinkoBoard: setupPegArea()
    local pegSpaceWidth = self.size.x / #self.rewards
    local pegAreaHeight = pegSpaceWidth * (self.rows + 1)
    local pegRadius = pegSpaceWidth * 0.1

    local pegHitSound = love.sound.newSoundData(soundResource("peg-hit-sfx"))

    local pegSpaceOffsetCoefficient = -1
    for i = 1, self.rows do
        if pegSpaceOffsetCoefficient == -1 then pegSpaceOffsetCoefficient = -0.5 else pegSpaceOffsetCoefficient = -1 end
        for j = 1, #self.rewards do
            if (pegSpaceOffsetCoefficient == -0.5) and (j == #self.rewards) then break end

            local p = Vector2:init(
                pegSpaceWidth * (j + pegSpaceOffsetCoefficient),
                self.size.y - pegSpaceWidth * i
            )

            local peg = GameObject: init { 
                position = p,
                size = Vector2:init( pegSpaceWidth, pegSpaceWidth ),
                zOrder = 5,
                imageName = imageResource("peg")
            }
            local pegR = Rigidbody: init {
                gameObject = peg,
                collisionCategory = "pegsCategory",
                collisionMask = { discsCategory = true },
                boundingBoxRadius = pegRadius,
                sfx = love.audio.newSource(pegHitSound, "static"),
                onCollide = function (self, r) 
                    if (not self.sfx:isPlaying()) then
                        self.sfx:play() 
                    end
                end
            }
            
            local n = #World.rigidbodies
            self:addChild(peg)
        end
    end
end