-- ======= Copyright (c) 2017, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/NavBar/Screens/PlayList/GUIMenuQuickPlayListItem.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Big, flashy, quick-play variant of the play list item, for the "play" menu from the nav bar drop down.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/NavBar/Screens/PlayList/GUIMenuPlayListItem.lua")

Script.Load("lua/menu2/MenuUtilities.lua")
Script.Load("lua/menu2/MenuStyles.lua")
Script.Load("lua/menu2/widgets/GUIMenuGlowyText.lua")

---@class GUIMenuPlayListThunderdomeItem : GUIMenuPlayListItem
class 'GUIMenuPlayListThunderdomeItem' (GUIMenuPlayListItem)

GUIMenuPlayListThunderdomeItem.kFont = MenuStyle.kPlayMatchMakingFont

local function On_FlashChanged(self, value)
    self.hoverText:SetFloatParameter("multAmount", 2*value+1)
    self.hoverText:SetFloatParameter("screenAmount", 2*value)
end

local function On_HoverOpacityChanged(self, value)
    self.hoverText:SetOpacity(value)
    self:SetOpacity(value)
end

local function UpdateTextHolderSize(self)
    self.textHolder:SetSize(self.nonHoverText:GetSize() * self.nonHoverText:GetScale())
end

local function OnFXStateChanged(self, state, prevState)
    if state == "disabled" then
        self.nonHoverText:SetStyle(MenuStyle.kMainBarDisabledButtonText)
        self.hoverText:SetStyle(MenuStyle.kMainBarDisabledButtonText)
    end
end

function GUIMenuPlayListThunderdomeItem:CreateVisuals()
    
    self:SetTexture(self.kBackTexture)
    self:SetSizeFromTexture()
    self:SetColor(1, 1, 1, 0)
    self:SetShader(self.kFlashShader)
    
    self.textHolder = self:CreateLocatorGUIItem()
    self.textHolder:SetPosition(self.kTextPosition)
    self.textHolder:AlignLeft()
    
    self.nonHoverText = CreateGUIObject("nonHoverText", GUIStyledText, self.textHolder)
    self.nonHoverText:SetLayer(1)
    self.nonHoverText:AlignCenter()
    self.nonHoverText:SetFont(self.kFont)
    self.nonHoverText:SetStyle(MenuStyle.kMainBarButtonText)
    
    self.hoverText = CreateGUIObject("hoverText", GUIMenuGlowyText, self.textHolder)
    self.hoverText:SetLayer(1)
    self.hoverText:AlignCenter()
    self.hoverText:SetFont(self.kFont)
    self.hoverText:SetStyle(MenuStyle.kMainBarButtonGlow)
    self.hoverText:SetOpacity(0.0)
    self:AddFXReceiver(self.hoverText)
    
    self:HookEvent(self.nonHoverText, "OnScaleChanged", UpdateTextHolderSize)
    self:HookEvent(self.nonHoverText, "OnSizeChanged", UpdateTextHolderSize)
    
    self:HookEvent(self, "OnTextChanged", self.OnTextChanged)
    self:HookEvent(self, "OnFlashChanged", On_FlashChanged)
    self:HookEvent(self, "OnHoverOpacityChanged", On_HoverOpacityChanged)
    self:HookEvent(self, "OnFXStateChanged", OnFXStateChanged)
    
end

function GUIMenuPlayListThunderdomeItem:OnTextChanged(text)
    self.hoverText:SetText(text)
    self.nonHoverText:SetText(text)
end
