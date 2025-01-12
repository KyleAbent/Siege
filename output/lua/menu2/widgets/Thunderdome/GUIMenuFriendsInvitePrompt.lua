-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GUIMenuFriendsInvitePrompt.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--  This utilizes most of the default Popup class, as similarities are very close. However,
--  there is enough dissimilarites to merit duplication of some code (kiss).
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIGlobalEventDispatcher.lua")
Script.Load("lua/GUI/wrappers/CursorInteractable.lua")
Script.Load("lua/menu2/GUIMenuCoolGlowBox.lua")

Script.Load("lua/menu2/widgets/Thunderdome/GUIMenuFriendInviteReturnButton.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GUIMenuLobbyFriendList.lua")


---@class GUIMenuFriendsInvitePrompt : GUIObject
---@field public GetMouseOver function @From CursorInteractable wrapper
---@field public GetPressed function @From CursorInteractable wrapper
local baseClass = GUIObject
baseClass = GetCursorInteractableWrappedClass(baseClass)
class "GUIMenuFriendsInvitePrompt" (GUIObject)


GUIMenuFriendsInvitePrompt.kDarkenColor = Color(0, 0, 0, 0.6)

GUIMenuFriendsInvitePrompt:AddCompositeClassProperty("Title", "titleText", "Text")
GUIMenuFriendsInvitePrompt:AddClassProperty("Enabled", false)    --default to false on init-step

-- Size of the outer box of the popup.
local kOuterPopupSize = Vector(1024, 1280, 0)

-- Size of the region that holds the title text.
local kTitleRegionSize = Vector(kOuterPopupSize.x, 96, 0)

-- How much padding should be added to the sides of the title.
local kTitleSidesPadding = 24

-- Amount of space between outer and inner box at the bottom.
local kBottomPaddingHeight = 24

-- Amount of space between outer and inner box at both sides.
local kOuterSidesPaddingWidth = 24

-- Size of the inner box, derived from above measures.
local kInnerPopupHeight = kOuterPopupSize.y - kTitleRegionSize.y - kBottomPaddingHeight

-- Position of top edge of button holder relative to bottom edge of inner box.
local kButtonHolderYOffset = 70

-- Spacing between buttons (eg right edge of button N to left edge of button N+1)
local kButtonSpacing = 18

-- Spacing between edge of popup and edge of buttons.
local kButtonEdgePadding = 90

-- Animate button holder scale from this to 1, 1.
local kButtonHolderInitialScale = Vector(0.75, 0.75, 1)

-- Animate popup scale from this to 1, 1.
local kPopupInitialScale = Vector(0.75, 0.75, 1)

local kGlossTexture = PrecacheAsset("ui/newMenu/gloss.dds")


local function OnResolutionChanged(self, x, y)
    self.screenDarkener:SetSize(x, y)
    -- mockupRes = 3840 x 2160
    local scale = math.min(x / 3840, y / 2160)
    self:SetScale(scale, scale) 
end


local function UpdateFriendsListHeight(self)
    self.friendsList:SetSize(self:GetSize().x - kOuterSidesPaddingWidth * 2, kInnerPopupHeight)
end


local function UpdateLayout(self)
    self.titleHolder:SetSize(self:GetSize().x, kTitleRegionSize.y)
    self.outerBox:SetSize(self:GetSize())
    self.outerBoxGloss:SetSize(self.outerBox:GetSize() * Vector(2, 0.5, 1))
    UpdateFriendsListHeight(self)
end

local function OnSizeChanged(self, size)
    UpdateLayout(self)
end

local function ComputeNeededWidthForButtons(self)
    local sum = kButtonEdgePadding * 2
    for i=1, #self.buttons do
        sum = sum + self.buttons[i]:GetSize().x
        if i > 1 then
            sum = sum + kButtonSpacing
        end
    end
    return sum
end

local function ComputeNeededWidthForTitle(self)
    return self.titleText:GetSize().x + kTitleSidesPadding * 2
end

local function UpdateSize(self)
    local defaultWidth = kOuterPopupSize.x
    local buttonNeededWidth = ComputeNeededWidthForButtons(self)
    
    local titleNeededWidth = ComputeNeededWidthForTitle(self)
    local neededWidth = math.max(defaultWidth, buttonNeededWidth, titleNeededWidth)
    
    local defaultHeight = kOuterPopupSize.y
    
    self:SetSize(neededWidth, defaultHeight)
