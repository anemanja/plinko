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
    
    self.levels[levelIndex] = self.levels[levelIndex] or {} 
    self.score = 0
    self.winningScore = self.levels[levelIndex].winningScore or levelIndex*15
    self.discsCount = self.levels[levelIndex].discsCount or levelIndex
    self.discs = {}
    self.currentLevel = levelIndex
    self.rows = self.levels[levelIndex].rows or 10
    self.rewards = self.levels[levelIndex].rewards or {levelIndex, levelIndex*2, levelIndex*3, 0, levelIndex*10, 0, levelIndex*3, levelIndex*2, levelIndex}
    self.state = PlinkoBoardStates.TRANSITION
    self.discsLanded = 0
    self.children = {}

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
    for i = 1, self.discsCount do
        local disc = GameObject: init {
            position = Vector2:init(-pegSpaceWidth, -pegSpaceWidth),
            size = Vector2:init( pegSpaceWidth * 0.73, pegSpaceWidth * 0.73 ),
            zOrder = 1,
            imageName = imageResourcePNG("disc")
        }   
    
        self.discs[#self.discs + 1] = disc
        self:addChild(disc)
    end
end

function PlinkoBoard: setupPegArea(pegSpaceWidth)
    local pegAreaHeight = pegSpaceWidth * (self.rows + 1)
    local pegRadius = pegSpaceWidth * 0.1

    local pegHitSound = love.sound.newSoundData(soundResource("peg-hit-sfx.wav"))

    local pegSpaceOffsetCoefficient = -1
    for i = 1, self.rows do
        if pegSpaceOffsetCoefficient == -1 then pegSpaceOffsetCoefficient = -0.5 else pegSpaceOffsetCoefficient = -1 end
        for j = 1, #self.rewards do
            if (pegSpaceOffsetCoefficient == -0.5) and (j == #self.rewards) then break end

            local p = Vector2:init(
                pegSpaceWidth * (j + pegSpaceOffsetCoefficient),
                self.size.y - pegSpaceWidth * (i + 1.5)
            )

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
                    if not self.sfx:isPlaying() then
                        self.sfx:play() 
                    end
                end
            }
            
            self:addChild(peg)
        end
    end


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
            zOrder = 1
        }
        local rewardR = Rigidbody: init {
            gameObject = rewardBox,
            shape = "square",
            collisionCategory = "rewardsCategory",
            collisionMask = { discsCategory = true },
            isColliding = false,
            sfx = love.audio.newSource(rewardSfx, "static"),
            onCollide = function (self, r) 
                if not self.isColliding then 
                    if not self.sfx:isPlaying() then
                        self.sfx:play() 
                    end

                    self.gameObject.parent.score = self.gameObject.parent.score + reward
                    self.isColliding = true

                    self.gameObject.parent.discsLanded = self.gameObject.parent.discsLanded + 1
                    if self.gameObject.parent.state == PlinkoBoardStates.PLAY then
                        if self.gameObject.parent.discsLanded == self.gameObject.parent.discsCount then
                            self.gameObject.parent:changeState()
                        end
                    end
                end
            end,
            draw = function (self)
                local r, g, b, a = love.graphics.getColor() 
                local rCoef = reward / maxReward
                local color = love.graphics.setColor(0.3 *rCoef, 0.9 *rCoef, 0.1 *rCoef, 0.5)
                if self.isColliding then love.graphics.setColor(0.9, 0.1, 0.2, 0.5) end
                love.graphics.rectangle("fill", p.x, p.y, pegSpaceWidth, pegSpaceWidth)
                love.graphics.setColor(r, g, b, a)
                love.graphics.print(reward, p.x, p.y + pegSpaceWidth, -pi_half, 3)
            end
        }

        self:addChild(rewardBox)
    end
end

function PlinkoBoard: update( dt )
    if self.state == PlinkoBoardStates.END then
        if self.score > self.winningScore then
            self:loadLevel(self.currentLevel + 1)
            self:changeState()
        end
    end
    GameObject.update(self, dt)
end

function PlinkoBoard: draw() 
    local mousePosition = self:getRelativePositionOfAbsolute(Vector2:init(love.mouse.getPosition()))
    GameObject.draw(self)
    love.graphics.print(self.score.." / "..self.winningScore, 0, 0, 0, 3)
    if #self.discs > 0 then 
        love.graphics.draw(self.discs[1].image, mousePosition.x - self.discs[1].size.x/2, mousePosition.y - self.discs[1].size.y/2, 0, self.discs[1].imageScale.x, self.discs[1].imageScale.y)
        love.graphics.print(#self.discs, mousePosition.x - self.discs[1].size.x, mousePosition.y - self.discs[1].size.y, 0, 2)
    end
end

function PlinkoBoard: onPressed(x, y, button, istouch)
    if self.state == PlinkoBoardStates.READY then
        self:changeState()
    end

    if self.state == PlinkoBoardStates.PLAY then
        local releasedDisc = self.discs[#self.discs]
        releasedDisc.isPlayerControlled = false

        local mousePosition = self:getRelativePositionOfAbsolute(Vector2:init(love.mouse.getPosition()))
        releasedDisc.position = mousePosition - (releasedDisc.size / 2)
        local r = Rigidbody: init {
            gameObject = releasedDisc,
            mass = 5,
            collisionCategory = "discsCategory",
            onCollide = function (self, r)
                if r.collisionCategory == "rewardsCategory" then
                    self.gameObject.parent:removeChild(self)
                    World.removeRigidbody(self)
                end
            end
        }

        self.discs[#self.discs] = nil
        
        if #self.discs == 0 then love.mouse.setVisible(true) end
    end
end