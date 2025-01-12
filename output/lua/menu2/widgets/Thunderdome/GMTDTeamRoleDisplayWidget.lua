-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDTeamRoleDisplayWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/widgets/Thunderdome/GMTDTeamMemberRoleDisplayWidget.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDTeamAssignmentWidget.lua")
Script.Load("lua/IterableDict.lua")

local DEBUG_SHOW_ALL_WIDGETS = false

local kPlayerRowHeight_Local = 162
local kPlayerRowHeight_Teammate = 108
local kPlayerRowWidth = 1033

local kPlayerRowWidthTotal = 1038 -- Includes Borders
local kPlayerRowBorderTopHeight = 5

local kTeamAssignmentsStartPos = Vector(kPlayerRowWidthTotal, kPlayerRowBorderTopHeight, 0)
local kTeamAssignmentsSize = Vector(385, 697, 0)

class "GMTDTeamRoleDisplayWidget" (GUIObject)

GMTDTeamRoleDisplayWidget.kBackgroundTexture = PrecacheAsset("ui/thunderdome/planning_teamframe.dds")

GMTDTeamRoleDisplayWidget.kInitializeTeammatesActualDelay = 0.5

GMTDTeamRoleDisplayWidget.kUpdateTeammatesInterval = 1   --forces widgets to be fully updated


function GMTDTeamRoleDisplayWidget:Reset()

    self.initializedTeammates = false

    if self.callbackWaitForData then
        self:RemoveTimedCallback(self.callbackWaitForData)
        self.callbackWaitForData = nil
    end

    for i = 1, #self.teamMemberRoleWidgets do
        self.teamMemberRoleWidgets[i]:Reset()
    end
end

