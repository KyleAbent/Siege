-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/NavBar/Screens/Thunderdome/GMTDPlanningScreen.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/widgets/Thunderdome/GMTDScreenStatusWidget.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDPlayerRoleDisplayWidget.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDTeamRoleDisplayWidget.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDChatWidget.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDGlossyButton.lua")
Script.Load("lua/GUI/style/GUIStyledText.lua")

local kPadding = 36
local kOverviewPaddingLeft = 16
local kTopContentPadding = 7


local lastWidgetsUpdateTime = 0
local kWidgetsUpdateInterval = 0.5

---@class GMTDPlanningScreen
GMTDPlanningScreen = nil

class "GMTDPlanningScreen" (GUIObject)

GMTDPlanningScreen.kChatWidgetCustomTexture = PrecacheAsset("ui/thunderdome/td_chat_background_planning.dds")

GMTDPlanningScreen.kChatInputColor_Marines = MenuStyle.kHighlight
GMTDPlanningScreen.kChatInputColor_Aliens  = HexToColor("d39f3a")
GMTDPlanningScreen.kPlaqueLayoutSize = Vector(600, 500, 0)

function GMTDPlanningScreen:Reset()
    self.teamRolesWidget:Reset()
    self.chatWidget:Clear()
    self.statusBar:Reset()
    lastWidgetsUpdateTime = 0

    if self.memberMetadataCallback then
        self:RemoveTimedCallback(self.memberMetadataCallback)
        self.memberMetadataCallback = nil
    end
end

function GMTDPlanningScreen:GetStatusBar()
    return self.statusBar
end

