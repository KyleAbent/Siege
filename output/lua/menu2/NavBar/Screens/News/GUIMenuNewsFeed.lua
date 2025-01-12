-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/NavBar/Screens/News/GUIMenuNewsFeed.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Used to display multiple different web pages, with buttons to choose between them.
--
--  Parameters (* = required)
--      webPages
--
--  Properties
--      WebPages            List of data for configuring the news feed.  Looks like this:
--                          {
--                              {
--                                  name = "news",
--                                  label = Locale.ResolveString("NEWS"),
--                                  webPageParams =
--                                  {
--                                      url = "http://unknownworlds.com/ns2/ingamenews/",
--                                      <other GUIWebPageView parameters can be added here>
--                                  },
--                              },
--                          },
--      CurrentPage         The name of the page currently being displayed.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIWebPageView.lua")
Script.Load("lua/GUI/layouts/GUIFlexLayout.lua")
Script.Load("lua/menu2/GUIMenuCoolBox2.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBTextButton.lua")
Script.Load("lua/menu2/NavBar/Screens/News/GUIMenuNewsFeedPullout.lua")

local backgroundClass = GUIMenuCoolBox2

---@class GUIMenuNewsFeed : GUIObject
local baseClass = GUIObject
class "GUIMenuNewsFeed" (baseClass)

local kPadding = 32
local kTextYOffset = -16
local kDefaultSize = Vector(1000, 1000, 0)

local kButtonHolderHeight = 64

local kPulloutHeight = 90
local kPulloutGap = 10

GUIMenuNewsFeed:AddClassProperty("WebPages", {}, true)
GUIMenuNewsFeed:AddClassProperty("CurrentPage", "")

local function UpdatePageVisibility(page, currentPage)
    page:SetVisible(page.name == currentPage)
end

local function UpdateButtonGlowing(button, currentPage)
    button:SetGlowing(button.pageName == currentPage)
end

local function ClearAllWebPages(self)
    
    -- Destroy the associated web page objects.
    for i=1, #self.webPageObjs do
        self.webPageObjs[i]:Destroy()
    end
    self.webPageObjs = {}
    
    -- Destroy the associated button objects.
    for i=1, #self.buttonObjs do
        self.buttonObjs[i]:Destroy()
    end
    self.buttonObjs = {}
    
end

local function CreateWebPage(self, config)

    -- Create a new web page object to display the web page.
    local newWebPage = CreateGUIObject(config.name, GUIWebPageView, self.webPagesHolder, config.webPageParams)
    table.insert(self.webPageObjs, newWebPage)
    self.webPageObjs[config.name] = newWebPage
    
    -- Ensure the object is only visible when it is the page currently being viewed.
    newWebPage:HookEvent(self, "OnCurrentPageChanged", UpdatePageVisibility)
    UpdatePageVisibility(newWebPage, self:GetCurrentPage())
    
    -- Sync the size of the web page display to the web pages holder.
    newWebPage:HookEvent(self.webPagesHolder, "OnSizeChanged", newWebPage.SetSize)
    newWebPage:SetSize(self.webPagesHolder:GetSize())
    
    -- Create a new page button for this page.
    local newButton = CreateGUIObject(string.format("%s_button", config.name), GMSBTextButton, self.buttonHolder)
    table.insert(self.buttonObjs, newButton)
    newButton.pageName = config.name
    newButton:AlignLeft()
    newButton:SetLabel(config.label)
    
    -- Ensure the button is only glowing when it represents the currently visible page.
    newButton:HookEvent(self, "OnCurrentPageChanged", UpdateButtonGlowing)
    UpdateButtonGlowing(newButton, self:GetCurrentPage())
    
    -- Clicking the button sets the currently visible page.
    newButton.newsFeed = self
    newButton:HookEvent(newButton, "OnPressed",
    function(button)
        button.newsFeed:SetCurrentPage(button.pageName)
    end)
    
    -- If the current web page is invalid, use this one.
    if self:GetCurrentPage() == "" then
        self:SetCurrentPage(config.name)
    end
    
end

local function CreateWebPagesFromList(self, webPages)
    for i=1, #webPages do
        CreateWebPage(self, webPages[i])
    end
end

local function UpdateWebPages(self, webPages)

    -- Store the current page so we can restore it later if it still exists after the change.
    local currentPage = self:GetCurrentPage()
    
    -- Clear the current page value so it will be set to the first page created.
    self:SetCurrentPage("")
    
    -- Just lazily destroy it all and re-create from scratch.  Should rarely happen, so performance
    -- shouldn't be an issue here.
    ClearAllWebPages(self)
    CreateWebPagesFromList(self, webPages)
    
    -- Restore the "current page" value to what it was before, if the page still exists.  Otherwise,
    -- it has already been set to the first created page.
    for i=1, #self.webPageObjs do
        if self.webPageObjs[i].name == currentPage then
            self:SetCurrentPage(currentPage)
            break
        end
    end

end

local function UpdateBackgroundSize(self)
    local size = self.everythingHolder:GetSize()
    self.background:SetSize(size.x, size.y - kPulloutHeight - kPulloutGap)
end

local function UpdateLayout(self)

    UpdateBackgroundSize(self)

    local backgroundSize = self.background:GetSize()
    local remainingHeight = backgroundSize.y - kPadding - kButtonHolderHeight + kTextYOffset

    self.webPagesHolder:SetSize(backgroundSize.x - kPadding*2, remainingHeight)
    self.buttonHolder:SetWidth(backgroundSize.x - kPadding*2)
    
end

