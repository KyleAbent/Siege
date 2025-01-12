-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/NavBar/Screens/PlayList/GUIMenuListItemSticker.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--  Text with a background that is meant to be used for the main menu list items, for example putting "BETA" after one of the buttons.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIText.lua")

class "GUIMenuListItemSticker" (GUIObject)

GUIMenuListItemSticker:AddCompositeClassProperty("Label", "label", "Text")

GUIMenuListItemSticker.kLabelPadding = 5

function GUIMenuListItemSticker:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.label = CreateGUIObject("stickerLabel", GUIText, self)
    self.label:SetFont("AgencyBold", 30)
    self.label:AlignCenter()

    self:SetColor(HexToColor("666E80"))

    self:HookEvent(self.label, "OnSizeChanged", self.OnTextSizeChanged)
    self:OnTextSizeChanged()

end

function GUIMenuListItemSticker:OnTextSizeChanged()
    self:SetSize(self.label:GetSize() + Vector(self.kLabelPadding * 2, 0, 0))
end