local player = require("player")

local npcHuman = {
    x = 500,
    y = 850,
    width = 100,
    height = 100,
    speed = 200,
    jumpPower = -2000,
    maxJumps = 2,
    jumpcount = 0,
    direction = 1,
    patrolDistance = 300,
    startX = 500,
    isOnGround = false,
    canJump = true
}

local platforms = {}

local world

local background

local cameraX = 0
local cameraY = 0

local keysPressed = {}

local gameState = "menu" -- Alustetaan pelin tila valikkoon

function love.keypressed(key)
    keysPressed[key] = true

    if player.keypressed then
        player.keypressed(key)
    end

    if gameState == "menu" then
        if key == "return" then     -- Enter aloittaa pelin
            gameState = "game"
        elseif key == "escape" then -- Escape sulkee pelin
            love.event.quit()
        end
    elseif gameState == "game" then
        if key == "escape" then -- Esc kesken pelin -> Pause-tila
            gameState = "paused"
        end
    elseif gameState == "paused" then
        if key == "return" then     -- Enter jatkaa peliä
            gameState = "game"
        elseif key == "escape" then -- Esc palaa päävalikkoon
            gameState = "menu"
        end
    end
end

function love.load(dt)
    -- Tämä ajetaan, kun peli käynnistyy
    local gravity = 800
    world = love.physics.newWorld(0, gravity, true)

    player.load(world)

    love.window.setTitle("Zero Ducks Given")

    background = love.graphics.newImage("sprites/woodedmountain.png")

    npcHuman.body = love.physics.newBody(world, npcHuman.x, npcHuman.y, "dynamic")
    npcHuman.shape = love.physics.newRectangleShape(npcHuman.width, npcHuman.height)
    npcHuman.sprite = love.graphics.newImage('sprites/duck.png')
    npcHuman.fixture = love.physics.newFixture(npcHuman.body, npcHuman.shape, 1)
    npcHuman.fixture:setRestitution(0)
    npcHuman.speed = 100          -- NPC:n nopeus
    npcHuman.jumpPower = -1500    -- Hyppyvoima
    npcHuman.patrolDistance = 300 -- Partiointimatka (jos ei seuraa pelaajaa)

    npcHuman.scaleX = npcHuman.width / npcHuman.sprite:getWidth()
    npcHuman.scaleY = npcHuman.height / npcHuman.sprite:getHeight()

    -- Asetetaan NPC:n liikesuunta
    npcHuman.direction = 1


    player.jumpcount = 0


    local platformData = {
        { x = 300,  y = 900, width = 400, height = 50 },
        { x = 700,  y = 950, width = 400, height = 50 },
        { x = 1100, y = 880, width = 400, height = 50 },
        { x = 1500, y = 920, width = 400, height = 50 },
        { x = 1900, y = 850, width = 400, height = 50 },
        { x = 2300, y = 900, width = 400, height = 50 },
        { x = 2700, y = 950, width = 400, height = 50 },
        { x = 3100, y = 870, width = 400, height = 50 },
        { x = 3500, y = 920, width = 400, height = 50 },
        { x = 3900, y = 850, width = 400, height = 50 },
        { x = 4300, y = 900, width = 400, height = 50 },
        { x = 4700, y = 950, width = 400, height = 50 },
        { x = 5100, y = 880, width = 400, height = 50 },
        { x = 5500, y = 920, width = 400, height = 50 },
    }

    for _, data in ipairs(platformData) do
        local platform = {}
        platform.body = love.physics.newBody(world, data.x, data.y, "static")
        platform.shape = love.physics.newRectangleShape(data.width, data.height)
        platform.fixture = love.physics.newFixture(platform.body, platform.shape)
        table.insert(platforms, platform)
    end
end

function love.keyboard.wasPressed(key)
    return keysPressed[key]
end

