-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDPlayerPlaqueWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- Events
--      OnShowRightClickMenu    This plaque has been right clicked, and is allowed to do so.
--                                  plaque - This clicked plaque
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/GUIMenuBasicBox.lua")
Script.Load("lua/menu2/GUIMenuTruncatedText.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDPlayerPlaqueContextMenu.lua")

local kRightSidePadding = 10

-- Gets the proper name overrides for _all_ of the current members in the local lobby model.
function GetThunderdomeNameOverrides( lobbyId )

    local td = Thunderdome()
    if not td then
        SLog("[TD-UI] WARNING: GetThunderdomeNameOverrides Delayed - Could not get ThunderdomeManager...")
        return {}, false
    end

    local memberData = td:GetMemberListLocalData( lobbyId )
    if #memberData <= 0 then
        SLog("[TD-UI] WARNING: GetThunderdomeNameOverrides Delayed - Lobby has zero members...")
        return {}, false
    end

    local processedAllMembers = true
    local memberSteamIDsToNames = {}
    for i = 1, #memberData do

        local joinTime = memberData[i].join_time or 0
        local steamid = memberData[i].steamid or ""
        local originalName = memberData[i].name or ""

        -- Only add to table if we have all relevant information.
        if joinTime ~= 0 and steamid ~= "" and originalName ~= "" then
            table.insert(memberSteamIDsToNames, {id = steamid, join_time = joinTime, name = originalName})
        else
            processedAllMembers = false
        end

    end

    local function SortByJoinTime(a, b)
        return a.join_time < b.join_time
    end

    table.sort(memberSteamIDsToNames, SortByJoinTime)

    -- Now we finally go through and do all the names
    local processedNames = {}
    local steamIDToProcessedName = {}
    for i = 1, #memberSteamIDsToNames do

        local member = memberSteamIDsToNames[i]

        local originalName = member.name
        if not processedNames[originalName] then
            processedNames[originalName] = 1
            steamIDToProcessedName[member.id] = originalName

            for j = i + 1, #memberSteamIDsToNames do
                local otherMember = memberSteamIDsToNames[j]
                if not otherMember then break end

                if otherMember.name == originalName then
                    processedNames[originalName] = processedNames[originalName] + 1
                    steamIDToProcessedName[otherMember.id] = string.format("%s (%d)", originalName, processedNames[originalName])
                end
            end
        end

    end

    return steamIDToProcessedName, processedAllMembers

end

class "GMTDPlayerPlaqueWidget" (GUIButton)

GMTDPlayerPlaqueWidget.kFriendsIconTexture = PrecacheAsset("ui/thunderdome/friend_icon.dds")
GMTDPlayerPlaqueWidget.kGroupIconTexture = PrecacheAsset("ui/newMenu/server_browser/people_icon.dds")
GMTDPlayerPlaqueWidget.kCommanderIconTexture = PrecacheAsset("ui/badges/commander.dds")
GMTDPlayerPlaqueWidget.kMapVotedIconTexture = PrecacheAsset("ui/thunderdome/mapvote_checkmark.dds")
GMTDPlayerPlaqueWidget.kMapVotedIconSize = Vector(112, 86, 0)

GMTDPlayerPlaqueWidget.kAvatarSize = 96
GMTDPlayerPlaqueWidget.kEmptyLabel = "THUNDERDOME_EMPTY_PLAQUE"
GMTDPlayerPlaqueWidget.kEllipsisAnimationHz = 1
GMTDPlayerPlaqueWidget.kEllipsisMaxDots = 3

GMTDPlayerPlaqueWidget.kPlayerNameMaxWidth = 320--174
GMTDPlayerPlaqueWidget.kPlayerNameHeight = 95--65

GMTDPlayerPlaqueWidget.kNameColor_Empty = Color(0.4, 0.4, 0.4)
GMTDPlayerPlaqueWidget.kNameColor_Active = Color(0.8, 0.8, 0.8)
GMTDPlayerPlaqueWidget.kGroupColor_1 = Color(0.4, 0.8, 0.4)
GMTDPlayerPlaqueWidget.kGroupColor_2 = Color(0.4, 0.4, 0.8)

