-- ======= Copyright (c) 2018, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/GUIMenuCheckboxWidgetLabeled.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--    
--    GUIMenuCheckboxWidget that includes a label.
--
--  Properties:
--      Value               -- State of the checkbox, expressed as a number to support partial
--                             states.  0 = unchecked, 1 = checked, anything else is partial.
--      Label               -- Label of this widget.
--  
--  Events:
--      OnPressed           Fires whenever the object is clicked and released on, while enabled.
--    
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/widgets/GUIMenuCheckboxWidget.lua")
Script.Load("lua/menu2/GUIMenuTruncatedText.lua")

---@class GUIMenuCheckboxWidgetLabeled : GUIObject
---@field public GetMouseOver function @From CursorInteractable wrapper
---@field public GetPressed function @From CursorInteractable wrapper
---@field public GetFXState function @From FXState wrapper
---@field public UpdateFXStateOverride function @From FXState wrapper
---@field public AddFXReceiver function @From FXState wrapper
---@field public RemoveFXReceiver function @From FXState wrapper
local baseClass = GUIObject
baseClass = GetCursorInteractableWrappedClass(baseClass)
baseClass = GetFXStateWrappedClass(baseClass)
class "GUIMenuCheckboxWidgetLabeled" (baseClass)

local kMaxLabelWidth = 700

GUIMenuCheckboxWidgetLabeled:AddCompositeClassProperty("Label", "label", "Text")
GUIMenuCheckboxWidgetLabeled:AddCompositeClassProperty("Value", "checkbox")

local function UpdateWidgetSize(self)
    
    -- Update label size
    self.label:SetSize(math.min(self.label:GetTextSize().x, kMaxLabelWidth), self.label:GetTextSize().y)
    
    self:SetSize(GUIMenuCheckboxWidget.kPlainBoxSize.x + MenuStyle.kWidgetPadding * 2 + MenuStyle.kLabelSpacing + self.label:GetSize().x * self.label:GetScale().x, math.max(GUIMenuCheckboxWidget.kPlainBoxSize.y, self.label:GetSize().y * self.label:GetScale().y) + MenuStyle.kWidgetPadding * 2)
end

local function OnResetButtonPressed(self)
    SetWidgetValueToDefault(self)
end

local function UpdateResetButtonFXState(self)

    if not self.resetButton then return end

    self.resetButton:SetEnabled(self.default ~= self:GetValue())

end

function GUIMenuCheckboxWidgetLabeled:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    RequireType({"string", "nil"}, params.label, "params.label", errorDepth)
    
    baseClass.Initialize(self, params, errorDepth)

    local elementX = MenuStyle.kWidgetPadding
    --if params.useResetButton and params.default ~= nil then
    --
    --    self.resetButton = CreateGUIObject("resetButton", GUIResetButton, self, { noAutoConnectToParent = true })
    --    self.resetButton:SetPosition(elementX, 0)
    --    self.resetButton:AlignLeft()
    --
    --    self:HookEvent(self.resetButton, "OnPressed", OnResetButtonPressed)
    --    self:HookEvent(self, "OnValueChanged", UpdateResetButtonFXState)
    --
    --    elementX = elementX + self.resetButton:GetSize().x + MenuStyle.kWidgetPadding
    --
    --end

    -- So default gets init in time for the reset button update.
    self.default = params.default
    
    self.checkbox = CreateGUIObject("checkbox", GUIMenuCheckboxWidget, self,
    {
        cursorController = self,
    })
    self.checkbox:AlignLeft()
    self.checkbox:SetPosition(elementX, 0)
    self.checkbox:StopListeningForCursorInteractions() -- will be forwarded from this object instead.

    elementX = elementX + self.checkbox:GetSize().x + MenuStyle.kWidgetPadding
    
    self.label = CreateGUIObject("label", GUIMenuTruncatedText, self,
    {
        cls = GUIMenuText,
    })
    self:AddFXReceiver(self.label:GetObject())
    
    self.label:SetText("LABEL")
    self.label:SetFont(MenuStyle.kOptionFont)
    self.label:SetColor(MenuStyle.kLightGrey)
    self:HookEvent(self, "OnLabelChanged", UpdateWidgetSize)
    self:HookEvent(self.label, "OnTextSizeChanged", UpdateWidgetSize)
    self.label:AlignLeft()
    self.label:SetPosition(elementX, 0)
    
    if params.label then
        self:SetLabel(params.label)
    end
    
    UpdateWidgetSize(self)
    UpdateResetButtonFXState(self)
    
end

function GUIMenuCheckboxWidgetLabeled:OnMouseRelease()
    baseClass.OnMouseRelease(self)
    self.checkbox:FireEvent("OnPressed")
end

function GUIMenuCheckboxWidgetLabeled:ToggleValue()
    self:SetValue(not self:GetValue())
end

function GUIMenuCheckboxWidgetLabeled:GetValueString(value)
    local result = self.checkbox:GetValueString(value)
    return result
end