function love.update(dt)
    -- Tarkista pelitila ennen päivityksiä
    if gameState == "game" then
        -- Päivitä pelin logiikkaa vain pelitilassa
        world:update(dt)

        player.update(dt)

        -- NPC:n maassaolotila ja seuranta
        npcHuman.isOnGround = false
        local distanceToPlayer = math.abs(player.body:getX() - npcHuman.body:getX())
        local followRange = 600

        if distanceToPlayer <= followRange then
            npcHuman.direction = player.body:getX() > npcHuman.body:getX() and 1 or -1
        end

        -- NPC liikkuminen
        if npcHuman.isOnGround then
            npcHuman.body:setLinearVelocity(npcHuman.speed * npcHuman.direction, 0)
        else
            local vx, vy = npcHuman.body:getLinearVelocity()
            npcHuman.body:setLinearVelocity(npcHuman.speed * npcHuman.direction, vy * 0.9)
        end

        -- NPC:n partiointi
        if math.abs(npcHuman.body:getX() - npcHuman.startX) >= npcHuman.patrolDistance then
            npcHuman.direction = npcHuman.direction * -1
        end

        -- NPC:n hyppy esteiden yli
        for _, contact in ipairs(npcHuman.body:getContacts()) do
            if contact:isTouching() then
                local fixtureA, fixtureB = contact:getFixtures()
                local otherBody = fixtureA:getBody() == npcHuman.body and fixtureB:getBody() or fixtureA:getBody()

                if otherBody:getType() == "static" then
                    local normalX, normalY = contact:getNormal()
                    if normalY > -0.1 then
                        npcHuman.isOnGround = true
                        npcHuman.canJump = true
                    end

                    if math.abs(normalX) > 0.7 and npcHuman.isOnGround and npcHuman.canJump then
                        npcHuman.body:setLinearVelocity(0, 0)
                        npcHuman.body:applyLinearImpulse(0, npcHuman.jumpPower)
                        npcHuman.canJump = false
                    end
                end
            end
        end
        cameraX = player.body:getX() - love.graphics.getWidth() / 2
    end
end

function love.draw()
    if gameState == "menu" then
        drawMenu()
    elseif gameState == "game" then
        -- Piirrä tausta vain pelitilassa
        love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(),
            love.graphics.getHeight() / background:getHeight())

        love.graphics.translate(-cameraX, -cameraY)

        player.draw()

        love.graphics.draw(
            npcHuman.sprite,
            npcHuman.body:getX(),
            npcHuman.body:getY(),
            npcHuman.body:getAngle(),
            npcHuman.scaleX,
            npcHuman.scaleY,
            npcHuman.sprite:getWidth() / 2,
            npcHuman.sprite:getHeight() / 2
        )

        for _, platform in ipairs(platforms) do
            love.graphics.polygon("fill", platform.body:getWorldPoints(platform.shape:getPoints()))
        end
    elseif gameState == "paused" then
        drawPaused()
    end
end

function drawMenu()
    love.graphics.clear(0.2, 0.2, 0.2)
    love.graphics.printf("Main Menu", 0, 100, love.graphics.getWidth(), "center")
    love.graphics.printf("Press Enter to Start", 0, 150, love.graphics.getWidth(), "center")
    love.graphics.printf("Press Escape to Quit", 0, 200, love.graphics.getWidth(), "center")
end

function drawPaused()
    love.graphics.clear(0.1, 0.1, 0.1)
    love.graphics.printf("Game Paused", 0, 100, love.graphics.getWidth(), "center")
    love.graphics.printf("Press Enter to Resume", 0, 150, love.graphics.getWidth(), "center")
    love.graphics.printf("Press Escape to Return to Menu", 0, 200, love.graphics.getWidth(), "center")
end

function drawGame()
    love.graphics.clear(0.1, 0.1, 0.3)
    love.graphics.printf("Game Running! Press Escape to return to Menu", 0, 100, love.graphics.getWidth(), "center")
end
