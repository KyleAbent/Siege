-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/NavBar/Screens/Thunderdome/GUIMenuThunderdome.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


kThunderdomeScreen = enum({'Selection','Search', 'Lobby', 'MapVote', 'PlanningSplash', 'Planning', 'Group'})
kThunderdomePopupState = enum({'None', 'NonPenalized', 'Penalized', 'PenalizedInGame'})
kStatusBarStage = enum({'WaitingForPlayers', 'WaitingForCommanders', 'WaitingForExtraCommanders', 'WaitingForMapVote', 'WaitingForServer', 'InServer', 'GroupWaiting', 'GroupSearch', 'GroupReady'})

Script.Load("lua/menu2/MenuStyles.lua") --To ref existing things ...isn't this already in scope though?
Script.Load("lua/menu2/NavBar/Screens/GUIMenuNavBarScreen.lua")
Script.Load("lua/menu2/GUIMenuBasicBox.lua")
Script.Load("lua/menu2/GUIMenuTabbedBox.lua")
Script.Load("lua/menu2/GUIMenuGraphic.lua")  --required for background images / logos?
Script.Load("lua/menu2/GUIMenuText.lua") --should use this, or plan GUIText?
Script.Load("lua/menu2/widgets/GUIMenuTabButtonWidget.lua")
Script.Load("lua/OrderedIterableDict.lua")
Script.Load("lua/UnorderedSet.lua")

Script.Load("lua/menu2/widgets/Thunderdome/GUIMenuFriendsInvitePrompt.lua")

Script.Load("lua/menu2/NavBar/Screens/Thunderdome/GMTDSelectionScreen.lua")
Script.Load("lua/menu2/NavBar/Screens/Thunderdome/GMTDLobbySearchScreen.lua")
Script.Load("lua/menu2/NavBar/Screens/Thunderdome/GMTDLobbyScreen.lua")
Script.Load("lua/menu2/NavBar/Screens/Thunderdome/GMTDGroupScreen.lua")
Script.Load("lua/menu2/NavBar/Screens/Thunderdome/GMTDMapVoteScreen.lua")
Script.Load("lua/menu2/NavBar/Screens/Thunderdome/GMTDPlanningSplashScreen.lua")
Script.Load("lua/menu2/NavBar/Screens/Thunderdome/GMTDPlanningScreen.lua")


function GetStatusBarStateFromLobbyState( lobState )
    assert(lobState, "Error: invalid or empty LobbyState passed[%s]", lobState)

    if lobState == kLobbyState.WaitingForPlayers then
        return kStatusBarStage.WaitingForPlayers

    elseif lobState == kLobbyState.WaitingForCommanders then
        return kStatusBarStage.WaitingForCommanders

    elseif lobState == kLobbyState.WaitingForExtraCommanders then
        return kStatusBarStage.WaitingForExtraCommanders

    elseif lobState == kLobbyState.WaitingForMapVote then
        return kStatusBarStage.WaitingForMapVote

    elseif lobState == kLobbyState.WaitingForServer then
        return kStatusBarStage.WaitingForServer
    
    elseif lobState == kLobbyState.Ready or lobState == kLobbyState.Playing then
        return kStatusBarStage.InServer

    elseif lobState == kLobbyState.GroupWaiting then
        return kStatusBarStage.GroupWaiting

    elseif lobState == kLobbyState.GroupSearching then
        return kStatusBarStage.GroupSearch

    elseif lobState == kLobbyState.GroupReady then
        return kStatusBarStage.GroupReady
    end
end

local thunderdomeMenu
function GetThunderdomeMenu()
    return thunderdomeMenu
end

local kWaitingForServer_StatusRandomizationSettings =
{
    startDelay = 0,
    interval   = 10,
    titles     =
    {
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_1",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_2",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_3",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_4",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_5",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_6",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_7",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_8",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_9",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_10",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_11",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_12",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_13",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_14",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_15",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_16",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_17",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_19",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_20",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_21",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_22",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_23",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_24",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_25",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_26",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_27",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_28",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_29",
        "THUNDERDOME_PLANNING_SERVERWAIT_FLAVOR_30",
    }
}

---@class GUIMenuThunderdome : GUIMenuNavBarScreen
class "GUIMenuThunderdome" (GUIMenuNavBarScreen)

GUIMenuThunderdome.kPlanningScreenShowDuration = 3

GUIMenuThunderdome.kStatusColor_WaitingForCommanders = ColorFrom255(255, 0, 0)

GUIMenuThunderdome:AddClassProperty("PopupState", kThunderdomePopupState.None)
GUIMenuThunderdome:AddClassProperty("CurrentScreen", kThunderdomeScreen.Selection)
GUIMenuThunderdome:AddClassProperty("CurrentStatusBarStage", kStatusBarStage.WaitingForPlayers)

-- how many pixels to leave between the bottom of the screen and the bottom of this screen.
local kScreenBottomDistance = 250
local kScreenWidth = 2577

local kPerScreenAnchor = 1.05 -- Little more than 1 to make sure part of other screens don't show up.

local kInnerBackgroundSideSpacing = 32 -- horizontal spacing between edge of outer background and inner background.
local kInnerBackgroundTopSpacing = 116 -- spacing between top edge of outer background and inner background.
-- spacing between bottom edge of outer background and inner background (not including tab height!).
local kInnerBackgroundBottomSpacing = 18

local kTabHeight = 94
local kTabMinWidth = 450


local function RecomputeCreditsMenuHeight(self)
    -- Resize this object to leave a consistent spacing to the bottom of the screen.
    local aScale = self.absoluteScale
    local ssSpacing = kScreenBottomDistance * aScale.y
    local ssBottomY = Client.GetScreenHeight() - ssSpacing
    local ssTopY = self:GetParent():GetScreenPosition().y
    local ssSizeY = ssBottomY - ssTopY
    local localSizeY = ssSizeY / aScale.y
    self:SetSize(kScreenWidth, localSizeY)
end

local function OnAbsoluteScaleChanged(self, aScale)
    self.absoluteScale = aScale
    RecomputeCreditsMenuHeight(self)
end


local function UpdateInnerBackgroundSize(self, coolBackSize)
    self.innerBack:SetSize(coolBackSize - Vector(kInnerBackgroundSideSpacing * 2, kInnerBackgroundBottomSpacing + kInnerBackgroundTopSpacing, 0))
end

local function UpdateSubScreenSize(self, newSize)
    self:SetSize(newSize)
end


local function OnThunderdomeMenuSizeChanged(self)
    -- Make the outer background the same size as this object.
    self.coolBack:SetSize(self:GetSize() + Vector(0, GUIMenuNavBar.kUnderlapYSize, 0))
    self.innerBack:SetSize(self:GetSize() + Vector(-kInnerBackgroundSideSpacing * 2, GUIMenuNavBar.kUnderlapYSize - kInnerBackgroundTopSpacing - kInnerBackgroundBottomSpacing - kTabHeight, 0))
end

function GUIMenuThunderdome:TabButtonCallback_OpenLobbyScreen()
    self:ShowScreen(kThunderdomeScreen.Lobby)
end

