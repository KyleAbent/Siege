-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/thunderdome/ThunderdomeManager.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")
Script.Load("lua/thunderdome/LobbyUtils.lua")

Script.Load("lua/thunderdome/LobbyMemberModel.lua")
Script.Load("lua/thunderdome/LobbyModel.lua")

Script.Load("lua/thunderdome/LobbyClientSearch.lua")
Script.Load("lua/thunderdome/LobbyClientMember.lua")
Script.Load("lua/thunderdome/LobbyClientOwner.lua")

Script.Load("lua/thunderdome/GroupClientMember.lua")
Script.Load("lua/thunderdome/GroupClientOwner.lua")

Script.Load("lua/thunderdome/ClientLobbyFunctors.lua")

--Script.Load("lua/thunderdome/TempShuffle.lua")      --TEMP!!!!  --  REMOVE B4 SHIP!


-------------------------------------------------------------------------------


--[[
This is essentially a wrapper for all the engine binding functions
related to Steam Lobbies. All primary logic should flow through this class
that pertains to Lobbies and Thunderdome.
--]]
class 'ThunderdomeManager'

--[[
None               - Client not in Lobby, idle in menu, on community server, or localhost
LobbyMember        - Local client is a member of a lobby
LobbySearch        - Local client is running searches on lobbies (looking for match)
LobbyOwner         - Local client Owns the lobby they're a member of it
--]]
ThunderdomeManager.kUpdateModes = enum({ 'None', 'Search', 'LobbyMember', 'LobbyOwner', 'GroupOwner', 'GroupMember' })

--Frequency which Update() of this class and its child mode-objects run at
ThunderdomeManager.kUpdateRate = 0.033  --TODO Tune

--Maximum rate lobby chat messages will send
ThunderdomeManager.kMaxChatSendRate = kLobbyChatSendRate

--Amount of seconds before system attempts to authenticate local-client (lobby owner) again
ThunderdomeManager.kReAuthRetryDelay = 2

--upper bound for number of seconds system will delay before attempting to re-auth again
ThunderdomeManager.kMaxAuthAttemptDelay = 8

--Maximum number of total attempts to authenticate local-client
ThunderdomeManager.kMaxAuthAttempts = 3

--Max amount of time alloted for (re)generating a Steam auth-tick. Typically, this action "should" be sub 2 seconds
ThunderdomeManager.kMaxSteamAuthGenerateLimit = 30

--Delay on class init-step (e.g. first few updates) for this to run checks on cached-ids and/or out-of-game lobby invites
ThunderdomeManager.kMinOnLoadCheckLobbyDelay = 1

--Absolute timeout for local-client attempting to fetch its Hive profile
ThunderdomeManager.kHiveProfileFetchTimeout = 25 --seconds

--Small delay before local-client sends TD Server a network message with their team/role data
ThunderdomeManager.kConnectedMessageDelay = 2.5

--Maximum time alloted for a Steam auth-ticket to be considered valid
ThunderdomeManager.kMaxSteamAuthTicketLifetime = 1800 --30m

--indicates the max number of times local client can be marked as steam offline, before this system assumes no connection
ThunderdomeManager.kSteamConnFailedLimit = 4

--time delay between Steam online checks
ThunderdomeManager.kSteamConnCheckInterval = 3

--max time (local) in seconds which a client can stay in a public-type lobby
ThunderdomeManager.kMaxLobbyLocalLifespan = 60 * 60  --1hr

--Minor delay (seconds) before triggering GUI-scope event for Lobby invites. Used to allow meta-data to be loaded
--before invite is triggering (of accept). So, group vs match lobby diff can be handled. This needs to be at minimum
--of 1.25 seconds, never smaller.
ThunderdomeManager.kInvitePromptDelay = 2


function ThunderdomeManager:Initialize()
    SLog("=== ThunderdomeManager:Initialize() ===")

    --Simple ref table of tables for event listeners
    self.eventListeners = {}
    for i = 1, #kThunderdomeEvents do
        self.eventListeners[ kThunderdomeEvents[ kThunderdomeEvents[i] ] ] = {}  --use only numeric value of enum
    end

    --TD events can also be queued to trigger at a later time, this holds them. This is a table of tables, see :TriggerDelayedEvent
    self.delayedEventsQueue = {}
    for i = 1, #kThunderdomeEvents do
        self.delayedEventsQueue[ kThunderdomeEvents[ kThunderdomeEvents[i] ] ] = {}  --use only numeric value of enum
    end

    --Queue for any events trigger in a way which they _must_ await data update to trigger for either lobby-meta data, or
    --for member meta-data. These events should only be used in this way. Purely time delayed ones should use `self.delayedEventsQueue`
    self.dataDelayedEventsQueue = {}
    for i = 1, #kThunderdomeEvents do
        self.dataDelayedEventsQueue[ kThunderdomeEvents[ kThunderdomeEvents[i] ] ] = {}  --use only numeric value of enum
    end

    --Queue for foreign-lobby data updates which need to be delayed until a steam update has been received
    self.pendingForeignLobbyRequests = {}

    --Initial local timestamp client joins (or creates) a lobby
    self.joinedLobbyTime = 0

    --String cache for current generated auth session ticket
    self.authTicket = nil

    --Single LobbyID local client is currently a member of (regardless of member-type)
    self.activeLobbyId = nil

    --Simple stash spot for incoming and accepted Lobby invitations (LobbyID), used to know if an invite is "active"
    self.cachedLobbyInviteId = nil

    --
    self.groupLobby = nil

    --
    self.groupLobbyId = nil

    --dumb flag to denote user _just_ joined a lobby from steam invitation
    self.recentlyJoinedCachedInvite = false

    --These two should be obvious, if they're not, please stop reading the code
    self.buildNumber = Shared.GetBuildNumber()
    self.steamBranch = Client.GetSteamBranch()

    --Simple flag set on client-init to denote if Thunderdome is unavailable / down
    self.thunderdomeDisabled = false

    --Cache for event listeners to fetch parsed lobby search results
    self.searchResultsList = nil

    --flag to indicate if lobby/match searching is processing data (required for Steam callbacks)
    self.searchingActive = false

    --simple int to denote if all of the search-list lobbies had their data fetched
    self.searchingDataFetchCount = 0

    --Indicates that Match searching was canceled by user, this flips the system back to "None" state on next update
    self.cancelSearching = false

    --Rate limiter tracking (note, not delta-time based)
    self.lastUpdatedTime = 0

    --Sub-routine object to handle specific functionality for Search/Member/Owner client-modes
    self.clientModeObject = nil

    --This dictates which update/state sub-routine is run when Update is called
    self.updateMode = self.kUpdateModes.None

    --Local client TD session id. Required to interact with TD API
    self.activeSessionId = nil

    --Timestamp of when re-authentication attempt starts
    self.authAttemptTime = 0

    --Amount of time in seconds after .authAttemptTime the re-auth attempt should be made
    self.authAttemptDelay = -1

    --Counter to denote how many attempts have been done to call into auth-api endpoint
    self.authAttempts = 0

    --Attempting to authentication local-client, need to delay until this is resolved
    self.authenticationAttemptActive = false

    --Flag to denote TD local-client authentication routine is awaiting Steam to generate new auth-ticket
    self.pendingSteamAuthGenerate = false

    --System timestamp to denote when steam auth-ticket generation started
    self.timeSteamAuthGenerate = 0

    --Flag to denote system is awaiting local-client to decide on rejoin prompt from AFK kick
    self.pendingAkfPromptAction = false

    --Flag to denote system need to confirm generating Reconnect prompt before proceeding (always checked)
    self.pendingReconnectPrompt = false

    --Flag to force local-client into only attempting to swap lobby ownership to another member
    --this is only set back to false when the swap-sequence completes. This will effectively
    --trigger local-client to flip to LobbyClientMember mode when true.
    self.swapOwnersActive = false

    --simple flag to indicate if TDMgr is attemptin to re-join/load lobby data after Lua VM start
    self.initLobbyDataLoadOnly = false

    --Flag to denote a connection attempt was made, but failed to Lobby's server. Only applies
    --when client Main VM has reloaded and parsed stored cached lobby-id
    self.lobbyServerConnFailed = false

    --Local-client internal data loading/initialization finalized flag (set once per boot)
    self.initializedLocalData = false

    --Indicate local-client is attempting to create a lobby and should ignore OnLobbyJoined events.
    --Works around Steam data-race bug where local client joins lobby and is made owner
    --(by previous owner leaving) before OnLobbyJoined event is processed.
    self.isCreatingLobby = false

    --One-time usage flag to denote system is attempting to re-load/join a cached lobby-id
    --used to fail-over to lobby-invite-id, to handle "old cache-id" but new invite-id
    self.isRejoiningCachedLobbyId = false

    --Flag to denote TDMgr should consider local-client connected to a TD server instance.
    --The moment its lobby data is re-loaded (handled from Init step), trigger network message
    --to prompt server to assign local player to their assigned team.
    self.isConnectedToServer = false

    --Flag to denote local-client has completed the needed tasks _after_ it has connected to a TD Server
    --and finished (re)loading all the active lobby data.
    self.onConnectedInitComplete = false

    --Timestamp to log when a client connect, used to slightly delay notifying server of their lobby-shuffled
    --team assignment and role network message.
    self.isConnectedTime = -1

    --array of steam64Id strings which denote local-client won't see chat messages from
    self.mutedSteamIds = {}

    --last local-time lobby chat message was sent
    self.lastChatSendTime = 0

    --Simple cache to hold the last attempted lobby-type when creating one
    self.lastLobbyCreateType = -1

    --flag to denote call into Hive for player's profile data completed. No initiating actions can be done
    --until this data is set (or call out fails)
    self.localHiveProfileFetched = false

    --Flag denotes trying to fetch local client's Hive profile failed (HTTP call failed)
    self.localHiveProfileFetchFailed = false

    --flag denotes local-client has lost connection to Steam, thus no other TD actions can occur
    self.steamConnectionLost = false

    --momentary flag to denote the last online state check failed, thus we're offline
    --Note: this is not the same as steamConnectionLost, this used for per-update ticks, not full-state changes.
    self.steamIsDisconnected = false

    --timestamp to denote last time client reported no Steam connection
    self.lastSteamConnLostTime = 0

    --timestamp of each tick when checking Steam connection
    self.lastSteamConnCheckTime = 0

    --tick denote the number of times client reports no Steam connection
    self.steamConnectionFailedTick = 0

    --Timestamp to indicate when Hive Profile query call begins
    self.hiveProfileFetchStartTime = 0

    --store skill values for local client (populates Lobby member data)
    self.avgSkill = 0
    self.skillOffset = 0
    self.commSkill = 0
    self.commOffset = 0
    self.adagradGradient = 0

    --Stores the Lat/Long geo-coords of the _local_ client. Used for computing geo-distances
    self.playerGeoData = { 1, -1 }

    self.playerName = kDefaultPlayerName

    --Track any lobbies local client was kicked/removed from. Used for search filtering
    self.kickedLobbies = {}

    self:InitLocalEventListeners()
    
    --simple timestamp of when this object was initialized, used once to delay the first check for
    --cached ids, or out-of-game invites
    self.initTimestamp = Shared.GetSystemTime()

    --Flag to denote the local TD system failed to initialized (typically because of failure to fetch Hive data)
    --this halts all updates and events once it's set. TD system will be unusable for local-client at that point.
    self.systemInitFailed = false


--Group Queuing Data ------------------

    --Local-client's GroupID for dealing with Member data writes/reads, and team shuffle
    self.localGroupId = ""

    --simple bool to denote if local-client is in Group Queue state or not
    self.isGroupQueueEnabled = false

end

--This should only ever be triggered self.kMinOnLoadCheckLobbyDelay time or greater after this class is
--initialized. Doing so otherwise can results in failed Steam callbacks and script errors due to local-client
--not being in a fully-loaded state yet.
function ThunderdomeManager:DelayedStartupChecks()
    SLog("ThunderdomeManager:DelayedStartupChecks()")

    if not Client.GetIsSteamAvailable() then
        self.systemInitFailed = true
    end

    local profile = {}
    if not Client.GetLocalHiveProfileData( profile ) then
        Log("ERROR: Failed to read Hive profile after set!")
        --TD-TODO Add trigger for Hive profile fetch-failure
        return
    else
        SLog("Cached Hive Profile:")
        SLog("%s", profile)

        --Handle first-time TD player case, fail-over to CR skills if null/zero
        local tdS = (type(profile[6]) == "number" and profile[6] > 0) and profile[6] or profile[1]
        local tdCS = (type(profile[7]) == "number" and profile[7] ~= 0) and profile[7]  or profile[2]
        local tdSo = (type(profile[8]) == "number") and profile[8] or profile[3]
        local tdCSo = (type(profile[9]) == "number") and profile[9] or profile[4]
        local tdAd = (type(profile[10]) == "number" and profile[10] > 0) and profile[10]  or profile[5]
        
        self:SetLocalHiveProfile( 
            profile[1], profile[2], profile[3], profile[4], profile[5],     --CR skills
            tdS, tdCS, tdSo, tdCSo, tdAd,                                   --TD skills
            profile[15], profile[16],                                       --lat,long
            profile[17]                                                     --thunderdome disabled flag
        )
    end

    if self.systemInitFailed then
    --ensure non-TD pop-ups can run (Disconnect message, etc.)
        self:TriggerEvent( kThunderdomeEvents.OnMenuLoadEndEvents )
        return
    end

    local launchLobbyId = Client.GetOnLaunchLobbyId()
    local cachedLobbyId = Client.GetOptionString( kOptionKey_CachedLobbyId, "" )
    local shouldDelayedLaunch = false

    if launchLobbyId or cachedLobbyId then
        SLog("\t   launchLobbyId:   %s", launchLobbyId)
        SLog("\t   cachedLobbyId:   %s", cachedLobbyId)
    end

    local hasDelayedLaunch = self:ProcessDelayedLaunchId( launchLobbyId, cachedLobbyId )

    if not hasDelayedLaunch then
    --Enure all "normal" on-load messages can trigger when not awaiting lobby data (i.e. invalid password, client/server diff, invalid password, etc.)
        self:TriggerEvent( kThunderdomeEvents.OnMenuLoadEndEvents )
    end

end

-- Handle delayed load of lobby metadata to be able to determine if we're
-- launching into a group or normal lobby.
-- Returns true if we have one (or more) lobby IDs to retrieve data for, false if we should continue "normal" startup procedures.
function ThunderdomeManager:ProcessDelayedLaunchId( launchLobbyId, cachedLobbyId )

    local joinLaunchLobby = function()
        self:JoinLobbyInvite( launchLobbyId, true )
    end

    local joinCachedLobby = function()
        self:ProcessCachedLobbyId( cachedLobbyId )
    end

    -- Fail-over to joining the cached lobby ID if the given launch lobby ID doesn't exist
    local fallbackHandler = function()
        if cachedLobbyId and cachedLobbyId ~= "" then
            self:LoadForeignLobbyData( cachedLobbyId, joinCachedLobby )
        end
    end

    -- Don't process launch lobby ids if we're loading while connected to a TD server
    if not Shared.GetThunderdomeEnabled() and launchLobbyId and launchLobbyId ~= "" then
        --handle steam launch invites to lobby
        SLog("Have launch lobby ID, attempting lobby data load...")

        self:LoadForeignLobbyData( launchLobbyId, joinLaunchLobby, fallbackHandler )
        return true
    elseif cachedLobbyId and cachedLobbyId ~= "" then
        --assume Lua VM restart, regardless of reason (e.g. crash, server-connect, etc.)
        SLog("Have Cached LobbyID on-load, attempt loading/re-join...")

        self:LoadForeignLobbyData( cachedLobbyId, joinCachedLobby )
        return true
    end

    return false

end

-- Handle joining a lobby invite that we've already received data about.
-- Performs filtering to determine whether the referred-to lobby actually
-- exists and is in some joinable state, as well as determining whether it's
-- a match lobby or a group lobby.
---@param lobbyId string SteamID of the lobby to attempt to join
---@param isLaunchId boolean|nil pass-through parameter to determine whether
---                              this lobby is being auto-joined at startup
---@return boolean success: if true, the lobby passed all data filtering and
---                         a join attempt was initiated
function ThunderdomeManager:JoinLobbyInvite( lobbyId, isLaunchId  )
    SLog("ThunderdomeManager:JoinLobbyInvite( %s, %s )", lobbyId, isLaunchId)
    local lobData = Client.GetLobbyDataField( lobbyId, kLobbyModelSyncField )

    if lobData and lobData ~= "" then
        SLog("  Deserialized LobbyData:\n%s", lobData)

        if self:GetIsConnectedToLobby() then
            self:LeaveLobby(self.activeLobbyId, true)
        end

        if self:GetIsGroupQueueEnabled() then
            self:LeaveGroup( self:GetGroupLobbyId() )
        end

        local lobby = LobbyModel()
        lobby:Init()
        lobby:Deserialize( lobData )

        --Init lobby model fields not covered by the data model sync field
        --NOTE: these fields "should" be present if the data model field is available
        lobby:SetField( LobbyModelFields.Build, Client.GetLobbyDataField( lobbyId, kLobbyModelFieldBuild ) )
        lobby:SetField( LobbyModelFields.SteamBranch, Client.GetLobbyDataField( lobbyId, kLobbyModelFieldBranch ) )
        lobby:SetField( LobbyModelFields.Version, Client.GetLobbyDataField( lobbyId, kLobbyModelFieldVersion ) )
        lobby:SetField( LobbyModelFields.NumMembers, Client.GetNumLobbyMembers( lobbyId ) )

        SLog("  Attempting to filter lobby %s, data:", lobbyId)

        lobby:DebugDump( true )

        local canJoin = false

        if lobby:GetIsGroup() then
            canJoin = GetIsFriendGroupJoinable( lobby )
        else
            canJoin = GetIsLobbyJoinable( lobby )
        end

        if not canJoin then
            SLog("  Lobby does not pass joinable-check, cannot join lobby from invite.")
            SLog("      lobbyId: %s", lobbyId)
            SLog("      isGroup: %s", lobby:GetIsGroup())
            SLog("\n")

            -- TD-TODO: is it worth trying to pass a reason for the lobby invite being invalid?
            self:TriggerEvent( kThunderdomeEvents.OnGUILobbyInviteInvalid )

            return false
        end

        self:JoinLobby( lobbyId, isLaunchId, lobby:GetIsGroup() )

        return true
    end

    SLog("  Unable to deserialize invite lobby data, invited lobby does not exist?")

    return false
end

--Simple priming function to reload all lobby data/state from a lobby local-client is already a member of
function ThunderdomeManager:ProcessCachedLobbyId( cachedId )
    SLog("ThunderdomeManager:ProcessCachedLobbyId( %s )", cachedId)
    assert(cachedId)

    local cachedLobMems = {}
    if not Client.GetLobbyMembersList( cachedId, cachedLobMems ) then
        SLog("Warning: Failed to fetch Cached-Lobby members list!")
    end

    -- Load lobby data to handle rejoining group lobbies / filter out deceased lobbies
    local lobData = Client.GetLobbyDataField( cachedId, kLobbyModelSyncField )
    local isGroup = false

    if lobData and lobData ~= "" then
        SLog("  Deserialized LobbyData:\n%s", lobData)
        
        local lobby = LobbyModel()
        lobby:Init()
        
        lobby:Deserialize(lobData)
        isGroup = lobby:GetIsGroup()
    else
        SLog("  Invalid / unknown lobby data! Cannot tell if we're in a group or if lobby still exists!")
    
        return false
    end

    -- NOTE: we do this *before* leaving any lobbies/groups to ensure the option is not cleared on-disk
    -- accidentally as a result of resetting any state the user may have managed to get into.
    local cachedGroupId = Client.GetOptionString(kOptionKey_CachedLobbyGroupId, "")
    
    -- Clear any potential local Thunderdome state
    -- FIXME (sturnclaw): this is better handled by a modal block in the UI preventing any thunderdome
    -- state actions from being taken while we're waiting to process a cached/launch lobby ID
    if self:GetIsConnectedToLobby() then
        self:LeaveLobby(self.activeLobbyId, true)
    end

    if self:GetIsGroupQueueEnabled() then
        self:LeaveGroup( self:GetGroupLobbyId() )
    end
    -- END FIXME

    local clientSteamId = self:GetLocalSteam64Id()

    -- Set the local group ID so we persist client group assignments across lobby crash/rejoin
    self:SetLocalGroupId(cachedGroupId)

    if not table.icontains( cachedLobMems, clientSteamId ) then
    --Client crashes handler condition, thus Steam no longer viewed as connected. 
    --If client crashed and didn't relaunch for some time, lobby won't exist so this will just fail-out(safely)
        SLog("\t Local not found in members list, joining normally...")
        -- self.isRejoiningCachedLobbyId = true
        -- TD-TODO: it might be worth trying to prioritize rejoining a cached lobby over a lobby invite when
        -- penalties are relevant again, e.g. if the cached lobby exists and is in playing state.

        self:JoinLobby( cachedId, true, isGroup )

        return true
    
    else
    -- Local client's Steam-client considers it already connected/loaded in Lobby, reload lobby data & client-object
    -- (e.g. Restart-main or connecting to TD instance)
        SLog("\t Local found in members list, refresh and re-init lobby state...")

        self:RejoinLobby( cachedId, isGroup )
        return true
    end

