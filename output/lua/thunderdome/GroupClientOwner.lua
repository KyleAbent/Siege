-- ======= Copyright (c) 2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/thunderdome/GroupClientOwner.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")

Script.Load("lua/thunderdome/LobbyUtils.lua")

Script.Load("lua/thunderdome/LobbyMemberModel.lua")
Script.Load("lua/thunderdome/LobbyModel.lua")

Script.Load("lua/thunderdome/ClientLobbyFunctors.lua")


class 'GroupClientOwner'

GroupClientOwner.kLobbySearchInterval = 2

--Modulo which search limiters will be ticked to next value (and/or clamped)
GroupClientOwner.kSearchTickStepMod = 3

--Max number of iterations when trying to find an applicable lobby for local group
GroupClientOwner.kLobbySearchMaxAttempts = 60

--Min / Max geographic distances allowed when searching (in km)
GroupClientOwner.kDefaultGeoDist = 250         --todo tune
GroupClientOwner.kMaxGeoDist = 9500            --todo tune (ideally, smallest viable value)
--TODO/FIXME Need to set this max-dist per which region local-client is in, otherwise...it'll isolate regions even more
GroupClientOwner.kGeoDistStep = 500

--Amount the search routine increases skill range check by with each iteration
GroupClientOwner.kDefaultSkillRange = 100

--Maximum allowed variance between local client's skill and available lobbies
GroupClientOwner.kSkillRangeLimit = kLobbyMaxSkillSearchLimit
--TODO Instead of using above, experiement with having it be +/- 1 skill-tier from local-client as limit

--Amount the skill average of a search-filter limits are increased (+/-) per search-step    --TODO Look into applying only upper/lower bounds
GroupClientOwner.kSkillRangeLimitStep = 100     --todo tune

--Amount of time that must pass between each search step
GroupClientOwner.kSearchIntervalTime = 1    -- +rand?

--Number of times a specific set of search filters/checks can be run
--before increasing those limits (e.g. increase geo-desic range limit, etc)
GroupClientOwner.kSearchStepAttemptsLimit = 1

--absolute timeout before new lobby is made
GroupClientOwner.kSearchingTimeLimit = 60



function GroupClientOwner:Initialize()
    SLog("-GroupClientOwner:Initialize()")

    --The number of iterations when looking for an applicable lobby
    self.numSearchAttempts = 0

    --simple flag to denote this client is actively searching for a target public-lobby
    self.isSearching = false

    --Flag to denote we're looking for a match and/or creating a match lobby
    self.queuedMatchFind = false

    --
    self.hasDirtyMetaData = true

    self.searchStartedTime = 0
    self.lastSearchTime = 0

    self.currentDistanceLimit = 0

    --
    self.currentSkillLimit = self.kDefaultSkillRange

    self.cachedDiscardList = {}

    --public lobby for group to join
    self.activeTargetLobby = nil

    --
    self.localCoords = nil

    --
    self.localSkill = nil

    self:RegisterEvents()

end


function GroupClientOwner:RegisterEvents()
    --Setup event for when the Lobby's state value changes, denotes various 'phases' of match setup
    Thunderdome_AddListener( kThunderdomeEvents.OnStateChange, kLobbyClientFunctors[kThunderdomeEvents.OnStateChange] )

    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyJoined, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoined] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyJoinFailed, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoinFailed] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyCreated, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyCreated] )
    --TODO Add CreateFailed
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberJoin, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberJoin] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberLeave, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberLeave] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberKicked, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberKicked] )

    Thunderdome_AddListener( kThunderdomeEvents.OnChatMessage, kLobbyClientFunctors[kThunderdomeEvents.OnChatMessage] )

    Thunderdome_AddListener( kThunderdomeEvents.OnSearchResults, self.OnGroupSearchResults )

    Thunderdome_AddListener( kThunderdomeEvents.OnGroupStateChange, self._OnGUIGroupStateChange )

    --Trigger on _all_ member meta change (even local)
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberJoin, self._OnMemberMetaDataChanged )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberLeave, self._OnMemberMetaDataChanged )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberKicked, self._OnMemberMetaDataChanged )
end

