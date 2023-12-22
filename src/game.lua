--game.lua

Game = {}

function Game:new()
    local background = love.graphics.newImage("assets/img/back.png")
    local gameMusic = love.audio.newSource("assets/sounds/game.mp3", "stream")
    gameMusic:setVolume(0.5)
    local buttonTryAgain = love.graphics.newImage("assets/img/button_tryagain.png")
    local buttonContinue = love.graphics.newImage("assets/img/button_continue.png")
    local pauseOrLoseBg = love.graphics.newImage("assets/img/bg_gameover.png")
    
    local soundOnImage = love.graphics.newImage("assets/img/s_on.png")
    local soundOffImage = love.graphics.newImage("assets/img/s_off.png")

    local scoreSound = love.audio.newSource("assets/sounds/coin.mp3", "static")
    local jumpSound = love.audio.newSource("assets/sounds/jump.wav", "static")
    local gameOverSound = love.audio.newSource("assets/sounds/death.mp3", "static")

    local highBuild = love.graphics.newImage("assets/img/high.png")
    local mediumBuild = love.graphics.newImage("assets/img/medium.png")
    local lowBuild = love.graphics.newImage("assets/img/low.png")

    local blueBalloon = love.graphics.newImage("assets/img/blue.png")
    local greenBalloon = love.graphics.newImage("assets/img/green.png")
    local orangeBalloon = love.graphics.newImage("assets/img/orange.png")

    local ufo = love.graphics.newImage("assets/img/ufo.png")

    local customFont = love.graphics.newFont("assets/font/BebasNeue-Regular.ttf", 80)
    love.graphics.setFont(customFont)
    local game = {
        buttons = {},
        visibleButtons = {},
        obstacles = {},
        background = background,
        pauseOrLoseBg = pauseOrLoseBg,
        gameMusic = gameMusic,
        scoreSound = scoreSound,
        jumpSound = jumpSound,
        gameOverSound = gameOverSound,
        soundOnImage = soundOnImage,
        soundOffImage = soundOffImage,
        soundIcon = soundOnImage,
        soundEnabled = true,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        scaleX = screenWidth / background:getWidth(),
        scaleY = screenHeight / background:getHeight(),
        flagPause = false,
        isGameOver = false,
        highBuild = highBuild,
        mediumBuild = mediumBuild,
        lowBuild = lowBuild,
        blueBalloon = blueBalloon,
        greenBalloon = greenBalloon,
        orangeBalloon = orangeBalloon,
        gravity = 800,
        jumpHeight = -400,
        obstacleSpawnTimer = 0,
        obstacleSpawnInterval = 1.8,
        score = 0
    }

    self.ufo = {
        image = ufo,
        x = ufo:getWidth()/4,
        y = game.screenHeight / 2 - ufo:getHeight()/2,
        width = ufo:getWidth() * game.scaleX,
        height = ufo:getHeight() * game.scaleY,
        velocity = 0
    }

    setmetatable(game, { __index = self })

    -- Добавление кнопок
    game:addButton("tryAgain", "button_tryagain.png", game.screenWidth/2, game.screenHeight/2, function() game:restartGame() end)
    game:addButton("continue", "button_continue.png", game.screenWidth/2 , game.screenHeight/2, function() game:togglePause() end)
    game:addButton("menu", "button_menu.png", menu.screenWidth/2, menu.screenHeight/2, function() currentGameState=gameState.MENU game:restartGame() end)

    local soundButton = {
        name = "sound",
        image = soundOnImage,
        x = 10,
        y = 10,
        width = soundOnImage:getWidth(),
        height = soundOnImage:getHeight(),
        callback = function() game:toggleSound() end
    }

    table.insert(game.buttons, soundButton)

    return game
end

function Game:restartGame()
    self.isGameOver = false
    self.gameStart = false
    self.flagPause = false
    self:getActiveButton().selected = false
    self.obstacleSpawnInterval = 1.8
    self.obstacleSpawnTimer = 0
    self.score = 0
    self.ufo.velocity = 0
    for i = #self.obstacles,1,-1 do
        table.remove(self.obstacles,i)
    end
    self.ufo.x = self.ufo.image:getWidth()/4
    self.ufo.y = self.screenHeight / 2 - self.ufo.image:getHeight()/2
end

function Game:spawnObstacle()
    local obstacleType = love.math.random(1, 3)
    local obstacle = {
        width = self.highBuild:getWidth() * self.scaleX,
        x = self.screenWidth,
        passed = false,
        type = obstacleType
    }

    if obstacleType == 1 then
        obstacle.build = self.highBuild
        obstacle.balloons = {self.blueBalloon}
    elseif obstacleType == 2 then
        obstacle.build = self.mediumBuild
        obstacle.balloons = {self.greenBalloon, self.greenBalloon}
    elseif obstacleType == 3 then
        obstacle.build = self.lowBuild
        obstacle.balloons = {self.orangeBalloon, self.orangeBalloon, self.orangeBalloon}
    end

    -- Insert the obstacle into the obstacles table
    table.insert(self.obstacles, obstacle)
