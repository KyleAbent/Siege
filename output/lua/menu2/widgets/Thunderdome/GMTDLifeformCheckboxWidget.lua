-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDLifeformCheckboxWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


Script.Load("lua/GUI/widgets/GUICheckboxWidget.lua")

local baseClass = GUICheckboxWidget
class "GMTDLifeformCheckboxWidget" (baseClass)

GMTDLifeformCheckboxWidget.kCheckboxTexture = PrecacheAsset("ui/thunderdome/lifeform_checkbox.dds")
GMTDLifeformCheckboxWidget.kCheckboxTextureSize = Vector(55, 53, 0)

local function GetPixelCoordsForCheckboxValue(self)

    local value = self:GetValue()
    local yIndex = (value and 1 or 0)
    local pixelsInBetween = 10 * (yIndex + 1) -- Space on top and bottom of each texture.

    local xStart = 0
    local yStart = (self.kCheckboxTextureSize.y * yIndex) + pixelsInBetween

    local xEnd = self.kCheckboxTextureSize.x
    local yEnd = yStart + self.kCheckboxTextureSize.y

    return xStart, yStart, xEnd, yEnd

end

local function OnValueChanged(self)
    self:SetTexturePixelCoordinates(GetPixelCoordsForCheckboxValue(self))
end

function GMTDLifeformCheckboxWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:SetSize(self.kCheckboxTextureSize)
    self:SetTexture(self.kCheckboxTexture)
    self:SetColor(1,1,1)

    self:HookEvent(self, "OnValueChanged", OnValueChanged)
    OnValueChanged(self)

end
