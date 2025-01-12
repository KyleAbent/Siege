-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/hud2/thunderdome/GUIReadyRoomDelayTimer.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
--    Simple countdown script to display the remaining time for all players in the Ready Room
--    before the next round of a TD match begins.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")


local baseClass = GUIListLayout
class 'GUIReadyRoomDelayTimer' (baseClass)


local kBottomOffset = -210
local kSpacing = 8
local kDefaultTimerTextValue = 60   --TODO pull from global


function GUIReadyRoomDelayTimer:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    PushParamChange(params, "spacing", kSpacing)
    PushParamChange(params, "orientation", "horizontal")
    baseClass.Initialize(self, params, errorDepth)
    PopParamChange(params, "orientation")
    PopParamChange(params, "spacing")

    self:AlignBottom()
    self:SetY( kBottomOffset )

    self:SetLayer(10)  --TODO Review/revise

    --TODO Add some kind of "shiny" background image for timer (ideally, use existing UI assets)
    --TODO Add left background image

    self.textHolder = CreateGUIObject("textHolder", GUIObject, self)
    self.textHolder:AlignCenter()

    self.label = CreateGUIObject("text", GUIText, self.textHolder)
    self.label:SetFontSize(20)
    self.label:SetFontFamily("Microgramma")
    self.label:AlignCenter()
    self.label:AlignTop()
    self.label:SetY( -50 )
    self.label:SetText(self:GetLabelMaxWidthText())
    self.textHolder:SetSize(self.label:GetSize())
    self.label:SetText( Locale.ResolveString("THUNDERDOME_RULES_TIMER_WAITCONNECT_PLAYERS") )
    self.label:SetDropShadowEnabled(true)
    self.label:SetVisible(false)

    self.timer = CreateGUIObject("text", GUIText, self.textHolder)
    self.timer:SetFontSize(30)
    self.timer:SetFontFamily("MicrogrammaBold")
    self.timer:AlignCenter()
    self.timer:AlignBottom()
    self.timer:SetText( "-1" )
    self.timer:SetDropShadowEnabled(true)
    self.timer:SetColor( HexToColor("36b4d4") )     --TD-TODO change to menu styles dip
    self.timer:SetVisible(false)
    
    --TODO Add right background image

    self.forceConcedeTitle = CreateGUIObject("text", GUIText, self.textHolder)
    self.forceConcedeTitle:SetFont("AgencyBold", 34) --20  --"MicrogrammaBold"
    self.forceConcedeTitle:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.forceConcedeTitle:AlignCenter()
    self.forceConcedeTitle:AlignTop()
    self.forceConcedeTitle:SetY( -145 )
    self.forceConcedeTitle:SetColor( HexToColor("36b4d4") )
    self.forceConcedeTitle:SetText( Locale.ResolveString("THUNDERDOME_RULES_FORCED_CONCEDE_MSG") )
    self.forceConcedeTitle:SetDropShadowEnabled(true)
    self.forceConcedeTitle:SetVisible(false)

    self.forceConcedeTitle2 = CreateGUIObject("text", GUIText, self.textHolder)
    self.forceConcedeTitle2:SetFont("AgencyBold", 34) --20  --"MicrogrammaBold"
    self.forceConcedeTitle2:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.forceConcedeTitle2:AlignCenter()
    self.forceConcedeTitle2:AlignTop()
    self.forceConcedeTitle2:SetY( -145 )
    self.forceConcedeTitle2:SetColor( HexToColor("36b4d4") )
    self.forceConcedeTitle2:SetText( Locale.ResolveString("THUNDERDOME_RULES_FORCED_CONCEDE_MSG_2") )
    self.forceConcedeTitle2:SetDropShadowEnabled(true)
    self.forceConcedeTitle2:SetVisible(false)

    self.forceConcedelabel = CreateGUIObject("text", GUIText, self.textHolder)
    self.forceConcedelabel:SetFont("Agency", 30) --16 --"Microgramma"
    self.forceConcedelabel:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.forceConcedelabel:AlignCenter()
    self.forceConcedelabel:AlignTop()
    self.forceConcedelabel:SetY( -100 )
    self.forceConcedelabel:SetColor( HexToColor("F0F0FF") )
    self.forceConcedelabel:SetText( Locale.ResolveString("THUNDERDOME_RULES_FORCED_CONCEDE_MSG_DESC") )
    self.forceConcedelabel:SetDropShadowEnabled(true)
    self.forceConcedelabel:SetVisible(false)

    self.forfeitWarning = CreateGUIObject("text", GUIText, self.textHolder)
    self.forfeitWarning:SetFont("Agency", 32)
    self.forfeitWarning:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.forfeitWarning:AlignCenter()
    self.forfeitWarning:AlignBottom()
    self.forfeitWarning:SetY( 20 )
    self.forfeitWarning:SetColor( HexToColor("FFCA3A", 1) )
    self.forfeitWarning:SetText( Locale.ResolveString("THUNDERDOME_RULES_FORCED_CONCEDE_WARN_MSG_TITLE") )
    self.forfeitWarning:SetDropShadowEnabled(true)
    self.forfeitWarning:SetVisible(true)

    self.forfeitWarning2 = CreateGUIObject("text", GUIText, self.textHolder)
    self.forfeitWarning2:SetFont("Agency", 30)
    self.forfeitWarning2:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.forfeitWarning2:AlignCenter()
    self.forfeitWarning2:AlignBottom()
    self.forfeitWarning2:SetY( 55 )
    self.forfeitWarning2:SetColor( HexToColor("FFCA3A", 1) )
    self.forfeitWarning2:SetText( string.format( Locale.ResolveString("THUNDERDOME_RULES_FORCED_CONCEDE_WARN_MSG") ,  tostring(kForfeitWarningActivateDelay)) )
    self.forfeitWarning2:SetDropShadowEnabled(true)
    self.forfeitWarning2:SetVisible(true)

    self.textHolder:SetSize(self.forceConcedelabel:GetSize())

    self:SetVisible(true)