end


function Game:checkCollision(buildingsType, obstacleX)
    local buildHeight = 0
    local balloonsHeight = 0
    local buildWidth = self.highBuild:getWidth()
    local balloonWidth = self.blueBalloon:getWidth()
    if buildingsType == 1 then
        buildHeight = self.highBuild:getHeight()
        balloonsHeight = self.blueBalloon:getHeight()
    elseif buildingsType == 2 then
        buildHeight = self.mediumBuild:getHeight()
        balloonsHeight = self.greenBalloon:getHeight() * 2
    elseif buildingsType == 3 then
        buildHeight = self.lowBuild:getHeight()
        balloonsHeight = self.orangeBalloon:getHeight() * 3
    end
    if self.ufo.x + self.ufo.image:getWidth()*self.scaleX-15> obstacleX-buildWidth*self.scaleX
    and self.ufo.y < self.screenHeight 
    and self.ufo.y + self.ufo.height > self.screenHeight - buildHeight*self.scaleY then
        self.isGameOver = true
        if self.soundEnabled then self.gameOverSound:play() end
        self.visibleButtons = self:getVisibleButtons()
    elseif self.ufo.x + self.ufo.image:getWidth()*self.scaleX> obstacleX-balloonWidth*self.scaleX 
    and self.ufo.y > 0
    and self.ufo.y< balloonsHeight*self.scaleY then
        self.isGameOver = true
        if self.soundEnabled then self.gameOverSound:play() end
        self.visibleButtons = self:getVisibleButtons()
    end
end

function Game:draw()
    love.graphics.setBackgroundColor(255, 255, 255)

    love.graphics.draw(self.background, 0, 0, 0, self.scaleX, self.scaleY)

    love.graphics.print(self.score, 50, 25)
    -- Отрисовка UFO
    love.graphics.draw(self.ufo.image, self.ufo.x, self.ufo.y, 0, self.scaleX, self.scaleY)
    if self.gameStart then
        --Отрисовка препятствий
        for i, obstacle in ipairs(self.obstacles) do
            love.graphics.draw(obstacle.build, obstacle.x, self.screenHeight - obstacle.build:getHeight() * self.scaleY, 0, self.scaleX, self.scaleY)
            local balloonGapAmount = 0
            for _, balloon in ipairs(obstacle.balloons) do
                love.graphics.draw(balloon, obstacle.x, balloonGapAmount, 0, self.scaleX, self.scaleY)
                balloonGapAmount = balloonGapAmount + balloon:getHeight()*self.scaleY
            end
        end
    end

    if self.isGameOver or self.flagPause then
        love.graphics.draw(self.pauseOrLoseBg, 0, 0, 0, self.scaleX, self.scaleY)
        -- Отрисовка кнопок
        for _, button in pairs(self.visibleButtons) do
            if button.selected then
                love.graphics.setColor(1, 1, 1, 0.96)
            else
                love.graphics.setColor(0.5, 0.5, 0.5, 0.92)
            end
            if button.name == "tryAgain" then 
                love.graphics.draw(button.image, button.x, button.y+button.image:getHeight()*self.scaleY*1.5, 0, self.scaleX, self.scaleY)
            else
                love.graphics.draw(button.image, button.x, button.y, 0, self.scaleX, self.scaleY)
            end
        end

        -- Восстановление цвета
        love.graphics.setColor(1, 1, 1)
    end
end

function Game:update(dt)
    if self.gameStart and not self.isGameOver and not self.flagPause then
        self.ufo.velocity = self.ufo.velocity + self.gravity*dt
        self.ufo.y = self.ufo.y + self.ufo.velocity*dt
        -- проверка столкновений
        if self.ufo.y < 0 then
            self.ufo.y = 0
            self.ufo.velocity = 0
        end

        if self.ufo.y + self.ufo.height > self.screenHeight then
            self.ufo.y = self.screenHeight - self.ufo.height
            self.ufo.velocity = 0
        end
        
        self.obstacleSpawnTimer = self.obstacleSpawnTimer + dt
        if self.obstacleSpawnTimer > self.obstacleSpawnInterval then
            self:spawnObstacle()
            self.obstacleSpawnTimer = 0
        end

        -- Обновление положения труб
        for i, obstacle in pairs(self.obstacles) do
            --скорость игры
            obstacle.x = obstacle.x - 300*dt


            if obstacle.x - obstacle.width < self.ufo.x + 20 and not obstacle.passed then
                self:checkCollision(obstacle.type, obstacle.x)
            end

            -- Увеличение счета
            if obstacle.x + obstacle.width < self.ufo.x and not obstacle.passed then
                self.score = self.score + 1
                if self.soundEnabled then self.scoreSound:play() end
                obstacle.passed = true
            end
        end

        -- Удаление труб, что вышли за пределы экрана
        for i = #self.obstacles,1,-1 do
            if self.obstacles[i].x + self.obstacles[i].width < 0 then table.remove(self.obstacles,i) end
        end
    end

    if love.keyboard.isDown("space") then
        self.gameStart = true 
    end   
        

    for i, button in pairs(self.buttons) do
        if button.callback == self.toggleSound then
            button.image = self.soundIcon
        end
    end
