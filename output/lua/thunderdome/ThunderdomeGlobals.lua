-- ======= Copyright (c) 2003-2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/thunderdome/ThunderdomeGlobals.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kBaseURI = "uwe-thunderdome.azurewebsites.net"      --PROD

kAuthHiveUrl = "https://" .. kBaseURI .. "/api/auth/"
kServerRequestUrl = "https://" .. kBaseURI .. "/api/servers/request/"
kServerRequestStatusUrl = "https://" .. kBaseURI .. "/api/servers/status/"
kServerRequestDetailsUrl = "https://" .. kBaseURI .. "/api/servers/details/"


kLobbyPlayersLimit = 12

kMinRequiredLobbySizeServerRequest = 12

--value to denote the % of members that must case a map-vote before voting is considered "valid"
kMinPercentMapVoteThreshold = 0.8   --% of
kMaxMapVoteAllowedTime = 60         --sec
kMaxMapVotingStateTimeLimit = 30    --sec

--Limits for WaitingForCommanders phase
kMinRequiredCommanderVolunteers = 2
kMaxWaitingCommandersStateTimeLimit = 15

-- Limit for UI on how long the timer should be when waiting for a server to spin up.
kServerSpinupTimerDuration = 300

kServerSpinupFailureTimeout = 300

-- Limit the number of times a client can fail to reconnect to a TD server before automatically leaving the lobby
kNumAllowedReconnectAttempts = 3

--Value to denote the maximum number of total client slots for TD servers
kThunderdomeServerSlotLimit = kLobbyPlayersLimit

kLobbyChatSendRate = 0.55

kMaxMapVoteCount = 3

kLeftTimePeriod = 15 * 60   --15m

--Amount of time the AFK-kicked prompt will display to user, warning them of penalty
kAfkPromptTimeoutPeriod = 50

--Fake SteamID to denote the System "user". Applicable mainly to lobby chat messages
kThunderdomeSystemUserId = 99999999

--Maximum size of returned search results list
kLobbySearchDefaultListSize = 15
kLobbySearchListSizeAttemptTick = 2
kLobbySearchMaxListSize = 50 --max size system will return
kLobbyMaxSkillSearchLimit = 2000


--Options key for the last Active LobbyId so clients can re-join if crash occurs
kOptionKey_CachedLobbyId = "thunderdome/lastActiveLobbyId"
kOptionKey_CachedLobbyConnAttempts = "thunderdome/lastActiveConnAttempts"
kOptionKey_CachedLobbyConnMade = "thunderdome/lastActiveConnMade"
kOptionKey_CachedLobbyGroupId = "thunderdome/lastLocalGroupId"
kOptionKey_CachedLobbyIsActive = "thunderdome/lastLobbyIsActive"
kOptionKey_CachedLobbyIsPrivate = "thunderdome/lastLobbyIsPrivate"

kThunderdomeRoundMaxTimeLimit = 60 * 60  --1hr      --TD Rounds cannot go longer than this (in seconds)
kForfeitRoundCheckingDelay = 60                     --amount of time before forfeit checking begin (from server startup)
kForfeitWarningActivateDelay = 60                   --amount of time from forfeit conditions met, to auto-concede
kForfeitMinServerTimeBeforeChecking = 25            --Minimum amount of time before any forfeit checks of any-type occur
kAbsoluteRoundTimeWarningStartTime = 60 * 2 --2m    --Num minutes before absoute round end when warning appears
--kForfeitActiveRatio = 4 / 6               --disparity ratio which triggers an auto-concede scenario - TBD

-- Time delay to wait for steam to return data about a foreign lobby before considering the operation failed.
kForeignLobbyTimeoutLimit = 2

-- Time delay between vote-kick requests accepted from a client
kVoteKickRequestCooldown = 30

-- Length (in seconds) for a vote kick to remain active
kVoteKickDuration = 60
-- Percentage of lobby members who must vote in favor to kick someone
kVoteKickThreshold = 0.6

