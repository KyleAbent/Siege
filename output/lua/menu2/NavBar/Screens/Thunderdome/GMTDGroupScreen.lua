-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/NavBar/Screens/Thunderdome/GMTDGroupScreen.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- Events
--        OnMapVoteButtonPressed - Just the "OnPressed" event from GUIButton. Fires when the map vote button is pressed.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/UnorderedSet.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GUIMenuLobbyFriendsInviteButton.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDChatWidget.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDPlayerPlaqueWidget.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDGroupSearchButton.lua")

local DEBUG_SHOW_ALL_PLAQUES = false

local kPadding = 36

---@class GMTDGroupScreen
GMTDGroupScreen = nil

class "GMTDGroupScreen" (GUIObject)

GMTDGroupScreen.kStatusTextColor_Default              = ColorFrom255(189, 189, 189)
GMTDGroupScreen.kStatusTextColor_WaitingForCommanders = ColorFrom255(255, 0, 0)

GMTDGroupScreen.kPlaqueLayoutSize = Vector(642, 1000, 0)

GMTDGroupScreen.kPlaqueSyncCallbackDelay = 0.8  --1
GMTDGroupScreen.kMemberNameDataUpdateDelay = 2
GMTDGroupScreen.kPlaqueSyncMinimumCheckDuration = 10 -- Check every kPlaqueSyncCallbackDelay seconds for at least this many seconds

local kChatWinWidth = 1764


function GMTDGroupScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.playerPlaques = {}

    self.titleText = CreateGUIObject("titleText", GUIStyledText, self, params, errorDepth)
    self.titleText:SetFont("AgencyBold", 90)
    self.titleText:SetStyle(MenuStyle.kThunderdomePlayerNameLabel)
    self.titleText:AlignTopLeft()
    self.titleText:SetPosition(kPadding, 9)
    self.titleText:SetText(Locale.ResolveString( "GROUP QUEUE" ))

    self.chatWindow = CreateGUIObject("chatWindow", GMTDChatWidget, self,
    {
        disableTeamColors = true,
        label = Locale.ResolveString("THUNDERDOME_CHAT_LABEL"),
        inputHeight = 78,
        entryYOffset = 4,
        lobbyUseType = kLobbyUsageType.Group,
    }, errorDepth)
    self.chatWindow:SetPosition(-kPadding, 150)
    self.chatWindow:AlignTopRight()
    self.chatWindow:SetWidth(kChatWinWidth)
    self.chatWindow:SetChatMessagesEnabled(true)
    self.chatWindow:SetBackPadding(20)
    
    --Note: this works regardless of local-client's Steam Overlay setting(enabled) or not
    self.friendInviteBtn = CreateGUIObject("inviteButton", GUIMenuLobbyFriendsInviteButton, self,
    {
        label = Locale.ResolveString("THUNDERDOME_LOBBYSCRN_INVITE_BUTTON_LABEL"),
        font = MenuStyle.kCustomizeViewBuyButtonFont,
        fontColor = MenuStyle.kOptionHeadingColor,
        fontGlow = MenuStyle.kCustomizeViewBuyButtonFont,
        fontGlowStyle = MenuStyle.kCustomizeBarButtonAlienGlow,
    }, errorDepth)
    self.friendInviteBtn:AlignTopLeft()
    self.friendInviteBtn:SetPosition((kChatWinWidth * 0.5) + (self.friendInviteBtn:GetSize().x), kPadding)  --TD-TODO revise padding/width, diff str lens (localized) change offset
    
    self.playerPlaquesLayout = CreateGUIObject("plaquesLayout", GUIColumnLayout, self, params, errorDepth)
    self.playerPlaquesLayout:SetPosition(kPadding * 2, 200)
    self.playerPlaquesLayout:SetSize(self.kPlaqueLayoutSize)
    self.playerPlaquesLayout:SetNumColumns( 1 )
    self.playerPlaquesLayout:SetLeftPadding( 0 )    --kPadding
    self.playerPlaquesLayout:SetColumnSpacing( 0 )
    self.playerPlaquesLayout:SetSpacing( 32 )

    self.searchButton = CreateGUIObject("goToMapVoteScreenButton", GMTDGroupSearchButton, self)
    self.searchButton:SetPosition(kPadding, 940)
    self.searchButton:SetVisible( false )
    self:HookEvent(self.searchButton, "OnMatchSearchPressed", self.OnMatchSearchPressed)

    self.searching = false

    self.rightClickMenu = CreateGUIObject("rightClickMenu", GMTDPlayerPlaqueContextMenu, self, nil, errorDepth)
    self.rightClickMenu:SetLayer(99)
    self.rightClickMenu:SetVisible(false)
    self:HookEvent(self.rightClickMenu, "OnHideContextMenu", self.OnHideRightClickMenu)

    for _ = 1, kFriendsGroupMaxSlots do

        local plaque = CreateGUIObject("playerPlaque", GMTDPlayerPlaqueWidget, self.playerPlaquesLayout, params, errorDepth)
        plaque:SetSize( self.kPlaqueLayoutSize.x - 64 , 192)
        plaque:SetVisible(true)
        table.insert(self.playerPlaques, plaque)

        self:HookEvent(plaque, "OnShowRightClickMenu", self.OnShowRightClickMenu)

    end

    self.statusBar = CreateGUIObject("statusBar", GMTDScreenStatusWidget, self, params, errorDepth)
    self.statusBar:AlignBottom()

    self:ListenForCursorInteractions()

    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)

    self:HookEvent(self, "OnHide", self.OnHide)

    self.TDOnLobbyMemberJoined = function(_, steamID64Str)
        self:TD_OnLobbyMemberJoined(steamID64Str)
    end

    self.TDOnLobbyJoined = function( clientObject, lobbyId )
        self:Reset()

        self:TD_OnLobbyJoined( lobbyId )
    end

    self.TDOnLobbyMemberLeave = function(_, steamID64Str)
        self:TD_OnLobbyMemberLeave(steamID64Str)
    end

    self.TDOnLobbyMemberKicked = function(_, steamID64Str)
        self:TD_OnLobbyMemberKicked(steamID64Str)
    end

    self.TmpChatMsg = function(clientModeObject, lobbyId, senderName, message, teamIndex, senderSteamID64)
        self.chatWindow.TDOnChatMessage(clientModeObject, lobbyId, senderName, message, teamIndex, senderSteamID64)
    end

    self.OnGroupStateRollback = function( clientObj, lobbyId )
        self.friendInviteBtn:SetVisible( true )
        self.searchButton:SetVisible( false )
        self.searchButton:Reset()
        self.searching = false
    end

    self.OnGroupStateChange = function( clientObj, newState, oldState, lobbyId )
        local tdGui = GetThunderdomeMenu()
        assert(tdGui, "Error: No ThunderdomeMenu object found")

        local barState = GetStatusBarStateFromLobbyState( newState )
        tdGui:SetStatusBarStage( barState, lobbyId )

        if newState == kLobbyState.GroupReady then
            self.searching = false
            self.searchButton:SetVisible( false )
            self.searchButton:Reset()
        end
    end

    self.TDOnLobbyMemberMetadataChange = function(_, memberId, lobbyId)
        if lobbyId ~= Thunderdome():GetGroupLobbyId() then
            return
        end

        if not self.metadataUpdateCallback then
            self.metadataUpdateCallback = self:AddTimedCallback(self.CallbackUpdateMemberNames, self.kMemberNameDataUpdateDelay, true)
        end
    end


    self:SetUpdates( true )

end

function GMTDGroupScreen:RegisterEvents()
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyJoined,          self.TDOnLobbyJoined)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberJoin,      self.TDOnLobbyMemberJoined)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberLeave,     self.TDOnLobbyMemberLeave)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberKicked,    self.TDOnLobbyMemberKicked)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange,  self.TDOnLobbyMemberMetadataChange)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUIChatMessage,          self.chatWindow.TDOnChatMessage)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUIGroupStateRollback,   self.OnGroupStateRollback)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIGroupStateChange,     self.OnGroupStateChange)
end

function GMTDGroupScreen:UnregisterEvents()
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyJoined,        self.TDOnLobbyJoined)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberJoin,    self.TDOnLobbyMemberJoined)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberLeave,   self.TDOnLobbyMemberLeave)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberKicked,  self.TDOnLobbyMemberKicked)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange,  self.TDOnLobbyMemberMetadataChange)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIChatMessage,        self.chatWindow.TDOnChatMessage)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIGroupStateRollback, self.OnGroupStateRollback)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIGroupStateChange,   self.OnGroupStateChange)
end

function GMTDGroupScreen:GetStatusBar()
    return self.statusBar
end

