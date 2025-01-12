-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDLifeformProfile.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/widgets/GUIButton.lua")

local function GetPixelCoordinatesForLifeform(lifeform)

    local size = 96
    local atlasIndex = kLobbyLifeformTypes[lifeform] - 1

    local startX = size * atlasIndex
    local startY = 0

    local endX = startX + size
    local endY = size

    return startX, startY, endX, endY

end

local function OnLifeformChanged(self, newValue)
    self:SetTexturePixelCoordinates(GetPixelCoordinatesForLifeform(newValue))
end

local function OnSelectedChanged(self, newValue)
    self:SetColor(ConditionalValue(newValue, self.kLifeformProfileColor_Selected, self.kLifeformProfileColor_Unselected))
end

local function OnPressed(self)
    self:FireEvent("OnLifeformSelected", self)
end

local function OnBlinkingChanged(self, newBlink)
    if newBlink then
        self:AnimateProperty("Color", nil, MenuAnimations.TDLerpLifeformColor)
    else
        self:ClearPropertyAnimations("Color")
    end
end

class "GMTDLifeformProfile" (GUIButton)

GMTDLifeformProfile:AddClassProperty("Lifeform", "")
GMTDLifeformProfile:AddClassProperty("Selected", false)
GMTDLifeformProfile:AddClassProperty("Blinking", false)

GMTDLifeformProfile.kLifeformProfilesTexture = PrecacheAsset("ui/thunderdome/planning_lifeform_select.dds")
GMTDLifeformProfile.kDefaultSize = Vector(96, 96, 0) -- size of texture (one piece of it)

GMTDLifeformProfile.kLifeformProfileColor_Selected   = ColorFrom255(211, 159, 58)
GMTDLifeformProfile.kLifeformProfileColor_Unselected = ColorFrom255(88, 87, 87)

function GMTDLifeformProfile:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIButton.Initialize(self, params, errorDepth)

    self:SetTexture(self.kLifeformProfilesTexture)
    self:SetSize(self.kDefaultSize)
    self:SetColor(self.kLifeformProfileColor_Unselected)

    self:HookEvent(self, "OnLifeformChanged", OnLifeformChanged)
    self:HookEvent(self, "OnSelectedChanged", OnSelectedChanged)
    self:HookEvent(self, "OnPressed", OnPressed)
    self:HookEvent(self, "OnBlinkingChanged", OnBlinkingChanged)

end
