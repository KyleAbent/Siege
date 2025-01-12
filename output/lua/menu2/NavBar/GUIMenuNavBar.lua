-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/NavBar/GUIMenuNavBar.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--    
--    The main bar, top-center, from which most other menus slide out from under.
--    
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/menu2/GUIMenuScreen.lua")
Script.Load("lua/GUI/GUIGlobalEventDispatcher.lua")

---@class GUIMenuNavBar : GUIMenuScreen
class "GUIMenuNavBar" (GUIMenuScreen)

GUIMenuNavBar:AddClassProperty("IsBuildNew", false)

GUIMenuNavBar.kPlayMenuXPosition = 200
GUIMenuNavBar.topEdge = 271

GUIMenuNavBar.kBackgroundTexture = PrecacheAsset("ui/newMenu/mainNavBarBack.dds")
GUIMenuNavBar.kHoverLightTexture = PrecacheAsset("ui/newMenu/mainNavBarButtonLight.dds")
GUIMenuNavBar.kFlashShader = PrecacheAsset("shaders/GUI/menu/flash.surface_shader")

GUIMenuNavBar.kNavBarCropOffsetStart = 150

GUIMenuNavBar.kLogoPosition = Vector(-5, -235, 0) -- center position relative to center of nav bar
GUIMenuNavBar.kLogoTexture = PrecacheAsset("ui/newMenu/logoHuge.dds")

GUIMenuNavBar.kFontFamily = MenuStyle.kNavBarFont.family
GUIMenuNavBar.kFontSize = MenuStyle.kNavBarFont.size

GUIMenuNavBar.kScreenYOffsetWhenClosed = -192

GUIMenuNavBar.kUnderlapYSize = 113

GUIMenuNavBar.kPulldownXPosition = 156

GUIMenuNavBar.kTooltipBlockerHeight = 152

GUIMenuNavBar.kNewsFeedSize = Vector(2000, 1500, 0)
local kDefaultNewsFeedWebViewSize = Vector(750, 562, 0) -- 0.375 of the GUIMenuNavBar.kNewsFeedSize
GUIMenuNavBar.kNewsFeedConfig =
{
    { -- NEWS
        name = "news",
        label = Locale.ResolveString("NEWS"),
        webPageParams =
        {
            url = "http://unknownworlds.com/ns2/ingamenews/",
            renderSize = kDefaultNewsFeedWebViewSize,
            wheelEnabled = true,
            clickMode = "Full",
            openURL = "http://unknownworlds.com/ns2/",
        },
    },
    
    { -- CHANGELOG
        name = "changelog",
        label = string.upper(Locale.ResolveString("CHANGELOG_TITLE")),
        webPageParams =
        {
            url = "http://unknownworlds.com/ns2/ingame-changelog/",
            renderSize = kDefaultNewsFeedWebViewSize,
            wheelEnabled = true,
            clickMode = "Full",
        },
    },
}


-- Load child window scripts here, as some of them rely on some of the constants defined above.
Script.Load("lua/menu2/NavBar/GUIMenuNavBarButton.lua")

Script.Load("lua/menu2/NavBar/Screens/PlayList/GUIMenuPlayList.lua")
Script.Load("lua/menu2/NavBar/Screens/Options/GUIMenuOptions.lua")
Script.Load("lua/menu2/NavBar/Screens/Thunderdome/GUIMenuThunderdome.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GUIMenuServerBrowser.lua")
Script.Load("lua/menu2/NavBar/Screens/StartServer/GUIMenuStartServerScreen.lua")
Script.Load("lua/menu2/NavBar/Screens/Training/GUIMenuTraining.lua")
Script.Load("lua/menu2/NavBar/Screens/Challenges/GUIMenuChallenges.lua")
Script.Load("lua/menu2/NavBar/Screens/Credits/GUIMenuCredits.lua")
Script.Load("lua/menu2/PlayerScreen/GUIMenuPlayerScreen.lua")
Script.Load("lua/menu2/NavBar/Screens/News/GUIMenuNewsFeed.lua")

