    -- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\HUD\Marine\GUINotificationItem.lua
--
-- Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- Notifications triggered by the commander. Shows structures/medpacks/ammopacks etc. being dropped.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIUtility.lua")

class 'GUINotificationItem'

GUINotificationItem.kBuildMenuTexture = PrecacheAsset("ui/buildmenu.dds")
GUINotificationItem.kNotificationsTexture = PrecacheAsset("ui/research_notifications.dds")
GUINotificationItem.kColoredTextureShader = PrecacheAsset("shaders/GUIColoredTextureLerp.surface_shader")

-- How many seconds should the notification show complete state before going away.
GUINotificationItem.kResearchCompleteStayTime = 2
GUINotificationItem.kNotificationYMargin = 5

GUINotificationItem.kMarineIconSize = Vector(40, 40, 0)
GUINotificationItem.kAlienIconSize = Vector(40, 40, 0)

GUINotificationItem.kDefaultFontName = Fonts.kAgencyFB_Small
GUINotificationItem.kTitleFontName = Fonts.kAgencyFB_Small

GUINotificationItem.kAlienFrameCoordinates = {6, 6, 213, 94}
GUINotificationItem.kAlienNotificationFrameSize = GUIGetSizeFromCoords(GUINotificationItem.kAlienFrameCoordinates)

GUINotificationItem.kAlienBarCoordinates = {240, 1, 273, 56} -- With glow.
GUINotificationItem.kAlienBarSize = GUIGetSizeFromCoords(GUINotificationItem.kAlienBarCoordinates)

GUINotificationItem.kMarineFrameCoordinates = {0, 182, 191, 256}
GUINotificationItem.kMarineNotificationFrameSize = GUIGetSizeFromCoords(GUINotificationItem.kMarineFrameCoordinates)

GUINotificationItem.kMarineBarCoordinates = {240, 180, 257, 232} -- With glow.
GUINotificationItem.kMarineBarSize = GUIGetSizeFromCoords(GUINotificationItem.kMarineBarCoordinates)

GUINotificationItem.kMarineGUIOffsets =
{
    ProgressBarPos = Vector(-5, -4, 0),
    ProgressBarGlowRadius = 5,

    ProgressBarBackgroundCoords = { 245, 185, 245 + 8, 185 + 43 },
    ProgressBarBackgroundSize = Vector( 8, 40, 0 ),
    ProgressBarBackgroundPos = Vector( 0, 2, 0 ),
    ProgressBarBackgroundColor = Color( 0/255, 33/255, 55/255 ),

    IconPos = Vector(8, 2, 0),
    TechTitlePos = Vector(55, -27, 0),
    BottomTextPos = Vector(7, -20, 0),
    TextColor = Color(183/255, 218/255, 220/255),
    IconColor = Color(kIconColors[kMarineTeamType]),
    CompleteColor = Color(0, 0.75, 0),
    CancelColor = Color(0.75, 0, 0)
}

GUINotificationItem.kAlienGUIOffsets =
{
    ProgressBarPos = Vector(-4, 6, 0),
    ProgressBarGlowRadius = 5,

    ProgressBarBackgroundCoords = { 240, 6, 240 + 28, 6 + 46 },
    ProgressBarBackgroundSize = GUIGetSizeFromCoords({ 240, 6, 240 + 28, 6 + 46 }),
    ProgressBarBackgroundPos = Vector(-4, 6 + 5, 0),
    ProgressBarBackgroundColor = Color( 47/255, 26/255, 11/255 ),

    IconPos = Vector(18, 19, 0),
    TechTitlePos = Vector(67, -18, 0),
    BottomTextPos = Vector(20, -15, 0),
    TextColor = Color(221/255, 188/255, 7/255),
    IconColor = Color(kIconColors[kAlienTeamType]),
    CompleteColor = Color(0.85, 0.85, 0.85),
    CancelColor = Color(0.62,0,0.01)
}

-- utility functions:
function CreateNotificationItem(scriptHandle, techId, scale, parent, useMarineStyle, entityId)

    local notification = GUINotificationItem()
    notification.scale = scale
    notification.parent = parent
    notification.script = scriptHandle
    notification.techId = techId
    notification.entityId = entityId
    notification.useMarineStyle = useMarineStyle
    notification:Initialize()
    
    return notification
end

function DestroyNotificationItem(item)
    item:Destroy()
end

