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

local menus = {
    main = {
        title = "Main Menu",
        options = { "Start Game", "Options", "Quit" }
    },
    options = {
        title = "Options",
        options = { "Sound: ON", "Back" }
    },
    pause = {
        title = "Game Paused",
        options = { "Resume", "Main Menu" }
    }
}

local font = love.graphics.newFont(32)
local currentMenu = "main"
local menu = menus[currentMenu] -- Nykyinen valikko

if key == "down" then
    selectedOption = math.min(selectedOption + 1, #menu.options)
elseif key == "up" then
    selectedOption = math.max(selectedOption - 1, 1)
elseif key == "return" then
    handleMenuSelection() -- Kutsutaan toimintoja
elseif key == "escape" then
    if currentMenu ~= "main" then
        currentMenu = "main" -- Paluu päävalikkoon
        selectedOption = 1
    end
end
local selectedOption = 1

function love.keypressed(key)
    keysPressed[key] = true

    if player.keypressed then
        player.keypressed(key)
    end

    if gameState == "menu" then
        if key == "return" then
            gameState = "game" -- Aloitetaan peli
        elseif key == "escape" then
            love.event.quit()  -- Suljetaan peli
        end
    elseif gameState == "game" then
        if key == "escape" then
            gameState = "paused" -- Vaihdetaan taukovalikkoon
        end
    elseif gameState == "paused" then
        if key == "return" then
            gameState = "game" -- Jatketaan peliä
        elseif key == "escape" then
            gameState = "menu" -- Palaa päävalikkoon
        end
    end

    -- Päivitetään valikon valintaa
    local menu = menus[currentMenu] -- Nykyinen valikko

    -- Valikon valinnan käsittely
    if key == "down" then
        selectedOption = math.min(selectedOption + 1, #menus[currentMenu].options)
    elseif key == "up" then
        selectedOption = math.max(selectedOption - 1, 1)
    elseif key == "return" then
        handleMenuSelection()
    elseif key == "escape" then
        if currentMenu ~= "main" then
            currentMenu = "main" -- Palaa päävalikkoon
            selectedOption = 1
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
        drawMenu(menus.main)
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
        drawMenu(menus.pause)
    end
end

-- Yleinen valikkofunktio, joka toimii kaikille valikoille
function drawMenu(menu)
    love.graphics.clear(0.2, 0.2, 0.2) -- Taustan väri

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local titleY = screenHeight / 4
    local optionStartY = screenHeight / 2
    local spacing = 50

    -- Piirrä valikon otsikko
    love.graphics.printf(menu.title, 0, titleY, screenWidth, "center")

    for i, option in ipairs(menu.options) do
        local y = optionStartY + (i - 1) * spacing
        if i == selectedOption then
            love.graphics.setColor(1, 1, 0) -- Korostusväri
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.printf(option, 0, y, screenWidth, "center")
    end

    love.graphics.setColor(1, 1, 1) -- Palautetaan väri normaaliksi
end

-- Käsitellään valinnat
function handleMenuSelection()
    local menu = menus[currentMenu]
    local choice = menu.options[selectedOption]

    if currentMenu == "main" then
        if choice == "Start Game" then
            print("Game Started!")
        elseif choice == "Options" then
            currentMenu = "options"
            selectedOption = 1
        elseif choice == "Quit" then
            love.event.quit()
        end
    elseif currentMenu == "options" then
        if choice == "Sound: ON" then
            print("Toggling Sound!")
        elseif choice == "Back" then
            currentMenu = "main"
            selectedOption = 1
        end
    elseif currentMenu == "pause" then
        if choice == "Resume" then
            print("Resuming Game!")
        elseif choice == "Main Menu" then
            currentMenu = "main"
            selectedOption = 1
        end
    end
end
