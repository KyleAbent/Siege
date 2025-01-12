-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/NavBar/Screens/QuitList/GUIMenuQuitList.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    A list of options for quitting in-game (leave server, leave game, go to ready room).
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/menu2/NavBar/Screens/GUIMenuNavBarScreen.lua")

Script.Load("lua/GUI/layouts/GUIListLayout.lua")
Script.Load("lua/menu2/NavBar/Screens/QuitList/GUIMenuQuitListItem.lua")

Script.Load("lua/menu2/GUIMenuDropShadow.lua")
Script.Load("lua/menu2/GUIMenuCoolBox2.lua")

---@class GUIMenuQuitList : GUIMenuNavBarScreen
local baseClass = GUIMenuNavBarScreen
class "GUIMenuQuitList" (baseClass)

GUIMenuQuitList.kSpacing = 24
GUIMenuQuitList.kPadding = Vector(0, 48, 0)

local kWiresTexture = PrecacheAsset("ui/newMenu/playListWires.dds")
local kWire1BoundsX = 76
local kWire2BoundsX = 122
local kWireBoundsY = 556
local kWire1PosX = 40

local kCropOffsetUL = Vector(-8, -8, 0)
local kCropOffsetLR = Vector(40, 40, 0)

function GUIMenuQuitList:GetOptionDefsTable()       --TD-FIXME Need to adjust this based on game-mode and/or local-mod
    return
    {
        {
            name = "readyRoom",
            class = GUIMenuQuitListItem,
            params =
            {
                label = Locale.ResolveString("MENU_GO_TO_READY_ROOM"),
            },
            callback = GUIMenuPlayList.OnGoToReadyRoomClicked,
            postInit = function(createdObj)
                createdObj:SetEnabled(not Shared.GetThunderdomeEnabled())
            end,
        },
        
        {
            name = "leaveServer",
            class = GUIMenuQuitListItem,
            params =
            {
                label = Locale.ResolveString("LEAVE_SERVER"),
            },
            callback = GUIMenuPlayList.OnLeaveServerClicked,
        },
        
        {
            name = "quitGame",
            class = GUIMenuQuitListItem,
            params =
            {
                label = Locale.ResolveString("QUIT_GAME"),
            },
            callback = GUIMenuPlayList.OnQuitGameClicked,
        },
    }
end

local function UpdateSize(self, newSize)
    
    local paddedSize = newSize + self.kPadding * 2
    
    self.back:SetSize(paddedSize)
    self.backShadow:SetSize(paddedSize)
    self:SetSize(paddedSize)
    
    -- Update crop.
    -- Add some padding around crop zone to prevent it from cropping away the effects like
    -- outer stroke, and drop shadow.
    self:SetCropMin(kCropOffsetUL.x / paddedSize.x, kCropOffsetUL.y / paddedSize.y)
    self:SetCropMax((kCropOffsetLR.x + paddedSize.x) / paddedSize.x, (kCropOffsetLR.y + paddedSize.y) / paddedSize.y)

end

function GUIMenuQuitList:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    PROFILE("GUIMenuPlayList:Initialize")
    
    PushParamChange(params, "screenName", "Quit")
    baseClass.Initialize(self, params, errorDepth)
    PopParamChange(params, "screenName")
    
    self:ListenForCursorInteractions() -- prevent click-through
    
    self.back = CreateGUIObject("back", GUIMenuCoolBox2, self)
    self.back:SetLayer(-1)
    
    self.backWire1 = self.back:CreateGUIItem()
    self.backWire1:SetTexture(kWiresTexture)
    self.backWire1:SetTexturePixelCoordinates(0, 0, kWire1BoundsX, kWireBoundsY)
    self.backWire1:SetSize(kWire1BoundsX, kWireBoundsY)
    self.backWire1:SetPosition(kWire1PosX, 0)
    self.backWire1:AlignBottomLeft()
    
    self.backWire2 = self.back:CreateGUIItem()
    self.backWire2:SetTexture(kWiresTexture)
    self.backWire2:SetTexturePixelCoordinates(kWire1BoundsX, 0, kWire2BoundsX, kWireBoundsY)
    self.backWire2:SetSize(kWire2BoundsX - kWire1BoundsX, kWireBoundsY)
    self.backWire2:AlignBottomRight()
    
    self.backShadow = CreateGUIObject("backShadow", GUIMenuDropShadow, self)
    self.backShadow:SetLayer(-2)
    
    self.listLayout = CreateGUIObject("listLayout", GUIListLayout, self, {orientation = "vertical"})
    self.listLayout:SetSpacing(self.kSpacing)
    self.listLayout:SetPosition(self.kPadding)
    
    self:HookEvent(self.listLayout, "OnSizeChanged", UpdateSize)
    
    self.options = {}
    local optionDefs = self:GetOptionDefsTable()
    for i=1, #optionDefs do
        local optionDef = optionDefs[i]
        local newOption = CreateGUIObjectFromConfig(optionDef, self.listLayout)
        self:HookEvent(newOption, "OnPressed", optionDef.callback)
    end

end

function GUIMenuQuitList:UpdateBackgroundSize(input, output)
    output[1].x = input[1].x + self.kPadding.x * 2
    output[1].y = input[1].y + self.kPadding.y * 2
    return output[1]
end

function GUIMenuPlayList:OnGoToReadyRoomClicked()
    Shared.ConsoleCommand("rr")
    GetScreenManager():DisplayScreen("NavBar")
end

function GUIMenuPlayList:OnLeaveServerClicked()

    if Shared.GetThunderdomeEnabled() then
        GetThunderdomeMenu():ShowLeaveConfirmation(function() Shared.ConsoleCommand("disconnect") end)
        return
    end

    Shared.ConsoleCommand("disconnect")
end

function GUIMenuPlayList:OnQuitGameClicked()

    if Shared.GetThunderdomeEnabled() then
        GetThunderdomeMenu():ShowLeaveConfirmation(function() Shared.ConsoleCommand("exit") end)
        return
    end

    Shared.ConsoleCommand("exit")
end