function GroupClientOwner:UnRegisterEvents()
    Thunderdome_RemoveListener( kThunderdomeEvents.OnStateChange, kLobbyClientFunctors[kThunderdomeEvents.OnStateChange] )

    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyJoined, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoined] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyJoinFailed, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoinFailed] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyCreated, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyCreated] )
    --TODO Add CreateFailed
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberJoin, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberJoin] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberLeave, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberLeave] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberKicked, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberKicked] )

    Thunderdome_RemoveListener( kThunderdomeEvents.OnChatMessage, kLobbyClientFunctors[kThunderdomeEvents.OnChatMessage] )

    Thunderdome_RemoveListener( kThunderdomeEvents.OnSearchResults, self.OnGroupSearchResults )

    Thunderdome_RemoveListener( kThunderdomeEvents.OnGroupStateChange, self._OnGUIGroupStateChange )

    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberJoin, self._OnMemberMetaDataChanged )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberLeave, self._OnMemberMetaDataChanged )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberKicked, self._OnMemberMetaDataChanged )
end

function GroupClientOwner:Destroy()
    self:UnRegisterEvents()
end

function GroupClientOwner:Reset()
    self.isSearching = false
    self.queuedMatchFind = false
    self.hasDirtyMetaData = false
    self.numSearchAttempts = 0
    self.searchStartedTime = 0
    self.lastSearchTime = 0
    self.currentDistanceLimit = self.kDefaultGeoDist
    self.cachedDiscardList = {}
end


GroupClientOwner._OnGUIGroupStateChange = function( self, newState, oldState, lobbyId )
    SLog("GroupClientOwner:_OnGUIGroupStateChange( --, %s, %s, %s )", newState, oldState, lobbyId )
    local tdGui = GetThunderdomeMenu()
    assert(tdGui, "Error: No ThunderdomeMenu object found")

    local barState = GetStatusBarStateFromLobbyState( newState )
    tdGui:SetStatusBarStage( barState, lobbyId )
end

GroupClientOwner._OnMemberMetaDataChanged = function( self, memberId, lobbyId )
    self.hasDirtyMetaData = true
end

--Updates lobby data with the total-members median Average skill (not team-centric)
function GroupClientOwner:UpdateGroupSkill( thunderdome )
    SLog("================|| GroupClientOwner:UpdateGroupSkill( -- )")
    assert(thunderdome)
    
    local lobby = thunderdome:GetGroupLobby()
    --We're just reusing the Mediam field if LobbyModel, it's not supposed to be Median in _this_ context.
    --However, in "normal" TD-Lobby context it *is* the skill-median
    local prevMeanSkill = lobby:GetField( LobbyModelFields.MedianSkill )
    local members = lobby:GetFilteredMembers( thunderdome:GetLoadedMembersList( lobby:GetId() ) )

    if #members <= 0 then
    --wait until member meta-data propagates
        return
    end

    local skills = {}

    for i = 1, #members do
        local mAvgSk = members[i]:GetField( LobbyMemberModelFields.AvgSkill )
        if mAvgSk and type(mAvgSk) == "number" then
            table.insert( skills, mAvgSk )
        end
    end
    
    SLog("   Group-Skills: %s", skills)
    local meanSkill = math.max(0, math.floor(table.mean(skills)))
    SLog("     Group-MEAN Skill: %s", meanSkill)
    SLog("          (prev mean): %s", prevMeanSkill)

    if meanSkill ~= prevMeanSkill then
    --if any difference, update values otherwise ignore
        SLog("\t\t GroupClientOwner - Mean-Skill changed, updated...")
        thunderdome.groupLobby:SetField( LobbyModelFields.MedianSkill, meanSkill )
        thunderdome:TriggerLobbyMetaDataUpload( thunderdome.groupLobbyId )
    end
