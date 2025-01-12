-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIPlayerResource.lua
--
-- Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- Displays team and personal resources. Everytime resources are being added, the numbers pulsate
-- x times, where x is the amount of resource towers.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIPlayerResource'

GUIPlayerResource.kPersonalResourceIcon = { Width = 0, Height = 0, X = 0, Y = 0 }
GUIPlayerResource.kPersonalResourceIcon.Width = 32
GUIPlayerResource.kPersonalResourceIcon.Height = 64

GUIPlayerResource.kPersonalResourceIconSize = Vector(GUIPlayerResource.kPersonalResourceIcon.Width, GUIPlayerResource.kPersonalResourceIcon.Height, 0)
GUIPlayerResource.kPersonalResourceIconSizeBig = Vector(GUIPlayerResource.kPersonalResourceIcon.Width, GUIPlayerResource.kPersonalResourceIcon.Height, 0) * 1.1

GUIPlayerResource.kPersonalIconPos = Vector(30,-4,0)
GUIPlayerResource.kPersonalTextPos = Vector(100,4,0)
GUIPlayerResource.kPresDescriptionPos = Vector(110,4,0)

GUIPlayerResource.kTeam1TextPos = Vector(20, 360, 0)
GUIPlayerResource.kTeam2TextPos = Vector(20, 540, 0)

GUIPlayerResource.kIconTextXOffset = -20

GUIPlayerResource.kFontSizePersonal = 30
GUIPlayerResource.kFontSizePersonalBig = 30

GUIPlayerResource.kPulseTime = 0.5

GUIPlayerResource.kFontSizePresDescription = 18
GUIPlayerResource.kFontSizeResGained = 25
GUIPlayerResource.kFontSizeTeam = 18
GUIPlayerResource.kTextFontName = Fonts.kAgencyFB_Small
GUIPlayerResource.kTresTextFontName = Fonts.kAgencyFB_Small
GUIPlayerResource.kResGainedFontName = Fonts.kAgencyFB_Small

--
-- GUIPlayerResource.kPersonalTimeIcon = { Width = 0, Height = 0, X = 0, Y = 0 }
-- GUIPlayerResource.kPersonalTimeIcon.Width = 32
-- GUIPlayerResource.kPersonalTimeIcon.Height = 64
--
-- GUIPlayerResource.kPersonalTimeIconSize = Vector(GUIPlayerResource.kPersonalResourceIcon.Width, GUIPlayerResource.kPersonalResourceIcon.Height, 0)
-- GUIPlayerResource.kPersonalTimeIconSizeBig = Vector(GUIPlayerResource.kPersonalResourceIcon.Width, GUIPlayerResource.kPersonalResourceIcon.Height, 0) * 1.1
--
--
-- GUIPlayerResource.kPersonalTimeIconPos = Vector(30,-4,0)
-- GUIPlayerResource.kPersonalTimeTextPos = Vector(100,4,0)
-- GUIPlayerResource.kTimeDescriptionPos = Vector(110,4,0)
-- GUIPlayerResource.kTimeGainedTextPos = Vector(90,-6,0)
--
-- GUIPlayerResource.kFontSizePersonalTime = 20
-- GUIPlayerResource.kFontSizePersonalTimeBig = 20
--
--
-- GUIPlayerResource.kFrontTimeBackgroundSize = Vector(180, 58, 0)
-- GUIPlayerResource.kFrontTimeBackgroundPos = Vector(-350, -175, 0)
--
-- GUIPlayerResource.kSideTimeBackgroundSize = Vector(180, 58, 0)
-- GUIPlayerResource.kSideTimeBackgroundPos = Vector(-150, -175, 0)
--
--
-- GUIPlayerResource.kSiegeTimeBackgroundSize = Vector(180, 58, 0)
-- GUIPlayerResource.kSiegeTimeBackgroundPos = Vector(50, -175, 0)



local kBackgroundTextures = { alien = PrecacheAsset("ui/alien_HUD_presbg.dds"), marine = PrecacheAsset("ui/marine_HUD_presbg.dds") }

local kPresIcons = { alien = PrecacheAsset("ui/alien_HUD_presicon.dds"), marine = PrecacheAsset("ui/marine_HUD_presicon.dds") }

GUIPlayerResource.kBackgroundSize = Vector(280, 58, 0)
GUIPlayerResource.kBackgroundPos = Vector(-320, -100, 0)

