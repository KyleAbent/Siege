-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/NavBar/Screens/Thunderdome/GMTDLobbyScreen.lua
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
Script.Load("lua/menu2/widgets/Thunderdome/GMTDVoteStatusWidget.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDGoToMapVoteScreenButton.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDCommanderVolunteerButton.lua")

local DEBUG_SHOW_ALL_PLAQUES = false

local kPadding = 36

class "GMTDLobbyScreen" (GUIObject)

GMTDLobbyScreen.kMapButtonTexture      = PrecacheAsset("ui/thunderdome/lobby_vote_background.dds")
GMTDLobbyScreen.kMapButtonFrameTexture = PrecacheAsset("ui/thunderdome/lobby_vote_frame.dds")
GMTDLobbyScreen.kMapThumbnailsTexture  = PrecacheAsset("ui/thunderdome/mapvote_mapimages.dds")

GMTDLobbyScreen.kStatusTextColor_Default              = ColorFrom255(189, 189, 189)
GMTDLobbyScreen.kStatusTextColor_WaitingForCommanders = ColorFrom255(255, 0, 0)

GMTDLobbyScreen.kPlaqueLayoutSize = Vector(642, 1000, 0)

GMTDLobbyScreen.kPlaqueSyncCallbackDelay = 1
GMTDLobbyScreen.kMemberNameDataUpdateDelay = 2
GMTDLobbyScreen.kPlaqueSyncMinimumCheckDuration = 10 -- Check every kPlaqueSyncCallbackDelay seconds for at least this many seconds

local kChatWinWidth = 1764

function GMTDLobbyScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.playerPlaques = {}
    self.numCommanderVolunteers = 0

    self.titleText = CreateGUIObject("titleText", GUIStyledText, self, params, errorDepth)
    self.titleText:SetFont("AgencyBold", 90)
    self.titleText:SetStyle(MenuStyle.kThunderdomePlayerNameLabel)
    self.titleText:AlignTopLeft()
    self.titleText:SetPosition(kPadding, 9)
    self.titleText:SetText(Locale.ResolveString("THUNDERDOME_LOBBY_TITLE"))

    self.goToMapVoteScreenButton = CreateGUIObject("goToMapVoteScreenButton", GMTDGoToMapVoteScreenButton, self)
    self.goToMapVoteScreenButton:SetPosition(kPadding, 150)
    self.goToMapVoteScreenButton:SetVisible(false)
    self:ForwardEvent(self.goToMapVoteScreenButton, "OnShowMapVoteScreen")

    self.commandButton = CreateGUIObject("goToMapVoteScreenButton", GMTDCommanderVolunteerButton, self)
    self.commandButton:SetPosition(kPadding, 150)
    self:HookEvent(self.commandButton, "OnCommandSelected", self.OnCommandVolunteered)

    self.chatWindow = CreateGUIObject("chatWindow", GMTDChatWidget, self,
    {
        disableTeamColors = true,
        label = Locale.ResolveString("THUNDERDOME_CHAT_LABEL"),
        inputHeight = 78,
        entryYOffset = 4,
        lobbyUseType = kLobbyUsageType.Match,
    }, errorDepth)
    self.chatWindow:SetPosition(-kPadding, 150)
    self.chatWindow:AlignTopRight()
    self.chatWindow:SetWidth(kChatWinWidth)
    self.chatWindow:SetChatMessagesEnabled(true)
    self.chatWindow:SetBackPadding(20)

    self.chatWindowHeight = self.chatWindow:GetSize().y

    self.voteKickStatus = CreateGUIObject("voteKickStatus", GMTDVoteStatusWidget, self)
    self.voteKickStatus:AlignTopRight()
    self.voteKickStatus:SetPosition(-kPadding, 150)
    self.voteKickStatus:SetWidth(kChatWinWidth)
    self.voteKickStatus:SetVisible(false)

    self.voteKickHeight = self.voteKickStatus:GetSize().y + kPadding / 2

    self:HookEvent(self.voteKickStatus, "OnVoteCast", self.OnVoteCast)

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
    self.playerPlaquesLayout:SetPosition(kPadding, 600)
    self.playerPlaquesLayout:SetSize(self.kPlaqueLayoutSize)
    self.playerPlaquesLayout:SetNumColumns(2)
    self.playerPlaquesLayout:SetLeftPadding(0)
    self.playerPlaquesLayout:SetColumnSpacing(0)
    self.playerPlaquesLayout:SetSpacing(45)

    self.rightClickMenu = CreateGUIObject("rightClickMenu", GMTDPlayerPlaqueContextMenu, self, nil, errorDepth)
    self.rightClickMenu:SetLayer(99)
    self.rightClickMenu:SetVisible(false)
    self:HookEvent(self.rightClickMenu, "OnHideContextMenu", self.OnHideRightClickMenu)

    for _ = 1, kLobbyPlayersLimit do

        local plaque = CreateGUIObject("playerPlaque", GMTDPlayerPlaqueWidget, self.playerPlaquesLayout, params, errorDepth)
        plaque:SetSize((self.kPlaqueLayoutSize.x / 2) - 40, 96)
        plaque:SetVisible(true)
        table.insert(self.playerPlaques, plaque)

        self:HookEvent(plaque, "OnShowRightClickMenu", self.OnShowRightClickMenu)

    end

    self.statusBar = CreateGUIObject("statusBar", GMTDScreenStatusWidget, self, params, errorDepth)
    self.statusBar:AlignBottom()

    self:ListenForCursorInteractions()

    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)

    self:HookEvent(self, "OnShow", self.OnShowLobbyScreen)
    self:HookEvent(self, "OnHide", self.OnHideLobbyScreen)

    self.TDOnLobbyMemberJoined = function(_, steamID64Str)
        self:TD_OnLobbyMemberJoined(steamID64Str)
    end

    self.TDOnLobbyJoined = function( clientObject, lobbyId )
        self:TD_OnLobbyJoined( lobbyId )
    end

    self.TDOnLobbyMemberLeave = function(_, steamID64Str)
        self:TD_OnLobbyMemberLeave(steamID64Str)
    end

    self.TDOnLobbyMemberKicked = function(_, steamID64Str)
        self:TD_OnLobbyMemberKicked(steamID64Str)
    end

    self.TDOnLobbyKickStarted = function(_, memberId, lobbyId)
        self:TD_OnLobbyKickStarted(memberId, lobbyId)
    end

    self.TDOnLobbyKickEnded = function(_, memberId, lobbyId)
        self:TD_OnLobbyKickEnded(memberId, lobbyId)
    end

    self.TDMapVoteStarted = function()
        self:ShowMapVoteButton()
        self.commandButton:ClosePopup()
    end

    self.TDOnLobbyStateRollback = function()
        local td = Thunderdome()

        if td:GetLobbyState() and td:GetLocalCommandAble() then
            self:ShowMapVoteButton()
        else
            self:ShowCommandButton()
            self.commandButton:ClosePopup()
        end

        self:UpdatePlayerPlaques()
    end

    self.TDOnCommandersWaitEnd = function()
        self:UpdatePlayerPlaques()
    end

    self.TDOnLobbyMemberMetadataChange = function(_, memberId, lobbyId)
        if lobbyId ~= Thunderdome():GetActiveLobbyId() then
            return
        end

        if not self.metadataUpdateCallback then
            self.metadataUpdateCallback = self:AddTimedCallback(self.CallbackUpdateMemberNames, self.kMemberNameDataUpdateDelay, true)
        end
    end

    self.goToMapVoteScreenButton:SetVisible(false)
    self.commandButton:SetVisible(true)

    self:SetUpdates(true)

end

