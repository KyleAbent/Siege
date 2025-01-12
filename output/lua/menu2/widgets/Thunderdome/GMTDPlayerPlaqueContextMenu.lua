-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDPlayerPlaqueContextMenu.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")
Script.Load("lua/menu2/widgets/GUIMenuSimpleTextButton.lua")
Script.Load("lua/menu2/GUIMenuTruncatedText.lua")

local kNoTextureSize = Vector(462, 495, 0)

class "GMTDPlayerPlaqueContextMenu" (GUIObject)

GMTDPlayerPlaqueContextMenu.kBackgroundTexture = PrecacheAsset("ui/thunderdome/plaque_rightclickmenu_bg.dds")
GMTDPlayerPlaqueContextMenu.kTextXOffset = 45
GMTDPlayerPlaqueContextMenu.kTextYOffset = 15

GMTDPlayerPlaqueContextMenu:AddClassProperty("Enabled", true)
GMTDPlayerPlaqueContextMenu:AddClassProperty("SteamID64", "")

function GMTDPlayerPlaqueContextMenu:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    -- Cache locale so we don't resolve it every time we set a player as the menu's target
    self.locale_MutePlayer       = Locale.ResolveString("THUNDERDOME_MUTE_PLAYER_CHAT")
    self.locale_UnmutePlayer     = Locale.ResolveString("THUNDERDOME_UNMUTE_PLAYER_CHAT")
    self.locale_ViewSteamProfile = Locale.ResolveString("THUNDERDOME_VIEW_PLAYER_STEAM_PROFILE")
    self.locale_AddToFriends     = Locale.ResolveString("THUNDERDOME_ADD_TO_FRIENDS")
    self.locale_VoteToKick       = Locale.ResolveString("THUNDERDOME_VOTE_TO_KICK")
    self.locale_KickPlayer       = Locale.ResolveString("THUNDERDOME_KICK_PLAYER")

    self.lastVoteKickTime = 0

    self.steamProfileURL = nil

    RequireType({"boolean", "nil"}, params.enabled, "params.enabled", errorDepth)

    self:SetTexture(self.kBackgroundTexture)
    self:SetSizeFromTexture()
    self:SetColor(1,1,1)

    self.layout = CreateGUIObject("layout", GUIListLayout, self, { orientation = "vertical" }, errorDepth)
    self.layout:SetPosition(self.kTextXOffset, self.kTextYOffset)
    self.layout:SetSpacing(10)

    self.targetNameObj = CreateGUIObject("targetName", GUIMenuTruncatedText, self.layout,
    {
        cls = GUIMenuText,
        font = {family = "AgencyBold", size = 50}
    }, errorDepth)
    self.targetNameObj:SetColor(ColorFrom255(219, 219, 219))
    self.targetNameObj:SetSize(self:GetSize().x - (self.kTextXOffset * 2), self.targetNameObj:CalculateTextSize("AEIOUgjq^&").y)

    self.dividerObj = CreateGUIObject("dividerLine", GUIObject, self.layout)

    local dividerBrightness = 50
    self.dividerObj:SetColor(ColorFrom255(dividerBrightness, dividerBrightness, dividerBrightness))

    self.viewSteamProfileObj = CreateGUIObject("viewSteamProfile", GUIMenuSimpleTextButton, self.layout,
    {
        font = {family = "Agency", size = 52}
    }, errorDepth)
    self.viewSteamProfileObj:SetLabel(self.locale_ViewSteamProfile)
    self:HookEvent(self.viewSteamProfileObj, "OnPressed",
    function()
        local steamID64 = self:GetSteamID64()
        if steamID64 == "" then return end
        Client.ShowWebpage(self.steamProfileURL)
        self:OnHideContextMenu(false)
    end)

    self.addToFriendsObj = CreateGUIObject("addToFriends", GUIMenuSimpleTextButton, self.layout,
    {
        font = {family = "Agency", size = 52}
    }, errorDepth)
    self.addToFriendsObj:SetLabel(self.locale_AddToFriends)
    self:HookEvent(self.addToFriendsObj, "OnPressed",
    function()
        local steamID64 = self:GetSteamID64()
        if steamID64 == "" then return end
        Client.ActivateOverlayToAddFriend(steamID64)
        self:OnHideContextMenu(false)
    end)

    self.mutePlayerObj = CreateGUIObject("mutePlayer", GUIMenuSimpleTextButton, self.layout,
    {
        font = {family = "Agency", size = 52}
    }, errorDepth)
    self:HookEvent(self.mutePlayerObj, "OnPressed",
    function()
        local steamID64 = self:GetSteamID64()
        if steamID64 == "" then return end
        local isMuted = table.icontains(Thunderdome():GetMutedClients(), steamID64)
        if isMuted then
            Thunderdome():RemoveMutedClient(steamID64)
            self.mutePlayerObj:SetLabel(self.locale_MutePlayer)
        else
            Thunderdome():AddMutedClient(steamID64)
            self.mutePlayerObj:SetLabel(self.locale_UnmutePlayer)
        end
        self:OnHideContextMenu(false)

    end)

    self.voteToKickObj = CreateGUIObject("voteToKick", GUIMenuSimpleTextButton, self.layout,
    {
        font = {family = "Agency", size = 52}
    }, errorDepth)
    self.voteToKickObj:SetLabel(self.locale_VoteToKick)
    self:HookEvent(self.voteToKickObj, "OnPressed",
    function()
        local steamID64 = self:GetSteamID64()
        if steamID64 == "" then return end
        Thunderdome():RequestVoteKickPlayer(steamID64)
        self:OnHideContextMenu(false)
    end)

    self.kickPlayerObj = CreateGUIObject("kickPlayer", GUIMenuSimpleTextButton, self.layout,
    {
        font = {family = "Agency", size = 52}
    }, errorDepth)
    self.kickPlayerObj:SetLabel(self.locale_KickPlayer)
    self:HookEvent(self.kickPlayerObj, "OnPressed",
    function()
        local steamID64 = self:GetSteamID64()
        if steamID64 == "" then return end
        Thunderdome():KickPlayerFromGroup(steamID64)
        self:OnHideContextMenu(false)
    end)

    if params.enabled ~= nil then
        self:SetEnabled(params.enabled)
    end

    self:HookEvent(self, "OnOutsideClick",      self.OnOutsideClickHandler)
    self:HookEvent(self, "OnMouseRightClick",   self.OnOutsideRightClickHandler) -- Same close behavior, want to immediately move it if clicked on same plaque
    self:HookEvent(self, "OnOutsideRightClick", self.OnOutsideRightClickHandler)

    self:HookEvent(self, "OnSteamID64Changed", self.OnSteamID64Changed)
    self:HookEvent(self, "OnSizeChanged",      self.OnSizeChanged)

    self:ListenForCursorInteractions()
    self:OnSizeChanged(self:GetSize())

