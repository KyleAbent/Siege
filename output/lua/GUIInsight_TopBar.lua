-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIInsight_TopBar.lua
--
-- Created by: Jon 'Huze' Hughes (jon@jhuze.com)
--
-- Spectator: Displays team names and gametime
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

class "GUIInsight_TopBar" (GUIScript)

local isVisible

local kBackgroundTexture = PrecacheAsset("ui/topbar.dds")
local kIconTextureAlien = PrecacheAsset("ui/alien_commander_textures.dds")
local kIconTextureMarine = PrecacheAsset("ui/marine_commander_textures.dds")
local kTeamResourceIconCoords = {192, 363, 240, 411}
local kResourceTowerIconCoords = {240, 363, 280, 411}
local kBiomassIconCoords = GetTextureCoordinatesForIcon(kTechId.Biomass)
local kBuildMenuTexture = PrecacheAsset("ui/buildmenu.dds")

local kTimeFontName = Fonts.kAgencyFB_Medium
local kMarineFontName = Fonts.kAgencyFB_Medium
local kAlienFontName = Fonts.kAgencyFB_Medium

local kInfoFontName = Fonts.kAgencyFB_Small

local kIconSize
local kButtonSize
local kButtonOffset

local background
local gameTime

local scoresBackground
local teamsSwapButton
local marinePlusButton
local marineMinusButton
local alienPlusButton
local alienMinusButton

local marineTeamScore
local alienTeamScore

local marineNameBackground
local marineTeamName
local marineResources
local marineExtractors

local alienNameBackground
local alienTeamName
local alienResources
local alienHarvesters
local alienBiomass


-- GUIInsight_TopBar.kPersonalTimeIcon = { Width = 0, Height = 0, X = 0, Y = 0 }
-- GUIInsight_TopBar.kPersonalTimeIcon.Width = 32
-- GUIInsight_TopBar.kPersonalTimeIcon.Height = 64
--
-- --GUIInsight_TopBar.kPersonalTimeIconSize = Vector(GUIInsight_TopBar.kPersonalResourceIcon.Width, GUIInsight_TopBar.kPersonalResourceIcon.Height, 0)
-- --GUIInsight_TopBar.kPersonalTimeIconSizeBig = Vector(GUIInsight_TopBar.kPersonalResourceIcon.Width, GUIInsight_TopBar.kPersonalResourceIcon.Height, 0) * 1.1
--
--
-- GUIInsight_TopBar.kPersonalTimeIconPos = Vector(30,-4,0)
-- GUIInsight_TopBar.kPersonalTimeTextPos = Vector(100,4,0)
-- GUIInsight_TopBar.kTimeDescriptionPos = Vector(110,4,0)
-- GUIInsight_TopBar.kTimeGainedTextPos = Vector(90,-6,0)
--
-- GUIInsight_TopBar.kFontSizePersonalTime = 20
-- GUIInsight_TopBar.kFontSizePersonalTimeBig = 20
--
--
-- GUIInsight_TopBar.kFrontTimeBackgroundSize = Vector(180, 58, 0)
-- GUIInsight_TopBar.kFrontTimeBackgroundPos = Vector(-300, -175, 0)
--
-- GUIInsight_TopBar.kSideTimeBackgroundSize = Vector(180, 58, 0)
-- GUIInsight_TopBar.kSideTimeBackgroundPos = Vector(-100, -175, 0)
--
--
-- GUIInsight_TopBar.kSiegeTimeBackgroundSize = Vector(180, 58, 0)
-- GUIInsight_TopBar.kSiegeTimeBackgroundPos = Vector(100, -175, 0)
--
-- /*
-- GUIInsight_TopBar.kPowerBackgroundSize = Vector(180, 58, 0)
-- GUIInsight_TopBar.kPowerBackgroundPos = Vector(300, -175, 0)
-- */
--
-- GUIInsight_TopBar.kTextFontName = Fonts.kAgencyFB_Small