function CreatePlayerResourceDisplay(scriptHandle, hudLayer, frame, style, teamNum)

    local playerResource = GUIPlayerResource()
    playerResource.script = scriptHandle
    playerResource.hudLayer = hudLayer
    playerResource.frame = frame
    playerResource:Initialize(style, teamNum)
    
    return playerResource
    
end

function GUIPlayerResource:Initialize(style, teamNumber)

    self.cachedHudDetail = Client.GetHudDetail()
    local minimal = self.cachedHudDetail == kHUDMode.Minimal

    self.style = style
    self.teamNumber = teamNumber
    self.scale = 1
    
    self.lastPersonalResources = 0
    
    -- Background.
    self.background = self.script:CreateAnimatedGraphicItem()
    self.background:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.background:SetTexture(kBackgroundTextures[style.textureSet])
    self.background:SetColor(Color(1,1,1,ConditionalValue(minimal, 0, 1)))
    self.background:AddAsChildTo(self.frame)
    
    -- Personal display.
    self.personalIcon = self.script:CreateAnimatedGraphicItem()
    self.personalIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.personalIcon:SetTexture(kPresIcons[style.textureSet])
    self.background:AddChild(self.personalIcon)
    
    self.personalText = self.script:CreateAnimatedTextItem()
    self.personalText:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.personalText:SetTextAlignmentX(GUIItem.Align_Max)
    self.personalText:SetTextAlignmentY(GUIItem.Align_Center)
    self.personalText:SetColor(style.textColor)
    self.personalText:SetFontIsBold(true)
    self.personalText:SetFontName(GUIPlayerResource.kTextFontName)
    self.background:AddChild(self.personalText)
    
    self.pResDescription = self.script:CreateAnimatedTextItem()
    self.pResDescription:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.pResDescription:SetTextAlignmentX(GUIItem.Align_Min)
    self.pResDescription:SetTextAlignmentY(GUIItem.Align_Center)
    self.pResDescription:SetColor(style.textColor)
    self.pResDescription:SetFontIsBold(true)
    self.pResDescription:SetFontName(GUIPlayerResource.kTextFontName)
    self.pResDescription:SetText(Locale.ResolveString("RESOURCES"))
    self.background:AddChild(self.pResDescription)


--     elf.frontBackground = self.script:CreateAnimatedGraphicItem()
--     self.frontBackground:SetAnchor(GUIItem.Center, GUIItem.Bottom)
--     self.frontBackground:SetTexture(kBackgroundTextures[style.textureSet])
--     self.frontBackground:AddAsChildTo(self.frame)
--
--     self.siegeBackground = self.script:CreateAnimatedGraphicItem()
--     self.siegeBackground:SetAnchor(GUIItem.Center, GUIItem.Bottom)
--     self.siegeBackground:SetTexture(kBackgroundTextures[style.textureSet])
--     self.siegeBackground:AddAsChildTo(self.frame)
--
--     self.sideBackground = self.script:CreateAnimatedGraphicItem()
--     self.sideBackground:SetAnchor(GUIItem.Center, GUIItem.Bottom)
--     self.sideBackground:SetTexture(kBackgroundTextures[style.textureSet])
--     self.sideBackground:AddAsChildTo(self.frame)
--
--     /*
--     self.powerBackground = self.script:CreateAnimatedGraphicItem()
--     self.powerBackground:SetAnchor(GUIItem.Center, GUIItem.Bottom)
--     self.powerBackground:SetTexture(kBackgroundTextures[style.textureSet])
--     self.powerBackground:AddAsChildTo(self.frame)
--     */
--
--     self.frontDoor = self.script:CreateAnimatedTextItem()
--     self.frontDoor:SetAnchor(GUIItem.Left, GUIItem.Center)
--     self.frontDoor:SetTextAlignmentX(GUIItem.Align_Max)
--     self.frontDoor:SetTextAlignmentY(GUIItem.Align_Center)
--     self.frontDoor:SetColor(style.textColor)
--     self.frontDoor:SetFontIsBold(true)
--     self.frontDoor:SetFontName(GUIPlayerResource.kTextFontName)
--     self.frontBackground:AddChild(self.frontDoor)
--
--     self.siegeDoor = self.script:CreateAnimatedTextItem()
--     self.siegeDoor:SetAnchor(GUIItem.Left, GUIItem.Center)
--     self.siegeDoor:SetTextAlignmentX(GUIItem.Align_Max)
--     self.siegeDoor:SetTextAlignmentY(GUIItem.Align_Center)
--     self.siegeDoor:SetColor(style.textColor)
--     self.siegeDoor:SetFontIsBold(true)
--     self.siegeDoor:SetFontName(GUIPlayerResource.kTextFontName)
--     self.siegeBackground:AddChild(self.siegeDoor)
--
--     self.sideDoor = self.script:CreateAnimatedTextItem()
--     self.sideDoor:SetAnchor(GUIItem.Left, GUIItem.Center)
--     self.sideDoor:SetTextAlignmentX(GUIItem.Align_Max)
--     self.sideDoor:SetTextAlignmentY(GUIItem.Align_Center)
--     self.sideDoor:SetColor(style.textColor)
--     self.sideDoor:SetFontIsBold(true)
--     self.sideDoor:SetFontName(GUIPlayerResource.kTextFontName)
--     self.sideBackground:AddChild(self.sideDoor)

   -- /*
--     self.powerTxt = self.script:CreateAnimatedTextItem()
--     self.powerTxt:SetAnchor(GUIItem.Left, GUIItem.Center)
--     self.powerTxt:SetTextAlignmentX(GUIItem.Align_Max)
--     self.powerTxt:SetTextAlignmentY(GUIItem.Align_Center)
--     self.powerTxt:SetColor(style.textColor)
--     self.powerTxt:SetFontIsBold(true)
--     self.powerTxt:SetFontName(GUIPlayerResource.kTextFontName)
--     self.powerBackground:AddChild(self.powerTxt)
    --*/


    