GMTDPlayerPlaqueWidget.kGroupBgStrokeWidth = 3
GMTDPlayerPlaqueWidget.kGroupBgColor_1 = Color(0.4, 0.8, 0.4, 0.45)
GMTDPlayerPlaqueWidget.kGroupBgColor_2 = Color(0.4, 0.4, 0.8, 0.45)

GMTDPlayerPlaqueWidget:AddClassProperty("SteamID64", "")
GMTDPlayerPlaqueWidget:AddClassProperty("NumEllipsis", 0)
GMTDPlayerPlaqueWidget:AddClassProperty("FriendsIconEnabled", true)
GMTDPlayerPlaqueWidget:AddClassProperty("NameOverride", "")

GMTDPlayerPlaqueWidget:AddClassProperty("CommanderIconEnabled", true)

function GMTDPlayerPlaqueWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIButton.Initialize(self, params, errorDepth)

    self.updateEllipsisCallback = nil

    --self:SetColor(Color(1,1,0,0.7))

    self.avatar = CreateGUIObject("avatar", GUIMenuAvatar, self, params, errorDepth)
    self.avatar:SetSize(self.kAvatarSize, self.kAvatarSize)
	self.avatar:SetAlignsToPixels(true)

    local commIconSize = self.kAvatarSize / 2.2
    self.commanderIcon = CreateGUIObject("commanderIcon", GUIObject, self.avatar, params ,errorDepth)
    self.commanderIcon:SetSize(commIconSize, commIconSize)
    self.commanderIcon:SetTexture(self.kCommanderIconTexture)
    self.commanderIcon:SetColor(1, 1, 1)
    self.commanderIcon:AlignBottomRight()
    self.commanderIcon:SetVisible(false)

    self.mapvoteCheck = CreateGUIObject("mapvoteCheck", GUIObject, self.avatar, params, errorDepth)
    self.mapvoteCheck:SetTexture(self.kMapVotedIconTexture)
    self.mapvoteCheck:SetSize(commIconSize * (self.kMapVotedIconSize.x / self.kMapVotedIconSize.y), commIconSize)
    self.mapvoteCheck:SetColor(1, 1, 1)
    self.mapvoteCheck:AlignBottomRight()
    self.mapvoteCheck:SetVisible(false)

    self.playerName = CreateGUIObject("playerName", GUIMenuTruncatedText, self,
    {
        cls = GUIMenuText,
    }, errorDepth)

    self.emptyText = Locale.ResolveString(self.kEmptyLabel)

    self.playerName:SetSize(self.kPlayerNameMaxWidth, self.kPlayerNameHeight)
    self.playerName:SetPosition(self.avatar:GetSize().x + kRightSidePadding, -12)
    self.playerName:SetFont("AgencyBold", 32)
    self.playerName:SetText(self.emptyText)
    self.playerName:SetColor(self.kNameColor_Active)

    self.skilltierIcon = CreateGUIObject("skillIcon", GUIMenuSkillTierIcon, self, params, errorDepth)
    self.skilltierIcon:SetPosition(self.avatar:GetSize().x + kRightSidePadding, 40)

    --[[
    self.friendsIcon = CreateGUIObject("friendsIcon", GUIObject, self, params, errorDepth)
    self.friendsIcon:SetTexture(self.kFriendsIconTexture)
    self.friendsIcon:SetColor(1,1,1)
    self.friendsIcon:SetSizeFromTexture()
    self.friendsIcon:AlignBottomLeft()
    self.friendsIcon:SetPosition(-40, -10)
    self.friendsIcon:SetVisible(false)
    --]]

    self.groupIcon = CreateGUIObject("groupId", GUIObject, self, params, errorDepth)
    self.groupIcon:SetTexture(self.kGroupIconTexture)
    self.groupIcon:SetSizeFromTexture()
    self.groupIcon:AlignBottomLeft()
    self.groupIcon:SetPosition(-40, -10)
    self.groupIcon:SetColor(self.kGroupColor_1)
	self.groupIcon:SetAlignsToPixels(true)

    self.groupBackground = CreateGUIObject("groupBackground", GUIMenuBasicBox, self.avatar, params, errorDepth)
    self.groupBackground:SetSize(self.avatar:GetSize())
    self.groupBackground:SetStrokeColor(self.kGroupBgColor_1)
    self.groupBackground:SetStrokeWidth(self.kGroupBgStrokeWidth)
    self.groupBackground:SetLayer(-1)

    self:HookEvent(self, "OnMouseRightClick",   self.OnRightMouseDown)
    self:HookEvent(self, "OnSteamID64Changed",  self.OnSteamID64Changed)
    self:HookEvent(self, "OnSizeChanged",       self.OnSizeChanged)
    self:HookEvent(self, "OnFriendsIconEnabledChanged", self.OnSteamID64Changed)
    self:HookEvent(self, "OnNameOverrideChanged", self.OnNameOverrideChanged)

    self:OnSizeChanged(self:GetSize())
    self:SetChildrenVisible(false)

    self.TDOnMemberDataChanged = function(clientModeObject, steamID64, lobbyId)
        if steamID64 == self:GetSteamID64() then
            self:UpdatePlayerDataElements( lobbyId )
        end
    end

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange, self.TDOnMemberDataChanged)

