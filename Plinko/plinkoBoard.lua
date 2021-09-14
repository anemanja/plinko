require("game/gameObject")
require("game/physics")
require("convenience/functions")

PlinkoBoard = GameObject:init()

PlinkoBoardStates = enum {
    "PLAY",
    "TRANSITION",
    "READY",
    "END"
}

function PlinkoBoard: load()
    self:loadLevel(1)
end

function PlinkoBoard: loadLevel(levelIndex)    
    self:clear()
    self.levels[levelIndex] = self.levels[levelIndex] or {} 
    self.score = 0
    self.winningScore = self.levels[levelIndex].winningScore or levelIndex*5
    self.discsCount = self.levels[levelIndex].discsCount or 5
    self.discs = {}
    self.currentLevel = levelIndex
    self.rows = self.levels[levelIndex].rows or 10
    self.rewards = self.levels[levelIndex].rewards or {levelIndex, levelIndex*2, levelIndex*3, 0, levelIndex*10, 0, levelIndex*3, levelIndex*2, levelIndex}
    self.state = self.state or PlinkoBoardStates.TRANSITION
    self.discsLanded = 0
    self.children = {}

    World.rigidbodies = {}

    local pegSpaceWidth = self.size.x / #self.rewards
    self:setupPlayerArea(pegSpaceWidth)
    self:setupPegArea(pegSpaceWidth)
    self:setupRewardsArea(pegSpaceWidth)

    GameObject.load(self)
    self:changeState()
end

function PlinkoBoard: changeState()
    if self.state == PlinkoBoardStates.TRANSITION then 
        self.state = PlinkoBoardStates.READY 
        return
    end
    if self.state == PlinkoBoardStates.READY then 
        self.state = PlinkoBoardStates.PLAY 
        return
    end
    if self.state == PlinkoBoardStates.PLAY then 
        self.state = PlinkoBoardStates.END 
        return
    end
    if self.state == PlinkoBoardStates.END then 
        self.state = PlinkoBoardStates.TRANSITION 
        return
    end
end