local function CreateIconTextItem(team, parent, position, texture, coords)

    local background = GUIManager:CreateGraphicItem()
    if team == kTeam1Index then
        background:SetAnchor(GUIItem.Left, GUIItem.Top)
    else
        background:SetAnchor(GUIItem.Right, GUIItem.Top)
    end
    background:SetColor(Color(0,0,0,0))
    background:SetSize(kIconSize)
    parent:AddChild(background)

    local icon = GUIManager:CreateGraphicItem()
    icon:SetSize(kIconSize)
    icon:SetAnchor(GUIItem.Left, GUIItem.Top)
    icon:SetPosition(position)
    icon:SetTexture(texture)
    icon:SetTexturePixelCoordinates(GUIUnpackCoords(coords))
    background:AddChild(icon)
    
    local value = GUIManager:CreateTextItem()
    value:SetFontName(kInfoFontName)
    value:SetScale(GetScaledVector())
    value:SetAnchor(GUIItem.Left, GUIItem.Center)
    value:SetTextAlignmentX(GUIItem.Align_Min)
    value:SetTextAlignmentY(GUIItem.Align_Center)
    value:SetColor(Color(1, 1, 1, 1))
    value:SetPosition(position + Vector(kIconSize.x + GUIScale(5), 0, 0))
    GUIMakeFontScale(value)
    background:AddChild(value)
    
    return value
    
end

local function CreateButtonItem(parent, position, color)

    local button = GUIManager:CreateGraphicItem()
    button:SetSize(kButtonSize)
    button:SetPosition(position - kButtonSize/2)
    button:SetColor(color)
    button:SetIsVisible(false)
    parent:AddChild(button)
    
    return button
    
end

local function GetTeamInfoStrings(teamInfo)

    local teamRes = teamInfo:GetTeamResources()
    local numRTs = teamInfo:GetNumResourceTowers()
    local constructingRTs = teamInfo:GetNumCapturedResPoints() - numRTs
    
    local resString = tostring(teamRes)
    local rtString = tostring(numRTs)
    if constructingRTs > 0 then
        rtString = rtString .. string.format(" (%d)", constructingRTs)
    end

    return resString, rtString
    
end

local function GetBioMassString(teamInfo)

    if teamInfo.GetBioMassLevel then
        return string.format("%d / 12", teamInfo:GetBioMassLevel())
    end
    
    return ""

end