end

local function OnButtonSizeChanged(self)
    UpdateSize(self)
end

function GUIMenuFriendsInvitePrompt:GetDefaultButtonClass()
    return GUIMenuFriendInviteReturnButton
end

function GUIMenuFriendsInvitePrompt:CreateButton(config)
    -- If a button class wasn't specified, let the popup chooose.
    local prevButtonClass = config.class
    config.class = config.class or self:GetDefaultButtonClass()
    
    local newButton = CreateGUIObjectFromConfig(config, self.buttonHolder)
    self:HookEvent(newButton, "OnPressed", config.callback)
    self.buttons[newButton:GetName()] = newButton
    
    -- Revert config.class to the value it was before we changed it.  Remember, these tables being
    -- passed to us aren't temporary -- if we make changes to them, they'll stick and get used
    -- anywhere else this table is used, so make sure we clean up after ourselves!
    config.class = prevButtonClass
    
    return newButton
end

function GUIMenuFriendsInvitePrompt:GetButton(name)
    return self.buttons[name] 
end

-- Override for different layouts.
function GUIMenuFriendsInvitePrompt:CreateButtonHolder()
    local result = CreateGUIObject("buttonHolder", GUIListLayout, self, {orientation = "horizontal"})
    return result
end


local function OnVisibleChanged(self)
    if self:GetVisible() then
        Client.TriggerFriendsListUpdate()     --Note: this "should" be handled via timed-callback in List itself
        self:SetModal()
        self:SetEnabled(true)
        
        -- Ensure the mouse cursor is visible for the popup (could potentially popup while the player is not in the menu).
        MouseTracker_SetIsVisible(true, "ui/Cursor_MenuDefault.dds", Client.GetIsConnected())
        self.cursorInStack = true -- keep track of whether or not we've removed the cursor yet.
    else
        self:SetEnabled(false)
        self:Close()
    end
end

