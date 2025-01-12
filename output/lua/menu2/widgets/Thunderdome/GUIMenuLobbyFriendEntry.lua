-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
-- 
-- lua/menu2/widgets/Thunderdome/GUIMenuLobbyFriendListEntry.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
--    A single entry for a single friend for the GUIMenuFriendsList.
--
--  Parameters (* = required)
--     *friendName
--     *steamId64
--     *friendState
--
--  Properties
--      FriendName      Name of the friend.
--      SteamID64       Steam id of the friend, in SteamID64 format (stored as a string).
--      FriendState     The steam friend state of this friend.  Can be any of the following:
--                          Client.FriendState_Offline
--                          Client.FriendState_Online
--                          Client.FriendState_Busy
--                          Client.FriendState_Away
--                          Client.FriendState_Snooze
--                          Client.FriendState_LookingTrade
--                          Client.FriendState_LookingPlay
--                          Client.FriendState_InGame
--
--  Events
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIGlobalEventDispatcher.lua")

Script.Load("lua/menu2/GUIMenuTruncatedText.lua")
Script.Load("lua/menu2/MenuStyles.lua")
Script.Load("lua/menu2/PlayerScreen/FriendsList/GUIMenuAvatar.lua")
Script.Load("lua/menu2/GUIMenuFlashGraphic.lua")

Script.Load("lua/menu2/popup/GUIMenuPopupSimpleMessage.lua")

---@class GUIMenuFriendsListEntry : GUIObject
---@field public GetExpanded function @From Expandable wrapper
---@field public SetExpanded function @From Expandable wrapper
---@field public GetExpansion function @From Expandable wrapper
local baseClass = GUIObject
baseClass = GetExpandableWrappedClass(baseClass)
class "GUIMenuLobbyFriendListEntry" (baseClass)

assert(Client.FriendState_Offline) -- this should be loaded by now... otherwise lots of stuff stops working...

GUIMenuLobbyFriendListEntry:AddCompositeClassProperty("FriendName", "playerName", "Text")
GUIMenuLobbyFriendListEntry:AddCompositeClassProperty("SteamID64", "avatar")
GUIMenuLobbyFriendListEntry:AddClassProperty("FriendState", Client.FriendState_Offline)
GUIMenuLobbyFriendListEntry:AddClassProperty("ServerAddress", "")

local kHeight = 120

local kAvatarSize = 96

local kEdgePadding = (kHeight - kAvatarSize) * 0.5
local kSpacing = 18 -- space between elements within the entry (eg between avatar and text).
local kFont = ReadOnly{ family = "Microgramma", size = 26}

local kInGameColor  = HexToColor("ade247")
local kOnlineColor  = HexToColor("68bdda")
local kAwayColor    = HexToColor("3f6a7e")
local kOfflineColor = HexToColor("7a7a7a")

local kButtonHeight = 64
local kInviteDimTexture = PrecacheAsset("ui/newMenu/invite_friend_dim.dds")
local kInviteLitTexture = PrecacheAsset("ui/newMenu/invite_friend_lit.dds")

-- Seconds between invites... steam doesn't throttle this at all, it would seem.
local kPlayerInviteCooldown = 25

local kFriendStateData =
{
    [Client.FriendState_Offline]        = {color = kOfflineColor, locale = Locale.ResolveString("FRIEND_STATE_OFFLINE"), },
    [Client.FriendState_Online]         = {color = kOnlineColor,  locale = Locale.ResolveString("FRIEND_STATE_ONLINE"), },
    [Client.FriendState_Busy]           = {color = kAwayColor,    locale = Locale.ResolveString("FRIEND_STATE_BUSY"), },
    [Client.FriendState_Away]           = {color = kAwayColor,    locale = Locale.ResolveString("FRIEND_STATE_AWAY"), },
    [Client.FriendState_Snooze]         = {color = kAwayColor,    locale = Locale.ResolveString("FRIEND_STATE_SNOOZE"), },
    [Client.FriendState_LookingTrade]   = {color = kOnlineColor,  locale = Locale.ResolveString("FRIEND_STATE_LOOKING_TRADE"), },
    [Client.FriendState_LookingPlay]    = {color = kOnlineColor,  locale = Locale.ResolveString("FRIEND_STATE_LOOKING_PLAY"), },
    [Client.FriendState_InGame]         = {color = kInGameColor,  locale = Locale.ResolveString("FRIEND_STATE_IN_GAME"), },
}