function GUIMenuThunderdome:SetStatusBarStage( stage, lobbyId )

    local label
    local labelColor
    local count
    local countMax
    local timerDuration
    local labelRandomizationTable

    if stage == kStatusBarStage.WaitingForPlayers then

        label = Locale.ResolveString("THUNDERDOME_WAITING_FOR_PLAYERS")
        labelColor = nil -- default
        count = 0 -- update right after starting status
        countMax = kLobbyPlayersLimit
        timerDuration = nil
        labelRandomizationTable = nil

    elseif stage == kStatusBarStage.WaitingForCommanders then

        label = Locale.ResolveString("THUNDERDOME_WAITING_FOR_COMMANDERS")
        labelColor = self.kStatusColor_WaitingForCommanders
        count = 0
        countMax = kMinRequiredCommanderVolunteers
        timerDuration = nil
        labelRandomizationTable = nil

    elseif stage == kStatusBarStage.WaitingForExtraCommanders then

        label = Locale.ResolveString("THUNDERDOME_WAITING_FOR_COMMANDERS")
        labelColor = self.kStatusColor_WaitingForCommanders
        count = 0 -- Update right away after this, so should catch it before next render
        countMax = kMinRequiredCommanderVolunteers
        timerDuration = kMaxWaitingCommandersStateTimeLimit
        labelRandomizationTable = nil

    elseif stage == kStatusBarStage.WaitingForMapVote then

        label = Locale.ResolveString("THUNDERDOME_WAITING_FOR_MAPVOTE")
        labelColor = nil
        count = 0
        countMax = kLobbyPlayersLimit
        timerDuration = kMaxMapVoteAllowedTime
        labelRandomizationTable = nil

    elseif stage == kStatusBarStage.WaitingForServer then

        label = string.format(Locale.ResolveString("THUNDERDOME_WAITING_FOR_SERVER"), kServerSpinupTimerDuration)
        labelColor = nil
        count = nil
        countMax = nil
        timerDuration = nil
        labelRandomizationTable = kWaitingForServer_StatusRandomizationSettings

    elseif stage == kStatusBarStage.InServer then

        label = "IN MATCH" --Locale.ResolveString("THUNDERDOME_JOINING_SERVER")
        labelColor = nil
        count = nil
        countMax = nil
        timerDuration = nil
        labelRandomizationTable = nil

    elseif stage == kStatusBarStage.GroupWaiting then

        label = Locale.ResolveString("THUNDERDOME_GROUP_WAITING_FOR_PLAYERS")
        labelColor = nil    --TD-TODO revise
        count = 0
        countMax = kFriendsGroupMaxSlots
        timerDuration = nil
        labelRandomizationTable = nil

    elseif stage == kStatusBarStage.GroupSearch then

        label = Locale.ResolveString("THUNDERDOME_GROUP_SEARCHING_FOR_MATCH")
        labelColor = nil    --TD-TODO revise
        count = nil
        countMax = nil
        timerDuration = kMaxMapVoteAllowedTime
        labelRandomizationTable = nil

    elseif stage == kStatusBarStage.GroupReady then

        label = Locale.ResolveString("THUNDERDOME_GROUP_MATCH_FOUND")
        labelColor = nil    --TD-TODO revise
        count = nil
        countMax = nil
        timerDuration = nil
        labelRandomizationTable = nil

    else
        SLog("[TD-UI] SetStatusBarStage - Stage '%s' is invalid!", stage)
        return
    end

    for i = 1, #self.statusBars do
        self.statusBars[i]:StartNewStatus(label, labelColor, count, countMax, timerDuration, labelRandomizationTable)
    end

    SLog("[TD-UI] SetStatusBarStage - '%s'", kStatusBarStage[stage])

    self:SetCurrentStatusBarStage( stage )
    self:UpdateStatusBars( lobbyId )

end

--- Updates the status bars based on current status bar state
function GUIMenuThunderdome:UpdateStatusBars( lobbyId )

    local stage = self:GetCurrentStatusBarStage()

    local td = Thunderdome()
    assert(td, "Error: Thunderdome Manager object not fetched")

    local members = Thunderdome():GetMemberListLocalData( lobbyId )
    if not members then
        return
    end

    local numPlayers = #members

    if stage == kStatusBarStage.WaitingForPlayers then

        for i = 1, #self.statusBars do
            self.statusBars[i]:UpdateCount(numPlayers)
        end

    elseif stage == kStatusBarStage.WaitingForCommanders or stage == kStatusBarStage.WaitingForExtraCommanders then

        local numCommanders = Thunderdome():GetLobbyCommanderCount()

        for i = 1, #self.statusBars do
            self.statusBars[i]:UpdateCount(numCommanders)
        end

    elseif stage == kStatusBarStage.WaitingForMapVote then

        local numMembersVoted = 0

        for i = 1, #members do

            local member = members[i]
            local memberMapVotes = member.map_votes

            if memberMapVotes and memberMapVotes ~= "" then -- map_votes field is a single concatenated string, separated by commas
                numMembersVoted = numMembersVoted + 1
            end

        end

        for i = 1, #self.statusBars do
            self.statusBars[i]:UpdateCount(numMembersVoted)
        end

    elseif stage == kStatusBarStage.WaitingForServer then
        --No need to do anything. Static bar

    elseif stage == kStatusBarStage.InServer then
        --No need to do anything. Static bar

    elseif stage == kStatusBarStage.GroupWaiting then

        for i = 1, #self.statusBars do
            self.statusBars[i]:UpdateCount(numPlayers)
        end

    elseif stage == kStatusBarStage.GroupSearch then    --TODO Add timer
        --No need to do anything. Static bar

    elseif stage == kStatusBarStage.GroupReady then
        --No need to do anything. Static bar

--Note: No updates for WaitingForServer

    else
        SLog("[TD-UI] SetStatusBarStage - Stage '%s' is invalid!", stage)
        return
    end

end

function GUIMenuThunderdome:UpdateBottomButton()

    local currentScreen = self:GetCurrentScreen()

    if currentScreen == kThunderdomeScreen.Selection then
        self.tabButton:SetLabel(Locale.ResolveString("THUNDERDOME_TABBUTTON_BACK"))
        self.bottomButtonCallback = self.ShowLeaveConfirmation

    elseif currentScreen == kThunderdomeScreen.Search then

        self.tabButton:SetLabel(Locale.ResolveString("THUNDERDOME_TABBUTTON_QUIT"))
        self.bottomButtonCallback = self.ShowLeaveConfirmation

    elseif currentScreen == kThunderdomeScreen.Lobby then

        self.tabButton:SetLabel(Locale.ResolveString("THUNDERDOME_TABBUTTON_LEAVE"))
        self.bottomButtonCallback = self.ShowLeaveConfirmation

    elseif currentScreen == kThunderdomeScreen.PlanningSplash or currentScreen == kThunderdomeScreen.Planning then

        self.tabButton:SetLabel(Locale.ResolveString("THUNDERDOME_TABBUTTON_LEAVE"))
        self.bottomButtonCallback = self.ShowLeaveConfirmation

    elseif currentScreen == kThunderdomeScreen.MapVote then

        self.tabButton:SetLabel(Locale.ResolveString("THUNDERDOME_TABBUTTON_BACK"))
        self.bottomButtonCallback = self.TabButtonCallback_OpenLobbyScreen

    elseif currentScreen == kThunderdomeScreen.Group then

        self.tabButton:SetLabel(Locale.ResolveString("THUNDERDOME_TABBUTTON_LEAVE"))
        self.bottomButtonCallback = self.ShowLeaveConfirmation      --TD-TODO Revise?

    end

