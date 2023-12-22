-- main.lua

require "menu"
require "game"

gameState = {
    MENU = "menu",
    GAME = "game"
}

currentGameState = gameState.MENU

function love.load()
    screenWidth, screenHeight = love.window.getDesktopDimensions()
    love.window.setMode(screenWidth, screenHeight)
    menu = Menu:new()
    game = Game:new()
end

function love.draw()
    if currentGameState == gameState.MENU then
        if menu.soundEnabled == true then
            menu:startMusic()
            game:stopMusic()
        else
            menu:stopMusic()
        end
        menu:draw()
    elseif currentGameState == gameState.GAME then
        -- Останвливаем музыку в меню
        menu:stopMusic()
        if game.soundEnabled == true then
            game:startMusic()
        else
            game:stopMusic()
        end
        game:draw()
    end
end

function love.update(dt)
    if currentGameState == gameState.MENU then
        menu:update(dt)
    elseif currentGameState == gameState.GAME then
        game:update(dt)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if currentGameState == gameState.MENU then
        menu:mousepressed(x, y, button, istouch, presses)
    elseif currentGameState == gameState.GAME then
        game:mousepressed(x, y, button, istouch, presses)
    end
end

function love.keypressed(key)
    if currentGameState == gameState.MENU then
        menu:keypressed(key)
    elseif currentGameState == gameState.GAME then
        game:keypressed(key)
    end
end