--These types of events can be used for this class or others to register and be notified when they occur
--It's very important to note if any of these events are hooked to a class-function, the definition of
--the callback must be in "static" format (e.g. don't declare it via colon). 
--Also worth noting any GUI code should not use any of the OnXYZ events, rather it should use the OnGUIxyz ones.
kThunderdomeEvents = enum({

--System Internal Events ------------------------------------------------------

    --Event signifies for whatever reason, the local TD system failed to initalized correctly.
    --when this fires, all other events will cease to fire and the TD system is then unusable.
    --params: none
    'OnSystemInitFailed',

    --Occurs after calling ThunderdomeManager:GenerateSteamAuthTicket completes
    --params: none
    'OnAuthGenerated',

    --Signal lost conn to auth-source, and TD cannot proceed in any circumstance
    --params: none
    'OnAuthFailed',     --XX separate Auth & ReAuth failure events?

    --Call out to Hive API to fetch local-client profile data finished
    --params: none
    'OnLocalHiveProfileDataFetched',

    --Local-client's internal TD data initialization routine completed
    --params: none
    'OnLocalDataInitComplete',

    --Received a lobby data update from steam about a specific lobby that we're not part of.
    --param: (string) ID of the lobby we're receiving data about
    --param: (table) Lobby data received from steam, in { { key, value }, ... } format
    --param: (boolean) Is this data update for a lobby member or the lobby metadata
    --param: (string) ID of the lobby member we're receiving data
    'OnForeignLobbyDataUpdate',

    --Failed to receive lobby data for the given foreign lobby before timeout was reached.
    --param: (string) ID of the lobby we were attempting to retrieve data about
    'OnForeignLobbyDataTimeout',

    --Receive invite to a lobby while client running
    --param: (string) ID of lobby local-client was invited to
    --param: (string) SteamID64 of client that send the invitation
    'OnLobbyInviteReceive',

    --Steamworks lobby search completed, with results
    --params: none
    'OnSearchResults',

    --When local client changes their alias (Options or console)
    --params: none
    'OnClientNameChange',

    --Received chat message
    --param: (string) sender steamid64
    --param: (string) chat message
    'OnChatMessage',

    --Lobby "state" change
    --param: (integer) Previous lobby state
    --param: (integer) New/Current lobby state
    'OnStateChange',

    --Lobby game server data change
    --params: (string) server IP address and Port number ('ip:port')
    'OnServerChange',

    --Signifies local-client successfully created a New lobby (without initial meta-data)
    --params: none
    'OnLobbyCreated',

    --Local client's attempt to create a new Lobby failed (likely due to Steam downtime)
    --params: (integer) Enum value of Client.SteamLobbyCreateResult
    'OnLobbyCreateFailed',

    --Local client only, event triggered when client actually joins a lobby (regardless of how)
    --params: none
    'OnLobbyJoined',

    --Local client failed to successfully join a given LobbyID, likely due to it not existing anymore
    --params: (integer) Enum value of Client.SteamLobbyEnterResponse
    'OnLobbyJoinFailed',

    --Denotes local-client left their activeLobbyId steam lobby (mainly for UI state-update)
    --params: none
    'OnLeaveLobby',

    --A new user has join the lobby local-client is a member of
    --params: (string) steamId64 of user that joined
    'OnLobbyMemberJoin',

    --An existing lobby member left the lobby local-client is in
    --params: (string) steamId64 of user that left lobby
    'OnLobbyMemberLeave',

    --Denotes either owner, auto, or vote-kick removed member from lobby
    --params: (string) steamId64 of user that was kicked from lobby
    'OnLobbyMemberKicked',

    --A kick vote was started by the lobby owner
    --param: (string) steamId64 of user that will be kicked from the lobby
    --param: (string) steamId64 of the lobby user is being kicked from
    'OnLobbyKickStarted',

    --A kick vote was ended by the lobby owner
    --param: (string) steamId64 of the kick vote that just ended (kicked-user steamId64)
    --param: (string) steamId64 of the lobby vote ended in
    'OnLobbyKickEnded',

    --Signifies steam did not initialize on client start (steam outage)
    --params: none
    'OnSteamOffline',
    --On crash recover? (e.g. cached lob-id in sys opts file)

    --Trigged when lobby team-shuffle routine is completed and associated data fields are set with per-client 
    --team assignment. Each client must then handle their team assignment accordingly.
    --params: none
    'OnTeamShuffleComplete',

    --Triggered whenever local client performs a manual refresh of its Steam stats/achievements memory cache
    --params: none
    'OnUserStatsAndItemsRefreshed',
    
    --Triggers when a Friends-Group lobby's state changes from previous (no historical/stack compare)
    --params: New lobby state, Old lobby state
    'OnGroupStateChange',

    --Triggers after a short delay to load lobby state data when launching into a group/lobby
    --params: launch LobbyId
    'OnDelayedLaunchId',
    
--GUI Events ------------------------------------------------------------------

    --Triggered whenever TD is triggered (search, invite, etc.) while Hive has set the disabled flag
    --params: none
    'OnGUISystemDisabled',

    --When triggered, indicates local-client has lost their connection to Steam
    --params: none
    'OnGUISteamConnectionLost',

    --Event notifies GUI local-client's Hive profile data failed to pull. Thus
    --TD can never be utilized.
    --params: none
    'OnGUIHiveProfileFetchFailure',

    --Event notifies GUI local-client hive profile sucessfully retrieved
    --params: none
    'OnGUIHiveProfileFetchSuccess',

    --Simple pass-thru event for sending chat messages to GUI
    --params: (string) message
    'OnGUIChatMessage',

    --Signal search step completed and potentially joinable lobbies found
    --params: numWaiting, numPlaying
    'OnGUISearchResults',

    --Signal no lobbies found or results fubared
    --params: none
    'OnGUISearchFailed',

    --Signal no lobbies found, prompt to create (eh)
    --params: none
    'OnGUISearchExhausted',

    --Signal new lobby was created, but no data has been populated to it yet
    --params: none
    'OnGUILobbyCreated',

    --Indicates to GUI the lobby-create attempt failed for X reasons, see bindings enum
    --params: integer (reason code)
    'OnGUILobbyCreateFailed',

    --Indicates to GUI local-client has successfully joined a lobby
    --params: none
    'OnGUILobbyJoined',

    --GUI event to denote joining a lobby (by invite or search) failed, likely due to sudden Steam outage, or invalid lobby-id
    --params: (integer) Enum value of Client.SteamLobbyEnterResponse
    'OnGUILobbyJoinFailed',

    --GUI event to denote a new client has joined (or potentially re-joined) active lobby
    --param: (string) SteamID64
    'OnGUILobbyMemberJoin',

    --GUI event for when local-client leaves their lobby by any means
    --params: none
    'OnGUILeaveLobby',

    --GUI event for when local-client was kicked from their previous lobby
    --params: (string) lobby SteamID64
    'OnGUILobbyKicked',

    --GUI event to denote current member has left active lobby
    --param: (string) SteamID64
    'OnGUILobbyMemberLeave',

    --GUI event to denote a current member of active lobby was kicked
    --param: (string) SteamID64
    'OnGUILobbyMemberKicked',

    --GUI event triggered when a kick-player vote has been started in a lobby
    --param: (string) SteamID64
    'OnGUILobbyKickVoteStarted',

    --GUI event triggered when a kick-player vote has been ended in a lobby
    --param: (string) SteamID64
    'OnGUILobbyKickVoteEnded',

    --GUI event to trigger while in-game and local-client receives a Lobby invitation, meant to produce a pop-up
    --params: LobbyID (string), InviterID (string - SteamID64), InviterName (string)
    'OnGUILobbyInviteReceived',

    --TODO
    --param: (string) SteamID64
    --'OnGUILobbyMemberBanned',

    --Simple signal to GUI to trigger it to enable/activate Map Voting UI components
    --params: none
    'OnGUIMapVoteStart',

    --For triggering GUI update to denote X stage of match-process
    --params: (integer) Vote result, map-index from kThunderdomeMaps enum
    'OnGUIMapVoteComplete',

    --For phase when players must volunteer to be Commanders before process continues
    --params: none
    'OnGUICommandersWaitStart',

    --To denote the Commander have volunteered and process can continue
    --params: none
    'OnGUICommandersWaitEnd',

    --Denotes that the minimum number of commanders is set for the WaitingForCommanders phase
    --params: none
    'OnGUIMinRequiredCommandersSet',

    --Trigger to GUI to denote that match is awaiting Server to be instanced
    --params: none
    'OnGUIServerWaitStart',

    --Only triggered when servers fail to be requested or initialized within X time or Y error code
    --params: none
    'OnGUIServerWaitFailed',

    --Triggers when local-client has attempted a connection to Lobby server, but failed to connect.
    --This should only be triggered after the Main VM has reloaded.
    --params: none
    'OnGUIServerConnectFailed',

    --Trigger to GUI to denote that Server is ready to join, and connection about to happen
    --params: none
    'OnGUIServerWaitComplete',

    --Prompts GUI to display confirmation to try to reconnect to lobby-server after a crash-scenario
    --params: none
    'OnGUIServerReconnectPrompt',

    --Denotes a member's meta-data has changed
    --param: (string) SteamID64
    'OnGUILobbyMemberMetaDataChange',

    --For signaling results, and rematch votes, etc
    --params: none
    'OnGUIRoundComplete',   --??? Actually needed?

    --For rematch vote prompting, leave match, new map vote, etc
    --params: none
    'OnGUIMatchComplete',

    --Simple indicator for all lobby members to notify them the entire process (regardless of where/why) has
    --failed and cannot proceed. Timer event should be triggered from GUI scope to signify they'll be kicked
    --back to main menu in a moment
    --params: none
    'OnGUIMatchProcessFailed',

    --Indicates the local client tried to change lobby-owners but failed. Typically, this should only trigger
    --when there is only one member left, or all possible owners have been cycled through. This is for the 
    --current Local client only, not non-owner members.
    --params: none
    'OnGUIOwnerChangeFailed',

    --Triggers when local-client penalty state has changed
    --params: (boolean) penalty state
    'OnGUIPenaltyStateChanged',

    --Triggers when local-client has a penalty encurred and is fired when attempting to use TD
    --params: none
    'OnGUIPenaltyIsActive',

    --Simple pop-up style event, used to notify local-client they have an active TD ban
    --params: none
    'OnGUIThunderdomeIsBanned',

    -- Lobby has rolled back it's state to WaitingForPlayers
    'OnGUILobbyStateRollback',

    -- TD System message to trigger AFK-Kick warning/notification to local-client
    'OnGUIAfkKickedPrompt',
    
    --GUI-scope on client load event which is only ever triggered after TDMgr has completed its initial loading-steps
    'OnMenuLoadEndEvents',

    --GUI-scope, warning client they have been forcibly disconnected from current Public Lobby due to lifespan
    'OnGUIMaxLobbyLifespanNotice',

    --Notification for the user that the lobby invite they've tried to join points to an invalid lobby
    --(e.g. wrong build, version, full, etc)
    --params: none, may be expanded in future to provide a reason enum
    'OnGUILobbyInviteInvalid',

    --GUI-scope, indicative of a Friends-Group lobby's state changed (for Status bar updates, etc.)
    --params: New lobby state, Old lobby state
    'OnGUIGroupStateChange',

    -- Lobby has rolled back it's state to WaitingForPlayers
    'OnGUIGroupStateRollback',

})


kThunderdomeMaps = enum({
    "ns2_ayumi",
    "ns2_biodome",
    "ns2_caged",
    "ns2_eclipse",
    "ns2_derelict",
    "ns2_descent",
    "ns2_docking",
    "ns2_kodiak",
    "ns2_metro",
    "ns2_mineshaft",
    "ns2_origin",
    "ns2_refinery",
    "ns2_summit",
    "ns2_tanith",
    "ns2_tram",
    "ns2_unearthed",
    "ns2_veil",
    "RANDOMIZE"
})

-------------------------------------------------------------------------------
-- Lobby Data, Models, and Member Model globals -------------------------------

--Note: the order which the enum keys are set is important, do not change
kLobbyState = enum({ 

    --Public & Private lobbies
    'WaitingForPlayers',         --In lobby, but more players required
    'WaitingForCommanders',      --Waiting for Commanders to be selected / volunteer
    'WaitingForExtraCommanders', --Waiting for Extra Commanders to be selected / volunteer (Min commanders reached, giving chance for extra volunteers)
    'WaitingForMapVote',         --Have required players, awaiting map vote completed
    'WaitingForServer',          --Waiting for system to spawn server instance. Note: this doubles as 'Planning' stage
    'Ready',                     --Server is ready, all voting done, clients should join
    'Playing',                   --Client on a TD-server and playing round(s)
    'Finalized',                 --All matches complete and system is cleaning this (and its server)
    'Failed',                    --Signifies system or data corruption, means no games can be played on this lobby

    --Friend Group Lobbies
    'GroupWaiting',             --Waiting for slots to fill
    'GroupSearching',           --looking for applicable lobby via search
    'GroupReady',               --Public lobby match found, ready to group-join

})

--Enum indicator used as per-memeber flags to indicate which lifeforms they intend to play as
kLobbyLifeformTypes = enum({ 'Skulk','Gorge','Lerk','Fade','Onos' })

--Note: all the data types of the LobbyMember fields are cast TO this when read
--all data is written as strings
LobbyMemberModelFields = enum({
    'Name',             --string:       'Jimmy'
    'SteamID64',        --string:       '7390282784849138323'
    'Coords',           --table[1,2]:   -38.1, 78.2
    'MapVotes',         --string:       '2,1,7' --comm delimted field of Map ID values, or [max] to denote randomize, see kThunderdomeMaps for index values
    'AvgSkill',         --integer
    'Adagrad',          --float         '0.0032893781'
    'MarineSkill',      --integer
    'AlienSkill',       --integer
    'MarineCommSkill',  --integer
    'AlienCommSkill',   --integer
    'JoinedServer',     --integer       simple 0/1 flag to indicate if a Member has started the server-connect process
    'Team',             --integer       1/2 indicates which team client was shuffled to, and can be used for chat filtering
    'IsCommander',      --integer       0/1 simple flag to indicate this client was selected to be Commander during shuffle
    'Lifeforms',        --string        UI/UX data to show what lifeforms player prefers for Alien team
    'CommanderAble',    --integer       0/1 flag to denote player is willing to Command
    'JoinTime',         --integer       timestamp of when the member has joined the lobby
    'GroupId'           --string        (optional) Indicates this client is part of a frinds-group
})

--This is the only lobby member field that's actually written to Steam lobby meta-data (per-member)
--the data written to this field is serialized. By doing this, it dramatically reduces the number
--of Steamworks API calls needed (thus callback results/events) to update member data.
kLobbyMemberModelDataSyncField = "player_data"

--Single field for Lobby meta-data to be assigned to. This should only ever be a string which
--is a serialized LobbyModel object (json format). All clients read from this, Owners update it.
kLobbyModelSyncField = "data"
kLobbyModelFieldBuild = "build"
kLobbyModelFieldBranch = "branch"
kLobbyModelFieldVersion = "version"

kLobbyServerStatusCreating = "Creating"
kLobbyServerStatusReady = "Ready"

--Max number of times Owner client is allowed to query for server-status, before owner handoff
kMaxLobbyOwnerStatusAttempts = 5

--This is used so the fields can be easily referenced without using their string value
--and maintains simple and consistent naming / access method
LobbyModelFields = enum({
    'Id', 
    'Build',
    'SteamBranch',
    'Version',
    'Type',

    'State',
    'StateChangeTime',

    'Coords',

    'NumMembers',   --TODO Remove usage

    --Special field that's only applicable to local-client context (not synchronized across lobby members)
    'LocalDistance',

    --Simple list to indicate all members that have been or currently are lobby owner
    --This set is used when determining which member to assign ownership when current owner changes (leave, failed, etc)
    'PrevOwners',

    --LobbyOwner related fields. Can be updated by any clients that are owners
    'ServerReqId',              --string
    'ServerReqAttempts',        --integer
    'ServerReqStatus',          --string
    'LastSrvReqTime',           --integer

    --Game Server data (only populated once in valid state & votes completed)   --!!! Populating this would allow for mods to easily bypass "protections" and join as is...not good
    'ServerIP', 
    'ServerPort',
    'ServerPassword',

    --Field holds the final result of map-voting stage (see kThunderdomeMaps for possible values)
    'VotedMap',

    --Numeric index serialized string of member SteamID64s denoting which team they've been assigned to
    --Each member object must listen and then update their own data so their client can act accordingly
    'ShuffledTeam1',
    'ShuffledTeam2',

    --"Dumb" fields that hold the Steam64ID of shuffled clients that were selected for Commander role
    'Team1Commander',
    'Team2Commander',

    --String comma separated list of SteamIDs that have been vote-kicked from a lobby
    'Kicked',

    --State table for active kick vote (for e.g. owner swapping/late-joins)
    'ActiveKick',

    --The integer value of all members avg-skill (represents lobby/group skill)
    'MedianSkill',  --Note: this doubles as average skill when in group-queue mode


    --Only applicable to Group Queue, used to pass LobbyID to clients from match search
    'TargetLobbyId',

    --Number of unique friend-groups in a lobby, see kLobbyGroupsLimit
    'NumGroups',
    
    --Bool that is only applicable when a lobby is serving as a Friends-group
    'IsGroup',
})


kTDErrorReportUrl = "http://skymarshal.naturalselection2.com/api/td/errors"


--Thunderdome Stats Fields
kThunderdomeStatFields_TimePlayed = "td_total_time_player"
kThunderdomeStatFields_TimePlayedCommander = "td_total_time_commander"
kThunderdomeStatFields_Victories = "td_rounds_won_player"
kThunderdomeStatFields_CommanderVictories = "td_rounds_won_commander"


-------------------------------------------------------------------------------
-- Group Queuing Data

--Total number of slots in a group (joinable)
kFriendsGroupMaxSlots = 3

--Minimum number of players in a group to allow searching for a match
kFriendsGroupMinMemberCountForSearch = 2

--No lobby can have more than two groups in it. Discard if hit when searching.
kLobbyGroupsLimit = 2

--Used for GUI config to set the "use case" of chat windows
kLobbyUsageType = enum({ 'Match', 'Group' })


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


if Server and Shared.GetThunderdomeEnabled() then
    Script.Load("lua/thunderdome/ProgressionData.lua")
end
