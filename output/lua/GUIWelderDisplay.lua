-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIWelderDisplay.lua
--
-- Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- Displays weld percentage of the current structure.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- Global state that can be externally set to adjust the display.
weldPercentage = 0

welderDisplay  = nil
weaponVariant = 1

Script.Load("lua/GUIScript.lua")
Script.Load("lua/GUIDial.lua")
Script.Load("lua/GUIAssets.lua")

local kHealthCircleWidth = 512
local kHealthCircleHeight = 512
local kArmorCircleSize = Vector(kHealthCircleWidth, kHealthCircleHeight, 0)
local kHealthCircleSize = Vector(kHealthCircleWidth, kHealthCircleHeight, 0)
local kHealthTextureName = Textures.kHealthCircle

--kWelderVariants = enum({ "normal", "kodiak", "tundra", "forge", "sandstorm", "chroma" })
local kTextures = 
{
    "ui/shotgundisplay0.dds",
    "ui/shotgundisplay4.dds",
    "ui/shotgundisplay1.dds",
    "ui/shotgundisplay2.dds",
    "ui/shotgundisplay3.dds",
    "ui/shotgundisplay5.dds",
}

local kSquareTextures =
{
    "ui/WelderSquares.dds",
    "ui/welder_squares_kodiak.dds",
    "ui/welder_squares_tundra.dds",
    "ui/welder_squares_forge.dds",
    "ui/weldersquares1.dds",
    "ui/welder_squares_chroma.dds",
}


class 'GUIWelderDisplay' (GUIScript)

function GUIWelderDisplay:Initialize()

    self.weldPercentage = 0
    self.time = 0

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize( Vector(512, 512, 0) )
    self.background:SetPosition( Vector(0, 0, 0))  
    
    self.squares = GUIManager:CreateGraphicItem()
    self.squares:SetSize( Vector(512, 2560, 0) )
    
    local healthCircleSettings = { }
    healthCircleSettings.BackgroundWidth = kHealthCircleSize.x
    healthCircleSettings.BackgroundHeight = kHealthCircleSize.y
    healthCircleSettings.BackgroundAnchorX = GUIItem.Left
    healthCircleSettings.BackgroundAnchorY = GUIItem.Bottom
    healthCircleSettings.BackgroundOffset = Vector(0, 0, 0)
    healthCircleSettings.BackgroundTextureName = kHealthTextureName
    healthCircleSettings.BackgroundTextureX1 = 0
    healthCircleSettings.BackgroundTextureY1 = 0
    healthCircleSettings.BackgroundTextureX2 = kHealthCircleWidth
    healthCircleSettings.BackgroundTextureY2 = kHealthCircleHeight
    healthCircleSettings.ForegroundTextureName = kHealthTextureName
    healthCircleSettings.ForegroundTextureWidth = kHealthCircleWidth
    healthCircleSettings.ForegroundTextureHeight = kHealthCircleHeight
    healthCircleSettings.ForegroundTextureX1 = kHealthCircleWidth
    healthCircleSettings.ForegroundTextureY1 = 0
    healthCircleSettings.ForegroundTextureX2 = kHealthCircleWidth * 2
    healthCircleSettings.ForegroundTextureY2 = kHealthCircleHeight
    healthCircleSettings.InheritParentAlpha = true
    self.circle = GUIDial()
    self.circle:Initialize(healthCircleSettings)

    -- Slightly larger copy of the text for a glow effect
    self.percentageText = GUIManager:CreateTextItem()
    self.percentageText:SetFontName(Fonts.kAgencyFB_Large_Bold)
    self.percentageText:SetScale(Vector(1,1,1) * 3)
    self.percentageText:SetFontIsBold(true)
    self.percentageText:SetTextAlignmentX(GUIItem.Align_Center)
    self.percentageText:SetTextAlignmentY(GUIItem.Align_Center)
    self.percentageText:SetPosition(Vector(256, 256, 0))
    self.percentageText:SetIsVisible(false)
    self.percentageText:SetColor(Color(1, 1, 1, 1))
    
    -- Force an update so our initial state is correct.
    self:Update(0)

end

function GUIWelderDisplay:Uninitialize()

    if self.circle then
        self.circle:Uninitialize()
        self.circle = nil
    end

end

function GUIWelderDisplay:Update(deltaTime)

    PROFILE("GUIWelderDisplay:Update")
    
    self.time = self.time + deltaTime
    
    -- Update display for skin
    if prevVariant ~= weaponVariant then
        prevVariant = weaponVariant
        self.background:SetTexture(kTextures[weaponVariant])
        self.squares:SetTexture(kSquareTextures[weaponVariant])
    end
    
    -- Update percentage display.
    local isVisible = self.weldPercentage > 0
    self.circle:GetBackground():SetIsVisible(isVisible)
    self.circle:SetPercentage(self.weldPercentage / 100)
    self.circle:Update(deltaTime)
    
    local yPos = 512 - ((self.time % 2) / 2) * (2560 + 256)
    
    self.squares:SetPosition(Vector(0, yPos, 0))
    
    local percentageFormat = string.format("%d%%", math.ceil(self.weldPercentage)) 
    self.percentageText:SetText( percentageFormat )
    
    self.percentageText:SetIsVisible(self.weldPercentage > 0)

end

-- pass 0-1
function GUIWelderDisplay:SetWeldPercentage(percentage)
    self.weldPercentage = percentage
end

--
-- Called by the player to update the components.
--
function Update(deltaTime)

    welderDisplay:SetWeldPercentage(weldPercentage)
    welderDisplay:Update(deltaTime)
    
end

--
-- Initializes the player components.
--
function Initialize()

    GUI.SetSize( 512, 512 )

    welderDisplay = GUIWelderDisplay()
    welderDisplay:Initialize()

end

Initialize()