function GMTDPlanningScreen:OnSizeChanged(newSize)

    local widthLeftOver = newSize.x - (kPadding*2) - self.teamRolesWidget:GetSize().x
    local chatWindowEndPosY = self.chatWidget:GetPosition().y + self.chatWidget:GetSize().y

    self.overview:SetSize(widthLeftOver - kOverviewPaddingLeft, chatWindowEndPosY - self.overview:GetPosition().y)
    self.statusBar:SetSize(newSize.x - (kPadding * 2), 70)

    local overviewPosX = kPadding*2 + self.teamRolesWidget:GetSize().x + kOverviewPaddingLeft
    local availableHeight = self.teamRolesWidget:GetSize().y + self.chatWidget:GetSize().y - kPadding

    local heightPer = availableHeight / (#self.enemyPlaques + 1) - kPadding
    for i = 1, #self.enemyPlaques do
        self.enemyPlaques[i]:SetSize(self.kPlaqueLayoutSize.x, heightPer)
    end

    self.playerPlaquesLayout:SetSize(self.kPlaqueLayoutSize.x, #self.enemyPlaques * (heightPer + kPadding) - kPadding)
    self.playerPlaquesLayout:SetX(overviewPosX + (widthLeftOver - kOverviewPaddingLeft - self.kPlaqueLayoutSize.x) * 0.5)
    self.playerPlaquesLayout:SetY(self.teamRolesWidget:GetPosition().y + (availableHeight - self.playerPlaquesLayout:GetSize().y) * 0.5)

    self.plaqueTitleLabel:SetFont("AgencyBold", self.overview:GetSize().y * 0.05)

    local spaceLeftY = newSize.y - (self.chatWidget:GetPosition().y + self.chatWidget:GetSize().y)
    self.statusBar:SetY(-((spaceLeftY - self.statusBar:GetSize().y) / 2))

end

function GMTDPlanningScreen:OnShowRightClickMenu(plaque)

    local steamID = plaque:GetSteamID64() -- plaque guarantees steam id is valid, or else we wouldn't have received the event
    local ssMouse = GetGlobalEventDispatcher():GetMousePosition()
    local lsMouse = self:ScreenSpaceToLocalSpace(ssMouse)
    self.rightClickMenu:SetPosition(lsMouse)
    self.rightClickMenu:SetSteamID64(steamID)
    self.rightClickMenu:SetPlayerName(plaque:GetPlayerName())
    self.rightClickMenu:SetModal()
    self.rightClickMenu:SetVisible(true)

end

function GMTDPlanningScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.rightClickMenu = CreateGUIObject("rightClickMenu", GMTDPlayerPlaqueContextMenu, self, nil, errorDepth)
    self.rightClickMenu:SetLayer(99)
    self.rightClickMenu:SetVisible(false)
    self:HookEvent(self.rightClickMenu, "OnHideContextMenu", self.OnHideRightClickMenu)

    self.teamRolesWidget = CreateGUIObject("teamRolesWidget", GMTDTeamRoleDisplayWidget, self, params, errorDepth)
    self.teamRolesWidget:SetPosition(kPadding, 150)
    self:HookEvent(self.teamRolesWidget, "OnShowRightClickMenu", self.OnShowRightClickMenu)

    self.chatWidget = CreateGUIObject("chatWidget", GMTDChatWidget, self,
    {
        label = Locale.ResolveString("THUNDERDOME_CHATTEAM_LABEL"),
        inputHeight = 77,
        entryYOffset = 5,
        lobbyUseType = kLobbyUsageType.Match,
    }, errorDepth)
    self.chatWidget:SetPosition(self.teamRolesWidget:GetPosition().x, self.teamRolesWidget:GetPosition().y + self.teamRolesWidget:GetSize().y - 6)
    self.chatWidget:SetTexture(self.kChatWidgetCustomTexture)
    self.chatWidget:SetSizeFromTexture()
    self.chatWidget:SetBackPadding(10)
    self:HookEvent(self.teamRolesWidget, "OnNameOverridesSet",
    function(_, steamIdsToNames)
        self.chatWidget:SetNameOverridesTable(steamIdsToNames)
    end)

    self.titleContainer = CreateGUIObject("titleContainer", GUIObject, self, params, errorDepth)
    self.titleContainer:AlignTopLeft()
    self.titleContainer:SetPosition(kPadding, kTopContentPadding)
    self.titleContainer:SetSize(self.teamRolesWidget:GetSize().x, 90)

    self.titleText = CreateGUIObject("titleText", GUIStyledText, self.titleContainer, params, errorDepth)
    self.titleText:SetFont("AgencyBold", 90)
    self.titleText:SetStyle(MenuStyle.kThunderdomePlayerNameLabel)
    self.titleText:AlignTopLeft()
    self.titleText:SetText(Locale.ResolveString("THUNDERDOME_PLANNING_PHASE"))

    local overviewPosX = self.teamRolesWidget:GetPosition().x + self.teamRolesWidget:GetSize().x + kOverviewPaddingLeft

    self.overview = CreateGUIObject("mapOverview", GMTDMapOverviewWidget, self)
    self.overview:SetPosition(overviewPosX, kTopContentPadding)
    self.overview:SetMapYAnchor(0.1)
    self.overview:SetShowOverviewBackground(true)
    self.overview:SetVisible(true)

    self.overviewSwitchButton = CreateGUIObject("overviewSwitch", GMTDGlossyButton, self.titleContainer, params, errorDepth)
    self.overviewSwitchButton:SetLabel(Locale.ResolveString("THUNDERDOME_SHOW_ROSTER"))
    self.overviewSwitchButton:AlignTopRight()
    self.overviewSwitchButton:SetY(20)

    self:HookEvent(self.overviewSwitchButton, "OnPressed", function(self)
        local vis = self.overview:GetVisible()
        self.overview:SetVisible(not vis)

        if vis then
            self.overviewSwitchButton:SetLabel(Locale.ResolveString("THUNDERDOME_HIDE_ROSTER"))
        else
            self.overviewSwitchButton:SetLabel(Locale.ResolveString("THUNDERDOME_SHOW_ROSTER"))
        end

        self.plaqueTitleLabel:SetVisible(vis)
        self.playerPlaquesLayout:SetVisible(vis)
    end)

    self.plaqueTitleLabel = CreateGUIObject("plaqueTitleLabel", GUIText, self, params, errorDepth)
    self.plaqueTitleLabel:SetFont("AgencyBold", 50)
    self.plaqueTitleLabel:SetPosition(overviewPosX + kPadding, kTopContentPadding + 20)
    self.plaqueTitleLabel:SetText(string.format("%s%s", Locale.ResolveString("THUNDERDOME_OPPOSING_TEAM"), ":"))
    self.plaqueTitleLabel:SetVisible(false)

    self.playerPlaquesLayout = CreateGUIObject("plaquesLayout", GUIColumnLayout, self, params, errorDepth)
    self.playerPlaquesLayout:SetPosition(overviewPosX, self.teamRolesWidget:GetPosition().y + kPadding)
    self.playerPlaquesLayout:SetSize(self.kPlaqueLayoutSize)
    self.playerPlaquesLayout:SetNumColumns(1)
    self.playerPlaquesLayout:SetLeftPadding(0)
    self.playerPlaquesLayout:SetColumnSpacing(0)
    self.playerPlaquesLayout:SetSpacing(kPadding)
    self.playerPlaquesLayout:SetVisible(false)

    self.enemyPlaques = {}

    for _ = 1, kLobbyPlayersLimit / 2 do

        local plaque = CreateGUIObject("playerPlaque", GMTDPlayerPlaqueWidget, self.playerPlaquesLayout, params, errorDepth)
        plaque:SetSize(self.kPlaqueLayoutSize.x, 128)
        plaque:SetVisible(true)
        table.insert(self.enemyPlaques, plaque)

        self:HookEvent(plaque, "OnShowRightClickMenu", self.OnShowRightClickMenu)

    end

    self.statusBar = CreateGUIObject("statusBar", GMTDScreenStatusWidget, self)
    self.statusBar:AlignBottom()

    self.TDServerWaitStart = function(clientModeObject) -- Shuffle should be done by now.

        self:Reset()

    end

    self.TDOnLobbyMemberMetadataChange = function( client, memberId )

        if not self.memberMetadataCallback then
            self.memberMetadataCallback = self:AddTimedCallback(self.UpdatePlayerMetadata, 2, true)
        end

    end

    self.TDOnLobbyMemberJoin = function( client, ... )

        if not self.memberMetadataCallback then
            self.memberMetadataCallback = self:AddTimedCallback(self.UpdatePlayerMetadata, 2, true)
        end

    end

    self.TDOnLobbyMemberLeave = function(client, ...)

        if not self.memberMetadataCallback then
            self.memberMetadataCallback = self:AddTimedCallback(self.UpdatePlayerMetadata, 2, true)
        end

    end

    self.TDOnLobbyMemberKicked = function(client, ...)

        self.TDOnLobbyMemberLeave(client, ...)

    end

    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)

    self:HookEvent(self, "OnShow", self.UpdatePlayerMetadata)

    self:SetUpdates(true)

    self.memberMetadataCallback = nil

end

function GMTDPlanningScreen:RegisterEvents()
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIServerWaitStart, self.TDServerWaitStart)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUIChatMessage,     self.chatWidget.TDOnChatMessage)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange,  self.TDOnLobbyMemberMetadataChange)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberJoin, self.TDOnLobbyMemberJoin)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberLeave, self.TDOnLobbyMemberLeave)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberKicked, self.TDOnLobbyMemberKicked)
end