end

--Updates the Lobby's Geo centroid coordinates based on all member's geo-coords
--Note: this won't always include all member's data. If they recently joined
--their data won't have propagated yet.
function GroupClientOwner:UpdateGroupCoords( thunderdome )
    SLog("================|| GroupClientOwner:UpdateGroupCoords( -- )")
    assert(thunderdome)

    local lobby = thunderdome:GetGroupLobby()
    local members = lobby:GetFilteredMembers( thunderdome:GetLoadedMembersList( lobby:GetId() ) )

    if #members <= 0 then
    --wait until member meta-data propagates
        return
    end

    local coordSet = {}

    for i = 1, #members do
        local memCoord = members[i]:GetField( LobbyMemberModelFields.Coords )
        if type(memCoord) == "table" and #memCoord == 2 then
        --must check the type and size of the data, as member might've just joined, and not updated yet
            table.insert( coordSet, memCoord )
        end
    end

    local newLat, newLong = ComputeCenterGeoCoord(coordSet)
    assert(newLat and newLong)

    local setCoords = lobby:GetField( LobbyModelFields.Coords )
    if newLat ~= setCoords[1] or newLong ~= setCoords[2] then
    --Only update the value if it's actually different (prevent meta-data updated event unless required)
        local lobCoordStr = newLat .. "," .. newLong
        thunderdome.groupLobby:SetField( LobbyModelFields.Coords, lobCoordStr )
        thunderdome:TriggerLobbyMetaDataUpload( thunderdome.groupLobbyId )
    end
end