end

function GUIMenuThunderdome:OnBottomButtonPressed()

    self.bottomButtonCallback(self)
    self:UpdateBottomButton() -- For when "BACK" is pressed on the map vote screen.

end

function GUIMenuThunderdome:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    thunderdomeMenu = self
    
    PushParamChange(params, "screenName", "MatchMaking")
    GUIMenuNavBarScreen.Initialize(self, params, errorDepth)
    PopParamChange(params, "screenName")

    self:GetRootItem():SetDebugName("matchMaking")

    -- status bar stuff
    self.numCommanderVolunteers = 0

    self.lastUpdatedTime = 0

    self.runAnimation = false --early outs OnUpdate

    self.lobbyFailed = false

    self.systemDisabled = false
    self.penaltyActive = false

    -- Background (two layers, the "cool" layer, and a basic layer on top of that).
    self.coolBack = CreateGUIObject("coolBack", GUIMenuTabbedBox, self)
    self.coolBack:SetLayer(-2)
    self.coolBack:SetPosition(0, -GUIMenuNavBar.kUnderlapYSize)

    self.innerBack = CreateGUIObject("innerBack", GUIMenuBasicBox, self)
    self.innerBack:SetLayer(-1)
    self.innerBack:SetPosition(kInnerBackgroundSideSpacing, kInnerBackgroundTopSpacing - GUIMenuNavBar.kUnderlapYSize)
    self:HookEvent(self.coolBack, "OnSizeChanged", UpdateInnerBackgroundSize)

    self.tabButton = CreateGUIObject("buttons", GUIMenuTabButtonWidget, self)
    self.tabButton:SetTabHeight(kTabHeight)
    self.tabButton:SetTabMinWidth(kTabMinWidth)
    self.tabButton:AlignBottom()
    self.tabButton:SetFont(MenuStyle.kButtonFont)
    self.tabButton:SetLabel(Locale.ResolveString("THUNDERDOME_TABBUTTON_QUIT"))
    self:HookEvent(self.tabButton, "OnPressed", self.OnBottomButtonPressed)
    self.coolBack:HookEvent(self.tabButton, "OnTabSizeChanged", self.coolBack.SetTabSize)
    self.coolBack:SetTabSize(self.tabButton:GetTabSize())

    EnableOnAbsoluteScaleChangedEvent(self)

    self:HookEvent(self, "OnAbsoluteScaleChanged", OnAbsoluteScaleChanged)
    self:HookEvent(GetGlobalEventDispatcher(), "OnResolutionChanged", RecomputeCreditsMenuHeight)
    
    self:HookEvent(self, "OnSizeChanged", OnThunderdomeMenuSizeChanged)

    self.screensMap = OrderedIterableDict()
    self.statusBars = {} -- Keep track of status bars in this table so we can avoid updating them individually

    self.childWindowCropper = CreateGUIObject("screenCropper", GUIObject, self.innerBack, params, errorDepth)
    self.childWindowCropper:SetCropMin(0,0)
    self.childWindowCropper:SetCropMax(1,1)
    self.childWindowCropper:HookEvent(self.innerBack, "OnSizeChanged", UpdateSubScreenSize)

    -- Locator item for all our TD screens. We'll set this object's anchor to "show" the other screens.
    self.screenHolder = CreateGUIObject("screenHolder", GUIObject, self.childWindowCropper, params, errorDepth)
    self.screenHolder:HookEvent(self.innerBack, "OnSizeChanged", UpdateSubScreenSize)

    self.selectionScreen = CreateGUIObject("selectionScreen", GMTDSelectionScreen, self.screenHolder, params, errorDepth)
    self.selectionScreen:HookEvent(self.innerBack, "OnSizeChanged", UpdateSubScreenSize)
    self.screensMap[kThunderdomeScreen.Selection] = self.selectionScreen

    self.searchScreen = CreateGUIObject("searchScreen", GMTDLobbySearchScreen, self.screenHolder, params, errorDepth)
    self.searchScreen:HookEvent(self.innerBack, "OnSizeChanged", UpdateSubScreenSize)
    self.screensMap[kThunderdomeScreen.Search] = self.searchScreen

    self.lobbyScreen = CreateGUIObject("lobbyScreen", GMTDLobbyScreen, self.screenHolder, params, errorDepth)
    self.lobbyScreen:HookEvent(self.innerBack, "OnSizeChanged", UpdateSubScreenSize)
    self.screensMap[kThunderdomeScreen.Lobby] = self.lobbyScreen

    self.mapVoteScreen = CreateGUIObject("mapVoteScreen", GMTDMapVoteScreen, self.screenHolder, params, errorDepth)
    self.mapVoteScreen:HookEvent(self.innerBack, "OnSizeChanged", UpdateSubScreenSize)
    self.screensMap[kThunderdomeScreen.MapVote] = self.mapVoteScreen

    self.planningSplashScreen = CreateGUIObject("mapVoteScreen", GMTDPlanningSplashScreen, self.screenHolder, params, errorDepth)
    self.planningSplashScreen:HookEvent(self.innerBack, "OnSizeChanged", UpdateSubScreenSize)
    self.screensMap[kThunderdomeScreen.PlanningSplash] = self.planningSplashScreen

    self.planningScreen = CreateGUIObject("mapVoteScreen", GMTDPlanningScreen, self.screenHolder, params, errorDepth)
    self.planningScreen:HookEvent(self.innerBack, "OnSizeChanged", UpdateSubScreenSize)
    self.screensMap[kThunderdomeScreen.Planning] = self.planningScreen

    self.groupScreen = CreateGUIObject("groupScreen", GMTDGroupScreen, self.screenHolder, params, errorDepth)
    self.groupScreen:HookEvent(self.innerBack, "OnSizeChanged", UpdateSubScreenSize)
    self.screensMap[kThunderdomeScreen.Group] = self.groupScreen

    self:HookEvent(self.lobbyScreen,   "OnShowMapVoteScreen", self.OnShowMapVoteScreen)
    self:HookEvent(self.mapVoteScreen, "OnMapVotesConfirmed", self.OnMapVotesConfirmed)

    self.lobbyScreen.goToMapVoteScreenButton:HookEvent(self.mapVoteScreen, "OnMapVotesConfirmed", self.lobbyScreen.goToMapVoteScreenButton.OnMapVotesConfirmed)

    -- Set all the screen's anchors so that they're laid out side by side, starting at 0.
    for i = 1, #self.screensMap do
        local screen = self.screensMap:GetValueAtIndex(i)
        assert(screen)
        screen:SetAnchor((i - 1)*kPerScreenAnchor, 0)

        if screen.GetStatusBar then
            table.insert(self.statusBars, screen:GetStatusBar())
        end
    end

    self:HookEvent(self, "OnScreenDisplay", self.OnScreenDisplay)
    self:HookEvent(self, "OnScreenHide", self.OnScreenHide)

    self:UpdateBottomButton()

    --Be sure below is LAST item to occur
    --Force immediate initialization of TD Manager
    Thunderdome()

    self.TDLobbyJoined = function( clientObject, lobbyId )

        --Note: Commands like td_lobmake can circumvent the displaying of the UI via clicking the menu button.

        local inGame = Client.GetIsConnected() and not Client.GetIsRunningServer()

        if not self:GetScreenDisplayed() and not inGame then
        --Only show TD screen(s) while in main-menu
            GetScreenManager():DisplayScreen("MatchMaking")
        end

        local td = Thunderdome()
        assert(td, "Error: no valid Thunderdome object found")

        local isGroup = td:GetIsGroupId( lobbyId )

        local lobState = isGroup and td:GetGroupLobbyState() or td:GetLobbyState()
        assert(lobState, "Error: No LobbyState found for any lobby-type")

        local barState = GetStatusBarStateFromLobbyState( lobState )

        self:SetStatusBarStage( barState, lobbyId )

        if isGroup then
            SLog(" !!! Show GROUP screen !!!")
            self:ShowScreen(kThunderdomeScreen.Group)
        else
            SLog(" !!! Show LOBBY screen !!!")
            self:ShowScreen(kThunderdomeScreen.Lobby)
        end

    end

    self.TDMapVoteStarted = function( clientObject, lobbyId )

        Client.WindowNeedsAttention()

        if not self:GetScreenDisplayed() then
        --Show MM screen immediately, as new phase started
            GetScreenManager():DisplayScreen("MatchMaking")
        end

        local td = Thunderdome()
        assert(td, "Error: No valid Thunderdome object")

        self:SetStatusBarStage( kStatusBarStage.WaitingForMapVote, lobbyId )

        local mapVotes = td:GetLocalMapVotes( lobbyId )
        if not mapVotes or mapVotes == "" then -- Not voted yet
            SLog("[TD-UI] Auto-showing map screen. (Map Vote Phase Started)")
            self:ShowScreen(kThunderdomeScreen.MapVote)
        else
            SLog("[TD-UI] Not auto-showing map screen. Votes Data: '%s', CurrentScreen: %s", mapVotes, kThunderdomeScreen[self:GetCurrentScreen()])
        end
    end

    self.TDServerWaitStart = function( clientModeObject, lobbyId )
        if not self:GetScreenDisplayed() then
        --Show MM screen immediately, as new phase started
            GetScreenManager():DisplayScreen("MatchMaking")
        end

        self:SetStatusBarStage( kStatusBarStage.WaitingForServer, lobbyId )
        self:OnShowPlanningSplashScreen()
    end

    -- Error events
    self.TD_LobbyJoinFailed = function(clientModeObject, steamLobbyJoinResponseCode)
        local errorMessage = GetLobbyJoinResponseLocale(steamLobbyJoinResponseCode)
        self:TD_OnMatchmakingFailed(Locale.ResolveString(errorMessage or "THUNDERDOME_LOBBY_JOIN_FAILED_GENERIC"))
    end

    self.TD_LobbyCreateFailed = function(clientModeObject, steamLobbyJoinResponseCode)
        local errorMessage = GetLobbyJoinResponseLocale(steamLobbyJoinResponseCode)
        self:TD_OnMatchmakingFailed(Locale.ResolveString(errorMessage or "THUNDERDOME_LOBBY_CREATE_FAILED_GENERIC"))
    end

    self.TD_SteamConnectionFailure = function(clientModeObject)
        self:TD_OnMatchmakingFailed(Locale.ResolveString("THUNDERDOME_STEAMOFFLINE"))
    end

    self.TD_SystemDisabled = function(clientModeObject)
        self:TD_OnMatchmakingFailed(Locale.ResolveString("THUNDERDOME_SYSTEM_DISABLED"))
    end

    self.TD_HiveProfileFetchFailure = function(clientModeObject)
        self:TD_OnMatchmakingFailed(Locale.ResolveString("THUNDERDOME_HIVEPROFILEFAILED"))
    end

    self.TD_SearchFailed = function(clientModeObject)
        self:TD_OnMatchmakingFailed(Locale.ResolveString("THUNDERDOME_SEARCH_FAILED"))
    end

    self.TD_OwnerChangeFailed = function(clientModeObject)
        self:TD_OnMatchmakingFailed(Locale.ResolveString("THUNDERDOME_OWNER_CHANGE_FAILED"))
    end

    self.TD_ServerWaitFailed = function(clientModeObject)
        self:TD_OnMatchmakingFailed(Locale.ResolveString("THUNDERDOME_SERVER_WAIT_FAILED"))
    end

    self.TD_MatchProcessFailed = function(clientModeObject)
        self:TD_OnMatchmakingFailed(Locale.ResolveString("THUNDERDOME_MATCH_PROCESS_FAILED"))
    end

    self.TD_ServerConnectFailed = function(clientModeObject)
        self:TD_OnMatchmakingFailed(Locale.ResolveString("THUNDERDOME_SERVER_CONNECT_FAILED"))
    end

    self.TD_ServerReconnectPrompt = function(clientModeObject)
        self:TD_HandleEventMessage( kThunderdomeEvents.OnGUIServerReconnectPrompt, Locale.ResolveString("THUNDERDOME_MATCHMAKING_RECONNECT_PROMPT") )
    end

    self.TD_AfkWarningTimerPrompt = function(clientModeObject)
        self:TD_HandleEventMessage( kThunderdomeEvents.OnGUIAfkKickedPrompt, Locale.ResolveString("THUNDERDOME_MATCHMAKING_AFKKICK_PROMPT") )
    end

    self.TD_MaxLobbyLifespanPrompt = function(clientModeObject)
        self:TD_HandleEventMessage( kThunderdomeEvents.OnGUIMaxLobbyLifespanNotice, Locale.ResolveString("THUNDERDOME_LOBBY_LIFESPAN_TIMEOUT") )
    end 

    self.TD_LobbyInviteReceived = function(clientModeObject, ...)
        SLog("    GUIMenuThunderdome:TD_LobbyInviteReceived()")
        self:TD_HandleEventMessage( kThunderdomeEvents.OnGUILobbyInviteReceived, Locale.ResolveString("THUNDERDOME_MATCHMAKING_LOBBYINVITE_PROMPT"), ... )
    end

    self.TD_LobbyInviteInvalid = function(clientModeObject, ...)
        SLog("    GUIMenuThunderdome:TD_LobbyInviteInvalid()")
        self:TD_HandleEventMessage( kThunderdomeEvents.OnGUILobbyInviteInvalid, Locale.ResolveString("THUNDERDOME_MATCHMAKING_LOBBYINVITE_INVALID"), ... )
    end

    self.TD_OnLobbyLeft = function( clientModeObject, lobbyId )
        Log("=== self.TD_OnLobbyLeft ===")
        --self:OnBack()
        self:Reset()
        self:LeaveThunderdome()
    end

    self.TD_OnLobbyKicked = function( clientModeObject, lobbyId )
        Log("=== self.TD_OnLobbyKicked ===")
        --self:OnBack()
        self:Reset()
        self:LeaveThunderdome()

        self:TD_HandleEventMessage( kThunderdomeEvents.OnGUILobbyKicked, Locale.ResolveString("THUNDERDOME_MATCHMAKING_LOBBY_KICKED") )
    end

    self.TD_LobbyMemberDataChanged = function(clientModeObject, steamID64, lobbyId)
        local td = Thunderdome()
        assert(td, "Error: No valid Thunderdome object found")

        self:UpdateStatusBars( lobbyId )
    end

    self.TD_CommanderWaitStarted = function( clientObject, lobbyId )
        if not self:GetScreenDisplayed() then
        --Show MM screen immediately, as new phase started
            GetScreenManager():DisplayScreen("MatchMaking")
        end
        
        Client.WindowNeedsAttention()
        PlayMenuSound("ThunderdomeAttention")
        
        self:SetStatusBarStage( kStatusBarStage.WaitingForCommanders, lobbyId )
        self.lobbyScreen.friendInviteBtn:SetVisible(false)
    end

    self.TD_ExtraCommanderWaitStarted = function( clientObject, lobbyId )
        self:SetStatusBarStage(kStatusBarStage.WaitingForExtraCommanders, lobbyId)
    end

    self.TD_UpdateStatusBars = function( clientObject, memberId, lobbyId )
        self:UpdateStatusBars( lobbyId )
    end
    
    self.TD_LobbyStateRollback = function( clientObject, lobbyId )
        self:SetStatusBarStage(kStatusBarStage.WaitingForPlayers, lobbyId)
        self:ShowScreen(kThunderdomeScreen.Lobby)
        self.lobbyScreen.friendInviteBtn:SetVisible(true)
    end

    self.TD_OnChatMessage = function( ... )
        -- Pass on chat message events to the lobby while the MapVote screen is open
        -- TD-TODO: this isn't the cleanest way of handling things, ideally the Menu
        -- would maintain a chat message "history" that screens pull from when they're
        -- initialized.
        if self:GetCurrentScreen() == kThunderdomeScreen.MapVote then
            self.lobbyScreen.chatWindow.TDOnChatMessage(...)
        end
    end

    self.TD_PenaltyIsActive = function ( ... )
        self:TD_HandleEventMessage( kThunderdomeEvents.OnGUIPenaltyIsActive,
            Locale.ResolveString("THUNDERDOME_MATCHMAKING_PENALIZED") .. " " ..
            string.format( Locale.ResolveString("THUNDERDOME_MATCHMAKING_PENALTY_EXPIRES"), GetThunderdomePenaltyExpirationFormatted() )
        )
    end

    self.TD_PenaltyStateChanged = function( clientObject, newState )
        self:Reset()
    end

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyJoinFailed,         self.TD_LobbyJoinFailed)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyCreateFailed,       self.TD_LobbyCreateFailed)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUISteamConnectionLost,     self.TD_SteamConnectionFailure)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIHiveProfileFetchFailure, self.TD_HiveProfileFetchFailure)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUISystemDisabled,          self.TD_SystemDisabled)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUISearchFailed,            self.TD_SearchFailed)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIOwnerChangeFailed,       self.TD_OwnerChangeFailed)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIServerWaitFailed,        self.TD_ServerWaitFailed)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIMatchProcessFailed,      self.TD_MatchProcessFailed)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIServerConnectFailed,     self.TD_ServerConnectFailed)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILeaveLobby,              self.TD_OnLobbyLeft)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyKicked,             self.TD_OnLobbyKicked)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyStateRollback,      self.TD_LobbyStateRollback)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIPenaltyIsActive,         self.TD_PenaltyIsActive)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIPenaltyStateChanged,     self.TD_PenaltyStateChanged)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUIChatMessage,             self.TD_OnChatMessage)

    -- Status bar update events
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberJoin,           self.TD_UpdateStatusBars)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberLeave,          self.TD_UpdateStatusBars)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberKicked,         self.TD_UpdateStatusBars)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange, self.TD_LobbyMemberDataChanged)
    
    -- Status bar start phase events
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyJoined,                  self.TDLobbyJoined)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUICommandersWaitStart,          self.TD_CommanderWaitStarted)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIMinRequiredCommandersSet,     self.TD_ExtraCommanderWaitStarted)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIMapVoteStart,                 self.TDMapVoteStarted)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIServerWaitStart,              self.TDServerWaitStart)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUIServerReconnectPrompt,   self.TD_ServerReconnectPrompt)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyInviteReceived,     self.TD_LobbyInviteReceived)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyInviteInvalid,     self.TD_LobbyInviteInvalid)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIAfkKickedPrompt,         self.TD_AfkWarningTimerPrompt)

    Thunderdome_AddListener(kThunderdomeEvents.OnGUIMaxLobbyLifespanNotice,  self.TD_MaxLobbyLifespanPrompt)