local kButtonData = 
{
    [1] = 
    {
        name = "play",
        buttonText = "PLAY",
        --screenName = "Play",
        
        glowPos = Vector(113, 0, 0),
        textPos = Vector(101, -3, 0),
        clickZonePoly = 
        {
            Vector(-1525,       11,       0),
            Vector(-1525 + 130, 11 + 130, 0),
            Vector(-884,        11 + 130, 0),
            Vector(-884,        11,       0),
        },
        buttonFunction = function()

            local curScreen = GetScreenManager():GetCurrentScreenName()

            if not Thunderdome():GetIsIdle() then
            --return to MM screen instead of showing play menu

                if curScreen == "MatchMaking" then
                    GetScreenManager():DisplayScreen("NavBar")
                    GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)
                    return
                else
                    GetScreenManager():DisplayScreen("MatchMaking")
                    return
                end

            else

                if curScreen == "Play" then
                -- clear the history by going back to the nav bar.
                    GetScreenManager():DisplayScreen("NavBar")
                    GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)
                else
                    GetScreenManager():DisplayScreen("NavBar")
                    GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)
                    GetScreenManager():DisplayScreen("Play")
                end
                
            end

        end
    },
    
    [2] = 
    {
        name = "options",
        buttonText = "OPTIONS",
        screenName = "Options",
        
        glowPos = Vector(-40, 0, 0),
        textPos = Vector(-40, -3, 0),
        clickZonePoly = 
        {
            Vector(-878      , 11,       0),
            Vector(-878      , 11 + 130, 0),
            Vector(-394      , 11 + 130, 0),
            Vector(-394 + 130, 11,       0),
        },
    },
    
    [3] = 
    {
        name = "customize",
        buttonText = "SKINS",
        screenName = "PlayerScreen",
        
        glowPos = Vector(44, 0, 0),
        textPos = Vector(45, -3, 0),
        clickZonePoly = 
        {
            Vector(260,       11,       0),
            Vector(260 + 130, 11 + 130, 0),
            Vector(881,       11 + 130, 0),
            Vector(881,       11,       0),
        },
    },
    
    [4] = 
    {
        name = "credits",
        buttonText = "CREDITS",
        screenName = "Credits",
        
        glowPos = Vector(-60, 0, 0),
        textPos = Vector(-46, -3, 0),
        clickZonePoly = 
        {
            Vector(887,             11,       0),
            Vector(887,             11 + 130, 0),
            Vector(887 + 504,       11 + 130, 0),
            Vector(887 + 504 + 130, 11,       0),
        },
    },
    
}

local navBar
function GetNavBar()
    return navBar
end

-- Extended in child classes to allow data to be selectively modified, without having to copy the
-- entire table.
function GUIMenuNavBar.GetData(dataIndex, fieldName)
    
    local data = kButtonData[dataIndex]
    return data[fieldName]
    
end

function GUIMenuNavBar:SetGlowingButtonIndex(idx)
    for i=1, #self.buttons do
        local button = self.buttons[i]
        button:SetGlowing(i == idx)
    end
end

function GUIMenuNavBar:CreateButton(dataIndex)
    
    local name = self.GetData(dataIndex, "name")
    assert(name)
    
    local newButton = CreateGUIObject(name, GUIMenuNavBarButton, self)
    newButton:SetAnchor(0.5, 0)
    
    local points = self.GetData(dataIndex, "clickZonePoly")
    assert(points)
    newButton:SetPoints(points)
    
    local localeString = self.GetData(dataIndex, "buttonText")
    assert(localeString)
    newButton:SetText(Locale.ResolveString(localeString))
    
    newButton:SetLayer(2)
    
    local textOffset = self.GetData(dataIndex, "textPos")
    assert(textOffset)
    newButton:SetTextOffset(textOffset)
    
    local glowOffset = self.GetData(dataIndex, "glowPos")
    assert(glowOffset)
    newButton:SetGlowOffset(glowOffset)
    
    local screenName = self.GetData(dataIndex, "screenName")
    local buttonFunction = self.GetData(dataIndex, "buttonFunction")
    assert(screenName or buttonFunction) -- must have one or the other...
    assert(not screenName or not buttonFunction) -- ...but not both.
    
    self:HookEvent(newButton, "OnPressed", function()

        if screenName then

            -- If they clicked the button for the screen we're already looking at, hide the screen.
            if GetScreenManager():GetCurrentScreenName() == screenName then
                GetScreenManager():DisplayScreen("NavBar")
                return
            end
    
            -- clear the history by going back to the nav bar.
            GetScreenManager():DisplayScreen("NavBar")
            GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)
            
            GetScreenManager():DisplayScreen(screenName)
            
        else
            
            buttonFunction(self)
            
        end
        
    end)
    
    return newButton
    
end

