-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\GUIAlienSpectatorHUD.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- Displays how much time is left until the alien spawns.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local timeWaveSpawnEnds = 0
local function OnSetTimeWaveSpawnEnds(message)
    timeWaveSpawnEnds = message.time
end
Client.HookNetworkMessage("SetTimeWaveSpawnEnds", OnSetTimeWaveSpawnEnds)

local function AlienUI_GetWaveSpawnTime()

    if timeWaveSpawnEnds > 0 then
        return timeWaveSpawnEnds - Shared.GetTime()
    end
    
    return 0
    
end

class 'GUIAlienSpectatorHUD' (GUIScript)

local kFontScale
local kTextFontName = Fonts.kAgencyFB_Large
local kFontColor = Color(1, 1, 1, 1)

local kEggSize

local kPadding
local kEggTopOffset

local kNoEggsColor = Color(1, 0, 0, 1)
local kWhite = Color(1, 1, 1, 1)

local kEggTexture = "ui/Egg.dds"

local kSpawnInOffset

local function UpdateItemsGUIScale(self)
    kFontScale = GetScaledVector()
    kEggSize = GUIScale(Vector(192, 96, 0) * 0.5)
    kPadding = GUIScale(32)
    kEggTopOffset = GUIScale(128)
    kSpawnInOffset = GUIScale(Vector(0, -125, 0))

    self.spawnText:SetPosition(kSpawnInOffset)
    self.spawnText:SetFontName(kTextFontName)
    self.spawnText:SetScale(kFontScale)
    GUIMakeFontScale(self.spawnText)
    
    self.eggIcon:SetPosition(Vector(-kEggSize.x * 0.75 - kPadding * 0.5, kEggTopOffset, 0))
    self.eggIcon:SetSize(kEggSize)
    
    self.eggCount:SetScale(kFontScale)
    self.eggCount:SetFontName(kTextFontName)
    GUIMakeFontScale(self.eggCount)
    self.eggCount:SetPosition(Vector(kPadding * 0.5, 0, 0))
end

function GUIAlienSpectatorHUD:OnResolutionChanged(oldX, oldY, newX, newY)
    UpdateItemsGUIScale(self)
end

function GUIAlienSpectatorHUD:Initialize()

    self.spawnText = GUIManager:CreateTextItem()
    self.spawnText:SetFontName(kTextFontName)
    self.spawnText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.spawnText:SetTextAlignmentX(GUIItem.Align_Center)
    self.spawnText:SetTextAlignmentY(GUIItem.Align_Center)
    self.spawnText:SetColor(kFontColor)
    
    self.eggIcon = GUIManager:CreateGraphicItem()
    self.eggIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.eggIcon:SetTexture(kEggTexture)
    self.eggIcon:SetIsVisible(false) -- to prevent 1-frame pop-in
    
    self.eggCount = GUIManager:CreateTextItem()
    self.eggCount:SetFontName(kTextFontName)
    self.eggCount:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.eggCount:SetTextAlignmentX(GUIItem.Align_Min)
    self.eggCount:SetTextAlignmentY(GUIItem.Align_Center)
    self.eggCount:SetColor(kFontColor)
    
    self.eggIcon:AddChild(self.eggCount)
    
    UpdateItemsGUIScale(self)
    
    self.visible = true
    
end

function GUIAlienSpectatorHUD:SetIsVisible(state)
    
    self.visible = state
    self:Update(0)
    
end

function GUIAlienSpectatorHUD:GetIsVisible()
    
    return self.visible
    
end

function GUIAlienSpectatorHUD:Uninitialize()

    assert(self.spawnText)
    
    GUI.DestroyItem(self.spawnText)
    self.spawnText = nil
    
    GUI.DestroyItem(self.eggIcon)
    self.eggIcon = nil
    eggCount = nil
    
end

function GUIAlienSpectatorHUD:Update(deltaTime)

    PROFILE("GUIAlienSpectatorHUD:Update")
    
    local waitingForTeamBalance = PlayerUI_GetIsWaitingForTeamBalance()

    local isVisible = self.visible and not waitingForTeamBalance and GetPlayerIsSpawning()
    self.spawnText:SetIsVisible(isVisible)
    self.eggIcon:SetIsVisible(isVisible and not StatsUIVisible)
    
    if isVisible then
    
        local timeToWave = math.max(0, math.floor(AlienUI_GetWaveSpawnTime()))
        
        if timeToWave == 0 then
            self.spawnText:SetText(Locale.ResolveString("WAITING_TO_SPAWN"))
        else
            self.spawnText:SetText(string.format(Locale.ResolveString("NEXT_SPAWN_IN"), ToString(timeToWave)))
        end
        
        local eggCount = AlienUI_GetEggCount()
        
        self.eggCount:SetText(string.format("x %s", ToString(eggCount)))
        
        local hasEggs = eggCount > 0
        self.eggCount:SetColor(hasEggs and kWhite or kNoEggsColor)
        self.eggIcon:SetColor(hasEggs and kWhite or kNoEggsColor)
        
    end
    
end