function GUIInsight_TopBar:Initialize()

    kIconSize = GUIScale(Vector(32, 32, 0))
    kButtonSize = GUIScale(Vector(8, 8, 0))
    kButtonOffset = GUIScale(Vector(0,20,0))
    
    isVisible = true
        
    local texSize = GUIScale(Vector(512,57,0))
    local texCoord = {0,0,512,57}
    local texPos = Vector(-texSize.x/2,0,0)
    background = GUIManager:CreateGraphicItem()
    background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    background:SetTexture(kBackgroundTexture)
    background:SetTexturePixelCoordinates(GUIUnpackCoords(texCoord))
    background:SetSize(texSize)
    background:SetPosition(texPos)
    background:SetLayer(kGUILayerInsight)
    
    gameTime = GUIManager:CreateTextItem()
    gameTime:SetFontName(kTimeFontName)
    gameTime:SetScale(GetScaledVector())
    gameTime:SetAnchor(GUIItem.Middle, GUIItem.Top)
    gameTime:SetPosition(GUIScale(Vector(0, 5, 0)))
    gameTime:SetTextAlignmentX(GUIItem.Align_Center)
    gameTime:SetTextAlignmentY(GUIItem.Align_Min)
    gameTime:SetColor(Color(1, 1, 1, 1))
    gameTime:SetText("")
    GUIMakeFontScale(gameTime)
    background:AddChild(gameTime)
    
    local scoresTexSize = GUIScale(Vector(512,71,0))
    local scoresTexCoord = {0,57,512,128}    
    
    scoresBackground = GUIManager:CreateGraphicItem()
    scoresBackground:SetTexture(kBackgroundTexture)
    scoresBackground:SetTexturePixelCoordinates(GUIUnpackCoords(scoresTexCoord))
    scoresBackground:SetSize(scoresTexSize)
    scoresBackground:SetAnchor(GUIItem.Middle, GUIItem.Top)
    scoresBackground:SetPosition(Vector(-scoresTexSize.x/2, texSize.y - GUIScale(15), 0))
    scoresBackground:SetIsVisible(false)
    background:AddChild(scoresBackground)
    
    marineTeamScore = GUIManager:CreateTextItem()
    marineTeamScore:SetFontName(kTimeFontName)
    marineTeamScore:SetScale(GetScaledVector() * 1.2)
    marineTeamScore:SetAnchor(GUIItem.Middle, GUIItem.Center)
    marineTeamScore:SetTextAlignmentX(GUIItem.Align_Center)
    marineTeamScore:SetTextAlignmentY(GUIItem.Align_Center)
    marineTeamScore:SetPosition(GUIScale(Vector(-30, -5, 0)))
    marineTeamScore:SetColor(Color(1, 1, 1, 1))
    GUIMakeFontScale(marineTeamScore)
    scoresBackground:AddChild(marineTeamScore)
    
    alienTeamScore = GUIManager:CreateTextItem()
    alienTeamScore:SetFontName(kTimeFontName)
    alienTeamScore:SetScale(GetScaledVector() * 1.2)
    alienTeamScore:SetAnchor(GUIItem.Middle, GUIItem.Center)
    alienTeamScore:SetTextAlignmentX(GUIItem.Align_Center)
    alienTeamScore:SetTextAlignmentY(GUIItem.Align_Center)
    alienTeamScore:SetPosition(GUIScale(Vector(30, -5, 0)))
    alienTeamScore:SetColor(Color(1, 1, 1, 1))
    GUIMakeFontScale(alienTeamScore)
    scoresBackground:AddChild(alienTeamScore)
    
    marineTeamName = GUIManager:CreateTextItem()
    marineTeamName:SetFontName(kMarineFontName)
    marineTeamName:SetScale(GetScaledVector())
    marineTeamName:SetAnchor(GUIItem.Middle, GUIItem.Center)
    marineTeamName:SetTextAlignmentX(GUIItem.Align_Max)
    marineTeamName:SetTextAlignmentY(GUIItem.Align_Center)
    marineTeamName:SetPosition(GUIScale(Vector(-60, -7, 0)))
    marineTeamName:SetColor(Color(1, 1, 1, 1))
    GUIMakeFontScale(marineTeamName)
    scoresBackground:AddChild(marineTeamName)
    
    alienTeamName = GUIManager:CreateTextItem()
    alienTeamName:SetFontName(kAlienFontName)
    alienTeamName:SetScale(GetScaledVector())
    alienTeamName:SetAnchor(GUIItem.Middle, GUIItem.Center)
    alienTeamName:SetTextAlignmentX(GUIItem.Align_Min)
    alienTeamName:SetTextAlignmentY(GUIItem.Align_Center)
    alienTeamName:SetPosition(GUIScale(Vector(60, -7, 0)))
    alienTeamName:SetColor(Color(1, 1, 1, 1))
    GUIMakeFontScale(alienTeamName)
    scoresBackground:AddChild(alienTeamName)
    
    local yoffset = GUIScale(4)
    marineResources = CreateIconTextItem(kTeam1Index, background, Vector(GUIScale(130),yoffset,0), kIconTextureMarine, kTeamResourceIconCoords)
    marineExtractors = CreateIconTextItem(kTeam1Index, background, Vector(GUIScale(50),yoffset,0), kIconTextureMarine, kResourceTowerIconCoords)

    alienResources = CreateIconTextItem(kTeam2Index, background, Vector(-GUIScale(195),yoffset,0), kIconTextureAlien, kTeamResourceIconCoords)
    alienHarvesters = CreateIconTextItem(kTeam2Index, background, Vector(-GUIScale(115),yoffset,0), kIconTextureAlien, kResourceTowerIconCoords)
    alienBiomass = CreateIconTextItem(kTeam2Index, background, Vector(-GUIScale(5),yoffset,0), kBuildMenuTexture, kBiomassIconCoords)
    
    teamsSwapButton = CreateButtonItem(scoresBackground, kButtonOffset, Color(1,1,1,0.5))
    teamsSwapButton:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    marinePlusButton = CreateButtonItem(scoresBackground, kButtonOffset + Vector(-kButtonSize.x,-kButtonSize.y,0), Color(0,1,0,0.5))
    marinePlusButton:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    alienPlusButton = CreateButtonItem(scoresBackground, kButtonOffset + Vector(kButtonSize.x,-kButtonSize.y,0), Color(0,1,0,0.5))
    alienPlusButton:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    marineMinusButton = CreateButtonItem(scoresBackground, kButtonOffset + Vector(-kButtonSize.x,kButtonSize.y,0), Color(1,0,0,0.5))
    marineMinusButton:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    alienMinusButton = CreateButtonItem(scoresBackground, kButtonOffset + Vector(kButtonSize.x,kButtonSize.y,0), Color(1,0,0,0.5))
    alienMinusButton:SetAnchor(GUIItem.Middle, GUIItem.Center)
        
    self:SetTeams(InsightUI_GetTeam1Name(), InsightUI_GetTeam2Name())
    self:SetScore(InsightUI_GetTeam1Score(), InsightUI_GetTeam2Score())



