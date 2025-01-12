-- ======= Copyright (c) 2003-2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/thunderdome/LobbyClientMember.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")

Script.Load("lua/thunderdome/LobbyUtils.lua")

Script.Load("lua/thunderdome/LobbyMemberModel.lua")
Script.Load("lua/thunderdome/LobbyModel.lua")

Script.Load("lua/thunderdome/ClientLobbyFunctors.lua")


-------------------------------------------------------------------------------


class 'LobbyClientOwner'


--Amount of time needed to pass before owner-client will query for the requested server's status
LobbyClientOwner.kServerStatusQueryInterval = 15    --seconds, avg spin-up time assumed to be 3m 40s

--Minimum number of seconds that must pass after successful server request completed, before status queries can start
LobbyClientOwner.kMinStatusQueryDelay = 60

--Small padding to increase time between status chek intervals
LobbyClientOwner.kServerStatusFailStepTime = 3
LobbyClientOwner.kMaxLocalLimitRequestServer = 3
LobbyClientOwner.kServerRequestRetryDelay = 20


function LobbyClientOwner:Initialize()
    SLog("-LobbyClientOwner:Initialize()")

    --flag to denote lobby geo-coords can no longer be updated (due to state)
    self.lobbyCoordsLocked = false

    --simple flag to prevent update steps from progressing until complete
    self.activeServerRequestAttempt = false

    --simple flag to denote an attempt to fetch requested server status is underway
    self.activeServerQuery = false

    --Each time a client becomes an owner, fetch the number of Server Request Attempts from Lobby (or default to zero)
    --Used to track how many times LOCAL client has tried to get a successfull request, and used to fail-over to another
    --client if it fails (e.g. local-client not allowed to make outbound HTTP calls...HTTP call just failed, etc, etc.)
    self.numLocalServerReqAttempts = 0

    --Local-client value only (not propagated) to know how many times it has pinged TD for requested server status
    self.numLocalServerStatusAttempts = 0
    --FIXME Need tracking of "was at X when I took over" and compare

    --Number of local attempts made to retrieve details of requested server
    self.numLocalServerDetailsAttempts = 0

    --Local-client timestamp of when it requested the server status, used to prevent it from spamming backend
    self.lastServerQueryTime = 0

    --Default to NOT allowing voting (for now), and only when state allows
    self.mapVotingLocked = false

    --simple flag to keep track of when mininum commanders have been set, so we can send a event for GUI
    self.minCommandersSet = false

    self:RegisterEvents()

end

function LobbyClientOwner:Destroy()
    SLog("-LobbyClientOwner:Destroy()")
    self:UnRegisterEvents()
end

function LobbyClientOwner:RegisterEvents()
    SLog("-LobbyClientOwner:RegisterEvents()")
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyCreated, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyCreated] )
    Thunderdome_AddListener( kThunderdomeEvents.OnStateChange, kLobbyClientFunctors[kThunderdomeEvents.OnStateChange] )
    Thunderdome_AddListener( kThunderdomeEvents.OnTeamShuffleComplete, kLobbyClientFunctors[kThunderdomeEvents.OnTeamShuffleComplete] )
    Thunderdome_AddListener( kThunderdomeEvents.OnClientNameChange, kLobbyClientFunctors[kThunderdomeEvents.OnClientNameChange] )
    Thunderdome_AddListener( kThunderdomeEvents.OnChatMessage, kLobbyClientFunctors[kThunderdomeEvents.OnChatMessage] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyJoined, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoined] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyJoinFailed, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoinFailed] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberJoin, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberJoin] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberLeave, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberLeave] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberKicked, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberKicked] )

end

function LobbyClientOwner:UnRegisterEvents()
    SLog("-LobbyClientOwner:UnRegisterEvents()")
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyCreated, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyCreated] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnStateChange, kLobbyClientFunctors[kThunderdomeEvents.OnStateChange] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnTeamShuffleComplete, kLobbyClientFunctors[kThunderdomeEvents.OnTeamShuffleComplete] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnClientNameChange, kLobbyClientFunctors[kThunderdomeEvents.OnClientNameChange] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnChatMessage, kLobbyClientFunctors[kThunderdomeEvents.OnChatMessage] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyJoined, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoined] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyJoinFailed, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoinFailed] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberJoin, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberJoin] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberLeave, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberLeave] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberKicked, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberKicked] )
end

--Do not trigger meta-update, work with what we've got now. Otherwise...more delays, more states...
function LobbyClientOwner:ForcedMemberModelUpdate( td )
    SLog("LobbyClientOwner:ForcedMemberModelUpdate()")
    assert(td)

    td.activeLobby:FlushAllMembers()

    local members = {}
    if not Client.GetLobbyMembersList( td.activeLobbyId, members ) then
        assert(false, "Error: Failed to read members list from active lobby")   --TD-FIXME This should trigger a bail-out / owner-swap
    end
    
    for i = 1, #members, 1 do
        local memberId = members[i]
        local memData = Client.GetLobbyMemberData( td.activeLobbyId, memberId, kLobbyMemberModelDataSyncField )
        assert(memData, "Error: member data failed to fetch or was empty")
        local member = LobbyMemberModel()
        member:Init()
        member:Deserialize(memData)
        td.activeLobby:AddMemberModel(member)
    end

end


-------------------------------------------------------------------------------
-- Lobby Update Routines

-- Count the number of valid commanders which can be selected by the team shuffle
-- routine. Multiple commanders from a single friends-group only count as one
-- commander, as the shuffle algorithm will place all members of a friends-group
-- on a single team.
function LobbyClientOwner:CountNumCommanders( lobby )

    local awesomePeople = 0
    local members = lobby:GetMembers()

    local groupId1 = nil
    local groupId2 = nil

    for i = 1, #members do
        local willingComm = members[i]:GetField( LobbyMemberModelFields.CommanderAble )
        if willingComm and type(willingComm) == "number" and willingComm == 1 then

            -- No more than one commander from a specific friends-group in the lobby can be
            -- a valid commander for the friends-group to be put on a single team; filter to
            -- ensure we have at least two non-affiliated commanders.
            local groupId = members[i]:GetField( LobbyMemberModelFields.GroupId )
            if groupId and groupId ~= "" then
                if ( groupId1 and groupId == groupId1 ) or ( groupId2 and groupId == groupId2 ) then
                    -- disregard this player.
                else
                    -- This is a valid commander vote, but the same friends-group cannot be
                    -- counted towards a valid commander again
                    if not groupId1 then
                        groupId1 = groupId
                    else
                        groupId2 = groupId
                    end

                    awesomePeople = awesomePeople + 1
                end
            else
                awesomePeople = awesomePeople + 1
            end

        end
    end

    return awesomePeople

end

function LobbyClientOwner:CollectMapVotes(members)  --TD-TODO Improve this, with a full lobby, this will be approx 460 loops...
    assert(members)

    local mapVotes = {} --iterdict?
    local votedMap

    local rank1 = 3
    local rank2 = 2
    local rank3 = 1

    --Build sorting table
    for i = 1, #kThunderdomeMaps do
        local map = tostring(kThunderdomeMaps[i])
        table.insert( mapVotes, { map = map, count = 0 } )
    end

    local function AddVote(voteRank, map)
        local mapWeight = 0
        if voteRank == rank1 then
            mapWeight = rank1
        elseif voteRank == rank2 then
            mapWeight = rank2
        else
            mapWeight = rank3
        end

        for i = 1, #mapVotes do
            if mapVotes[i].map == map then
                mapVotes[i].count = mapVotes[i].count + mapWeight
                break
            end
        end
    end

    --Loop over members, and tally votes
    for m = 1, #members do
        --each member vote is weighted first to last
        local votes = members[m]:GetField( LobbyMemberModelFields.MapVotes )
        if votes ~= "" then
            local v = StringSplit(votes, ",")
            
            AddVote( rank1, v[1] )

            if v[2] then
                AddVote( rank2, v[2] )
            end
            if v[3] then
                AddVote( rank3, v[3] )
            end
        end
    end

    local function SortVotes(a, b)
        return a.count > b.count --desc order
    end
    table.sort(mapVotes, SortVotes)
    
    if mapVotes[1].count > 0 then
        return mapVotes[1].map
    end
    return false    --no map-vote data set by members yet
