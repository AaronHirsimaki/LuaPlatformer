local player = {
    width = 50,
    height = 50,
    speed = 200,
    jumpPower = -400,
    maxJumps = 2,
    jumcount = 0
}

local platforms = {}

local world

local background

local cameraX = 0
local cameraY = 0

function love.load(dt)
    -- Tämä ajetaan, kun peli käynnistyy
    world = love.physics.newWorld(0, 800, true)

    background = love.graphics.newImage("sprites/PeliTausta.png")

    player.body = love.physics.newBody(world, 100, 100, "dynamic")             -- (world, x, y, tyyppi)
    player.shape = love.physics.newRectangleShape(player.width, player.height) -- Pelaajan koko
    player.sprite = love.graphics.newImage('sprites/hymyNeliö.png')
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)     -- Kiinnitä muoto kappaleeseen
    player.fixture:setRestitution(0)                                           -- Hyppimisen elastisuus (0 = ei pomppaa)

    -- Skaalauskerroin spriteä varten
    player.scaleX = player.width / player.sprite:getWidth()   -- Skaalaus leveydelle
    player.scaleY = player.height / player.sprite:getHeight() -- Skaalaus korkeudelle

    player.jumcount = 0


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

    -- Luo alustat
    for _, data in ipairs(platformData) do
        local platform = {}
        platform.body = love.physics.newBody(world, data.x, data.y, "static")     -- "static" = ei liikkuva kappale
        platform.shape = love.physics.newRectangleShape(data.width, data.height)  -- Alustan koko
        platform.fixture = love.physics.newFixture(platform.body, platform.shape) -- Kiinnitä muoto alustaan
        table.insert(platforms, platform)                                         -- Lisää alusta alustojen listaan
    end
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
        -- Pysäytä vaakasuuntainen liike, jos ei paineta mitään
        player.body:setLinearVelocity(0, vy)
    end

    if love.keyboard.isDown("space") then
        local isOnGround = false

        -- Tarkistetaan pelaajan maassa olo
        for _, contact in ipairs(player.body:getContacts()) do
            local fixture1, fixture2 = contact:getFixtures() -- Hae molemmat törmäävät objektit
            local otherBody = fixture1:getBody() == player.body and fixture2:getBody() or fixture1:getBody()

            -- Tarkista, onko toinen objekti alusta ja pelaaja maassa
            if otherBody:getType() == "static" then
                isOnGround = true -- Pelaaja on maassa, jos on yhteys staattiseen alustaan
                break
            end
        end

        -- Jos pelaaja on maassa, nollaa hyppyjen laskuri
        if isOnGround then
            player.jumpCount = 0
        end

        -- Hyppää, jos hyppyjä on jäljellä
        if player.jumpCount < player.maxJumps then
            player.body:applyLinearImpulse(0, player.jumpPower) -- Hyppy
            player.jumpCount = player.jumpCount + 1             -- Lisää hyppyjen määrä
        end
    end

    cameraX = player.body:getX() - love.graphics.getWidth() / 2
end

function love.draw()
    -- Piirrä kaikki pelin elementit
    love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(),
        love.graphics.getHeight() / background:getHeight())

    love.graphics.translate(-cameraX, -cameraY)

    love.graphics.draw(
        player.sprite,                             -- Sprite-kuva
        player.body:getX(),                        -- Pelaajan fysiikkakappaleen X-sijainti
        player.body:getY(),                        -- Pelaajan fysiikkakappaleen Y-sijainti
        player.body:getAngle(),                    -- Pelaajan fysiikkakappaleen kulma
        player.width / player.sprite:getWidth(),   -- Skaalaus X-suunnassa
        player.height / player.sprite:getHeight(), -- Skaalaus Y-suunnassa
        player.sprite:getWidth() / 2,              -- Siirrä kuvan keskipiste X-akselilla
        player.sprite:getHeight() / 2              -- Siirrä kuvan keskipiste Y-akselilla
    )
    for _, platform in ipairs(platforms) do
        love.graphics.polygon("fill", platform.body:getWorldPoints(platform.shape:getPoints()))
    end
end