--       self.frame = GUIManager:CreateGraphicItem()
--       --  self.frame:SetIsScaling(false)
--         self.frame:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
--         self.frame:SetPosition(Vector(0, 0, 0))
--         self.frame:SetIsVisible(true)
--         self.frame:SetLayer(kGUILayerPlayerHUDBackground)
--         self.frame:SetColor(Color(1, 1, 1, 0))
--
--         local style = kGUILayerPlayerHUDForeground1
--         --self.frame = CreateAvocaDisplay(self, kGUILayerPlayerHUDForeground3, self.doorTimersBackground, style, kTeam2Index)
--
--
--         self.frontBackground = GUIManager:CreateGraphicItem()
--         self.frontBackground:SetAnchor(GUIItem.Center, GUIItem.Bottom)
--         --self.frontBackground:SetTexture(kBackgroundTextures[style.textureSet])
--         self.frontBackground:SetPosition(GUIInsight_TopBar.kFrontTimeBackgroundPos)
--         self.frame:AddChild(self.frontBackground)
--
--         self.siegeBackground = GUIManager:CreateGraphicItem()
--         self.siegeBackground:SetAnchor(GUIItem.Center, GUIItem.Bottom)
--         --self.siegeBackground:SetTexture(kBackgroundTextures[style.textureSet])
--         self.siegeBackground:SetPosition(GUIInsight_TopBar.kSiegeTimeBackgroundPos)
--         self.frame:AddChild(self.siegeBackground)
--
--         self.sideBackground = GUIManager:CreateGraphicItem()
--         self.sideBackground:SetAnchor(GUIItem.Center, GUIItem.Bottom)
--         --self.sideBackground:SetTexture(kBackgroundTextures[style.textureSet])
--         self.sideBackground:SetPosition(GUIInsight_TopBar.kSideTimeBackgroundPos)
--         self.frame:AddChild(self.sideBackground)
--
--         /*
--         self.powerBackground =  GUIManager:CreateGraphicItem()
--         self.powerBackground:SetAnchor(GUIItem.Center, GUIItem.Bottom)
--         --self.powerBackground:SetTexture(kBackgroundTextures[style.textureSet])
--          self.powerBackground:SetPosition(GUIInsight_TopBar.kPowerBackgroundPos)
--         self.frame:AddChild(self.powerBackground)
--         */
--
--         self.frontDoor = GUIManager:CreateTextItem()
--         self.frontDoor:SetAnchor(GUIItem.Left, GUIItem.Center)
--         self.frontDoor:SetTextAlignmentX(GUIItem.Align_Max)
--         self.frontDoor:SetTextAlignmentY(GUIItem.Align_Center)
--         --self.frontDoor:SetColor(style.textColor)
--         self.frontDoor:SetFontIsBold(true)
--         self.frontDoor:SetFontName(GUIInsight_TopBar.kTextFontName)
--         self.frontBackground:AddChild(self.frontDoor)
--
--         self.siegeDoor = GUIManager:CreateTextItem()
--         self.siegeDoor:SetAnchor(GUIItem.Left, GUIItem.Center)
--         self.siegeDoor:SetTextAlignmentX(GUIItem.Align_Max)
--         self.siegeDoor:SetTextAlignmentY(GUIItem.Align_Center)
--         --self.siegeDoor:SetColor(style.textColor)
--         self.siegeDoor:SetFontIsBold(true)
--         self.siegeDoor:SetFontName(GUIInsight_TopBar.kTextFontName)
--         GUIMakeFontScale(self.siegeDoor)
--         self.siegeBackground:AddChild(self.siegeDoor)
--
--         self.sideDoor = GUIManager:CreateTextItem()
--         self.sideDoor:SetAnchor(GUIItem.Left, GUIItem.Center)
--         self.sideDoor:SetTextAlignmentX(GUIItem.Align_Max)
--         self.sideDoor:SetTextAlignmentY(GUIItem.Align_Center)
--         --self.sideDoor:SetColor(style.textColor)
--         self.sideDoor:SetFontIsBold(true)
--         self.sideDoor:SetFontName(GUIInsight_TopBar.kTextFontName)
--         self.sideBackground:AddChild(self.sideDoor)
--
--         /*
--         self.powerTxt = GUIManager:CreateTextItem()
--         self.powerTxt:SetAnchor(GUIItem.Left, GUIItem.Center)
--         self.powerTxt:SetTextAlignmentX(GUIItem.Align_Max)
--         self.powerTxt:SetTextAlignmentY(GUIItem.Align_Center)
--         --self.powerTxt:SetColor(style.textColor)
--         self.powerTxt:SetFontIsBold(true)
--         self.powerTxt:SetFontName(GUIInsight_TopBar.kTextFontName)
--         self.powerBackground:AddChild(self.powerTxt)
--         */

        
end