end

function GUIMenuThunderdome:ShowScreen(kThunderdomeScreenType)
    SLog("GUIMenuThunderdome:ShowScreen( %s )", kThunderdomeScreen[kThunderdomeScreenType])
    local screen = self.screensMap[kThunderdomeScreenType]
    assert(screen)

    --Handle TD event registering / desregistering based on display, as Group/Lobby have identical event handling
    local curScr = self:GetCurrentScreen()
    if kThunderdomeScreenType ~= curScr then
        self.screensMap[curScr]:UnregisterEvents()
        self.screensMap[curScr]:FireEvent("OnHide")
        
        screen:RegisterEvents()
        screen:FireEvent("OnShow")
    end

    self.screenHolder:ClearPropertyAnimations("Anchor")
    self.screenHolder:AnimateProperty("Anchor", Vector(-screen:GetAnchor().x, 0, 0), MenuAnimations.FlyIn)
    self:SetCurrentScreen(kThunderdomeScreenType)
    self:UpdateBottomButton()
end

-- Matchmaking has completely failed, cannot continue.
function GUIMenuThunderdome:TD_OnMatchmakingFailed(errorMessage)

    SLog("[TD-UI] ERROR: Matchmaking Failed - Reason: %s", errorMessage)
    GetMainMenu():DisplayPopupMessage(errorMessage, Locale.ResolveString("THUNDERDOME_MATCHMAKING_ERROR_TITLE"))

    self.lobbyFailed = true

    self:OnBack()
    self:LeaveThunderdome()
    self:Reset()

