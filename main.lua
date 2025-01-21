local player = {
    width = 50,
    height = 50,
    speed = 200,
    jumpPower = -400,
}

local platforms = {}

local world

function love.load(dt)
    -- Tämä ajetaan, kun peli käynnistyy
    world = love.physics.newWorld(0, 800, true)

    player.body = love.physics.newBody(world, 100, 100, "dynamic")             -- (world, x, y, tyyppi)
    player.shape = love.physics.newRectangleShape(player.width, player.height) -- Pelaajan koko
    player.sprite = love.graphics.newImage('sprites/hymyNeliö.png')
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)     -- Kiinnitä muoto kappaleeseen
    player.fixture:setRestitution(0)                                           -- Hyppimisen elastisuus (0 = ei pomppaa)

    -- Skaalauskerroin spriteä varten
    player.scaleX = player.width / player.sprite:getWidth()       -- Skaalaus leveydelle
    player.scaleY = player.height / player.sprite:getHeight()     -- Skaalaus korkeudelle


    local platformData = {
        { x = 1400, y = 900,  width = 800, height = 50 },
        { x = 500,  y = 500,  width = 200, height = 50 },
        { x = 700,  y = 1000, width = 500, height = 50 },
        { x = 100,  y = 400,  width = 400, height = 50 },
        { x = 1600, y = 200,  width = 400, height = 50 },
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
        local contacts = player.body:getContactList() -- Tarkista törmäykset
        for _, contact in ipairs(contacts) do
            if contact:isTouching() then
                player.body:applyLinearImpulse(0, player.jumpPower) -- Hyppää, jos on maassa
                break
            end
        end
    end
end

function love.draw()
    -- Piirrä kaikki pelin elementit
    love.graphics.draw(
        player.sprite,                                 -- Sprite-kuva
        player.body:getX(),                            -- Pelaajan fysiikkakappaleen X-sijainti
        player.body:getY(),                            -- Pelaajan fysiikkakappaleen Y-sijainti
        player.body:getAngle(),                        -- Pelaajan fysiikkakappaleen kulma
        player.width / player.sprite:getWidth(),       -- Skaalaus X-suunnassa
        player.height / player.sprite:getHeight(),     -- Skaalaus Y-suunnassa
        player.sprite:getWidth() / 2,                  -- Siirrä kuvan keskipiste X-akselilla
        player.sprite:getHeight() / 2                  -- Siirrä kuvan keskipiste Y-akselilla
    )
    for _, platform in ipairs(platforms) do
        love.graphics.polygon("fill", platform.body:getWorldPoints(platform.shape:getPoints()))
    end
end
