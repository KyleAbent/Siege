-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/DebugGUI/GBDDetailsSection.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
--  A collapsable section of the bot debugging details window.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/bots/DebugGUI/GBDDetailsSectionHeader.lua")
Script.Load("lua/bots/DebugGUI/GBDDetailsSectionContents.lua")

---@class GBDDetailsSection : GUIObject
local baseClass = GUIObject
class "GBDDetailsSection" (baseClass)

GBDDetailsSection:AddCompositeClassProperty("SectionString", "contents")
GBDDetailsSection:AddClassProperty("HeaderText", "")

function GBDDetailsSection:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    RequireType({"string"}, params.headerText, "params.headerText", errorDepth) -- for header title
    RequireType({"string", "nil"}, params.sectionString, "params.sectionString", errorDepth) -- for header title

    self.header = CreateGUIObject("header", GBDDetailsSectionHeader, self, params, errorDepth)
    self.contents = CreateGUIObject("contents", GBDDetailsSectionContents, self, params, errorDepth)

    self.timeLastUpdated = Shared.GetTime()

    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)
    self:HookEvent(self.contents, "OnSizeChanged", self.OnContentsSizeChanged)
    self:HookEvent(self.header, "OnSizeChanged", self.OnContentsSizeChanged)

    self:HookEvent(self.header, "OnPressed", self.OnHeaderPressed)
    self.header:HookEvent(self.contents, "OnExpandedChanged", self.header.SetExpanded)
    self:HookEvent(self.contents, "OnExpandedChanged", self.OnContentsExpandedChanged)

    self:HookEvent(self, "OnSectionStringChanged", self.OnSectionStringChanged)

    if params.headerText then
        self:SetHeaderText(params.headerText)
        self:UpdateHeaderText()
    end

    self.contents:SetY(self.header:GetSize().y)
    self:OnSizeChanged(self:GetSize())

    self.timeCallback = self:AddTimedCallback(self.UpdateHeaderText, 0.5, true)

end

function GBDDetailsSection:Uninitialize()
    self:RemoveTimedCallback(self.timeCallback)
end

function GBDDetailsSection:OnSectionStringChanged()
    self:UpdateHeaderText()
    self.timeLastUpdated = Shared.GetTime()
end

function GBDDetailsSection:UpdateHeaderText()
    local now = Shared.GetTime()
    local timeSinceLastUpdate = now - self.timeLastUpdated
    local newHeader = string.format("%s (t+%d)", self:GetHeaderText(), timeSinceLastUpdate)
    self.header:SetHeaderText(newHeader)
end

function GBDDetailsSection:UpdateSize()

    if self.contents:GetExpanded() then
        self:SetHeight(self.header:GetSize().y + self.contents:GetSize().y)
    else
        self:SetHeight(self.header:GetSize().y)
    end

end

function GBDDetailsSection:OnContentsExpandedChanged(newExpanded)
    self:UpdateSize()
end

function GBDDetailsSection:OnContentsSizeChanged(newSize)
    self:UpdateSize()
end

function GBDDetailsSection:OnHeaderPressed()
    self.contents:SetExpanded(not self.contents:GetExpanded())
end

function GBDDetailsSection:OnSizeChanged(newSize)
    self.header:SetWidth(newSize.x)
    self.contents:SetWidth(newSize.x)
end