end


local kEventHandlersMap =
{
    --TODO Add penalized popup for when user attempts to use system after being penalized for any reason
    [kThunderdomeEvents.OnGUIThunderdomeIsBanned] = function(message)
        SLog("***  kThunderdomeEvents.OnGUIThunderdomeIsBanned - Event - Show Banned-message pop-up")

        local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
        {
            title = "Banned", -- TD-TODO: localize when penalty system re-enabled
            message = message,
            escDisabled = true,
            buttonConfig =
            {
                {
                    name = "ok",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("OK")),
                    },
                    callback = function(popup)  
                        popup:FireEvent("OnConfirmed", popup)
                        popup:Close()
                    end,
                },
            },
        })

    end,

    --TODO Add penalized popup for when user attempts to use system after being penalized for any reason
    [kThunderdomeEvents.OnGUIPenaltyIsActive] = function(message)
        SLog("***  kThunderdomeEvents.OnGUIPenaltyIsActive - Event - Show Penalty-message pop-up")

        local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
        {
            title = "Unavailable", -- TD-TODO: localize when penalty system re-enabled
            message = message,
            escDisabled = true,
            buttonConfig =
            {
                {
                    name = "ok",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("OK")),
                    },
                    callback = function(popup)  
                        popup:FireEvent("OnConfirmed", popup)
                        popup:Close()
                    end,
                },
            },
        })

    end,

    [kThunderdomeEvents.OnGUISteamConnectionLost] = function(message)
        SLog("***  kThunderdomeEvents.OnGUISteamConnectionLost - Event - Show steam-offline pop-up")

        local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
        {
            title = Locale.ResolveString("THUNDERDOME_STEAM_OFFLINE"),
            message = message,
            escDisabled = true,
            buttonConfig =
            {
                {
                    name = "ok",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("OK")),
                    },
                    callback = function(popup)  
                        popup:FireEvent("OnConfirmed", popup)
                        popup:Close()
                    end,
                },
            },
        })

    end,

    [kThunderdomeEvents.OnGUIMaxLobbyLifespanNotice] = function(message)
        SLog("***  kThunderdomeEvents.OnGUIMaxLobbyLifespanNotice - Event - Show lobby lifetime timeout")

        --Leave immediately, always
        local td = Thunderdome()
        td:LeaveLobby(td:GetActiveLobbyId())

        local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
        {
            title = Locale.ResolveString("THUNDERDOME_LOBBY_TIMEOUT"),
            message = message,
            escDisabled = true,
            buttonConfig =
            {
                {
                    name = "ok",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("OK")),
                    },
                    callback = function(popup)  
                        popup:FireEvent("OnConfirmed", popup)
                        popup:Close()
                    end,
                },
            },
        })

    end,
    
    [kThunderdomeEvents.OnGUILobbyInviteReceived] = function(message, lobbyId, inviterId, inviterName)

        SLog("***  kThunderdomeEvents.OnGUILobbyInviteReceived - Event - Show Confirmation pop-up")
        SLog("\t      lobbyId:      %s", lobbyId)
        SLog("\t    inviterId:      %s", inviterId)
        SLog("\t  inviterName:      %s", inviterName)
        
        GetScreenManager():DisplayScreen("NavBar")
        GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)

        local OnOk = function(popup)
            local ok = Thunderdome():JoinLobbyInvite( lobbyId, Client.GetOnLaunchLobbyId() ~= "" )

            if ok then
                GetScreenManager():DisplayScreen("MatchMaking")
                GetScreenManager():GetCurrentScreen():ShowScreen(kThunderdomeScreen.Lobby)
            end

            popup:FireEvent("OnConfirmed", popup)
            popup:Close()
        end
        
        local OnCancel = function(popup)
            popup:FireEvent("OnCancelled", popup)
            popup:Close()
            Thunderdome():OnRejectLobbyInvitation()
        end

        local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
        {
            title = Locale.ResolveString("THUNDERDOME_LOBBY_INVITATION"),
            message = inviterName .. " " .. message,
            escDisabled = true,
            buttonConfig =
            {
                {
                    name = "ok",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("YES")),
                    },
                    callback = OnOk,
                },
                {
                    name = "cancel",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("NO")),
                    },
                    callback = OnCancel,
                }
            },
            updateFunc = function(self)     --TD-FIXME this hides the main screen when this condition would apply (need to move this logic up the chain)
                local td = Thunderdome()
                if td:GetActiveLobbyId() == lobbyId or td:GetGroupLobbyId() == lobbyId then
                --We make duplicate invites (due to accepting from Steam chat with game open), auto-close.
                --Yes, this may result in a "blip" behavior, but we have NO way of know if user clicks
                --invite link in a Steam chat window (no callback, message, or signal), so...this is the best we can do.
                    self:Close()
                end
            end,
        })

    end,

    [kThunderdomeEvents.OnGUILobbyInviteInvalid] = function(message)
        SLog("***  kThunderdomeEvents.OnGUILobbyInviteInvalid - Event - Show lobby invalid message")

        local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
        {
            title = Locale.ResolveString("THUNDERDOME_LOBBY_INVITE_INVALID"),
            message = message,
            escDisabled = true,
            buttonConfig =
            {
                {
                    name = "ok",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("OK")),
                    },
                    callback = function(popup)  
                        popup:FireEvent("OnConfirmed", popup)
                        popup:Close()
                    end,
                },
            },
        })

    end,

    [kThunderdomeEvents.OnGUILobbyKicked] = function(message)
        SLog("***  kThunderdomeEvents.OnGUILobbyKicked - Event - Show lobby kicked message")

        local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
        {
            title = Locale.ResolveString("THUNDERDOME_LOBBY_KICKED"),
            message = message,
            escDisabled = true,
            buttonConfig =
            {
                {
                    name = "ok",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("OK")),
                    },
                    callback = function(popup)  
                        popup:FireEvent("OnConfirmed", popup)
                        popup:Close()
                    end,
                },
            },
        })

    end,

    [kThunderdomeEvents.OnGUIAfkKickedPrompt] = function(message)

        SLog("***  kThunderdomeEvents.OnGUIAfkKickedPrompt - Event - Show Confirmation pop-up and timer")

        local timeAfkPomptShown = 0
        local promptTimeoutFunc = function(popup, timeStarted)
            local timeLeft = math.floor((timeStarted + kAfkPromptTimeoutPeriod) - Shared.GetSystemTime())
            if timeLeft < 0 then
                timeLeft = 0
            end
            return timeLeft
        end

        local OnYes = function(popup)
            local td = Thunderdome()
            local lobState = td:GetLobbyState()

            if lobState and (lobState >= kLobbyState.Ready and lobState < kLobbyState.Finalized ) then
            --If the round is not completed, attempt a reconnect
                popup:FireEvent("OnConfirmed", popup)
                popup:Close()
                td:AttemptServerConnect()
            else
            --round is completed, penalize
                td:LeaveLobby(td:GetActiveLobbyId(), true)  --TD-TODO should notify user, this is an info-gap that'll be construed as a bug

                popup:FireEvent("OnCancelled", popup)
                popup:Close()

                GetScreenManager():DisplayScreen("NavBar")
                GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)
                GetNavBar():SetThunderdomeState( true )
            end
        end

        local OnNo = function(popup)
            local td = Thunderdome()

            td:LeaveLobby(td:GetActiveLobbyId(), true)

            popup:FireEvent("OnCancelled", popup)
            popup:Close()

            Thunderdome():LoadCompletePromptsClear()

            GetScreenManager():DisplayScreen("NavBar")
            GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)
            GetNavBar():SetThunderdomeState( true )
        end

        local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
        {
            title = Locale.ResolveString("THUNDERDOME_AFK_KICKED"),
            message = message,
            escDisabled = true,
            buttonConfig = 
            {
                {
                    name = "ok",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("YES")),
                    },
                    callback = OnYes,
                },
                {
                    name = "cancel",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("NO")),
                    },
                    callback = OnNo,
                }
            },
            updateFunc = function(self)
                if timeAfkPomptShown == 0 then
                --timestamp timer on first-display
                    timeAfkPomptShown = Shared.GetSystemTime()  --system time, as we're not in-game
                end

                local timeRemain = promptTimeoutFunc(self, timeAfkPomptShown)

                if timeRemain <= 0 then
                    GetMainMenu():DisplayPopupMessage( Locale.ResolveString("THUNDERDOME_MATCHMAKING_AFKKICK_PENALZIED"), Locale.ResolveString("THUNDERDOME_MATCHMAKING_AFKKICK_TIMEOUT_PENALIZED_TITLE") )
                    return OnNo(self)
                end

                local isPubLob = not Thunderdome():GetIsPrivateLobby()
                local updatedMsg
                if isPubLob then
                    updatedMsg = Locale.ResolveString("THUNDERDOME_MATCHMAKING_AFKKICK_PROMPT")
                    updatedMsg = updatedMsg .. string.format(Locale.ResolveString("THUNDERDOME_MATCHMAKING_AUTOPENALIZED_IN"), timeRemain)
                else
                    updatedMsg = Locale.ResolveString("THUNDERDOME_MATCHMAKING_AFKKICK_NO_PEN_PROMPT")
                    updatedMsg = updatedMsg .. string.format(Locale.ResolveString("THUNDERDOME_MATCHMAKING_AUTOLEAVE_IN"), timeRemain)
                end
                
                self:SetMessage(updatedMsg)
            end
        })

    end,
    
    [kThunderdomeEvents.OnGUIServerReconnectPrompt] = function(message)

        SLog("***  kThunderdomeEvents.OnGUIServerReconnectPrompt - Event - Show Confirmation pop-up")

        local OnOk = function(popup)
            popup:FireEvent("OnConfirmed", popup)
            popup:Close()
            Thunderdome():AttemptServerConnect()
        end
        
        local OnCancel = function(popup)
            local td = Thunderdome()
            td:LeaveLobby( td:GetActiveLobbyId(), true )
            popup:FireEvent("OnCancelled", popup)
            popup:Close()
            GetScreenManager():DisplayScreen("NavBar")
            GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)
            td:LoadCompletePromptsClear()
            GetNavBar():SetThunderdomeState( true )
        end
        
        local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
        {
            title = Locale.ResolveString("THUNDERDOME_RECONNECT_TO_MATCH"),
            message = message,
            escDisabled = true,
            buttonConfig =
            {
                {
                    name = "ok",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("YES")),
                    },
                    callback = OnOk,
                },
                {
                    name = "cancel",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("NO")),
                    },
                    callback = OnCancel,
                }
            },
        })

    end
}

