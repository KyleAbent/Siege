-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/GUIMenuTabButtonWidget.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--    
--    Single button designed to fit inside the tab part at the bottom of a GUIMenuTabbedBox.
--@class GUIMenuTabbedBox : GUIObject
--
--  Properties:
--      TabMinWidth         -- The minimum width of the whole tab.
--      TabHeight           -- The height of the tab.  The width is calculated based on the button
--                             labels' sizes.
--      Label               -- The text to display on the left button.
--      Enabled             -- Whether or not the left button is enabled.
--  
--  Events:
--      OnPressed           -- Whenver the button is pressed and released while enabled.
--      OnTabSizeChanged    -- Whenever the derived TabSize has changed.
--    
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/menu2/widgets/GUIMenuShapedButton.lua")
Script.Load("lua/menu2/MenuStyles.lua")

---@class GUIMenuTabButtonWidget : GUIObject
class "GUIMenuTabButtonWidget" (GUIObject)

local kButtonTextPadding = 50 -- empty space on either side of the button.
local kLabelOffsetY = -8

GUIMenuTabButtonWidget:AddClassProperty("TabMinWidth", 400)
GUIMenuTabButtonWidget:AddClassProperty("TabHeight", 100)

GUIMenuTabButtonWidget:AddCompositeClassProperty("Label"  , "button")
GUIMenuTabButtonWidget:AddCompositeClassProperty("Enabled", "button")

local function RecalculateSize(self)

    local buttonTextWidth = self.button.text:GetSize().x
    local tabHeight = self:GetTabHeight()
    local minWidth = self:GetTabMinWidth()

    local numTextPadding = 2
    
    local combinedWidth = buttonTextWidth + kButtonTextPadding * numTextPadding
    local newTotalWidth = math.max(minWidth, combinedWidth)
    local actualPadding = (newTotalWidth - buttonTextWidth) * (1/numTextPadding)
    
    self:SetSize(newTotalWidth + tabHeight * 2, tabHeight)
    
    local actualWidth = buttonTextWidth + actualPadding * 2

    self.button:SetPoints(
    {
        Vector(0, 0, 0),
        Vector(tabHeight, tabHeight, 0),
        Vector(tabHeight + actualWidth, tabHeight, 0),
        Vector(tabHeight + actualWidth, 0, 0),
    })
    
    self.button:SetLabelOffset(tabHeight * 0.5, kLabelOffsetY)

    local prevTabSize = self.tabSize
    local newTabSize = self:GetTabSize()

    if prevTabSize.x ~= newTabSize.x or prevTabSize.y ~= newTabSize.y then
        self.tabSize = newTabSize
        self:FireEvent("OnTabSizeChanged", Vector(self.tabSize), prevTabSize)
    end
    
end

function GUIMenuTabButtonWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    self.tabSize = Vector(-1, -1, 0)
    
    GUIObject.Initialize(self, params, errorDepth)
    
    self.button = CreateGUIObject( "button", GUIMenuShapedButton, self)

    self:ForwardEvent(self.button, "OnPressed", "OnPressed")

    self:HookEvent(self, "OnTabHeightChanged", RecalculateSize)
    self:HookEvent(self, "OnTabMinWidthChanged", RecalculateSize)
    self:HookEvent(self.button.text, "OnSizeChanged", RecalculateSize)

end

function GUIMenuTabButtonWidget:SetFont(font)

    self.button:SetFont(font)

end

function GUIMenuTabButtonWidget:GetTabSize()
    local result = Vector(self:GetSize().x - self:GetTabHeight() * 2, self:GetTabHeight(), 0)
    return result
end
