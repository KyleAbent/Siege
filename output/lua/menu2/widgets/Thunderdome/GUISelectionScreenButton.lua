-- ======= Copyright (c) 2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GUISelectionScreenButton.lua
--
--    Created by:   Brock Gillespie
--
--  Parameters (* = required)
--      label
--
--  Properties
--      Label       Text label for this button
--  
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/wrappers/FXState.lua")
Script.Load("lua/GUI/wrappers/CursorInteractable.lua")



local kButtonTextFontSize = 58
local kLabelVertOffset = 230

local kHoverBg = PrecacheAsset("ui/thunderdome/selectscreen_active_btn_highlite.dds")

local kNormalColor = Color( 1, 1, 1 )
local kInactiveColor = Color( 0.3, 0.3, 0.3, 0.3 )

---@class GUISelectionScreenButton : GUIButton
---@field public GetFXState function @From FXState wrapper
---@field public UpdateFXStateOverride function @From FXState wrapper
---@field public AddFXReceiver function @From FXState wrapper
---@field public RemoveFXReceiver function @From FXState wrapper
local baseClass = GUIObject
baseClass = GetFXStateWrappedClass(baseClass)
baseClass = GetTooltipWrappedClass(baseClass)
baseClass = GetCursorInteractableWrappedClass(baseClass)
class "GUISelectionScreenButton" (baseClass)

GUISelectionScreenButton:AddCompositeClassProperty("Label", "label", "Text")

GUISelectionScreenButton.kButtonTypes = enum({'Search', 'Group', 'Private'})


function GUISelectionScreenButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    RequireType({"string", "nil"}, params.label, "params.label", errorDepth)
    RequireType({"string", "nil"}, params.icon, "params.icon", errorDepth)
    RequireType({"string", "nil"}, params.activeIcon, "params.activeIcon", errorDepth)
    RequireType({"Vector", "nil"}, params.iconSize, "params.iconSize", errorDepth)
    RequireType({"Vector", "nil"}, params.buttonSize, "params.buttonSize", errorDepth)
    RequireType({"number", "nil"}, params.modeFlag, "params.modeFlag", errorDepth)

    baseClass.Initialize(self, params, errorDepth)

    self:SetSize( params.buttonSize )

    self.modeButtonType = params.modeFlag

    self.label = CreateGUIObject( "label", GUIText, self, nil, errorDepth )
    self.label:SetFont( "Agency", kButtonTextFontSize )
    self.label:SetColor( Color(0.8, 0.8, 0.8,0.8) )
    self.label:SetText( params.label )
    self.label:AlignBottom()

    self.icon = CreateGUIObject( "icon", GUIGraphic, self, nil, errorDepth )
    self.icon:AlignCenter()
    self.icon:SetTexture(params.icon)
    self.icon:SetSize( params.iconSize )

    self.iconActive = CreateGUIObject( "iconActive", GUIGraphic, self, nil, errorDepth )
    self.iconActive:AlignCenter()
    self.iconActive:SetTexture(params.activeIcon)
    self.iconActive:SetSize( params.iconSize )
    self.iconActive:SetVisible(false)

    self.hoverBg = CreateGUIObject( "buttonHoverBg", GUIGraphic, self, nil, errorDepth )
    self.hoverBg:AlignCenter()
    self.hoverBg:SetSize( params.buttonSize + 80 )
    self.hoverBg:SetPosition( 0, 50 )
    self.hoverBg:SetTexture( kHoverBg )
    self.hoverBg:SetColor( Color(1,1,1,0.2) )
    self.hoverBg:SetVisible(false)

    self.targetScreen = nil

    self:HookEvent(self, "OnPressed", self.OnPressed)

    self:HookEvent(self, "OnMouseOverChanged", self.OnHoverChanged)
    
    self.disabled = false
    
end

function GUISelectionScreenButton:SetDisabled(enable)

    self.disabled = enable
    self:UpdateColors(self:GetMouseOver())

end

function GUISelectionScreenButton:UpdateColors(hovered)

    if self.disabled then
        self.iconActive:SetVisible(false)
        self.icon:SetVisible(true)
        self.icon:SetColor(kInactiveColor)
    else
        self.iconActive:SetVisible(hovered)
        self.icon:SetVisible(not hovered)
        self.icon:SetColor(kNormalColor)
    end

    self.hoverBg:SetVisible( hovered )

    local modeTipText = self:GetParent():GetParent().modeTipText

    if hovered then
        self.label:SetColor( Color(1, 1, 1, 1) )
        if self.modeButtonType == self.kButtonTypes.Search then
            if self.disabled then
                modeTipText:SetText( Locale.ResolveString("THUNDERDOME_MODE_TIP_SEARCH_PENALTY") )
            else
                modeTipText:SetText( Locale.ResolveString("THUNDERDOME_MODE_TIP_SEARCH") )
            end
        elseif self.modeButtonType == self.kButtonTypes.Group then
            if self.disabled then
                modeTipText:SetText( Locale.ResolveString("THUNDERDOME_MODE_TIP_GROUP_PENALTY") )
            else
                modeTipText:SetText( Locale.ResolveString("THUNDERDOME_MODE_TIP_GROUP") )
            end
        elseif self.modeButtonType == self.kButtonTypes.Private then
            modeTipText:SetText( Locale.ResolveString("THUNDERDOME_MODE_TIP_PRIVATE") )
        end
    else
        self.label:SetColor( Color(0.8, 0.8, 0.8,0.8) )
        modeTipText:SetText("")
    end

end

function GUISelectionScreenButton:OnHoverChanged()
    PlayMenuSound("ButtonHover")

    self:UpdateColors(self:GetMouseOver())
end

function GUISelectionScreenButton:SetPressedCallback(callback)
    assert(callback)
    self.pressedCallback = callback
end

function GUISelectionScreenButton:OnPressed()
    assert(self.pressedCallback, "Error: no button pressed callback set")
    PlayMenuSound("ButtonClick")
    self.pressedCallback(self)
end

function GUISelectionScreenButton:GetCanBeDoubleClicked()
    return false
end

function GUISelectionScreenButton:SetTargetScreen(screen)
    assert(screen, "Error: No TD target screen set")
    self.targetScreen = screen
end