--[[
    NOTE(Salads): GetCustomSizeOffsetForTechId & GetCustomPosOffsetForTechId

    These functions get the offset and size for each icon to make them fill the whole
    80 pixel square of their original texture. This way we can scale the result and use it
    to get more reliable and uniform size and positions for the icons for the research notifications,
    instead of having some icons bee too small, or some icons not being centered.
]]--

local kCustomIconSizeOffsets
local function GetCustomSizeOffsetForTechId(techId)

    if not kCustomIconSizeOffsets then

        kCustomIconSizeOffsets = {}

        -- Marine stuff
        kCustomIconSizeOffsets[kTechId.AdvancedMarineSupport] = Vector( 33, 33, 0 )
        kCustomIconSizeOffsets[kTechId.Armor1] = Vector( 35, 35, 0 )
        kCustomIconSizeOffsets[kTechId.Armor2] = Vector( 16, 16, 0 )
        kCustomIconSizeOffsets[kTechId.Armor3] = Vector( 12, 12, 0 )
        kCustomIconSizeOffsets[kTechId.Weapons1] = Vector( 18, 18, 0 )
        kCustomIconSizeOffsets[kTechId.Weapons2] = Vector( 13, 13, 0 )
        kCustomIconSizeOffsets[kTechId.Weapons3] = Vector( 12, 12, 0 )
        kCustomIconSizeOffsets[kTechId.PhaseTech] = Vector( 16, 16, 0 )
        kCustomIconSizeOffsets[kTechId.ShotgunTech] = Vector( 21, 21, 0 )
        kCustomIconSizeOffsets[kTechId.AdvancedWeaponry] = Vector( 13, 13, 0 ) -- Unused. Completed automatically when adv. armory is finished.
        kCustomIconSizeOffsets[kTechId.GrenadeTech] = Vector( 29, 29, 0 )
        kCustomIconSizeOffsets[kTechId.MinesTech] = Vector( 24, 24, 0 )
        kCustomIconSizeOffsets[kTechId.JetpackTech] = Vector( 26, 26, 0 )
        kCustomIconSizeOffsets[kTechId.ExosuitTech] = Vector( 21, 21, 0 )
        kCustomIconSizeOffsets[kTechId.AdvancedArmoryUpgrade] = Vector( 16, 16, 0 )
        kCustomIconSizeOffsets[kTechId.UpgradeRoboticsFactory] = Vector( 17, 17, 0 )

        -- Alien stuff
        kCustomIconSizeOffsets[kTechId.Leap] = Vector( 33, 33, 0 ) -- Added a bit extra size since the icon is a bit small.
        kCustomIconSizeOffsets[kTechId.Xenocide] = Vector( 25, 25, 0 )
        kCustomIconSizeOffsets[kTechId.BileBomb] = Vector( 29, 29, 0 )
        kCustomIconSizeOffsets[kTechId.Umbra] = Vector( 31, 31, 0 )
        kCustomIconSizeOffsets[kTechId.Spores] = Vector( 25, 25, 0 )
        kCustomIconSizeOffsets[kTechId.MetabolizeEnergy] = Vector( 14, 14, 0 )
        kCustomIconSizeOffsets[kTechId.MetabolizeHealth] = Vector( 14, 14, 0 )
        kCustomIconSizeOffsets[kTechId.Stab] = Vector( 18, 18, 0 )
        kCustomIconSizeOffsets[kTechId.Charge] = Vector( 13, 13, 0 )
        kCustomIconSizeOffsets[kTechId.BoneShield] = Vector( 18, 18, 0 )
        kCustomIconSizeOffsets[kTechId.Stomp] = Vector( 24, 24, 0 )
        kCustomIconSizeOffsets[kTechId.UpgradeToCragHive] = Vector( 19, 19, 0 )
        kCustomIconSizeOffsets[kTechId.UpgradeToShadeHive] = Vector( 23, 23, 0 )
        kCustomIconSizeOffsets[kTechId.UpgradeToShiftHive] = Vector( 20, 20, 0 )
    end

    return (kCustomIconSizeOffsets[techId] or Vector(0,0,0))
end