function GUIMenuThunderdome:TD_HandleEventMessage( eventId, message, ... )
    assert(eventId)
    assert(message)
    assert(kEventHandlersMap[eventId])
    
     --actions to take are left to prompt, any extra arguments are left to handler to parse
    kEventHandlersMap[eventId](message, ...)
end

function GUIMenuThunderdome:OnBack()
    -- Clear screen history, reset to main screen.
    GetScreenManager():DisplayScreen("NavBar")
    GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)
end

function GUIMenuThunderdome:OnMapVotesConfirmed()
    self:ShowScreen(kThunderdomeScreen.Lobby)
end

function GUIMenuThunderdome:RequestHide(acceptCallback)
    GetNavBar():SetThunderdomeState(true)
    return true
end

function GUIMenuThunderdome:OnShowPlanningSplashScreen()
    self.planningSplashScreen:SetStartingRoundTeam(Thunderdome():GetLocalClientTeam())
    self:ShowScreen(kThunderdomeScreen.PlanningSplash)
    self:AddTimedCallback(self.OnShowPlanningScreen, self.kPlanningScreenShowDuration, false)
end

function GUIMenuThunderdome:OnShowPlanningScreen()
    if not Thunderdome():GetActiveLobbyId() then
        return -- lobby may have failed in some state and invalidated the callback
    end

    self:ShowScreen(kThunderdomeScreen.Planning)