function GMTDPlanningScreen:UnregisterEvents()
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIServerWaitStart, self.TDServerWaitStart)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIChatMessage,     self.chatWidget.TDOnChatMessage)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange,  self.TDOnLobbyMemberMetadataChange)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberJoin, self.TDOnLobbyMemberJoin)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberLeave, self.TDOnLobbyMemberLeave)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberKicked, self.TDOnLobbyMemberKicked)
end


function GMTDPlanningScreen:OnUpdate( delta, time )

    if GetThunderdomeMenu():GetCurrentScreen() ~= kThunderdomeScreen.Planning then
        return
    end

    if lastWidgetsUpdateTime + kWidgetsUpdateInterval > time then
        return
    end

    lastWidgetsUpdateTime = time

    local lobbyState = Thunderdome():GetLobbyState()
    if lobbyState and lobbyState >= kLobbyState.WaitingForServer then

        self.teamRolesWidget:InitializeTeammates()
        self.chatWidget:SetChatMessagesEnabled(true)

        -- Set the map overview's level.
        local votedMap = Thunderdome():GetLobbyVotedMap()
        if not votedMap then
            SLog("[TD-UI] ERROR: Could not get 'VotedMap' field from the active lobby when initializing planning screen!")
            return
        end

        local team = Thunderdome():GetLocalClientTeam()
        if not team then
            SLog("[TD-UI] ERROR: Could not get local client's team when initializing planning screen!")
            return
        elseif team ~= kTeam1Index and team ~= kTeam2Index then
            SLog("[TD-UI] ERROR: local client's team is invalid! Team: '%s'", team)
            return
        end

        local teamInputColor = team == kTeam1Index and self.kChatInputColor_Marines or self.kChatInputColor_Aliens
        self.chatWidget:SetInputLabelColor(teamInputColor)

        self.overview:SetLevelName(votedMap)
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