function GMTDLobbyScreen:RegisterEvents()
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyJoined,        self.TDOnLobbyJoined)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyStateRollback, self.TDOnLobbyStateRollback)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberJoin,    self.TDOnLobbyMemberJoined)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberLeave,   self.TDOnLobbyMemberLeave)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberKicked,  self.TDOnLobbyMemberKicked)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange,  self.TDOnLobbyMemberMetadataChange)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyKickVoteStarted, self.TDOnLobbyKickStarted)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyKickVoteEnded,   self.TDOnLobbyKickEnded)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUICommandersWaitEnd,  self.TDOnCommandersWaitEnd)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIMapVoteStart,       self.TDMapVoteStarted)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUIChatMessage,        self.chatWindow.TDOnChatMessage)
end

function GMTDLobbyScreen:UnregisterEvents()
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberJoin,    self.TDOnLobbyMemberJoined)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberLeave,   self.TDOnLobbyMemberLeave)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberKicked,  self.TDOnLobbyMemberKicked)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyKickVoteStarted, self.TDOnLobbyKickStarted)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyKickVoteEnded,   self.TDOnLobbyKickEnded)
    
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange,  self.TDOnLobbyMemberMetadataChange)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyJoined,        self.TDOnLobbyJoined)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyStateRollback, self.TDOnLobbyStateRollback)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIMapVoteStart,       self.TDMapVoteStarted)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUICommandersWaitEnd,  self.TDOnCommandersWaitEnd)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIChatMessage,        self.chatWindow.TDOnChatMessage)
end

function GMTDLobbyScreen:GetGoToVoteButton()
    return self.goToMapVoteScreenButton
end

function GMTDLobbyScreen:GetStatusBar()
    return self.statusBar
end

function GMTDLobbyScreen:OnShowRightClickMenu(plaque)

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

function GMTDLobbyScreen:OnHideRightClickMenu(rightClickedExit)

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

function GMTDLobbyScreen:OnSizeChanged(newSize)
    self.statusBar:SetWidth(newSize.x - (kPadding * 2))

    local spaceLeftY = newSize.y - (self.chatWindow:GetPosition().y + self.chatWindow:GetSize().y)
    self.statusBar:SetY(-((spaceLeftY - self.statusBar:GetSize().y) / 2))
end