local kCustomIconPosOffsets
local function GetCustomPosOffsetForTechId(techId)

    if not kCustomIconPosOffsets then

        kCustomIconPosOffsets = {}

        -- Marine stuff
        kCustomIconPosOffsets[kTechId.Armor1] = Vector( 9, 10, 0 )
        kCustomIconPosOffsets[kTechId.Armor3] = Vector( 6, 0, 0 )
        kCustomIconPosOffsets[kTechId.Weapons1] = Vector( 6, -6, 0 )
        kCustomIconPosOffsets[kTechId.Weapons2] = Vector( 6, -2, 0 )
        kCustomIconPosOffsets[kTechId.Weapons3] = Vector( 0, -2, 0 )
        kCustomIconPosOffsets[kTechId.PhaseTech] = Vector( 3, 2, 0 )
        kCustomIconPosOffsets[kTechId.ShotgunTech] = Vector( -3, -1, 0 )
        kCustomIconPosOffsets[kTechId.AdvancedWeaponry] = Vector( -3, 0, 0 )
        kCustomIconPosOffsets[kTechId.GrenadeTech] = Vector( -4, -1, 0 )
        kCustomIconPosOffsets[kTechId.MinesTech] = Vector( 0, -2, 0 )
        kCustomIconPosOffsets[kTechId.JetpackTech] = Vector( 0, 1, 0 )
        kCustomIconPosOffsets[kTechId.ExosuitTech] = Vector( 6, 5, 0 )
        kCustomIconPosOffsets[kTechId.AdvancedArmoryUpgrade] = Vector( 1, -2, 0 )
        kCustomIconPosOffsets[kTechId.UpgradeRoboticsFactory] = Vector( -1, -4, 0 )

        -- Alien stuff
        kCustomIconPosOffsets[kTechId.Leap] = Vector( -4, -3, 0 ) -- 1 pixel more right since the extra size changes above.
        kCustomIconPosOffsets[kTechId.Xenocide] = Vector( 5, 3, 0 )
        kCustomIconPosOffsets[kTechId.BileBomb] = Vector( -3, -2, 0 )
        kCustomIconPosOffsets[kTechId.Umbra] = Vector( 7, 8, 0 )
        kCustomIconPosOffsets[kTechId.Spores] = Vector( 1, 1, 0 )
        kCustomIconPosOffsets[kTechId.MetabolizeEnergy] = Vector( 0, -1, 0 )
        kCustomIconPosOffsets[kTechId.MetabolizeHealth] = Vector( 0, -2, 0 )
        kCustomIconPosOffsets[kTechId.Stab] = Vector( -5, 0, 0 )
        kCustomIconPosOffsets[kTechId.Charge] = Vector( -1, 6, 0 ) -- move to left a bit to ignore hard-to-see faded stuff
        kCustomIconPosOffsets[kTechId.BoneShield] = Vector( -6, -3, 0 )
        kCustomIconPosOffsets[kTechId.Stomp] = Vector( 2, 2, 0 )
        kCustomIconPosOffsets[kTechId.UpgradeToCragHive] = Vector( -6, -1, 0 )
        kCustomIconPosOffsets[kTechId.UpgradeToShadeHive] = Vector( -8, -1, 0 )
        kCustomIconPosOffsets[kTechId.UpgradeToShiftHive] = Vector( -4, -1, 0 )

    end

    return (kCustomIconPosOffsets[techId] or Vector(0,0,0))
end

