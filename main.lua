local player = {
    width = 100,
    height = 100,
    speed = 200,
    jumpPower = -3000,
    maxJumps = 2,
    jumcount = 0
}

local platforms = {}

local world

local background

local cameraX = 0
local cameraY = 0

local keysPressed = {}

function love.keypressed(key)
    keysPressed[key] = true
end

function love.load(dt)
    -- Tämä ajetaan, kun peli käynnistyy
    world = love.physics.newWorld(0, 800, true)

    background = love.graphics.newImage("sprites/woodedmountain.png")

    player.body = love.physics.newBody(world, 100, 100, "dynamic")
    player.shape = love.physics.newRectangleShape(player.width, player.height)
    player.sprite = love.graphics.newImage('sprites/duck.png')
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)
    player.fixture:setRestitution(0)

    player.scaleX = player.width / player.sprite:getWidth()
    player.scaleY = player.height / player.sprite:getHeight()

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
    -- Päivitä pelin logiikkaa (dt on aika viime ruudunpäivityksestä)
    world:update(dt)

    local vx, vy = player.body:getLinearVelocity()
    if love.keyboard.isDown("a") then
        player.body:setLinearVelocity(-player.speed, vy)
    elseif love.keyboard.isDown("d") then
        player.body:setLinearVelocity(player.speed, vy)
    else
        player.body:setLinearVelocity(0, vy)
    end

    if love.keyboard.isDown("space") then
        local isOnGround = false

        for _, contact in ipairs(player.body:getContacts()) do
            local fixture1, fixture2 = contact:getFixtures()
            local otherBody = fixture1:getBody() == player.body and fixture2:getBody() or fixture1:getBody()

            if contact:isTouching() then
                isOnGround = true
                break
            end
        end

        if isOnGround then
            player.jumpcount = 0
        end

        if love.keyboard.wasPressed("space") and player.jumpcount < player.maxJumps then
            player.body:setLinearVelocity(vx, 0)
            player.body:applyLinearImpulse(0, player.jumpPower)
            player.jumpcount = player.jumpcount + 1
        end
    end
    keysPressed = {}

    cameraX = player.body:getX() - love.graphics.getWidth() / 2
end

function love.draw()
    -- Piirrä kaikki pelin elementit
    love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(),
        love.graphics.getHeight() / background:getHeight())

    love.graphics.translate(-cameraX, -cameraY)

    love.graphics.draw(
        player.sprite,
        player.body:getX(),
        player.body:getY(),
        player.body:getAngle(),
        player.width / player.sprite:getWidth(),
        player.height / player.sprite:getHeight(),
        player.sprite:getWidth() / 2,
        player.sprite:getHeight() / 2
    )
    for _, platform in ipairs(platforms) do
        love.graphics.polygon("fill", platform.body:getWorldPoints(platform.shape:getPoints()))
    end
end