end

function GUIPlayerResource:Reset(scale)

    self.scale = scale

    self.background:SetUniformScale(self.scale)
    self.background:SetPosition(GUIPlayerResource.kBackgroundPos)
    self.background:SetSize(GUIPlayerResource.kBackgroundSize)
    
    self.personalIcon:SetUniformScale(self.scale)
    self.personalIcon:SetSize(Vector(GUIPlayerResource.kPersonalResourceIcon.Width, GUIPlayerResource.kPersonalResourceIcon.Height, 0))
    self.personalIcon:SetPosition(GUIPlayerResource.kPersonalIconPos)
    
    self.personalText:SetScale(Vector(1,1,1) * self.scale * 1.2)
    self.personalText:SetFontSize(GUIPlayerResource.kFontSizePersonal)
    self.personalText:SetPosition(GUIPlayerResource.kPersonalTextPos)
    self.personalText:SetFontName(GUIPlayerResource.kTextFontName)
    GUIMakeFontScale(self.personalText)
   
    self.pResDescription:SetScale(Vector(1,1,1) * self.scale * 1.2)
    self.pResDescription:SetFontSize(GUIPlayerResource.kFontSizePresDescription)
    self.pResDescription:SetPosition(GUIPlayerResource.kPresDescriptionPos)
    self.pResDescription:SetFontName(GUIPlayerResource.kTextFontName)
    GUIMakeFontScale(self.pResDescription)


--      self.frontBackground:SetUniformScale(self.scale)
--         self.frontBackground:SetPosition(GUIPlayerResource.kFrontTimeBackgroundPos)
--         self.frontBackground:SetSize(GUIPlayerResource.kFrontTimeBackgroundSize)
--
--         self.siegeBackground:SetUniformScale(self.scale)
--         self.siegeBackground:SetPosition(GUIPlayerResource.kSiegeTimeBackgroundPos)
--         self.siegeBackground:SetSize(GUIPlayerResource.kSiegeTimeBackgroundSize)
--
--         self.sideBackground:SetUniformScale(self.scale)
--         self.sideBackground:SetPosition(GUIPlayerResource.kSideTimeBackgroundPos)
--         self.sideBackground:SetSize(GUIPlayerResource.kSideTimeBackgroundSize)
--
--         /*
--         self.powerBackground:SetUniformScale(self.scale)
--         self.powerBackground:SetPosition(GUIPlayerResource.kPowerBackgroundPos)
--         self.powerBackground:SetSize(GUIPlayerResource.kPowerBackgroundSize)
--         */
--
--         self.frontDoor:SetScale(Vector(1,1,1) * self.scale * 1.0)
--         self.frontDoor:SetFontSize(GUIPlayerResource.kFontSizePersonal)
--         self.frontDoor:SetPosition(pos)
--         self.frontDoor:SetFontName(GUIPlayerResource.kTextFontName)
--         GUIMakeFontScale(self.frontDoor)
--
--         self.siegeDoor:SetScale(Vector(1,1,1) * self.scale * 1.0)
--         self.siegeDoor:SetFontSize(GUIPlayerResource.kFontSizePersonal)
--         self.siegeDoor:SetPosition(posTwo)
--         self.siegeDoor:SetFontName(GUIPlayerResource.kTextFontName)
--         GUIMakeFontScale(self.siegeDoor)
--
--         self.sideDoor:SetScale(Vector(1,1,1) * self.scale * 1.0)
--         self.sideDoor:SetFontSize(GUIPlayerResource.kFontSizePersonal)
--         self.sideDoor:SetPosition(posTwo)
--         self.sideDoor:SetFontName(GUIPlayerResource.kTextFontName)
--         GUIMakeFontScale(self.sideDoor)
--
--         /*
--         self.powerTxt:SetScale(Vector(1,1,1) * self.scale * 1.0)
--         self.powerTxt:SetFontSize(GUIPlayerResource.kFontSizePersonal)
--         self.powerTxt:SetPosition(posTwo)
--         self.powerTxt:SetFontName(GUIPlayerResource.kTextFontName)
--         GUIMakeFontScale(self.powerTxt)
--         */


