-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/NavBar/Screens/ServerBrowser/Columns/GMSBColumnMapName.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Defines the header and contents classes for the "map name" column of the server browser.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBColumn.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBColumnHeadingText.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")

---@class GMSBColumnHeadingMapName : GMSBColumnHeadingText
class "GMSBColumnHeadingMapName" (GMSBColumnHeadingText)

local function OnHeadingPressed(self)
    
    local serverBrowser = GetServerBrowser()
    assert(serverBrowser)
    
    if serverBrowser:GetSortFunction() == ServerBrowserSortFunctions.MapName then
        serverBrowser:SetSortFunction(ServerBrowserSortFunctions.MapNameReversed)
    else
        serverBrowser:SetSortFunction(ServerBrowserSortFunctions.MapName)
    end

end

function GMSBColumnHeadingMapName:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    PushParamChange(params, "label", Locale.ResolveString("SERVERBROWSER_MAP"))
    GMSBColumnHeadingText.Initialize(self, params, errorDepth)
    PopParamChange(params, "label")
    
    self:HookEvent(self, "OnPressed", OnHeadingPressed)

end


---@class GMSBColumnContentsMapName : GMSBColumnContents
class "GMSBColumnContentsMapName" (GMSBColumnContents)

local function OnSelectedChanged(self, selected)
    
    if selected then
        self.mapName:SetColor(MenuStyle.kHighlight)
    else
        self.mapName:SetColor(MenuStyle.kServerNameColor)
    end

end

function GMSBColumnContentsMapName:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    GMSBColumnContents.Initialize(self, params, errorDepth)
    
    self.mapName = CreateGUIObject("mapName", GUIText, self)
    self.mapName:SetFont(MenuStyle.kServerNameFont)
    self.mapName:SetColor(MenuStyle.kServerNameColor)
    self.mapName:AlignCenter()
    self.mapName:SetText(self.entry:GetMapName())
    self.mapName:HookEvent(self.entry, "OnMapNameChanged", self.mapName.SetText)
    
    self:HookEvent(self.entry, "OnSelectedChanged", OnSelectedChanged)
    OnSelectedChanged(self, self.entry:GetSelected())

end

RegisterServerBrowserColumnType("MapName", GMSBColumnHeadingMapName, GMSBColumnContentsMapName, 6.5, 704)
