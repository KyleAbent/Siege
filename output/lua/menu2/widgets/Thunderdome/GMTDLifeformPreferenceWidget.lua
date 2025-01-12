-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDLifeformPreferenceWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--  Events
--      OnLifeformSelectionChanged - When checkbox value changes. No parameters.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kLifeformLabelPaddingLeft = 25

Script.Load("lua/menu2/widgets/Thunderdome/GMTDLifeformCheckboxWidget.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDLifeformProfile.lua")
Script.Load("lua/GUI/widgets/GUIButton.lua")

local baseClass = GUIButton
class "GMTDLifeformPreferenceWidget" (baseClass)

GMTDLifeformPreferenceWidget:AddClassProperty("Lifeform", "")
GMTDLifeformPreferenceWidget:AddClassProperty("Padding", 125)
GMTDLifeformPreferenceWidget:AddCompositeClassProperty("Value", "checkbox")
GMTDLifeformPreferenceWidget:AddCompositeClassProperty("LifeformIconSize", "lifeformProfile", "Size")

local function UpdateSize(self)

    local lifeformSize = self.lifeformProfile:GetSize()
    local totalHeight = math.max(lifeformSize.y, self.checkbox:GetSize().y, self.lifeformLabel:GetSize().y)

    -- Update Alignment of all our objects
    local x = self.lifeformProfile:GetSize().x + self:GetPadding()
    self.checkbox:SetPosition(x, 0)

    x = x + self.checkbox:GetSize().x + kLifeformLabelPaddingLeft
    self.lifeformLabel:SetPosition(x , 0)

    self:SetSize(x + self.lifeformLabel:GetSize().x, totalHeight)

end

local function OnCheckboxValueChanged(self, newValue)

    self.lifeformProfile:SetSelected(newValue)
    self.lifeformLabel:SetColor(self.lifeformProfile:GetColor())
    self:FireEvent("OnLifeformSelectionChanged", self:GetLifeform(), newValue)

end

function GMTDLifeformPreferenceWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self.lifeformProfile = CreateGUIObject("lifeformProfile", GMTDLifeformProfile, self, params, errorDepth)
    self.lifeformProfile:AlignLeft()
    self:HookEvent(self.lifeformProfile, "OnSizeChanged", UpdateSize)

    self.checkbox = CreateGUIObject("checkbox", GMTDLifeformCheckboxWidget, self, params, errorDepth)
    self.checkbox:AlignLeft()

    self.lifeformLabel = CreateGUIObject("lifeformLabel", GUIText, self, params, errorDepth)
    self.lifeformLabel:AlignLeft()
    self.lifeformLabel:SetFont("Agency", 45)
    self.lifeformLabel:SetText("Lifeform")

    self:HookEvent(self.checkbox, "OnValueChanged", OnCheckboxValueChanged)
    OnCheckboxValueChanged(self, self:GetValue())

    self:HookEvent(self, "OnLifeformChanged", self.OnLifeformChanged)
    self:HookEvent(self, "OnPaddingChanged", UpdateSize)
    self:HookEvent(self, "OnLifeformIconSizeChanged", UpdateSize)
    self:HookEvent(self, "OnPressed", self.OnPressed)
    UpdateSize(self)

end

function GMTDLifeformPreferenceWidget:OnPressed()
    self.checkbox:SetValue(not self.checkbox:GetValue())
end

local kTDLifeformsLocales =
{
    [kLobbyLifeformTypes[kLobbyLifeformTypes.Skulk]] = "SKULK",
    [kLobbyLifeformTypes[kLobbyLifeformTypes.Gorge]] = "GORGE",
    [kLobbyLifeformTypes[kLobbyLifeformTypes.Lerk ]] = "LERK",
    [kLobbyLifeformTypes[kLobbyLifeformTypes.Fade ]] = "FADE",
    [kLobbyLifeformTypes[kLobbyLifeformTypes.Onos ]] = "ONOS",
}

function GMTDLifeformPreferenceWidget:OnLifeformChanged()

    local lifeform = self:GetLifeform()
    self.lifeformProfile:SetLifeform(lifeform)
    self.lifeformLabel:SetText(Locale.ResolveString(kTDLifeformsLocales[lifeform]))
    UpdateSize(self)

end