end


--Computes the total weighted values of all ST (Standard Tally) map votes and updates lobby
--Note: this should only be called once map voting should be stopped/unallowed
function LobbyClientOwner:UpdateLobbyMapVote( thunderdome )
    SLog("-LobbyClientOwner:UpdateLobbyMapVote()")
    assert(thunderdome)

    if self.mapVotingLocked then
        return
    end

    local lobby = thunderdome:GetActiveLobby()
    local curSelMap = lobby:GetField( LobbyModelFields.VotedMap )
    SLog("\t\t curSelMap: %s", curSelMap)
    local members = lobby:GetFilteredMembers( thunderdome:GetLoadedMembersList( lobby:GetId() ) )

    local votedMap = self:CollectMapVotes(members)
    if votedMap and votedMap ~= "" and votedMap ~= curSelMap then
        if votedMap == tostring(kThunderdomeMaps[#kThunderdomeMaps]) then
        --randomize map
            if not self:SelectRandomMap(thunderdome) then
                return false
            end
        else
            thunderdome.activeLobby:SetField( LobbyModelFields.VotedMap, votedMap )
            thunderdome:TriggerLobbyMetaDataUpload( thunderdome.activeLobbyId )
        end
        SLog("\t Voted Map: %s", votedMap)
        return true
    else
        return false -- no votes
    end
end

function LobbyClientOwner:SelectRandomMap( thunderdome )
    Log("LobbyClientOwner:SelectRandomMap()")
    assert(thunderdome, "Error: No Thunderdome object found")

    if self.mapVotingLocked then
        Log("ERROR: Random map selection triggered while map-voting locked!")
        return false
    end

    local mapTicks = {}
    local itrs = math.random(150,250)

    for d = 1, itrs do
        local idx = math.random(1,15)
        local map = tostring(kThunderdomeMaps[idx])
        table.insert( mapTicks, map )
    end

    local mapsCounts = {}
    for i = 1, #kThunderdomeMaps do
        local map = tostring(kThunderdomeMaps[i])
        table.insert( mapsCounts, { map = map, count = 0 } )
    end

    for i = 1, #mapTicks do
        local map = mapTicks[i]
        for m = 1, #mapsCounts do
            if map == mapsCounts[m].map then
                mapsCounts[m].count = mapsCounts[m].count + 1
            end
        end
    end

    table.sort(
        mapsCounts,
        function(a, b)
            return a.count > b.count --desc
        end
    )
    
    local idx = math.random(1,3)
    SLog("\t  Random Map Selected:  %s", mapsCounts[idx].map)
    thunderdome.activeLobby:SetField( LobbyModelFields.VotedMap, mapsCounts[idx].map )
    thunderdome:TriggerLobbyMetaDataUpload( thunderdome.activeLobbyId )

    return true
end

--Updates lobby data with the total-members median Average skill (not team-centric)
function LobbyClientOwner:UpdateLobbyMedianSkill( td )
    assert(td, "Error: No Thunderdome object found")
    
    local lobby = td:GetActiveLobby()
    local prevSkillMed = lobby:GetField( LobbyModelFields.MedianSkill )
    local members = lobby:GetFilteredMembers( td:GetLoadedMembersList( lobby:GetId() ) )
    local skills = {}

    for i = 1, #members do
        local mAvgSk = members[i]:GetField( LobbyMemberModelFields.AvgSkill )
        if mAvgSk and type(mAvgSk) == "number" then
            table.insert( skills, mAvgSk )
        end
    end
    
    local lobbyMedSkill = math.max(0, math.floor(table.median(skills)))

    if lobbyMedSkill ~= prevSkillMed then
    --if any difference, update values otherwise ignore
        SLog("\t\t LobbyClientOwner - Median skill changed, updated...")
        td.activeLobby:SetField( LobbyModelFields.MedianSkill, lobbyMedSkill )
        td:TriggerLobbyMetaDataUpload( td.activeLobbyId )
    end
end

--Reads all member data, and collects the number of groups current lobby has, sets meta-data
function LobbyClientOwner:UpdateLobbyGroupCounts( td )
    assert(td, "Error: No Thunderdome object found")

    local lobby = td:GetActiveLobby()
    local members = lobby:GetFilteredMembers( td:GetLoadedMembersList( lobby:GetId() ) )
    local groupIds = {}

    for i = 1, #members do
        local memGrpId = members[i]:GetField( LobbyMemberModelFields.GroupId )
        if type(memGrpId) == "string" and memGrpId ~= "" then
        --we don't care of order, only unique count
            table.insertunique( groupIds, memGrpId )
        end
    end

    if #groupIds > kLobbyGroupsLimit then   --TD-FIXME This will need to perform some kind of "cull" if this ever occurs
        SLog("ERROR: Lobby unique group-id count exceeds limit!")
    end

    td.activeLobby:SetField( LobbyModelFields.NumGroups, #groupIds )
    td:TriggerLobbyMetaDataUpload( lobby:GetId() )
end

--Updates the Lobby's Geo centroid coordinates based on all member's geo-coords
--Note: this won't always include all member's data. If they recently joined
--their data won't have propagated yet.
function LobbyClientOwner:UpdateLobbyGeoCoords( thunderdome )
    assert(thunderdome)

    if self.lobbyCoordsLocked then
        return
    end

    local lobby = thunderdome:GetActiveLobby()
    local members = lobby:GetFilteredMembers( thunderdome:GetLoadedMembersList( lobby:GetId() ) )
    local coordSet = {}

    for i = 1, #members do
        local memCoord = members[i]:GetField( LobbyMemberModelFields.Coords )
        if type(memCoord) == "table" and #memCoord == 2 then
        --must check the type and size of the data, as member might've just joined, and not updated yet
            table.insert( coordSet, memCoord )
        end
    end

    if #coordSet == 0 then
        SLog("LobbyClientOwner:UpdateLobbyGeoCoords(): Warning: no member coordinates available, lobby member models not loaded?")
        return
    end

    local newLat, newLong = ComputeCenterGeoCoord(coordSet)
    assert(newLat and newLong)

    local setCoords = lobby:GetField( LobbyModelFields.Coords )
    if newLat ~= setCoords[1] or newLong ~= setCoords[2] then
    --Only update the value if it's actually different (prevent meta-data updated event unless required)
        local lobCoordStr = newLat .. "," .. newLong
        --SLog("\t\t Computed geo-center of lobby: (%s)", lobCoordStr)
        thunderdome.activeLobby:SetField( LobbyModelFields.Coords, lobCoordStr )
        thunderdome:TriggerLobbyMetaDataUpload( thunderdome.activeLobbyId )
    end
end


local function GetUniqueLobbyGroups( players )
    SLog("|S|   GetUniqueLobbyGroups()")
    --build group list(s) for compares
    local group1 = nil
    local group2 = nil

    for g = 1, #players do
        local pGrp = players[g].group

        if pGrp ~= "" then
            if group1 == nil then
                group1 = pGrp
                SLog("     Set GroupID-1: %s", pGrp)

            elseif group2 == nil and pGrp ~= group1 then
                group2 = pGrp
                SLog("     Set GroupID-2: %s", pGrp)
            end
        end
    end

    return group1, group2
end


--?? localized params/config?
function LobbyClientOwner:UpdateTeamShuffle( thunderdome )
    SLog("-- LobbyClientOwner:UpdateTeamShuffle()")
    assert(thunderdome)

    local lobby = thunderdome:GetActiveLobby()  --read-only
    assert(lobby, "Error: calling UpdateTeamShuffle in inactive lobby!")
    
    local members = lobby:GetMembers()
    assert(members, "Error: Missing lobby members list")
    
    --For sanity sake, always force local(owner) client to rebuild member list and its data, from _current_ lobby meta-data
    self:ForcedMemberModelUpdate( thunderdome )
    members = thunderdome.activeLobby:GetMembers()
    assert(#members == Client.GetNumLobbyMembers(lobby:GetId()), "Error: member list mismatch after flush and forced update")

    local playersList = {}
    --Build list of player data in sorting friendly format
    for i = 1, #members do
        local member = members[i]

        local skillAgg =        --member:GetField( LobbyMemberModelFields.AvgSkill )
            math.max( member:GetField( LobbyMemberModelFields.MarineSkill ), member:GetField( LobbyMemberModelFields.AlienSkill ) )

        local commSkillAgg = 
            math.max( member:GetField( LobbyMemberModelFields.MarineCommSkill ), member:GetField( LobbyMemberModelFields.AlienCommSkill ) )

        table.insert( playersList, 
            { 
                skill = skillAgg,
                commSkill = commSkillAgg,
                team = 0,
                steamid = member:GetField( LobbyMemberModelFields.SteamID64 ), 
                commander = member:GetField( LobbyMemberModelFields.CommanderAble ) == 1,        --denotes volunteered
                group = member:GetField( LobbyMemberModelFields.GroupId ) 
            }
        )
    end
    
    --ease of parsing, as higher deltas worked first
    table.sort( playersList, 
        function(a, b)
            return b.skill < a.skill    --desc
        end
    )


    local groupId1, groupId2 = GetUniqueLobbyGroups( playersList )
    SLog("      Group 1 ID: %s", groupId1)
    SLog("      Group 2 ID: %s", groupId2)


    --cache list for reference tests for swapping players
    local groups = {}
    if #groups == 0 then
        if groupId1 then
            groups[groupId1] = {}
        end

        if groupId2 then
            groups[groupId2] = {}
        end
    end
    
    for g = 1, #playersList do
        if playersList[g].group ~= "" and groups[playersList[g].group] then
            table.insert( groups[playersList[g].group], playersList[g].steamid )
        end
    end

    --[[
    SLog("\n[Player Groups]\n")
    if groups[groupId1] or groups[groupId2] then
        dumpSetsTable( groups[groupId1], groups[groupId2], "Group I", "Group II" )
    else
        SLog("\t NONE")
    end
    SLog("\n")
    --]]

    local commId1, commId2, set1, set2 = self:PerformShuffle( playersList, groups, groupId1, groupId2 )

    thunderdome.activeLobby:SetField( LobbyModelFields.Team1Commander, commId1 )
    thunderdome.activeLobby:SetField( LobbyModelFields.Team2Commander, commId2 )

    if #set1 > 0 then
        thunderdome.activeLobby:SetField( LobbyModelFields.ShuffledTeam1, set1 )
    end

    if #set2 > 0 then
        thunderdome.activeLobby:SetField( LobbyModelFields.ShuffledTeam2, set2 )
    end

    SLog("**** Writing team-shuffle meta-data...")
    thunderdome:TriggerLobbyMetaDataUpload( thunderdome.activeLobbyId )
end

-- Shuffle a list of players who may or may not be in groups.
--
-- Note: as a precondition to this function, if a player is present in the `groups` table,
-- they must also be present in the `playersList` table and have identical table contents.
--
-- Parameters:
---  @param playersList table array of player data from UpdateTeamShuffle
---  @param groups table contains up to two player lists for group-specific players indexed by groupId
---  @param groupId1 string|nil SteamLobby ID of the first player group in this lobby
---  @param groupId2 string|nil SteamLobby ID of the second player group in this lobby
-- Returns:
---  commId1 - string, player steamId for team 1 commander
---  commId2 - string, player steamId for team 2 commander
---  set1    - unsorted array table of steamIds for team 1 players (incl. commander)
---  set2    - unsorted array table of steamIds for team 2 players (incl. commander)
function LobbyClientOwner:PerformShuffle( playersList, groups, groupId1, groupId2 )
    SLog(" - LobbyClientOwner:PerformShuffle()")

    local assignedList = {} --finalized list target
    local rollingSkillDiff = 0
    local teamCount = { 0, 0 }
    local maxTeamSize = math.ceil( #playersList / 2 )
    local kTeamSign = { [kTeam1Index] = 1, [kTeam2Index] = -1 }

    --[[
    local function GetGroupPlayers( groupId )
        return groups[groupId]
    end

    local function GetIsPlayerInGroup( steamid )
        return 
            table.icontains( groups[groupId1], steamid ) or 
            table.icontains( groups[groupId2], steamid )
    end
    --]]
    
    --Now deal with commanders and "pre" assign them
    local comms = {}
    for _, player in ipairs(playersList) do
        if player.commander then
            table.insert(comms, player)
        end
    end

    table.sort(comms, function(a, b)
        return b.commSkill < a.commSkill        --abs to deal with +/- of offsets?
    end)

    local commId1 = nil
    local commId2 = nil
    local comm1 = nil
    local comm2 = nil

    --Assume Marine comm should be highest, yup...
    ----
    --FIXME This MUST verify two selected Commanders are NOT in the same Group...if they are, randomly pick another (non-group or other)
    --...however, ALL Group members must ALWAYS be in the same team, no matter what.
    --STURNCLAW: commander selection should now properly handle potential comms being in the same group.
    ----
    commId1 = comms[1] and comms[1].steamid or nil
    comm1 = comms[1] or nil

    -- If the first commander is in a group, ensure that the other commander is not
    -- part of the first commander's group.
    if comm1 and comm1.group ~= "" then
        for i = 2, # comms do
            if comms[i].group ~= comm1.group then
                commId2 = comms[i].steamid
                comm2 = comms[i]
                break
            end
        end
    else
        -- Otherwise, just pick the next highest commander if present
        commId2 = comms[2] and comms[2].steamid or nil
        comm2 = comms[2] or nil
    end
    
    ---[[
    SLog("  [COMMANDERS]")
    if commId1 then
        SLog("    commander 1 ID:        %s", commId1)
        SLog("    commander 1 skill:     %s", comm1.skill)
        SLog("    commander 1 commSkill: %s", comm1.commSkill)
        SLog("    commander 1 groupId:   %s", comm1.group)
    end
    if commId2 then
        SLog("    commander 2 ID:        %s", commId2)
        SLog("    commander 2 skill:     %s", comm2.skill)
        SLog("    commander 2 commSkill: %s", comm2.commSkill)
        SLog("    commander 2 groupId:   %s", comm2.group)
    end
    if not commId1 or not commId2 then
        SLog("    Not enough commanders!")
    end
    --]]

    --[[
    SLog("\n")
    if commId1 and commId2 then
        dumpSetsTable( { commId1, comms[1].skill, comms[1].commSkill }, { commId2, comms[2].skill, comms[2].commSkill }, "Commander 1", "Commander 2" )
    elseif commId1 and not commId2 then

    elseif commId2 and not commId1 then

    end
    SLog("\n")
    --]]
    
    if commId1 then
        teamCount[kTeam1Index] = 1
        assignedList[ #assignedList + 1 ] =
        {
            steamid = comm1.steamid,
            skill = comm1.skill,
            commSkill = comm1.commSkill,
            team = kTeam1Index,
            group = comm1.group,
            commander = true,
            locked = true,
        }
    end

    if commId2 then
        teamCount[kTeam2Index] = 1
        assignedList[ #assignedList + 1 ] =
        {
            steamid = comm2.steamid,
            skill = comm2.skill,
            commSkill = comm2.commSkill,
            team = kTeam2Index,
            group = comm2.group,
            commander = true,
            locked = true,
        }
    end

    --Update all players to not flag as Commanders, now we've picked them
    for i = 1, #playersList do
        if playersList[i].steamid ~= commId1 and playersList[i].steamid ~= commId2 then
            playersList[i].commander = false
        end
    end


    comms = nil --flush tmp tbl

    local function GetAssignedListAt(steamid)
        for i = 1, #assignedList do
            if assignedList[i] and assignedList[i].steamid == steamid then
                return i, assignedList[i]
            end
        end
    end


--Statically assign Groups (if present), and lock those players  ...REshuffling GROUPS may be needed later

    local function GetPlayerDataInGroup( players, steamid )
        for i = 1, #players do
            if players[i].steamid and players[i].steamid == steamid then
                return players[i]
            end
        end
        return nil
    end

    -- Tracking variables to quickly check group team assignments and whether a group contains a valid commander
    local group1Team = 0
    local group1Comm = false
    local group2Team = 0
    local group2Comm = false

    -- Check commanders for group membership and assign entire group to team
    if groupId1 then
        local commTeam1 = groups[groupId1] and table.icontains( groups[groupId1], commId1 )
        local commTeam2 = groups[groupId1] and table.icontains( groups[groupId1], commId2 )

        if commTeam1 or commTeam2 then
            group1Comm = true
            group1Team = commTeam1 and kTeam1Index or kTeam2Index
            
            SLog("     ** Group 1 has Commander, assigned entire group to Team %s", group1Team)
        end
    end

    if groupId2 then
        local commTeam1 = groups[groupId2] and table.icontains( groups[groupId2], commId1 )
        local commTeam2 = groups[groupId2] and table.icontains( groups[groupId2], commId2 )

        if commTeam1 or commTeam2 then
            group2Comm = true
            group2Team = commTeam1 and kTeam1Index or kTeam2Index
            
            SLog("     ** Group 2 has Commander, assigned entire group to Team %s", group2Team)
        end
    end

    -- Handle groups without commanders:
    -- For each group, we check if the other has been assigned a commander (and thus a team)
    -- and take the opposing team to balance things out.
    -- If both teams have been assigned commanders, just assign group1 = team1 and group2 = team2
    if groupId1 and not group1Comm then
        if group2Comm then
            group1Team = group2Team == kTeam1Index and kTeam2Index or kTeam1Index
        else
            group1Team = kTeam1Index
        end

        SLog("    ** Group 1 does not have Commander, assigned entire group to Team %s", group1Team)
    end

    if groupId2 and not group2Comm then
        if group1Comm then
            group2Team = group1Team == kTeam1Index and kTeam2Index or kTeam1Index
        else
            group2Team = kTeam2Index
        end

        SLog("    ** Group 2 does not have Commander, assigned entire group to Team %s", group2Team)
    end

    assert(groupId1 == nil or group1Team ~= 0, "Error: shuffle failed to assign group1 a team")
    assert(groupId2 == nil or group1Team ~= 0, "Error: shuffle failed to assign group2 a team")

    -- Make player assignments into each team, excluding commanders as they're handled above
    for i = 1, #playersList do

        local player = playersList[i]

        --Group 1
        if groupId1 ~= nil and player.group == groupId1 and not player.commander then

            assignedList[ #assignedList + 1 ] =
            {
                steamid = player.steamid,
                skill = player.skill,
                commSkill = player.commSkill,
                team = group1Team,
                group = player.group,
                commander = false,
                locked = true,  --flag this player _cannot_ be moved/swapped in list
            }

            teamCount[group1Team] = teamCount[group1Team] + 1
            
        elseif groupId2 ~= nil and player.group == groupId2 and not player.commander then

            assignedList[ #assignedList + 1 ] =
            {
                steamid = player.steamid,
                skill = player.skill,
                commSkill = player.commSkill,
                team = group2Team,
                group = player.group,
                commander = false,
                locked = true,  --flag this player _cannot_ be moved/swapped in list
            }

            teamCount[group2Team] = teamCount[group2Team] + 1

        end

    end

    --[[
    --Check commanders for Group membership
    if groupId1 and ( groups[groupId1] and table.icontains( groups[groupId1], commId1 )) or ( groups[groupId1] and table.icontains( groups[groupId1], commId2 )) then
       --assign entire group to team one
        SLog("     ** Group 1 has Commander, assigned entire group to Team 1")

        for g = 1, #groups[groupId1] do
            local player = GetPlayerDataInGroup( playersList, groups[groupId1][g] )

            if player and not player.commander then
                assignedList[ #assignedList + 1 ] =
                {
                    steamid = player.steamid,
                    skill = player.skill,
                    commSkill = player.commSkill,
                    team = kTeam1Index,
                    group = player.group,
                    commander = false,
                    locked = true,  --flag this player _cannot_ be moved/swapped in list
                }

                teamCount[kTeam1Index] = teamCount[kTeam1Index] + 1
            elseif not player then
                SLog("Error: Failed to find Player[%s] in players-list data", groups[groupId1][g])
            end
        end
    elseif groupId2 and ( groups[groupId2] and table.icontains( groups[groupId2], commId2 )) or ( groups[groupId2] and table.icontains( groups[groupId2], commId1 )) then
    --assign entire group to team two
        SLog("     ** Group 2 has Commander, assigned entire group to Team 2")

        for g = 1, #groups[groupId2] do
            local player = GetPlayerDataInGroup( playersList, groups[groupId2][g] )

            if player and not player.commander then
                assignedList[ #assignedList + 1 ] =
                {
                    steamid = player.steamid,
                    skill = player.skill,
                    commSkill = player.commSkill,
                    team = kTeam2Index,
                    group = player.group,
                    commander = false,
                    locked = true,  --flag this player _cannot_ be moved/swapped in list
                }

                teamCount[kTeam2Index] = teamCount[kTeam2Index] + 1
            elseif not player then
                SLog("Error: Failed to find Player[%s] in players-list data", groups[groupId2][g])
            end
        end

    end
    --]]

    --Now, deal with groups which have no commander in them
    local group1Med = groups[groupId1] and table.median( groups[groupId1] ) or -1
    local group2Med = groups[groupId2] and table.median( groups[groupId2] ) or -1
    
    --[[
    local grpT1 = 0     --1 or 2 (group1 or group2 get assigned to Team1)

    for i = 1, #playersList do

        local player = playersList[i]

        --Group 1
        if groupId1 ~= nil and #groups[groupId1] > 0 and grpT1 == 1 then

            if player.group == groupId1 then
                assignedList[ #assignedList + 1 ] =
                {
                    steamid = player.steamid,
                    skill = player.skill,
                    commSkill = player.commSkill,
                    team = kTeam1Index,
                    group = player.group,
                    commander = false,
                    locked = true,  --flag this player _cannot_ be moved/swapped in list
                }

                teamCount[kTeam1Index] = teamCount[kTeam1Index] + 1
            end

        elseif groupId2 ~= nil and #groups[groupId2] > 0 and grpT1 == 2 then

            if player.group == groupId2 then
                assignedList[ #assignedList + 1 ] =
                {
                    steamid = player.steamid,
                    skill = player.skill,
                    commSkill = player.commSkill,
                    team = kTeam1Index,
                    group = player.group,
                    commander = false,
                    locked = true,  --flag this player _cannot_ be moved/swapped in list
                }

                teamCount[kTeam1Index] = teamCount[kTeam1Index] + 1
            end

        end

    end
    --]]

    local function IsPlayerAssigned( steamid )
        for i = 1, #assignedList do
            if assignedList[i].steamid == steamid then
                return true
            end
        end
        return false
    end

--General Assignments (Non-Comm  /  No Group)
    for _, player in ipairs(playersList) do

        local playerTeam

        if IsPlayerAssigned(player.steamid) then 
        --Build delta for already assigned (groups) players
            local aI, assignedPlayer = GetAssignedListAt( player.steamid )
            rollingSkillDiff = rollingSkillDiff + ( kTeamSign[assignedPlayer.team] * assignedPlayer.skill )
        else

            if teamCount[kTeam2Index] == maxTeamSize then
                playerTeam = kTeam1Index

            elseif teamCount[kTeam1Index] == maxTeamSize then
                playerTeam = kTeam2Index

            elseif rollingSkillDiff > 0 then
                playerTeam = kTeam1Index

            elseif rollingSkillDiff < 0 then
                playerTeam = kTeam2Index

            else
                playerTeam = math.random( kTeam1Index, kTeam2Index )
            end

            teamCount[playerTeam] = teamCount[playerTeam] + 1

            --Field Players only here
            assignedList[ #assignedList + 1 ] =
            {
                steamid = player.steamid,
                skill = player.skill,
                team = playerTeam,
                group = player.group,
                locked = false,     --group-assigned
                commander = false,
            }

            rollingSkillDiff = rollingSkillDiff + ( kTeamSign[playerTeam] * player.skill )

        end

    end

    SLog("******[post-divy]  AssignedList Size: %s", #assignedList)

    -- Temporary post-divy assigned list
    for i = 1, #assignedList do
        SLog("    [Assigned Player %s]:", i)
        SLog("        SteamID: %s", assignedList[i].steamid)
        SLog("          Skill: %s", assignedList[i].skill)
        SLog("           Team: %s", assignedList[i].team)
        SLog("          Group: %s", assignedList[i].group)
        SLog("         Locked: %s", assignedList[i].locked)
        SLog("      Commander: %s", assignedList[i].commander)
        SLog("\n")
    end

    for team = 1, 2 do

        local otherTeam = (team == kTeam1Index and kTeam1Index or kTeam2Index)

        if teamCount[team] > maxTeamSize then

            for i = #assignedList, 1, -1 do

                if assignedList[i].team == team and not assignedList[i].locked then

                    teamCount[team] = teamCount[team] - 1
                    teamCount[otherTeam] = teamCount[otherTeam] + 1

                    assignedList[i].team = otherTeam

                    rollingSkillDiff = rollingSkillDiff + 2 * (kTeamSign[otherTeam] * assignedList[i].skill)    --team-applicable?

                end

                if teamCount[team] == maxTeamSize then
                    break
                end

            end

        end

    end

    SLog("******[post-assign]  AssignedList Size: %s", #assignedList)

    SLog("  PrepStep Skill-Diff:  %s", rollingSkillDiff)
    SLog("     Assigned Size: %s", #assignedList)
    SLog("     Team1Count: %s   -   Team2Count: %s", teamCount[kTeam1Index], teamCount[kTeam2Index])

    local swapI, swapJ, swapDelta
    local playerI,teamI        
    local playerJ,teamJ

    for round = 0, 1 do
        SLog("    Round: %s\n", round)

        for swaps = 0, 20 do
            SLog("       Swap-Step[%s]\n", swaps)

            swapI = -1
            swapJ = -1
            swapDelta = rollingSkillDiff

            for i = 1, #assignedList do

                playerI = assignedList[i]
                teamI = playerI.team

                if playerI.locked then
                    SLog("          Player is team-locked [%s]", playerI.steamid)
                end

                if (not playerI.commander and not playerI.locked) and (round == 1 or not playerI.team) then    --never swap commanders

                    SLog("     Checking player[%s]", playerI.steamid)

                    for j = i + 1, #assignedList do

                        local delta

                        playerJ = assignedList[j]
                        local teamJ = playerJ.team

                        if playerJ.locked then
                            SLog("          Skip-swapable player, locked:  %s", playerJ.steamid)
                        end

                        if teamI ~= teamJ and ( not playerJ.commander and not playerJ.locked ) then

                            delta = 
                                (kTeamSign[teamI] * playerI.skill) +
                                (kTeamSign[teamJ] * playerJ.skill)

                            if math.abs(rollingSkillDiff - 2 * delta) < math.abs(swapDelta) then
                                swapI = i
                                swapJ = j
                                swapDelta = rollingSkillDiff - 2 * delta
                            end

                        end

                    end

                end

            end

            SLog("     swapI: %s", swapI)
            SLog("     swapJ: %s", swapJ)
            
            if swapI ~= -1 and swapJ ~= -1 then
                
                SLog("        Swapping Player[%s] with Player[%s]", assignedList[swapI].steamid, assignedList[swapJ].steamid)

                assignedList[swapI].team, assignedList[swapJ].team = 
                    assignedList[swapJ].team, assignedList[swapI].team

                rollingSkillDiff = swapDelta

            else
                break
            end

        end

    end

    SLog("******[post-swap]  AssignedList Size: %s", #assignedList)

    local validComms = true
    SLog("  Commander-1 ID: %s", commId1)
    SLog("  Commander-2 ID: %s", commId2)
    for t = 1, #assignedList do
        if assignedList[t].commander then
        
            if assignedList[t].team == kTeam1Index and commId1 ~= assignedList[t].steamid then
                SLog("   Found Mismatched Commander Player [%s]", assignedList[t].steamid)
                validComms = false
                break

            elseif assignedList[t].team == kTeam2Index and commId2 ~= assignedList[t].steamid then
                SLog("   Found Mismatched Commander Player [%s]", assignedList[t].steamid)
                validComms = false
                break
            end

        end
    end

    assert(validComms, "Error: Shuffle routine moved pre-assigned Commander player(s)!")
    
    --[[
    SLog("\n[Player Groups]\n")
    if groups[groupId1] or groups[groupId2] then
        dumpSetsTable( groups[groupId1], groups[groupId2], "Group I", "Group II" )
    else
        SLog("\t NONE")
    end
    SLog("\n")
    --]]

    for i = 1, #assignedList do
        local p = assignedList[i]
        if p.steamid == commId1 or p.steamid == commId2 then
            SLog("       Commander[%s]:\n", p.steamid)
            SLog("           TEAM: %s", p.team)
            SLog("          Skill: %s", p.skill)
            SLog("      CommSkill: %s", p.commSkill)
            SLog("        GroupID: %s", p.groupId)
        end
    end

    --FIXME Need to add test / report for Group players and assignments (validation)

    for i = 1, #assignedList do
        local player = assignedList[i]

        if groupId1 and player.group == groupId1 and player.team ~= group1Team then
            SLog("  - TEST FAIL: player [%s] was group-assigned to team %s but is in team %s.", player.steamid, group1Team, player.team)
        elseif groupId2 and player.group == groupId2 and player.team ~= group2Team then
            SLog("  - TEST FAIL: player [%s] was group-assigned to team %s but is in team %s.", player.steamid, group2Team, player.team)
        end
    end

    local set1 = {}
    local set2 = {}
    for i = 1, #assignedList do
        if assignedList[i].team == kTeam1Index then
            table.insert( set1, assignedList[i].steamid )
        else
            table.insert( set2, assignedList[i].steamid )
        end
    end

    return commId1, commId2, set1, set2
end

--Call into Hive requesting a server with XYZ map loaded
function LobbyClientOwner:RequestServer( lobby )
    SLog("LobbyClientOwner:RequestServer()")

    if lobby:GetState() ~= kLobbyState.WaitingForServer then
        Log("Warning: Cannot request server unless Lobby State[%s] is waiting for server", lobby:GetState())
        return
    end

    if not Thunderdome():IsAuthenticated() then
        Thunderdome():Authenticate()
        return
    end

    if self.numLocalServerReqAttempts > self.kMaxLocalLimitRequestServer then
    --local client has failed to successfully start server request
        Thunderdome():TriggerOwnerChange( lobby:GetId() )
        return
    end 

    self.activeServerRequestAttempt = true

    local td = Thunderdome()

    local reqParams =
    {
        ns2tdsessid = Thunderdome():GetSessionId(),
        lobbyid = lobby:GetId(),
        mapname = lobby:GetFieldAsString( LobbyModelFields.VotedMap ),
        playerslots = kThunderdomeServerSlotLimit, 
        geocoord = lobby:GetFieldAsString( LobbyModelFields.Coords ),
        steambranch = Thunderdome():GetSteamBranch(),
        build = Shared.GetBuildNumber(),
        expectedplayers = Client.GetNumLobbyMembers( lobby:GetId() ), 
        team1 = lobby:GetFieldAsString( LobbyModelFields.ShuffledTeam1 ),
        team2 = lobby:GetFieldAsString( LobbyModelFields.ShuffledTeam2 ),
        team1comm = lobby:GetFieldAsString( LobbyModelFields.Team1Commander ),
        team2comm = lobby:GetFieldAsString( LobbyModelFields.Team2Commander ),
        private = tostring(lobby:GetType() == Client.SteamLobbyType_Private and 1 or 0),
    }

    SLog("    Request Params: %s", reqParams)

    local lobNumAttempts = tonumber(lobby:GetField( LobbyModelFields.ServerReqAttempts ))
    local numReqAttempts = lobNumAttempts and lobNumAttempts or 0
    SLog("\t\t lobNumAttempts: %s", lobNumAttempts)
    SLog("\t\t numReqAttempts: %s", numReqAttempts)

    td.activeLobby:SetField( LobbyModelFields.LastSrvReqTime, Client.GetTdTimestamp() )
    td.activeLobby:SetField( LobbyModelFields.ServerReqAttempts, numReqAttempts + 1 )
    td:TriggerLobbyMetaDataUpload( td.activeLobbyId )

    Shared.SendHTTPRequest( string.format("%s%s", kServerRequestUrl, Client.GetSteamId()) , "POST", reqParams, 
        function(response, errMsg, errCode)

            local obj, pos, err = json.decode(response, 1, nil)

            if not obj then
            --server-side issue, cannot proceed
                Log("Error: failed to parse server-request response:\n%s\n%s\n%s", obj, pos, err)
                self.activeServerRequestAttempt = false
                self.numLocalServerReqAttempts = self.numLocalServerReqAttempts + 1
                return false
            end

            SLog("\t obj: %s\n\t pos: %s\n\t err: %s", obj, pos, err)

            if not obj.code then
            --This only occurs if the path was incorrect for invalid request parameters
                Log("Error: invalid server-request response format:\n%s\n%s\n%s", obj, pos, err)
                self.activeServerRequestAttempt = false
                self.numLocalServerReqAttempts = self.numLocalServerReqAttempts + 1
                return false
            end

            if obj.code == 200 and obj.requestId then
            --success, set associated data and prime for status-polling

                local serverRequestId = tostring(obj.requestId)

                td.activeLobby:SetField( LobbyModelFields.ServerReqId, serverRequestId )
                td.activeLobby:SetField( LobbyModelFields.ServerReqStatus, kLobbyServerStatusCreating )
                td:TriggerLobbyMetaDataUpload( td.activeLobbyId )

            elseif obj.code == 429 then
            --server already requested, potential dead-lock due to data-prop fail!

                local lobReqId = lobby:GetField( LobbyModelFields.ServerReqId )
                if obj.requestId and (not lobReqId or lobReqId == "") then
                --server-request-id was missing from meta-data, likely due to owner-change, set it and move on
                    local serverRequestId = tostring(obj.requestId)

                    td.activeLobby:SetField( LobbyModelFields.ServerReqId, serverRequestId )
                    td.activeLobby:SetField( LobbyModelFields.ServerReqStatus, kLobbyServerStatusCreating )
                    td:TriggerLobbyMetaDataUpload( td.activeLobbyId )

                else
                --malformed response for 429 code, fail-out
                    Thunderdome():TriggerOwnerChange( td.activeLobbyId )
                end

            elseif obj.code == 500 or obj.code == 406 then
            --Request failed and will continue failing, pass owner to another member

                Log("Error: Failed to retrieve good response for Server-Request")
                Log("\t %s", obj)

                self.lastServerQueryTime = self.lastServerQueryTime + self.kServerStatusFailStepTime
                self.numLocalServerReqAttempts = self.numLocalServerReqAttempts + 1
                self.activeServerRequestAttempt = false
                return false

            end

            self.activeServerRequestAttempt = false

        end
    )

end

function LobbyClientOwner:UpdateServerRequestStatus( lobby )
    
    assert(lobby)
    assert(lobby:GetState() == kLobbyState.WaitingForServer)

    if not Thunderdome():IsAuthenticated() then
        SLog("LobbyClientOwner:UpdateServerRequestStatus()")
        SLog("\t Not authenticated! Run auth routine...")
        Thunderdome():Authenticate()
        return
    end

    if self.activeServerQuery then
    --active query already running, bail-out
        return
    end

    local initReqTs = lobby:GetField( LobbyModelFields.StateChangeTime )
    if not initReqTs or initReqTs == 0 or initReqTs == "" then
    --timestamp data not yet propagated
        return
    end

    local curLobTs = Client.GetTdTimestamp()
    if initReqTs + self.kMinStatusQueryDelay >= curLobTs then
    --always wait a short period, because immediately pinging for status immediately utterly pointless
        return
    end

    local time = Shared.GetSystemTime()
    if self.lastServerQueryTime == 0 then
        self.lastServerQueryTime = time --first run, always skip
        return
    end

    if self.lastServerQueryTime + self.kServerStatusQueryInterval > time then
        return
    end

    self.lastServerQueryTime = time
    self.activeServerQuery = true

    local td = Thunderdome()

    local params = 
    {
        lobbyid = lobby:GetId(),
        requestid = lobby:GetFieldAsString( LobbyModelFields.ServerReqId ),
        ns2tdsessid = td:GetSessionId(),
    }

    if self.numLocalServerStatusAttempts > kMaxLobbyOwnerStatusAttempts then
    --Fail-out, and switch owners
        SLog("LobbyClientOwner:UpdateServerRequestStatus()")
        SLog("WARNING: retry attempts limit hit, switching lobby owner from local-client")
        td:TriggerOwnerChange( td.activeLobbyId )
    end

    Shared.SendHTTPRequest( string.format("%s%s", kServerRequestStatusUrl, Client.GetSteamId()) , "POST", params, 
        function(res, errMsg, errCode)
            SLog("LobbyClientOwner:UpdateServerRequestStatus()")
            
            local obj, pos, err = json.decode(res, 1, nil)
            SLog("\t obj: %s\n\t pos: %s\n\t err: %s", obj, pos, err)

            if not obj then
                Log("Error: failed to parse server-request status response:\n%s\n%s\n%s", obj, pos, err)
                self.numLocalServerStatusAttempts = self.numLocalServerStatusAttempts + 1
                self.activeServerQuery = false
                return false
            end

            if not obj.code then
                Log("Error: invalid server-request response status format:\n%s\n%s\n%s", obj, pos, err)
                self.activeServerQuery = false
                self.numLocalServerStatusAttempts = self.numLocalServerStatusAttempts + 1
                return false
            end

            if obj.code == 200 and obj.status then

                local lobLastStatus = lobby:GetField( LobbyModelFields.ServerReqStatus )
                if lobLastStatus ~= obj.status then
                --Only update status if it changed. Clients can use it to update their GUI
                    
                    lobby:SetField( LobbyModelFields.ServerReqStatus, obj.status )
                    if obj.status == kLobbyServerStatusReady then
                        --Client.SetLobbyDataField( lobby:GetId(), GetLobbyFieldName( LobbyModelFields.ServerReqStatus ), kLobbyServerStatusReady )

                        td.activeLobby:SetField( LobbyModelFields.ServerReqStatus, kLobbyServerStatusReady )
                        td:TriggerLobbyMetaDataUpload( td.activeLobbyId )

                    end
                
                end

            elseif obj.code == 403 then

                --Owner is not authenticated, fail-out and swap owners
                self.numLocalServerStatusAttempts = kMaxLobbyOwnerStatusAttempts
                self.activeServerQuery = false
                return false

            elseif obj.code == 406 or obj.code == 500 then
            --Problems, request-system failures, can only try to delay or retry. All else...setup alternate lobby and "transfer" to that (...BLEH)

                self.lastServerQueryTime = self.lastServerQueryTime + self.kServerStatusFailStepTime
                self.numLocalServerStatusAttempts = self.numLocalServerStatusAttempts + 1   --TD-TODO Rename to imply "count on failed"
                self.activeServerQuery = false
                return false

            end

            self.activeServerQuery = false

        end
    ) --end http-request

end

function LobbyClientOwner:FetchServerDetails( lobby )
    SLog("LobbyClientOwner:FetchServerDetails()")
    assert(lobby)
    assert(lobby:GetState() == kLobbyState.Ready)

    if not Thunderdome():IsAuthenticated() then
        Thunderdome():Authenticate()
        return
    end

    self.activeServerQuery = true

    local td = Thunderdome()

    local params = 
    {
        lobbyid = lobby:GetId(),
        requestid = lobby:GetFieldAsString( LobbyModelFields.ServerReqId ),
        ns2tdsessid = td:GetSessionId(),
    }
    
    if self.numLocalServerDetailsAttempts > kMaxLobbyOwnerStatusAttempts then
    --Fail-out, and switch owners
        SLog("WARNING: retry attempts limit hit, switching lobby owner from local-client")
        td:TriggerOwnerChange( td.activeLobbyId )
    end

    Shared.SendHTTPRequest( string.format("%s%s", kServerRequestDetailsUrl, Client.GetSteamId()) , "POST", params, 
        function(res, errMsg, errCode)
            
            local obj, pos, err = json.decode(res, 1, nil)
            SLog("\t obj: %s\n\t pos: %s\n\t err: %s", obj, pos, err)

            if not obj then
                Log("Error: failed to parse server-details response:\n%s\n%s\n%s", obj, pos, err)
                self.activeServerQuery = false

                self.lastServerQueryTime = self.lastServerQueryTime + self.kServerStatusFailStepTime
                self.numLocalServerDetailsAttempts = self.numLocalServerDetailsAttempts + 1

                return false
            end

            if not obj.code then
                Log("Error: invalid server-details response format:\n%s\n%s\n%s", obj, pos, err)
                self.activeServerQuery = false

                self.lastServerQueryTime = self.lastServerQueryTime + self.kServerStatusFailStepTime
                self.numLocalServerDetailsAttempts = self.numLocalServerDetailsAttempts + 1

                return false
            end

            if obj.code ~= 200 then
                Log("Error: invalid server-details response, system error[%s]:\n%s", obj.code, obj)
                self.activeServerQuery = false
                self.numLocalServerDetailsAttempts = self.numLocalServerDetailsAttempts + 1
                self.lastServerQueryTime = self.lastServerQueryTime + self.kServerStatusFailStepTime
                return false
            end

            local ip = obj.ip
            local port = obj.port
            local pass = obj.pass

            td.activeLobby:SetField( LobbyModelFields.ServerIP, ip )
            td.activeLobby:SetField( LobbyModelFields.ServerPort, port )
            td.activeLobby:SetField( LobbyModelFields.ServerPassword, pass )
            td:TriggerLobbyMetaDataUpload( td.activeLobbyId )

            self.activeServerQuery = false
        end
    )

end

local function CheckAndRecoverFailureLobbyState( td, lob, lobState, count )

    if lobState >= kLobbyState.WaitingForServer then
    --Once a server request is "active", the lobby is committed in its state (regardless of player count)
        return lobState
    end

    local hasEnoughPlayers =
        (count >= kMinRequiredLobbySizeServerRequest) and
        lobState > kLobbyState.WaitingForPlayers

    if not hasEnoughPlayers then
        return kLobbyState.WaitingForPlayers
    end

    return lobState
end

--Util to handle lobby state change to WaitingForPlayers state due to a rollback (player left, timedout, etc.)
--Return true, if this function has modified anything (pushed state forward, etc.)
local function CheckAndUpdateStateFromRollback( td, count, prevLobState )
    SLog("LobbyClientOwner#CheckAndUpdateStateFromRollback()")
    SLog(" prevLobbyState: %s", prevLobState)

    assert( td, "Error: No ThunderdomeManager object passed" )
    assert( count, "Error: Lobby player count not passed")

    --If previous was awaiting server, it's too late, as teams info already passed to server
    --Side note: if people are joining at that stage, things are broken anyway.
    if prevLobState > kLobbyState.WaitingForPlayers and prevLobState < kLobbyState.WaitingForServer then

        td.activeLobby:SetField( LobbyModelFields.Team1Commander, nil )
        td.activeLobby:SetField( LobbyModelFields.Team2Commander, nil )
        td.activeLobby:SetField( LobbyModelFields.ShuffledTeam1, nil )
        td.activeLobby:SetField( LobbyModelFields.ShuffledTeam2, nil )

    end

end

function LobbyClientOwner:UpdateLobbyState( thunderdome, count )
    assert(thunderdome)
    assert(count)
    
    local lobby = thunderdome:GetActiveLobby()
    local curState = lobby:GetState()

    --Check current lobby state and data, if current state doesn't match current data, fail-over to applicable "new" state
    local failoverState = CheckAndRecoverFailureLobbyState( thunderdome, lobby, curState, count )

    if failoverState and curState ~= failoverState and ( not Client.GetIsConnected() and not Shared.GetThunderdomeEnabled() ) then
    --Only affect fail-over while NOT already on a TD server
        SLog("WARNING: Lobby current-state not match failover-state. Regressing lobby 'progress' to fail-over mode")
        local newState = kLobbyState[ kLobbyState[failoverState] ]
        SLog("\t Old State:         %s", curState)
        SLog("\t Fail-over State:   %s", newState)

        if newState == kLobbyState.WaitingForPlayers then
            CheckAndUpdateStateFromRollback( thunderdome, count, curState )
        end

        thunderdome.activeLobby:SetState( newState )
        thunderdome:TriggerLobbyMetaDataUpload( thunderdome.activeLobbyId )

        --TODO check returned state, and reset other fields accordingly (per cur vs actual)
        self.minCommandersSet = false
        
        return  --return in order for above data to propagate, next update loop will handle this
    end

    if curState == kLobbyState.WaitingForPlayers then

        if count >= kMinRequiredLobbySizeServerRequest then
        --TD-FIXME: will need means for a Min-Count + Waited at least Y time-limit. This would allow for players to continue with bots, otherwise could be waiting a LONG time
            thunderdome.activeLobby:SetState( kLobbyState.WaitingForCommanders )
            thunderdome:TriggerLobbyMetaDataUpload( thunderdome.activeLobbyId )
        end

    elseif curState == kLobbyState.WaitingForCommanders or curState == kLobbyState.WaitingForExtraCommanders then

        local awesomePeople = self:CountNumCommanders( lobby )

        --TD-TODO Add timeout threshold(s) and auto-force 2 for comm?
        local stateTs = lobby:GetField( LobbyModelFields.StateChangeTime )
        local sinceState = Client.GetTdTimestamp() - stateTs
        
        if awesomePeople >= kMinRequiredCommanderVolunteers then

            if sinceState >= kMaxWaitingCommandersStateTimeLimit then

                local team1List = lobby:GetField( LobbyModelFields.ShuffledTeam1 ) or {}
                local team2List = lobby:GetField( LobbyModelFields.ShuffledTeam2 ) or {}

                if #team1List == 0 and #team2List == 0 then --TD-TODO tweak/remove to allow for re-shuffle(s)          --Note: This MUST have the previous state and StateChangeTime in scope, otherwise it'll get triggered too often
                    self:UpdateTeamShuffle( thunderdome )
                end
                
            elseif not self.minCommandersSet then
                thunderdome.activeLobby:SetState( kLobbyState.WaitingForExtraCommanders )
                thunderdome:TriggerLobbyMetaDataUpload( thunderdome.activeLobbyId )

                self.minCommandersSet = true
            end
        end

    elseif curState == kLobbyState.WaitingForMapVote then

        local numMemberVoted = 0
        local timeVoteStart = lobby:GetField( LobbyModelFields.StateChangeTime )
        local voteExpireTime = timeVoteStart + kMaxMapVoteAllowedTime
        local curLobTime = Client.GetTdTimestamp()

        local members = lobby:GetMembers()
        for i = 1, #members do
            local memVoteVal = members[i]:GetField( LobbyMemberModelFields.MapVotes )
            if memVoteVal and memVoteVal ~= "" then
                numMemberVoted = numMemberVoted + 1
            end
        end
        
        --Absolute timeout or all members voted, whichever comes first. On timeout, map will be randomized
        local readyToRequestServer = (curLobTime >= voteExpireTime) or (numMemberVoted == lobby:GetMemberCount())
        
        if readyToRequestServer then
        --Only set the field here, On-State logic will update when data propagates

            --Re-run server-request centric data one more time to finalize it before continuing.
            self:UpdateLobbyGeoCoords( thunderdome )

            local selectMapFailed = false
            if not self:UpdateLobbyMapVote( thunderdome ) then
            -- Was not able to set the voted map, due to no votes being set, and we're past the time limit for map votes..
                if not self:SelectRandomMap(thunderdome) then
                    selectMapFailed = true
                end
            end
            
            --Safety condition, before proceeding, swap owners (should be quick)
            if selectMapFailed then
                thunderdome:TriggerOwnerChange( thunderdome.activeLobbyId )
            else
                thunderdome.activeLobby:SetState( kLobbyState.WaitingForServer )
                thunderdome:TriggerLobbyMetaDataUpload( thunderdome.activeLobbyId )
            end
        end

    elseif curState == kLobbyState.WaitingForServer then

        local srvReqId = lobby:GetField( LobbyModelFields.ServerReqId )
        if not srvReqId or srvReqId == "" then

            if not self.activeServerRequestAttempt then
                
                local lobLastTime = lobby:GetField( LobbyModelFields.LastSrvReqTime )
                local lastReqCheck = lobLastTime and lobLastTime or 0
                local curTs = Client.GetTdTimestamp()

                if lastReqCheck + self.kServerRequestRetryDelay < curTs then
                    self.numLocalServerReqAttempts = self.numLocalServerReqAttempts + 1
                    self:RequestServer( lobby )
                end

            end

        else
        --Have an existing request ID, check times and fetch Request Status instead
            local reqStat = lobby:GetField( LobbyModelFields.ServerReqStatus )

            if reqStat ~= kLobbyServerStatusReady then
                self:UpdateServerRequestStatus( lobby )

            elseif reqStat == kLobbyServerStatusReady then
                thunderdome.activeLobby:SetState( kLobbyState.Ready )
                thunderdome:TriggerLobbyMetaDataUpload( thunderdome.activeLobbyId )

            end

        end

    elseif curState == kLobbyState.Ready then
        local serverIp = lobby:GetField( LobbyModelFields.ServerIP )
        if not serverIp or serverIp == "" and not Client.GetIsConnected() then
            self:FetchServerDetails( lobby )
        end
        
        if Client.GetIsConnected() and serverIp and Shared.GetThunderdomeEnabled() then     --TD-FIXME Need a delayed/load sort of thing for "new" LobbyModel to complete (due to LuaVM destroy from Main -> Client)
            SLog("  ** Set LobbyState to 'Playing' ** ")
            thunderdome.activeLobby:SetState( kLobbyState.Playing )
            thunderdome:TriggerLobbyMetaDataUpload( thunderdome.activeLobbyId )
        end
    end

end


local function GetMembersReloadRequired( lobby )

    if not lobby then
        SLog("Warning: GetMembersReloadRequired() called with no LobbyModel")
        return false
    end

    local tSteamActualList = {}
    if not Client.GetLobbyMembersList( lobby:GetId(), tSteamActualList ) then
    --false on failure or no members, bail-out. Most likely a update routine called before lob-leave sequence completes
        SLog("Warning: Failed to fetch lobby members list")
        return false
    end

    local tLobbyList = lobby:GetMembersIdList()
    if #tLobbyList ~= #tSteamActualList then
        return true
    end

    --Ensure member data is accurate to users in lobby
    --Sort each list respective in order to ensure ordering is the same for both (desc)
    local tmpOrderSort = function(a, b) 
        return tonumber(b) < tonumber(a) 
    end

    table.sort( tSteamActualList, tmpOrderSort )
    table.sort( tLobbyList, tmpOrderSort )

    --stringify and hash each listing for equality comparison
    local actualListHash = Client.GetStringHashed( table.concat( tSteamActualList , "," ) )
    local lobbyListHash = Client.GetStringHashed( table.concat( tLobbyList, "," ) )
    
    if actualListHash ~= lobbyListHash then
    --We get a list of member Ids that have been as single hash string to
    --determine if the actual members list has changed. This eliminates the
    --need to do ID by ID, and when they were added as problems.
    --Primarily, this also resolves scenario where member Counts are the same
    --but IDs have changed (two members left/joined in between now and last tick, etc.)
        SLog("\t Member-list hash failed, reloading members data...")
        SLog("\t\t   tSteamActualList:      %s", tSteamActualList)
        SLog("\t\t   tLobbyList:            %s", tLobbyList)
        SLog("\t\t actualListHash:     %s", actualListHash)
        SLog("\t\t  lobbyListHash:     %s", lobbyListHash)
        return true
    end

    return false
end

--Note: None of the TD Client-Objects (logical) need rate throttling, as TDMgr does update-rate handling
function LobbyClientOwner:Update( thunderDome, deltaTime, time )

    if self.activeServerRequestAttempt or self.activeServerQuery then
    --Wait for server requests to complete before doing anything else
        --SLog("INFO: Skipping update/tick, have pending API/HTTP action running...")
        return
    end

    local lobby = thunderDome:GetActiveLobby()
    if thunderDome.initLobbyDataLoadOnly then   --one-off warning, can remove later
        SLog("Warning: Client-Object :Update() run at invalid time!")
    end
    
    if GetMembersReloadRequired( lobby ) then
    --force reload (into local models/memory) from on-Steam stored lobby data. Update all associated meta-data fields accordingly
        thunderDome:ReloadLobbyMembers( lobby:GetId() )
        self:UpdateLobbyMedianSkill( thunderDome )
        self:UpdateLobbyGeoCoords( thunderDome )
        self:UpdateLobbyGroupCounts( thunderDome )
    end

    --Lobby states are manually checked instead of Event-driven, so more granular and timed logic can be applied
    self:UpdateLobbyState( thunderDome, lobby:GetMemberCount() )

    local lobState = lobby:GetState()
    
    if lobState <= kLobbyState.WaitingForMapVote then
        self:UpdateLobbyMedianSkill( thunderDome )
        self:UpdateLobbyGeoCoords( thunderDome )
        self:UpdateLobbyGroupCounts( thunderDome )
    end

    local readyConn = 
        (lobState == kLobbyState.Ready or lobState == kLobbyState.Playing) and 
        not Shared.GetThunderdomeEnabled() and --doubles as not-is-connected
        ( thunderDome.pendingAkfPromptAction == false and thunderDome.pendingReconnectPrompt == false )

    --[[
    if (lobState == kLobbyState.Ready or lobState == kLobbyState.Playing) then
        SLog("    pendingAkfPromptAction:   %s", thunderDome.pendingAkfPromptAction)
        SLog("    pendingReconnectPrompt:   %s", thunderDome.pendingReconnectPrompt)
    end
    --]]

    if readyConn then
    --Lobby is ready for players to join TD server
        
        SLog("  LobbyClientMember:Update() -- readyConn: %s", readyConn)

        local numConnAttempts = Client.GetOptionInteger( kOptionKey_CachedLobbyConnAttempts, 0)
        local prevAttemptMade = Client.GetOptionBoolean( kOptionKey_CachedLobbyConnMade, false )
        local isFirstConnect = (numConnAttempts == 0 and prevAttemptMade == false)
        
        SLog("\t   numConnAttempts:     %s", numConnAttempts)
        SLog("\t   prevAttemptMade:     %s", prevAttemptMade)
        SLog("\t    isFirstConnect:     %s", isFirstConnect)

        if isFirstConnect then
        --Only do this once in the process, as other mechanics deal with return/reconn
            SLog(" *** Is FirstConnectionAttempt, joining...")
            thunderDome:AttemptServerConnect()
        end
        
    end

end

function LobbyClientOwner:DebugDump(full)
    SLog("\t\t [LobbyClientOwner]")

    SLog("\t\t\t (internals) ")
    SLog("\t\t\t     kServerStatusFailStepTime:         %s", self.kServerStatusFailStepTime)
    SLog("\t\t\t     kServerStatusQueryInterval:        %s", self.kServerStatusQueryInterval)
    SLog("\t\t\t     kMaxLocalLimitRequestServer:       %s", self.kMaxLocalLimitRequestServer)
    
    SLog("")
    SLog("\t\t\t     minCommandersSet:                  %s", self.minCommandersSet)
    SLog("\t\t\t     lobbyCoordsLocked:                 %s", self.lobbyCoordsLocked)
    SLog("\t\t\t     mapVotingLocked:                   %s", self.mapVotingLocked)
    SLog("\t\t\t     activeServerRequestAttempt:        %s", self.activeServerRequestAttempt)
    SLog("\t\t\t     activeServerQuery:                 %s", self.activeServerQuery)
    SLog("\t\t\t     lastServerQueryTime:               %s", self.lastServerQueryTime)
    SLog("\t\t\t     numLocalServerReqAttempts:         %s", self.numLocalServerReqAttempts)
    SLog("\t\t\t     numLocalServerStatusAttempts:      %s", self.numLocalServerStatusAttempts)
    SLog("\t\t\t     numLocalServerDetailsAttempts:     %s", self.numLocalServerDetailsAttempts)

end
