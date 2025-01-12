-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GMTDRewardsScreenOverlay.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Overlays the Rewards Screen and tells player they need to complete tutorial missions first if needed.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/style/GUIStyledText.lua")

local kArrowAnimationDistance = 200
local kArrowStartX = -80

local kArrowAnimation = ReadOnly
{
    cycleTime = 2,

    func = function(obj, time, params, currentValue, startValue, endValue, startTime)

        local currentCyclePercent = (time % params.cycleTime) / params.cycleTime
        local posPercent = (currentCyclePercent / 2) / 0.5

        if currentCyclePercent > 0.5 then
            posPercent = 1 - (posPercent - math.floor(posPercent))
        end

        return Vector(LerpNumber(startValue.x, endValue.x, posPercent), 0, 0), false

    end
}

local baseClass = GUIObject
---@class GMTDRewardsScreenOverlay : GUIObject
class "GMTDRewardsScreenOverlay" (baseClass)

GMTDRewardsScreenOverlay.kArrowTexture = PrecacheAsset("ui/thunderdome_rewards/locked_arrow.dds")

function GMTDRewardsScreenOverlay:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:SetSyncToParentSize(true)
    self:ListenForWheelInteractions() -- block wheel to stop scroll pane in rewards screen from moving while it should be blocked.
    self:AlignCenter()

    self:SetColor(0, 0, 0, 0.85)
    self:SetVisible(false)

    self.lockedText = CreateGUIObject("label", GUIStyledText, self,
    {
        style = MenuStyle.kThunderdomeRewardsOverlayText,
        font = MenuStyle.kRewardsOverlayTextFont,
        align = "left",
    })

    self.lockedText:SetX(200)
    self.lockedText:SetText(Locale.ResolveString("THUNDERDOME_REWARDS_LOCKED_TEXT"))

    self.arrow = CreateGUIObject("arrow", GUIObject, self.lockedText)
    self.arrow:SetAnchor(1.0, 0.5)
    self.arrow:SetHotSpot(0, 0.5)
    self.arrow:SetTexture(self.kArrowTexture)
    self.arrow:SetSizeFromTexture()
    self.arrow:SetColor(1,1,1)
    self.arrow:SetX(kArrowStartX)

    self:HookEvent(self, "OnVisibleChanged", self.OnVisibleChanged)

end

function GMTDRewardsScreenOverlay:OnVisibleChanged()
    self.arrow:ClearPropertyAnimations("Position")
    self.arrow:SetPosition(0,0)
    if self:GetVisible() then
        self.arrow:AnimateProperty("Position", Vector(kArrowAnimationDistance, 0, 0), kArrowAnimation)
    end
end