function GMTDGroupScreen:OnShowRightClickMenu(plaque)

    local steamID = plaque:GetSteamID64() -- plaque guarantees steam id is valid, or else we wouldn't have received the event
    local ssMouse = GetGlobalEventDispatcher():GetMousePosition()
    local lsMouse = self:ScreenSpaceToLocalSpace(ssMouse)
    self.rightClickMenu:SetPosition(lsMouse)
    self.rightClickMenu:SetSteamID64(steamID)
    self.rightClickMenu:SetPlayerName(plaque:GetPlayerName())
    self.rightClickMenu:SetModal()
    self.rightClickMenu:SetVisible(true)

    -- If plaque is too big and will hang off the bottom, it'll get cut off by the window cropper.
    local menuSize = self.rightClickMenu:GetSize()
    if (lsMouse.y + menuSize.y) >= self:GetSize().y then
        self.rightClickMenu:SetHotSpot(0, 1)
    else
        self.rightClickMenu:SetHotSpot(0, 0)
    end

end

local function GetPointOverPlaque(point, plaque)

    local plaquePos = plaque:GetPosition()
    local plaqueSize = plaque:GetSize()

    if point.x < plaquePos.x or point.y < plaquePos.y then
        return false
    end

    local lsMax = Vector(plaquePos.x + plaqueSize.x, plaquePos.y + plaqueSize.y, 0)
    if point.x > lsMax.x or point.y > lsMax.y then
        return false
    end

    return true

end

function GMTDGroupScreen:OnHideRightClickMenu(rightClickedExit)

    -- Reset previously right-clicked plaque
    self.rightClickMenu:SetVisible(false)
    self.rightClickMenu:ClearModal()
    self.rightClickMenu:SetSteamID64("")

    -- If we right clicked on another plaque (or the same one)
    -- then treat this as another context menu opening.
    if rightClickedExit then

        local ssMouse = GetGlobalEventDispatcher():GetMousePosition()
        local lsMouse = self.playerPlaquesLayout:ScreenSpaceToLocalSpace(ssMouse)

        -- Check if the mouse is over a plaque
        local overPlaque
        for i = 1, #self.playerPlaques do
            local plaque = self.playerPlaques[i]
            if GetPointOverPlaque(lsMouse, plaque) then
                overPlaque = plaque
                break
            end
        end

        if overPlaque and overPlaque:GetSteamID64() ~= "" then
            self:OnShowRightClickMenu(overPlaque)
        end

    end

end

function GMTDGroupScreen:OnHide()

    self.friendInviteBtn.friendsList:SetVisible(false)

end

function GMTDGroupScreen:OnSizeChanged(newSize)
    self.statusBar:SetWidth(newSize.x - (kPadding * 2))

    local spaceLeftY = newSize.y - (self.chatWindow:GetPosition().y + self.chatWindow:GetSize().y)
    self.statusBar:SetY(-((spaceLeftY - self.statusBar:GetSize().y) / 2))
end

function GMTDGroupScreen:UpdatePlaquesFromMemberList()
    local td = Thunderdome()
    if not td then return end

    local lobbyId = td:GetGroupLobbyId()
    if not lobbyId then return end

    local members = td:GetMemberListLocalData( lobbyId )
    if not members or #members <= 0 then return end

    local arePlaquesSyncedWithTDMembersList = true
    local emptyPlaqueIndices = {}

    -- Ensure all present plaques are assigned to valid members
    local memberSteamIDs = {}

    for i = 1, #members do
        local memberSteamID = members[i].steamid or ""
        memberSteamIDs[memberSteamID] = i
    end

    -- Invalidate all plaques containing unknown members and build empty plaques list
    for j = 1, #self.playerPlaques do

        local plaque = self.playerPlaques[j]
        local steamid = plaque:GetSteamID64()

        if steamid == "" or not memberSteamIDs[steamid] then
            table.insert(emptyPlaqueIndices, j)
            plaque:SetSteamID64("")
        end

    end

    for i = 1, #members do

        local memberSteamID = members[i].steamid
        local foundMemberIDInPlaques = false

        for j = 1, #self.playerPlaques do

            local plaque = self.playerPlaques[j]

            if memberSteamID == plaque:GetSteamID64() then
                foundMemberIDInPlaques = true
                break
            end

        end

        if not foundMemberIDInPlaques then

            if #emptyPlaqueIndices > 0 then
                local firstEmptyPlaque = self.playerPlaques[emptyPlaqueIndices[1]]
                firstEmptyPlaque:SetSteamID64(memberSteamID) -- Assign a plaque to this un-assigned steamid.

                table.remove(emptyPlaqueIndices, 1) -- Remove that plaque index from empty plaque indices list.
                arePlaquesSyncedWithTDMembersList = false -- Run one more time, since packets might still be on the wire.
            else
                SLog("[TD-UI] ERROR: Plaque for client [%s] not found, but we don't have an empty plaque!", memberSteamID)
            end

            self:UpdatePlayerNames()

        end
    end
    