--[[
local function GetMembersReloadRequired( lobby )

    if not lobby then
        SLog("Warning: GetMembersReloadRequired() called with no LobbyModel")
        return false
    end

    local tSteamActualList = {}
    if not Client.GetLobbyMembersList( lobby:GetId(), tSteamActualList ) then
    --false on failure or no members, bail-out. Most likely a update routine called before lob-leave sequence completes
        SLog("Warning: Failed to direct-fetch lobby members list")
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

    local meanSkill = lobby:GetField( LobbyModelFields.MedianSkill )
    local coords = lobby:GetField( LobbyModelFields.Coords )
    if meanSkill == nil or coords == nil or (#coords == 0) then
        return true
    end

    return false
end
--]]

function GroupClientOwner:GetIsFindingMatch()
    SLog("GroupClientOwner:GetIsFindingMatch()")
    SLog("       queuedMatchFind: %s", self.queuedMatchFind)
    return self.queuedMatchFind
end

function GroupClientOwner:GetIsSearching()
    return self.isSearching
end

function GroupClientOwner:GetLobbyDistance( lobbyCoords, clientCoords )
    assert(lobbyCoords and #lobbyCoords == 2)
    assert(clientCoords and #clientCoords == 2)
    return CalcGeoDistance( lobbyCoords[1], lobbyCoords[2], clientCoords[1], clientCoords[2] )
end

function GroupClientOwner:GetLobbySkillDiff( lobbySkill, clientSkill )
   return math.round(math.abs( lobbySkill - clientSkill ))
end

--This does not "filter" anything for quality just the technical "can join" check
function GroupClientOwner:GetIsValidLobby( lobby, group )
    SLog("GroupClientOwner:GetIsValidLobby( -- )")
    assert(lobby, "Error: invalid or nil Lobby object")
    assert(group, "Error: invalid or nil Group object")
    
    local targetDist = lobby:GetField( LobbyModelFields.LocalDistance )
    local skillDiff = self:GetLobbySkillDiff( lobby:GetField( LobbyModelFields.MedianSkill ), self.localSkill )
    local isJoinable = GetIsLobbyJoinableWithGroup( lobby, group )  --checks state, build, steam-branch and member count, number of groups(slots), etc.
    local kickedIds = lobby:GetField( LobbyModelFields.Kicked )
    local isKicked = false

    if ( kickedIds and kickedIds ~= "" and #kickedIds > 0 ) then
        isKicked = table.icontains( kickedIds, Thunderdome():GetLocalSteam64Id() )
    end
    
    local valid = false
    valid = targetDist <= self.currentDistanceLimit
    valid = valid and skillDiff <= self.currentSkillLimit
    valid = valid and isJoinable
    valid = valid and not isKicked

    --TODO Add more granular range checks (e.g. if localSkill >= lobSkill(t6) OK no matter what, etc.  ...?)
    --TODO Add check for if local-client was kicked/banned/community-banned/etc...lobby data is loaded, so should be in scope

    return valid
end

function GroupClientOwner:SortFilteredResults( results )
    assert(results and type(results) == "table")

    local localSkill = self.localSkill

    local DumpRes = function(r)
        if g_thunderdomeVerbose then
            SLog("Sorting parsed search results...")
            for i = 1, #r do
                r[i]:DebugDump()
            end
        end
    end

    local SortResults = function(a, b)  --TD-TODO Add weight/sort for Steam Friends?
        local aMemNum = a:GetField( LobbyModelFields.NumMembers )
        local bMemNum = b:GetField( LobbyModelFields.NumMembers )

        local aSkillDiff = math.abs( a:GetField( LobbyModelFields.MedianSkill ) - localSkill )
        local bSkillDiff = math.abs( b:GetField( LobbyModelFields.MedianSkill ) - localSkill )

        local aDist = a:GetField( LobbyModelFields.LocalDistance )
        local bDist = b:GetField( LobbyModelFields.LocalDistance )

        return
        (
            (aDist < bDist) and
            (aSkillDiff < bSkillDiff) and
            (aMemNum > bMemNum)
        )
    end
    table.sort( results, SortResults )

    return results
end

GroupClientOwner.OnGroupSearchResults = function( self )
    SLog("--GroupClientOwner.OnGroupSearchResults")

    local list = Thunderdome():GetSearchResultsList()
    local time = Shared.GetSystemTime()

    assert(list, "Error: no search results list found")

    if #list == 0 then
        return
    end

    local filteredResults = {}
    for i = 1, #list do

        local lobbyId = list[i]:GetField( LobbyModelFields.Id )
        if not table.icontains( self.cachedDiscardList, lobbyId ) then
            --compute lobby geo-distance so filtering / sorting functions have data in scope
            local lobCoords = list[i]:GetField( LobbyModelFields.Coords )
            list[i]:SetField( LobbyModelFields.LocalDistance, CalcGeoDistance( lobCoords[1], lobCoords[2], self.localCoords[1], self.localCoords[2], true ) )
            
            if g_thunderdomeVerbose then
                list[i]:DebugDump()
            end
            
            if self:GetIsValidLobby( list[i], Thunderdome():GetGroupLobby() ) then     --XX Feed validity bounds as param?
                table.insert( filteredResults, list[i] )
            else
                table.insert( self.cachedDiscardList, list[i] )
            end
        end

    end

    if #filteredResults > 0 then

        local sortedList = #filteredResults > 1 and
            self:SortFilteredResults( filteredResults ) or filteredResults

        for i = 1, #sortedList do
            local lobbyId = sortedList[i]:GetField( LobbyModelFields.Id )
            if lobbyId == self.activeTargetLobby and lobbyId ~= nil then
            --Don't retry any already attempted
                table.insert( self.cachedDiscardList, lobbyId )
            else
                self.activeTargetLobby = lobbyId
                break --bails immediately, match-lobby found
            end
        end

    end

    Log("*LobbySearch - DONE - Attempt: %s*", self.numSearchAttempts)
    return

end


function GroupClientOwner:PerformGroupSearch()
    SLog("GroupClientOwner:PerformGroupSearch()")
    local td = Thunderdome()
    assert(not self.isSearching, "Error: cannot trigger group-search, it is already running")

    self.isSearching = true
    self.lastSearchTime = 0
    self.searchStartedTime = Shared.GetSystemTime()
    self.searchStepsAttempts = 1
    self.queuedMatchFind = true
    
    self.currentSkillLimit = td:GetGroupLobby():GetField( LobbyModelFields.MedianSkill ) + self.kSkillRangeLimitStep
    
    SLog("\t Starting initial group-search...")
    td:InitGroupSearch()
    td:RunLobbySearch( kLobbySearchMaxListSize )
end

function GroupClientOwner:CancelGroupSearch()
    SLog("GroupClientOwner:CancelGroupSearch()")
    local td = Thunderdome()
    assert(self.isSearching, "Error: cannot cancel group-search while not searching")

    self.isSearching = false
    self.queuedMatchFind = false
    self.lastSearchTime = 0
    self.numSearchAttempts = 0

end

--check if we have enough members to proced, fail-over to waiting accordingly
function GroupClientOwner:CheckAndFailoverState( td )

    local lobState = td.groupLobby:GetState()

    if lobState == kLobbyState.GroupWaiting then
        return false
    end

    local targetLobbyId = td.groupLobby:GetField( LobbyModelFields.TargetLobbyId )
    local actMemCnt = Client.GetNumLobbyMembers( td.groupLobbyId )

    -- Fail over if a member left or we cancelled the search
    local shouldCancelSearch = actMemCnt < kFriendsGroupMinMemberCountForSearch or not self.isSearching

    if shouldCancelSearch and lobState > kLobbyState.GroupWaiting and not targetLobbyId then

        self.isSearching = false
        self.queuedMatchFind = false

        td.groupLobby:SetState( kLobbyState.GroupWaiting )
        td:TriggerLobbyMetaDataUpload( td.groupLobbyId )
        
        --safety if left during active search
        self.numSearchAttempts = 0
        self.lastSearchTime = 0

        td:TriggerEvent( kThunderdomeEvents.OnGUIGroupStateRollback, td:GetGroupLobbyId() )

        self.hasDirtyMetaData = true

        return true
    end

    return false    --no need to fail-over
end

--Note: None of the TD Client-Objects (logical) need rate throttling, as TDMgr does update-rate handling
function GroupClientOwner:Update( td, deltaTime, time )

    local lobby = td:GetGroupLobby()

    if self:CheckAndFailoverState( td ) then
        return
    end

    if self.hasDirtyMetaData then
    --Member join or left, update meta-data and continue
        SLog("*** Group meta-data needs update...")

        self:UpdateGroupSkill( td )
        self:UpdateGroupCoords( td )
        lobby = td:GetGroupLobby() --refresh (incase changes made)

        --update comparitive data fields before proceeding
        local lobCoords = lobby:GetField( LobbyModelFields.Coords )
        self.localCoords = { tonumber(lobCoords[1]), tonumber(lobCoords[2]) }

        self.localSkill = lobby:GetField( LobbyModelFields.MedianSkill )

        self.hasDirtyMetaData = false
    end

    --TD-TODO Handle kicking

    local lobState = lobby:GetField( LobbyModelFields.State )

    --Only pertains to when we're actually searching; otherwise, we block member data being set/consumed correctly.
    if self.isSearching then

        if lobState ~= kLobbyState.GroupSearching then
            td.groupLobby:SetState( kLobbyState.GroupSearching )
            td:TriggerLobbyMetaDataUpload( lobby:GetId() )
        end

        if self.searchStartedTime + self.kSearchingTimeLimit < time then
        --max time allotted exceeded, fail out, create lobby
            self.isSearching = false
            SLog("INFO: Maximum time-limit hit for match-search!")
            SLog("INFO: No applicable match-lobbies found for group, creating new public lobby...")
            td:SetLocalGroupId( lobby:GetId() )
            td:CreateLobby( Client.SteamLobbyType_Public, false )
            return
        end

        if self.lastSearchTime + self.kSearchIntervalTime > time then
            return
        end

    --Note: activeTargetLobby will be populated on an _event_ trigger basis, not update-loop tick
        if self.activeTargetLobby ~= nil then
        --we've found a match, attempt to assign and trigger join-flow

            SLog("INFO: Have applicable match lobby-id for group, setting id...")
            td.groupLobby:SetField( LobbyModelFields.TargetLobbyId, self.activeTargetLobby )
            td:TriggerLobbyMetaDataUpload( lobby:GetId() )

            self.isSearching = false
            return
            
        else
        --run limit checks, interval, and re-search step

            if self.lastSearchTime + self.kSearchIntervalTime <= time then

                self.numSearchAttempts = self.numSearchAttempts + 1
                self.lastSearchTime = time
                
                if self.numSearchAttempts % self.kSearchTickStepMod == 0 then
                --increase evert 3rd step
                    self.currentDistanceLimit = math.min( self.kMaxGeoDist , self.currentDistanceLimit + self.kGeoDistStep )
                    self.currentSkillLimit = math.min( kLobbyMaxSkillSearchLimit, self.currentSkillLimit + self.kSkillRangeLimitStep )
                end
                
                SLog("  ...no match-lobby found, re-run search at tick[%s]", self.numSearchAttempts)
                SLog("      [Search Parameters]")
                SLog("             Skill-Limit:  %s", self.currentSkillLimit)
                SLog("              Dist-Limit:  %s", self.currentDistanceLimit)

                --gradually increase the size of the return lobby list for more possible matches
                td:RunLobbySearch( kLobbySearchDefaultListSize + ( self.numSearchAttempts * kLobbySearchListSizeAttemptTick ))

            end

        end

    end
    
    if not self.isSearching then
    --should have a match, need to await propagation and then attempt join (after setting what local group-id)

        if lobState == kLobbyState.GroupWaiting then
            return
        end

        local targetId = lobby:GetField( LobbyModelFields.TargetLobbyId )

        if lobState == kLobbyState.GroupSearching and targetId and targetId ~= "" then
            td.groupLobby:SetState( kLobbyState.GroupReady )
            td:TriggerLobbyMetaDataUpload( lobby:GetId() )
            return

        elseif lobState == kLobbyState.GroupReady then

            -- STURNCLAW
            SLog("GroupClientOwner: Joining MATCH lobby from group")
            self:DebugDump(true)

            td:SetLocalGroupId( lobby:GetId() )
            td:LeaveGroup( lobby:GetId(), true )
            td:JoinLobby( targetId, false, false )
            
            return
        end

    end
    
end

--TD-FIXME Need to "reset" all logic-flow applicable fields on either lobby enter OR fail-over

function GroupClientOwner:DebugDump(full)
    SLog("\t\t [GroupClientOwner]")

    SLog("\t\t\t (internals) ")
    SLog("\t\t\t\t       isSearching:   %s", self.isSearching)
    SLog("\t\t\t\t   queuedMatchFind:   %s", self.queuedMatchFind)

    SLog("\t\t\t      lastSearchTime:   %s", self.lastSearchTime)
    SLog("\t\t\t   searchStartedTime:   %s", self.searchStartedTime)
    SLog("\t\t\t   numSearchAttempts:   %s", self.numSearchAttempts)
    SLog("\t\t\tcurrentDistanceLimit:   %s", self.currentDistanceLimit)
    SLog("\t\t\t   currentSkillLimit:   %s", self.currentSkillLimit)
    SLog("\t\t\t   activeTargetLobby:   %s", self.activeTargetLobby)
    SLog("\t\t\t          localSkill:   %s", self.localSkill)
    SLog("\t\t\t         localCoords:   %s", self.localCoords)
    --TD-TODO Add all internal vars
end


--**** TEMP - REMOVE ****
Event.Hook("Console_td_groupsearch", function()
    SLog("  Start match search for current GroupLobby...")
    Thunderdome():StartGroupSearch()
end)