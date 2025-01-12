
-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUICrosshair.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- Manages the crosshairs for aliens and marines.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")
Script.Load("lua/GUIAssets.lua")

class 'GUICrosshair' (GUIAnimatedScript)

local kReloadDialTexture = PrecacheAsset("ui/reload_indicator.dds")

GUICrosshair.kCrosshairSize = 64
GUICrosshair.kCrosshairPos = Vector(-GUICrosshair.kCrosshairSize / 2, -GUICrosshair.kCrosshairSize / 2, 0)

GUICrosshair.kCrosshairScale = GetAdvancedOption("crosshairscale")
GUICrosshair.kReloadIndicatorEnabled = GetAdvancedOption("reloadindicator")
GUICrosshair.kReloadIndicatorColor = GetAdvancedOption("reloadindicatorcolor")

function GUICrosshair:OnResolutionChanged(_, _, _, _)
    self:Uninitialize()
    self:Initialize()
end

function GUICrosshair:Initialize()
    
    GUIAnimatedScript.Initialize(self, kUpdateIntervalFull)

    self.crosshairs = GUIManager:CreateGraphicItem()
    self.crosshairs:SetSize(Vector(GUICrosshair.kCrosshairSize, GUICrosshair.kCrosshairSize, 0) * GUICrosshair.kCrosshairScale)
    self.crosshairs:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.crosshairs:SetPosition(GUICrosshair.kCrosshairPos * GUICrosshair.kCrosshairScale)
    self.crosshairs:SetTexture(Textures.kCrosshairs)
    self.crosshairs:SetIsVisible(false)
    self.crosshairs:SetScale(GetScaledVector())
    self.crosshairs:SetLayer(kGUILayerPlayerHUD)
    
    self.damageIndicator = GUIManager:CreateGraphicItem()
    self.damageIndicator:SetSize(Vector(GUICrosshair.kCrosshairSize, GUICrosshair.kCrosshairSize, 0) * GUICrosshair.kCrosshairScale)
    self.damageIndicator:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.damageIndicator:SetPosition(Vector(0, 0, 0))
    self.damageIndicator:SetTexture(Textures.kCrosshairsHit)
    local yCoord = PlayerUI_GetCrosshairDamageIndicatorY()
    self.damageIndicator:SetTexturePixelCoordinates(0, yCoord, 64, yCoord + 64)
    self.damageIndicator:SetIsVisible(false)
    self.crosshairs:AddChild(self.damageIndicator)

    if GUICrosshair.kReloadIndicatorEnabled then

        --self.updateInterval = 0.004
        --self.noItemsUpdateInterval = 0.004

        local reloadDialSettings = { }
        reloadDialSettings.BackgroundWidth = GUIScale(GUICrosshair.kCrosshairSize) * GUICrosshair.kCrosshairScale
        reloadDialSettings.BackgroundHeight = GUIScale(GUICrosshair.kCrosshairSize) * GUICrosshair.kCrosshairScale
        reloadDialSettings.BackgroundAnchorX = GUIItem.Middle
        reloadDialSettings.BackgroundAnchorY = GUIItem.Center
        reloadDialSettings.BackgroundOffset = GUIScale(Vector(-32, 32, 0)) * GUICrosshair.kCrosshairScale
        reloadDialSettings.BackgroundTextureName = nil
        reloadDialSettings.BackgroundTextureX1 = 0
        reloadDialSettings.BackgroundTextureY1 = 0
        reloadDialSettings.BackgroundTextureX2 = 0
        reloadDialSettings.BackgroundTextureY2 = 0
        reloadDialSettings.ForegroundTextureName = kReloadDialTexture
        reloadDialSettings.ForegroundTextureWidth = 128
        reloadDialSettings.ForegroundTextureHeight = 128
        reloadDialSettings.ForegroundTextureX1 = 0
        reloadDialSettings.ForegroundTextureY1 = 0
        reloadDialSettings.ForegroundTextureX2 = 128
        reloadDialSettings.ForegroundTextureY2 = 128
        reloadDialSettings.InheritParentAlpha = false
        self.reloadDial = GUIDial()
        self.reloadDial:Initialize(reloadDialSettings)
        self.reloadDial:SetIsVisible(false)
        self.reloadDial:GetBackground():SetLayer(kGUILayerPlayerHUD)
        self.reloadDial:GetLeftSide():SetColor(GUICrosshair.kReloadIndicatorColor)
        self.reloadDial:GetRightSide():SetColor(GUICrosshair.kReloadIndicatorColor)

    end
    
    HelpScreen_AddObserver(self)

end

function GUICrosshair:OnHelpScreenVisChange(hsVis)
    
    self.visible_hs = not hsVis -- visible due to help screen?
    self:Update(0)
    
end

function GUICrosshair:Uninitialize()
    
    -- Destroying the crosshair will destroy all it's children too.
    GUI.DestroyItem(self.crosshairs)
    self.crosshairs = nil

    if self.reloadDial then
        self.reloadDial:Uninitialize()
        self.reloadDial = nil
    end
    
    GUIAnimatedScript.Uninitialize(self)
    
    HelpScreen_RemoveObserver(self)
    
end

function GUICrosshair:Update(deltaTime)
    
    PROFILE("GUICrosshair:Update")
    
    GUIAnimatedScript.Update(self, deltaTime)
    self.updateInterval = kUpdateIntervalFull
    
    -- Update crosshair image.
    local xCoord = PlayerUI_GetCrosshairX()
    local yCoord = PlayerUI_GetCrosshairY()
    
    local showCrossHair = not PlayerUI_GetIsDead() and PlayerUI_GetIsPlaying() and not PlayerUI_GetIsThirdperson() and not PlayerUI_IsACommander() and not PlayerUI_GetBuyMenuDisplaying() and not MainMenu_GetIsOpened() and self.visible_hs
                          --and not PlayerUI_GetIsConstructing() and not PlayerUI_GetIsRepairing()
    
    self.crosshairs:SetIsVisible(showCrossHair)
    
    if showCrossHair then
        if xCoord and yCoord then
        
            self.crosshairs:SetTexturePixelCoordinates(xCoord, yCoord,
                                                       xCoord + PlayerUI_GetCrosshairWidth(), yCoord + PlayerUI_GetCrosshairHeight())
            
            self.damageIndicator:SetTexturePixelCoordinates(xCoord, yCoord,
                                                       xCoord + PlayerUI_GetCrosshairWidth(), yCoord + PlayerUI_GetCrosshairHeight())

        end
    end
        
    -- Update give damage indicator.
    local indicatorVisible, timePassedPercent = PlayerUI_GetShowGiveDamageIndicator()
    self.damageIndicator:SetIsVisible(indicatorVisible and showCrossHair)
    self.damageIndicator:SetColor(Color(1, 1, 1, 1 - timePassedPercent))

    -- Update reload dial if enabled
    local reloadFraction = GetReloadFraction()
    if self.reloadDial then

        if showCrossHair and reloadFraction > -1 then

            self.reloadDial:SetIsVisible(showCrossHair)
            self.reloadDial:SetPercentage(reloadFraction)
            self.reloadDial:Update(deltaTime)
        else

            self.reloadDial:SetIsVisible(false)

        end
    end
end