end

function GMTDPlayerPlaqueWidget:OnNameOverrideChanged(newOverride)

    if newOverride ~= "" then
        self:OnSteamID64Changed()
    end

end

function GMTDPlayerPlaqueWidget:GetPlayerName()
    return self.playerName:GetText()
end

function GMTDPlayerPlaqueWidget:OnRightMouseDown()
    if self:GetSteamID64() == "" then return end
    self:FireEvent("OnShowRightClickMenu", self)
end

local kDefaultSkillIconSize = Vector(100, 32, 0)
function GMTDPlayerPlaqueWidget:OnSizeChanged(newSize)

    local halfHeight = newSize.y / 2
    local skilltierIconScale = math.min(halfHeight, 41) / kDefaultSkillIconSize.y

    self.avatar:SetSize(newSize.y, newSize.y)
    self.playerName:SetSize(newSize.x - kRightSidePadding - self.avatar:GetSize().x, halfHeight)
    self.playerName:SetPosition(self.avatar:GetSize().x + kRightSidePadding, 0)
    self.skilltierIcon:SetScale(skilltierIconScale, skilltierIconScale)
    self.skilltierIcon:SetPosition(self.avatar:GetSize().x + kRightSidePadding, halfHeight)
    self.groupBackground:SetSize(self.avatar:GetSize())

end

function GMTDPlayerPlaqueWidget:Uninitialize()
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange, self.TDOnMemberDataChanged)
end

function GMTDPlayerPlaqueWidget:UpdateEllipsisAnimation()

    local numEllipsis = self:GetNumEllipsis()
    if numEllipsis >= self.kEllipsisMaxDots then
        numEllipsis = 0
    else
        numEllipsis = numEllipsis + 1
    end

    self:SetNumEllipsis(numEllipsis)

    self.playerName:SetText(string.format("%s%s", self.emptyText, string.rep(".", numEllipsis)))
end