function GUIMenuFriendsInvitePrompt:Initialize(params, errorDepth)

    errorDepth = (errorDepth or 1) + 1

    -- Ensure escDisabled is a boolean.
    RequireType({"boolean", "nil"}, params.escDisabled, "params.escDisabled", errorDepth)

    -- Ensure title is text.
    RequireType({"string", "nil"}, params.title, "params.title", errorDepth)

    -- Ensure update function, if specified, is a function.
    RequireType({"function", "nil"}, params.updateFunc, "params.updateFunc", errorDepth)

    
    -- Ensure buttons have been specified, and that each button class is a GUIButton derived type,
    -- and that callback functions have been specified.
    local usedButtonNames = {} -- ensure no duplicate button names.
    RequireType({"table"}, params.buttonConfig, "params.buttonConfig", errorDepth)
    if #params.buttonConfig == 0 then
        error("Expected an array of button configurations for params.buttonConfig, but got a 0-length table (did you accidentally create a dictionary?)", errorDepth)
    end
    for i=1, #params.buttonConfig do
        
        RequireType({"GUIButton", "nil"}, params.buttonConfig[i].class, string.format("params.buttonConfig[%d].class", i), errorDepth)
        RequireType({"function"}, params.buttonConfig[i].callback, string.format("params.buttonConfig[%d].callback", i), errorDepth)
        RequireType({"string"}, params.buttonConfig[i].name, string.format("params.buttonConfig[%d].name", i), errorDepth)
        
        local buttonName = params.buttonConfig[i].name
        
        -- Ensure button name isn't already taken.
        if usedButtonNames[buttonName] then
            error(string.format("There is already a button named '%s'!", buttonName), errorDepth)
        end
        usedButtonNames[buttonName] = true
        
    end

    GUIObject.Initialize(self, params, errorDepth)

    -- Setup background
    self.outerBox = CreateGUIObject("outerBox", GUIMenuCoolBox, self)
    self.outerBox:SetLayer(-2)
    
    self.outerBoxGloss = self.outerBox:CreateGUIItem()
    self.outerBoxGloss:SetLayer(1)
    self.outerBoxGloss:SetTexture(kGlossTexture)
    self.outerBoxGloss:SetColor(MenuStyle.kGlossColor)
    self.outerBoxGloss:SetBlendTechnique(GUIItem.Add)
    self.outerBoxGloss:SetAnchor(0.5, 0.5)
    self.outerBoxGloss:SetHotSpot(0.5, 1)
    self.outerBoxGloss:SetMinCrop(0.25, 0)
    self.outerBoxGloss:SetMaxCrop(0.75, 1)

    self.titleHolder = self:CreateLocatorGUIItem()
    self.titleHolder:AlignTop()
    self.titleText = CreateGUIObject("titleText", GUIText, self.titleHolder)
    self.titleText:SetFont(MenuStyle.kCustomizeViewBuyButtonFont)
    self.titleText:SetColor(MenuStyle.kOptionHeadingColor)
    self.titleText:AlignCenter()
    self:SetTitle(params.title or "TITLE")

    -- Create buttons.
    self.buttons = {} -- mapping of button name --> button.
    self.buttonHolder = self:CreateButtonHolder()
    for i=1, #params.buttonConfig do
        local newButton = self:CreateButton(params.buttonConfig[i])
        self.buttons[newButton:GetName()] = newButton
        self.buttons[#self.buttons+1] = newButton
    end

    self.buttonHolder:AlignBottom()
    self.buttonHolder:SetY(kButtonHolderYOffset)

    -- Setup the update function, if provided.
    if params.updateFunc then
        self.OnUpdate =
            function(self, deltaTime, now)
                params.updateFunc(self, deltaTime, now)
            end
        GetGUIUpdateManager():AddObjectToUpdateSet(self)
    end

    UpdateSize(self)

    self.friendsList = CreateGUIObject("friendsInviteList", GUIMenuLobbyFriendList, self)
    self.friendsList:AlignTop()
    self.friendsList:SetPosition(0, kTitleRegionSize.y - 8)
    self.friendsList:HookEvent(self, "OnSizeChanged", self.friendsList.SetWidth)

    self:HookEvent(self, "OnSizeChanged", UpdateFriendsListHeight)
    UpdateFriendsListHeight(self)

    -- Popup should appear above everything else.
    self:SetLayer(GetLayerConstant("Popup", 1000))

    -- Darken the screen behind the popup.
    self.screenDarkener = self:CreateGUIItem()
    self.screenDarkener:SetLayer(-100)
    self.screenDarkener:SetColor(self.kDarkenColor)
    
    -- Screen darkener should stretch to fill the whole screen.  To make this easier, its transform
    -- should be setup in screen space, not parent-local space.
    self.screenDarkener:SetInheritsParentScaling(false)
    self.screenDarkener:SetInheritsParentPosition(false)
    
    -- Need to adjust the size of the darkener and main object, as well as adjust scaling of popup part of object.
    self:HookEvent(GetGlobalEventDispatcher(), "OnResolutionChanged", OnResolutionChanged)
    OnResolutionChanged(self, Client.GetScreenWidth(), Client.GetScreenHeight())

    self:HookEvent(self, "OnSizeChanged", OnSizeChanged)

    self:AlignCenter()

    UpdateLayout(self)

    self:SetVisible(false)
    self:SetEnabled(false)
    self:HookEvent(self, "OnVisibleChanged", OnVisibleChanged)

end

function GUIMenuFriendsInvitePrompt:OnKey(key, down)
    
    if not self:GetEnabled() then
        return
    end

    if key == InputKey.Escape and down then
        self:FireEvent("OnEscape")
        self:FireEvent("OnCancelled")
        self:Close()
    end
    
end

function GUIMenuFriendsInvitePrompt:Uninitialize()
    
    -- Hide the mouse cursor if we haven't already (or at least stop reserving mouse cursor visibility for this object).
    if self.cursorInStack then
        self.cursorInStack = nil
        MouseTracker_SetIsVisible(false)
    end
    
    GUIObject.Uninitialize(self)
    
end


-- Close the popup.  This method should never be overridden.  Instead, override PerformClose() to
-- change _how_ the popup closes.
function GUIMenuFriendsInvitePrompt:Close()
    
    -- Hide the mouse cursor if we haven't already (or at least stop reserving mouse cursor visibility for this object).
    if self.cursorInStack then
        self.cursorInStack = nil
        MouseTracker_SetIsVisible(false)
    end
    
    -- Popup no longer blocks other interactions.
    self:ClearModal()
    
    self:FireEvent("OnClosed")
    
    self:PerformClose()
    
end

-- Do whatever the derived class wants to do when a dialog closes.
function GUIMenuFriendsInvitePrompt:PerformClose()
    --self:Destroy()
    self:SetVisible(false)
end

function GUIMenuFriendsInvitePrompt:GetContents()
    return self.contents
end