function GMTDTeamRoleDisplayWidget:InitializeTeammatesActual()
    --SLog("[TD-UI] GMTDTeamRoleDisplayWidget:InitializeTeammatesActual")

    local td = Thunderdome()
    assert(td, "Error: No valid Thunderdome object found")
    
    local lobby = false

    if not Thunderdome():GetActiveLobbyId() then
        return
    end

    local localMemberSteamID64 = td:GetLocalSteam64Id()

    local localMemberTeam = td:GetLocalClientTeam()
    if not localMemberTeam then
        SLog("[TD-UI] INFO: GMTDTeamRoleDisplayWidget:InitializeTeammatesActual - Local member team not available")
        return
    end

    local team1Members, team2Members = Thunderdome():GetLobbyTeamAssignments()

    local firstTeam
    local secondTeam

    local teamMembers
    if localMemberTeam == kTeam1Index then
        teamMembers = team1Members
        firstTeam = kTeam1Index
        secondTeam = kTeam2Index
    elseif localMemberTeam == kTeam2Index then
        teamMembers = team2Members
        firstTeam = kTeam2Index
        secondTeam = kTeam1Index
    else
        --McG: Uh, this is an invalid case quite often, needs a rethink
        --SLog("[TD-UI] INFO: GMTDTeamRoleDisplayWidget:InitializeTeammatesActual - Local member team is invalid... Team: %s", localMemberTeam)
        return
    end

    if DEBUG_SHOW_ALL_WIDGETS then
        local localSteamID = GetLocalSteamID64()
        teamMembers =
        {
            localSteamID,
            localSteamID,
            localSteamID,
            localSteamID,
            localSteamID,
            localSteamID
        }
    end

    if not teamMembers then
        SLog("[TD-UI] INFO: GMTDTeamRoleDisplayWidget:InitializeTeammatesActual - Shuffled team members not available")
        return
    end

    local steamIDToNames, processedAll = GetThunderdomeNameOverrides( td:GetActiveLobbyId() )
    if not processedAll then
        SLog("[TD-UI] INFO: GMTDTeamRoleDisplayWidget:InitializeTeammatesActual - Name Overrides did not process all current members.")
        return
    end

    -- ==================================================================================
    -- == Required information acquired. Now we can start actually filling out the GUI ==
    -- ==================================================================================

    -- Set the "what team on which rounds are we" widgets.
    self.firstTeamWidget:SetTeamIndex(firstTeam)
    self.firstTeamWidget:SetVisible(true)

    self.secondTeamWidget:SetTeamIndex(secondTeam)
    self.secondTeamWidget:SetVisible(true)

    for i = 1, #self.leavingMembers do
        table.removevalue(teamMembers, self.leavingMembers[i])
    end

    local numTeamMembers = #teamMembers

    -- Make sure the local player's steam id is first. (Bigger one at the top)
    for i = 1, numTeamMembers do
        if teamMembers[i] == localMemberSteamID64 then
            local localPlayerSteamID = table.remove(teamMembers, i)
            table.insert(teamMembers, 1, localPlayerSteamID)
            break
        end
    end

    -- Make sure each steam id in the ShuffledTeamX field actually exists as a member, since we now allow rejoins, and this function will be called multiple times
    -- (The field doesn't remove a leaving member's id)
    for i = #teamMembers, 1, -1  do
        if not Thunderdome():GetMemberLocalData( lobbyId, teamMembers[i] ) then
            table.remove(teamMembers, i)
        end
    end

    numTeamMembers = #teamMembers

    local numWidgets = #self.teamMemberRoleWidgets
    if numTeamMembers > numWidgets then
        -- Always give out a warning here.
        Log("[TD-UI] WARNING: GMTDTeamRoleDisplayWidget:InitializeTeammatesActual - Number of team members exceed number of widgets! #Team Members: %s, #Widgets: %s", numTeamMembers, numWidgets)
    end

    local extraTeamMembers = {} -- Team members that exceed the number of widgets, and will not be shown.
    for i = 1, numTeamMembers do

        local memberSteamID = teamMembers[i]
        if i <= numWidgets then
            local widget = self.teamMemberRoleWidgets[i]
            widget:SetSteamID64(memberSteamID)
            widget:SetInteractable(memberSteamID == localMemberSteamID64)
        else
            table.insert(extraTeamMembers, memberSteamID)
        end
    end

    for i = 1, numWidgets do

        local widget = self.teamMemberRoleWidgets[i]
        local overrideName = steamIDToNames[widget:GetSteamID64()]
        if overrideName then
            widget:SetNameOverride(overrideName)
        end

        -- Make sure unused widgets are not shown
        if i > numTeamMembers then
            widget:Reset()
        end

    end

    self:FireEvent("OnNameOverridesSet", steamIDToNames)

    if #extraTeamMembers > 0 then
        SLog("\tExtra Team Members: { %s }", extraTeamMembers)
    end

    local removed = self:RemoveTimedCallback(self.callbackWaitForData)
    --SLog("[TD-UI] INFO: GMTDTeamRoleDisplayWidget:InitializeTeammates COMPLETE\n\tCallback Removed: %s, \n\t#Teammates: %s, \n\tTeammates List: { %s }", removed, numTeamMembers, teamMembers)
    self.initializedTeammates = true
    self.leavingMembers = {}

    if removed then
        self.callbackWaitForData = nil
    end

end

function GMTDTeamRoleDisplayWidget:InitializeTeammates()
    if not self.callbackWaitForData then
        self.callbackWaitForData = self:AddTimedCallback(self.InitializeTeammatesActual, self.kInitializeTeammatesActualDelay, true)
    end
end

function GMTDTeamRoleDisplayWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.initializedTeammates = false
    self.leavingMembers = {} -- Keeps track of steam ids of leaving members, in case someone's internet is reaallllllllly slow

    self:SetTexture(self.kBackgroundTexture)
    self:SetSizeFromTexture()
    self:SetColor(1, 1, 1)

    self.memberRolesLayout = CreateGUIObject("memberRolesLayout", GUIListLayout, self, {orientation = "vertical"}, errorDepth)

    self.teamMemberRoleWidgets = {}

    for i = 1, (kLobbyPlayersLimit / 2) do

        local height = ConditionalValue(i == 1, kPlayerRowHeight_Local, kPlayerRowHeight_Teammate)
        local memberRoleWidget = CreateGUIObject("memberRoleWidget", GMTDTeamMemberRoleDisplayWidget, self.memberRolesLayout, params, errorDepth)
        memberRoleWidget:SetSize(kPlayerRowWidth, height)

        table.insert(self.teamMemberRoleWidgets, memberRoleWidget)
        self:ForwardEvent(memberRoleWidget, "OnShowRightClickMenu")
    end

    local centralizedTeamWidgetPosX = kTeamAssignmentsStartPos.x + (kTeamAssignmentsSize.x / 2)
    self.firstTeamWidget = CreateGUIObject("firstTeamWidget", GMTDTeamAssignmentWidget, self)
    self.firstTeamWidget:SetHotSpot(0.5, 0)
    self.firstTeamWidget:SetTeamAndOrder(kTeam1Index, 1)
    self.firstTeamWidget:SetPosition(centralizedTeamWidgetPosX, 20)
    self.firstTeamWidget:SetVisible(false)

    self.secondTeamWidget = CreateGUIObject("secondTeamWidget", GMTDTeamAssignmentWidget, self)
    self.secondTeamWidget:SetHotSpot(0.5, 0)
    self.secondTeamWidget:SetTeamAndOrder(kTeam2Index, 2)
    self.secondTeamWidget:SetPosition(centralizedTeamWidgetPosX, self.firstTeamWidget:GetPosition().y + self.firstTeamWidget:GetSize().y + 56)
    self.secondTeamWidget:SetVisible(false)

    self.TDLobbyMemberLeave = function(_, leavingMemberSteamID64)
        self:TD_OnLobbyMemberLeave(leavingMemberSteamID64)
    end

    self.TDLobbyMemberKicked = function(_, leavingMemberSteamID64)
        self:TD_OnLobbyMemberKicked(leavingMemberSteamID64)
    end
    
    self.TDLobbyMemberJoined = function()   --TD-FIXME ...eehhh...this should probably be hooking on State-changes, not member join

        -- Only do this on member join when team shuffle has been completed
        if self.initializedTeammates then
            self:InitializeTeammates()
        end

    end

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberLeave,  self.TDLobbyMemberLeave)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberKicked, self.TDLobbyMemberKicked)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberJoin,   self.TDLobbyMemberJoined)

    -- TEMP(Salads): TD - Debug command to fake person leaving Thunderdome
    Event.Hook("Console_td_oneleave_planning",
    function()

        local members = Thunderdome():GetMemberListLocalData( Thunderdome():GetActiveLobbyId() )
        local randomIndex = math.random(1, #members)
        local leavingID = members[randomIndex].steamid

        SLog("td_oneleave_planning - '%s'", leavingID)

        self:TD_OnLobbyMemberLeave(leavingID)

    end)

end

function GMTDTeamRoleDisplayWidget:UpdatePlayerNames()

    local steamIDToNames = GetThunderdomeNameOverrides( Thunderdome():GetActiveLobbyId() )

    for i = 1, #self.teamMemberRoleWidgets do

        local widget = self.teamMemberRoleWidgets[i]
        local overrideName = steamIDToNames[widget:GetSteamID64()]
        if overrideName then
            widget:SetNameOverride(overrideName)
        end

    end

end

function GMTDTeamRoleDisplayWidget:TD_OnLobbyMemberLeave(leavingMemberSteamID64)
    table.insert(self.leavingMembers, leavingMemberSteamID64)
end

function GMTDTeamRoleDisplayWidget:TD_OnLobbyMemberKicked(kickedSteamID64)
    self:TD_OnLobbyMemberLeave(kickedSteamID64)
end

function GMTDTeamRoleDisplayWidget:Uninitialize()
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberLeave,  self.TDLobbyMemberLeave)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberKicked, self.TDLobbyMemberKicked)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberJoin,   self.TDLobbyMemberJoined)
end