local function OnPulloutPressed(self, hideCompletely, dontPlaySound)

    self.beingDisplayed = not self.beingDisplayed

    if not dontPlaySound then
        PlayMenuSound("ButtonClick")
    end
    
    if self.beingDisplayed then
        self.pullout:PointDown()
        self.everythingHolder:AnimateProperty("HotSpot", Vector(0, 1, 0), MenuAnimations.FlyIn)
        self.everythingHolder:AnimateProperty("Position", Vector(0, self:GetPulloutHeight() + kPulloutGap, 0), MenuAnimations.FlyIn)
    else
        self.pullout:PointUp()
        self.everythingHolder:AnimateProperty("HotSpot", Vector(0, 0, 0), MenuAnimations.FlyIn)
        self.everythingHolder:AnimateProperty("Position", Vector(0, ConditionalValue(hideCompletely, self:GetPulloutHeight() + kPulloutGap, 0), 0), MenuAnimations.FlyIn)
    end

end

function GUIMenuNewsFeed:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    RequireType({"table", "nil"}, params.webPages, "params.webPages", errorDepth)
    
    PushParamChange(params, "size", params.size or kDefaultSize)
    baseClass.Initialize(self, params, errorDepth)
    PopParamChange(params, "size")
    
    self.webPageObjs = {}
    self.buttonObjs = {}
    
    self.everythingHolder = CreateGUIObject("everythingHolder", GUIObject, self)

    -- Create a pullout at the bottom to allow the news feed to be shown/hidden at will.
    self.pullout = CreateGUIObject("pullout", GUIMenuNewsFeedPullout, self.everythingHolder,
    {
        size = Vector(32, kPulloutHeight, 0),
    })
    self.pullout:HookEvent(self.everythingHolder, "OnSizeChanged", self.pullout.SetWidth)
    self.pullout:SetWidth(self.everythingHolder:GetSize().x)
    self.pullout:SetUpsideDown(true)
    self:HookEvent(self.pullout, "OnPressed", OnPulloutPressed)

    self.background = CreateGUIObject("background", backgroundClass, self.everythingHolder)
    self.background:SetLayer(-1)
    self.background:AlignTop()
    self.background:SetY(kPulloutHeight + kPulloutGap)
    self:HookEvent(self.everythingHolder, "OnSizeChanged", UpdateBackgroundSize)

    self.webPagesHolder = CreateGUIObject("webPagesHolder", GUIObject, self.everythingHolder)
    self.webPagesHolder:AlignTop()
    self.webPagesHolder:SetY(kPulloutHeight + kPulloutGap + kPadding)
    self:HookEvent(self.everythingHolder, "OnSizeChanged", UpdateLayout)
    
    self.buttonHolder = CreateGUIObject("buttonHolder", GUIFlexLayout, self.everythingHolder,
    {
        orientation = "horizontal",
        fixedMinorSize = true,
    })
    self.buttonHolder:SetHeight(kButtonHolderHeight)
    self.buttonHolder:HookEvent(self.everythingHolder, "OnSizeChanged", self.buttonHolder.SetWidth)
    self.buttonHolder:AlignBottom()
    self.buttonHolder:SetY(kTextYOffset)

    self:HookEvent(self, "OnWebPagesChanged", UpdateWebPages)
    self:HookEvent(self, "OnSizeChanged", UpdateLayout)

    self.beingDisplayed = false -- hidden vs "rolled up"
    
    self.everythingHolder:HookEvent(self, "OnSizeChanged", self.everythingHolder.SetSize)
    
    if params.webPages then
        self:SetWebPages(params.webPages)
    end

    UpdateBackgroundSize(self)
    UpdateLayout(self, self.everythingHolder:GetSize())
    
end

function GUIMenuNewsFeed:GetPulloutHeight()
    return kPulloutHeight
end

function GUIMenuNewsFeed:Collapse(hideCompletely, dontPlaySound)
    self.beingDisplayed = true
    OnPulloutPressed(self, hideCompletely, dontPlaySound)
end

function GUIMenuNewsFeed:Show(dontPlaySound)
    self.beingDisplayed = false
    OnPulloutPressed(self, nil, dontPlaySound)
end

-- Returns the GUIWebPageView object associated with the given name -- if it can be found.
function GUIMenuNewsFeed:GetWebPageObject(name)
    return self.webPageObjs[name]
end

-- Attempts to add a new web page config to the list of configs, at the given index, if provided.
-- Returns true if successful, false if it was unable to be added due to a config with the same name
-- already being present.
function GUIMenuNewsFeed:AddWebPage(config, idx)
    
    RequireType("string", config.name, "config.name", 2)
    RequireType("string", config.label, "config.label", 2)
    
    local webPages = self:GetWebPages()
    local insertIdx = idx or (#webPages+1)
    
    -- Ensure this name isn't already taken.
    for i=1, #webPages do
        if webPages[i].name == config.name then
            return false
        end
    end
    
    insertIdx = Clamp(insertIdx, 1, #webPages+1)
    table.insert(webPages, insertIdx, config)
    self:SetWebPages(webPages)
    
    return true
    
end

-- Attempts to find and remove a web page with the given name.  Returns true if successfully
-- removed, false if it couldn't be found.
function GUIMenuNewsFeed:RemoveWebPage(name)
    
    local webPages = self:GetWebPages()
    local idx
    for i=1, #webPages do
        if webPages[i].name == name then
            idx = i
            break
        end
    end
    
    if not idx then
        return false
    end
    
    table.remove(webPages, idx)
    self:SetWebPages(webPages)
    
end