end

function GUIPlayerResource:Update(_, parameters)

    PROFILE("GUIPlayerResource:Update")

    local newHudDetail = Client.GetHudDetail()
    if self.cachedHudDetail ~= newHudDetail then
        self.cachedHudDetail = newHudDetail
        local minimal = self.cachedHudDetail == kHUDMode.Minimal
        self.background:SetColor(Color(1,1,1,ConditionalValue(minimal, 0, 1)))
    end
    
    local tRes, pRes, numRTs = parameters[1], parameters[2], parameters[3]
    
    self.personalText:SetText(ToString(math.floor(pRes * 10) / 10))
    if pRes > self.lastPersonalResources then
        
        self.lastPersonalResources = pRes
        self.pulseLeft = 1
        
        self.personalText:SetFontSize(GUIPlayerResource.kFontSizePersonalBig)
        self.personalText:SetFontSize(GUIPlayerResource.kFontSizePersonal, GUIPlayerResource.kPulseTime, "RES_PULSATE")
        self.personalText:SetColor(Color(1,1,1,1))
        self.personalText:SetColor(self.style.textColor, GUIPlayerResource.kPulseTime)
        
        self.personalIcon:DestroyAnimations()
        self.personalIcon:SetSize(GUIPlayerResource.kPersonalResourceIconSizeBig)
        self.personalIcon:SetSize(GUIPlayerResource.kPersonalResourceIconSize, GUIPlayerResource.kPulseTime,  nil, AnimateQuadratic)
        
    end

end

function GUIPlayerResource:OnAnimationCompleted(animatedItem, animationName, itemHandle)

    if animationName == "RES_PULSATE" then
    
        if self.pulseLeft > 0 then
        
            self.personalText:SetFontSize(GUIPlayerResource.kFontSizePersonalBig)
            self.personalText:SetFontSize(GUIPlayerResource.kFontSizePersonal, GUIPlayerResource.kPulseTime, "RES_PULSATE", AnimateQuadratic)
            self.personalText:SetColor(Color(1, 1, 1, 1))
            self.personalText:SetColor(self.style.textColor, GUIPlayerResource.kPulseTime)
            
            self.personalIcon:DestroyAnimations()
            self.personalIcon:SetSize(GUIPlayerResource.kPersonalResourceIconSizeBig)
            self.personalIcon:SetSize(GUIPlayerResource.kPersonalResourceIconSize, GUIPlayerResource.kPulseTime,  nil, AnimateQuadratic)
            
            self.pulseLeft = self.pulseLeft - 1
            
        end
        
    end
    
end

function GUIPlayerResource:Destroy()
end

-- function GUIPlayerResource:UpdateFrontSiege(_, parameters)
--      local activePower, gLength, fLength, sLength, ssLength, adjustment = parameters[1],  parameters[2], parameters[3], parameters[4],  parameters[5], parameters[6]
--
--         local frontRemain = Clamp(fLength - gLength, 0, fLength)
--         local Frontminutes = math.floor( frontRemain / 60 )
--         local Frontseconds = math.floor( frontRemain - Frontminutes * 60 )
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


--end