function GMTDLobbyScreen:UpdatePlaquesFromMemberList()
    local td = Thunderdome()
    if not td then return end

    local lobbyId = td:GetActiveLobbyId()
    if not lobbyId then return end

    local members = td:GetMemberListLocalData( lobbyId )
    if not members or #members == 0 then return end

    local arePlaquesSyncedWithTDMembersList = true
    local emptyPlaqueIndices = {}
    for i = 1, #members do
        local firstRun = i == 1
        local memberSteamID = members[i].steamid
        local foundMemberIDInPlaques = false
        for j = 1, #self.playerPlaques do
            local plaque = self.playerPlaques[j]
            if firstRun and plaque:GetSteamID64() == "" then
                table.insert(emptyPlaqueIndices, j)
            elseif memberSteamID == plaque:GetSteamID64() then
                foundMemberIDInPlaques = true
                if not firstRun then -- needs to count empty plaques on first run
                    break
                end
            end
        end

        if not foundMemberIDInPlaques then
            assert(#emptyPlaqueIndices > 0)
            local firstEmptyPlaque = self.playerPlaques[emptyPlaqueIndices[1]]
            firstEmptyPlaque:SetSteamID64(memberSteamID) -- Assign a plaque to this un-assigned steamid.
            table.remove(emptyPlaqueIndices, 1) -- Remove that plaque index from empty plaque indices list.
            arePlaquesSyncedWithTDMembersList = false -- Run one more time, since packets might still be on the wire.
            self:UpdatePlayerNames()
        end
    end
    
end

function GMTDLobbyScreen:UpdatePlayerNames()
    if not self.nameOverrideCallback then
        self.nameOverrideCallback = self:AddTimedCallback(self.CallbackApplyNameOverrides, 0.1, true)
    end
end

function GMTDLobbyScreen:CallbackApplyNameOverrides()

    local steamIDToNames, processedAll = GetThunderdomeNameOverrides( Thunderdome():GetActiveLobbyId() )

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

function GMTDLobbyScreen:CallbackUpdateMemberNames()

    local steamIDToNames, processedAll = GetThunderdomeNameOverrides( Thunderdome():GetActiveLobbyId() )

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

function GMTDLobbyScreen:TD_OnLobbyMemberJoined(steamID64Str)

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
            SLog("[TD-UI] ERROR: GMTDLobbyScreen:TD_OnLobbyMemberJoined - Incoming Lobby Member '%s' is unique, but there is no empty plaque!", steamID64Str)
        end
    end

    self:UpdatePlayerPlaques()

end

function GMTDLobbyScreen:TD_OnLobbyMemberLeave(steamID64Str)

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
    self:UpdatePlayerPlaques()

end

function GMTDLobbyScreen:TD_OnLobbyMemberKicked(steamID64Str)
    self:TD_OnLobbyMemberLeave(steamID64Str)
end

-- Fallback event handler for when the lobby GUI is shown before we've actually joined a valid lobby
function GMTDLobbyScreen:TD_OnLobbyJoined( lobbyId )
    local td = Thunderdome()
    assert(td, "Error: no valid Thunderdome object found")

    if not td:GetActiveLobbyId() then
    --halt and bail for times when we're only in a Group
        return
    end

    self:InitializeLobbyGUI( lobbyId )
end

function GMTDLobbyScreen:TD_OnLobbyKickStarted(memberId)
    SLog("GMTDLobbyScreen:TD_OnLobbyKickStarted( %s )", memberId)

    local td = Thunderdome()
    local lobbyId = td:GetActiveLobbyId()

    local memberModel = td:GetMemberLocalData(lobbyId, memberId)
    assert(memberModel)

    local nameOverrides = GetThunderdomeNameOverrides( lobbyId )
    local memberName = nameOverrides[memberId] or memberModel.name
    local voteText = StringReformat(Locale.ResolveString("VOTE_KICK_PLAYER_QUERY"), { name = memberName })

    self:SetVoteKickStatusVisible(true)
    self.voteKickStatus:StartNewVote(voteText)
end

function GMTDLobbyScreen:TD_OnLobbyKickEnded(memberId)
    SLog("GMTDLobbyScreen:TD_OnLobbyKickEnded( %s )", memberId)

    self.voteKickStatus:EndVote()
    self:SetVoteKickStatusVisible(false)
end

function GMTDLobbyScreen:OnVoteCast(vote)
    SLog("GMTDLobbyScreen:OnVoteCast( %s )", vote)
    Thunderdome():CastLocalKickVote(vote)
end

function GMTDLobbyScreen:SetVoteKickStatusVisible(enabled)
    if enabled then
        self.chatWindow:SetY(150 + self.voteKickHeight)
        self.chatWindow:SetHeight(self.chatWindowHeight - self.voteKickHeight)
        self.voteKickStatus:SetVisible(true)
    else
        self.chatWindow:SetY(150)
        self.chatWindow:SetHeight(self.chatWindowHeight)
        self.voteKickStatus:SetVisible(false)
    end
end

function GMTDLobbyScreen:UpdatePlayerPlaques()

    -- Update player plaque data, e.g. when lobby state changes
    for i = 1, #self.playerPlaques do
        local p = self.playerPlaques[i]

        p:UpdatePlayerDataElements( lobbyId )
    end

end

function GMTDLobbyScreen:InitializeLobbyGUI( lobbyId )
    SLog("GMTDLobbyScreen:InitializeLobbyGUI( %s )", lobbyId)
    local td = Thunderdome()

    if DEBUG_SHOW_ALL_PLAQUES then
        local steamID = GetLocalSteamID64()
        for i = 1, #self.playerPlaques do
            self.playerPlaques[i]:SetSteamID64(steamID)
        end

        self:UpdatePlayerNames()

        return
    end

    local memberData = td:GetMemberListLocalData( lobbyId )

    local titleText = ""
    if td:GetIsGroupId( lobbyId ) then
        titleText = Locale.ResolveString("THUNDERDOME_GROUP_TITLE")
    else
        if td:GetIsPrivateLobby() then
            titleText = Locale.ResolveString("THUNDERDOME_LOBBY_PRIVATE_TITLE")
        else
            titleText = Locale.ResolveString("THUNDERDOME_LOBBY_TITLE")
        end
    end
    
    self.titleText:SetText(titleText)
    
    local numMembers = #memberData
    for i = 1, numMembers do
        local steamID = memberData[i].steamid or "" -- Make sure steam id is a string.
        --SLog("\tSet Plaque #%s's SteamID: '%s'", i, steamID)
        self.playerPlaques[i]:SetSteamID64(steamID)
    end

    local numPlaques = #self.playerPlaques
    for i = numMembers + 1, numPlaques do
        -- Clear player plaques that do not have players available to them
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

    -- Update map vote buttons based on lobby state - we may not receive the map vote event
    -- because another screen is being shown while the event is processed.
    if td:GetLobbyState() and (td:GetLobbyState() >= kLobbyState.WaitingForMapVote or td:GetLocalCommandAble()) then
        self:ShowMapVoteButton()
        self.commandButton:ClosePopup()
        self:SetVoteKickStatusVisible(false)
    else
        self:ShowCommandButton()
    end

    local activeKickVote = td:GetActiveKickVote()
    if activeKickVote then
        self:TD_OnLobbyKickStarted(activeKickVote)
    else
        self.voteKickStatus:Reset()
        self:SetVoteKickStatusVisible(false)
    end
end

function GMTDLobbyScreen:OnShowLobbyScreen()
    SLog("GMTDLobbyScreen:OnShowLobbyScreen()")
    local td = Thunderdome()
    local lobbyId = td:GetActiveLobbyId()

    if not lobbyId then
        return
    end

    self:InitializeLobbyGUI( td:GetActiveLobbyId() )

    self:UpdatePlayerPlaques()
end

function GMTDLobbyScreen:OnHideLobbyScreen()
    self.commandButton:ClosePopup()
    self.friendInviteBtn.friendsList:SetVisible(false)
end

function GMTDLobbyScreen:OnUpdate(deltaTime, time)
    if GetThunderdomeMenu():GetCurrentScreen() ~= kThunderdomeScreen.Lobby then
        return
    end

    local td = Thunderdome()
    assert(td, "Error: Failed to get Thunderdome object")

    local activeId = td:GetActiveLobbyId()
    if activeId then

        if not self.plaqueSyncCallback then
            self.plaqueSyncCallback = self:AddTimedCallback(self.UpdatePlaquesFromMemberList, self.kPlaqueSyncCallbackDelay, true)
        end

    else
        if self.plaqueSyncCallback then
        --only run update when IN Match lobby
            self:RemoveTimedCallback(self.plaqueSyncCallback)
        end
    end
end

function GMTDLobbyScreen:OnCommandVolunteered()
    Thunderdome():SetLocalCommandAble(1)
    self:ShowMapVoteButton()
end

function GMTDLobbyScreen:ShowCommandButton()
    self.goToMapVoteScreenButton:SetVisible(false)
    self.commandButton:SetVisible(true)
end

function GMTDLobbyScreen:ShowMapVoteButton()
    self.goToMapVoteScreenButton:SetVisible(true)
    self.commandButton:SetVisible(false)
end

function GMTDLobbyScreen:Uninitialize()
    self:UnregisterEvents()
    if self.plaqueSyncCallback then
        self:RemoveTimedCallback(self.plaqueSyncCallback)
    end
end

function GMTDLobbyScreen:Reset()

    self.numCommanderVolunteers = 0

    self.chatWindow:Clear()

    self.voteKickStatus:Reset()
    self:SetVoteKickStatusVisible(false)

    self.commandButton:Reset()
    self.goToMapVoteScreenButton:Reset()

    self.goToMapVoteScreenButton:SetVisible(false)
    self.commandButton:SetVisible(true)

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
