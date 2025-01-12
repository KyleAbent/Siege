-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/NavBar/Screens/ServerBrowser/Columns/GMSBColumnServerName.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Defines the header and contents classes for the "server name" column of the server browser.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBColumn.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBColumnHeadingText.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")

---@class GMSBColumnHeadingServerName : GMSBColumnHeadingText
class "GMSBColumnHeadingServerName" (GMSBColumnHeadingText)

local function OnHeadingPressed(self)
    
    local serverBrowser = GetServerBrowser()
    assert(serverBrowser)
    
    if serverBrowser:GetSortFunction() == ServerBrowserSortFunctions.ServerName then
        serverBrowser:SetSortFunction(ServerBrowserSortFunctions.ServerNameReversed)
    else
        serverBrowser:SetSortFunction(ServerBrowserSortFunctions.ServerName)
    end
    
end

function GMSBColumnHeadingServerName:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    PushParamChange(params, "label", Locale.ResolveString("SERVERBROWSER_SERVERNAME"))
    GMSBColumnHeadingText.Initialize(self, params, errorDepth)
    PopParamChange(params, "label")
    
    self:HookEvent(self, "OnPressed", OnHeadingPressed)
    
end


---@class GMSBColumnContentsServerName : GMSBColumnContents
class "GMSBColumnContentsServerName" (GMSBColumnContents)

local function OnSelectedChanged(self, selected)
    
    if selected then
        self.serverName:SetColor(MenuStyle.kHighlight)
    else
        self.serverName:SetColor(MenuStyle.kServerNameColor)
    end
    
end

function GMSBColumnContentsServerName:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    GMSBColumnContents.Initialize(self, params, errorDepth)
    
    self.textLayout = CreateGUIObject("textLayout", GUIListLayout, self,
    {
        orientation = "horizontal",
        spacing = 20,
    })
    self.textLayout:AlignLeft()
    
    self.rookieText = CreateGUIObject("rookieText", GUIText, self.textLayout)
    self.rookieText:SetFont(MenuStyle.kServerNameFont)
    self.rookieText:SetColor(MenuStyle.kRookieTextColor)
    self.rookieText:SetText(Locale.ResolveString("SERVERBROWSER_ROOKIEONLY"))
    self.rookieText:SetVisible(self.entry:GetRookieOnly())
    self.rookieText:HookEvent(self.entry, "OnRookieOnlyChanged", self.rookieText.SetVisible)
    
    self.serverName = CreateGUIObject("serverName", GUIText, self.textLayout)
    self.serverName:SetFont(MenuStyle.kServerNameFont)
    self.serverName:SetColor(MenuStyle.kServerNameColor)
    self.serverName:SetText(self.entry:GetServerName())
    self.serverName:HookEvent(self.entry, "OnServerNameChanged", self.serverName.SetText)
    
    self:HookEvent(self.entry, "OnSelectedChanged", OnSelectedChanged)
    OnSelectedChanged(self, self.entry:GetSelected())
    
end

RegisterServerBrowserColumnType("ServerName", GMSBColumnHeadingServerName, GMSBColumnContentsServerName, 13, 640)
