local player = {
    width = 100,
    height = 100,
    speed = 200,
    jumpPower = -3000,  -- Muutin pienemmäksi, koska -3000 oli todella voimakas
    maxJumps = 1,
    jumpcount = 0
}

local cameraX = 0
local cameraY = 0

function player.load(world)
    player.body = love.physics.newBody(world, 100, 100, "dynamic")
    player.shape = love.physics.newRectangleShape(player.width, player.height)
    player.sprite = love.graphics.newImage('sprites/duck.png')
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)
    player.fixture:setRestitution(0)
    player.scaleX = player.width / player.sprite:getWidth()
    player.scaleY = player.height / player.sprite:getHeight()
end

-- Tarkistetaan, onko pelaaja maassa
function player.isOnGround()
    for _, contact in ipairs(player.body:getContacts()) do
        if contact:isTouching() then
            return true
        end
    end
    return false
end

function player.update()
    local vx, vy = player.body:getLinearVelocity()

    -- Liikkuminen
    if love.keyboard.isDown("a") then
        player.body:setLinearVelocity(-player.speed, vy)
    elseif love.keyboard.isDown("d") then
        player.body:setLinearVelocity(player.speed, vy)
    else
        player.body:setLinearVelocity(0, vy)
    end

    -- Jos pelaaja on maassa, nollataan hyppylaskuri
    if player.isOnGround() then
        player.jumpcount = 0
    end

    -- Päivitetään kamera
    cameraX = player.body:getX() - love.graphics.getWidth() / 2
end

-- Hyppylogiikka
function player.keypressed(key)
    if key == "space" and player.jumpcount < player.maxJumps then
        local vx, vy = player.body:getLinearVelocity()
        player.body:setLinearVelocity(vx, 0)  -- Nollataan vain y-akselin nopeus
        player.body:applyLinearImpulse(0, player.jumpPower)
        player.jumpcount = player.jumpcount + 1
    end
end

function player.draw()
    love.graphics.draw(
        player.sprite,
        player.body:getX(),
        player.body:getY(),
        player.body:getAngle(),
        player.scaleX,
        player.scaleY,
        player.sprite:getWidth() / 2,
        player.sprite:getHeight() / 2
    )
end

return player