end

function GMTDPlayerPlaqueContextMenu:OnSizeChanged(newSize)
    self.dividerObj:SetSize(newSize.x - (self.kTextXOffset * 2), 5)
end

function GMTDPlayerPlaqueContextMenu:SetPlayerName(name)
    self.targetNameObj:SetText(name)
end

function GMTDPlayerPlaqueContextMenu:OnOutsideClickHandler()
    self:OnHideContextMenu(false)
end

function GMTDPlayerPlaqueContextMenu:OnOutsideRightClickHandler()
    self:OnHideContextMenu(true)
end

function GMTDPlayerPlaqueContextMenu:OnHideContextMenu(rightClicked)
    if self:GetSteamID64() ~= "" then
        self:FireEvent("OnHideContextMenu", rightClicked)
    end
end

function GMTDPlayerPlaqueContextMenu:OnSteamID64Changed(newSteamID)
    if newSteamID == "" then return end

    self.steamProfileURL = string.format("http://steamcommunity.com/profiles/%s", newSteamID)

    local isSelf = newSteamID == GetLocalSteamID64()

    -- Update Add to Friends
    local steamID32 = Shared.ConvertSteamId64To32(newSteamID)
    self.addToFriendsObj:SetEnabled(not Client.GetIsSteamFriend(steamID32))
    self.addToFriendsObj:SetVisible(not isSelf)

    local td = Thunderdome()

    -- Update Mute Player
    local isMuted = table.icontains(td:GetMutedClients(), newSteamID)
    if isMuted then
        self.mutePlayerObj:SetLabel(self.locale_UnmutePlayer)
    else
        self.mutePlayerObj:SetLabel(self.locale_MutePlayer)
    end
    self.mutePlayerObj:SetVisible(not isSelf)

    -- Update Vote to Kick / Kick Player options
    local showVoteToKick = not td:GetIsGroupQueueEnabled()
        and td:GetLobbyState()
        and (td:GetLobbyState() == kLobbyState.WaitingForPlayers)
        and not isSelf

    local showKickPlayer = td:GetIsGroupQueueEnabled()
        and td:GetLocalClientIsOwner()
        and not isSelf

    -- TD-TODO: UI should visually rate-limit Vote to Kick button
    self.voteToKickObj:SetVisible(showVoteToKick)
    self.kickPlayerObj:SetVisible(showKickPlayer)

end