end

function GUIReadyRoomDelayTimer:SetStateLabel( labelTxt )
    self.label:SetText( labelTxt )
end

function GUIReadyRoomDelayTimer:GetShowingForfeitWarning()
    return self.forfeitWarning:GetVisible()
end

function GUIReadyRoomDelayTimer:UpdateForfeitWarningTextColors()
--flip team-color for the text, so it has more contrast against the GUI
    self.forfeitWarning:SetColor( PlayerUI_GetTeamType() == kMarineTeamType and HexToColor("FFCA3A") or HexToColor("4DB1FF") )
    self.forfeitWarning2:SetColor( PlayerUI_GetTeamType() == kMarineTeamType and HexToColor("FFCA3A") or HexToColor("4DB1FF") )
end

function GUIReadyRoomDelayTimer:UpdateForfeitTimerText(timeVal)
    self.forfeitWarning:SetText( Locale.ResolveString("THUNDERDOME_RULES_FORCED_CONCEDE_WARN_MSG_TITLE") )
    self.forfeitWarning2:SetText( string.format( Locale.ResolveString("THUNDERDOME_RULES_FORCED_CONCEDE_WARN_MSG"), tostring(timeVal) ) )
end

function GUIReadyRoomDelayTimer:UpdateForfeitAbsoluteTimerText(timeVal)
    self.forfeitWarning:SetText( Locale.ResolveString("THUNDERDOME_RULES_FORCED_CONCEDE_WARN_ROUNDLEN_MSG_TITLE") )
    local limitInMinutes = math.floor(kThunderdomeRoundMaxTimeLimit / 60)
    self.forfeitWarning2:SetText( string.format( Locale.ResolveString("THUNDERDOME_RULES_FORCED_CONCEDE_WARN_ROUNDLEN_MSG"), tostring(limitInMinutes), tostring(timeVal) ) )
end

function GUIReadyRoomDelayTimer:UpdateMessageForMaxRoundTime()
    self.forfeitWarning:SetText( Locale.ResolveString("THUNDERDOME_RULES_FORCED_CONCEDE_WARN_ROUNDLEN_MSG_TITLE") ) 
    local limitInMinutes = math.floor(kThunderdomeRoundMaxTimeLimit / 60)
    self.forfeitWarning2:SetText( 
        string.format( Locale.ResolveString("THUNDERDOME_RULES_FORCED_CONCEDE_WARN_ROUNDLEN_MSG"), tostring(limitInMinutes), tostring(kForfeitWarningActivateDelay) ) 
    )
end

function GUIReadyRoomDelayTimer:ShowForfeitWarning(enable)
    self.forfeitWarning:SetVisible(enable)
    self.forfeitWarning2:SetVisible(enable)
end

function GUIReadyRoomDelayTimer:ShowForcedConcedeMessage(enable, teamIdx)

    self.forceConcedelabel:SetVisible(enable)

    if enable and teamIdx ~= PlayerUI_GetTeamNumber() then
        self.forceConcedeTitle:SetVisible(true)
    elseif enable then
        self.forceConcedeTitle2:SetVisible(true)
    else
        self.forceConcedeTitle:SetVisible(false)
        self.forceConcedeTitle2:SetVisible(false)
    end

end

function GUIReadyRoomDelayTimer:GetLabelMaxWidthText()
    return " " .. Locale.ResolveString("THUNDERDOME_RULES_TIMER_WAITCONNECT_PLAYERS") .. " "
end

function GUIReadyRoomDelayTimer:SetTimerRemaining( newTimerVal )
    assert(newTimerVal)
    local val = tonumber(newTimerVal)
    val = val > 0 and val or 0
    --TODO change color as time decreases. End with pulsing blue/red?
    self.timer:SetText( string.format("%2d", val) )
    if val > 0 and not self.timer:GetVisible() or not self.label:GetVisible() then
        self.timer:SetVisible(true)
        self.label:SetVisible(true)
    end

    if val <= 0 then
        self.timer:SetVisible(false)
        self.label:SetVisible(false)
    end
end