-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/widgets/Thunderdome/GUIMenuLobbyFriendList.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Widget that displays a list of friends of the player.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIText.lua")
Script.Load("lua/menu2/MenuStyles.lua")
Script.Load("lua/menu2/GUIMenuBasicBox.lua")
Script.Load("lua/menu2/widgets/GUIMenuScrollPane.lua")

Script.Load("lua/menu2/widgets/Thunderdome/GUIMenuLobbyFriendEntry.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GUIMenuLobbyFriendsSearchBox.lua")

Script.Load("lua/menu2/NavBar/Screens/Options/Mods/GUIMenuModEntryLayout.lua")  --??? what's this for?


---@class GUIMenuFriendsList : GUIObject
local baseClass = GUIObject
class "GUIMenuLobbyFriendList" (baseClass)

-- Maximum frequency of triggering friends list update manually (eg opening/closing menu quickly)
local kFriendsListUpdateTriggerThrottle = 2
local kVerticalSpacing = 8 -- vertical spacing between label, searchBox, and listBox.
local kPadding = 12 -- padding around edges of items.
local kSearchBoxHeight = 73
local kMinListHeight = 32

-- Refresh friends list every X seconds. Only occurs when GUI object is active/shown
local kFriendsListRefreshInterval = 3

-- Debug tool to prevent list from changing.
local freezeFriendsList = false

local function UpdateLayout(self)
    
    local currentY = 0
    
    currentY = currentY + kVerticalSpacing
    
    self.searchBox:SetY(currentY)
    
    currentY = currentY + kSearchBoxHeight
    currentY = currentY + kVerticalSpacing
    
    self.searchBox:SetHeight(currentY - self.searchBox:GetPosition().y)
    self.listBox:SetY(currentY)
    
    local listHeight = self:GetSize().y - currentY
    listHeight = math.max(listHeight, kMinListHeight)
    self.listBox:SetHeight(listHeight)

end

local function UpdateSearchFilter(self)

    PROFILE("GUIMenuLobbyFriendList_UpdateSearchFilter")
    
    local td = Thunderdome()
    local lobbyId = td:GetActiveLobbyId()

    local IsInLobby = function(friendId)
        return Thunderdome():GetLobbyContainsMember( lobbyId, friendId )
    end

    local filterText = self.searchBox:GetValue()
    if filterText == "" then
        
        -- Skip filtering step if text is empty.
        for steamId64, entry in pairs(self.friendEntries) do
            entry:SetExpanded( not IsInLobby(steamId64) )
        end
    
    else
        
        for steamId64, entry in pairs(self.friendEntries) do
            local friendName = entry:GetFriendName()
            local expanded = SubStringInString(filterText, friendName) and not IsInLobby(steamId64)
            entry:SetExpanded(expanded)
        end
    
    end

end

-- Expensive callback routine !!!
-- So only update friends list when player screen is visible
local nextAllowedFriendsListUpdateTriggering = 0
function GUIMenuLobbyFriendList:RefreshFriendsList()
    local now = Shared.GetTime()
    
    if (MainMenu_GetIsOpened() and now >= nextAllowedFriendsListUpdateTriggering) and self:GetVisible() then
        nextAllowedFriendsListUpdateTriggering = now + kFriendsListUpdateTriggerThrottle
        Client.TriggerFriendsListUpdate()
    end
end