local function UpdateResolutionScaling(self, newX, newY, oldX, oldY)
    
    local mockupRes = Vector(3840, 2160, 0)
    local res = Vector(newX, newY, 0)
    local scale = res / mockupRes
    scale = math.min(scale.x, scale.y)
    
    self:SetScale(scale, scale)
    self:SetPosition(0, self.topEdge * scale)
    
end


function GUIMenuNavBar:SetThunderdomeState( enabled )

    for i = 1, #self.buttons do
        if self.buttons[i]:GetName() == "play" then
        --set interactivirty state for entire Play menu
            self.buttons[i]:SetEnabled( enabled )
            
            --hack to make the disabling of menu visual
            self.buttons[i].nonHoverText:SetStyle( enabled and MenuStyle.kMainBarButtonText or MenuStyle.kMainBarDisabledButtonText )
        end
    end

end

function GUIMenuNavBar:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    navBar = self
    
    PushParamChange(params, "screenName", "NavBar")
    GUIMenuScreen.Initialize(self, params, errorDepth)
    PopParamChange(params, "screenName")
    
    self:GetRootItem():SetDebugName("navBar")
    self:SetLayer(100)
    
    -- Nav bar is to be centered horizontally in the screen.
    self:AlignTop()
    self:HookEvent(GetGlobalEventDispatcher(), "OnResolutionChanged", UpdateResolutionScaling)
    UpdateResolutionScaling(self, Client.GetScreenWidth(), Client.GetScreenHeight())
    
    -- Background image.
    self.barGraphic = self:CreateGUIItem()
    self.barGraphic:SetTexture(self.kBackgroundTexture)
    self.barGraphic:SetSizeFromTexture()
    self:SetSize(self.barGraphic:GetSize())
    self.barGraphic:SetLayer(1)
    
    -- buttons
    self.buttons = {}
    for i=1, #kButtonData do
        self.buttons[i] = self:CreateButton(i)
    end
    
    -- logo
    self.logo = self:CreateGUIItem(self.barGraphic)
    self.logo:SetTexture(self.kLogoTexture)
    self.logo:SetSizeFromTexture()
    self.logo:AlignCenter()
    self.logo:SetLayer(1) -- appear above bar graphic.
    self.logo:SetPosition(self.kLogoPosition)

    -- item to prevent tooltips from going through nav bar.
    self.tooltipBlocker = self:CreateLocatorGUIItem()
    self.tooltipBlocker:SetSize(self:GetSize().x, self.kTooltipBlockerHeight)
    self.tooltipBlocker:AlignTop()
    self.tooltipBlocker:SetLayer(100)
    GetGUIMenuTooltipManager():SetBlocksTooltips(self.tooltipBlocker)

    -- Crop child windows a little bit above the origin, as the graphics leave a bit of overlap in
    -- the middle.
    self.childWindowCropper = self:CreateLocatorGUIItem()
    self.childWindowCropper:SetDebugName("navBarChildWindowCropper")
    self.childWindowCropper:SetSize(99999, 99999)
    self.childWindowCropper:AlignTop()
    self.childWindowCropper:CropToBounds()
    self.childWindowCropper:SetPosition(0, self.kNavBarCropOffsetStart - self.kUnderlapYSize)
    
    -- Parent of all child windows.  Origin is right at the bottom of the nav bar.
    self.childWindows = self:CreateLocatorGUIItem(self.childWindowCropper)
    self.childWindows:SetDebugName("navBarChildWindows")
    self.childWindows:SetSize(self.barGraphic:GetSize().x, 99999)
    self.childWindows:SetPosition(0, self.kUnderlapYSize)
    self.childWindows:AlignTop()
    
    -- play menu
    self.playMenu = CreateGUIObject("playMenu", GUIMenuPlayList, self.childWindows)
    self.playMenu:SetHotSpot(0, self.playMenu:GetHotSpot().y)
    self.playMenu:SetPosition(self.kPlayMenuXPosition, self.playMenu:GetPosition().y)
    self:HookEvent(self.playMenu, "OnScreenDisplay", function(self2) self2:SetGlowingButtonIndex(1) end)
    self:HookEvent(self.playMenu, "OnScreenHide", function(self2) self2:SetGlowingButtonIndex(nil) end)
    
    -- options menu
    self.optionsMenu = CreateGUIObject("optionsMenu", GUIMenuOptions, self.childWindows)
    self.optionsMenu:SetHotSpot(0.5, self.optionsMenu:GetHotSpot().y)
    self.optionsMenu:SetAnchor(0.5, 0)
    self:HookEvent(self.optionsMenu, "OnScreenDisplay", function(self2) self2:SetGlowingButtonIndex(2) end)
    self:HookEvent(self.optionsMenu, "OnScreenHide", function(self2) self2:SetGlowingButtonIndex(nil) end)
    
    -- Match Making / Thunderdome
    self.thunderdomeMenu = CreateGUIObject("matchMakingMenu", GUIMenuThunderdome, self.childWindows)
    self.thunderdomeMenu:SetHotSpot(0.5, self.thunderdomeMenu:GetHotSpot().y)
    self.thunderdomeMenu:SetAnchor(0.5, 0)

    -- server browser
    self.serverBrowserMenu = CreateGUIObject("serverBrowserMenu", GUIMenuServerBrowser, self.childWindows)
    self.serverBrowserMenu:SetHotSpot(0.5, self.serverBrowserMenu:GetHotSpot().y)
    self.serverBrowserMenu:SetAnchor(0.5, 0)
    
    -- start server
    self.startServerScreen = CreateGUIObject("startServerScreen", GUIMenuStartServerScreen, self.childWindows)
    self.startServerScreen:SetHotSpot(0, self.startServerScreen:GetHotSpot().y)

    -- Create player profile screen.
    self.playerScreen = CreateGUIObject("playerScreen", GUIMenuPlayerScreen, GetMainMenu()) --parented to GUIMainMenu, not this self

    --customize menu link (actual screen is managed in PlayerScreen)
    self:HookEvent(self.playerScreen, "OnScreenDisplay", 
        function(self)
            if not GetMainMenu():GetIsInGame() then
                self:SetGlowingButtonIndex(3) 
            end
        end)
    self:HookEvent(self.playerScreen, "OnScreenHide", 
        function(self) 
        if not GetMainMenu():GetIsInGame() then
            self:SetGlowingButtonIndex(nil) 
        end
    end)
    
    -- credits menu
    self.creditsMenu = CreateGUIObject("creditsMenu", GUIMenuCredits, self.childWindows)
    self.creditsMenu:SetHotSpot(0.5, self.creditsMenu:GetHotSpot().y)
    self.creditsMenu:SetAnchor(0.5, 0)
    self:HookEvent(self.creditsMenu, "OnScreenDisplay", function(self2) self2:SetGlowingButtonIndex(4) end)
    self:HookEvent(self.creditsMenu, "OnScreenHide", function(self2) self2:SetGlowingButtonIndex(nil) end)
    
    -- training menu
    self.trainingMenu = CreateGUIObject("trainingMenu", GUIMenuTraining, self.childWindows)
    self.trainingMenu:SetHotSpot(0.5, self.trainingMenu:GetHotSpot().y)
    self.trainingMenu:SetAnchor(0.5, 0)
    self:HookEvent(self.trainingMenu, "OnScreenDisplay", function(self2) self2:SetGlowingButtonIndex(nil) end)
    self:HookEvent(self.trainingMenu, "OnScreenHide", function(self2) self2:SetGlowingButtonIndex(nil) end)
    
    -- challenges menu
    self.challengesMenu = CreateGUIObject("challengesMenu", GUIMenuChallenges, self.childWindows)
    self.challengesMenu:SetHotSpot(0.5, self.challengesMenu:GetHotSpot().y)
    self.challengesMenu:SetAnchor(0.5, 0)
    self:HookEvent(self.challengesMenu, "OnScreenDisplay", function(self2) self2:SetGlowingButtonIndex(nil) end)
    self:HookEvent(self.challengesMenu, "OnScreenHide", function(self2) self2:SetGlowingButtonIndex(nil) end)
    
    -- news feed and other webpages.
    self.newsFeed = CreateGUIObject("newsFeed", GUIMenuNewsFeed, self,
    {
        webPages = self.kNewsFeedConfig,
    })
    self.newsFeed:SetAnchor(0.5, 1)
    self.newsFeed:SetHotSpot(0.5, 0)
    self.newsFeed:SetSize(self.kNewsFeedSize)
    self.newsFeed:SetY(-self.newsFeed:GetPulloutHeight())
    self.newsFeed:SetInheritsParentPosition(false)

    self.newsFeed:HookEvent(self, "OnScreenDisplay",
    function(newsFeed)
        if self:GetIsBuildNew() then
            self.newsFeed:Show(true)
            self:SetIsBuildNew(false)
        else
            newsFeed:Collapse(false, true)
        end
    end)

    self.newsFeed:HookEvent(self, "OnScreenHide",
    function(newsFeed)
        newsFeed:Collapse(true, true)
    end)
    
end