function GUIInsight_TopBar:Uninitialize()

    GUI.DestroyItem(background)
    background = nil

end

function GUIInsight_TopBar:OnResolutionChanged(oldX, oldY, newX, newY)

    self:Uninitialize()
    
    self:Initialize()

end

function GUIInsight_TopBar:SetIsVisible(bool)

    isVisible = bool
    background:SetIsVisible(bool)

end

function GUIInsight_TopBar:SendKeyEvent(key, down)

    if isVisible then
        local cursor = MouseTracker_GetCursorPos()
        local inBackground, posX, posY = GUIItemContainsPoint(scoresBackground, cursor.x, cursor.y)
        if inBackground then
        
            if key == InputKey.MouseButton0 and down then

                local inSwap, posX, posY = GUIItemContainsPoint(teamsSwapButton, cursor.x, cursor.y)
                if inSwap then
                    Shared.ConsoleCommand("teams swap")
                end
                local inMPlus, posX, posY = GUIItemContainsPoint(marinePlusButton, cursor.x, cursor.y)
                if inMPlus then
                    Shared.ConsoleCommand("score1 +")
                end
                local inMMinus, posX, posY = GUIItemContainsPoint(marineMinusButton, cursor.x, cursor.y)
                if inMMinus then
                    Shared.ConsoleCommand("score1 -")
                end
                local inAPlus, posX, posY = GUIItemContainsPoint(alienPlusButton, cursor.x, cursor.y)
                if inAPlus then
                    Shared.ConsoleCommand("score2 +")
                end
                local inAMinus, posX, posY = GUIItemContainsPoint(alienMinusButton, cursor.x, cursor.y)
                if inAMinus then
                    Shared.ConsoleCommand("score2 -")
                end
                --Shared.ConsoleCommand("teams reset")
                return true
                
            end
            
        end    
    
    end

    return false

end