-- pass a GUIItem as parent
function GUINotificationItem:Initialize()

    self.position = 0
    self.lastSecondsLeft = 999999999
    self.lastProgress = 0
    self.completeTime = 0
    self.completed = false
    self.cancelled = false

    local techNode = GetTechTree():GetTechNode(self.techId)

    assert(techNode ~= nil)

    -- Save the correct texture cord stuff depending if we're on marine team or not.
    self.size = ConditionalValue(self.useMarineStyle, GUINotificationItem.kMarineNotificationFrameSize, GUINotificationItem.kAlienNotificationFrameSize)
    self.progressBarTextureCoords = ConditionalValue(self.useMarineStyle, GUINotificationItem.kMarineBarCoordinates, GUINotificationItem.kAlienBarCoordinates)
    self.progressBarSize = ConditionalValue(self.useMarineStyle, GUINotificationItem.kMarineBarSize, GUINotificationItem.kAlienBarSize)
    self.iconSize = ConditionalValue(self.useMarineStyle, GUINotificationItem.kMarineIconSize, GUINotificationItem.kAlienIconSize)
    self.guiOffsets = ConditionalValue(self.useMarineStyle, GUINotificationItem.kMarineGUIOffsets, GUINotificationItem.kAlienGUIOffsets)

    local backgroundCoords = ConditionalValue(self.useMarineStyle, GUINotificationItem.kMarineFrameCoordinates, GUINotificationItem.kAlienFrameCoordinates)
    self.background = self.script:CreateAnimatedGraphicItem()
    self.background:SetUniformScale(self.scale)
    self.background:SetSize(self.size)
    self.background:SetTexture(GUINotificationItem.kNotificationsTexture)
    self.background:SetTexturePixelCoordinates(GUIUnpackCoords(backgroundCoords))
    self.background:SetIsVisible(false)
    self.background:SetLayer(0)
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)

    self.background:Pause(0.2, nil, AnimateLinear, 
        function (script, item)
        
            item:SetIsVisible(true)
        
        end
    )
    
    if self.parent then
        self.background:AddAsChildTo(self.parent)
    end

    self.progressBarBackground = self.script:CreateAnimatedGraphicItem()
    self.progressBarBackground:SetUniformScale(self.scale)
    self.progressBarBackground:SetSize(self.guiOffsets.ProgressBarBackgroundSize)
    self.progressBarBackground:SetTexture(GUINotificationItem.kNotificationsTexture)
    self.progressBarBackground:SetTexturePixelCoordinates(GUIUnpackCoords(self.guiOffsets.ProgressBarBackgroundCoords))
    self.progressBarBackground:SetPosition(self.guiOffsets.ProgressBarBackgroundPos)
    self.progressBarBackground:SetColor(self.guiOffsets.ProgressBarBackgroundColor)
    self.progressBarBackground:SetLayer(1)
    self.progressBarBackground:SetIsVisible(true)
    self.progressBarBackground:AddAsChildTo(self.background)
    self.progressBarBackground.originalColor = self.guiOffsets.ProgressBarBackgroundColor

    local iconScale = (self.iconSize / 80)
    local iconSizeOffset = GetCustomSizeOffsetForTechId(self.techId) * iconScale
    local iconPosOffset = GetCustomPosOffsetForTechId(self.techId) * iconScale

    self.icon = self.script:CreateAnimatedGraphicItem()
    self.icon:SetUniformScale(self.scale)
    self.icon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.icon:SetSize(self.iconSize + iconSizeOffset)
    self.icon:SetPosition(self.guiOffsets.IconPos - (iconSizeOffset / 2) + iconPosOffset)
    self.icon:SetTexture(GUINotificationItem.kBuildMenuTexture)
    self.icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(self.techId)))
    self.icon:SetLayer(2)
    self.icon.originalColor = self.guiOffsets.IconColor
    self.icon:AddAsChildTo(self.background)

    self.progressBar = self.script:CreateAnimatedGraphicItem()
    self.progressBar:SetUniformScale(self.scale)
    self.progressBar:SetTexture(GUINotificationItem.kNotificationsTexture)
    self.progressBar:SetTexturePixelCoordinates(GUIUnpackCoords(self.progressBarTextureCoords))
    self.progressBar:SetPosition(self.guiOffsets.ProgressBarPos)
    self.progressBar:SetSize(self.progressBarSize)
    self.progressBar:SetLayer(2)
    self.progressBar:SetShader(GUINotificationItem.kColoredTextureShader)
    self.progressBar:AddAsChildTo(self.background)

    local techName = LookupTechData(self.techId, kTechDataResearchName)
    if not techName then
        techName = EnumToString(kTechId, self.techId)
        Log("Warning: Missing research title for (%s). Defaulting to TechID name.", techName)
    else
        techName = Locale.ResolveString(techName)
    end

    self.techTitle = self.script:CreateAnimatedTextItem()
    self.techTitle:SetText(string.UTF8Upper(techName))
    self.techTitle:SetFontName(GUINotificationItem.kTitleFontName)
    self.techTitle:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.techTitle:SetPosition(self.guiOffsets.TechTitlePos)
    self.techTitle:SetLayer(1)
    self.techTitle:SetScale(GetScaledVector() * 1.1)
    self.techTitle:SetFontIsBold(true)
    self.techTitle.originalColor = self.guiOffsets.TextColor
    self.techTitle:AddAsChildTo(self.background)
    GUIMakeFontScale(self.techTitle)

    self.bottomText = self.script:CreateAnimatedTextItem()
    self.bottomText:SetText("--:--")
    self.bottomText:SetFontName(GUINotificationItem.kDefaultFontName)
    self.bottomText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.bottomText:SetTextAlignmentX(GUIItem.Align_Min)
    self.bottomText:SetTextAlignmentY(GUIItem.Align_Center)
    self.bottomText:SetPosition(self.guiOffsets.BottomTextPos)
    self.bottomText:SetLayer(1)
    self.bottomText:SetScale(GetScaledVector() * 0.9)
    GUIMakeFontScale(self.bottomText)
    self.bottomText.originalColor = self.guiOffsets.TextColor
    self.bottomText:AddAsChildTo(self.background)

    self.destroyTime = 0

