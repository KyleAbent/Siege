-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUICommanderManager.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- Manages the other commander UIs and input for the commander UI.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUICommanderManager' (GUIScript)

local kSelectorMarineColor = Color(0.0, 0, 0.5, 0.15)
local kSelectorAlienColor = Color(0.8, 0.3, 0, 0.15)

local kLocationTextOffset = GUIScale(Vector(36, 36, 0))
local kLocationTextFont = Fonts.kAgencyFB_Small
local kLocationTextColor = Color(1, 1, 1, 0.5)

local kSideTimerPos = GUIScale(Vector(30, 120, 0))
local kFrontTimerPos = GUIScale(Vector(30, 150, 0))
local kSiegeTimerPos = GUIScale(Vector(30, 180, 0))

local function CreateSelector(self)

    self.selector = GUIManager:CreateGraphicItem()
    self.selector:SetAnchor(GUIItem.Top, GUIItem.Left)
    self.selector:SetIsVisible(false)
    
end

local function CreateLocationText(self)

    self.locationText = GUIManager:CreateTextItem()
    self.locationText:SetFontName(kLocationTextFont)
    self.locationText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.locationText)
    self.locationText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.locationText:SetTextAlignmentX(GUIItem.Align_Min)
    self.locationText:SetTextAlignmentY(GUIItem.Align_Min)
    self.locationText:SetPosition(kLocationTextOffset)
    self.locationText:SetColor(kLocationTextColor)
    self.locationText:SetText(PlayerUI_GetLocationName())
    
end

function GUICommanderManager:OnResolutionChanged(oldX, oldY, newX, newY)
    kLocationTextOffset = GUIScale(Vector(36, 36, 0))
    self.locationText:SetFontName(kLocationTextFont)
    self.locationText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.locationText)
    self.locationText:SetPosition(kLocationTextOffset)

    -- Update timer positions
    if self.sideTimer then
        self.sideTimer:SetScale(GetScaledVector())
        GUIMakeFontScale(self.sideTimer)
        self.sideTimer:SetPosition(GUIScale(Vector(30, 120, 0)))
    end

    if self.frontTimer then
        self.frontTimer:SetScale(GetScaledVector())
        GUIMakeFontScale(self.frontTimer)
        self.frontTimer:SetPosition(GUIScale(Vector(30, 150, 0)))
    end

    if self.siegeTimer then
        self.siegeTimer:SetScale(GetScaledVector())
        GUIMakeFontScale(self.siegeTimer)
        self.siegeTimer:SetPosition(GUIScale(Vector(30, 180, 0)))
    end
end


local function CreateTimers(self)
    -- Side timer
    self.sideTimer = GUIManager:CreateTextItem()
    self.sideTimer:SetFontName(kLocationTextFont)
    self.sideTimer:SetScale(GetScaledVector())
    GUIMakeFontScale(self.sideTimer)
    self.sideTimer:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.sideTimer:SetTextAlignmentX(GUIItem.Align_Min)
    self.sideTimer:SetTextAlignmentY(GUIItem.Align_Min)
    self.sideTimer:SetPosition(kSideTimerPos)
    self.sideTimer:SetColor(kLocationTextColor)
    self.sideTimer:SetText("Side: --:--")

    -- Front timer
    self.frontTimer = GUIManager:CreateTextItem()
    self.frontTimer:SetFontName(kLocationTextFont)
    self.frontTimer:SetScale(GetScaledVector())
    GUIMakeFontScale(self.frontTimer)
    self.frontTimer:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.frontTimer:SetTextAlignmentX(GUIItem.Align_Min)
    self.frontTimer:SetTextAlignmentY(GUIItem.Align_Min)
    self.frontTimer:SetPosition(kFrontTimerPos)
    self.frontTimer:SetColor(kLocationTextColor)
    self.frontTimer:SetText("Front: --:--")

    -- Siege timer
    self.siegeTimer = GUIManager:CreateTextItem()
    self.siegeTimer:SetFontName(kLocationTextFont)
    self.siegeTimer:SetScale(GetScaledVector())
    GUIMakeFontScale(self.siegeTimer)
    self.siegeTimer:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.siegeTimer:SetTextAlignmentX(GUIItem.Align_Min)
    self.siegeTimer:SetTextAlignmentY(GUIItem.Align_Min)
    self.siegeTimer:SetPosition(kSiegeTimerPos)
    self.siegeTimer:SetColor(kLocationTextColor)
    self.siegeTimer:SetText("Siege: --:--")
end