function GMTDPlanningScreen:OnHideRightClickMenu(rightClickedExit)

    -- Reset previously right-clicked plaque
    self.rightClickMenu:SetVisible(false)
    self.rightClickMenu:ClearModal()
    self.rightClickMenu:SetSteamID64("")

    -- If we right clicked on another plaque (or the same one)
    -- then treat this as another context menu opening.
    if rightClickedExit then

        local rolesLayout = self.teamRolesWidget.memberRolesLayout

        local ssMouse = GetGlobalEventDispatcher():GetMousePosition()
        local lsMouse = rolesLayout:ScreenSpaceToLocalSpace(ssMouse)

        -- Check if the mouse is over a plaque
        local overPlaque
        for i = 1, #self.teamRolesWidget.teamMemberRoleWidgets do
            local plaque = self.teamRolesWidget.teamMemberRoleWidgets[i]:GetPlaque()
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

function GMTDPlanningScreen:UpdatePlayerMetadata()

    local lobbyId = Thunderdome():GetActiveLobbyId()

    if not lobbyId then
        SLog("GMTDPlanningScreen:UpdatePlayerMetadata() - not in an active lobby!")
        return
    end

    local steamIDToNames, processedAll = GetThunderdomeNameOverrides( lobbyId )
    local members = Thunderdome():GetMemberListLocalData( lobbyId )

    local plaqueNum = 1

    for i = 1, #members do

        local member = members[i]
        local steamId = member.steamid

        if member.team ~= 0 and member.team ~= Thunderdome():GetLocalClientTeam() then

            local plaque = self.enemyPlaques[plaqueNum]
            plaqueNum = plaqueNum + 1

            plaque:SetSteamID64(steamId)

            local overrideName = steamIDToNames[steamId]
            if plaque and overrideName then
                plaque:SetNameOverride(overrideName)
            end

        end

    end

    if plaqueNum <= #self.enemyPlaques then

        for i = plaqueNum, #self.enemyPlaques do
            self.enemyPlaques[i]:SetSteamID64("")
        end

    end

    self.chatWidget:SetNameOverridesTable(steamIDToNames)

    if processedAll then
        self:RemoveTimedCallback(self.memberMetadataCallback)
        self.memberMetadataCallback = nil
    end

end

function GMTDPlanningScreen:Uninitialize()
    self:UnregisterEvents()
end