end

function GUINotificationItem:Destroy()

    if self.background then
        self.background:Destroy()
        self.background = nil
    end

    if self.icon then
        self.icon:Destroy()
        self.icon = nil
    end
    
    if self.techTitle then
        self.techTitle:Destroy()
        self.techTitle = nil
    end

    if self.progressBar then
        self.progressBar:Destroy()
        self.progressBar = nil
    end

    if self.progressBarBackground then
        self.progressBarBackground:Destroy()
        self.progressBarBackground = nil
    end

    if self.techTitle then
        self.techTitle:Destroy()
        self.techTitle = nil
    end

    if self.bottomText then
        self.bottomText:Destroy()
        self.bottomText = nil
    end

end

function GUINotificationItem:SetCompleted()

    self.completeTime = Shared.GetTime()
    self.completed = true
    self.bottomText:SetText(
            string.UTF8Upper(ConditionalValue(self.useMarineStyle,
                    Locale.ResolveString("MARINE_ALERT_RESEARCH_COMPLETE"),
                    Locale.ResolveString("ALIEN_ALERT_RESEARCH_COMPLETE"))
                    or "Research Complete"))
    self.bottomText:SetPosition(self.bottomText:GetPosition() + Vector(-self.guiOffsets.BottomTextPos.x, 0, 0))

    self.progressBar:SetColor(self.guiOffsets.CompleteColor)

    self.icon:SetColor(self.guiOffsets.CompleteColor, 0.5, "RESEARCH_COMPLETE")
    self.techTitle:SetColor(self.guiOffsets.CompleteColor, 0.5, "RESEARCH_COMPLETE")
    self.bottomText:SetColor(self.guiOffsets.CompleteColor, 0.5, "RESEARCH_COMPLETE")
end

function GUINotificationItem:UpdateItem()

    if self.cancelled or self.completed then

        local lerpFactor = 0
        local timePassedSinceComplete = Shared.GetTime() - self.completeTime
        if timePassedSinceComplete <= 0.5 then

            lerpFactor = timePassedSinceComplete / 0.5

        elseif timePassedSinceComplete > 0.5 and timePassedSinceComplete < 1 then

            lerpFactor = 1 - (timePassedSinceComplete - 0.5) / (1 - 0.5)

        end

        self.progressBar.guiItem:SetFloatParameter("lerpFactor", lerpFactor)

        if timePassedSinceComplete > 1 then

            self.progressBar.guiItem:SetFloatParameter("fading", true)

        end
    end

end

function GUINotificationItem:SetCancelled()

    self.completeTime = Shared.GetTime()
    self.cancelled = true
    self.bottomText:SetText(
            string.UTF8Upper(ConditionalValue(self.useMarineStyle,
                    Locale.ResolveString("MARINE_ALERT_RESEARCH_CANCELLED"),
                    Locale.ResolveString("ALIEN_ALERT_RESEARCH_CANCELLED"))
                    or "Research Cancelled"))
    self.bottomText:SetPosition(self.bottomText:GetPosition() + Vector(-self.guiOffsets.BottomTextPos.x, 0, 0))

    self.progressBar:SetColor(self.guiOffsets.CancelColor)

    self.icon:SetColor(self.guiOffsets.CancelColor, 0.5, "RESEARCH_COMPLETE")
    self.techTitle:SetColor(self.guiOffsets.CancelColor, 0.5, "RESEARCH_COMPLETE")
    self.bottomText:SetColor(self.guiOffsets.CancelColor, 0.5, "RESEARCH_COMPLETE")

end

function GUINotificationItem:GetCancelled()
    return self.cancelled
end

