-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/GUI/widgets/GUIResetButton.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Meant for use with "option" related widgets.
--  
--  Properties:
--      MouseOver   Whether or not the mouse is over the button (regardless of enabled-state).
--      Pressed     Whether or not the button is being pressed in by the mouse.
--      Enabled     Whether or not the button can be interacted with.
--  
--  Events:
--      OnPressed   Whenever the button is pressed and released while enabled.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/wrappers/CursorInteractable.lua")
Script.Load("lua/menu2/wrappers/MenuFX.lua")
Script.Load("lua/menu2/wrappers/Tooltip.lua")

local kResetButtonTexture = PrecacheAsset("ui/newMenu/resetToDefaultIcon.dds")
local kResetButtonSize = 64

---@class GUIResetButton : GUIButton
local baseClass = GUIButton
baseClass = GetMultiWrappedClass(baseClass, {"MenuFX", "Tooltip"})
class "GUIResetButton" (baseClass)

local function OnPressed(_)
    PlayMenuSound("CancelChoice")
end

function GUIResetButton:Initialize(params, errorDepth)

    errorDepth = (errorDepth or 1) + 1
    params.defaultColor = params.defaultColor or HexToColor("36b4d4")
    params.highlightColor = params.highlightColor or HexToColor("FFFFFF")

    baseClass.Initialize(self, params, errorDepth)

    self:SetTexture(kResetButtonTexture)
    self:SetSize(kResetButtonSize, kResetButtonSize)

    self:HookEvent(self, "OnPressed", OnPressed)

end