end

function GMTDGroupScreen:UpdatePlayerNames()
    if not self.nameOverrideCallback then
        self.nameOverrideCallback = self:AddTimedCallback(self.CallbackApplyNameOverrides, 0.1, true)
    end
end

function GMTDGroupScreen:CallbackApplyNameOverrides()

    local steamIDToNames, processedAll = GetThunderdomeNameOverrides( Thunderdome():GetGroupLobbyId() )

    -- Set all the override names for plaques
    for i = 1, #self.playerPlaques do

        local plaque = self.playerPlaques[i]
        local overrideName = steamIDToNames[plaque:GetSteamID64()]
        if overrideName then
            plaque:SetNameOverride(overrideName)
        end

    end

    self.chatWindow:SetNameOverridesTable(steamIDToNames)

    if processedAll then
        self:RemoveTimedCallback(self.nameOverrideCallback)
        self.nameOverrideCallback = nil
    end

end

function GMTDGroupScreen:CallbackUpdateMemberNames()

    local steamIDToNames, processedAll = GetThunderdomeNameOverrides( Thunderdome():GetGroupLobbyId() )

    -- Set all the override names for plaques
    for i = 1, #self.playerPlaques do

        local plaque = self.playerPlaques[i]
        local overrideName = steamIDToNames[plaque:GetSteamID64()]
        if overrideName then
            plaque:SetNameOverride(overrideName)
        end

    end

    self.chatWindow:SetNameOverridesTable(steamIDToNames)

    if processedAll then
        self:RemoveTimedCallback(self.metadataUpdateCallback)
        self.metadataUpdateCallback = nil
    end

end

function GMTDGroupScreen:TD_OnLobbyMemberJoined(steamID64Str)

    -- Find first available player plaque, but check if this new steamID64 is unique first.
    local alreadyHasPlaque = false
    local firstEmptyPlaque

    for i = 1, #self.playerPlaques do
        local plaque = self.playerPlaques[i]
        if not firstEmptyPlaque and plaque:GetSteamID64() == "" then
            firstEmptyPlaque = plaque
        end

        if plaque:GetSteamID64() == steamID64Str then
            alreadyHasPlaque = true
            break
        end
    end

    if not alreadyHasPlaque then
        if firstEmptyPlaque then
            firstEmptyPlaque:SetSteamID64(steamID64Str)
            self:UpdatePlayerNames()
        else
            SLog("[TD-UI] ERROR: GMTDGroupScreen:TD_OnLobbyMemberJoined - Incoming Lobby Member '%s' is unique, but there is no empty plaque!", steamID64Str)
        end
    end

end

function GMTDGroupScreen:TD_OnLobbyMemberLeave(steamID64Str)

    -- Find the plaque related to the leaving player.
    for i = 1, #self.playerPlaques do

        local plaque = self.playerPlaques[i]
        if plaque:GetSteamID64() == steamID64Str then

            plaque:SetSteamID64("")

            -- Remove parent and re-add to layout so that the newly "empty" one is now the last one.
            plaque:SetParent(nil)
            plaque:SetParent(self.playerPlaquesLayout)

            -- Update the tracking list of plaques.
            table.remove(self.playerPlaques, i)
            table.insert(self.playerPlaques, plaque)

            break

        end

    end

    self:UpdatePlayerNames()

    self.searchButton:Reset()

end

function GMTDGroupScreen:TD_OnLobbyMemberKicked(steamID64Str)
    self:TD_OnLobbyMemberLeave(steamID64Str)
end