function GUINotificationItem:GetCompleted()
    return self.completed
end

function GUINotificationItem:GetCreationTime()
    return self.creationTime
end

function GUINotificationItem:SetPositionInstant(newPositionIndex)

    self.position = newPositionIndex
    self.background:DestroyAnimation("SHIFT_UP")
    self.background:DestroyAnimation("SHIFT_DOWN")
    self.background:SetPosition( Vector(0, self.size.y + GUINotificationItem.kNotificationYMargin, 0) * self.position)
end

function GUINotificationItem:ShiftUp(numPositions)

    if numPositions == nil or type(numPositions) ~= "number" then
        numPositions = 1
    end

    assert(self.position > 0)

    self.position = self.position - numPositions
    self.background:DestroyAnimation("SHIFT_UP")
    self.background:DestroyAnimation("SHIFT_DOWN")
    self.background:SetPosition( Vector(0, self.size.y + GUINotificationItem.kNotificationYMargin, 0) * self.position, 0.5, "SHIFT_UP", AnimateSin)
end

function GUINotificationItem:ShiftDown(numPositions)

    if numPositions == nil or type(numPositions) ~= "number" then
        numPositions = 1
    end

    self.position = self.position + numPositions
    self.background:DestroyAnimation("SHIFT_UP")
    self.background:DestroyAnimation("SHIFT_DOWN")
    self.background:SetPosition( Vector(0, self.size.y + GUINotificationItem.kNotificationYMargin, 0) * self.position, 0.5, "SHIFT_DOWN", AnimateSin)
end

function GUINotificationItem:MatchesTo(techId)
    return techId == self.techId
end

function GUINotificationItem:SetLayer(layer)

    if self.background then
        self.background:SetLayer(layer)
    end
    
    if self.techTitle then
        self.techTitle:SetLayer(layer)
    end
        
    if self.icon then
        self.icon:SetLayer(layer)
    end
end

-- will trigger fade out on itself and all children and destroy all GUIItems
function GUINotificationItem:FadeIn(animDuration)

    local textColor = Color(self.guiOffsets.TextColor)
    textColor.a = 0

    local iconColor = Color(self.guiOffsets.IconColor)
    iconColor.a = 0

    if self.icon then
        self.icon:SetColor(iconColor)
        self.icon:FadeIn(animDuration, nil, AnimateLinear)
    end

    if self.techTitle then
        self.techTitle:SetColor(textColor)
        self.techTitle:FadeIn(animDuration, nil, AnimateLinear)
    end   
    
    if self.background then
        self.background:SetColor(Color(1,1,1,0))
        self.background:FadeIn(animDuration, nil, AnimateLinear)
    end

    if self.bottomText then
        self.bottomText:SetColor(textColor)
        self.bottomText:FadeIn(animDuration, nil, AnimateLinear)
    end

    if self.progressBar then
        self.progressBar:SetColor(Color(1,1,1,0))
        self.progressBar:FadeIn(animDuration, nil, AnimateLinear)
    end

    if self.progressBarBackground then
        self.progressBarBackground:FadeIn(animDuration, nil, AnimateLinear)
    end
end

-- will trigger fade out on itself and all children and destroy all GUIItems
function GUINotificationItem:FadeOut(animDuration)

    if self.destroyTime ~= 0 then
        return
    end
    
    if self.icon then
        self.icon:FadeOut(animDuration, nil, AnimateLinear)
    end

    if self.progressBarBackground then
        self.progressBarBackground:FadeOut(animDuration, nil, AnimateLinear)
    end
    
    if self.techTitle then
        self.techTitle:FadeOut(animDuration, nil, AnimateLinear)
    end   
    
    if self.background then
        self.background:FadeOut(animDuration, nil, AnimateLinear)
    end

    if self.bottomText then
        self.bottomText:FadeOut(animDuration, nil, AnimateLinear)
    end

    if self.progressBar then
        self.progressBar:FadeOut(animDuration, nil, AnimateLinear)
    end

    self.destroyTime = Client.GetTime() + animDuration
end

function GUINotificationItem:GetShouldStartFading()
    return (self.completed or self.cancelled) and Shared.GetTime() > self.completeTime + GUINotificationItem.kResearchCompleteStayTime
end

function GUINotificationItem:GetIsReadyToBeDestroyed()
    return self.destroyTime ~= 0 and self.destroyTime < Client.GetTime()
end