function GMTDPlayerPlaqueWidget:UpdatePlayerDataElements( lobbyId )

    local steamID64 = self:GetSteamID64()
    if steamID64 == "" then -- nothing to update
        return
    end

    local td = Thunderdome()
    assert(td, "Error: No Thunderdome object found")

    local lobbyState
    if td:GetIsGroupId( lobbyId ) then
        lobbyState = td:GetGroupLobbyState()
    else
        lobbyState = td:GetLobbyState()
    end

    if not lobbyState then
        return
    end

    local memberModel = td:GetMemberLocalData( lobbyId, steamID64 )

    if memberModel then

        local isCommanderVolunteer = memberModel.commander_able == 1 and self:GetCommanderIconEnabled()
        local mapVotes = memberModel.map_votes
        local groupId = memberModel.group_id

        local overrideName = self:GetNameOverride()
        local playerName = overrideName ~= "" and overrideName or memberModel.name

        if memberModel.avg_skill then
            self.skilltierIcon:SetSkill( memberModel.avg_skill )
        end

        if memberModel.adagrad then
            self.skilltierIcon:SetAdagradSum( memberModel.adagrad )
        end

        if playerName and playerName ~= "" then
            self.playerName:SetText( playerName )
        end

        -- if we're in mapvote stage, show whether the player has voted for a map yet or not
        if lobbyState == kLobbyState.WaitingForMapVote then
            self.commanderIcon:SetVisible(false)
            self.mapvoteCheck:SetVisible(mapVotes and mapVotes ~= "")
        else
            self.commanderIcon:SetVisible(isCommanderVolunteer)
            self.mapvoteCheck:SetVisible(false)
        end

        -- If avatar steam id is not valid, then set it now.
        local currentAvatarSteamID64 = self.avatar:GetSteamID64()
        if not currentAvatarSteamID64 or currentAvatarSteamID64 == "" then
            self:SetSteamID64(steamID64)
        end

        self:SetChildrenVisible(true) -- Make sure the plaques are visible, since we now set it to be invisible if member model isn't available yet.

        -- Update group icon color and visibility here
        -- Group information should only be shown in lobbies while not sorted onto teams
        if groupId and groupId ~= "" and lobbyState < kLobbyState.WaitingForServer then
            local groupIds = td:GetMemberListLocalGroups( lobbyId )
            if groupId == groupIds[2] then
                self.groupBackground:SetStrokeColor(self.kGroupBgColor_2)
                self.groupIcon:SetColor(self.kGroupColor_2)
            else
                self.groupBackground:SetStrokeColor(self.kGroupBgColor_1)
                self.groupIcon:SetColor(self.kGroupColor_1)
            end
        else
            self.groupBackground:SetVisible(false)
            self.groupIcon:SetVisible(false)
        end

    else
        SLog("[TD-UI] WARNING: GMTDPlayerPlaqueWidget - Could not get member model for set Steam ID when updating player data elements. SteamID: '%s'", steamID64)
    end

end

function GMTDPlayerPlaqueWidget:SetChildrenVisible(newVisible)

    self.avatar:SetVisible(newVisible)
    self.playerName:SetVisible(newVisible)
    self.skilltierIcon:SetVisible(newVisible)
    self.groupBackground:SetVisible(newVisible)
    self.groupIcon:SetVisible(newVisible)

    local steamID32 = Shared.ConvertSteamId64To32(self:GetSteamID64())
    -- self.friendsIcon:SetVisible(newVisible and self:GetFriendsIconEnabled() and Client.GetIsSteamFriend(steamID32))

end

function GMTDPlayerPlaqueWidget:OnSteamID64Changed()

    local steamID64 = self:GetSteamID64()
    if steamID64 ~= "" then

        --if self.updateEllipsisCallback then
        --    self:RemoveTimedCallback(self.updateEllipsisCallback)
        --    self:SetNumEllipsis(0)
        --end

        self.avatar:SetSteamID64(steamID64)
        self.skilltierIcon:SetSteamID64(steamID64)

        --prioritize active over group, but still attempt
        local lobbyId = Thunderdome():GetActiveLobbyId() or Thunderdome():GetGroupLobbyId()

        if not lobbyId then
            SLog("[TD-UI] ERROR: GMTDPlayerPlaqueWidget - Could not find Active Lobby!")
            return
        end

        local memberModel = Thunderdome():GetMemberLocalData( lobbyId, steamID64 )
        if memberModel then
            self:SetChildrenVisible(true)
            self:UpdatePlayerDataElements( lobbyId )
        else
            SLog("[TD-UI] WARNING: GMTDPlayerPlaqueWidget - Could not find Member Model of lobby member! (data not synced yet?) SteamID: '%s'", steamID64)
        end

    else

        self:SetNameOverride("")
        self.playerName:SetText(self.emptyText)
        self:SetChildrenVisible(false)

        -- "..." animation for empty plaques.
        --self.updateEllipsisCallback = self:AddTimedCallback(self.UpdateEllipsisAnimation, self.kEllipsisAnimationHz, true)
    end

end