end
function Game:startMusic()
    -- Установка музыки на повторение и воспроизведение
    self.gameMusic:setLooping(true)
    love.audio.play(self.gameMusic)
end

function Game:stopMusic()
    self.gameMusic:setLooping(false)
    love.audio.stop(self.gameMusic)
end

function Game:toggleSound()
    self.soundEnabled = not self.soundEnabled

    if self.soundEnabled then
        self.soundIcon = self.soundOnImage
    else
        self.soundIcon = self.soundOffImage
    end
    for i, button in ipairs(self.buttons) do
        if button.name == "sound" then
            button.image = self.soundIcon
        end
    end
end

function Game:addButton(name, imageFile, x, y, callback)
    -- Создание изображения кнопки и добавление кнопки в массив
    local buttonImage = love.graphics.newImage("assets/img/" .. imageFile)
    local button = {
        name = name,
        image = buttonImage,
        x = x - buttonImage:getWidth()/2 * self.scaleX,
        y = y - buttonImage:getHeight() / 2 * self.scaleY + (#self.buttons * buttonImage:getHeight() * self.scaleY),
        selected = false,
        callback = callback,
        buttonMargin = buttonImage:getHeight() * self.scaleY * 1.5
    }

    table.insert(self.buttons, button)

    -- Пересчет координат всех кнопок после добавления новой
    local totalButtonHeight = #self.buttons * buttonImage:getHeight() * self.scaleY
    local centerY = self.screenHeight / 2

    for i, button in ipairs(self.buttons) do
        if i == 1 then button.selected = true end
        button.y = centerY - totalButtonHeight / 2 + (i - 1) * button.buttonMargin - (#self.buttons * buttonImage:getHeight() * self.scaleY) / 2.5
    end
end

function Game:togglePause()
    self.flagPause = not self.flagPause
end

function Game:mousepressed(x, y, button, istouch, presses)
    for i, button in pairs(self.buttons) do
        if x >= button.x and x <= button.x + button.image:getWidth() and y >= button.y and y <= button.y + button.image:getHeight() then
            if button.callback then
                button.callback()
            end
        end
    end
end

function Game:keypressed(key)
    if self.isGameOver == true or self.flagPause == true then
        if key == "return" or key == "kpenter" then
            -- Выполнение обратного вызова активной кнопки
            local activeButton = self:getActiveButton()
            if activeButton and activeButton.callback then
                activeButton.callback()
            end
        elseif key == "up" then
            self:moveSelection(-1)
        elseif key == "down" then
            self:moveSelection(1)
        end
    end
    if self.isGameOver == false then
        if key == "escape" then
            self:togglePause()
            self.visibleButtons = self:getVisibleButtons()
        end
        if self.gameStart and key == "space" then
            self.ufo.velocity = self.jumpHeight
            if self.soundEnabled then self.jumpSound:play() end
        end
    end
end

function Game:moveSelection(direction)
    -- Найти текущую выбранную кнопку
    local currentButton = self:getActiveButton()
    -- Снять выделение с текущей кнопки
    if currentButton then
        currentButton.selected = false
    end
    
    -- Вычислить индекс следующей кнопки
    local currentIndex = 1
    if currentButton then
        for i, button in ipairs(self.visibleButtons) do
            if button == currentButton then
                currentIndex = i
                break
            end
        end
    
        local nextIndex = ((currentIndex - 1) + direction) % #self.visibleButtons + 1
    
        -- Выделить следующую кнопку
        local nextButton = self.visibleButtons[nextIndex]
        if nextButton then
            nextButton.selected = true
        end
    end
end

function Game:getVisibleButtons()
    -- Возвращает массив только отображаемых кнопок
    local newVisibleButtons = {}
    for i, button in ipairs(self.buttons) do
        if (button.name == "tryAgain" and not self.flagPause) or
           (button.name == "continue" and not self.isGameOver) or
           (button.name == "sound") or
           (button.name == "menu") then
            table.insert(newVisibleButtons, button)
        end
    end
    newVisibleButtons[1].selected = true
    return newVisibleButtons
end


function Game:getActiveButton()
    for _, button in ipairs(self.visibleButtons) do
        if button.selected then
            return button
        end
    end
    return nil
end

