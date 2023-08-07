---@diagnostic disable: lowercase-global, undefined-global
---@funkinScript

--[[
    Creator: RamenDominoes (https://gamebanana.com/members/2135195)
    Version: 3.0.1 (Now with Psych v0.7 compatibility!!!)
]]--

local WHITE = 'FFFFFF'
local BLACK = '000000'
local scriptVersion = "3.0.2" -- so that I don't gotta keep scrolling all the way down to change it
local pressedOptionsKey = false
local allowCountdown = false
local allowSongEnd = false

local playerPrefs = { -- Default Values
    enterOptions =      true,

    showHitTimings =    true,
    showNPS =           true,
    showCombo =         true,
    showColorScheme =   true,
    showUnderlay =      true,
    showJudgements =    true,
    showResults =       true,

    underlayType =      1,
    underlayOpacity =   70,
    judgementType =     1,
    resultsType =       1,
    colorPalette =      1
}
local colorPalettes = { -- Name, Quote, Palette (I wanna try to make a way to create a custom color palette in-game, that would be cool I think [I already have an idea how to, it's just very unpolished])
    {'Default',     '"Made by yours truly." -RamenDominoes',        {'FED636','1FFEB2','FF2BB2','FE3636','9F2121'} },
    {'Malke',       '"Mommy kinky..." -Malke',                      {'FF0040','863D53','4E425F','5E5E5E','420707'} },
    {'Etterna',     'Play Etterna!!!',                              {'99CCFF','14CC8F','FF1AB3','E67617','CC2929'} },
    {'Kade Engine', 'The original FNF results screen.',             {'00FDFD','00FD00','FD0000','8A0000','570000'} },
    {'Camellia',    'A little bit of old, a little bit of new.',    {'D65F57','F7FD5B','006DFD','FD7607','570000'} }
}
local stats = {
    curCombo = 0,
    maxCombo = 0,
    curNPS = 0,
    maxNPS = 0,
    mean = 0,
    accuracy = 0,
    hitsAndMisses = 0
}
local subtractNPS = false

function onCreate()
	-- luaDebugMode = true
	-- luaDeprecatedWarnings = true
    if stringStartsWith(version, '0.6') then
        debugPrint("THIS SCRIPT MAY NOT BE COMPATIBLE WITH THIS VERSION OF PSYCH ENGINE, PLEASE UPDATE YOUR ENGINE.")
    end
    loadPlayerPrefs()
end

function onCreatePost()
    if playerPrefs.enterOptions then
        createMainMenu()
    else
        if botPlay then
            newScoreText = '[Botplay!]'
            if playerPrefs.showNPS then
                newScoreText = newScoreText .. ' | NPS: ' .. stats.curNPS .. ' (' .. stats.maxNPS .. ')'
            end
            if playerPrefs.showCombo then
                newScoreText = newScoreText .. ' | Combo: ' .. stats.curCombo .. ' (' .. stats.maxCombo .. ')'
            end
        else
            stats.accuracy = round((rating * 100), 2)
            newScoreText = 'Score: ' .. score .. ' | '
            if playerPrefs.showNPS then
                newScoreText = newScoreText .. 'NPS: ' .. stats.curNPS .. ' (' .. stats.maxNPS .. ') | '
            end
            if playerPrefs.showCombo then
                newScoreText = newScoreText .. 'Combo: ' .. stats.curCombo .. ' (' .. stats.maxCombo .. ') | '
            end
            newScoreText = newScoreText .. 'Misses: ' .. misses .. ' | Rating: ' .. ratingName .. ' (' .. stats.accuracy .. '%) - N/A'
        end
        setTextString('scoreTxt', newScoreText)
        setTextSize('scoreTxt', playerPrefs.showNPS and 18 or playerPrefs.showCombo and 18 or 20)

        if playerPrefs.showColorScheme then
            debugPrint("Current Color Palette: " .. colorPalettes[playerPrefs.colorPalette][1])
        end
        if playerPrefs.showUnderlay then
            for i = 0,3 do
                if playerPrefs.underlayType == 2 or playerPrefs.underlayType == 3 then
                    luaGraphic("opponentUnderlay" .. i, getPropertyFromGroup("opponentStrums", i, "x"), 0, 112, screenHeight, BLACK, "HUD")
                    setProperty("opponentUnderlay" .. i .. '.alpha', playerPrefs.underlayOpacity / 100)
                end
                if playerPrefs.underlayType == 1 or playerPrefs.underlayType == 3 then
                    luaGraphic("playerUnderlay" .. i, getPropertyFromGroup("playerStrums", i, "x"), 0, 112, screenHeight, BLACK, "HUD")
                    setProperty("playerUnderlay" .. i .. '.alpha', playerPrefs.underlayOpacity / 100)
                end
            end
        end
        local gameRatings = {"Sicks", "Goods", "Bads", "Shits", "Misses"}
        if playerPrefs.showJudgements then
            for i = 1, #gameRatings do
                luaText('judgementText' .. i, ((playerPrefs.judgementType == 1 and 0) or (playerPrefs.judgementType == 2 and screenWidth - 180)), ((i * 25) + 320) - 25, 110, 25, colorPalettes[playerPrefs.colorPalette][3][i], BLACK, 2, "LEFT", gameRatings[i] .. ':', "HUD")
                luaText('judgementCount' .. i, getProperty('judgementText' .. i .. '.x') + 100, getProperty('judgementText' .. i .. '.y'), 80, 25, WHITE, BLACK, 2, "RIGHT", "0", "HUD")
            end
        end
        if playerPrefs.showHitTimings then
            luaText('hitTimeText', getPropertyFromGroup('playerStrums', 1, 'x'), 0, 224, 30, WHITE, BLACK, 1, "CENTER", "", "HUD")
            screenCenter('hitTimeText', 'y')
        end
    end
end

function onStartCountdown()
    if playerPrefs.enterOptions then
        if not allowCountdown then
            return Function_Stop
        end
        if allowCountdown then
            return Function_Continue
        end
    else
        allowCountdown = true -- to prevent a luaDebugMode thing lol
    end
end

function onUpdate()
    if playerPrefs.enterOptions and not allowCountdown then
        keyPressHandler("UP", changeMainMenu, -1)
        keyPressHandler("DOWN", changeMainMenu, 1)
        if keyboardJustPressed('ENTER') then
            playSound("dialogueClose")
            if mainItems[curMain] ~= "Save & Exit" then
                openCustomSubstate(mainItems[curMain], true)
            else
                playerPrefs.enterOptions = not playerPrefs.enterOptions
                savePlayerPrefs()
                restartSong()
            end
        end
    elseif not playerPrefs.enterOptions then
        if keyboardJustPressed('F1') and not pressedOptionsKey then
            pressedOptionsKey = true
            debugPrint("The options menu will appear upon the next loaded song.")
        end
        if stats.curNPS > 0 and not subtractNPS then
            subtractNPS = true
            runTimer('subtractNPS', 1 / stats.curNPS , 1)
        elseif stats.curNPS == 0 then
            subtractNPS = false
        end
        if playerPrefs.showUnderlay then
            for i = 0,3 do
                if playerPrefs.underlayType == 2 or playerPrefs.underlayType == 3 then
                    setProperty("opponentUnderlay" .. i ..".x", getPropertyFromGroup("opponentStrums", i, "x"))
                end
                if playerPrefs.underlayType == 1 or playerPrefs.underlayType == 3 then
                    setProperty("playerUnderlay" .. i ..".x", getPropertyFromGroup("playerStrums", i, "x"))
                end
            end
        end
        if playerPrefs.showHitTimings then
            setProperty("hitTimeText.x", getPropertyFromGroup('playerStrums', 1, 'x'))
        end
    end
end

function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    local time = (getPropertyFromClass('backend.Conductor', 'songPosition') / songLength) * 100
    local strumTime = getPropertyFromGroup('notes', membersIndex, 'strumTime')
    local songPosition = getPropertyFromClass('backend.Conductor', 'songPosition')
    local playerOffset = getPropertyFromClass('backend.ClientPrefs','data.ratingOffset')
    local rawMilliseconds = strumTime - songPosition + playerOffset
    local simpleMilliseconds = round(-rawMilliseconds, 2)

    local songRatings = {
        getProperty('ratingsData[0].hits'), -- sicks
        getProperty('ratingsData[1].hits'), -- goods
        getProperty('ratingsData[2].hits'), -- bads
        getProperty('ratingsData[3].hits'), -- shits
        getProperty('songMisses')
    }

    local ratingsMap = {
        ['sick'] = 1,
        ['good'] = 2,
        ['bad'] = 3,
        ['shit'] = 4
    }
    local curRating = getPropertyFromGroup('notes', membersIndex, 'rating')

    if not isSustainNote then
        stats.curCombo = stats.curCombo + 1
        stats.curNPS = stats.curNPS + 1
        if stats.curCombo > stats.maxCombo then
            stats.maxCombo = stats.maxCombo + 1
        end
        if stats.curNPS > stats.maxNPS then
            stats.maxNPS = stats.maxNPS + 1
        end

        stats.hitsAndMisses = stats.hitsAndMisses + 1

        if playerPrefs.showHitTimings and ratingsMap[curRating] then
            cancelTimer('hitTimeTimer')
            cancelTween('hitTimeAlpha')
            setTextColor('hitTimeText', colorPalettes[playerPrefs.colorPalette][3][ratingsMap[curRating]])
            setTextString('hitTimeText', simpleMilliseconds..' ms')
            setProperty('hitTimeText.alpha', 0.75)
            runTimer('hitTimeTimer', 0.3, 1)
        end

        if ratingsMap[curRating] then
            luaGraphic('playerHit' .. stats.hitsAndMisses, 55 + (round(time, 2) * 5.47), 522.25 - (simpleMilliseconds / 2), 3, 3, colorPalettes[playerPrefs.colorPalette][3][ratingsMap[curRating]])
            setObjectOrder('playerHit' .. stats.hitsAndMisses, 100) -- lol
            setProperty('playerHit' .. stats.hitsAndMisses .. '.alpha', 0)
        end

    end
    onUpdateScore()
    if playerPrefs.showJudgements then
        for i = 1, #songRatings do
            setTextString('judgementCount' .. i, songRatings[i])
        end
    end
end
function noteMiss(membersIndex, noteData, noteType, isSustainNote)
    local time = (getPropertyFromClass('backend.Conductor', 'songPosition') / songLength) * 100
    local strumTime = getPropertyFromGroup('notes', membersIndex, 'strumTime')
    local songPosition = getPropertyFromClass('backend.Conductor', 'songPosition')
    local playerOffset = getPropertyFromClass('backend.ClientPrefs','data.ratingOffset')
    local rawMilliseconds = strumTime - songPosition + playerOffset
    local simpleMilliseconds = round(-rawMilliseconds, 2)

    local songRatings = {
        getProperty('ratingsData[0].hits'), -- sicks
        getProperty('ratingsData[1].hits'), -- goods
        getProperty('ratingsData[2].hits'), -- bads
        getProperty('ratingsData[3].hits'), -- shits
        getProperty('songMisses')
    }

    stats.curCombo = 0
    stats.hitsAndMisses = stats.hitsAndMisses + 1
    onUpdateScore()
    if not isSustainNote then
        luaGraphic('playerHit' .. stats.hitsAndMisses, 55 + (round(time, 2) * 5.47), 522.25 - 87, 3, 3, colorPalettes[playerPrefs.colorPalette][3][5])
        setObjectOrder('playerHit' .. stats.hitsAndMisses, 100) -- lol
        setProperty('playerHit' .. stats.hitsAndMisses .. '.alpha', 0)
    end
    if playerPrefs.showJudgements then
        for i = 1, #songRatings do
            setTextString('judgementCount' .. i, songRatings[i])
        end
    end
end

function onUpdateScore(miss)
    if botPlay then
        newScoreText = '[Botplay!]'
        if playerPrefs.showNPS then
            newScoreText = newScoreText .. ' | NPS: ' .. stats.curNPS .. ' (' .. stats.maxNPS .. ')'
        end
        if playerPrefs.showCombo then
            newScoreText = newScoreText .. ' | Combo: ' .. stats.curCombo .. ' (' .. stats.maxCombo .. ')'
        end
    else
        stats.accuracy = round((rating * 100), 2)
        newScoreText = 'Score: ' .. score .. ' | '
        if playerPrefs.showNPS then
            newScoreText = newScoreText .. 'NPS: ' .. stats.curNPS .. ' (' .. stats.maxNPS .. ') | '
        end
        if playerPrefs.showCombo then
            newScoreText = newScoreText .. 'Combo: ' .. stats.curCombo .. ' (' .. stats.maxCombo .. ') | '
        end
        newScoreText = newScoreText .. 'Misses: ' .. misses .. ' | Rating: ' .. ratingName .. ' (' .. stats.accuracy .. '%) - ' .. ratingFC
    end
    setTextString('scoreTxt', newScoreText)
end

function onTimerCompleted(tag, loops, loopsleft)
    if tag == 'subtractNPS' and stats.curNPS > 0 then
        runTimer('subtractNPS', 1 / stats.curNPS, 1)
        stats.curNPS = stats.curNPS - 1
        onUpdateScore()
    end
    if tag == 'hitTimeTimer' and playerPrefs.showHitTimings then
        doTweenAlpha('hitTimeAlpha', 'hitTimeText', 0, 0.5)
    end
end

function onEndSong()
    if playerPrefs.showResults then
        if playerPrefs.resultsType == 1 or (playerPrefs.resultsType == 2 and isStoryMode) or (playerPrefs.resultsType == 3 and not isStoryMode) then
            if not allowSongEnd then
                openCustomSubstate('Results', true)
            end
        else
            allowSongEnd = true
        end
    else
        allowSongEnd = true
    end
    if not allowSongEnd then
        return Function_Stop
    end
    if allowSongEnd then
        return Function_Continue
    end
end

function onDestroy()
    if pressedOptionsKey then -- have to do it like this or else the NPS counter fucks up if you press [F1]
        playerPrefs.enterOptions = true
        savePlayerPrefs()
    end
end


-- Substate Stuff
local canExit = false
function onCustomSubstateCreate(name)
    -- debugPrint('This is the "' .. name .. '" substate.')
    if playerPrefs.enterOptions then
        setMainMenuVisibility(false)
        if name == 'Visibility' then
            createVisibilityMenu()
        elseif name == 'Gameplay' then
            createGameplayMenu()
        elseif name == 'Colors' then
            createColorsMenu()
        elseif name == 'Reset Settings' then
            createResetMenu()
        end
    else
        if name == 'Results' then
            menuMusic = string.lower(string.gsub(getPropertyFromClass("backend.ClientPrefs", "data.pauseMusic"), ' ', '-'))
            playMusic(menuMusic, 0, true)
            musicFadeIn(10, 0, 1) -- how tf am i supposed to use "soundFadeIn" instead if that function needs a tag???

            allowSongEnd = true

            luaGraphic('resultsBackground', 0, 0, 1, 1, WHITE)
            screenCenter('resultsBackground')
            doTweenX('resultsBackgroundTweenX', 'resultsBackground.scale', screenWidth, 0.25, "sineOut") -- Initial Tween

            createSongTitleBox()
            createStatsBox()
            createBarGraphBox()
            createSongProgressBox()
            createExitBox()
        end
    end
end
function onTweenCompleted(tag)
    if tag == "resultsBackgroundTweenX" then
        doTweenY('resultsBackgroundTweenY', 'resultsBackground.scale', screenHeight, 0.5, "sineOut")
    elseif tag == "resultsBackgroundTweenY" then
        setProperty('camGame.visible', false)
        setProperty('camHUD.visible', false)
        luaBox('resultsBackgroundBorder', 0, 0, screenWidth, screenHeight, BLACK, WHITE, 10, 0)
        doTweenColor('resultsBackgroundTweenColor', 'resultsBackground', RGBToHex(getProperty('dad.healthColorArray')), 1, "sineOut")
    elseif tag == "resultsBackgroundTweenColor" then
        doTweenY("songNameBoxTweenX",           'songNameBox1',         30,     1,    "sineOut") -- Song Name
        doTweenX("statsBoxTweenX",              'statsBox1',            650,    1,    "sineOut") -- Stats Box
        doTweenX("barBoxTweenX",                'barBox1',              30,     1,    "sineOut") -- Bar Graph Box
        doTweenX("progressionBorderTweenX",     'progressionBorder1',   30,     1,    "sineOut") -- Dots Graph Box
        doTweenX("exitBoxTweenX",               'exitBox1',             650,    1,    "sineOut") -- Exit Box
    elseif tag == "exitBoxTweenX" then
        if stats.hitsAndMisses > 0 then
            for i = 1, stats.hitsAndMisses do
                doTweenAlpha("playerHitTweenAlpha" .. i, 'playerHit' .. i, 1, 1, "sineOut")
            end
        else
            canExit = true -- just incase some mf ends the song without a note being played
        end
    elseif tag == "playerHitTweenAlpha1" then
        canExit = true
    elseif tag == 'resultsTweenAlpha' then
        closeCustomSubstate()
    end
end
function  onCustomSubstateUpdate(name, elapsed)
    if playerPrefs.enterOptions then
        if keyboardJustPressed('BACKSPACE') then
            playSound("cancelMenu")
            closeCustomSubstate()
        end
        if name == 'Visibility' then
            keyPressHandler("UP", changeVisibilityMenu, -1)
            keyPressHandler("DOWN", changeVisibilityMenu, 1)
            if keyboardJustPressed("ENTER") then
                playSound("dialogue")
                playerPrefs[visibilityItems[curVisibility][3]] = not playerPrefs[visibilityItems[curVisibility][3]]
                setProperty('visibilityCheck' .. curVisibility .. '.visible', playerPrefs[visibilityItems[curVisibility][3]])
            end
        elseif name == 'Gameplay' then
            keyPressHandler("UP", changeGameplayMenu, -1)
            keyPressHandler("DOWN", changeGameplayMenu, 1)
            if curGameplay == 1 then
                keyPressHandler("LEFT", changeGameplayOption, -1)
                keyPressHandler("RIGHT", changeGameplayOption, 1)
            elseif curGameplay == 2 then
                if gameplayItems[1][curGameplayOption][1] == "Underlays Shown" then
                    keyPressHandler("LEFT", changeUnderlayType, -1)
                    keyPressHandler("RIGHT", changeUnderlayType, 1)

                    setProperty('opponentUnderlay.visible', playerPrefs.underlayType == 2 or playerPrefs.underlayType == 3)
                    setProperty('playerUnderlay.visible', playerPrefs.underlayType == 1 or playerPrefs.underlayType == 3)
                    setTextString('gameplayText2', '< ' .. gameplayItems[2][curGameplayOption][curUnderlayType] .. ' >')
                elseif gameplayItems[1][curGameplayOption][1] == "Underlay Opacity" then
                    if keyboardPressed("LEFT") or keyboardPressed("RIGHT") then
                        timeHeld = timeHeld + (1 * elapsed)
                    elseif not keyboardPressed("LEFT") or not keyboardPressed("RIGHT") then
                        timeHeld = 0
                    end
                    if timeHeld > 0.5 then
                        if keyboardPressed("LEFT") then
                            changeUnderlayOpacity(-1)
                        elseif keyboardPressed("RIGHT") then
                            changeUnderlayOpacity(1)
                        end
                    else
                        keyPressHandler("LEFT", changeUnderlayOpacity, -1)
                        keyPressHandler("RIGHT", changeUnderlayOpacity, 1)
                    end
                    setProperty('opponentUnderlay.alpha', playerPrefs.underlayOpacity / 100)
                    setProperty('playerUnderlay.alpha', playerPrefs.underlayOpacity / 100)

                    setTextString('gameplayText2', '< ' .. curUnderlayOpacity .. '% >')
                elseif gameplayItems[1][curGameplayOption][1] == "Judgement Tracker Side" then
                    keyPressHandler("LEFT", changeJudgementType, -1)
                    keyPressHandler("RIGHT", changeJudgementType, 1)

                    setTextAlignment('judgementText', gameplayItems[2][3][curJudgementType])

                    setTextString('gameplayText2', '< ' .. gameplayItems[2][curGameplayOption][playerPrefs.judgementType] .. ' >')
                elseif gameplayItems[1][curGameplayOption][1] == "Results Screen Presence" then
                    keyPressHandler("LEFT", changeResultsPresence, -1)
                    keyPressHandler("RIGHT", changeResultsPresence, 1)
                    setTextString('gameplayText2', '< ' .. gameplayItems[2][curGameplayOption][playerPrefs.resultsType] .. ' >')
                end
            end
        elseif name == 'Colors' then
            keyPressHandler("LEFT", changeColorsMenu, -1)
            keyPressHandler("RIGHT", changeColorsMenu, 1)
        elseif name == 'Reset Settings' then
            keyPressHandler("LEFT", changeResetMenu, -1)
            keyPressHandler("RIGHT", changeResetMenu, 1)
            if keyboardJustPressed("ENTER") then
                playSound("dialogueClose")
                if resetItems[curReset] == "No" then
                    closeCustomSubstate()
                elseif resetItems[curReset] == "Yes" then
                    resetPlayerPrefs()
                    loadPlayerPrefs()
                    closeCustomSubstate()
                end
            end
        end
    else
        anchoring()
        if keyboardJustPressed('ENTER') and canExit then
            canExit = false
            playSound('confirmMenu')
            doTweenAlpha('resultsTweenAlpha', 'camOther', 0, 2, 'linear')
            musicFadeOut(2, 0)
        end
    end
end
function  onCustomSubstateDestroy(name)
    -- debugPrint('Closed "' .. name .. '" substate.')
    if playerPrefs.enterOptions then
        setMainMenuVisibility(true)
        if name == 'Visibility' then
            removeVisibilityMenu()
        elseif name == 'Gameplay' then
            removeGameplayMenu()
        elseif name == 'Colors' then
            removeColorsMenu()
        elseif name == 'Reset Settings' then
            removeResetMenu()
        end
    else
        if name == 'Results' then
            endSong()
        end
    end
end


-- Results screen stuff
function createSongTitleBox()
    luaBox('songNameBox', 90, -80, 1100, 80, BLACK, WHITE, 10, 75) -- 90 x 30 (Tween the Y)
    luaText('songNameText', getProperty('songNameBox1.x'), getProperty('songNameBox1.y') + 18, getProperty('songNameBox1.width'), 40, WHITE, BLACK, 2, "CENTER", songName .. " | " .. difficultyName)
end
function createStatsBox()
    score =                 botPlay and "N/A"       or score
    stats.accuracy =        botPlay and "N/A"       or stats.accuracy .. "%"
    ratingFC =              botPlay and "N/A"       or "[" .. ratingFC .. "]"

    botPlayText =           botPlay and "Botplay!"  or "Song Cleared!"

    usedStats = { -- Display Name, Stat Tag
        {"Score", score},
        {"Accuracy", stats.accuracy},
        {"Rating", ratingFC},
        {"Total Hits", hits .. "/" .. getProperty("totalPlayed")},
        {"Max Combo", stats.maxCombo},
        {"Max NPS", stats.maxNPS}
        -- {"Mean", stats.mean}
    }

    luaBox('statsBox', screenWidth, 130, 600, 480, BLACK, WHITE, 10, 75) -- 650 x 130 (Tween the X)
    luaText('genericText', getProperty('statsBox1.x'), getProperty('statsBox1.y') + 20, getProperty('statsBox1.width'), 50, WHITE, BLACK, 2, "CENTER", botPlayText)
    luaGraphic('genericUnderline', (getProperty('genericText.x') + (getProperty('genericText.width') / 2)) - (400 / 2), getProperty('genericText.y') + getProperty('genericText.height'), 400, 3, WHITE)
    for i = 1, #usedStats do
        luaText('statsDisplay' .. i, getProperty('statsBox1.x') + 20, (getProperty('genericUnderline.y') + (i * 60)) - 40, getProperty('statsBox1.width') - 20, 40, WHITE, BLACK, 2, "LEFT", usedStats[i][1] .. ":")
        luaText('statsValue' .. i, getProperty('statsBox1.x'), (getProperty('genericUnderline.y') + (i * 60)) - 40, getProperty('statsBox1.width') - 20, 40, WHITE, BLACK, 2, "RIGHT", usedStats[i][2])
    end
end
function createBarGraphBox()
    percentages = {"100%", "75%", "50%", "25%", "0%"}
    barRatings = {
        {"Sicks", getProperty('ratingsData[0].hits')}, -- sicks
        {"Goods", getProperty('ratingsData[1].hits')}, -- goods
        {"Bads", getProperty('ratingsData[2].hits')}, -- bads
        {"Shits", getProperty('ratingsData[3].hits')}, -- shits
        {"Misses", getProperty('songMisses')}, -- misses
    }

    luaBox('barBox', -600, 130, 600, 260, BLACK, WHITE, 10, 75) -- 30 x 130 (Tween the X)
    luaGraphic('barSpine', getProperty('barBox1.x') + 70, getProperty('barBox1.y') + 40, 1, 180, WHITE)
    for i = 1, #percentages do
        luaGraphic('percentagesLine' .. i, getProperty('barSpine.x') - 5, (getProperty('barSpine.y') + (i * 45)) - 45, 465, 1, WHITE)
        luaText('percentagesText' .. i, getProperty('percentagesLine' .. i .. '.x') - 40, getProperty('percentagesLine' .. i .. '.y') - 8, 40, 16, WHITE, BLACK, 1, "RIGHT", percentages[i])
    end
    for i = 1, #barRatings do
        luaGraphic('barRating' .. i, ((getProperty('barSpine.x') + 9) + (i * 90)) - 90, (getProperty('barSpine.y') + 180) - (180 * (barRatings[i][2] / stats.hitsAndMisses)), 80, 1, colorPalettes[playerPrefs.colorPalette][3][i])
        luaText('barRatingText' .. i, getProperty('barRating' .. i .. '.x'), (getProperty('barSpine.y') + getProperty('barSpine.height')) + 6, getProperty('barRating' .. i .. '.width'), 16, WHITE, BLACK, 1, "CENTER", barRatings[i][1])
        luaText('barCountText' .. i, getProperty('barRating' .. i .. '.x'), getProperty('barBox1.y') + 15, getProperty('barRating' .. i .. '.width'), 16, WHITE, BLACK, 1, "CENTER", barRatings[i][2])
        luaText('barPercent' .. i, getProperty('barRating' .. i .. '.x'), getProperty('barRating' .. i .. '.y') - 10, getProperty('barRating' .. i .. '.width'), 14, WHITE, BLACK, 1, "CENTER", round((barRatings[i][2] / stats.hitsAndMisses) * 100, 2) .. "%")

        scaleObject('barRating' .. i, 1, 180 * (barRatings[i][2] / stats.hitsAndMisses))
    end
end
function createSongProgressBox()
    ratingMarkers = { -- Color, Hit Time
        colorPalettes[playerPrefs.colorPalette][3][4],
        colorPalettes[playerPrefs.colorPalette][3][3],
        colorPalettes[playerPrefs.colorPalette][3][2],
        colorPalettes[playerPrefs.colorPalette][3][1],
        colorPalettes[playerPrefs.colorPalette][3][2],
        colorPalettes[playerPrefs.colorPalette][3][3],
        colorPalettes[playerPrefs.colorPalette][3][4]
    }

    luaBox('progressionBorder', -600, 410, 600, 280, BLACK, WHITE, 10, 75) -- 30 x 410 (Tween the X)
    luaBox('progressionBox', getProperty('progressionBorder1.x') + 20, getProperty('progressionBorder1.y') + 20, 560, 190, BLACK, WHITE, 5, 75)
    luaBox('timingsBox', getProperty('progressionBorder1.x') + 20, (getProperty('progressionBox1.y') + getProperty('progressionBox1.height')) + 10, 560, 40, BLACK, WHITE, 5, 75)
    luaText('timingsText', getProperty('timingsBox1.x') + 5, getProperty('timingsBox1.y') + 6, getProperty('timingsBox1.width') - 10, 26, WHITE, BLACK, 2, "CENTER", "Sick:45ms | Good:90ms | Bad:135ms")

    for i = 1, #ratingMarkers do
        luaGraphic('markerLine' .. i, getProperty('progressionBox1.x') + 5, (getProperty('progressionBox1.y') + 26) + ((i * 22.5) - 22.5), getProperty('progressionBox1.width') - 10, 1, ratingMarkers[i])
        setProperty('markerLine' .. i .. '.alpha', 0.75)
    end

    luaText('tooLateText', getProperty('progressionBox1.x') + 5, getProperty('progressionBox1.y') + 5, getProperty('progressionBox1.width') - 10, 16, WHITE, BLACK, 1, "LEFT", 'Too Late (+180ms)')
    setProperty('tooLateText.alpha', 0.25)
    luaText('tooEarlyText', getProperty('progressionBox1.x') + 5, (getProperty('progressionBox1.y') + getProperty('progressionBox1.height')) - 24, getProperty('progressionBox1.width') - 10, 16, WHITE, BLACK, 1, "LEFT", 'Too Early (-180ms)')
    setProperty('tooEarlyText.alpha', 0.25)
end
function createExitBox()
    luaBox('exitBox', screenWidth, 630, 600, 60, BLACK, WHITE, 10, 75) -- 650 x 630 (Tween the X)
    luaText('exitText', getProperty('exitBox1.x'), getProperty('exitBox1.y') + 14, getProperty('exitBox1.width'), 34, WHITE, BLACK, 2, "CENTER", "Press [ENTER] to Continue!")
end
function anchoring()
    -- Song Name
    boxAnchoring("songNameBox")
    setPosition("songNameText", getProperty('songNameBox1.x'), getProperty('songNameBox1.y') + 18)

    -- Stats Box
    boxAnchoring("statsBox")
    setPosition("genericText", getProperty('statsBox1.x'), getProperty('statsBox1.y') + 20)
    setPosition("genericUnderline", (getProperty('genericText.x') + (getProperty('genericText.width') / 2)) - (400 / 2), getProperty('genericText.y') + getProperty('genericText.height'))
    for i = 1, #usedStats do
        setPosition("statsDisplay" .. i, getProperty('statsBox1.x') + 20, (getProperty('genericUnderline.y') + (i * 60)) - 40)
        setPosition("statsValue" .. i, getProperty('statsBox1.x'), (getProperty('genericUnderline.y') + (i * 60)) - 40)
    end

    -- Bar Graph Box
    boxAnchoring("barBox")
    setPosition("barSpine", getProperty('barBox1.x') + 70, getProperty('barBox1.y') + 40)
    for i = 1, #percentages do
        setPosition("percentagesLine" .. i, getProperty('barSpine.x') - 5, (getProperty('barSpine.y') + (i * 45)) - 45)
        setPosition("percentagesText" .. i, getProperty('percentagesLine' .. i .. '.x') - 40, getProperty('percentagesLine' .. i .. '.y') - 8)
    end
    for i = 1, #barRatings do
        setPosition("barRating" .. i, ((getProperty('barSpine.x') + 9) + (i * 90)) - 90, (getProperty('barSpine.y') + 180) - (180 * (barRatings[i][2] / stats.hitsAndMisses)))
        setPosition("barRatingText" .. i, getProperty('barRating' .. i .. '.x'), (getProperty('barSpine.y') + getProperty('barSpine.height')) + 6)
        setPosition("barCountText" .. i, getProperty('barRating' .. i .. '.x'), getProperty('barBox1.y') + 15)
        setPosition("barPercent" .. i, getProperty('barRating' .. i .. '.x'), getProperty('barRating' .. i .. '.y') - 10)
    end

    -- Dots Graph Box
    boxAnchoring("progressionBorder")
    boxAnchoring("progressionBox")
    boxAnchoring("timingsBox")

    setPosition("progressionBox1", getProperty('progressionBorder1.x') + 20, getProperty('progressionBorder1.y') + 20)
    setPosition("timingsBox1", getProperty('progressionBorder1.x') + 20, (getProperty('progressionBox1.y') + getProperty('progressionBox1.height')) + 10)
    setPosition("timingsText", getProperty('timingsBox1.x') + 5, getProperty('timingsBox1.y') + 6)
    for i = 1, #ratingMarkers do
        setPosition("markerLine" .. i, getProperty('progressionBox1.x') + 5, (getProperty('progressionBox1.y') + 26) + ((i * 22.5) - 22.5))
    end
    setPosition("tooLateText", getProperty('progressionBox1.x') + 5, getProperty('progressionBox1.y') + 5)
    setPosition("tooEarlyText", getProperty('progressionBox1.x') + 5, (getProperty('progressionBox1.y') + getProperty('progressionBox1.height')) - 24)

    -- Exit Box
    boxAnchoring("exitBox")
    setPosition("exitText", getProperty('exitBox1.x'), getProperty('exitBox1.y') + 14)
end

-- Functions only relevant to the results screen (usually just shortens code n stuff teehee)
function boxAnchoring(tag)
    local boxPoints = {
        {getProperty(tag .. '1.x'), getProperty(tag .. '1.y')},
        {getProperty(tag .. '1.x'), getProperty(tag .. '1.y')},
        {(getProperty(tag .. '1.x') + getProperty(tag .. '3.width')) - getProperty(tag .. '2.width'), getProperty(tag .. '1.y')},
        {getProperty(tag .. '1.x'), (getProperty(tag .. '1.y') + getProperty(tag .. '2.height')) - getProperty(tag .. '3.height')}
    }
    for i = 1, 4 do
        setProperty(tag .. (i + 1) .. '.x', boxPoints[i][1])
        setProperty(tag .. (i + 1) .. '.y', boxPoints[i][2])
    end
end
function setPosition(tag, x, y)
    setProperty(tag .. '.x', x)
    setProperty(tag .. '.y', y)
end


-- Options Menu Stuff
function createMainMenu()
    mainItems = {"Visibility", "Gameplay", "Colors", "Reset Settings", "Save & Exit"}
    curMain = 1

    luaSprite('mainBackground', 'menuDesat', 0, 0)
    screenCenter('mainBackground')
    setProperty('mainBackground.color', getColorFromHex(RGBToHex(getProperty('dad.healthColorArray'))))
    -- luaGraphic('mainBlend', 0, 0, screenWidth, screenHeight, RGBToHex(getProperty('dad.healthColorArray')))
    -- setBlendMode('mainBlend', 'SCREEN')

    for i = 1, #mainItems do
        luaText('mainText' ..i, 0, (i * 120) - 90, screenWidth, 80, WHITE, BLACK, 3, 'CENTER', mainItems[i])
    end

    changeMainMenu()
    descriptionStuff('main', true)
    setTextString("mainDescText", "Press [F1] during a song to revisit this menu.")

    luaText('scriptVersion', 0, screenHeight - 20, screenWidth, 20, WHITE, BLACK, 1, "LEFT", "Ramen's Results Screen v" .. scriptVersion)
end
function changeMainMenu(change)
    curMain = updateItemValue(curMain, change, #mainItems)
    for i = 1, #mainItems do
        setProperty('mainText' .. i .. '.alpha', 0.6)
        if curMain == i then
            setProperty('mainText' .. i .. '.alpha', 1)
        end
    end
end
function setMainMenuVisibility(visibility)
    for i = 1, #mainItems do
        setProperty('mainText' .. i .. '.visible', visibility)
    end
    setProperty('mainDescBox.visible', visibility)
    setProperty('mainDescText.visible', visibility)
end

function createVisibilityMenu()
    visibilityItems = { -- Display Name, Description, PlayerPrefs Tag
        {'Hit Timings',                 "The time a note is hit relative to the intended strum time.",      'showHitTimings'},
        {'N.P.S (Notes Per Second)',    "The amount of notes a player has hit within one second.",          'showNPS'},
        {'Combo',                       "The consecutive number of notes a player hits without missing.",   'showCombo'},
        {'Color Scheme Chosen',         "Text that displays the current color scheme chosen.",              'showColorScheme'},
        {'Lane Underlay',               "A graphic displayed beneath the strumline to aid in visibility.",  'showUnderlay'},
        {'Judgement Tracker',           "Text that displays the total of each note rating obtained.",       'showJudgements'},
        {'Results Screen',              "A screen that reviews the player's performance when a song ends.", 'showResults'}
    }
    curVisibility = 1

    for i = 1, #visibilityItems do
        luaBox('visibilityBox' .. i, 200, 10 + (i * 70), 60, 60 , BLACK, WHITE, 5, 60)
        luaGraphic('visibilityCheck' .. i, getProperty('visibilityBox' .. i ..'1.x') + 10, getProperty('visibilityBox' .. i ..'1.y') + 10, getProperty('visibilityBox' .. i ..'1.width') - 20, getProperty('visibilityBox' .. i ..'1.height') - 20, WHITE)
        setProperty('visibilityCheck' .. i .. '.visible', playerPrefs[visibilityItems[i][3]])
        luaText('visibilityText' .. i, (getProperty('visibilityBox' .. i ..'1.x') + getProperty('visibilityBox' .. i ..'1.width')) + 20, getProperty('visibilityBox' .. i ..'1.y') + 5, screenWidth, 50, WHITE, BLACK, 3, 'LEFT', 'Show ' .. visibilityItems[i][1])
    end

    descriptionStuff("visibility", true)
    changeVisibilityMenu()
end
function changeVisibilityMenu(change)
    curVisibility = updateItemValue(curVisibility, change, #visibilityItems)
    for i = 1, #visibilityItems do
        for j = 2, 5 do
            setProperty('visibilityBox' .. i .. j .. '.alpha', 0.6)
        end
        setProperty('visibilityCheck' .. i .. '.alpha', 0.6)
        setProperty('visibilityText' .. i .. '.alpha', 0.6)

        if curVisibility == i then
            for j = 2, 5 do
                setProperty('visibilityBox' .. i .. j .. '.alpha', 1)
            end
            setProperty('visibilityCheck' .. i .. '.alpha', 1)
            setProperty('visibilityText' .. i .. '.alpha', 1)
        end
        setTextString('visibilityDescText', visibilityItems[curVisibility][2])
    end
end
function removeVisibilityMenu()
    for i = 1, #visibilityItems do
        for j = 1, 5 do -- for the boxes
            removeLuaSprite('visibilityBox' .. i .. j, false)
        end
        removeLuaSprite('visibilityCheck' .. i, false)
        removeLuaText('visibilityText' .. i, false)
    end
    descriptionStuff("visibility", false)
end

function createGameplayMenu()
    gameplayItems = {
        {   -- Display Name, Description
            {'Underlays Shown',         'Choose the lane underlays to be displayed.'},
            {'Underlay Opacity',        'Choose the Opacity of the underlays displayed.'},
            {'Judgement Tracker Side',  'Choose which side of the screen the judgement tracker is on.'},
            {'Results Screen Presence', 'Choose when the Results Screen will be displayed.'}
        },
        {   -- Options Available
            {'PLAYER', 'OPPONENT', 'ALL'},
            {playerPrefs.underlayOpacity .. "%"},
            {'LEFT', 'RIGHT'},
            {'ALL', 'STORY MODE', 'FREEPLAY'}
        }
    }
    curGameplay = 1
    curGameplayOption = 1
    timeHeld = 0

    curUnderlayType = playerPrefs.underlayType
    curUnderlayOpacity = playerPrefs.underlayOpacity
    curJudgementType = playerPrefs.judgementType
    curResultsType = playerPrefs.resultsType

    for i = 1, #gameplayItems do
        luaText('gameplayText' .. i, 0, (i * 80) - 40, screenWidth, 60, WHITE, BLACK, 3, "CENTER", "< " .. gameplayItems[i][curGameplay][1] .. " >")
    end

    luaGraphic('demoBackground', 0, 205, 800, 380, "404040")
    screenCenter('demoBackground', "x")

    luaGraphic('opponentUnderlay', getProperty('demoBackground.x') + 30, getProperty('demoBackground.y'), 280,getProperty('demoBackground.height'), BLACK)
    luaGraphic('playerUnderlay', (getProperty('demoBackground.x') + getProperty('demoBackground.width')) - 310, getProperty('demoBackground.y'), 280, getProperty('demoBackground.height'), BLACK)

    for i = 1,4 do
        local strumDirections = {"LEFT", "DOWN", "UP", "RIGHT"}
        luaSprite('opponentStrums' .. i, 'noteSkins/NOTE_assets', getProperty('opponentUnderlay.x') + ((i * 70) - 70), getProperty('opponentUnderlay.y') + 30, true, {"arrow" .. strumDirections[i]})
        scaleObject('opponentStrums' .. i, 0.45, 0.45)
        luaSprite('playerStrums' .. i, 'noteSkins/NOTE_assets', getProperty('playerUnderlay.x') + ((i * 70) - 70), getProperty('playerUnderlay.y') + 30, true, {"arrow" .. strumDirections[i]})
        scaleObject('playerStrums' .. i, 0.45, 0.45)
    end

    luaBox('demoBorder', getProperty('demoBackground.x'), getProperty('demoBackground.y'), getProperty('demoBackground.width'), getProperty('demoBackground.height'), BLACK, WHITE, 10, 0)

    luaText('judgementText', getProperty('demoBackground.x') + 10, getProperty('demoBackground.y') + 180, getProperty('demoBackground.width') - 20, 16, WHITE, BLACK, 1, "CENTER", 'Sicks: 100\nGoods: 100\nBads: 100\nShits: 100\nMisses: 100')

    descriptionStuff("gameplay", true)
    changeGameplayMenu()
    changeGameplayOption()
end
function changeGameplayMenu(change)
    curGameplay = updateItemValue(curGameplay, change, #gameplayItems)
    for i = 1, #gameplayItems do
        setProperty('gameplayText' .. i .. '.alpha', 0.6)
        if curGameplay == i then
            setProperty('gameplayText' .. i .. '.alpha', 1)
        end
    end
end
function changeGameplayOption(change)
    curGameplayOption = updateItemValue(curGameplayOption, change, #gameplayItems[curGameplay])
    setTextString('gameplayText1', '< ' .. gameplayItems[1][curGameplayOption][1] .. ' >')

    if curGameplayOption == 1 then
        setTextString('gameplayText2', '< ' .. gameplayItems[2][curGameplayOption][curUnderlayType] .. ' >')
    elseif curGameplayOption == 2 then
        setTextString('gameplayText2', '< ' .. curUnderlayOpacity .. '% >')
    elseif curGameplayOption == 3 then
        setTextString('gameplayText2', '< ' .. gameplayItems[2][curGameplayOption][curJudgementType] .. ' >')
    elseif curGameplayOption == 4 then
        setTextString('gameplayText2', '< ' .. gameplayItems[2][curGameplayOption][curResultsType] .. ' >')
    end

    setTextString('gameplayDescText', gameplayItems[1][curGameplayOption][2])

    setProperty('opponentUnderlay.visible', playerPrefs.underlayType == 2 or playerPrefs.underlayType == 3)
    setProperty('playerUnderlay.visible', playerPrefs.underlayType == 1 or playerPrefs.underlayType == 3)

    setProperty('opponentUnderlay.alpha', playerPrefs.underlayOpacity / 100)
    setProperty('playerUnderlay.alpha', playerPrefs.underlayOpacity / 100)

    setTextAlignment('judgementText', gameplayItems[2][3][curJudgementType])
end
function changeUnderlayType(change)
    curUnderlayType = updateItemValue(curUnderlayType, change, #gameplayItems[2][curGameplayOption])
    playerPrefs.underlayType = curUnderlayType
end
function changeUnderlayOpacity(change)
    change = change or 0

    curUnderlayOpacity = curUnderlayOpacity + change
    if curUnderlayOpacity >= 100 then
        curUnderlayOpacity = 100
    elseif curUnderlayOpacity <= 1 then -- if you want it at 0 might as well turn it off bruh
        curUnderlayOpacity = 1
    end

    playerPrefs.underlayOpacity = curUnderlayOpacity
end
function changeJudgementType(change)
    curJudgementType = updateItemValue(curJudgementType, change, #gameplayItems[2][curGameplayOption])
    playerPrefs.judgementType = curJudgementType
end
function changeResultsPresence(change)
    curResultsType = updateItemValue(curResultsType, change, #gameplayItems[2][curGameplayOption])
    playerPrefs.resultsType = curResultsType
end
function removeGameplayMenu()
    for i = 1, #gameplayItems do
        removeLuaText('gameplayText' .. i, false)
        removeLuaSprite('demoBackground', false)
    end
    for i = 1, 5 do -- for the boxes
        removeLuaSprite('demoBorder' .. i, false)
    end
    removeLuaSprite('opponentUnderlay', false)
    removeLuaSprite('playerUnderlay', false)
    for i = 1,4 do -- for the strums
        removeLuaSprite('opponentStrums' .. i, false)
        removeLuaSprite('playerStrums' .. i, false)
    end

    removeLuaText('judgementText', false)
    descriptionStuff("gameplay", false)
end

function createColorsMenu()
    ratings = {"Sicks", "Goods", "Bads", "Shits", "Misses"}
    curColors = playerPrefs.colorPalette

    luaText('colorsText', 0, 40, screenWidth, 70, WHITE, BLACK, 3, "CENTER", "< " .. colorPalettes[curColors][1] .. " >")

    luaGraphic('colorPaletteBackground', 0, 0, 610, 400, WHITE)
    screenCenter('colorPaletteBackground')

    for i = 1, #ratings do
        luaBox('ratingBox' .. i, (getProperty('colorPaletteBackground.x') + 10) + ((i * 120) - 120), getProperty('colorPaletteBackground.y') + 10, 110, getProperty('colorPaletteBackground.height') - 20, WHITE, BLACK, 5, 100)
        setProperty('ratingBox' .. i .. '1.color', getColorFromHex(colorPalettes[curColors][3][i]))
        luaText('ratingText' .. i, getProperty('ratingBox' .. i .. '1.x'), getProperty('ratingBox' .. i .. '1.y') + 345, getProperty('ratingBox' .. i .. '1.width'), 26, WHITE, BLACK, 1, "CENTER", ratings[i])
    end
    luaBox('ratingsDim', getProperty('colorPaletteBackground.x'), (getProperty('colorPaletteBackground.y') + getProperty('colorPaletteBackground.height')) - 60, getProperty('colorPaletteBackground.width'), 60, BLACK, WHITE, 10, 60)

    descriptionStuff("colors", true)
    changeColorsMenu()
end
function changeColorsMenu(change)
    curColors = updateItemValue(curColors, change, #colorPalettes)
    playerPrefs.colorPalette = curColors

    for i = 1, #ratings do
        setProperty('ratingBox' .. i .. '1.color', getColorFromHex(colorPalettes[curColors][3][i]))
    end
    setTextString('colorsText', '< ' ..colorPalettes[playerPrefs.colorPalette][1].. ' >')
    setTextString('colorsDescText', colorPalettes[playerPrefs.colorPalette][2])
end
function removeColorsMenu()
    removeLuaText('colorsText', false)
    removeLuaSprite('colorPaletteBackground', false)
    for i = 1, #ratings do
        removeLuaText('ratingText' .. i, false)
        for j = 1, 5 do
            removeLuaSprite('ratingBox' .. i .. j, false)
            removeLuaSprite('ratingsDim' .. j, false)
        end
    end
    descriptionStuff("colors", false)
end

function createResetMenu()
    resetItems = {"No", "Yes"}
    curReset = 1

    for i = 1, #resetItems do
        luaText('resetText' .. i, 400 + ((i * 300) - 300), 0, 150, 80, WHITE, BLACK, 3, "CENTER", resetItems[i])
        screenCenter('resetText' .. i, 'y')
    end

    descriptionStuff("reset", true)
    setTextString('resetDescText', "Are you sure you'd like to reset all settings?")

    changeResetMenu()
end
function changeResetMenu(change)
    curReset = updateItemValue(curReset, change, #resetItems)

    for i = 1, #resetItems do
        setProperty('resetText' .. i .. '.alpha', 0.6)
        if curReset == i then
            setProperty('resetText' .. i .. '.alpha', 1)
        end
    end
end
function removeResetMenu()
    for i = 1, #resetItems do
        removeLuaText("resetText" .. i, false)
    end
    descriptionStuff("reset", false)
end

-- Functions only relevant to the options screen (usually just shortens code n stuff teehee)
function keyPressHandler(key,func,change)
    if keyboardJustPressed(key) then
        playSound('scrollMenu', 0.4)
        func(change)
    end
end
function descriptionStuff(tag, create)
    if create then
        luaGraphic(tag .. 'DescBox', 0, screenHeight - 100, 1100, 80, BLACK)
        screenCenter(tag .. 'DescBox', 'x')
        setProperty(tag .. 'DescBox.alpha', 0.4)
        luaText(tag .. 'DescText', getProperty(tag .. 'DescBox.x'), getProperty(tag .. 'DescBox.y') + 24, getProperty(tag .. 'DescBox.width'), 26, WHITE, BLACK, 2, "CENTER", "Sample Text")
    elseif not create then
        removeLuaSprite(tag .. 'DescBox', false)
        removeLuaText(tag .. 'DescText', false)
    end
end
function updateItemValue(item, change, maxValue)
    change = change or 0
    item = item + change
    if item > maxValue then
        item = 1
    elseif item < 1 then
        item = maxValue
    end
    return item
end


--savin' and loadin'
function loadPlayerPrefs()
    initSaveData('RamensResultsScreen')
    for k, v in pairs(playerPrefs) do
        playerPrefs[k] = getDataFromSave('RamensResultsScreen', k, v)
    end
end
function savePlayerPrefs()
    for k, v in pairs(playerPrefs) do
        setDataFromSave('RamensResultsScreen', k, v)
    end
    flushSaveData('RamensResultsScreen')
    -- debugPrint('Player Preferences Saved!')
end
function resetPlayerPrefs()
    local defaultPrefs = { -- probably a better way to grab the original values
        enterOptions =      true,

        showHitTimings =    true,
        showNPS =           true,
        showCombo =         true,
        showColorScheme =   true,
        showUnderlay =      true,
        showJudgements =    true,
        showResults =       true,

        underlayType =      1,
        underlayOpacity =   70,
        judgementType =     1,
        resultsType =       1,
        colorPalette =      1
    }
    for k, v in pairs(defaultPrefs) do
        setDataFromSave('RamensResultsScreen', k, v)
    end
    flushSaveData('RamensResultsScreen')
    -- debugPrint('Player Preferences Reset!')
end


-- Just random functions that are useful to me
function luaGraphic(tag, x, y, w, h, color, camera)
    camera = camera == nil and 'other' or camera
	makeLuaSprite(tag, nil, x, y)
	makeGraphic(tag, w, h, color)
	setObjectCamera(tag, camera)
	addLuaSprite(tag)
end
function luaSprite(tag, image, x, y, isAnimated, animPrefix)
    isAnimated = isAnimated == nil and false or isAnimated
    if not isAnimated then
	    makeLuaSprite(tag, image, x, y)
    else
        makeAnimatedLuaSprite(tag, image, x, y)
        for i = 1, #animPrefix do
            addAnimationByPrefix(tag, animPrefix[i], animPrefix[i], 1, false)
        end
    end
    setObjectCamera(tag, 'other')
	addLuaSprite(tag)
end
function luaText(tag, x, y, w, size, fillColor, borderColor, thickness, alignment, text, camera)
	camera = camera == nil and 'other' or camera
    makeLuaText(tag, text, w, x, y)
	setTextSize(tag, size)
	setTextColor(tag, fillColor)
	setTextBorder(tag, thickness, borderColor)
	setTextAlignment(tag, alignment)
	setObjectCamera(tag, camera)
	addLuaText(tag)
end
function RGBToHex(colorArray)
    local hexcode = ''
    for i = 1, #colorArray do
        value1 = math.floor(colorArray[i] / 16)
        value2 = ((colorArray[i] / 16) % 1) * 16
        hexcode = hexcode .. (value1 < 10 and tostring(value1) or tostring(string.char((65 + value1) - 10)))
        hexcode = hexcode .. (value2 < 10 and tostring(value2) or tostring(string.char((65 + value2) - 10)))
    end
    return hexcode
end
function round(float, decimalPlaces)
	local mult = 10^(decimalPlaces or 0)
	return math.floor(float * mult + 0.5) / mult
end
function luaBox(tag, x, y, w, h, fillColor, borderColor, thickness, transparency)
    luaGraphic(tag .. '1', x, y, w, h, fillColor)
    setProperty(tag .. '1.alpha', transparency / 100)
    local boxPoints = {
        {getProperty(tag .. '1.x'), getProperty(tag .. '1.y'), thickness, h},-- left
        {getProperty(tag .. '1.x'), getProperty(tag .. '1.y'), w, thickness},-- top
        {(getProperty(tag .. '1.x') + w) - thickness, getProperty(tag .. '1.y'), thickness, h},-- right
        {getProperty(tag .. '1.x'), (getProperty(tag .. '1.y') + h) - thickness, w, thickness} -- bottom
    }
    for i = 1,4 do
        luaGraphic(tag .. tostring(i + 1), boxPoints[i][1],  boxPoints[i][2], boxPoints[i][3],  boxPoints[i][4], borderColor)
    end
end