local function OnLobbyFriendsInviteListUpdated(self, friendsTbl)
    
    PROFILE("GUIMenuLobbyFriendList_OnLobbyFriendsInviteListUpdated")
    
    if freezeFriendsList then
        return
    end
    
    -- Update the friends objects, creating new ones if we don't have enough.
    local oldFriendEntries = self.friendEntries
    self.friendEntries = OrderedIterableDict()

    for i = 1, #friendsTbl do
        
        local tableEntry = friendsTbl[i]
        
        local friendName = tableEntry[1]
        local steamId64 = tableEntry[2]
        local friendState = tableEntry[3]
        local serverAddress = tableEntry[4]

        local entryObj = oldFriendEntries[steamId64]

        if entryObj == nil then
        -- Entry for this friend not found, create a new one.
            if not serverAddress or serverAddress == "" then
                local objName = "friendEntry"..tostring(#self.friendEntries + 1)
                entryObj = CreateGUIObject(objName, GUIMenuLobbyFriendListEntry, self.listLayout,
                {
                    friendName    = friendName,
                    steamId64     = steamId64,
                    friendState   = friendState,
                    serverAddress = serverAddress,
                })
                entryObj:HookEvent(self.listLayout, "OnSizeChanged", entryObj.SetWidth)
            end
        elseif entryObj and not serverAddress then
        -- Entry exists.  Update the existing data.
            entryObj:SetFriendName(friendName)
            entryObj:SetFriendState(friendState)
        end

        if entryObj then
            entryObj:SetLayer(i)    -- ensure they display in this order in the layout.
            self.friendEntries[steamId64] = entryObj
            oldFriendEntries[steamId64] = nil
        end
    
    end
    
    -- Destroy old friend entries.
    for _, entry in pairs(oldFriendEntries) do
        if entry then
            entry:Destroy()
        end
    end

    UpdateSearchFilter(self)

end

function GUIMenuLobbyFriendList:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    baseClass.Initialize(self, params, errorDepth)
    
    -- Mapping of SteamID64 --> friend entry.  Order of elements will match the order of the entries
    -- in the last "OnSteamFriendsUpdated" event.
    self.friendEntries = OrderedIterableDict()
    
    self.searchBox = CreateGUIObject("searchBox", GUIMenuFriendsListSearchBox, self)
    self.searchBox:SetHeight(kSearchBoxHeight)
    self.searchBox:HookEvent(self, "OnSizeChanged", self.searchBox.SetWidth)
    self:HookEvent(self.searchBox, "OnValueChanged", UpdateSearchFilter)
    
    self.listBox = CreateGUIObject("listBox", GUIMenuBasicBox, self,
    {
        StrokeColor = Color(1,1,1,1),
        StrokeWidth = 2,
    }, errorDepth)
    self.listBox:HookEvent(self, "OnSizeChanged", self.listBox.SetWidth)
    
    self.listBoxScrollPane = CreateGUIObject("listBoxScrollPane", GUIMenuScrollPane, self.listBox)
    
    -- Scroll pane size is sync'd to the list box's size.
    self.listBoxScrollPane:HookEvent(self.listBox, "OnSizeChanged", self.listBoxScrollPane.SetSize)
    
    -- Scroll pane's pane size is sync'd to the width of the list box.
    self.listBoxScrollPane:HookEvent(self.listBox, "OnSizeChanged", self.listBoxScrollPane.SetPaneWidth)
    
    -- Create a vertical list layout to store the friends list entries.
    self.listLayout = CreateGUIObject("listLayout", GUIMenuModEntryLayout, self.listBoxScrollPane,
    {
        orientation = "vertical",
        fixedMinorSize = true,
    })
    
    -- List layout's width is sync'd to the contents width of the scroll pane.
    self.listLayout:HookEvent(self.listBoxScrollPane, "OnContentsSizeChanged", self.listLayout.SetWidth)
    self.listLayout:SetWidth(self.listBoxScrollPane:GetContentsSize())
    
    -- Scroll pane's pane-height is sync'd to the height of the layout.
    self.listBoxScrollPane:HookEvent(self.listLayout, "OnSizeChanged", self.listBoxScrollPane.SetPaneHeight)
    
    self:HookEvent(self, "OnSizeChanged", UpdateLayout)
    UpdateLayout(self)
    
    self:HookEvent(GetGlobalEventDispatcher(), "OnSteamFriendsUpdated", OnLobbyFriendsInviteListUpdated)
    
    self:AddTimedCallback(self.RefreshFriendsList, kFriendsListRefreshInterval, true)
    self:RefreshFriendsList()
    
    -- (Attempt to) refresh the friends list whenever the menu is opened with the friends
    -- list visible.
    self:HookEvent(GetMainMenu(), "OnVisibleChanged", self.RefreshFriendsList)
    
end