function GUICommanderManager:Initialize()
    self.updateInterval = kUpdateIntervalFull

    CreateSelector(self)
    CreateLocationText(self)
    CreateTimers(self)  -- Add this line

    self.childScripts = { }
end

function GUICommanderManager:Uninitialize()
    self.childScripts = { }

    if self.selector then
        GUI.DestroyItem(self.selector)
        self.selector = nil
    end

    if self.locationText then
        GUI.DestroyItem(self.locationText)
        self.locationText = nil
    end

    -- Add these lines
    if self.sideTimer then
        GUI.DestroyItem(self.sideTimer)
        self.sideTimer = nil
    end

    if self.frontTimer then
        GUI.DestroyItem(self.frontTimer)
        self.frontTimer = nil
    end

    if self.siegeTimer then
        GUI.DestroyItem(self.siegeTimer)
        self.siegeTimer = nil
    end
end

function GUICommanderManager:AddChildScript(childScript)
    table.insert(self.childScripts, childScript)
end

local function UpdateSelector(self)

    if self.selector then
    
        local visible = GetIsCommanderMarqueeSelectorDown()
        self.selector:SetIsVisible(visible)
        
        if visible then
        
            local info = GetCommanderMarqueeSelectorInfo()
            
            self.selector:SetPosition(Vector(info.startX, info.startY, 0))
            self.selector:SetSize(Vector(info.endX - info.startX, info.endY - info.startY, 0))
            
            if CommanderUI_IsAlienCommander() then
                self.selector:SetColor(kSelectorAlienColor)
            else
                self.selector:SetColor(kSelectorMarineColor)
            end
            
        end
        
    end
    
end

local function UpdateMouseOverUIState(self)

    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    -- Check all the clickable commander UI items owned by the manager.
    local mouseOverUI = false
    
    for i, childScript in ipairs(self.childScripts) do
    
        -- Can break out if the mouse is already over the UI.
        if mouseOverUI then
            break
        end
        
        mouseOverUI = mouseOverUI or childScript:ContainsPoint(mouseX, mouseY)
        
    end
    
    CommanderUI_SetMouseIsOverUI(mouseOverUI)
    
end


local function UpdateTimers(self)
    if self.sideTimer and self.frontTimer and self.siegeTimer then
        local gameLength = PlayerUI_GetGameLengthTime() or 0
        local sideLength = PlayerUI_GetSideLength()
        local frontLength = PlayerUI_GetFrontLength()
        local siegeLength = PlayerUI_GetSiegeLength()

        -- Side Timer
        if sideLength then
            local sideRemain = math.max(0, sideLength - gameLength)
            local sideMinutes = math.floor(sideRemain / 60)
            local sideSeconds = math.floor(sideRemain % 60)
            if sideRemain > 0 then
                self.sideTimer:SetText(string.format("Side: %d:%02d", sideMinutes, sideSeconds))
                self.sideTimer:SetColor(Color(1, 1, 1, 1))
            else
                self.sideTimer:SetText("Side: OPEN")
                self.sideTimer:SetColor(Color(0, 1, 0, 1))
            end
        end

        -- Front Timer
        if frontLength then
            local frontRemain = math.max(0, frontLength - gameLength)
            local frontMinutes = math.floor(frontRemain / 60)
            local frontSeconds = math.floor(frontRemain % 60)
            if frontRemain > 0 then
                self.frontTimer:SetText(string.format("Front: %d:%02d", frontMinutes, frontSeconds))
                self.frontTimer:SetColor(Color(1, 1, 1, 1))
            else
                self.frontTimer:SetText("Front: OPEN")
                self.frontTimer:SetColor(Color(0, 1, 0, 1))
            end
        end

        -- Siege Timer
        if siegeLength then
            local siegeRemain = math.max(0, siegeLength - gameLength)
            local siegeMinutes = math.floor(siegeRemain / 60)
            local siegeSeconds = math.floor(siegeRemain % 60)
            if siegeRemain > 0 then
                self.siegeTimer:SetText(string.format("Siege: %d:%02d", siegeMinutes, siegeSeconds))
                self.siegeTimer:SetColor(Color(1, 1, 1, 1))
            else
                self.siegeTimer:SetText("Siege: OPEN")
                self.siegeTimer:SetColor(Color(0, 1, 0, 1))
            end
        end
    end
end


function GUICommanderManager:Update(deltaTime)
        
    PROFILE("GUICommanderManager:Update")
    
    UpdateSelector(self)
    
    local locationName = PlayerUI_GetLocationName()
    if locationName then
        self.locationText:SetText(locationName)
    end
    
    UpdateMouseOverUIState(self)

    UpdateTimers(self)
    
end