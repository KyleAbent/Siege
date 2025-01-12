-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/PlayerScreen/CallingCards/GUIMenuCallingCard.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Represents a calling card in the calling card customizer contents.
--
--  Parameters (* = required)
--
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/menu2/GUIMenuBasicBox.lua")
Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/GUI/wrappers/FXState.lua")
Script.Load("lua/menu2/wrappers/Tooltip.lua")

local kDefaultSize = Vector(270, 270, 0)
local kLockedTexture = PrecacheAsset("ui/callingcards/locked_overlay.dds")

local function OnFXStateChanged(self, state, prevState)

    if state == "pressed" then
        self:ClearPropertyAnimations("StrokeWidth")
        self:SetStrokeWidth(MenuStyle.kStrokeWidth)
        self:ClearPropertyAnimations("StrokeColor")
        self:SetStrokeColor((MenuStyle.kHighlight + MenuStyle.kBasicStrokeColor)*0.5)
    elseif state == "hover" then
        if prevState == "pressed" then
            self:AnimateProperty("StrokeWidth", 3, MenuAnimations.Fade)
            self:AnimateProperty("StrokeColor", MenuStyle.kHighlight, MenuAnimations.Fade)
        else
            PlayMenuSound("ButtonHover")
            DoColorFlashEffect(self, "StrokeColor")
            self:ClearPropertyAnimations("StrokeWidth")
            self:SetStrokeWidth(2)
        end
    else -- default or disabled (which isn't used).
        self:AnimateProperty("StrokeWidth", MenuStyle.kStrokeWidth, MenuAnimations.Fade)
        self:AnimateProperty("StrokeColor", MenuStyle.kBasicStrokeColor, MenuAnimations.Fade)
    end

end

local buttonClass = GUIButton
buttonClass = GetFXStateWrappedClass(buttonClass)
buttonClass = GetTooltipWrappedClass(buttonClass)

local baseClass = GUIMenuBasicBox
class "GUIMenuCallingCard" (baseClass)

GUIMenuCallingCard:AddClassProperty("CardID", kDefaultPlayerCallingCard)

function GUIMenuCallingCard:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:SetSize(kDefaultSize)

    self.button = CreateGUIObject("button", buttonClass, self)
    self.button:SetSyncToParentSize(true)
    self.button:AlignCenter()
    self.button:SetColor(1,1,1)

    self.lockedOverlay = CreateGUIObject("lockedOverlay", GUIObject, self)
    self.lockedOverlay:SetSyncToParentSize(true)
    self.lockedOverlay:AlignCenter()
    self.lockedOverlay:SetColor(1,1,1)
    self.lockedOverlay:SetTexture(kLockedTexture)

    self:HookEvent(self, "OnCardIDChanged", self.OnCardIDChanged)
    self:OnCardIDChanged(kDefaultPlayerCallingCard)

    self:HookEvent(self.button, "OnFXStateChanged", OnFXStateChanged)
    self:HookEvent(self.button, "OnPressed", self.OnPressed)

end

function GUIMenuCallingCard:GetButtonObj()
    return self.button
end

local kTooltipExtra = Locale.ResolveString("CALLINGCARD_TOOLTIP_EXTRA")
local kTooltipShouldPatchExtra = Locale.ResolveString("CALLINGCARD_TOOLTIP_EXTRASHOULDERPATCH")
function GUIMenuCallingCard:OnCardIDChanged(newCardID)

    local isUnlocked = GetIsCallingCardUnlocked(newCardID)

    local cardData = GetCallingCardTextureDetails(newCardID)
    if cardData then
        self.button:SetTexture(cardData.texture)
        self.button:SetTexturePixelCoordinates(cardData.texCoords)
        self.button:SetColor(1,1,1)

        local tooltipId = GetCallingCardUnlockedTooltipIdentifier(newCardID)
        assert(tooltipId)

        local extraStr = ""
        if not isUnlocked then

            local lockedTooltipOverride = GetCallingCardLockedTooltipIdentifierOverride(newCardID)
            if lockedTooltipOverride then
                tooltipId = lockedTooltipOverride
            else
                extraStr = string.format(" (%s)", kTooltipExtra)
                if GetIsCallingCardShoulderPatch(newCardID) then
                    extraStr = string.format(" (%s)", kTooltipShouldPatchExtra)
                end
            end

        end

        self.button:SetTooltip(string.format("%s%s", Locale.ResolveString(tooltipId), extraStr))

    end

    self.lockedOverlay:SetVisible(not isUnlocked)

end

function GUIMenuCallingCard:OnPressed()
    if GetIsCallingCardUnlocked(self:GetCardID()) then
        PlayMenuSound("ButtonClick")
        self:FireEvent("OnCallingCardSelected", self)
    else
        PlayMenuSound("InvalidSound")
    end
end