function GUIInsight_TopBar:Update(deltaTime)
    
    PROFILE("GUIInsight_TopBar:Update")
    
    local startTime = PlayerUI_GetGameStartTime()
        
    if startTime ~= 0 then
        startTime = math.floor(Shared.GetTime()) - PlayerUI_GetGameStartTime()
    end

    local seconds = math.round(startTime)
    local minutes = math.floor(seconds / 60)
    seconds = seconds - minutes * 60
    
    local gameTimeText = string.format("%d:%02d", minutes, seconds)

    gameTime:SetText(gameTimeText)
    
    local resString
    local rtString
    
    local marineTeamInfo = GetTeamInfoEntity(kTeam1Index)
    if marineTeamInfo then
    
        resString, rtString = GetTeamInfoStrings(marineTeamInfo)
        marineResources:SetText(resString)
        marineExtractors:SetText(rtString)
        
    end

    local alienTeamInfo = GetTeamInfoEntity(kTeam2Index)
    if alienTeamInfo then
    
        resString, rtString = GetTeamInfoStrings(alienTeamInfo)
        alienResources:SetText(resString)
        alienHarvesters:SetText(rtString)
        alienBiomass:SetText(GetBioMassString(alienTeamInfo))
        
    end

    local cursor = MouseTracker_GetCursorPos()
    local inBackground, posX, posY = GUIItemContainsPoint(scoresBackground, cursor.x, cursor.y)
    teamsSwapButton:SetIsVisible(inBackground)
    marinePlusButton:SetIsVisible(inBackground)
    marineMinusButton:SetIsVisible(inBackground)
    alienPlusButton:SetIsVisible(inBackground)
    alienMinusButton:SetIsVisible(inBackground)




--       --Print("uhh")
--      local gLength =  PlayerUI_GetGameLengthTime()
--      local fLength = PlayerUI_GetFrontLength()
--      local sLength = PlayerUI_GetSiegeLength()
--      local ssLength = PlayerUI_GetSideLength()
--      --local adjustment = PlayerUI_GetDynamicLength()
--
--     local frontRemain = Clamp(fLength - gLength, 0, fLength)
--     local Frontminutes = math.floor( frontRemain / 60 )
--     local Frontseconds = math.floor( frontRemain - Frontminutes * 60 )
--
--     if frontRemain > 0 then
--         self.frontDoor:SetText(string.format("Front: %s:%s", Frontminutes, Frontseconds))
--     else
--         self.frontDoor:SetText(string.format("Front: OPEN"))
--     end
--
--     local siegeRemain = Clamp(sLength - gLength, 0, sLength)
--     local Siegeminutes = math.floor( siegeRemain / 60 )
--     local Siegeseconds = math.floor( siegeRemain - Siegeminutes * 60 )
--
--     if siegeRemain > 0 then
--         self.siegeDoor:SetText(string.format("Siege: %s:%s", Siegeminutes, Siegeseconds))
--     else
--         self.siegeDoor:SetText(string.format("Siege: OPEN"))
--     end
--
--     if ssLength > 0 then
--         local sideRemain = Clamp(ssLength - gLength, 0, ssLength)
--         local Sideminutes = math.floor( sideRemain / 60 )
--         local Sideseconds = math.floor( sideRemain - Sideminutes * 60 )
--         --self.sideDoor:SetVisible(true)
--         self.sideDoor:SetText(string.format("Side: %s:%s", Sideminutes, Sideseconds))
--     else
--         --self.sideDoor:SetVisible(false)
--         self.sideDoor:SetText(string.format("Side: OPEN"))
--     --fallacy
--     end




end

function GUIInsight_TopBar:SetTeams(team1Name, team2Name)

    if team1Name == nil and team2Name == nil then
    
        scoresBackground:SetIsVisible(false)
            
    else

        scoresBackground:SetIsVisible(true)
        if team1Name == nil then
            alienTeamName:SetText(team2Name)
        elseif team2Name == nil then
            marineTeamName:SetText(team1Name)
        else        
            marineTeamName:SetText(team1Name)
            alienTeamName:SetText(team2Name)
        end
        
    end
    
end

function GUIInsight_TopBar:SetScore(team1Score, team2Score)

    marineTeamScore:SetText(tostring(team1Score))
    alienTeamScore:SetText(tostring(team2Score))

end