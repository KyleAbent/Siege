-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/DebugGUI/GBDDetailsSectionHeader.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
--  Header for a collapseable section. The part that is always shown and used to collapse/expand
--  the "contents" part of the section.
--
--  Parameters (* = requried)
--      label*  = section name of the section. The text that gets displayed on the header.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/menu2/GUIMenuBasicBox.lua")
Script.Load("lua/menu2/widgets/GUIMenuExpansionArrowWidget.lua")

local kLabelFont = ReadOnly({family = "Agency", size = 35})

---@class GBDDetailsSectionHeader : GUIMenuBasicBox
local baseClass = GUIMenuBasicBox
class "GBDDetailsSectionHeader" (baseClass)

GBDDetailsSectionHeader:AddClassProperty("Expanded", true)
GBDDetailsSectionHeader:AddClassProperty("SectionName", "No Name")
GBDDetailsSectionHeader:AddCompositeClassProperty("HeaderText", "label", "Text")

function GBDDetailsSectionHeader:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:SetStrokeColor(Color(0.2, 0.2, 0.2, 0.3))

    self.arrow = CreateGUIObject("arrow", GUIMenuExpansionArrowWidget, self)
    self.arrow:AlignLeft()

    self.label = CreateGUIObject("label", GUIText, self)
    self.label:SetFont(kLabelFont)
    self.label:AlignLeft()
    self.label:SetX(self.arrow:GetSize().x + self.arrow:GetPosition().x)

    self.button = CreateGUIObject("button", GUIButton, self)
    self.button:SetSyncToParentSize(true)
    self:ForwardEvent(self.button, "OnPressed")

    self:HookEvent(self, "OnExpandedChanged", self.OnExpandedChanged)
    self:OnExpandedChanged(self:GetExpanded())

    self:SetHeight(math.max(self.arrow:GetSize().y, self.button:GetSize().y))

end

function GBDDetailsSectionHeader:OnExpandedChanged(newExpanded)
    if newExpanded then
        self.arrow:PointUp()
    else
        self.arrow:PointDown()
    end
end