function PlinkoBoard: setupPlayerArea(pegSpaceWidth)
    self.shouldBlink = false
    self.blinkingDelay = 0

    for i = 1, self.discsCount do
        local disc = GameObject: init {
            position = Vector2:init(-pegSpaceWidth, -pegSpaceWidth),
            size = Vector2:init( pegSpaceWidth * 0.73, pegSpaceWidth * 0.73 ),
            zOrder = 4,
            imageName = imageResourcePNG("disc")
        }   
    
        self.playerAreaHeight = 2 * pegSpaceWidth

        self.discs[#self.discs + 1] = disc
        self:addChild(disc)
    end
end

function PlinkoBoard: setupPegArea(pegSpaceWidth)
    local rows = self.rows + 5
    local pegAreaHeight = pegSpaceWidth * (rows + 1)

    local pegHitSound = love.sound.newSoundData(soundResource("peg-hit-sfx.wav"))

    local pegSpaceOffsetCoefficient = -1
    for i = 1, rows do
        self: pinAPeg( Vector2:init(-pegSpaceWidth/2, self.size.y - pegSpaceWidth * (i + 1.5)), pegSpaceWidth, pegHitSound )
        self: pinAPeg( Vector2:init(self.size.x - pegSpaceWidth/2, self.size.y - pegSpaceWidth * (i + 1.5)), pegSpaceWidth, pegHitSound )
        self: pinAPeg( Vector2:init(-pegSpaceWidth/2, self.size.y - pegSpaceWidth * (i + 1)), pegSpaceWidth, pegHitSound )
        self: pinAPeg( Vector2:init(self.size.x - pegSpaceWidth/2, self.size.y - pegSpaceWidth * (i + 1)), pegSpaceWidth, pegHitSound )

        if pegSpaceOffsetCoefficient == -1 then pegSpaceOffsetCoefficient = -0.5 else pegSpaceOffsetCoefficient = -1 end
        for j = 1, #self.rewards do
            if (pegSpaceOffsetCoefficient == -0.5) and (j == #self.rewards) then break end

            local p = Vector2:init(
                pegSpaceWidth * (j + pegSpaceOffsetCoefficient),
                self.size.y - pegSpaceWidth * (i + 1.5)
            )

            if p.y < self.playerAreaHeight - pegSpaceWidth/2 then break end

            self: pinAPeg( p, pegSpaceWidth, pegHitSound )
        end
    end
end

function PlinkoBoard: pinAPeg( p, pegSpaceWidth, pegHitSound ) 
    local pegRadius = pegSpaceWidth * 0.05
    local peg = GameObject: init { 
        position = p,
        size = Vector2:init( pegSpaceWidth, pegSpaceWidth ),
        zOrder = 5,
        imageName = imageResourcePNG("peg")
    }
    local pegR = Rigidbody: init {
        gameObject = peg,
        collisionCategory = "pegsCategory",
        collisionMask = { discsCategory = true },
        boundingBoxRadius = pegRadius,
        sfx = love.audio.newSource(pegHitSound, "static"),
        onCollide = function (self, r) 
            self.sfx:stop()
            self.sfx:play() 
        end
    }
    
    self:addChild(peg)
end

function PlinkoBoard: setupRewardsArea(pegSpaceWidth) 
    local rewardSfx = love.sound.newSoundData(soundResource("reward-sfx.wav"))
    local maxReward = self.rewards[1]
    for _, reward in ipairs(self.rewards) do
        if maxReward < reward then maxReward = reward end
    end

    for i, reward in ipairs(self.rewards) do
        local p = Vector2:init(
            pegSpaceWidth * (i - 1),
            self.size.y - pegSpaceWidth
        )

        local rewardBox = GameObject: init { 
            position = p,
            size = Vector2:init( pegSpaceWidth, pegSpaceWidth ),
            zOrder = 0,
            reward = reward,
            draw = function (self)
                local r, g, b, a = love.graphics.getColor() 
                local rCoef = self.reward / maxReward
                local color = love.graphics.setColor(0.3 *rCoef, 0.9 *rCoef, 0.1 *rCoef, 0.5)
                love.graphics.rectangle("fill", p.x, p.y, pegSpaceWidth, pegSpaceWidth)
                love.graphics.setColor(r, g, b, a)
                love.graphics.print("$"..self.reward, p.x + 10, p.y + pegSpaceWidth - 10, -pi_half, 1.5)
            end
        }

        local rewardR = Rigidbody: init {
            gameObject = rewardBox,
            shape = "square",
            collisionCategory = "rewardsCategory",
            collisionMask = { discsCategory = true },
            sfx = love.audio.newSource(rewardSfx, "static"),
            onCollide = function (self, r) 
                if not r.isRewarded then 
                    self.sfx:stop() 
                    self.sfx:play() 

                    self.gameObject.parent.score = self.gameObject.parent.score + self.gameObject.reward
                    r.isRewarded = true

                    self.gameObject.parent.discsLanded = self.gameObject.parent.discsLanded + 1
                    if self.gameObject.parent.state == PlinkoBoardStates.PLAY then
                        if self.gameObject.parent.discsLanded == self.gameObject.parent.discsCount then
                            self.gameObject.parent:changeState()
                        end
                    end
                end
            end
        }

        self:addChild(rewardBox)
    end
end

function PlinkoBoard: update( dt )
    if self.state == PlinkoBoardStates.END then
        local levelToLoad = self.currentLevel
        self.gameEndedLabel = "GAME OVER"
        if self.score > self.winningScore then
            levelToLoad = levelToLoad + 1
            self.gameEndedLabel = "CONGRATULATIONS\n"..self.score
        end
        self:loadLevel(levelToLoad)
        self:changeState()
        self.gameEnded = true
        self.gameEndedDelay = 0
    end
    GameObject.update(self, dt)

    if self.gameEnded then
        self.gameEndedDelay = self.gameEndedDelay + dt
        if self.gameEndedDelay > 5 then
            self.gameEnded = false
        end
    end

    if self.blinkingDelay > 0.73 then
        self.blinkingDelay = 0
        self.shouldBlink = not self.shouldBlink
    end

    self.blinkingDelay = self.blinkingDelay + dt
end

function PlinkoBoard: draw() 
    local mousePosition = self:getRelativePositionOfAbsolute(Vector2:init(love.mouse.getPosition()))
    GameObject.draw(self)
    local r, g, b, a = love.graphics.getColor()

    if self.shouldBlink and ((self.state == PlinkoBoardStates.PLAY) or (self.state == PlinkoBoardStates.READY)) then
        love.graphics.setColor(0.7, 0.3, 0.1, 0.3)
        love.graphics.rectangle("fill", 10, 20, self.size.x - 20, self.playerAreaHeight - 30)
        love.graphics.setColor(0.7, 0.3, 0.1, 1.0)
        love.graphics.printf("CLICK HERE", 0, self.playerAreaHeight/2, self.size.x, "center")
    end

    if self.gameEnded then
        love.graphics.setColor(0.2, 0.1, 0.3, 0.7)
        love.graphics.rectangle("fill", 100, self.size.y/2 - 100, self.size.x - 200, 200)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(self.gameEndedLabel, 100, self.size.y/2, self.size.x - 200, "center")
    end

    love.graphics.setColor(0.7, 0.3, 0.1, 1.0)
    love.graphics.printf("SCORE: "..self.score.." / "..self.winningScore, 0, 5, self.size.x - 10, "right")
    love.graphics.printf("LEVEL "..self.currentLevel, 10, 5, self.size.x, "left")

    love.graphics.setColor(r, g, b, a)

    if #self.discs > 0 then 
        love.graphics.draw(self.discs[1].image, mousePosition.x - self.discs[1].size.x/2, mousePosition.y - self.discs[1].size.y/2, 0, self.discs[1].imageScale.x, self.discs[1].imageScale.y)
        love.graphics.print(#self.discs, mousePosition.x - self.discs[1].size.x/2 + 7, mousePosition.y - 9, 0, 1.37)
    end
end

function PlinkoBoard: onPressed(x, y, button, istouch)
    if self.playerAreaHeight < y then return end 

    if self.state == PlinkoBoardStates.READY then
        self:changeState()
    end

    if self.state == PlinkoBoardStates.PLAY and #self.discs > 0 then
        local releasedDisc = self.discs[#self.discs]
        releasedDisc.isPlayerControlled = false

        local mousePosition = self:getRelativePositionOfAbsolute(Vector2:init(love.mouse.getPosition()))
        releasedDisc.position = mousePosition - (releasedDisc.size / 2)
        local r = Rigidbody: init {
            gameObject = releasedDisc,
            mass = 5,
            --[[
                Cool thing with collision category and mask is that it can be used in diffeerent ways by different objects for the same collision. 
                Example 1: disc is colliding bouncing off of pegs, but pegs are only playing away sound.
                Example 2: disc 
            --]]
            collisionCategory = "discsCategory",
            collisionMask = { pegsCategory = true, wallsCategory = true, worldCategory = true },
            onCollide = function (self, r) 
                if r.collisionCategory == "pegsCategory" then
                    local d = self.absolutePosition - r.absolutePosition
                    local D = r.boundingBoxRadius + self.boundingBoxRadius + 2

                    local dn = d:normalized()
                    local disp = dn:scale(D)
                    local absPos = r.absolutePosition + disp
                    self.gameObject.position = self.gameObject.position - (self.absolutePosition - absPos)
                    self.gameObject.absolutePosition = self.gameObject:updateAbsolutePosition()
                    self:updateAbsolutePosition()
                
                    self.velocity = self.velocity - d:scale(1.5*(self.velocity * d) / d:power())
                end

                if r.collisionCategory == "rewardsCategory" then
                    self.gameObject.position = self:getRelativePositionOfAbsolute(r.absolutePosition)
                    World.removeRigidbody(self)
                end
            end
        }

        self.discs[#self.discs] = nil
        
        if #self.discs == 0 then love.mouse.setVisible(true) end
    end
end