end

function GUIMenuThunderdome:OnShowMapVoteScreen()
    self:ShowScreen(kThunderdomeScreen.MapVote)
end

function GUIMenuThunderdome:ShowSearchScreen()
    self:ShowScreen(kThunderdomeScreen.Search)
    self.searchScreen:StartSearching()
end

function GUIMenuThunderdome:Display(immediate)

    --McG: Yes, this is ugly as hell, but required for now because TD Events won't be handled
    --unless this screen is visible/active. Plus, a "system outage" prompt will be needed.

    if not Client.GetIsSteamAvailable() then
        self:TD_HandleEventMessage( 
            kThunderdomeEvents.OnGUISteamConnectionLost, 
            Locale.ResolveString("THUNDERDOME_STEAMOFFLINE") 
        )
        return
    end

    if Client.GetIsTDBanned() then
        self:TD_HandleEventMessage( 
            kThunderdomeEvents.OnGUIThunderdomeIsBanned, 
            Locale.ResolveString("THUNDERDOME_BANNED") 
        )
        return
    end

    --TODO Add System disabled pop-up to work, even AFTER main-vm restart (e.g. mods, menu bg, etc.)

    GUIMenuNavBarScreen.Display(self, immediate)

end

function GUIMenuThunderdome:OnScreenDisplay()
    SLog("GUIMenuThunderdome:OnScreenDisplay()")

    self.screensMap[self:GetCurrentScreen()]:FireEvent("OnShow")
end

function GUIMenuThunderdome:OnScreenHide()
    SLog("GUIMenuThunderdome:OnScreenHide()")

    self.screensMap[self:GetCurrentScreen()]:FireEvent("OnHide")
end

function GUIMenuThunderdome:Reset()

    self.commanderWaitStartTime = 0
    self.numCommanderVolunteers = 0

    self.lobbyFailed = false

    self.selectionScreen:Reset()
    self.searchScreen:Reset()
    self.lobbyScreen:Reset()
    self.groupScreen:Reset()
    self.mapVoteScreen:Reset()
    self.planningScreen:Reset()

    self:ShowScreen(kThunderdomeScreen.Selection)

    self:SetPopupState(kThunderdomePopupState.None)

end

function GUIMenuThunderdome:OnLeavePopup_Cancel()
    self:SetPopupState(kThunderdomePopupState.None)
end

function GUIMenuThunderdome:OnLeavePopup_Confirm(popup)
    SLog("** GUIMenuThunderdome:OnLeavePopup_Confirm()")

    self:LeaveThunderdome(true)
    self:Reset()
    
    self:SetPopupState(kThunderdomePopupState.None)

    local callback = popup.acceptCallback
    if callback then
        callback()
    end
end

function GUIMenuThunderdome:OnLeavePopup_ConfirmPenalized(popup)
    SLog("** GUIMenuThunderdome:OnLeavePopup_Confirm()")

    self:LeaveThunderdome(true)
    self:Reset()
    self:OnBack()

    self:SetPopupState(kThunderdomePopupState.None)

    local callback = popup.acceptCallback
    if callback then
        callback()
    end
end

function GUIMenuThunderdome:LeaveThunderdome(clientChoice)
    SLog("** GUIMenuThunderdome:LeaveThunderdome()")
    local td = Thunderdome()
    if td:GetIsSearching() then
        td:CancelMatchSearch()
    end

    if td:GetIsGroupQueueEnabled() then
        td:LeaveGroup( td:GetGroupLobbyId() )
    end

    if td:GetIsConnectedToLobby() then
        td:LeaveLobby( Thunderdome():GetActiveLobbyId(), clientChoice )
    end

    --Re-enabled the Play menu
    GetNavBar():SetThunderdomeState(true)