local function UpdateLayout(self)
    
    PROFILE("GUIMenuFriendsListEntry:UpdateLayout")
    
    local width = self:GetSize().x
    width = width - kEdgePadding * 2
    width = width - kAvatarSize
    width = width - kSpacing
    
    local buttonOffset = -kEdgePadding

    if self.inviteFriendButton:GetVisible() then
        self.inviteFriendButton:SetX(buttonOffset)
        local buttonWidth = self.inviteFriendButton:GetSize().x
        buttonWidth = buttonWidth + kSpacing
        width = width - buttonWidth
    end
    
    -- Update the text holder sizes to use the remaining space.
    self.playerNameHolder:SetWidth(width)
    self.statusHolder:SetWidth(width)

end

local function UpdateFriendState(self)

    local friendState = self:GetFriendState()
    local serverAddress = self:GetServerAddress()
    
    -- See if we can figure out which server they're on.  If so, display that as their status
    -- instead of the more generic "In-Game".
    if friendState == Client.FriendState_InGame and serverAddress ~= "" then
        
        local serverBrowser = GetServerBrowser()
        assert(serverBrowser)
        local serverSet = serverBrowser:GetServerSet()
        assert(serverSet)
        local serverEntry = serverSet[serverAddress]
        if serverEntry then
        
            local serverName = serverEntry:GetServerName()      --XX can trigger on "Thunderdome"
            local statusText = string.format(Locale.ResolveString("FRIEND_PLAYING_ON"), serverName)
            self.status:SetText(statusText)
            self.status:SetColor(kFriendStateData[Client.FriendState_InGame].color)
            return
        
        --TODO Need to try to handle localhost vs TD-instance, if TD...disable invite status

        end
        
    end
    
    local friendStateData = kFriendStateData[friendState] or kFriendStateData[Client.FriendState_Offline]
    local stateLocale = friendStateData.locale
    local stateColor = friendStateData.color
    
    self.status:SetText(stateLocale)
    self.status:SetColor(stateColor)
    
end

local function InviteFriendCooldownFinished(self)
    self.inviteFriendButton:SetEnabled(true)
end

local function OnInviteFriendPressed(self)
    local lobbyId = Thunderdome():GetActiveLobbyId()
    if not lobbyId then
        lobbyId = Thunderdome():GetGroupLobbyId()
    end
    assert(lobbyId, "Error: No LobbyModel found for any lobby-type")

    local friendId = self:GetSteamID64()
    if Client.SendLobbyInvite( lobbyId, friendId ) then
    -- Throttle invitation requests.  Too easy to spam, otherwise.
        PlayMenuSound("ButtonClick")
        self.inviteFriendButton:SetEnabled(false)
        self:AddTimedCallback(InviteFriendCooldownFinished, kPlayerInviteCooldown)
    end    
end

local function UpdateInviteFriendButtonVisibility(self)

    if Shared.GetThunderdomeEnabled() then
    --Do NOT invite if we're on a TD server, safety check
        self.inviteFriendButton:SetVisible(false)
        return
    end
    
    local friendState = self:GetFriendState()
    if friendState == Client.FriendState_Offline then
    --Note: Invisible users are considered offline
        self.inviteFriendButton:SetVisible(false)
        return
    end
    
    local td = Thunderdome()
    local lobbyId = td:GetActiveLobbyId()
    if lobbyId then
        if Thunderdome():GetLobbyContainsMember(lobbyId, self:GetSteamID64() ) then
        --Ensure friend-entry is not in local-client's active-lobby
            self.inviteFriendButton:SetVisible(false)
        end
    end

    self.inviteFriendButton:SetVisible(true)
end