function GMTDGroupScreen:TD_OnLobbyJoined( lobbyId )
    if DEBUG_SHOW_ALL_PLAQUES then
        local steamID = GetLocalSteamID64()
        for i = 1, #self.playerPlaques do
            self.playerPlaques[i]:SetSteamID64(steamID)
        end

        self:UpdatePlayerNames()

        return
    end

    local memberData = Thunderdome():GetMemberListLocalData( lobbyId )
    
    local numMembers = #memberData
    for i = 1, numMembers do
        local steamID = memberData[i].steamid or "" -- Make sure steam id is a string.
        --SLog("\tSet Plaque #%s's SteamID: '%s'", i, steamID)
        self.playerPlaques[i]:SetSteamID64(steamID)
    end

    for i = numMembers + 1, #self.playerPlaques do
        -- Clear player plaques that do not have players in the lobby
        self.playerPlaques[i]:SetSteamID64("")
    end

    -- Make sure that we have the local player's plaque in the lobby.
    local localSteamID = GetLocalSteamID64()
    local found = false
    local firstEmptyPlaque

    for i = 1, #self.playerPlaques do

        local plaque = self.playerPlaques[i]

        if not firstEmptyPlaque and plaque:GetSteamID64() == "" then
            firstEmptyPlaque = plaque
        end

        if plaque:GetSteamID64() == localSteamID then
            found = true
            break
        end

    end

    if not found then

        if firstEmptyPlaque then
            firstEmptyPlaque:SetSteamID64(localSteamID)
        else
            SLog("[TD-UI] ERROR: Plaque for local client not found, but we don't have an empty plaque!")
        end

    end

    self:UpdatePlayerNames()

end

function GMTDGroupScreen:OnUpdate( deltaTime, time )
    if GetThunderdomeMenu():GetCurrentScreen() ~= kThunderdomeScreen.Group then
        --SLog("[TD-UI] Screen not Group, skip update")
        return
    end
    
    local groupId = Thunderdome():GetGroupLobbyId()
    if groupId then

        if not self.plaqueSyncCallback then
            self.plaqueSyncCallback = self:AddTimedCallback(self.UpdatePlaquesFromMemberList, self.kPlaqueSyncCallbackDelay, true)
        end

        local showSearchBtn = 
            ( Client.GetLobbyOwnerId( groupId ) == Thunderdome():GetLocalSteam64Id() ) and
            Client.GetNumLobbyMembers( Thunderdome():GetGroupLobbyId() ) >= kFriendsGroupMinMemberCountForSearch

        self.searchButton:SetVisible( showSearchBtn )

        local groupState = Thunderdome():GetGroupLobbyState()

        if groupState >= kLobbyState.GroupSearching or Client.GetNumLobbyMembers(groupId) == kFriendsGroupMaxSlots then
            self.friendInviteBtn:SetVisible(false)
            -- hide the friends list if it's open
            self.friendInviteBtn.friendsList:SetVisible(false)
        else
            self.friendInviteBtn:SetVisible(true)
        end

        -- Handle search state changes
        local isSearching = Thunderdome():GetIsSearching()

        if self.searching ~= isSearching then

            if isSearching then
                self.searchButton:SetSearching()
            else
                self.searchButton:Reset()
            end

            self.searching = isSearching

        end

    else

        if self.plaqueSyncCallback then
        --only poll when Group-Mode is active
            self:RemoveTimedCallback(self.plaqueSyncCallback)
        end

    end

end

function GMTDGroupScreen:OnMatchSearchPressed()
    SLog("GMTDGroupScreen:OnMatchSearchPressed()")
    local td = Thunderdome()
    assert(td, "Error: No Thunderdome object found")

    if self.searching then

        td:CancelGroupSearch()
        self.searchButton:Reset()
        self.searching = false

        -- Pre-emptively set the status bar stage back to waiting, assume group-search cancel will
        -- always succeed.
        GetThunderdomeMenu():SetStatusBarStage( kStatusBarStage.GroupWaiting, td:GetGroupLobbyId() )

        -- Same with friend invite button
        self.friendInviteBtn:SetVisible(true)

    else

        td:StartGroupSearch()
        self.searchButton:SetSearching()
        self.searching = true

    end
end

function GMTDGroupScreen:Uninitialize()
    self:UnregisterEvents()

    if self.plaqueSyncCallback then
        self:RemoveTimedCallback(self.plaqueSyncCallback)
    end
end

function GMTDGroupScreen:Reset()

    self.chatWindow:Clear()

    self.searchButton:Reset()
    self.searchButton:SetVisible(false)

    self.friendInviteBtn:SetVisible(true)

    self.statusBar:Reset()

    if self.nameOverrideCallback then
        self:RemoveTimedCallback(self.nameOverrideCallback)
        self.nameOverrideCallback = nil
    end

    if self.metadataUpdateCallback then
        self:RemoveTimedCallback(self.metadataUpdateCallback)
        self.metadataUpdateCallback = nil
    end

    for i = 1, #self.playerPlaques do
        self.playerPlaques[i]:SetSteamID64("")
    end

end