end

function GUIMenuThunderdome:ShowLeaveConfirmation(acceptCallback)
    SLog("--- GUIMenuThunderdome:ShowLeaveConfirmation() ---")

    local td = Thunderdome()
    assert(td, "Error: No valid Thunderdome object found")

    local curScr = self:GetCurrentScreen()

    if Shared.GetThunderdomeEnabled() then

        if not GetThunderdomeRules():GetIsMatchCompleted() and td:GetLeaveLobbyPenalizes() then
            self:DoLeaveConfirmationPenalizedInGame(acceptCallback)
            return
        end

    elseif GetScreenManager():GetCurrentScreenName() == "MatchMaking" then
        SLog("  Is showing TD screen...")
        SLog("      [ %s ]", kThunderdomeScreen[curScr])
        SLog("")

        if td:GetLeaveLobbyPenalizes() then
            self:DoLeaveConfirmationPenalized(acceptCallback)
            return
        end

        if curScr ~= kThunderdomeScreen.Search and curScr ~= kThunderdomeScreen.Selection and curScr ~= kThunderdomeScreen.Group then

            if not td:GetLeaveLobbyPenalizes() then
            --Don't bother prompting for Private/Invite-Only lobbies
                self:LeaveThunderdome(true)
                self:Reset()
                self:SetPopupState(kThunderdomePopupState.None)
                return
            end

            if not td:GetHasCachedInvite() then
            --Note: if local-client would be penalized, the invite is "ignored" before reaching this point
                self:DoLeaveConfirmation(acceptCallback)
            end
            return

        else
        --No blocking / confirmation for just Search screen

            if curScr == kThunderdomeScreen.Search then
            --Search running, no match found, return to selection screen
                td:CancelMatchSearch()
                self:Reset()
                return
            end

            if curScr == kThunderdomeScreen.Group then
            --Leave friends-group, return to selection screen
                
                -- The user can trigger the leave button twice in short succession,
                -- leading to LeaveGroup(nil) if we don't check the lobby id
                if td:GetGroupLobbyId() then
                    td:LeaveGroup( td:GetGroupLobbyId() )
                end

                self:Reset()
                return
            end

            if curScr == kThunderdomeScreen.Selection then
                self:Reset()
                self:OnBack()
            end

            SLog("   ...reset & leave TD")
            self:LeaveThunderdome(true)
            self:Reset()
            return
        end

    end

    -- If we don't need to show the leave confirmation, just do the accept callback.
    if acceptCallback then
        acceptCallback()
    end

end

function GUIMenuThunderdome:DoLeaveConfirmation(acceptCallback)
    SLog("** GUIMenuThunderdome:DoLeaveConfirmation()")
    if self:GetPopupState() ~= kThunderdomePopupState.None then
        return
    end

    self:SetPopupState(kThunderdomePopupState.NonPenalized)

    local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
    {
        title = Locale.ResolveString("THUNDERDOME_LEAVE_WARNING_TITLE"),
        message = Locale.ResolveString("THUNDERDOME_LEAVE_WARNING_MESSAGE"),
        buttonConfig =
        {
            GUIPopupDialog.OkayButton,
            GUIPopupDialog.CancelButton
        },

    })
    popup.acceptCallback = acceptCallback

    self:HookEvent(popup, "OnConfirmed", self.OnLeavePopup_Confirm)
    self:HookEvent(popup, "OnCancelled", self.OnLeavePopup_Cancel)

end

function GUIMenuThunderdome:DoLeaveConfirmationPenalized(acceptCallback)
    SLog("** GUIMenuThunderdome:DoLeaveConfirmationPenalized()")
    if self:GetPopupState() ~= kThunderdomePopupState.None then
        return
    end

    self:SetPopupState(kThunderdomePopupState.Penalized)

    local leaveMessage = GetLeaveLobbyMessage()

    local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
    {
        title = Locale.ResolveString("THUNDERDOME_LEAVE_WARNING_TITLE"),
        message = leaveMessage,
        buttonConfig =
        {
            GUIPopupDialog.OkayButton,
            GUIPopupDialog.CancelButton
        },

    })
    popup.acceptCallback = acceptCallback

    self:HookEvent(popup, "OnConfirmed", self.OnLeavePopup_ConfirmPenalized)
    self:HookEvent(popup, "OnCancelled", self.OnLeavePopup_Cancel)

end

function GUIMenuThunderdome:DoLeaveConfirmationPenalizedInGame(acceptCallback)
    SLog("** GUIMenuThunderdome:DoLeaveConfirmationPenalizedInGame()")
    if self:GetPopupState() ~= kThunderdomePopupState.None then
        return
    end

    self:SetPopupState(kThunderdomePopupState.PenalizedInGame)

    local leaveMessage = GetLeaveLobbyMessage()

    local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
    {
        title = Locale.ResolveString("THUNDERDOME_LEAVE_WARNING_TITLE"),
        message = leaveMessage,
        buttonConfig =
        {
            GUIPopupDialog.OkayButton,
            GUIPopupDialog.CancelButton
        },

    })
    popup.acceptCallback = acceptCallback

    self:HookEvent(popup, "OnConfirmed", self.OnLeavePopup_ConfirmPenalized)
    self:HookEvent(popup, "OnCancelled", self.OnLeavePopup_Cancel)

end

function GUIMenuThunderdome:Uninitialize()

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyJoinFailed,         self.TD_LobbyJoinFailed)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyCreateFailed,       self.TD_LobbyCreateFailed)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUISteamConnectionLost,     self.TD_SteamConnectionFailure)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIHiveProfileFetchFailure, self.TD_HiveProfileFetchFailure)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUISystemDisabled,          self.TD_SystemDisabled)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUISearchFailed,            self.TD_SearchFailed)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIOwnerChangeFailed,       self.TD_OwnerChangeFailed)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIServerWaitFailed,        self.TD_ServerWaitFailed)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIMatchProcessFailed,      self.TD_MatchProcessFailed)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIServerConnectFailed,     self.TD_ServerConnectFailed)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILeaveLobby,              self.TD_OnLobbyLeft)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyStateRollback,      self.TD_LobbyStateRollback)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIPenaltyIsActive,         self.TD_PenaltyIsActive)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIPenaltyStateChanged,     self.TD_PenaltyStateChanged)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIChatMessage,             self.TD_OnChatMessage)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyJoined,                 self.TDLobbyJoined)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUICommandersWaitStart,         self.TD_CommanderWaitStarted)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIMinRequiredCommandersSet,    self.TD_ExtraCommanderWaitStarted)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIServerWaitStart,             self.TDServerWaitStart)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIMapVoteStart,                self.TDMapVoteStarted)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberJoin,           self.TD_UpdateStatusBars)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberLeave,          self.TD_UpdateStatusBars)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberKicked,         self.TD_UpdateStatusBars)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange, self.TD_LobbyMemberDataChanged)

    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIServerReconnectPrompt, self.TD_ServerReconnectPrompt)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyInviteReceived,   self.TD_LobbyInviteReceived)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyInviteInvalid,   self.TD_LobbyInviteInvalid)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIAfkKickedPrompt,       self.TD_AfkWarningTimerPrompt)

    GUIMenuNavBarScreen.Uninitialize(self)

end