end

--[[
TODO *** IN-Game Lobby invites ***

    - When invite callback (into ClientGame, thus Hooked in Lua) received, trigger Menu pop-up IF local client NOT on server (local or otherwise)
        - If connected to server  ...do...what, exactly? Local menu timeout? Some prompt thing? Wait until dead?  ....this gets fucky

-ON ACCEPT
    - If connect to ANY server...
        - On invite accept, cache invite Id to options (clear first? or cache to different field?)
        - Disconnect from server (local or otherwise)
        - OnLoad "should" capture the invite and load/join said lobby
--]]

function ThunderdomeManager:OnLobbyInviteReceived( lobbyId, inviterId, inviterName )                    --TD-FIXME This MUST perform a data-dip of Lobby in order to determine Type (Match / Group)
    SLog("ThunderdomeManager:OnLobbyInviteReceived( %s, %s, %s )", lobbyId, inviterId, inviterName)

    assert(lobbyId)
    assert(inviterId)
    assert(inviterName)

    local canAccept = true

    --Block invites when on any non-localhost server
    if Shared.GetThunderdomeEnabled() or ( Client.GetIsConnected() and not Client.GetIsRunningServer() ) then
    --cannot accept lobby invitations while in active TD server
        canAccept = false
    end

    if Client.GetIsThunderdomePenalized() then
        canAccept = false
    end

    if self:GetIsConnectedToLobby() and self:GetActiveLobbyId() == lobbyId then
    --no point in dealing with an invite to our active lobby...block "yo dawg"
        canAccept = false

    --[[
        McG:  TD-FIXME This while conceptually is fine, blocks GUI interaction when occurs from Steam double-prompt. For now, silence one in lobbies
         - will require TDMgr handling of all GUI-scope TD specific prompts, as internal state checks needed before any GUI actions taken (i.e. isShowingInvite like flag check)
    elseif canAccept and self:GetIsConnectedToLobby() then
        local lobState = self.activeLobby:GetState()
        canAccept = lobState < kLobbyState.WaitingForCommanders
    --]]
    end
    
    --TD-TODO This needs some kind of "soft" event which notifies user, but doesn't FORCE it in their face
    -- e.g. Stash it, then display front-and-center as soon as local-client is dead(in-game), or game ends, etc.
    -- Note: above will need some kind of Invite Expiration period or some such...no sense in trying to join X minutes (i.e. after a round is over)
    ----    Basically, when chance to display presents, test lob-data first, show if applicable (i.e. don't show if lobby full, match in progress, etc.)

    if canAccept then
        self:LoadForeignLobbyData( lobbyId, function()
            self.cachedLobbyInviteId = lobbyId
            self:TriggerEvent( kThunderdomeEvents.OnGUILobbyInviteReceived, lobbyId, inviterId, inviterName )
        end)
    else
    --Silence ignore, as user cannot do anything with the invite anyway
        self.cachedLobbyInviteId = nil
        self.recentlyJoinedCachedInvite = false
    end

end

function ThunderdomeManager:GetHasCachedInvite()
    return self.cachedLobbyInviteId ~= nil
end

function ThunderdomeManager:GetHasRecentlyJoinedInvitedLobby()
    return self.recentlyJoinedCachedInvite
end

function ThunderdomeManager:OnRejectLobbyInvitation()
    self.cachedLobbyInviteId = nil
    self.recentlyJoinedCachedInvite = false
end

--TD-TODO Add cached invite expiration check/routine(s)

--Only applicable to be triggered on GUI shutdown/destroy
function ThunderdomeManager:Uninitialize()
    SLog("ThunderdomeManager:Uninitialize()")
    if self.activeLobbyId then  --FIXME This will interfere with any in-progress or Loading states...
        self:LeaveLobby(self.activeLobbyId)
    end
end

--Checks to see if client is in a lobby (and connected), and cache that LobbyID in system options file
--this ID is used in cases where the program crashes, so clients can quickly rejoin it (thus rejoin its associated server)
function ThunderdomeManager:UpdateCachedLobbyIdState()
    SLog("ThunderdomeManager:UpdateCachedLobbyIdState()")

    local lobbyId
    if self.groupLobbyId then
        lobbyId = self.groupLobbyId
    else
        lobbyId = self.activeLobbyId
    end
    
    local oldCachedId = Client.GetOptionString( kOptionKey_CachedLobbyId, "" )
    SLog("\t    oldCachedId:  %s", oldCachedId)
    SLog("\t   groupLobbyId:  %s", self.groupLobbyId)
    SLog("\t  activeLobbyId:  %s", self.activeLobbyId)
    SLog("\t     selectedId:  %s", lobbyId)

    if oldCachedId ~= lobbyId then
        Client.SetOptionInteger( kOptionKey_CachedLobbyConnAttempts, 0 )
        Client.SetOptionBoolean( kOptionKey_CachedLobbyConnMade, false )
        SLog("!!!! Cleared cached CONN lobby-data !!!")
    end
    Client.SetOptionString( kOptionKey_CachedLobbyId, lobbyId )
end


function ThunderdomeManager:GetVerboseEnabled()
    return g_thuderdomeVerbose
end

function ThunderdomeManager:GetTestsEnabled()
    return g_thunderdomeTests
end

function ThunderdomeManager:GetSystemState()
    return self.updateMode
end

-----------------------------------------------------------
--- Events & Signals --------------------------------------

--Convenience util so callee can use function instead of having to fetch TD object first
function Thunderdome_AddListener( eventType, callback )
    local td = Thunderdome()
    td:AddEventListener( eventType, callback )
end

--Convienience util so callee can use function instead of having to fetch TD object first
function Thunderdome_RemoveListener( eventType, callback )
    local td = Thunderdome()
    td:RemoveEventListener( eventType, callback )
end

--Simple method for GUI to get notified of X lobby event. This allows
--time for the data to be processed / handled. Reduces the need for GUI
--to do a bunch of polling / queries when it is updating. The 'callback'
--may or may not receive parameters, it's up to each event handler.
function ThunderdomeManager:AddEventListener( event, callback )
    assert(event)
    assert(kThunderdomeEvents[event])
    assert(self.eventListeners[event])
    assert(type(callback) == "function")
    table.insert(self.eventListeners[event], callback)
end

function ThunderdomeManager:RemoveEventListener( event, callback )
    assert(event)
    assert(self.eventListeners[event])
    if #self.eventListeners[event] > 0 then
        for i = 1, #self.eventListeners[event] do
            if self.eventListeners[event][i] == callback then
                table.remove( self.eventListeners[event], i )
            end
        end
    end
end

--Sanity function to ensure event types are always in sync with system-state
local IsValidEventType = function(type)
    assert(type)
    return kThunderdomeEvents[type] and kThunderdomeEvents[kThunderdomeEvents[type]]    --cheesy "IsEnum" test
end

--Allows for an event to be "triggered", but only after 'delay' has passed (keep in mind inherent delay of self.kUpdateRate)
--any soft-locking state (awaiting X external HTTP call results, etc) will also add delay on top of the passed wait-time. So
--any events setup via a delay-trigger, should not be range-limited, and instead think of 'delay' as "at least X time before Event".
--Also, this requires the intended listener for the passed event already be registered. 
function ThunderdomeManager:TriggerDelayedEvent( eventType, delay, ... )
    SLog("ThunderdomeManager:TriggerDelayedEvent( '%s', %s, %s )", kThunderdomeEvents[eventType], delay, {...} )
    assert(eventType)
    assert(IsValidEventType(eventType))
    assert(self.delayedEventsQueue)
    
    if self.systemInitFailed and eventType ~= kThunderdomeEvents.OnSystemInitFailed then
    --Halt all other events from firing
        return
    end

    local delayedEvent = { wait = delay, args = {...}, started = Shared.GetSystemTime() }
    table.insert( self.delayedEventsQueue[eventType], 1, delayedEvent ) --FILO
    SLog("  Added delayed-event[%s] for %s delay", kThunderdomeEvents[eventType], delay)
    SLog("%s", self.delayedEventsQueue[eventType])
end

--Allows for events to only be triggered when a meta-data update occurs for a given MemberID or
--for lobby data (note: lobby data is unreliable and should be avoided).
--the specified memberId is to be matched on member-only updates when Steam event triggers
--lobby meta-data update callback(s)
function ThunderdomeManager:TriggerDataDelayedEvent( eventType, memberId, ... )
    assert(eventType)
    assert(IsValidEventType(eventType))
    assert(self.dataDelayedEventsQueue)
    assert(memberId)

    if self.systemInitFailed and eventType ~= kThunderdomeEvents.OnSystemInitFailed then
    --Halt all other events from firing
        return
    end

    local dataEvent = { member_id = memberId, args = {...} }
    table.insert( self.dataDelayedEventsQueue[eventType], 1, dataEvent ) --FILO
end


--Initiate all registrant functions for the passed in Event. Each handler will get
--a reference to this object and the clientModeObject, for ease of data-handling(set/get)
--always as first param, thus safe to use self. in called function internals
function ThunderdomeManager:TriggerEvent( eventType, ... )
    if eventType ~= kThunderdomeEvents.OnChatMessage then
        SLog("ThunderdomeManager:TriggerEvent( '%s', %s )", kThunderdomeEvents[eventType], {...} )
    end
    assert(eventType)
    assert(IsValidEventType(eventType))
    assert(self.eventListeners)
    --No assert for eventData, as it can and will be nil/'no value' in lots of cases

    if self.systemInitFailed and eventType ~= kThunderdomeEvents.OnSystemInitFailed then
    --Halt all other events from firing
        return
    end

    --Note: all events, regardless of how they're triggered will pass through this routine
    if #self.eventListeners[eventType] > 0 then
        local eventLbl = kThunderdomeEvents[eventType]
        SLog("  Triggering Event: %s", eventLbl)
        for i = 1, #self.eventListeners[eventType] do
            if self.eventListeners[eventType][i] then
            --Always passes in reference to clientModeObject, in order for them to set/read they contain inside TD functors
                self.eventListeners[eventType][i]( self.clientModeObject, ... )
            end
        end
    end
end


--Inbound signal from other objects to denote all search options completed and no viable
--lobbies were found. This initiates new behaviors in the system, typically creating a lobby.
function ThunderdomeManager:SignalSearchExhausted()
    SLog("\t === ThunderdomeManager:SignalSearchExhausted() === \n")
    assert(self.updateMode == self.kUpdateModes.Search)

    self.clientModeObject:Destroy()
    self.clientModeObject = nil --nil until lobby create succeeds

    self.searchingActive = false
    --McG-Note: This is the point in which we'd _potentially_ trigger a prompt to join a skirmish server AND create a lobby

    self:TriggerEvent( kThunderdomeEvents.OnGUISearchExhausted )
    self:CreateLobby( Client.SteamLobbyType_Public )
end

--This should onyl be triggered when it is determined Steam is offline, network issues (consecutive timeouts), etc.
function ThunderdomeManager:SignalSearchFailure()
    SLog("\t === ThunderdomeManager:SignalSearchFailure() === \n")
    assert(self.updateMode == self.kUpdateModes.Search)

    --Clear client modes and trigger search failure to listeners
    self.clientModeObject:Destroy()
    self.clientModeObject = nil

    self.searchingActive = false

    self:TriggerEvent( kThunderdomeEvents.OnGUISearchFailed )
end

--Local TD system internal bindings for its own events
function ThunderdomeManager:InitLocalEventListeners()
    SLog("ThunderdomeManager:InitLocalEventListeners()")
    --Note: this particular event is never Unregistered
    self:AddEventListener( kThunderdomeEvents.OnAuthGenerated, ThunderdomeManager.OnAuthGenerated )

    --Note: this particular event is never Unregistered
    self:AddEventListener( kThunderdomeEvents.OnAuthFailed, ThunderdomeManager.OnAuthFailed )

    --Note: this particular event is never Unregistered
    self:AddEventListener( kThunderdomeEvents.OnLocalHiveProfileDataFetched, kLobbyClientFunctors[kThunderdomeEvents.OnLocalHiveProfileDataFetched] )

    --Note: this particular event is never Unregistered
    self:AddEventListener( kThunderdomeEvents.OnForeignLobbyDataUpdate, ThunderdomeManager.OnForeignLobbyDataUpdate )

    --Note: this particular event is never Unregistered
    self:AddEventListener( kThunderdomeEvents.OnForeignLobbyDataTimeout, ThunderdomeManager.OnForeignLobbyDataTimeout )

    --Always hook this to ensure that regardless of ClientModeObject loaded, the OnGUILobbyLeave event will trigger
    self:AddEventListener( kThunderdomeEvents.OnLeaveLobby, kLobbyClientFunctors[kThunderdomeEvents.OnLeaveLobby] )
end

--Only triggered when local-client connects to a server
function ThunderdomeManager:EnableAutoTeamJoin()
    SLog("ThunderdomeManager:EnableAutoTeamJoin()")

    if Client.GetIsConnected() and Client.GetIsRunningServer() then
    --bypass message event for localhost games
        self.isConnectedToServer = false
        self.onConnectedInitComplete = true
        self.isConnectedTime = -1
    end

    self.isConnectedToServer = true
    self.onConnectedInitComplete = false
    self.isConnectedTime = Shared.GetTime()
end

--Simple utility for Lobby Owners to run lobby meta-data propagation steps
function ThunderdomeManager:TriggerLobbyMetaDataUpload( lobbyId )
    --SLog("ThunderdomeManager:TriggerLobbyMetaDataUpload( %s )", lobbyId )

    local serializedData = nil
    if self:GetIsGroupId( lobbyId ) then
        assert(self.groupLobby, "Error: No LobbyModel active")    
        serializedData = self.groupLobby:Serialize()
    else
        assert(self.activeLobby, "Error: No LobbyModel active")
        serializedData = self.activeLobby:Serialize()
    end

    --SLog("    serialized: %s", serializedData)
    --SLog("    ...setting meta-data field...")

    --below will trigger OnLobbyDataUpdate callback on all clients (including Owner-type)
    Client.SetLobbyDataField( lobbyId, kLobbyModelSyncField, serializedData )
end

function ThunderdomeManager:UpdateOnConnectedState()        --TD-FIXME This doesn't handle crash while loading...also highly volitile to script errors...move in-engine?

    if self.isConnectedToServer and self.isConnectedTime ~= -1 then
    --Only run while actively connected to a server

        if self.isConnectedTime + self.kConnectedMessageDelay > Shared.GetTime() then
        --wait for kConnectedMessageDelay before sending the server local-client team/role message
            return
        end

        if not self.initLobbyDataLoadOnly and not self.onConnectedInitComplete and self.activeLobby then
        --Only run this _after_ lobby data is reloaded, and only do so once
            --Log locally to indicate re-connects are allowed/viable upon a client crash
            self.onConnectedInitComplete = true
        end

    end

end

-------------------------------------------------------------------------------
-- Thunderdome client authentication --

function ThunderdomeManager:CancelSteamAuthTicket()
    SLog("ThunderdomeManager:CancelSteamAuthTicket()")
    Client.CancelSessionAuthTicket()
    self.authTicket = nil
    self.timeSteamAuthGenerate = 0
end

function ThunderdomeManager:GenerateSteamAuthTicket()
    self.pendingSteamAuthGenerate = true
    self:CancelSteamAuthTicket()
    Client.GenerateSessionAuthTicket()
    self.timeSteamAuthGenerate = Shared.GetSystemTime()
end

Event.Hook("Console_td_genauth", function()
    Thunderdome():GenerateSteamAuthTicket()
end)

ThunderdomeManager.OnAuthGenerated = function(clObj, ticketStr)
    SLog("** ThunderdomeManager.OnAuthGenerated")
    SLog("%s", ticketStr)
    assert(ticketStr)
    local td = Thunderdome()
    td:SetSteamAuthTicket(ticketStr)
end

--Calling signals local-client was unable to authenticate with TD system
ThunderdomeManager.OnAuthFailed = function()
    local td = Thunderdome()
    td:ResetAuthentication()
    td:TriggerOwnerChange( td.activeLobbyId ) --never hits auth step in Groups
end


function ThunderdomeManager:GetSteamAuthTicket()
    assert(self.authTicket ~= nil)
    return self.authTicket
end

function ThunderdomeManager:SetSteamAuthTicket(ticketStr)
    SLog("ThunderdomeManager:SetSteamAuthTicket( -- )")
    SLog("\tSteam AuthTicket:\n%s", ticketStr)
    assert(ticketStr)
    self.authTicket = ticketStr
    self.pendingSteamAuthGenerate = false
    --self.timeSteamAuthGenerate = 0
end

function ThunderdomeManager:IsAuthenticated()
    return self.activeSessionId ~= nil and 
        self.authAttemptDelay == -1 and
        self.authAttemptTime == 0 and
        self.authAttempts == 0 and
        self.authTicket ~= nil
end

function ThunderdomeManager:Authenticate()
    SLog("ThunderdomeManager:Authenticate()")
    
    if self.activeSessionId == nil and self.authTicket == nil and not self.pendingSteamAuthGenerate then
    --Always cancel any existing auth-ticket, as it can cause failure if not renewed now
        self:CancelSteamAuthTicket()
    end

    if not self.authTicket and not self.pendingSteamAuthGenerate then
        self:GenerateSteamAuthTicket()
        return
    end

    if self.pendingSteamAuthGenerate then
    --waiting for Steam to generate new auth-ticket value
        return
    end

    local steamId = Client.GetSteamId()
    local requestUrl = string.format("%s%s", kAuthHiveUrl, steamId)

    self.authAttempts = self.authAttempts + 1

    if self.authAttempts > self.kMaxAuthAttempts then
        SLog("Warning: Max authentication attempts reached, switching lobby-owner...")
        self:TriggerEvent( kThunderdomeEvents.OnAuthFailed )    --err-code?
        self:ResetAuthentication()
        return false
    end

    self.activeSessionId = nil
    self.authAttemptDelay = -1 --"reset" re-auth attempts
    self.authAttemptTime = 0
    self.authenticationAttemptActive = true

    Shared.SendHTTPRequest(requestUrl, "POST", { swakey = self:GetSteamAuthTicket() }, 
        function(res)
            assert(res)
            SLog(res)

            local obj, pos, err = json.decode(res, 1, nil)
            SLog("\t obj: %s\n\t pos: %s\n\t err: %s", obj, pos, err)

            if not obj then
                Log("Error: failed to parse thunderdome authentication response:\n%s\n%s\n%s", obj, pos, err)
                self.authenticationAttemptActive = false
                return false
            end

            if obj.code == 101 or obj.code == 403 then
            --Submited steam auth data is invalid or expired
            --session data was corrupted and should be regenerated
                
            --XX Force a logout/sess-dest first? ...could just make that a flag/param for reauth URI (opt?)
                self:CancelSteamAuthTicket()
                self:GenerateSteamAuthTicket()
                self:SetAuthRetry(self.kReAuthRetryDelay)
            
            elseif obj.code == 429 then

                SLog("Warning: [likely] Client already authenticated / Duplicate auth-attempt!")
                local cachedSessId = Client.GetThunderdomeSessionId()
                if Client.GetThunderdomeSessionId() ~= "" and self.activeSessionId ~= cachedSessId then
                    self.activeSessionId = Client.GetThunderdomeSessionId()
                end
                
                if self.activeSessionId == "" or not self.activeSessionId then
                    self:SetAuthRetry(self.kReAuthRetryDelay + 1)
                end
                return true

            elseif obj.code == 500 then
                
                self:SetAuthRetry(self.kReAuthRetryDelay + 5)    --give a bit more time

            elseif obj.sessid == nil or obj.sessid == "" then
                SLog("Error: Received invalid session-id in response")
                self:SetAuthRetry(self.kReAuthRetryDelay)
            end

            if obj.code == 200 then

                assert(obj.sessid)
                SLog("\t Received valid response, SessID: %s", obj.sessid)
                self:SetSessionId(tostring(obj.sessid))

                self.authAttemptDelay = -1 --"reset" re-auth attempts
                self.authAttemptTime = 0
                self.authAttempts = 0
                self.authenticationAttemptActive = false

                --Cancel the auth-token, since it has now been used. Immediately trigger a
                --new token generation, so there is no delay when connecting to TD server.
                self:CancelSteamAuthTicket()
                self:GenerateSteamAuthTicket()

                return true --Authenticated
            end

            self.authenticationAttemptActive = false

            Log("Error: invalid re-auth response code:\n%s\n%s\n%s", obj, pos, err)
            return false
        end
    )
end

--This will trigger a delayed re-auth attempt, after .authAttemptDelay + .authAttemptTime passes
function ThunderdomeManager:SetAuthRetry( delay )
    assert(delay)
    delay = math.max( delay, math.min(2, self.kMaxAuthAttemptDelay ))

    if self.authAttempts > self.kMaxAuthAttempts then
        SLog("Warning: Maximum number of re-auth attempts reached")
        self:TriggerEvent( kThunderdomeEvents.OnAuthFailed )
        return false
    end
    
    self.authAttemptDelay = delay
    self.authAttemptTime = Shared.GetSystemTime()
    self.authenticationAttemptActive = true --blocks client-obj update until completed or fails
end

function ThunderdomeManager:ResetAuthentication()
    self.activeSessionId = nil
    self.authAttemptDelay = -1
    self.authAttemptTime = 0
    self.authAttempts = 0
    self.authenticationAttemptActive = false
end

-------------------------------------------------------------------------------
-- Local Client Data Only ------------------

--Note: all of these functions are for setting data that'll be read often, but doesn't
--need to be fetched often. Basically, treat as (mostly) read-only

function ThunderdomeManager:SetSessionId(sessId)
    assert(sessId)
    self.activeSessionId = sessId
    Client.SetThunderdomeSessionId(sessId) --cache for reloads, and if re-auth step occurs
end

function ThunderdomeManager:GetSessionId()
    assert(self.activeSessionId)
    return self.activeSessionId
end

function ThunderdomeManager:GetLocalDataInitialized()
    return self.initializedLocalData
end

function ThunderdomeManager:GetLeaveLobbyPenalizes()
    if not self.activeLobby then
        return false
    end

    local lobState = self.activeLobby:GetState()
    local lobType = self.activeLobby:GetType()
    local willPenalize = false

    if lobState and lobState ~= nil then
    --required to check as this can occur if user clicks absurdly fast
        willPenalize = 
            lobState >= kLobbyState.WaitingForCommanders and
            lobState < kLobbyState.Finalized and
            ( 
                not self.lobbyServerConnFailed and 
                not self.lobbyServerFailed and 
                not self.localHiveProfileFetchFailed and
                not self.steamConnectionLost and 
                not self.systemInitFailed
            ) and
            lobType == Client.SteamLobbyType_Public
    end

    return willPenalize
end

function ThunderdomeManager:SetLocalHiveProfile(
    avgSkill, commSkill, skillOffset, commOffset, adagrad, 
    td_avgSkill, td_commSkill, td_skillOffset, td_commOffset, td_adagrad, 
    lat, long, tdSysEnabled)

    SLog("ThunderdomeManager:SetLocalSkills( ... )")
    SLog("     Community-Skills:  s: %s, c: %s, so: %s, co: %s, a: %s", avgSkill, commSkill, skillOffset, commOffset, adagrad)
    SLog("   Thunderdome-Skills:  s: %s, c: %s, so: %s, co: %s, a: %s", td_avgSkill, td_commSkill, td_skillOffset, td_commOffset, td_adagrad)

    assert(td_avgSkill)

    self.avgSkill = td_avgSkill
    self.skillOffset = td_skillOffset
    self.commSkill = td_commSkill
    self.commOffset = td_commOffset
    self.adagradGradient = td_adagrad

    assert(lat and long)
    self.playerGeoData[1] = lat
    self.playerGeoData[2] = long

    self.thunderdomeDisabled = not tdSysEnabled
end

function ThunderdomeManager:HasValidHiveProfileData()
    return 
        not self.localHiveProfileFetchFailed    --no err
        and self.localHiveProfileFetched        --success!
        --and self.hiveProfileFetchStartTime > 0  --attempted
end

function ThunderdomeManager:SetHiveProfileFetched(fetched, hadError, errMsg, systemEnabled )
    SLog("ThunderdomeManager:SetHiveProfileFetched( %s, %s, %s, %s )", fetched, hadError, errMsg, systemDisabled)

    if fetched then
        self.localHiveProfileFetchFailed = false
        self.localHiveProfileFetched = true
    end

    if hadError then
        self.localHiveProfileFetched = true
        self.localHiveProfileFetchFailed = true
        self.systemInitFailed = true

        if errMsg then
            Log("ERROR: Failed to retrieve Hive Profile data!")
            Log("%s", errMsg)
        end
    end
    
    if systemEnabled ~= nil and systemEnabled == false then
    --Thunderdome system is Disabled by Hive
        self.systemInitFailed = true
    end

    self:TriggerEvent( kThunderdomeEvents.OnLocalHiveProfileDataFetched )

    --Allow for "normal" alt-tab behavior now that call completed. Any TD actions
    --will re-trigger full-rate if needed.
    Client.SetLocalThunderdomeMode(false)
end

function ThunderdomeManager:StartingHiveProfileFetch()
    self.hiveProfileFetchStartTime = Shared.GetSystemTime()
end

function ThunderdomeManager:GetHiveProfileFetchedFlags()
    return
        self.localHiveProfileFetched, self.localHiveProfileFetchFailed
end

function ThunderdomeManager:SetPlayerName( name )
    assert(name)
    self.playerName = name
    self:TriggerEvent(kThunderdomeEvents.OnClientNameChange)
end

function ThunderdomeManager:GetLocalPlayerProfile()
    assert(self.playerGeoData and type(self.playerGeoData) == "table" and #self.playerGeoData == 2)
    
    return
    {
        name = self.playerName,
        skill = self.avgSkill,
        skillOffset = self.skillOffset,
        commSkill = self.commSkill,
        commOffset = self.commOffset,
        adagrad = self.adagradGradient,
        lat = self.playerGeoData[1],
        long = self.playerGeoData[2]
    }

end

function ThunderdomeManager:GetLocalPlayerGeoData()
    return self.playerGeoData
end

function ThunderdomeManager:GetLocalSteam64Id()
    return Shared.ConvertSteamId32To64( Client.GetSteamId() )
end

--Simple getter to eliminate need to call Client.GetSteamBranch() multiple times
function ThunderdomeManager:GetSteamBranch()
    return self.steamBranch
end

function ThunderdomeManager:GetLocalClientTeam()
    assert(self.activeLobby)
    assert(self.activeLobbyId)
    local model = self:GetLocalClientMemberModel( self.activeLobbyId )  --no teams in GroupLobby
    assert(model)
    return model:GetField( LobbyMemberModelFields.Team )
end

function ThunderdomeManager:GetIsConnectedToLobby()
    return 
        self.activeLobby and self.activeLobbyId and
        ( self.updateMode == self.kUpdateModes.LobbyMember or 
          self.updateMode == self.kUpdateModes.LobbyOwner )
end

function ThunderdomeManager:GetLobbyState()
    if not self.activeLobby then
        return nil
    end

    return self.activeLobby:GetState()
end

function ThunderdomeManager:GetIsIdle()
    return self.updateMode == self.kUpdateModes.None
end


-------------------------------------------------------------------------------
-- Local Client Lobby Data Functions -------------

function ThunderdomeManager:SetLocalGroupId( groupId )
    assert(groupId, "Error: No group-id passed")
    self.localGroupId = groupId
    Client.SetOptionString(kOptionKey_CachedLobbyGroupId, groupId)
end

function ThunderdomeManager:GetLocalGroupId()
    return self.localGroupId
end

function ThunderdomeManager:ClearLocalGroupId()
    self.localGroupId = ""
    Client.SetOptionString(kOptionKey_CachedLobbyGroupId, "")
end

function ThunderdomeManager:StartGroupSearch()
    assert(self.updateMode == self.kUpdateModes.GroupOwner, "Error: cannot perform group-search while in non-owner mode")
    self.clientModeObject:PerformGroupSearch()
end

function ThunderdomeManager:CancelGroupSearch()
    assert(self.updateMode == self.kUpdateModes.GroupOwner, "Error: cannot cancel group-search while in non-owner mode")

    self.clientModeObject:CancelGroupSearch()
    self.searchingActive = false -- Discard any unprocessed search results
end

function ThunderdomeManager:GetIsGroupQueueEnabled()
    return self.isGroupQueueEnabled
end

--Should be called by GUI, any time the local-client casts their map-vote.
--This will validate and immediately submit the updated member meta-data
function ThunderdomeManager:SetLocalMapVotes( mapVotes )
    SLog("ThunderdomeManager:SetLocalMapVotes( %s )", mapVotes)
    assert(mapVotes)

    assert(#mapVotes > 0 and #mapVotes <= kMaxMapVoteCount)
    
    local localMapVote = ""

    --Package ranked local-client map votes into Lobby data-format
    local validVotes = {}
    for i = 1, #mapVotes do
        if not GetIsValidMap( mapVotes[i] ) then
            Log("Error: invalid map-name[%s] value in votes table", mapVotes[i])
        else
            table.insert( validVotes, mapVotes[i] )
        end
    end

    local localMapVote = table.concat( validVotes, "," )
    
    if localMapVote ~= "" then
    --Note: member model will be updated automatically when the Steam callback OnLobbyDataUpdate is completed
        local model = self:GetLocalClientMemberModel( self.activeLobbyId )
        model:SetField( LobbyMemberModelFields.MapVotes, localMapVote )
        local serialized = model:Serialize()
        assert(serialized)
        Client.SetLobbyMemberData( self.activeLobbyId, kLobbyMemberModelDataSyncField, serialized )
    end

end

--This should not be used by GUI context, it's for the ClientModeObject routine(s)
function ThunderdomeManager:GetLoadedMembersList( lobbyId )
    assert(lobbyId, "Error: no valid lobby-id passed [%s]", lobbyId)
    
    local amList = {}   --actual member Ids
    if not Client.GetLobbyMembersList( lobbyId, amList ) then
        SLog("Error: failed to fetch members list for lobby[%s]", lobbyId)
        return amList
    end

    local loadedList = {}
    for i = 1, #amList do
        local mDat = Client.GetLobbyMemberData( lobbyId, amList[i], kLobbyMemberModelDataSyncField )
        if mDat and mDat ~= "" then
            table.insert( loadedList, amList[i] )
        end
    end
    return loadedList
end

function ThunderdomeManager:AddMutedClient( steamId )
    assert(steamId)
    table.insert(self.mutedSteamIds, steamId)
end

function ThunderdomeManager:RemoveMutedClient( steamId )
    assert(steamId)
    for i = 1, #self.mutedSteamIds do
        if self.mutedSteamIds[i] == steamId then
            table.remove( self.mutedSteamIds, i )
        end
    end
end

function ThunderdomeManager:GetMutedClients()
    return self.mutedSteamIds
end

function ThunderdomeManager:CastLocalKickVote( steamId, vote )
    --TODO Need to format into "hidden" chat message "packet"
    --TODO Need Owning client to parse out those hidden messages
    --TODO For local-members, need to "detect" if kick-vote is active or not ...again, from those stupid "chat packets"
end

--Helper function for GUI-context to get the full list (at time of this call) of
--all lobby members and their associated meta-data. Note: this may not be a complete
--image of all their data, as it might not have been sent and received yet.
function ThunderdomeManager:GetMemberListLocalData( lobbyId )
    --convert models into table for ease of access (remove need for file scoping)
    local members = {}
    if self:GetIsGroupId( lobbyId ) then
        members = self.groupLobby:GetMembers()
    else
        members = self.activeLobby:GetMembers()
    end
    assert(members)

    local memData = {}
    for i = 1, #members do
        table.insert( memData, members[i]:ExportAsTable() )
    end
    return memData
end

function ThunderdomeManager:SetLocalCommandAble( isLocalClientAwesome )
    assert(isLocalClientAwesome)
    assert(self.activeLobbyId)
    local model = self.activeLobby:GetMemberModel( self:GetLocalSteam64Id() )
    model:SetField( LobbyMemberModelFields.CommanderAble, tonumber(isLocalClientAwesome) )
    local serialized = model:Serialize()
    Client.SetLobbyMemberData( self.activeLobbyId, kLobbyMemberModelDataSyncField, serialized )
end

function ThunderdomeManager:SetLocalLifeformsChoices( choices )
    assert(self.activeLobbyId)
    local model = self.activeLobby:GetMemberModel( self:GetLocalSteam64Id() )
    model:SetField( LobbyMemberModelFields.Lifeforms, choices )
    local serialized = model:Serialize()
    Client.SetLobbyMemberData( self.activeLobbyId, kLobbyMemberModelDataSyncField, serialized )
end


function ThunderdomeManager:HandleOwnerSwapping( lobbyId )
    SLog("ThunderdomeManager:HandleOwnerSwapping( %s )", lobbyId)
    assert(self.swapOwnersActive)
    assert(lobbyId, "Error: No lobby-id passed")

    local lobby = nil
    local isGroup = false
    if self:GetIsGroupId( lobbyId ) then
        lobby = self.groupLobby
        isGroup = true
    else
        lobby = self.activeLobby
    end

    local ownerId = self:GetLocalSteam64Id()
    local prevOwners = lobby:GetField( LobbyModelFields.PrevOwners )
    local nextOwnerId = nil
    local listExhausted = false
    local mList = lobby:GetMembersIdList()
    
    assert(prevOwners and #prevOwners > 0)  --This should only trigger once meta-data propagates

    --Determine next owner-id to set
    for i = 1, #mList do
        if not table.icontains( prevOwners, mList[i] ) then
            nextOwnerId = mList[i]
            break
        end
    end

    --member list exhausted, this lobby is screwed likely due to a system outage
    listExhausted = nextOwnerId == nil

    if nextOwnerId ~= nil and listExhausted == false then
        Client.SetLobbyOwnerId( lobbyId, nextOwnerId )
    end

    if listExhausted then
    --Need to trigger full-failure. Lobby is now in unrecoverable state

        --Set lobby into Failed state to signal to all members this isn't going to result in a game
        if isGroup then
            self.groupLobby:SetState( kLobbyState.Failed )
        else
            self.activeLobby:SetState( kLobbyState.Failed )
        end
        self:TriggerLobbyMetaDataUpload( lobbyId )

        self:ResetAuthentication()
        self.lobbyServerFailed = true    --hack to prevent system from updating

        self:TriggerEvent( kThunderdomeEvents.OnGUIOwnerChangeFailed )

    end

    --Always set to false here, in order for TDMgr update-mode to change (see :Update())
    self.swapOwnersActive = false

end

--Util function to for cycling through members to change Lobby Owner, only
--utilized when current owner & local-client fail to complete task(s).
--This is a separate task in order to ensure lobby meta-data has time to propagate
function ThunderdomeManager:TriggerOwnerChange( lobbyId )
    
    local lobby = nil
    local isGroup = false
    if self:GetIsGroupId( lobbyId ) then
        lobby = self.groupLobby
        isGroup = true
    else
        lobby = self.activeLobby
    end

    if self.swapOwnersActive then
    --ignore while in-process of attempting to switch owners
        return
    end

    local ownerId = self:GetLocalSteam64Id()
    local prevOwners = lobby:GetField( LobbyModelFields.PrevOwners )
    
    if prevOwners ~= nil and prevOwners ~= "" and #prevOwners > 0 then
        if not table.icontains( prevOwners, ownerId ) then
            table.insert( prevOwners, ownerId )
        end
    else
    --first attempt to swap, append current owner to list, and change
        prevOwners = {}
        table.insert( prevOwners, ownerId )
    end

    --Always update field to force meta-data update to all clients
    if isGroup then
        self.groupLobby:SetField( LobbyModelFields.PrevOwners, prevOwners )
    else
        self.activeLobby:SetField( LobbyModelFields.PrevOwners, prevOwners )
    end
    self:TriggerLobbyMetaDataUpload( lobbyId )
    --Client.SetLobbyDataField( self.activeLobbyId, GetLobbyFieldName( LobbyModelFields.PrevOwners ), table.concat( prevOwners, "," ) )

    self.swapOwnersActive = true

end

--Re-run events to get the GUI in sync with cached(loaded) lobby data
function ThunderdomeManager:TriggerCachedLobbyLoadedGUIEvents()
    SLog("ThunderdomeManager:TriggerCachedLobbyLoadedGUIEvents()")
    assert(self.activeLobbyId)
    assert(self.activeLobby)

    local state = self.activeLobby:GetState()

    --Always trigger join GUI event so it defaults to good baseline state
    self:TriggerEvent( kThunderdomeEvents.OnGUILobbyJoined )

    --Note: WaitingForPlayers is skipped, as that's the default state on init
    if state == kLobbyState.WaitingForCommanders then
        self.clientModeObject.mapVotingLocked = false
        self:TriggerEvent( kThunderdomeEvents.OnGUICommandersWaitStart )

    elseif state == kLobbyState.WaitingForExtraCommanders then
        self.clientModeObject.mapVotingLocked = false
        self:TriggerEvent( kThunderdomeEvents.OnGUICommandersWaitStart )
        self:TriggerEvent( kThunderdomeEvents.OnGUIMinRequiredCommandersSet ) -- Since timestamps for GUI are based on the event receive time, this will be more inaccurate.

    elseif state == kLobbyState.WaitingForMapVote then
        self.clientModeObject.mapVotingLocked = false
        self:TriggerEvent( kThunderdomeEvents.OnGUICommandersWaitEnd )
        self:TriggerEvent( kThunderdomeEvents.OnGUIMapVoteStart )

    elseif state == kLobbyState.WaitingForServer then
        self.clientModeObject.mapVotingLocked = true
        if self.clientModeObject.lobbyCoordsLocked ~= nil then
            self.clientModeObject.lobbyCoordsLocked = true
        end

        local mapStr = self.activeLobby:GetField( LobbyModelFields.VotedMap )
        self:TriggerEvent( kThunderdomeEvents.OnGUIMapVoteComplete, kThunderdomeMaps[mapStr] )
        self:TriggerEvent( kThunderdomeEvents.OnGUIServerWaitStart )

    elseif state == kLobbyState.Ready then
        self.clientModeObject.mapVotingLocked = true
        if self.clientModeObject.lobbyCoordsLocked ~= nil then
            self.clientModeObject.lobbyCoordsLocked = true
        end
        self:TriggerEvent( kThunderdomeEvents.OnGUIServerWaitComplete )
    end
end

--Special case that is only applicable when Lua VM is destroyed (e.g. 'restartmain', post map-load/server-connect)
function ThunderdomeManager:LoadCachedLobbyModelData( lobbyId, data )
    SLog("ThunderdomeManager:LoadCachedLobbyModelData( %s , -- )", lobbyId)
    assert(lobbyId)
    assert(data, "Error: No meta-data passed for Lobby[%s]", lobbyId)
    assert(self.initLobbyDataLoadOnly)
    assert(self.activeLobbyId == lobbyId)
    assert(self.activeLobby)

    local dataIdx = -1
    local buildIdx = -1
    local branchIdx = -1
    local verIdx = -1
    for i = 1, #data do
        if data[i][1] == kLobbyModelSyncField then
            dataIdx = i
        elseif data[i][1] == kLobbyModelFieldBuild then
            buildIdx = i
        elseif data[i][1] == kLobbyModelFieldBranch then
            branchIdx = i
        elseif data[i][1] == kLobbyModelFieldVersion then
            verIdx = i
        end
    end

    self.activeLobby:SetField( LobbyModelFields.Build, data[buildIdx][2] )
    self.activeLobby:SetField( LobbyModelFields.SteamBranch, data[branchIdx][2] )
    self.activeLobby:SetField( LobbyModelFields.Version, data[verIdx][2] )

    assert( self.activeLobby:Deserialize( data[dataIdx][2] ), "Error: Failed to deserialize Lobby meta-data" )

    --Manually set LobbyID in model, as this is special case and normally models are init'd with it
    self.activeLobby.data[LobbyModelFields.Id] = lobbyId

    self:ReloadLobbyMembers( lobbyId )

    --Update lobby-id temp-saved in options file (for re-join after crash-restart)
    self:UpdateCachedLobbyIdState()

    self:TriggerCachedLobbyLoadedGUIEvents()

    SLog("\t initLobbyDataLoadOnly flag to FALSE")
    self.initLobbyDataLoadOnly = false

    if not Shared.GetThunderdomeEnabled() then
    --Allow reloaded/re-joined (i.e. after crash) events to fire while in Main Menu. Do not run through these while 
    --connected to TD instance, as at that point, they're invalid (shouldn't ever happen anyway).
        self:TriggerEvent( kThunderdomeEvents.OnMenuLoadEndEvents )
    end

end

function ThunderdomeManager:GetHasSteamAuthExpired()
    SLog("ThunderdomeManager:GetHasSteamAuthExpired()")

    if self.authTicket == nil or self.timeSteamAuthGenerate == 0 then
        return nil  --indicate "No Auth found"
    end

    local lastAuthTime = Shared.GetSystemTime() - self.timeSteamAuthGenerate
    if lastAuthTime >= self.kMaxSteamAuthTicketLifetime and not self.pendingSteamAuthGenerate then
        return true
    end

    return false
end

--Should only be triggered by Client-Objects when they detect server connection should occur
--Simple helper routine to manage options data, basically.
function ThunderdomeManager:AttemptServerConnect()
    
    if self.lobbyServerFailed or MainMenu_GetIsInGame() then
        SLog("Error: cannot attempt server connect failure, or in-game connect disallowed")
        return
    end
    
    if self:GetHasSteamAuthExpired() then
    --Note: all Lobby update object (regardless of Client-type) will repeatidly call this function when lobby is "ready"
        SLog("!!    ThunderdomeManager:AttemptServerConnect() called after max auth-ticket lifetime, regenerating Steam auth...")
        self:CancelSteamAuthTicket()
        self:GenerateSteamAuthTicket()
        return
    end

    SLog("ThunderdomeManager:AttemptServerConnect()") 

    --Note: if script errors occur outside this, could cause a run-away re-connect loop
    local srvIp = self.activeLobby:GetField( LobbyModelFields.ServerIP )
    local srvPort = self.activeLobby:GetField( LobbyModelFields.ServerPort )
    local srvPass = self.activeLobby:GetField( LobbyModelFields.ServerPassword )
    
    local haveServerInfo = 
        srvIp and srvIp ~= "" and 
        srvPort and srvPort ~= "" and 
        srvPass and srvPass ~= ""

    local numCachedConnAttempts = Client.GetOptionInteger( kOptionKey_CachedLobbyConnAttempts, 0 )

    if haveServerInfo then
    --Log the connection attempt before tring to connect, so the data will exist when
    --client fails back to Main VM on connection failure.
        
        Client.SetOptionBoolean( kOptionKey_CachedLobbyConnMade, true )
        Client.SetOptionInteger( kOptionKey_CachedLobbyConnAttempts, numCachedConnAttempts + 1 )
        Client.Connect( srvIp .. ":" .. srvPort, srvPass, true )
    end

end

-------------------------------------------------------------------------------
-- Lobby Search Functions -------------

function ThunderdomeManager:GetSearchResultsList()
    return self.searchResultsList
end

function ThunderdomeManager:InitSearchMode()
    SLog("ThunderdomeManager:InitSearchMode()")
    assert(self.updateMode == self.kUpdateModes.None)

    if g_thuderdomeVerbose then
        self:DebugDump(true)
    end

    if self.updateMode == self.kUpdateModes.Search or self.searchingActive then
        SLog("ERROR: Client already in LobbySearch mode")
        return false
    end

    if Client.GetIsThunderdomePenalized() then
        self:TriggerEvent( kThunderdomeEvents.OnGUIPenaltyIsActive )
        return false
    end

    if self.steamConnectionLost then
        return false
    end

    if Client.GetIsConnected() or Client.GetIsRunningServer() then
    --Do not perform searching if local-client is running listen host
        self:TriggerEvent( kThunderdomeEvents.OnGUISearchFailed )
        return false
    end

    if self.thunderdomeDisabled then
        self:TriggerEvent( kThunderdomeEvents.OnGUISystemDisabled )
        return false
    end

    if self.activeLobby and self.activeLobbyId then
    --For cases of late state-changes (e.g. user clicks UI fast as shit), need to make sure no active lobby is set
        self:LeaveLobby( self.activeLobbyId )
    else
        --Force afk prompt flag to false, so this can run Update() fully
        self.pendingAkfPromptAction = false
        self.pendingReconnectPrompt = false
    end

    if self.clientModeObject ~= nil then
    --De-register any events associated with active client-object
        self.clientModeObject:Destroy()
        self.clientModeObject = nil
    end

    self.clientModeObject = LobbyClientSearch()
    self.clientModeObject:Initialize()
    self.clientModeObject:BeginLobbySearch()
    self.updateMode = self.kUpdateModes.Search

    self.cancelSearching = false

    return true
end

--Note: not modal, as normal search routine is
function ThunderdomeManager:InitGroupSearch()
    SLog("ThunderdomeManager:InitGroupSearch()")
    assert(self.updateMode == self.kUpdateModes.GroupOwner, "Error: cannot run group search, in wrong mode")
    assert( self.isGroupQueueEnabled, "Error: cannot run group search when group flag not set" )

    if g_thuderdomeVerbose then
        self:DebugDump(true)
    end

    if Client.GetIsConnected() or Client.GetIsRunningServer() then
    --Do not perform searching if local-client is running listen host
        self:TriggerEvent( kThunderdomeEvents.OnGUISearchFailed )
        return false
    end

    if self.searchingActive then
        SLog("ERROR: Cannot init group-search, Client already in LobbySearch mode")
        return false
    end

    if Client.GetIsThunderdomePenalized() then
        self:TriggerEvent( kThunderdomeEvents.OnGUIPenaltyIsActive )
        return false
    end

    if self.steamConnectionLost then
        return false
    end

    if self.clientModeObject == nil then
        return false
    end

    --self.searchResultsList = {}
    self.searchingActive = true

end

function ThunderdomeManager:GetIsSearching()
    if self.updateMode == self.kUpdateModes.GroupOwner then
        return self.clientModeObject:GetIsSearching()
    else
        return self.updateMode == self.kUpdateModes.Search
    end
end

function ThunderdomeManager:AddLobbySearchFilter( field, value, comparitor )
    --SLog("ThunderdomeManager:AddLobbySearchFilter( %s, %s, %s )", field, value, comparitor)
    --assert(not self.searchingActive, "Error: Cannot apply search filters while search already in process")

    local type = type(value)
    assert(type == "string" or type == "number")

    assert( field == kLobbyModelFieldBuild or field == kLobbyModelFieldBranch or field == kLobbyModelFieldVersion, "Error: Invalid search-filter field" )
    
    --TODO Add support for AddRequestLobbyListFilterSlotsAvailable in Engine
    --TODO Add available slots filter option here

    if type == "string" then
        Client.SetLobbySearchStringFilter( field, value, comparitor )
    elseif type == "number" then
        Client.SetLobbySearchIntegerFilter( field, value, comparitor )
    else
        assert(false, "Error: Invalid Lobby Filter value-type")
    end

end

--Trigger Steam to run a search on ALL lobbies. Note: this does not perform any of the detailed
--filtering, that is handled via a child object (see LobbyClientSearch class).
function ThunderdomeManager:RunLobbySearch( listSize )
    assert(self.updateMode == self.kUpdateModes.Search or self.updateMode == self.kUpdateModes.GroupOwner, "Error: Invalid update-mode set for performing search")
    listSize = math.min( listSize, kLobbySearchMaxListSize )    --cap to Steamworks max value

    --Set this as static as Steamworks only _sorts_ results by this, none of retrived lobby-list data is modified
    --Client.SetLobbyDistanceFilter( Client.SteamLobbyDistanceFilter_Close )

    self:AddLobbySearchFilter( kLobbyModelFieldBuild, self.buildNumber, Client.SteamLobbyFilterComparator_Equal )
    self:AddLobbySearchFilter( kLobbyModelFieldBranch, self.steamBranch, Client.SteamLobbyFilterComparator_Equal )
    self:AddLobbySearchFilter( kLobbyModelFieldVersion, Client.GetSteamBuildId(), Client.SteamLobbyFilterComparator_Equal )

    Client.SetLobbyListSizeFilter( listSize )  --Note: the smaller this values is the faster results are returned

    self.searchingDataFetchCount = 0
    self.searchResultsList = {}

    Client.SetLocalThunderdomeMode(true)    --force program to always update, regardless of window-focus state

    self.searchingActive = true

    --Note: Full lobbies are automatically filtered out
    --Note: applied filters are reset when this is called (engine internal)
    Client.RebuildLobbyList()
    
end

--Simple helper function to parse raw lobby-id list into usable object (table of models) structure
function ThunderdomeManager:ParseSearchResults( list )
    assert(list)
    assert(type(list) == "table")

    if not self.searchingActive then
        return
    end

    self.searchResultsList = {}
    
    local resultIdx = 0 --0 indexed for starting, simpler this way
    for i = 1, #list do

        local lobbyId = list[i]
        resultIdx = resultIdx + 1

        if not table.contains( self.kickedLobbies, list[i] ) then
        --Skip over any lobbies local-client was kicked/removed from
            
            local lobby = LobbyModel()  --init-model
            lobby:Init()
            lobby:SetField( LobbyModelFields.Id, lobbyId )

            table.insert( self.searchResultsList, lobby )

            --Force refresh full copy of lobby data (required for details data comparisons).
            --This will trigger self:OnLobbyDataUpdate for each lobby in the list
            Client.ReloadLobbyData( lobbyId )
        end

    end

end

--Fires after calling Client.RebuildLobbyList(), returned table is a simple array of lobby IDs, no lobby data
function ThunderdomeManager:OnLobbySearchResults( results )
    assert(results)

    --Parse list of Lobby IDs into useful data tables (table of tables)
    --Note: this begins a series of Lua -> Engine -> Steam -> Engine -> Lua call-chains for each lobby
    --This is required in order to get a full copy of each lobby's data fields and values
    self:ParseSearchResults( results )
end

function ThunderdomeManager:OnSearchFinalized()
    assert(self.searchingActive)
    --Note: this doesn't pass the parsed list because contextual usage
    --(e.g. the UI doesn't need the list, but should know when search is "done")
    self.searchingActive = false
    self:TriggerEvent( kThunderdomeEvents.OnSearchResults )
end

--Note: 'data' is formatted as table-of-tables (i.e.  { [1] = { [1] = "field_name", [2] = "field_data" } })
function ThunderdomeManager:ProcessSearchResultLobbyData( lobbyId, data )
    assert(lobbyId)

    local hasDataFld = false
    local hasBuildFld = false
    local hasBranchFld = false
    local hasVerFld = false

    local dataIdx = -1
    local buildIdx = -1
    local branchIdx = -1
    local verIdx = -1
    for i = 1, #data do
        if data[i][1] == kLobbyModelSyncField then
            hasDataFld = true
            dataIdx = i
        elseif data[i][1] == kLobbyModelFieldBuild then
            hasBuildFld = true
            buildIdx = i
        elseif data[i][1] == kLobbyModelFieldBranch then
            hasBranchFld = true
            branchIdx = i
        elseif data[i][1] == kLobbyModelFieldVersion then
            hasVerFld = true
            verIdx = i
        end
    end
    
    assert(hasDataFld, "Error: No meta-data field found in searched lobby[%s]", lobbyId)

    local validLob = true

    if data[dataIdx][2] == "" or data[buildIdx][2] == "" or data[branchIdx][2] == "" or data[verIdx][2] == "" then
        validLob = false
    end
    
    local minReqFields = { LobbyModelFields.Type, LobbyModelFields.State, LobbyModelFields.MedianSkill, LobbyModelFields.Coords }
    local tempModel = LobbyModel()
    tempModel:Init()

    --Init fields not primed from data fetch
    tempModel:SetField( LobbyModelFields.Build, data[buildIdx][2] )
    tempModel:SetField( LobbyModelFields.SteamBranch, data[branchIdx][2] )
    tempModel:SetField( LobbyModelFields.Version, data[verIdx][2] )

    if not tempModel:Deserialize( data[dataIdx][2] ) then
        SLog("Warning: Failed to parse search-result lobby[%s] meta-data", lobbyId)
        SLog("  %s", data)
        validLob = false
    end

    --Run through quick tests to ensure we have a valid lobby (for local client)
    for i = 1, #minReqFields do
        local fldId = minReqFields[i]
        local fldVal = tempModel:GetField( fldId )

        --SLog("     fldId: %s", LobbyModelFields[fldId])
        --SLog("    fldVal: %s", fldVal)

        if not fldVal or fldVal == "" then
            SLog("   Invalid Lobby - no field[%s] value", LobbyModelFields[fldId])
            validLob = false
            break

        elseif fldId == LobbyModelFields.State then
            if fldVal > kLobbyState.WaitingForPlayers then
                SLog("   Invalid Lobby - wrong lobby state[%s]", kLobbyState[fldVal])
                validLob = false
                break
            end

        --This ignores frield-only and invis type (not supported). Private 'should' be auto excluded pre-search
        elseif fldId == LobbyModelFields.Type and fldVal ~= Client.SteamLobbyType_Public then
            validLob = false
            break
        end
    end
    
    --client issue or mod bullshit screwed up the lobby data, invalidate it and skip
    if not validLob then
        SLog("  Invalidated %s", lobbyId)
        local validList = {}
        for i = 1, #self.searchResultsList do
            if lobbyId ~= self.searchResultsList[i]:GetId() then
                table.insert( validList, self.searchResultsList[i] )
            end
        end

        self.searchResultsList = validList

        if #self.searchResultsList < 1 then
            self:OnSearchFinalized()
        end
        return --bail immediately
    end

    --Since there is no gauantee that Steam will return requests LobbyID->Data in linear order (async)
    --we must search for the specific model that matched the passed ID.

    local modelIdx
    for i = 1, #self.searchResultsList do
        if self.searchResultsList[i]:GetId() == lobbyId then
            modelIdx = i
            break
        end
    end

    tempModel:SetField( LobbyModelFields.Id, lobbyId )
    tempModel:SetField( LobbyModelFields.NumMembers, Client.GetNumLobbyMembers( lobbyId ) )

    self.searchingDataFetchCount = self.searchingDataFetchCount + 1
    self.searchResultsList[modelIdx] = tempModel

    if self.searchingDataFetchCount == #self.searchResultsList then
    --Parsed all of the search results, can trigger next steps/events now
        self:OnSearchFinalized()
    end

end

function ThunderdomeManager:SignalSearchSuccess( targetLobbyId )
    self.searchingActive = false
    self:JoinLobby( targetLobbyId )
end

function ThunderdomeManager:CancelMatchSearch()
    if self:GetIsSearching() then
        self.cancelSearching = true
        Client.SetLocalThunderdomeMode(false)
    end
end


-------------------------------------------------------------------------------
-- Lobby Helper Functions -----------------------------------------------------

function ThunderdomeManager:CreateLobby( lobbyType, isGroup )

    if self.systemInitFailed then
        Log("Error: Cannot create lobbies when local TD system failed to initialize")
        return
    end

    if Client.GetIsThunderdomePenalized() then
        self:TriggerEvent( kThunderdomeEvents.OnGUIPenaltyIsActive )
        return
    end

    if Client.GetIsConnected() or Client.GetIsRunningServer() then
    --Do not allow creation of lobbies from local listen host
        self:TriggerEvent( kThunderdomeEvents.OnGUILobbyCreateFailed )
        return
    end

    assert(not self.activeLobbyId)
    if isGroup then
        assert(not self.groupLobbyId)
    end
    
    assert(lobbyType, "Error: No lobby type passed")
    assert(lobbyType == Client.SteamLobbyType_Public or lobbyType == Client.SteamLobbyType_Private, "Error: Invalid lobby type passed, only public/private allowed")
    
    local numSlots = ( isGroup == nil or isGroup == false ) and kLobbyPlayersLimit or kFriendsGroupMaxSlots

    SLog("   CreateLobby [ Type: %s  -  Slots: %s ]", lobbyType, numSlots)
    self.lastLobbyCreateType = lobbyType

    if isGroup ~= nil and isGroup then
    --flip switch to act as Group Queue mode, for behavior/data handling differences
        SLog("\t ENABLED GROUP-QUEUE")
        self.isGroupQueueEnabled = true
    end

    self.isCreatingLobby = true

    Client.CreateLobby( lobbyType, numSlots )

    --force to always update, regardless of window-focus state
    Client.SetLocalThunderdomeMode(true)
end

function ThunderdomeManager:JoinLobby( lobbyId, isLaunchId, isGroup )
    SLog("ThunderdomeManager:JoinLobby( %s, %s, %s )", lobbyId, isLaunchId, isGroup)
    assert(lobbyId, "Error: Passed lobbyId invalid, cannot join")
    
    if self.systemInitFailed then
        Log("Error: Cannot join lobbies when local TD system failed to initialize")
        return
    end

    if Client.GetIsThunderdomePenalized() then
        self:TriggerEvent( kThunderdomeEvents.OnGUIPenaltyIsActive )
        return
    end

    if Client.GetIsConnected() or Client.GetIsRunningServer() then
        self:TriggerEvent( kThunderdomeEvents.OnGUILobbyJoinFailed )
        return
    end

    --This needs to be trapped in group-check, because we're still using Group model & update object during waiting-period to join "Actual" lobby
    --so, this god aweful jank has to be done and the reset "normal" setup is in OnLobbyLocalClientEnter
    if self.clientModeObject ~= nil then
        self.clientModeObject:Destroy()
        self.clientModeObject = nil
    end

    if isGroup == true then
        SLog("   Setup Group-type lobby[ MEMBER ]")
        SLog("\t ENABLED GROUP-QUEUE")
        self.isGroupQueueEnabled = true
        self.clientModeObject = GroupClientMember()
        self.updateMode = self.kUpdateModes.GroupMember

        self.groupLobbyId = lobbyId
        self.groupLobby = LobbyModel()
        self.groupLobby:Init()
    else
        SLog("   Setup Match-type lobby [ MEMBER ]")
        self.clientModeObject = LobbyClientMember()
        self.updateMode = self.kUpdateModes.LobbyMember

        --init data model so it can accept data updates / first-load
        self.activeLobbyId = lobbyId
        self.activeLobby = LobbyModel()
        self.activeLobby:Init()
    end

    self.clientModeObject:Initialize()

    self.recentlyJoinedCachedInvite = lobbyId == self.cachedLobbyInviteId
    self.cachedLobbyInviteId = nil

    --force to always update, regardless of window-focus state
    Client.SetLocalThunderdomeMode(true)

    Client.JoinLobby( lobbyId )
end

-- Handle re-initializing client state for a lobby we're already part of.
-- Note: this function should not be called if ThunderdomeManager is already in a lobby/group state
function ThunderdomeManager:RejoinLobby( lobbyId, isGroup )
    SLog("ThunderdomeManager:RejoinLobby( %s, %s )", lobbyId, isGroup)
    assert(lobbyId, "Error: Passed lobbyId invalid, cannot join")

    SLog("\t initLobbyDataLoadOnly flag to TRUE")
    self.initLobbyDataLoadOnly = true

    --Note: this will only return accuratly when already a member of cacheId lobby
    local ownerId = Client.GetLobbyOwnerId( lobbyId )

    local clientSteamId = self:GetLocalSteam64Id()

    --init data model so it can accept data updates / first-load
    if isGroup then

        self.isGroupQueueEnabled = true

        self.groupLobbyId = lobbyId
        self.groupLobby = LobbyModel()
        self.groupLobby:Init()

        if ownerId == clientSteamId then
            SLog("\t Set as GroupOwner")
            self.clientModeObject = GroupClientOwner()
            self.updateMode = self.kUpdateModes.GroupOwner
        else
            SLog("\t Set as GroupMember")
            self.clientModeObject = GroupClientMember()
            self.updateMode = self.kUpdateModes.GroupMember
        end

    else

        self.activeLobbyId = lobbyId
        self.activeLobby = LobbyModel()
        self.activeLobby:Init()

        if ownerId == clientSteamId then
            SLog("\t Set as LobbyOwner")
            self.clientModeObject = LobbyClientOwner()
            self.updateMode = self.kUpdateModes.LobbyOwner
        else
            SLog("\t Set as LobbyMember")
            self.clientModeObject = LobbyClientMember()
            self.updateMode = self.kUpdateModes.LobbyMember
        end

    end

    self.clientModeObject:Initialize()

    SLog("  Trigger lobby-data reload...")

    --force to always update, regardless of window-focus state
    Client.SetLocalThunderdomeMode(true)

    Client.ReloadLobbyData( lobbyId )
end

function ThunderdomeManager:LeaveLobby( lobbyId, clientChoice )
    SLog("ThunderdomeManager:LeaveLobby( %s, %s )", lobbyId, clientChoice)
    assert(lobbyId, "Error: Invalid LobbyID supplied")
    --assert(self.activeLobbyId == lobbyId, "Error: active lobby-id mismatch from supplied id")

    local isGroup = self:GetIsGroupId( lobbyId )

    if g_thunderdomeVerbose then
        SLog("")
        self:DebugDump(true)
        SLog("")
    end

    if clientChoice == nil then
        clientChoice = false
    end

    local activeLobby = false
    if not isGroup and self.activeLobby then
        local lobState = self.activeLobby:GetState()
        SLog("\t lobState:  %s", kLobbyState[lobState])

        activeLobby = 
            ( lobState >= kLobbyState.WaitingForCommanders and lobState < kLobbyState.Finalized ) and 
            ( 
                not self.lobbyServerConnFailed and 
                not self.lobbyServerFailed and 
                not self.localHiveProfileFetchFailed and
                not self.steamConnectionLost and 
                not self.systemInitFailed
            )
    end

    self.joinedLobbyTime = 0    --clear
    
    if isGroup then
    --moving from GroupLobby to MatchLobby
        self.groupLobby = nil
        self.groupLobbyId = nil
        activeLobby = false --??
        self.isGroupQueueEnabled = false
    end

    local activeMatch = false
    if Shared.GetThunderdomeEnabled() then
        activeMatch = 
            not GetThunderdomeRules():GetIsMatchCompleted() and
            not GetThunderdomeRules():GetIsMatchForceConceded()
    end
    
    local lobType = self.activeLobby:GetField( LobbyModelFields.Type )
    local isPrivate = GetLobbyTypeValue(lobType) == Client.SteamLobbyType_Private

    SLog("\t\t  activeLobby:  %s", activeLobby)
    SLog("\t\t  activeMatch:  %s", activeMatch)
    SLog("\t\t    isPrivate:  %s", isPrivate)
    SLog("\t\t\t    lobbyType:  %s", lobType)

    if clientChoice == true and not isPrivate and activeLobby and not activeMatch then
    --safety check to ensure leaving an active match always penalizes, this is only applicable to AKF-Kick & Reconnect prompt states
        activeMatch = true
    end
    
    local ignoreLeavePrompt = clientChoice and ( self.pendingReconnectPrompt or self.pendingAkfPromptAction )

    if (isPrivate and self.pendingAkfPromptAction) or (clientChoice and self.pendingAkfPromptAction) then
    --ignore client choice/prompts penalties for Private lobbies/matches
        self.pendingAkfPromptAction = false
    end
    
    if (isPrivate and self.pendingReconnectPrompt) or (clientChoice and self.pendingReconnectPrompt) then
    --ignore client choice/prompts penalties for Private lobbies/matches
        self.pendingReconnectPrompt = false
    end

    Client.ThunderdomeDisconnectEvent(lobbyId, activeLobby, activeMatch, isPrivate, clientChoice)

    Client.LeaveLobby(lobbyId)

    if not isGroup then
        self.lobbyServerConnFailed = false
        self.lobbyServerFailed = false

        self.activeLobbyId = nil
        self.activeLobby = nil
        self.cachedLobbyInviteId = nil

        self:ClearLocalGroupId()

        if self.clientModeObject ~= nil then
            self.clientModeObject:Destroy()
            self.clientModeObject = nil
        end

        self.updateMode = self.kUpdateModes.None

        --Clear any cached LobbyID and Conn-Attempt count from options file
        Client.SetOptionString(kOptionKey_CachedLobbyId, "")
        Client.SetOptionInteger(kOptionKey_CachedLobbyConnAttempts, 0)
        Client.SetOptionBoolean(kOptionKey_CachedLobbyConnMade, false)
        SLog("!!!! Cleared all cached lobby-data !!!")

        Client.ClearLaunchLobbyId()

        self:ResetAuthentication()

        self:TriggerEvent( kThunderdomeEvents.OnLeaveLobby, ignoreLeavePrompt )

        Client.SetLocalThunderdomeMode(false)
    end

end

function ThunderdomeManager:LeaveGroup( groupId, toMatch )
    SLog("ThunderdomeManager:LeaveGroup( %s )", groupId)
    SLog("  activeLobby: %s", self.activeLobby)
    SLog("  updateMode: %s", self.updateMode)

    assert(self.groupLobbyId == groupId)

    -- STURNCLAW: we're not in an active lobby if we're group client members
    -- joining a MATCH lobby, or if we're group owner/members leaving the group
    -- back to the main menu.
    -- Explicitly specify the case in which we're joining a MATCH lobby vs. leaving the group
    if toMatch then
        self:DebugDump(true)

        self.groupLobby = nil
        self.groupLobbyId = nil
    else
        self:ResetMode()
    end

    self.isGroupQueueEnabled = false

    Client.LeaveLobby(groupId)
end

--utility for whenever Create or Join fails, to push local-client back to awaiting-action/mode state
function ThunderdomeManager:ResetMode()
    SLog("ThunderdomeManager:ResetMode()")

    if self.clientModeObject ~= nil then
        self.clientModeObject:Destroy()
        self.clientModeObject = nil
    end

    self.updateMode = self.kUpdateModes.None

    self.activeLobbyId = nil
    self.activeLobby = nil

    self.searchingActive = false

    self.pendingAkfPromptAction = false
    self.pendingReconnectPrompt = false

    self.lastLobbyCreateType = -1

    self.groupLobby = nil
    self.groupLobbyId = nil
    self.isGroupQueueEnabled = false
    self:ClearLocalGroupId()
    
    --Forcibly reset any cached values, as we're "full-error/fail" when this is called
    --Clear any cached LobbyID and Conn-Attempt count from options file
    Client.SetOptionString(kOptionKey_CachedLobbyId, "")
    Client.SetOptionInteger(kOptionKey_CachedLobbyConnAttempts, 0)
    Client.SetOptionBoolean(kOptionKey_CachedLobbyConnMade, false)
    SLog("!!!! Cleared all cached lobby-data !!!")

    Client.SetLocalThunderdomeMode(false)

end

function ThunderdomeManager:SendChatMessage( message, lobbyId )
    assert(message, "Error: Invalid lobby chat message")
    assert(lobbyId, "Error: No valid LobbyID passed")
    assert(lobbyId == self.activeLobbyId or lobbyId == self.groupLobbyId, "Error: Invalid LobbyID[%s], does not match active or group", lobbyId)

    SLog("ThunderdomeManager:SendChatMessage( %s, %s )", message, lobbyId)

    local time = Shared.GetSystemTime()
    if self.lastChatSendTime + self.kMaxChatSendRate < time then
        Client.SendLobbyChatMessage( lobbyId, string.UTF8SanitizeForNS2(message) )
        self.lastChatSendTime = time
    end
end

function ThunderdomeManager:GetActiveLobby()
    return self.activeLobby
end

function ThunderdomeManager:GetActiveLobbyId()
    return self.activeLobbyId
end

function ThunderdomeManager:GetGroupLobby()
    return self.groupLobby
end

function ThunderdomeManager:GetGroupLobbyId()
    return self.groupLobbyId
end

function ThunderdomeManager:GetIsGroupId(lobbyId)
    return lobbyId ~= nil and lobbyId == self.groupLobbyId
end

-------------------------------------------------------------------------------
-- Lobby Data Management ------------------------------------------------------

-- Handle triggering callbacks for successful foreign lobby data updates
function ThunderdomeManager.OnForeignLobbyDataUpdate( clientModeObject, lobbyId, lobbyData, isMemberData, memberId )
    SLog("ThunderdomeManager.OnForeignLobbyDataUpdate( %s, %s, %s, %s )", lobbyId, lobbyData, isMemberData, memberId)

    -- We don't particularly care about member metadata for lobbies we are not part of.
    if isMemberData then
        return
    end

    local td = Thunderdome()

    local pendingRequest = td.pendingForeignLobbyRequests[lobbyId]

    if not pendingRequest then
        return
    end

    local hasDataFld = false
    for i = 1, #lobbyData do
        if lobbyData[i][1] == kLobbyModelSyncField then
            hasDataFld = true
        end
    end

    if not hasDataFld then
        SLog("-- Foreign lobby data update for lobby [%s] has no LobbyModelSyncField, skipping update.", lobbyId)
        return
    end

    SLog("-- OnForeignLobbyDataUpdate for lobby [%s] succeeded!", lobbyId)

    -- At this point, we assume the lobby has a valid data model available via Steamworks API
    -- and can be queried with Client.GetLobbyDataField. Trigger success and cleanup this function.

    if pendingRequest.onSuccess then
        pendingRequest.onSuccess( lobbyId )
    end

    -- Clear the pending request

    td.pendingForeignLobbyRequests[lobbyId] = nil

end

-- Handle triggering callbacks for unsuccessful foreign lobby data updates
function ThunderdomeManager.OnForeignLobbyDataTimeout( clientModeObject, lobbyId )
    SLog("ThunderdomeManager.OnForeignLobbyDataTimeout( %s )", lobbyId)

    local td = Thunderdome()

    local pendingRequest = td.pendingForeignLobbyRequests[lobbyId]

    if not pendingRequest then
        return
    end

    SLog("-- OnForeignLobbyDataTimeout for lobby [%s]", lobbyId)

    if pendingRequest.onTimeout then
        pendingRequest.onTimeout( lobbyId )
    end

    -- Clear the pending request

    td.pendingForeignLobbyRequests[lobbyId] = nil

end

-- Load data about a "foreign lobby" (not an active match or group queue SteamLobby)
-- and trigger a user-supplied callback on success or data timeout.
-- Used as a building block to handle deferred processing of lobby data for invites etc.
-- If more than one request is triggered for a given lobby ID before the first request has completed,
-- all but the last request are dropped.
---@param lobbyId string SteamID of the lobby to load data about.
---@param onSuccess function|nil callback triggered when lobby data has been successfully received from Steam.
---@param onTimeout function|nil callback triggered when no lobby data has been received (e.g. lobby doesn't exist / steam offline)
function ThunderdomeManager:LoadForeignLobbyData( lobbyId, onSuccess, onTimeout )
    SLog("ThunderdomeManager:LoadForeignLobbyData( %s )", lobbyId)

    if self.pendingForeignLobbyRequests[lobbyId] then
        SLog("-- Warning: foreign lobby data request is already pending for lobby [%s]!", lobbyId)
    end

    SLog("-- Adding pending request for foreign lobby data (lobby: %s, success: %s, timeout: %s)", lobbyId, onSuccess, onTimeout)
    
    self.pendingForeignLobbyRequests[lobbyId] = {
        lobbyId = lobbyId,
        onSuccess = onSuccess,
        onTimeout = onTimeout
    }

    -- If we don't receive any lobby data about the lobby we're trying to join
    -- after a certain period, assume it's defunct/destroyed
    self:TriggerDelayedEvent( kThunderdomeEvents.OnForeignLobbyDataTimeout, kForeignLobbyTimeoutLimit, lobbyId )

    Client.ReloadLobbyData( lobbyId )

end

--Helper function to wrap updating / adding lobby members to current Active Lobby model
--Note: this function requires that the local-client be a member of the queried lobby
function ThunderdomeManager:LoadLobbyMemberData( lobbyId, memberId )
    assert(lobbyId, "Error: invalid or not LobbyID passed")
    assert(memberId, "Error: invalid or no memberId passed")

    local isGroupLobby = self:GetIsGroupId( lobbyId )
    local memData = Client.GetLobbyMemberData( lobbyId, memberId, kLobbyMemberModelDataSyncField )

    local model = nil
    if isGroupLobby then
        model = self.groupLobby:GetMemberModel( memberId )
    else
        model = self.activeLobby:GetMemberModel( memberId )
    end

    if model then
    --Update existing member object (such as local-client)
        SLog("\t Have model for member[%s], updating and overwrite existing...", memberId)
        model:Deserialize( memData )
        model:SetField( LobbyMemberModelFields.SteamID64, memberId )

        if isGroupLobby then
            if not self.groupLobby:OverwriteMemberModel( model ) then
                Log("Error: failed to overwrite GroupLobby member-model for Id[%s]", memberId)
            end
        else
            if not self.activeLobby:OverwriteMemberModel( model ) then
                Log("Error: failed to overwrite ActiveLobby member-model for Id[%s]", memberId)
            end
        end

    else
    --New lobby member
        SLog("\t No model for member[%s], adding new...", memberId)
        model = LobbyMemberModel()
        model:Init( (memData ~= nil and memData ~= "") and memData or nil )
        model:SetField( LobbyMemberModelFields.SteamID64, memberId )
        --Note: sometimes a member join (Ex: LobbyDataUpdate steam-event) will trigger without that actual client 
        --have had time to apply/set its member-data, thus from LOCAL client's perspective, said data is an empty string
        --Always create a model in this scenario, and set the SteamID (known), on future update will find and Overwrite
        if isGroupLobby then
            self.groupLobby:AddMemberModel( model )
        else
            self.activeLobby:AddMemberModel( model )
        end
    end

end

function ThunderdomeManager:RemoveMember( lobbyId, memberId )
    assert(lobbyId)
    assert(memberId)
    if self:GetIsGroupId( lobbyId ) then    
        if not self.groupLobby:RemoveMemberModel(memberId) then
            SLog("Warning: [Group] LobbyModel:RemoveMemberModel - failed to remove member-model, usrdata may not have been cached")
        end
    else
        if not self.activeLobby:RemoveMemberModel(memberId) then
            SLog("Warning: [Active] LobbyModel:RemoveMemberModel - failed to remove member-model, usrdata may not have been cached")
        end
    end
end

function ThunderdomeManager:ReloadLobbyMembers( lobbyId )
    SLog("ThunderdomeManager:ReloadLobbyMembers( %s )", lobbyId)
    assert(lobbyId)

    local lobMemberIds = {}
    Client.GetLobbyMembersList( lobbyId, lobMemberIds )

    for i = 1, #lobMemberIds do
        self:LoadLobbyMemberData( lobbyId, lobMemberIds[i] )
    end
end

function ThunderdomeManager:SetupNewGroup( groupId )
    assert(groupId, "Error: GroupID required to setup new group-lobby")

    SLog("ThunderdomeManager:SetupNewGroup( %s )", groupId )

    self.groupLobby = LobbyModel()
    self.groupLobbyId = groupId
    self.groupLobby:Init()

    local build = tostring(self.buildNumber)
    local steamBranch = tostring(self.steamBranch)
    local version = tostring(Client.GetSteamBuildId())
    --Set first to allow LobbyModel to return in applicable format
    local localCoords = self.playerGeoData[1] .. "," .. self.playerGeoData[2]

    self.groupLobby:SetField( LobbyModelFields.Id, groupId )
    self.groupLobby:SetField( LobbyModelFields.Type, Client.SteamLobbyType_Private )
    self.groupLobby:SetField( LobbyModelFields.Build, build )
    self.groupLobby:SetField( LobbyModelFields.SteamBranch, steamBranch )
    self.groupLobby:SetField( LobbyModelFields.Version, version )
    self.groupLobby:SetField( LobbyModelFields.MedianSkill, self.avgSkill )
    self.groupLobby:SetField( LobbyModelFields.Coords, localCoords )
    self.groupLobby:SetIsGroup( true )
    self.groupLobby:SetState( kLobbyState.GroupWaiting )

    --Handle one-time fields. Once set, these never change
    Client.SetLobbyDataField( groupId, kLobbyModelFieldBuild, build )
    Client.SetLobbyDataField( groupId, kLobbyModelFieldBranch, steamBranch )
    Client.SetLobbyDataField( groupId, kLobbyModelFieldVersion, version )

    --Trigger data serialization and propagate
    self:TriggerLobbyMetaDataUpload( groupId )

    
    --Setup model for local-client (Lobby Owning client), required because lobby creating client doesn't get "normal" event callbacks
    local localMember = LobbyMemberModel()
    local data = 
    {
        name = self.playerName,
        steamid = self:GetLocalSteam64Id(),
        avg_skill = self.avgSkill,
        adagrad = self.adagradGradient,
        marine_skill = self.avgSkill + self.skillOffset,            --TD-FIXME Need to utilize TD skill fields, if present
        alien_skill = self.avgSkill - self.skillOffset,             --TD-FIXME Need to utilize TD skill fields, if present
        marine_comm_skill = self.commSkill + self.commOffset,       --TD-FIXME Need to utilize TD skill fields, if present
        alien_comm_skill = self.commSkill - self.commOffset,        --TD-FIXME Need to utilize TD skill fields, if present
        coords = localCoords,
        map_votes = "",
        commander_able = 0,
        team = 0,
        lifeforms = "",
        join_time = 0,
        group_id = groupId,
    }
    
    localMember:Init( json.encode( data, { indent = false } ) )
    self.groupLobby:AddMemberModel(localMember)
    Client.SetLobbyMemberData( groupId, kLobbyMemberModelDataSyncField, localMember:Serialize() )

    self:TriggerEvent( kThunderdomeEvents.OnLobbyJoined, -1, groupId )   --owner-client meta-data push/trigger

end

--Destroys any existing Lobby data (caution!). Sets the init-lobby data fields (one-time)
function ThunderdomeManager:SetupNewLobby( lobbyId, lobbyType )
    --SLog("ThunderdomeManager:SetupNewLobby( %s, %s )", lobbyId, lobbyType)
    assert(lobbyId)

    SLog("ThunderdomeManager:SetupNewLobby( %s, %s )", lobbyId, lobbyType)

    self.activeLobbyId = lobbyId    --simple reference
    self.activeLobby = LobbyModel() --data object
    self.activeLobby:Init()

    local build = tostring(self.buildNumber)
    local steamBranch = tostring(self.steamBranch)
    local version = tostring(Client.GetSteamBuildId())
    --Set first to allow LobbyModel to return in applicable format
    local localCoords = self.playerGeoData[1] .. "," .. self.playerGeoData[2]

    self.activeLobby:SetField( LobbyModelFields.Id, lobbyId )
    self.activeLobby:SetField( LobbyModelFields.Type, lobbyType )
    self.activeLobby:SetField( LobbyModelFields.Build, build )
    self.activeLobby:SetField( LobbyModelFields.SteamBranch, steamBranch )
    self.activeLobby:SetField( LobbyModelFields.Version, version )
    self.activeLobby:SetField( LobbyModelFields.MedianSkill, self.avgSkill )
    self.activeLobby:SetField( LobbyModelFields.Coords, localCoords )
    self.activeLobby:SetIsGroup( false )
    self.activeLobby:SetState( kLobbyState.WaitingForPlayers )  --fresh state, force set for timestamp

    --Handle one-time fields. Once set, these never change
    Client.SetLobbyDataField( lobbyId, kLobbyModelFieldBuild, build )
    Client.SetLobbyDataField( lobbyId, kLobbyModelFieldBranch, steamBranch )
    Client.SetLobbyDataField( lobbyId, kLobbyModelFieldVersion, version )

    --Trigger data serialization and propagate
    self:TriggerLobbyMetaDataUpload( lobbyId )

    --Setup model for local-client (Lobby Owning client)
    local localMember = LobbyMemberModel()
    local data = 
    {
        name = self.playerName,
        steamid = self:GetLocalSteam64Id(),
        avg_skill = self.avgSkill,
        adagrad = self.adagradGradient,
        marine_skill = self.avgSkill + self.skillOffset,            --TD-FIXME Need to utilize TD skill fields, if present
        alien_skill = self.avgSkill - self.skillOffset,             --TD-FIXME Need to utilize TD skill fields, if present
        marine_comm_skill = self.commSkill + self.commOffset,       --TD-FIXME Need to utilize TD skill fields, if present
        alien_comm_skill = self.commSkill - self.commOffset,        --TD-FIXME Need to utilize TD skill fields, if present
        coords = localCoords,
        map_votes = "",
        commander_able = 0,
        team = 0,
        lifeforms = "",
        join_time = 0,
        group_id = self:GetLocalGroupId(),
    }
    
    localMember:Init( json.encode( data, { indent = false } ) )
    self.activeLobby:AddMemberModel(localMember)

    Client.SetLobbyMemberData( lobbyId, kLobbyMemberModelDataSyncField, localMember:Serialize() )
    
    self:UpdateCachedLobbyIdState()

    self:ResetAuthentication()

    self:TriggerEvent( kThunderdomeEvents.OnLobbyJoined, nil, lobbyId )   --owner-client meta-data push/trigger
end

--This should only ever be called when a client joins a lobby, not when creating one.
--Triggering this will attempt to build a complete data-model (locally) of all joined
--lobby data, including the member data. This should only be called when joining an
--existing lobby and never when creating or updating one.
function ThunderdomeManager:InitializeJoinedLobby( lobbyId )
    SLog("ThunderdomeManager:InitializeJoinedLobby( %s )", lobbyId)
    assert(lobbyId)

    --Initialize all data fields for LobbyModel and populate them 
    local lobbyData = Client.GetLobbyDataField( lobbyId, kLobbyModelSyncField )
    local lobbyBuild = Client.GetLobbyDataField( lobbyId, kLobbyModelFieldBuild )
    local lobbyBranch = Client.GetLobbyDataField( lobbyId, kLobbyModelFieldBranch )
    local lobbyVersion = Client.GetLobbyDataField( lobbyId, kLobbyModelFieldVersion )

    assert(lobbyData, "Error: lobby meta-data not found")

    if self:GetIsGroupId(lobbyId) then
        SLog("===| Initialize GROUP lobby-type...")
        assert( self.groupLobby:Deserialize( lobbyData ), "Error: failed to deserialize group-lobby meta-data" )

        --Handle one-time fields (these are effectively static)
        self.groupLobby:SetField( LobbyModelFields.Build, lobbyBuild )
        self.groupLobby:SetField( LobbyModelFields.SteamBranch, lobbyBranch )
        self.groupLobby:SetField( LobbyModelFields.Version, lobbyVersion )
    else
        SLog("===| Initialize MATCH lobby-type...")
        assert( self.activeLobby:Deserialize( lobbyData ), "Error: failed to deserialize lobby meta-data" )

        --Handle one-time fields (these are effectively static)
        self.activeLobby:SetField( LobbyModelFields.Build, lobbyBuild )
        self.activeLobby:SetField( LobbyModelFields.SteamBranch, lobbyBranch )
        self.activeLobby:SetField( LobbyModelFields.Version, lobbyVersion )
    end
    
    --Update and init models for all Lobby members
    local memberIds = {}
    Client.GetLobbyMembersList( lobbyId, memberIds )
    SLog("\t memberIds: %s", memberIds)
    local localClientId = self:GetLocalSteam64Id()

    for i = 1, #memberIds do
        --skip local client, as its not yet set it's own data
        if memberIds[i] ~= localClientId then 
            local memData = Client.GetLobbyMemberData( lobbyId, memberIds[i], kLobbyMemberModelDataSyncField )
            SLog("\t\t memData: %s", memData)
            local member = LobbyMemberModel()
            member:Init( ( memData ~= nil and memData ~= "" ) and memData or nil )  --account for Member data not yet set by remote-client
            member:SetField( LobbyMemberModelFields.SteamID64, memberIds[i] )   --always set SteamID64

            if self:GetIsGroupId(lobbyId) then
                self.groupLobby:AddMemberModel( member )
            else
                self.activeLobby:AddMemberModel( member )
            end
        end
    end

    self.joinedLobbyTime = Shared.GetSystemTime()

    --Update lobby-id temp-saved in options file (for re-join after crash-restart)
    self:UpdateCachedLobbyIdState()

    self:ResetAuthentication()

end

function ThunderdomeManager:GetCurrentGeoCoords(forLocalClient)
    if forLocalClient then
        return self:GetLocalPlayerGeoData()
    else
        assert(self.activeLobby)
        return self.activeLobby:GetField( LobbyModelFields.Coords )
    end

end

--This is for system-internal use only, and should not be called by GUI-context
function ThunderdomeManager:GetLocalClientMemberModel( lobbyId )
    --SLog("ThunderdomeManager:GetLocalClientMemberModel( %s )", lobbyId)
    local model = nil
    if self:GetIsGroupQueueEnabled() then
        model = self.groupLobby:GetMemberModel( self:GetLocalSteam64Id() )
    else
        model = self.activeLobby:GetMemberModel( self:GetLocalSteam64Id() )
    end

    if not model then

        model = LobbyMemberModel()
        
        local data = 
        {
            name = self.playerName,
            steamid = self:GetLocalSteam64Id(),
            avg_skill = self.avgSkill,
            adagrad = self.adagradGradient,
            marine_skill = self.avgSkill + self.skillOffset,
            alien_skill = self.avgSkill - self.skillOffset,
            marine_comm_skill = self.commSkill + self.commOffset,
            alien_comm_skill = self.commSkill - self.commOffset,
            coords = self.playerGeoData[1] .. "," .. self.playerGeoData[2],
            map_votes = "",
            lifeforms = "",
            commander_able = 0,
            team = 0,
            join_time = 0,
            group_id = self:GetLocalGroupId(),
        }

        model:Init(json.encode( data, { indent = false } ))   --cheesy, but simple
    end

    return model
end


-------------------------------------------------------------------------------
-- Event Hook Handlers & Steam Event Hooks ------------------------------------

function ThunderdomeManager:LoadCompletePromptsClear()
    SLog("ThunderdomeManager:LoadCompletePromptsClear()")
    self.pendingAkfPromptAction = false
    self.pendingReconnectPrompt = false
end

function ThunderdomeManager:SetActiveAFKPrompt(active)
    assert(active == true or active == false, "Error: Invalid pending AFK prompt flag")
    self.pendingAkfPromptAction = active
end

function ThunderdomeManager:SetActiveReconnectPrompt(active)
    assert(active == true or active == false, "Error: Invalid pending reconnect flag")
    self.pendingReconnectPrompt = active
end

local kAfkKickedMessage = "AFK Kicked"  --TD-TODO need means to fetch automatically (const/binding)
local kKickedMessage = "Kicked"
local kTimeoutMessage = "Timeout"
function ThunderdomeManager:OnLoadCompleteMessage(message)

    SLog("ThunderdomeManager:OnLoadCompleteMessage( %s )", message)

    local lobby
    if self:GetIsGroupQueueEnabled() then
        lobby = self.groupLobby
    else
        lobby = self.activeLobby
    end

    if not lobby then
        SLog("\t No Lobby active, ret-false, skip to 'normal' message handling...")
        self:LoadCompletePromptsClear()
        return false
    end

    --Verify we WERE recently in TD state, etc.
    local lastConnAttempted = Client.GetOptionBoolean(kOptionKey_CachedLobbyConnMade, false)
    local lastNumConn = Client.GetOptionInteger(kOptionKey_CachedLobbyConnAttempts, 0)

    SLog("\t lastConnAttempted:     %s", lastConnAttempted)
    SLog("\t       lastNumConn:     %s", lastNumConn)
    
    if lastConnAttempted then
    --AFK or Reconnect is only applicable _after_ connecting to TD instance
        SLog("  Prev TD-conn attempted...")

        if message == kAfkKickedMessage then
            SLog("---|    AFK message matched, trigger event...")
            self:SetActiveAFKPrompt(true)
            self:TriggerEvent( kThunderdomeEvents.OnGUIAfkKickedPrompt )
            return true
            
        elseif (message == kTimeoutMessage or not message) and lobby:GetState() >= kLobbyState.Ready and lobby:GetState() < kLobbyState.Finalized then

            SLog("---|    Reconnect-Prompt conditions, match, trigger event...")
            self:SetActiveReconnectPrompt(true)
            self:TriggerEvent( kThunderdomeEvents.OnGUIServerReconnectPrompt )
            return true

        end

    end

    SLog("  No applicable tests, ret-false, proceed with normal msg-handling...")
    self:LoadCompletePromptsClear()
    return false

end

function ThunderdomeManager:OnAuthTicketComplete( ticketStr )
    assert(ticketStr)
    self:TriggerEvent( kThunderdomeEvents.OnAuthGenerated, ticketStr )
end

--Fires when the local client completes the lobby create action(s)
function ThunderdomeManager:OnLobbyCreated( lobbyId, resultCode )
    SLog("ThunderdomeManager:OnLobbyCreated( %s, %s )", lobbyId, resultCode)
    assert(lobbyId, "Error: invalid OnLobbyCreated event with no LobbyID passed")
    assert(resultCode, "Error: invalid or no create res-code")
    
    local isMakingGroupMatch = self.clientModeObject and self.clientModeObject:GetIsFindingMatch()
    SLog("\t  isMakingGroupMatch: %s", isMakingGroupMatch)

    self.isCreatingLobby = false

    if resultCode == Client.SteamLobbyCreateResult_OK then

        if isMakingGroupMatch then  --TD-TODO Move below into client-object
            if self.groupLobbyId and self.groupLobbyId ~= lobbyId then
            --we're creating new Match lobby, update Group data with TargetID
                self.groupLobby:SetField( LobbyModelFields.TargetLobbyId, lobbyId )
                self.groupLobby:SetState( kLobbyState.GroupReady )
                self:TriggerLobbyMetaDataUpload( self.groupLobbyId )
                self:LeaveGroup( self.groupLobbyId, true )
                self.lastLobbyCreateType = Client.SteamLobbyType_Public
            end
        end

        if self.clientModeObject ~= nil then
            self.clientModeObject:Destroy()
            self.clientModeObject = nil
        end

        if self:GetIsGroupQueueEnabled() and not isMakingGroupMatch then
            SLog("\t  Set as GroupClientOwner")
            self.clientModeObject = GroupClientOwner()
            self.updateMode = self.kUpdateModes.GroupOwner
        else
            SLog("\t  Set as LobbyClientOwner")
            self.clientModeObject = LobbyClientOwner()
            self.updateMode = self.kUpdateModes.LobbyOwner
        end

        self.clientModeObject:Initialize()

        self:TriggerEvent( kThunderdomeEvents.OnLobbyCreated )

        self.joinedLobbyTime = Shared.GetSystemTime()

        if self:GetIsGroupQueueEnabled() and not isMakingGroupMatch then
            self:SetupNewGroup( lobbyId, self.lastLobbyCreateType )
        else
            self:SetupNewLobby( lobbyId, self.lastLobbyCreateType )
        end
        self.lastLobbyCreateType = -1  --reset to "invalid"
        return
    end

    SLog("ERROR: Failed to create lobby, code: %s", resultCode)
    self:TriggerEvent( kThunderdomeEvents.OnLobbyCreateFailed, resultCode )
end

--Occurs when local client enters a lobby, occurs for both owner and non-owner clients. 
--It Does not trigger for other lobby members
--Note: this is potentially much more complicated than desired, as users blocking other users
--may impact people being able to join, see:
-- https://partner.steamgames.com/doc/api/steam_api#EChatRoomEnterResponse
function ThunderdomeManager:OnLobbyLocalClientEnter(lobbyId, enterCode, locked, chatPerms)
    SLog("ThunderdomeManager:OnLobbyLocalClientEnter( %s , %s, %s, %s )", lobbyId, enterCode, locked, chatPerms)
    if self.updateMode == self.kUpdateModes.None then
    --Capture and ignore events triggered after local-client has changed it's mode-state
        return
    end

    assert(lobbyId, "Error: OnLobbyLocalClientEnter fired without valid LobbyID")

    if self.updateMode == self.kUpdateModes.Search then
    --ensure transfering from searching to active state
        self.searchingActive = false
    end

    if Client.GetLobbyOwnerId(lobbyId) == self:GetLocalSteam64Id() then
        if self.isCreatingLobby or (self.updateMode == self.kUpdateModes.LobbyOwner or self.updateMode == self.kUpdateModes.GroupOwner) then
            return --All tasks needed for Owners is already (or will be) done in OnLobbyCreated callback
        else
            --Otherwise we have joined a lobby that we did not create but are owner due to steam shenanigans
            --Lobby update will handle switching owner modes if we are a client owner in member mode
        end
    end

    if enterCode == Client.SteamLobbyEnterResponse_Success then
    --Only proceed if this is purely success value, any other value indicates some kind of issue
        
        if self:GetIsGroupQueueEnabled() then
            SLog("----(Local): Setup new GROUP lobby/mode")

            if self.clientModeObject ~= nil then
                self.clientModeObject:Destroy()
                self.clientModeObject = nil
            end

            self.clientModeObject = GroupClientMember()

            self.updateMode = self.kUpdateModes.GroupMember

            self.groupLobbyId = lobbyId
            
            --init data model so it can accept data updates / first-load
            self.groupLobby = LobbyModel()
            self.groupLobby:Init()
            
        else
            SLog("----(Local): Setup new MATCH lobby/mode")
            if self.clientModeObject ~= nil then
                self.clientModeObject:Destroy()
                self.clientModeObject = nil
            end

            self.clientModeObject = LobbyClientMember()

            self.updateMode = self.kUpdateModes.LobbyMember

            self.activeLobbyId = lobbyId
            
            --init data model so it can accept data updates / first-load
            self.activeLobby = LobbyModel()
            self.activeLobby:Init()
        end

        assert(self.clientModeObject, "Error: no valid client-mode object set")
        self.clientModeObject:Initialize()

        self:InitializeJoinedLobby( lobbyId )
        --[[
        if Client.GetLobbyOwnerId(lobbyId) ~= self:GetLocalSteam64Id() then
        --LobbyOwner clients will already have initialized the lobby-model object in OnLobbyCreated event
            self:InitializeJoinedLobby( lobbyId )
        end
        --]]

        self:ResetAuthentication()

        --Always flush any cached lobby-id provided by Steam at client launch-time. No longer needed
        Client.ClearLaunchLobbyId()

        self:TriggerEvent( kThunderdomeEvents.OnLobbyJoined, enterCode, lobbyId )
        
        if not Shared.GetThunderdomeEnabled() then
            self:TriggerEvent( kThunderdomeEvents.OnMenuLoadEndEvents )
        end

    else
    --Failed, cannot enter. parse enterCode for reason

        --TODO Need to account for Group

        self.activeLobbyId = nil
        self.activeLobby = nil

        if bit.band( enterCode, Client.SteamLobbyEnterResponse_CommunityBan ) ~= 0 then     --TD-TODO Add more reason/filters
            table.insert( self.kickedLobbies, lobbyId )
        end

        --If we tried to join a cached lobby-id, but it failed (i.e. no longer exists), 
        --immediately attempt to join the invite-lobby-id, if present. Otherwise, error out
        --normally as any join-fail would.
        if self.isRejoiningCachedLobbyId then
            self.isRejoiningCachedLobbyId = false
            -- NOTE: we should have cached lobby data if we're trying to rejoin a cached lobby Id, no need to re-poll the lobby data
            self:JoinLobbyInvite( Client.GetOnLaunchLobbyId(), true )
        else
            self:TriggerEvent( kThunderdomeEvents.OnLobbyJoinFailed, enterCode )
            self:TriggerEvent( kThunderdomeEvents.OnMenuLoadEndEvents ) --Always trigger to allow "normal" (i.e. consistency fail) prompt to go through
        end
    end

end

--Occurs when any non-local client enters, leaves, kicked etc. in lobby local client is a member of
function ThunderdomeManager:OnLobbyMessage( lobbyId, userChangeBy, userChanged, message )

    if self.updateMode == self.kUpdateModes.None or self.updateMode == self.kUpdateModes.Search then
    --Capture and ignore events triggered after local-client has changed it's mode-state
        return
    end

    assert(lobbyId)
    assert(userChangeBy)
    assert(userChanged)
    assert(message)

    local activeLobbyIds = { self.activeLobbyId, self.groupLobbyId }

    if not table.icontains(activeLobbyIds, lobbyId) then
    --trap any checks/triggers, as this can be fired _after_ local-client leaves a lobby
        return
    end

    SLog("ThunderdomeManager:OnLobbyMessage( %s, %s, %s, %s )", lobbyId, userChangeBy, userChanged, message)

    if bit.band(message, Client.SteamLobbyUserStateChange_Entered) ~= 0 then
    --Note: below event will not trigger until the Next meta-data update arrives and processed for matching MemberID
        SLog("\t ENTERED Flag set")

        self:TriggerDataDelayedEvent( kThunderdomeEvents.OnLobbyMemberJoin, userChanged, lobbyId )
        self:TriggerDataDelayedEvent( kThunderdomeEvents.OnGUILobbyMemberJoin, userChanged, lobbyId )
    end

    if bit.band(message, Client.SteamLobbyUserStateChange_Disconnected) ~= 0 then
        SLog("\t DISCONNECTED Flag set")
        --!!TEMP!! for testing if LOCAL client sees themselves Disconnect or not
        SLog("\t   [local]: %s          [userId]: %s", self:GetLocalSteam64Id(), userChanged)   
        self.steamIsDisconnected = true

    elseif bit.band(message, Client.SteamLobbyUserStateChange_Left) ~= 0 then
        SLog("\t LEFT Flag set")
        self:TriggerEvent( kThunderdomeEvents.OnLobbyMemberLeave, userChanged, lobbyId )
        self:TriggerEvent( kThunderdomeEvents.OnGUILobbyMemberLeave, userChanged, lobbyId )

    elseif bit.band(message, Client.SteamLobbyUserStateChange_Kicked) ~= 0 then     --Note: for display here only, Steam doesn't accutally ever set this...go figure
        SLog("\t KICKED Flag set")
        self:TriggerEvent( kThunderdomeEvents.OnLobbyMemberKicked, userChanged, lobbyId )
        self:TriggerEvent( kThunderdomeEvents.OnGUILobbyMemberKicked, userChanged, lobbyId )

    elseif bit.band(message, Client.SteamLobbyUserStateChange_Banned) ~= 0 then     --Note: for display here only, Steam doesn't accutally ever set this...go figure
        SLog("\t BANNED Flag set")
        --TODO
        --self:TriggerEvent( kThunderdomeEvents.OnLobbyMemberBanned, userChanged )
        --self:TriggerEvent( kThunderdomeEvents.OnGUILobbyMemberBanned, userChanged )
    end
    
end


--Triggered any time a Lobby's meta-data changes for local client which is a member of that lobby (regardless of ownership)
function ThunderdomeManager:OnLobbyDataUpdate( lobbyId, lobbyData, memberUpdate, memberId )
    --SLog("ThunderdomeManager:OnLobbyDataUpdate( %s, %s, %s, %s )", lobbyId, lobbyData, memberUpdate, memberId)
    assert(lobbyId)

    if self.initLobbyDataLoadOnly and lobbyData then
        self:LoadCachedLobbyModelData( lobbyId, lobbyData )
        return
    end

    local activeIds = { self.activeLobbyId, self.groupLobbyId }

    -- Trap for "late" Steam events firing _after_ local-client left a lobby and
    -- requested data update events for lobbies we are not part of
    if not self:GetIsSearching() and not table.icontains(activeIds, lobbyId) then
        self:TriggerEvent(kThunderdomeEvents.OnForeignLobbyDataUpdate, lobbyId, lobbyData, memberUpdate, memberId)
        return
    end

    --[[
    SLog("    |OnLobbyDataUpdate|")
    SLog("        isLdat: %s  -  isMdata: %s", 
        (lobbyData ~= nil and type(lobbyData) == "table" and #lobbyData > 0), 
        (memberUpdate ~= nil and memberUpdate ~= false and memberId ~= nil and memberId ~= "")
    )
    --]]

    local isGroupUpdate = self:GetIsGroupId( lobbyId )
    --SLog("        isGroupUpdate: %s", isGroupUpdate)

    if lobbyData and not memberUpdate then   --lobbyData nil when member meta-data changed

        local hasDataFld = false
        local dataIdx = -1
        for i = 1, #lobbyData do
            if lobbyData[i][1] == kLobbyModelSyncField then
                hasDataFld = true
                dataIdx = i
            end
        end
        
        if not hasDataFld then
            SLog("INFO: LobbyDataUpdate - data does not have meta-data field set")
            return
        end

        local activeIds = { self.activeLobbyId, self.groupLobbyId }

        if self:GetIsSearching() and not table.icontains(activeIds, lobbyId) then
        --Handle parsing single-lobby data that was in a search results list
            self:ProcessSearchResultLobbyData( lobbyId, lobbyData )         --TD-TODO This needs to be changed to accommodate GroupOwner, etc.
            return
        end

        local oldState

        if isGroupUpdate then
        --Friends-Groups Lobbyies only
            SLog("...Group-Lobby Data-Update...")

            local curState = self.groupLobby:GetPreviousState()
            if curState and kLobbyState[curState] then
                oldState = kLobbyState[kLobbyState[curState]]
            end

            if not self.groupLobby then
            --Trap here and Steam events can occur _after_ local-client has left their lobby
                return
            end

            --SLog("    ...deserializing GROUP meta-data...")
            assert( self.groupLobby:Deserialize( lobbyData[dataIdx][2] ), "Error: failed to deserialize Lobby meta-data" )

            local newState = self.groupLobby:GetState()

            SLog("     curState: %s", curState)
            SLog("     newState: %s", newState)

            if oldState then
                --if oldState ~= newState then
                --Since state changed, notify all listeners, this is a "main" logical step
                    SLog("    Checking Group for State change...")
                    SLog("        oldState: %s", oldState)
                    SLog("        newState: %s", newState)
                    self:TriggerEvent( kThunderdomeEvents.OnStateChange, oldState, newState, lobbyId )
                --end
            end

            if self.swapOwnersActive then
            --Block other update past this until owner swap completes
                local pO = self.groupLobby:GetField( LobbyModelFields.PrevOwners )
                --do not call swap routine until data has propagated, otherwise looping state can occur
                if pO and #pO > 0 then
                    self:HandleOwnerSwapping( lobbyId )
                end
                return
            end

        else
        --"Normal" Match Lobbies

            local oldTeam1
            local oldTeam2

            if self.activeLobby then
                local curState = self.activeLobby:GetPreviousState()
                if curState and kLobbyState[curState] then
                    oldState = kLobbyState[kLobbyState[curState]]
                end

                oldTeam1 = self.activeLobby:GetField( LobbyModelFields.ShuffledTeam1 )
                oldTeam2 = self.activeLobby:GetField( LobbyModelFields.ShuffledTeam2 )
            end

            if not self.activeLobby then
            --Trap here and Steam events can occur _after_ local-client has left their lobby
                return
            end

            --SLog("    ...deserializing MATCH meta-data...")
            assert( self.activeLobby:Deserialize( lobbyData[dataIdx][2] ), "Error: failed to deserialize Lobby meta-data" )

            local newState = self.activeLobby:GetState()
            if oldState then
                if oldState ~= newState then
                --Since state changed, notify all listeners, this is a "main" logical step
                    SLog("    Checking Match for State change...")
                    SLog("        oldState: %s", oldState)
                    SLog("        newState: %s", newState)
                    self:TriggerEvent( kThunderdomeEvents.OnStateChange, oldState, newState, lobbyId )
                end
            end

            if self.swapOwnersActive then
            --Block other update past this until owner swap completes
                local pO = self.activeLobby:GetField( LobbyModelFields.PrevOwners )
                --do not call swap routine until data has propagated, otherwise looping state can occur
                if pO and #pO > 0 then
                    self:HandleOwnerSwapping( self.activeLobbyId )
                end
                return
            end

            if oldState == kLobbyState.WaitingForCommanders or oldState == kLobbyState.WaitingForExtraCommanders then
                SLog("   --State Match for TEAMS-SHUFFLE CHECK--")
                local newTeam1 = self.activeLobby:GetField( LobbyModelFields.ShuffledTeam1 )
                local newTeam2 = self.activeLobby:GetField( LobbyModelFields.ShuffledTeam2 )

                local newComm1 = self.activeLobby:GetField( LobbyModelFields.Team1Commander )
                local newComm2 = self.activeLobby:GetField( LobbyModelFields.Team2Commander )

                local teamsShuffled = --TODO integrate comms
                    ( oldTeam1 ~= newTeam1 and (newTeam1 ~= nil and newTeam1 ~= "" and #newTeam1 > 0 ) ) or 
                    ( oldTeam2 ~= newTeam2 and (newTeam2 ~= nil and newTeam2 ~= "" and #newTeam2 > 0 ) )

                SLog("\t teamsShuffled: %s", teamsShuffled)
                SLog("\t\t oldTeam1: %s", oldTeam1)
                SLog("\t\t oldTeam2: %s", oldTeam2)
                SLog("\t\t   newTeam1: %s", newTeam1)
                SLog("\t\t   newTeam2: %s", newTeam2)
                SLog("\t\t   newComm1: %s", newComm1)
                SLog("\t\t   newComm2: %s", newComm2)

                if teamsShuffled then
                    self:TriggerEvent( kThunderdomeEvents.OnTeamShuffleComplete )
                end
            end

        end

    end

    if memberUpdate then
    --Lobby Member data update only, trigger update of Lobby member id
        
        local actualMembers = {}
        if not Client.GetLobbyMembersList( lobbyId, actualMembers ) then
            SLog("Warning: Failed to fetch members list on Member[%s] Data update for Lobby[%s]", memberId, lobbyId)
        end

        SLog("    actualMembers: %s", actualMembers)

        if table.icontains( actualMembers, memberId ) then
        --Safety check for when/if member leaves and then Steam notifies of update (yay, async without validation...)
        --Data updates can come in before message denoting member left, required to check member actually exists
            self:LoadLobbyMemberData( lobbyId, memberId )
            self:ProcessDataDelayedEvents( memberId )
            self:TriggerEvent( kThunderdomeEvents.OnGUILobbyMemberMetaDataChange, memberId, lobbyId )
        end

    end

    local isLocalOwner = Client.GetLobbyOwnerId( lobbyId ) == self:GetLocalSteam64Id()

--Handle Groups
    if isLocalOwner and self.updateMode == self.kUpdateModes.GroupMember then
        SLog("\t !!!  Local-client is now GroupOwner, switching modes...")
        self.clientModeObject:Destroy()
        self.clientModeObject = nil

        self.clientModeObject = GroupClientOwner()
        self.clientModeObject:Initialize()

        self.updateMode = self.kUpdateModes.GroupOwner
    end

    if self.updateMode == self.kUpdateModes.GroupOwner and not isLocalOwner then
    --Lobby Owner switching back to Member when some failure condition occured (e.g. fail to re-auth, etc)
        SLog("\t !!!  Local-client _was_ GroupOwner, switching to Member mode...")
        self.clientModeObject:Destroy()
        self.clientModeObject = nil

        self.clientModeObject = GroupClientMember()
        self.clientModeObject:Initialize()

        self.updateMode = self.kUpdateModes.GroupMember
    end

--Handle Match Lobbies
    if isLocalOwner and self.updateMode == self.kUpdateModes.LobbyMember then
    --local client is now lobby owner, need to switch modes and logic-objects
        SLog("\t !!!  Local-client is now LobbyOwner, switching modes...")
        self.clientModeObject:Destroy()
        self.clientModeObject = nil

        self.clientModeObject = LobbyClientOwner()
        self.clientModeObject:Initialize()

        self.updateMode = self.kUpdateModes.LobbyOwner
    end
    
    if self.updateMode == self.kUpdateModes.LobbyOwner and not isLocalOwner then
    --Lobby Owner switching back to Member when some failure condition occured (e.g. fail to re-auth, etc)
        SLog("\t !!!  Local-client _was_ LobbyOwner, switching to Member mode...")
        self.clientModeObject:Destroy()
        self.clientModeObject = nil

        self.clientModeObject = LobbyClientMember()
        self.clientModeObject:Initialize()

        self.updateMode = self.kUpdateModes.LobbyMember
    end

end

--Happens when any chat message is Received for lobby local-client is a member of
function ThunderdomeManager:OnLobbyChatMessage( lobbyId, senderSteamId, message )

    local validChatMode = 
        self.updateMode == self.kUpdateModes.LobbyMember or 
        self.updateMode == self.kUpdateModes.LobbyOwner or
        self.updateMode == self.kUpdateModes.GroupOwner or
        self.updateMode == self.kUpdateModes.GroupMember

    if not validChatMode then
    --Capture and ignore events triggered after local-client has changed it's mode-state
        return
    end

    assert(lobbyId)
    assert(senderSteamId)
    assert(message)

    --TODO Add handler for "Special" messages (kick, etc.)
    ----Use a hash-key (saved as const) that denotes "SYSTEM" message, append a ' ' and enum index for type/message
    ------A simple functor table could be used to be setup behavior, e.g.  HASHKEY -> Function

    if table.icontains( self.mutedSteamIds, senderSteamId ) then
        return
    end

    if message == "" then
        return
    end

    local senderTeam = 0

    local lob
    local isGroup = self:GetIsGroupId( lobbyId )
    if isGroup then
        lob = self.groupLobby
    else
        lob = self.activeLobby
    end
    assert(lob, "Error: No valid LobbyModel found for any lobby-type")

    if not isGroup and lob:GetState() >= kLobbyState.WaitingForServer then

        senderTeam = lob:GetMemberModel(senderSteamId):GetField( LobbyMemberModelFields.Team )

        if senderTeam ~= self:GetLocalClientTeam() then
            return
        end
    end

    local chatMessage = string.UTF8SanitizeForNS2(message)
    local senderAlias = lob:GetMemberName( senderSteamId )

    self:TriggerEvent( kThunderdomeEvents.OnChatMessage, lobbyId, senderSteamId, senderAlias, chatMessage, senderTeam )

end


-------------------------------------------------------------------------------
-- Timed / Interval Routines

function ThunderdomeManager:ProcessDelayedEvents()
    local time = Shared.GetSystemTime()

    --Run through all events (to keep jit-friendly)
    for i = 1, #kThunderdomeEvents do
        local eventType = kThunderdomeEvents[kThunderdomeEvents[i]]
        
        if #self.delayedEventsQueue[eventType] > 0 then
            SLog("  Have delayed-events for Type: %s", kThunderdomeEvents[i])

            for d = #self.delayedEventsQueue[eventType], 1, -1 do
            --run in reverse so we respond to the oldest delayed-events first
                SLog("    Delayed-Event: %s", self.delayedEventsQueue[eventType][d])

                local delayTime = self.delayedEventsQueue[eventType][d].started + self.delayedEventsQueue[eventType][d].wait
                SLog("      delayTime[%s]", delayTime)

                if delayTime <= time then
                --Delayed event has expired and ready to trigger, do so
                    SLog("  Delayed event[%s-%s] expired! Triggering callbacks...", kThunderdomeEvents[i], d)

                    if self.systemInitFailed and eventType ~= kThunderdomeEvents.OnSystemInitFailed then
                    --Halt all other events from firing
                        table.remove( self.delayedEventsQueue[eventType], d )   --clear out so won't re-run
                        return
                    end

                    SLog("==ThunderdomeManager - Have delayed-event '%s', triggering...", kThunderdomeEvents[eventType])
                    self:TriggerEvent( eventType, unpack(self.delayedEventsQueue[eventType][d].args) )
                    table.remove( self.delayedEventsQueue[eventType], d )
                end
            end
        end
    end

end

function ThunderdomeManager:ProcessDataDelayedEvents( memberId )
    SLog("ThunderdomeManager:ProcessDataDelayedEvents( %s )", memberId)
    assert(memberId)
    for i = 1, #kThunderdomeEvents do
        local eventType = kThunderdomeEvents[kThunderdomeEvents[i]]
        if #self.dataDelayedEventsQueue[eventType] > 0 then
            for d = #self.dataDelayedEventsQueue[eventType], 1, -1 do   --FILO stack, start with oldest
                if memberId == self.dataDelayedEventsQueue[eventType][d].member_id then

                    if self.systemInitFailed and eventType ~= kThunderdomeEvents.OnSystemInitFailed then
                    --Halt all other events from firing
                        table.remove( self.dataDelayedEventsQueue[eventType], d )   --clear out so won't re-run
                        return
                    end

                    SLog("\t ** ThunderdomeManager - Have Member data-delayed event '%s', triggering...", kThunderdomeEvents[eventType])
                    self:TriggerEvent( eventType, memberId, unpack(self.dataDelayedEventsQueue[eventType][d].args) )
                    table.remove( self.dataDelayedEventsQueue[eventType], d )
                end
            end
        end
    end
end

function ThunderdomeManager:AttemptLobbyReconnect()
    SLog("ThunderdomeManager:AttemptLobbyReconnect()")
    assert(not self.steamConnectionLost, "Error: cannot utilize Steam features when offline")
    assert(self.activeLobbyId, "Error: no applicable LobbyID set, cannot re-join")

    local numMems = Client.GetNumLobbyMembers(self.activeLobbyId)
    SLog("   numMems: %s", numMems)

    if numMems > 1 then
    --existing lobby exists, rejoin. 
    --Note: we cannot rejoin unless another client is in lobby, attempting to rejoin will trigger leave-event, this destroying lobby
        Client.JoinLobby(self.activeLobbyId)
    else
    --lobby no longer exists, test if we were single member of it (e.g. single-user started private, but ticked offline, etc.)
        local lobType = self.activeLobby:GetType()      --TD-FIXME ...we need to cache full-state, and update accordingly after connecting completes! (e.g. a failed-over lobby)
        self:ResetMode() --clear existing state, so clean when re-creating
        self:CreateLobby( lobType, self.isGroupQueueEnabled )
    end

end

function ThunderdomeManager:GetIsSteamDisconnected()
    return self.steamIsDisconnected or self.steamConnectionLost
end

--Run a quick check to ensure Steam client is online, limit to kSteamConnCheckInterval frequency
--Note: the interval can _never_ be less than 1 second
--!IMPORTANT!: We're entirely at the mercy of local-client's Steam client. If it doesn't "want" to come online quickly, we're hosed.
function ThunderdomeManager:UpdateSteamConnection()
    
    local time = Shared.GetSystemTime() --seconds

    if self.lastSteamConnCheckTime + self.kSteamConnCheckInterval < time then

        self.lastSteamConnCheckTime = time

        local online = Client.GetIsSteamAvailable()

        if self.steamConnectionFailedTick > 0 and online then

            self.steamConnectionFailedTick = self.steamConnectionFailedTick - 1

            SLog("   Steam-Client ticked Online, checking tracking...")
            SLog("      offline-tick: %s", self.steamConnectionFailedTick)

            self.steamIsDisconnected = false

            if self.steamConnectionFailedTick == 0 then
            --clear and reset offline tracking

                self.lastSteamConnCheckTime = 0
                self.lastSteamConnLostTime = 0
                self.steamConnectionLost = false
                SLog("     Steam-Client !ONLINE! ...reset tracking data...")

            end

            --Look for active-lobby (object and ID), AND ensure we've testing online state a few times before attempting rejoin
            --this is done to eliminate cases where wifi is crap, and a single Online check passes, then rejoin fails again.
            if self.activeLobby and self.activeLobbyId and self.steamConnectionFailedTick == 0 and not self.steamIsDisconnected then
            --Note: self.steamIsDisconnected check is done when OnLobbyMessage fires during this update
                SLog("   Steam-Client !ONLINE!")
                SLog("     Attempting to rejoin active lobby[%s]", self.activeLobbyId)

                --Force a re-join when we've come back online, because Steam automatically leaves (backend) a lobby
                --when a Steam Client is considered offline and not pinging Steamworks anymore.
                self:AttemptLobbyReconnect()
            end

        else

            if not online then

                if self.steamConnectionFailedTick == self.kSteamConnFailedLimit and self.steamConnectionLost then
                    return
                end

                SLog("   Steam-Client OFFLINE")

                self.lastSteamConnLostTime = time
                self.steamConnectionFailedTick = math.min( self.steamConnectionFailedTick + 1, self.kSteamConnFailedLimit )
                SLog("      offline-tick: %s", self.steamConnectionFailedTick)

                self.steamIsDisconnected = true

                if self.steamConnectionFailedTick >= self.kSteamConnFailedLimit then
                    SLog("     Steam-Client OFFLINE limt hit, disabling TD system...")

                    self.steamConnectionFailedTick = self.kSteamConnFailedLimit
                    self.steamConnectionLost = true

                    local isConnectedToLobby = self:GetIsConnectedToLobby()
                    local isSearching = self:GetIsSearching()

                    --We're still in Menu context here, ignore when connected to _any_ server (local or otherwise)
                    if (isSearching or isConnectedToLobby) and not Shared.GetThunderdomeEnabled() and not Client.GetIsConnected() then
                        SLog("    Trigger steam-offline event...")
                        self:TriggerEvent( kThunderdomeEvents.OnGUISteamConnectionLost )
                        self:ResetMode()
                    end

                end

            end

        end

    end

end


local sysFailedNotified = false

--Note: this does run outside of Menu, so even while playing (hence its self-throttle)
function ThunderdomeManager:Update( delta )

    if self.thunderdomeDisabled then
        return
    end

    local time = Shared.GetSystemTime()

    if self.systemInitFailed and not sysFailedNotified then
        self:TriggerEvent( kThunderdomeEvents.OnSystemInitFailed )
        sysFailedNotified = true
        return
    end

    if not self.localHiveProfileFetched then
        if self.hiveProfileFetchStartTime + self.kHiveProfileFetchTimeout < time then
            self:SetHiveProfileFetched( false, true, "Hive profile data-fetch call timeout" )
        end
        return
    end
    
    if not self.initializedLocalData then
        self.initializedLocalData = Client.GetThunderdomeDataInitialized()
        if not self.initializedLocalData then
            return
        else
            self:TriggerEvent( kThunderdomeEvents.OnLocalDataInitComplete )
        end
    end

    self:UpdateSteamConnection()

    if self.steamConnectionLost then
    --cannot proceed without active connection to Steam
        return
    end

    if self.cancelSearching then
    --halt immediately regardless of update-rate, to prevent any events/actions being taken
        self.searchingActive = false

        if self.clientModeObject then
            self.clientModeObject:Destroy()
            self.clientModeObject = nil
        end

        self.searchResultsList = nil

        self.updateMode = self.kUpdateModes.None
        
        --clear so next tick doesn't access nils
        self.cancelSearching = false
    end
    
    if self.initTimestamp > 0 and ( time - self.initTimestamp ) > self.kMinOnLoadCheckLobbyDelay then
        self.initTimestamp = -1
        self:DelayedStartupChecks()
        return
    end

    if self.initLobbyDataLoadOnly then
    --wait for cached lobby-id data to be loaded/primed before updating
        SLog("TD - Skipping update, still loading cached lobby data...")
        return
    end
    
    if self.isConnectedToServer and not self.onConnectedInitComplete then
    --Client recently connected to the Server, and needs to notify the server of its own lobby data
        self:UpdateOnConnectedState()
    end

    --Waiting on user to interact with AFK kicked prompt, halt all non-load/init updates until done
    if self.pendingAkfPromptAction or self.pendingReconnectPrompt then
        return
    end

    --Runs outside of Client-Object context so out-of-lobby Invites or in-match invites can work
    self:ProcessDelayedEvents()

    -- Prevent update from continuing if we've set initLobbyDataLoadOnly during an event handler
    if self.initLobbyDataLoadOnly then
    --wait for cached lobby-id data to be loaded/primed before updating
        SLog("TD - Skipping late-update, still loading cached lobby data...")
        return
    end

    if self.updateMode == self.kUpdateModes.None then
        return
    end

    if self.lastUpdatedTime + self.kUpdateRate > time then
        return
    end

    self.lastUpdatedTime = time

    if self.authAttemptDelay ~= -1 and self.authAttemptTime > 0 then

        if self.pendingSteamAuthGenerate then
        --check to ensure steam ticket generate hasn't failed (it should be quick)
            if self.timeSteamAuthGenerate + self.kMaxSteamAuthGenerateLimit < time then
                SLog("Warning: Steam auth-ticket generation timed out")
                self:TriggerOwnerChange( self.activeLobbyId )   --swap owners so local-client doesn't dead-lock lobby routines
            end
        end

        local authAttemptTime = self.authAttemptTime + self.authAttemptDelay
        if authAttemptTime <= time then
            self:Authenticate()
        end
    end

    if self.authenticationAttemptActive then
    --Always delay updating anything else, that's not pure event-based, until auth attempt
    --is completed (regardless of success/fail). Required as multiple client-state objects
    --need auth-state clearly defined. Easy to skip updates.
        return
    end

    --check local client's lifespan time in current lobby, if public type, we don't care bout private ones
    if self.activeLobby and self.activeLobby:GetType() == Client.SteamLobbyType_Public then
    
        local curTdTime = Client.GetTdTimestamp()
        local lastStateTime = self.activeLobby:GetField( LobbyModelFields.StateChangeTime )
        local lobState = self.activeLobby:GetState()

        if lastStateTime and lobState then
        --Lobby is not and actively playing match, and it's been at least X seconds since last state change. Bail out now, to prevent AFK deadlocked lobbies
            if (lobState >= kLobbyState.WaitingForPlayers and lobState < kLobbyState.Playing ) and curTdTime - lastStateTime > self.kMaxLobbyLocalLifespan then     --TD-FIXME This only works IF lobby is set to 'Playing' by Owner...
                self:TriggerEvent( kThunderdomeEvents.OnGUIMaxLobbyLifespanNotice )
                return  --halt here, as this will in turn trigger auto-leaving
            end
        end
        
    end

    if self.clientModeObject ~= nil and not self.steamIsDisconnected then

        --TD-TODO Handle any timed / interval actions (internal)
        -- e.g. waiting before X action, waiting Y time before lobby owner joins (await all members leaving, etc), etc
        ---- XXX Need to CAREFULLY review list of needed updates and devise consistent contextual triggers for them

        self.clientModeObject:Update(self, delta, time)
    end

end


-------------------------------------------------------------------------------
-- Debug / Data dump utils

function ThunderdomeManager:DebugDump(fullDump)
    Log("-------------------------------------------------------------------------------")
    Log("   Thunderdome Debug-Dump -----------------")

    local updateMode = 
        self.kUpdateModes[ self.updateMode ] and self.kUpdateModes[ self.updateMode ] or "None"
    
    Log("(internals)")
    
    Log("\t System Disabled:            %s", self.thunderdomeDisabled)
    Log("\t Sys-Init Fail:              %s", self.systemInitFailed)
    Log("\t SteamConnLost:              %s", self.steamConnectionLost)
    Log("")
    Log("\t GroupQueueEnabled:          %s", self.isGroupQueueEnabled)
    Log("\t LocalGroupID:               %s", self.localGroupId)
    Log("")
    Log("\t Init Ts:                    %s", self.initTimestamp)
    Log("\t Init LobData Load:          %s", self.initLobbyDataLoadOnly)
    Log("")
    Log("\t HiveP Fetch:                %s", self.localHiveProfileFetched)
    Log("\t HiveP FetchFail:            %s", self.localHiveProfileFetchFailed)
    Log("")
    Log("\t Conn-Init:                  %s", self.onConnectedInitComplete)
    Log("\t Conn Ts:                    %s", self.isConnectedTime)
    Log("\t ServerConn:                 %s", self.isConnectedToServer)
    Log("\t Lob Server Failed:          %s", self.lobbyServerFailed)
    Log("\t Lob ServerConn Failed:      %s", self.lobbyServerConnFailed)
    Log("")
    Log("\t Search Active:              %s", self.searchingActive)
    Log("\t Search Cancel:              %s", self.cancelSearching)
    Log("\t Search Res-Size:            %s", self.searchingDataFetchCount)
    Log("\t IsCreatingLobby:            %s", self.isCreatingLobby)
    Log("")
    Log("\t AuthAttempt:                %s", self.authenticationAttemptActive)
    Log("\t SwapOwnerActive:            %s", self.swapOwnersActive)
    Log("\t SessionID:                  %s", self.activeSessionId)
    Log("")
    Log("\t Muted ClientIDs:            %s", self.mutedSteamIds)
    Log("")
    Log("(sys-opts)")
    Log("\t      lastActiveLobbyId:    %s", Client.GetOptionString(kOptionKey_CachedLobbyId, ""))
    Log("\t lastActiveConnAttempts:    %s", Client.GetOptionInteger(kOptionKey_CachedLobbyConnAttempts, 0))
    Log("\t     lastActiveConnMade:    %s", Client.GetOptionBoolean(kOptionKey_CachedLobbyConnMade, false))

    Log("---------------------------------------\n")

    if fullDump then
        Log("\t [ Hive Profile Data ]")
        Log("\t\t         avg skill:   %s", self.avgSkill)
        Log("\t\t      skill-offset:   %s", self.skillOffset)
        Log("\t\t        comm skill:   %s", self.commSkill)
        Log("\t\t comm skill offset:   %s", self.commOffset)
        Log("\t\t   adagradGradient:   %s", self.adagradGradient)

        Log("---------------------------------------\n")
    end

    Log("\t [ Client Update-Mode Object ]")
    Log("\t\t Type: %s", updateMode)
    if updateMode ~= "None" then
        self.clientModeObject:DebugDump(fullDump)
    end

    Log("---------------------------------------\n")

    if self.groupLobby then
        Log("\t [ Group Lobby ]")
        Log("\t\t  GroupLobbyId: %s", self.groupLobbyId)
        local ownerId = Client.GetLobbyOwnerId(self.groupLobbyId)
        local ownerName = self.groupLobby:GetMemberName(ownerId)
        Log("\t\t  OwnerId: %s  -  [%s]", ownerId, ownerName)
        self.groupLobby:DebugDump(fullDump)
        Log("")
    end

    if self.activeLobby then
        Log("\t [ Active Lobby ]")
        Log("\t\t  ActiveLobbyId: %s", self.activeLobbyId)
        local ownerId = Client.GetLobbyOwnerId(self.activeLobbyId)
        local ownerName = self.activeLobby:GetMemberName(ownerId)
        Log("\t\t  OwnerId: %s  -  [%s]", ownerId, ownerName)
        self.activeLobby:DebugDump(fullDump)
    end

    Log("\n-------------------------------------------------------------------------------\n")
end


-------------------------------------------------------------------------------


--singleton accessor
gThunderdomeManager = nil
function Thunderdome()
    if gThunderdomeManager == nil then
        gThunderdomeManager = ThunderdomeManager()
        gThunderdomeManager:Initialize()
    end
    return gThunderdomeManager
end


-------------------------------------------------------------------------------
-- Steamworks Event bindings

Event.Hook("SessionAuthTicketComplete",
    function( authTicket )
        SLog("Steamworks Event - SessionAuthTicketComplete")
        Thunderdome():OnAuthTicketComplete(authTicket)
        return true
    end
)

Event.Hook("OnLobbyCreated", 
    function( lobbyId, resultCode )
        SLog("Steamworks Event - OnLobbyCreated")
        SLog("\t lobbyId: %s, resultCode: %s", lobbyId, resultCode)
        Thunderdome():OnLobbyCreated( lobbyId, resultCode )
        return true
    end
)

Event.Hook("OnLobbyListResults", 
    function( list )
        SLog("Steamworks Event - OnLobbyListResults")
        Thunderdome():OnLobbySearchResults( list )
        return true
    end
)

--triggers any time lobby data is added/removed/modified. This includes memberdata and gameserver data
Event.Hook("OnLobbyDataUpdated", 
    function( lobbyId, lobbyData, memberUpdate, lobbyMemberId )
        --SLog("Steamworks Event - OnLobbyDataUpdated")
        Thunderdome():OnLobbyDataUpdate( lobbyId, lobbyData, memberUpdate, lobbyMemberId )
        return true
    end
)

--Only fires when joining a lobby or another client joins. Does not trigger when lobby owner creates a lobby
Event.Hook("OnLobbyClientEnter", 
    function(lobbyId, enterCode, locked, chatPerms) 
        SLog("Steamworks Event - OnLobbyClientEnter")
        Thunderdome():OnLobbyLocalClientEnter(lobbyId, enterCode, locked, chatPerms) 
        return true
    end
)

Event.Hook("OnLobbyMessage", 
    function(lobbyId, userChangeBy, userChanged, message) 
        SLog("Steamworks Event - OnLobbyMessage")
        Thunderdome():OnLobbyMessage(lobbyId, userChangeBy, userChanged, message) 
        return true
    end
)

Event.Hook("OnLobbyChatMessage", 
    function(lobbyId, sentById, message) 
        --SLog("Steamworks Event - OnLobbyChatMessage")
        Thunderdome():OnLobbyChatMessage(lobbyId, sentById, message) 
        return true
    end
)

--Triggers when running the game and a friend sent an join-invite to a their lobby
Event.Hook("OnLobbyInviteReceived", 
    function(lobbyId, inviterId, inviterName)
        SLog("Steamworks Event - OnLobbyInviteReceived")
        Thunderdome():OnLobbyInviteReceived(lobbyId, inviterId, inviterName)
    end
)

--Triggers when attempting to join a lobby via Steam Friends list, not from in-game/menu action
--(requires Overlay active while game running), joining when outside game via Friends list will
--be handled on ThunderdomeManager init routine.
Event.Hook("OnFriendsLobbyJoin",
    function(lobbyId)
        SLog("Steamworks Event - OnFriendsLobbyJoin")
        Thunderdome():JoinLobby(lobbyId)
    end
)

-------------------------------------------------------------------------------
-- Local Client Bindings / Events

Event.Hook("UpdateClient", 
    function( deltaTime )
    --done as Client update, in order for lobby behaviors to not be affected by Menu visibility
        Thunderdome():Update( deltaTime )
    end
)

--TODO Add binding & hook for In-Game lobby invites (both with and without Steam overlay enabled!)

local leaveEventTriggered = false
local OnClientLeaveEvent = function(type, reason)
    SLog("  --  OnClientLeaveEvent( %s, %s ) ", type, reason)
    if leaveEventTriggered then
        SLog("\t already triggered, skipping...")
        return
    end
    assert(type)

    local td = Thunderdome()

    if g_thunderdomeVerbose and td.activeLobby then
        SLog("")
        td:DebugDump()
        SLog("")

        td.activeLobby:DebugDump(true)
        SLog("")

        if not td.activeLobby then
            SLog("  DisconnectEvent fired without valid Lobby object")
        else
            td.activeLobby:DebugDump(true)
            SLog("")
        end
    end

    if td.activeLobby then
    --only applicable to test when lobby exists
        
        local lobState = td.activeLobby:GetState()
        SLog("\t lobState:  %s", kLobbyState[lobState])
        local activeLobby = 
            ( lobState >= kLobbyState.WaitingForCommanders and lobState < kLobbyState.Finalized ) and 
            ( 
                not td.lobbyServerConnFailed and 
                not td.lobbyServerFailed and 
                not td.localHiveProfileFetchFailed and
                not td.steamConnectionLost and 
                not td.systemInitFailed
            )

        local activeMatch = false
        local postMatch = false
        if Shared.GetThunderdomeEnabled() then
            activeMatch = 
                not GetThunderdomeRules():GetIsMatchCompleted() and 
                not GetThunderdomeRules():GetIsMatchForceConceded()

            postMatch =
                GetThunderdomeRules():GetIsMatchCompleted() or
                GetThunderdomeRules():GetIsMatchForceConceded()
        end

        local lobType = td.activeLobby:GetField( LobbyModelFields.Type )
        local isPrivate = GetLobbyTypeValue(lobType) == Client.SteamLobbyType_Private

        SLog("\t\t  activeLobby:  %s", activeLobby)
        SLog("\t\t  activeMatch:  %s", activeMatch)
        SLog("\t\t    isPrivate:  %s", isPrivate)
        SLog("\t\t\t    lobbyType:  %s", lobType)

        Client.ThunderdomeDisconnectEvent( td.activeLobbyId, activeLobby, activeMatch, isPrivate )

        if (not activeLobby) or postMatch then
           --force/clear cached data when not penalized to ensure clean state on next start
            Client.SetOptionString(kOptionKey_CachedLobbyId, "")            --TD-FIXME If this is encountered during consistency fail (etc.) can cause script error due to client not fully loaded
            Client.SetOptionInteger(kOptionKey_CachedLobbyConnAttempts, 0)
            Client.SetOptionBoolean(kOptionKey_CachedLobbyConnMade, false)
            SLog("!!!! Cleared all cached lobby-data !!!")
        end

    else
        td:Uninitialize()

        --force/clear cached data when not penalized to ensure clean state on next start
        Client.SetOptionString(kOptionKey_CachedLobbyId, "")            --TD-FIXME If this is encountered during consistency fail (etc.) can cause script error due to client not fully loaded
        Client.SetOptionInteger(kOptionKey_CachedLobbyConnAttempts, 0)
        Client.SetOptionBoolean(kOptionKey_CachedLobbyConnMade, false)
        SLog("!!!! Cleared all cached lobby-data !!!")
    end

    leaveEventTriggered = true
end

Event.Hook("OnClientExit", 
function()
    SLog("Event OnClientExit")
    OnClientLeaveEvent("exit")
end)

Event.Hook("ClientConnected",
    function()
        SLog("Event ClientConnected")
        if Shared.GetThunderdomeEnabled() then
        --trigger auto-join message routines when connected to TD server
            Thunderdome():EnableAutoTeamJoin()
        end
    end
)

Event.Hook("ClientDisconnected",
    function( reason, isExit ) 
        SLog("Event ClientDisconnected")
        SLog("\t  reason: %s", reason)
        OnClientLeaveEvent("disconnect", reason)
    end
)

Event.Hook("Console_td_cl_matchend",
    function()
        Log("Console_td_cl_matchend")
        Client.ClearLaunchLobbyId()
        Thunderdome():LeaveLobby(Thunderdome():GetActiveLobbyId())
        Client.Disconnect()
    end
)

Event.Hook("InventoryUpdated",
    function()
        Thunderdome():TriggerEvent( kThunderdomeEvents.OnUserStatsAndItemsRefreshed )
        --TD-TODO can trigger item pop-ups here, maybe
    end
)

Event.Hook("OnUserStatsUpdate",
    function()
    --force update of inventory in order to ensure we capture new item grants
        Client.GrantPromoItems()
        Client.UpdateInventory()
    end
)


--trap repeating errors, only send once
local errorCount = 0
local lastError
local seenErrors = {}

Event.Hook("ErrorCallback", 
    function(error, log)

        if ( Client.GetIsConnected() and not Client.GetIsRunningServer() ) or not Shared.GetThunderdomeEnabled() then
        --Ignore all non-TD servers, except localhost scenarios (e.g. tutorials), but capture Main Menu context
            return
        end

        local newError = not seenErrors[error]
        local repeatingError = error == lastError
        lastError = error
        seenErrors[error] = (seenErrors[error] or 0) + 1

        if not repeatingError and newError then
        --Note: no response handler, as this should be fire-n-forget    
            SLog("--Sending Error Report--")

            --TD-TODO Devise test of when/if scope of error, and flag it as TD. If so, leave lobby with message

            Shared.SendHTTPRequest( 
                kTDErrorReportUrl, 
                "POST", 
                { 
                    error = error, 
                    log_msg = log, 
                    version = Client.GetSteamBuildId(), 
                    branch = Client.GetSteamBranch(), 
                    build = Shared.GetBuildNumber(), 
                    source = "client",
                    sid = Client.GetSteamId(),
                }
            )
        end

        -- If we're in an active lobby and getting script errors, assume lobby state and client state are likely to be
        -- borked. Try to leave the lobby safely (without causing cascading errors) and clear the client state.

        local td = Thunderdome()

        if not Client.GetIsConnected() and td.activeLobbyId or td.activeGroupId then

            pcall(td.LeaveLobby, td, td.activeLobbyId or td.activeGroupId)

            -- if we still have an active lobby Id of some form set, assume the above call failed with an error

            if td.activeLobbyId then
                Client.LeaveLobby(td.activeLobbyId)
            end

            if td.activeGroupId then
                Client.LeaveLobby(td.activeGroupId)
            end

            -- Assume lobby state is probably borked and the LeaveLobby call also errored, so manually clear cached
            -- lobby IDs and reset to a "known-good" state.
            Client.SetOptionString( kOptionKey_CachedLobbyId, "" )
            Client.SetOptionString( kOptionKey_CachedLobbyGroupId, "" )
            Client.SetOptionBoolean( kOptionKey_CachedLobbyConnMade, false )
            Client.SetOptionInteger( kOptionKey_CachedLobbyConnAttempts, 0 )

            Client.ClearLaunchLobbyId()

            -- Finally, reboot the menu VM to reload GUI and Thunderdome state.
            Client.RestartMain()

        end
    end
)



-------------------------------------------------------------------------------
-- Debug / Testing Utils
--                              *********************************************
--                              *********************************************
--                              *********************************************
--                              ********REMOVE BEFORE SHIPPING UPDATE********
--                              *********************************************
--                              *********************************************
--                              *********************************************


Event.Hook("Console_td_dumppen", function()
    Client.DumpPenaltyState()
end)

Event.Hook("Console_td_lobinvite", 
    function()
        assert(Client.GetIsSteamOverlayEnabled(), "Error: can only be used with Steam overlay enabled")
        local lobId = Thunderdome():GetActiveLobbyId()
        assert(lobId, "Error: must be in an active lobby before inviting")
        Client.ShowOverlayLobbyInvite(lobId)
    end
)

Event.Hook("Console_td_penalized", function()
    if Client.GetIsThunderdomePenalized() then
        Log("\t Is penalized")
    else
        Log("\t No penalties")
    end
end)

Event.Hook("Console_td_penaltytime", function()
    local t = Client.GetThunderdomeActivePenaltyPeriod()
    Log("Penalty Expires:  %s", t)
end)

Event.Hook("Console_td_dump",
    function(full)
        local fullDump = (full ~= nil and (full == "1" or full == "true")) and true or false
        Thunderdome():DebugDump(fullDump)
    end
)

Event.Hook("Console_td_lobowner", 
    function()
        local lobby = Thunderdome():GetActiveLobby()
        assert(lobby)
        local ownerId = Client.GetLobbyOwnerId(lobby:GetId())
        local owner = lobby:GetMemberModel( ownerId )
        assert(owner)
        owner:DebugDump()
    end
)

Event.Hook("Console_td_lob_rawdump",
    function()
        SLog("------ Dumping Steam Lobby meta-data ------")
        local lobId = Thunderdome():GetActiveLobby():GetId()
        assert(lobId)

        SLog("Lobby ID: %s", lobId)
        SLog("\t Num Members: %s", Client.GetNumLobbyMembers(lobId))
        local raw = Client.GetLobbyDataField( lobId, kLobbyModelSyncField )
        --TD-TODO Add Build, Branch, etc.
        SLog("\t Raw Data:\n %s", raw)
    end
)

Event.Hook("Console_td_create_priv_lob", 
    function()
        Log("--Create Private Lobby--")
        local aLob = Thunderdome():GetActiveLobby()
        if aLob == nil then
            Thunderdome():CreateLobby( Client.SteamLobbyType_Private, false )
        else
            Log("Error: Cannot create private-lobby while already in a lobby")
        end
    end
)

Event.Hook("Console_td_group", function()
    local l = Thunderdome():GetActiveLobby()
    assert(l == nil, "Error: must not be in existing lobby")
    Thunderdome():CreateLobby( Client.SteamLobbyType_Private, true )
end)

local defaultSlots = kMinRequiredLobbySizeServerRequest
Event.Hook("Console_td_glob_waitplayer_limit",
function(count)
    if not count then
        Log("Set player-limit threshold for lobby steps [2-%s]", kMinRequiredLobbySizeServerRequest)
        Log("\t Value of -1 resets to default[%s]", defaultSlots)
        return
    end
    count = tonumber(count)
    assert(count)
    assert( count == -1 or (count > 0 and count <= defaultSlots) )

    if count == -1 then
        kMinRequiredLobbySizeServerRequest = defaultSlots
        Log("Reset player-limit to: %s", kMinRequiredLobbySizeServerRequest)
        return
    end

    kMinRequiredLobbySizeServerRequest = count
    Log("Set player-limit to: %s", kMinRequiredLobbySizeServerRequest)
end)

local defaultCommsLimit = kMinRequiredCommanderVolunteers
Event.Hook("Console_td_glob_waitcomms_limit",
function(limit)
    if not limit then
        Log("Set min commanders required threshold for lobby steps [1-%s]", kMinRequiredLobbySizeServerRequest)
        Log("\t Value of -1 resets to default[%s]", defaultCommsLimit)
        return
    end

    limit = tonumber(limit)
    assert(limit)
    assert( limit == -1 or (limit > 0 and limit <= kMinRequiredLobbySizeServerRequest) )

    if limit == -1 then
        kMinRequiredCommanderVolunteers = defaultCommsLimit
        Log("Reset min commanders required threshold to: %s", kMinRequiredCommanderVolunteers)
        return
    end

    kMinRequiredCommanderVolunteers = limit
    Log("Set min commanders required threshold to: %s", kMinRequiredCommanderVolunteers)
end)

local defaultMapVotePercentLimit = kMinPercentMapVoteThreshold
Event.Hook("Console_td_glob_mapvote_limit",
function(percent)
    if not percent then
        Log("Set map-vote percentage threshold for lobby steps [2-%s]", kMinPercentMapVoteThreshold)
        Log("\t Value of 0 resets to default[%s]", defaultMapVotePercentLimit)
    end

    percent = tonumber(percent)

    if percent == 0 then
        kMinPercentMapVoteThreshold = defaultMapVotePercentLimit
        Log("Reset map-vote threshold to: %s", kMinPercentMapVoteThreshold)
        return
    end

    percent = percent * 0.01
    assert(percent > 0)

    kMinPercentMapVoteThreshold = percent
    Log("Set lobby map-vote percentage threshold to: %s", kMinPercentMapVoteThreshold)
end)

Event.Hook("Console_td_solo",
function()

    kMinRequiredCommanderVolunteers = 1
    kMinRequiredLobbySizeServerRequest = 1
    kMaxWaitingCommandersStateTimeLimit = 3
    Log("td_solo test :)")
    
end)

Event.Hook("Console_td_fuach", function()
    Log("Force Achievements / Stats memory cache update...")
    Client.ForceUpdateAchievements()
    Client.UpdateInventory()
end)

Event.Hook("Console_td_dumpstats", function()
    local tpf = Client.GetUserStat_Int("td_total_time_player") or 0
    local tpc = Client.GetUserStat_Int("td_total_time_commander") or 0
    local fv = Client.GetUserStat_Int("td_rounds_won_player") or 0
    local cv = Client.GetUserStat_Int("td_rounds_won_commander") or 0
    Log("Current Thunderdome Steam-Stats:")
    Log("\t     Total Time Played:     %s", tpf)
    Log("\t  Total Time Commander:     %s", tpc)
    Log("\t     Total Wins Player:     %s", fv)
    Log("\t  Total Wins Commander:     %s", cv)
end)

-- Vigorously test shuffle behavior is correct / bug free with multiple permutations of players
Event.Hook("Console_td_test_shuffle", function(numPlayers, numGroups, group1Comm, group2Comm)
    local td = Thunderdome()

    if numPlayers == nil then
        Log("\ntd_test_shuffle [numPlayers 2..12] [numGroups 0..2] [group1Comm] [group2Comm]")
        return
    end

    if td.updateMode ~= td.kUpdateModes.LobbyOwner then
        SLog("Error: must be Lobby Owner to test team shuffle!")
        return
    end

    numPlayers = math.max(tonumber(numPlayers) or 12, 2)
    numGroups = tonumber(numGroups) or 2

    SLog("  numPlayers: %s, numGroups: %s, group1Comm: %s, group2Comm: %s",
        numPlayers, numGroups, group1Comm, group2Comm)

    --
    -- Generate random players for shuffle. Most parameters are random or configurable,
    -- but we ensure that there are always two commanders generated.
    --

    local function GenRandSteamId()
        local s = "7"
        for i = 1, 16 do
            s = s .. math.random(0,9)
        end
        return s
    end

    local function GenRandGroupId()
        local s = "15"
        for i = 1, 12 do
            s = s .. math.random(0,9)
        end
        return s
    end

    local playersList = {}
    local playersIndex = {}
    local groups = {}

    -- Make a random player and assign them to the players list and optionally a group
    local function MakeRandPlayerData(groupId, isCommander)
        -- Generate ...somewhat realistic skill values.
        -- 300 field player skill with 3,900 comm skill is an extreme outlier/synthetic value not really worth testing
        local skillAvg = math.random(10, 4000)
        local commAvg = math.random(math.max(skillAvg - 1000, 10), math.min(skillAvg + 1000, 4000))

        local player = {
            steamid = GenRandSteamId(),
            skill = skillAvg,
            commSkill = commAvg,
            team = 0,
            commander = isCommander,
            group = groupId or ""
        }

        table.insert(playersList, player)
        playersIndex[player.steamid] = player

        if groupId then
            table.insert(groups[groupId], player.steamid)
        end

        return player
    end

    local groupId1 = nil
    local groupId2 = nil

    if numGroups > 0 then
        groupId1 = GenRandGroupId()
        groups[groupId1] = {}
    end

    if numGroups > 1 then
        groupId2 = GenRandGroupId()
        groups[groupId2] = {}
    end

    -- Generate starting commanders first, to guarantee we always have volunteers
    MakeRandPlayerData(group1Comm and groupId1 or nil, true)
    MakeRandPlayerData(group2Comm and groupId2 or nil, true)

    -- Generate remaining players, filling groups as we go
    while #playersList < numPlayers do

        local groupId = nil
        -- random (somewhat small) chance for extra commander volunteers
        local isCommander = math.random(0, 4) == 0

        -- Try to evenly fill friends groups (for e.g. two groups but only five players)
        if groupId1 and groupId2 then
            groupId = ( #groups[groupId1] <= #groups[groupId2] ) and groupId1 or groupId2
        elseif groupId2 then
            groupId = groupId2
        elseif groupId1 then
            groupId = groupId1
        end

        -- Don't fill groups beyond their maximum size
        if groupId and #groups[groupId] >= kFriendsGroupMaxSlots then
            groupId = nil
        end

        MakeRandPlayerData(groupId, isCommander)

    end

    -- Sort the table so higher skills are processed first
    table.sort(playersList, function(a, b) return b.skill < a.skill end)

    SLog("  [Player List]")
    for p = 1, #playersList do
        SLog("       SteamID: %s", playersList[p].steamid)
        SLog("         Skill: %s", playersList[p].skill)
        SLog("     CommSkill: %s", playersList[p].commSkill)
        SLog("     Commander: %s", playersList[p].commander)
        SLog("         Group: %s", playersList[p].group)
        SLog("\n")
    end

    -- Perform the actual shuffle
    local commId1, commId2, set1, set2 = td.clientModeObject:PerformShuffle( playersList, groups, groupId1, groupId2 )

    -- Generate aggregate data
    local skills1 = {}
    local skills2 = {}

    for i = 1, #set1 do
        local player = playersIndex[set1[i]]
        player.team = 1

        table.insert(skills1, player.skill)
    end

    for i = 1, #set2 do
        local player = playersIndex[set2[i]]
        player.team = 2
        
        table.insert(skills2, player.skill)
    end

    -- There's no table.sum for some reason, so this will have to do
    local function sum(t)
        local s = 0
        for i = 1, #t do s = s + (t[i] and t[i] or 0) end
        return s
    end

    local delta = sum(skills1) - sum(skills2)
    local m_delta = table.mean(skills1) - table.mean(skills2)
    local md_delta = table.median(skills1) - table.median(skills2)

    -- Print reports

    SLog("=== [ POST-SHUFFLE ] ===")
    dumpSetsTable( { commId1 }, { commId2 }, "COMMANDER 1", "COMMANDER 2" )
    dumpSetsTable( set1, set2, "TEAM 1", "TEAM 2" )

    SLog("  (Shuffle Stats):")
    SLog("      Sum-Delta: %s", delta)
    SLog("     Mean-Delta: %s", m_delta)
    SLog("   Median-Delta: %s", md_delta)

end)