function GUIMenuLobbyFriendListEntry:Initialize(params, errorDepth)
    
    PROFILE("GUIMenuLobbyFriendListEntry:Initialize")
    
    errorDepth = (errorDepth or 1) + 1
    
    RequireType("string", params.friendName, "params.friendName", errorDepth)
    RequireType("string", params.steamId64, "params.steamId64", errorDepth)
    RequireType("number", params.friendState, "params.friendState", errorDepth)
    if not kFriendStateData[params.friendState] then
        error(string.format("Invalid value of params.friendState.  Got %d.", params.friendState), errorDepth)
    end
    
    baseClass.Initialize(self, params, errorDepth)
    
    self.avatar = CreateGUIObject("avatar", GUIMenuAvatar, self)
    self.avatar:SetSize(kAvatarSize, kAvatarSize)
    self.avatar:AlignLeft()
    self.avatar:SetPosition(kEdgePadding, 0)
    
    self.playerNameHolder = CreateGUIObject("playerNameHolder", GUIMenuTruncatedText, self,
    {
        cls = GUIText,
        font = kFont,
        color = MenuStyle.kOptionHeadingColor,
        text = "",
    })
    self.playerName = self.playerNameHolder:GetObject()
    self.playerNameHolder:SetAnchor(0, 0.3333)
    self.playerNameHolder:SetHotSpot(0, 0.5)
    self.playerNameHolder:SetX(kEdgePadding + kAvatarSize + kSpacing)
    self.playerNameHolder:HookEvent(self.playerName, "OnSizeChanged", self.playerNameHolder.SetHeight)
    
    self.statusHolder = CreateGUIObject("statusHolder", GUIMenuTruncatedText, self,
    {
        cls = GUIText,
        font = kFont,
        color = MenuStyle.kOptionHeadingColor,
        text = "",
    })
    self.status = self.statusHolder:GetObject()
    self.statusHolder:SetAnchor(0, 0.6667)
    self.statusHolder:SetHotSpot(0, 0.5)
    self.statusHolder:SetX(kEdgePadding + kAvatarSize + kSpacing)
    self.statusHolder:HookEvent(self.status, "OnSizeChanged", self.playerNameHolder.SetHeight)
    
    local buttonClass = GUIMenuLobbyFriendsListEntryInviteFriendButton
    if not buttonClass then
        local cls = GUIMenuFlashGraphic
        cls = GetCursorInteractableWrappedClass(cls)
        cls = GetTooltipWrappedClass(cls)
        class "GUIMenuLobbyFriendsListEntryInviteFriendButton" (cls)
        GUIMenuLobbyFriendsListEntryInviteFriendButton:AddClassProperty("Enabled", true)
        buttonClass = GUIMenuLobbyFriendsListEntryInviteFriendButton
    end
    
    self.inviteFriendButton = CreateGUIObject("inviteFriendButton", buttonClass, self,      --TD-TODO Change to be text+icon, e.g. [(icon) Invite]
    {
        defaultTexture = kInviteDimTexture,
        hoverTexture = kInviteLitTexture,
        tooltip = Locale.ResolveString("THUNDERDOME_FRIENDENTRY_INVITE_BUTTON_LABEL"),
    })
    local inviteScaleFactor = kButtonHeight / self.inviteFriendButton:GetSize().y
    self.inviteFriendButton:SetScale(inviteScaleFactor, inviteScaleFactor)
    self.inviteFriendButton:AlignRight()
    self:HookEvent(self.inviteFriendButton, "OnPressed", OnInviteFriendPressed)
    self:HookEvent(self, "OnFriendStateChanged", UpdateInviteFriendButtonVisibility)
    self:HookEvent(self.inviteFriendButton, "OnSizeChanged", UpdateLayout)
    self:HookEvent(self.inviteFriendButton, "OnScaleChanged", UpdateLayout)
    self:HookEvent(self.inviteFriendButton, "OnVisibleChanged", UpdateLayout)
    
    self:HookEvent(self, "OnSizeChanged", UpdateLayout)
    UpdateLayout(self)
    
    self:HookEvent(self, "OnFriendStateChanged", UpdateFriendState)
    self:HookEvent(self, "OnServerAddressChanged", UpdateFriendState)
    local serverBrowser = GetServerBrowser()
    assert(serverBrowser)
    self:HookEvent(serverBrowser, "OnServerSetChanged", UpdateFriendState)
    UpdateFriendState(self)
    
    self:SetFriendName(params.friendName)
    self:SetSteamID64(params.steamId64)
    self:SetFriendState(params.friendState)
    
    self:SetHeight(kHeight)
    
    UpdateInviteFriendButtonVisibility(self)
    
end
