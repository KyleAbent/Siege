-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/NavBar/Screens/ServerBrowser/GMSBRefreshButton.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Spinning button used for the server browser refresh button, and match-making loading graphic.
--
--  Parameters (* = required)
--      customGraphic     Use specified texture instead.
--  Properties:
--      Spinning          Whether or not arrows should spin.
--
--  Events:
--      OnPressed         Whenever the button is pressed and released while enabled.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/GUI/wrappers/CircularCollision.lua")
Script.Load("lua/GUI/wrappers/FXState.lua")

---@class GMSBRefreshButton : GUIButton
---@field public GetFXState function @From FXState wrapper
---@field public UpdateFXStateOverride function @From FXState wrapper
---@field public AddFXReceiver function @From FXState wrapper
---@field public RemoveFXReceiver function @From FXState wrapper
local baseClass = GUIButton
baseClass = GetCircularCollisionWrappedClass(baseClass)
baseClass = GetFXStateWrappedClass(baseClass)
class "GMSBRefreshButton" (baseClass)

local kDefaultDiameter = 220

local kRefreshingArrowsTexture = PrecacheAsset("ui/newMenu/refreshing_arrows.dds")
local kArrowMaxSpinSpeed =  360 * (math.pi / 180.0) -- radians/sec
local kArrowSpinAccel = 1000    * (math.pi / 180.0) -- radians/sec
local kArrowSpinDecel = 500     * (math.pi / 180.0) -- radians/sec

local kFlashShader = PrecacheAsset("shaders/GUI/menu/flash.surface_shader")
local kPressedScale = 0.9

local function OnFlashChanged(self, value)
    self.arrows:SetFloatParameter("multAmount", 2 * value + 1)
    self.arrows:SetFloatParameter("screenAmount", 2 * value)
end

GMSBRefreshButton:AddClassProperty("Spinning", false)
GMSBRefreshButton:AddClassProperty("_Flash", 0.0)

GMSBRefreshButton:AddClassProperty("_SpinSpeed", 0)
GMSBRefreshButton:AddClassProperty("_BeingRendered", false)

local function OnFXStateChanged(self, state, prevState)
    
    if state == "pressed" then
        self.arrows:ClearPropertyAnimations("Scale")
        self.arrows:SetScale(kPressedScale, kPressedScale)
    elseif state == "hover" then
        if prevState == "pressed" then
            self.arrows:AnimateProperty("Scale", Vector(1, 1, 1), MenuAnimations.Fade)
        else
            PlayMenuSound("ButtonHover")
            self:Set_Flash(1)
            self:AnimateProperty("_Flash", 0.125, MenuAnimations.FlashColor)
        end
    elseif state == "default" then
        self.arrows:AnimateProperty("Scale", Vector(1, 1, 1), MenuAnimations.Fade)
        self:AnimateProperty("_Flash", 0, MenuAnimations.Fade)
    end

end

local function UpdateUsesUpdates(self)
    
    local beingRendered = self:Get_BeingRendered()
    if not beingRendered then
        self:SetUpdates(false)
        return
    end
    
    local spinning = self:GetSpinning()
    if spinning then
        self:SetUpdates(true)
        return
    end
    
    local spinSpeed = self:Get_SpinSpeed()
    self:SetUpdates(spinSpeed > 0)
    
end

function GMSBRefreshButton:OnUpdate(deltaTime, now)

    local spinSpeed = self:Get_SpinSpeed() * 0.0001
    local spinning = self:GetSpinning()
    local accel = spinning and kArrowSpinAccel or -kArrowSpinDecel
    spinSpeed = Clamp(spinSpeed + accel * deltaTime, 0, kArrowMaxSpinSpeed)
    
    self.arrowRads = self.arrowRads - spinSpeed * deltaTime
    self.arrowRads = Wrap(self.arrowRads, 0, math.pi * 2)
    self.arrows:SetAngle(self.arrowRads)
    
    self:Set_SpinSpeed(spinSpeed * 10000)

end

function GMSBRefreshButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    RequireType({"string", "nil"}, params.customGraphic, "params.customGraphic", errorDepth)
    
    baseClass.Initialize(self, params, errorDepth)

    self.texture = params.customGraphic or kRefreshingArrowsTexture
    
    self.arrowRads = 0
    
    self.arrows = CreateGUIObject("arrows", GUIObject, self)
    self.arrows:AlignCenter()
    self.arrows:SetTexture(self.texture)
    self.arrows:SetShader(kFlashShader)
    self.arrows:SetSizeFromTexture()
    self.arrows:SetColor(1, 1, 1, 1)
    self.arrows:SetRotationOffset(0.5, 0.5)
    
    self:SetSize(kDefaultDiameter, kDefaultDiameter)
    
    self:HookEvent(self, "OnFXStateChanged", OnFXStateChanged)
    self:HookEvent(self, "On_FlashChanged", OnFlashChanged)
    
    self:TrackRenderStatus(self.arrows)
    self:HookEvent(self, "OnRenderingStarted", function(self2) self2:Set_BeingRendered(true) end)
    self:HookEvent(self, "OnRenderingStopped", function(self2) self2:Set_BeingRendered(false) end)
    
    self:HookEvent(self, "On_BeingRenderedChanged", UpdateUsesUpdates)
    self:HookEvent(self, "OnSpinningChanged", UpdateUsesUpdates)
    self:HookEvent(self, "On_SpinSpeedChanged", UpdateUsesUpdates)
    
end
