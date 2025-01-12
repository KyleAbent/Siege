-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/thunderdome/LobbyClient.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")
Script.Load("lua/thunderdome/LobbyUtils.lua")

Script.Load("lua/thunderdome/LobbyMemberModel.lua")
Script.Load("lua/thunderdome/LobbyModel.lua")


-------------------------------------------------------------------------------


class 'LobbyClientSearch'


--Min / Max geographic distances allowed when searching (in km)
LobbyClientSearch.kDefaultGeoDist = 250         --todo tune
LobbyClientSearch.kMaxGeoDist = 9500            --todo tune (ideally, smallest viable value)
--TODO/FIXME Need to set this max-dist per which region local-client is in, otherwise...it'll isolate regions even more
LobbyClientSearch.kGeoDistStep = 500

--Amount the search routine increases skill range check by with each iteration
LobbyClientSearch.kDefaultSkillRange = 100

--Maximum allowed variance between local client's skill and available lobbies
LobbyClientSearch.kSkillRangeLimit = kLobbyMaxSkillSearchLimit
--TODO Instead of using above, experiement with having it be +/- 1 skill-tier from local-client as limit

--Amount the skill average of a search-filter limits are increased (+/-) per search-step    --TODO Look into applying only upper/lower bounds
LobbyClientSearch.kSkillRangeLimitStep = 100     --todo tune

--Amount of time that must pass between each search step
LobbyClientSearch.kSearchIntervalTime = 1    -- +rand?

--Number of times a specific set of search filters/checks can be run
--before increasing those limits (e.g. increase geo-desic range limit, etc)
LobbyClientSearch.kSearchStepAttemptsLimit = 1

--Maximum amount of time local-client will perform searching
--Note: MaxNumSearches = kSearchingTimeLimit / kSearchIntervalTime
LobbyClientSearch.kSearchingTimeLimit = 25      --todo tune


function LobbyClientSearch:Initialize()
    SLog("LobbyClientSearch:Initialize()")

    --Local-client time search began
    self.searchStartedTime = 0

    --Last timestamp which update was run
    self.lastUpdate = 0

    --Time (not delta additive) last search attempt was made, used for fail-out check(s)
    self.lastSearchTime = 0

    --Denotes the time-stepping between running searches
    self.searchRunInterval = self.kSearchIntervalTime

    --current limiter for max allowed skill-range for active search interval
    self.currentSkillLimit = self.kDefaultSkillRange

    --current limiter for max allowed geo-distance for active search interval
    self.currentDistanceLimit = self.kDefaultGeoDist

    local playerData = Thunderdome():GetLocalPlayerProfile()
    SLog("\t playerData: \n%s", playerData)
    assert(playerData and type(playerData) == "table")
    assert(playerData.skill)
    assert(playerData.lat and playerData.long)

    --!!TEMP!!
    --local playerData = { skill = 138, lat = 35.9, long = -84.1 }

    --simple storage of local client geo-coords (pulled form Hive response)
    self.localCoords = { tonumber(playerData.lat), tonumber(playerData.long) }
    Log("\t self.localCoords = %s", self.localCoords)

    --Local Client's current Hive Skill value
    self.localSkill = playerData.skill
    Log("\t self.localSkill = %s", self.localSkill)

    self:RegisterSearchEvents()

    --Simple internal flag to denote if is in "active" search routine
    self.searchRunning = false

    --Track number of times a search has been performed. Can be used for "fail-out" checks
    self.searchStepsAttempts = 0

    --total number of search attempts made thus far
    self.totalSearchAttempts = 0

    --Cached list (reset each time NEW search is initiated, not at each step) to hold list of
    --LobbyIDs which are considered "invalid" (filtered out for any reason)
    self.cachedDiscardList = {}

    --Active "Viable" selected and filtered LobbyID based on last search attempt
    self.activeTargetLobby = false

end

function LobbyClientSearch:Destroy()
    self:UnRegisterSearchEvents()
end

function LobbyClientSearch:RegisterSearchEvents()
    Thunderdome_AddListener( kThunderdomeEvents.OnSearchResults, self.OnSearchResults )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyCreated, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyCreated] )
end

function LobbyClientSearch:UnRegisterSearchEvents()
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyCreated, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyCreated] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnSearchResults, self.OnSearchResults )
end


function LobbyClientSearch:GetLobbyDistance( lobbyCoords, clientCoords )
    --SLog("LobbyClientSearch:GetLobbyDistance( %s, %s )", lobbyCoords, clientCoords)
    assert(lobbyCoords and #lobbyCoords == 2)
    assert(clientCoords and #clientCoords == 2)
    local dist = CalcGeoDistance( lobbyCoords[1], lobbyCoords[2], clientCoords[1], clientCoords[2] )
    --?? flatten to smaller value?  e.g.  / 1000 (iirc, the return is in meters)
    return dist
end

function LobbyClientSearch:GetLobbySkillDiff( lobbySkill, clientSkill )
     --don't care if it's above or below local-client skill, only the range
     --XXX above note might be detrimental ...ideally, clients should be placed in matches at their range, BUT next
     --bext option would be slightly above (not below), only then should lower ranked matches be checked.
    return math.round(math.abs( lobbySkill - clientSkill ))
end

--This does not "filter" anything for quality just the technical "can join" check
function LobbyClientSearch:GetIsValidLobby( lobby )
    assert(lobby)

    local distance = lobby:GetField( LobbyModelFields.LocalDistance )
    local skillDiff = self:GetLobbySkillDiff( lobby:GetField( LobbyModelFields.MedianSkill ), self.localSkill )
    local isJoinable = GetIsLobbyJoinable( lobby )  --checks state, build, steam-branch and member count
    local kickedIds = lobby:GetField( LobbyModelFields.Kicked )
    local isKicked = false
    if ( kickedIds and kickedIds ~= "" and #kickedIds > 0 ) then
        isKicked = table.icontains( kickedIds, Thunderdome():GetLocalSteam64Id() )
    end
        
    local valid = false
    valid = distance <= self.currentDistanceLimit or distance == 0
    valid = valid and skillDiff <= self.currentSkillLimit
    valid = valid and isJoinable
    valid = valid and not isKicked
    --TODO Add more granular range checks (e.g. if localSkill >= lobSkill(t6) OK no matter what, etc.  ...?)
    --TODO Add check for if local-client was kicked/banned/community-banned/etc...lobby data is loaded, so should be in scope
    return valid
end

function LobbyClientSearch:SortFilteredResults( results )
    assert(results and type(results) == "table")

    local localSkill = self.localSkill

    local DumpRes = function(r)
        if g_thunderdomeVerbose then
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

--Parse down the fetched lobby list into a list that's applicable to local client
LobbyClientSearch.OnSearchResults = function(self)
    --Optionally allow data to be provided instead of fetched (makes testing easier)
    local list = Thunderdome():GetSearchResultsList()

    if #list > 0 then
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

                if self:GetIsValidLobby( list[i] ) then     --XX Feed validity bounds as param?
                    table.insert( filteredResults, list[i] )
                else
                    table.insert( self.cachedDiscardList, list[i] )
                end
            end
        end

    --XXXX Might want to do insertunique of potential (best sorted) lob-ids into cache, and only after X time, select from said list
    --  Doing this would risk lob-state being more innaccurate, but would allow a potentially larger sample-size before selection/join-attempts
        
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
                    Thunderdome():SignalSearchSuccess( self.activeTargetLobby )
                    break --bails immediately, otherwise it'll attempt to join next in list
                end
            end

        end

        Log("*LobbySearch - DONE - Attempt: %s*", self.totalSearchAttempts)
        return
    end

    SLog("\t No lobbies in list, re-run...")
end

--Prompts this to begin searching on next self:Update() call
function LobbyClientSearch:BeginLobbySearch()
    SLog("LobbyClientSearch:BeginLobbySearch()")
    self.searchStartedTime = 0
    self.lastSearchTime = 0
    self.searchRunning = true
    self.totalSearchAttempts = 0
    self.cachedDiscardList = {}
    self.activeTargetLobby = false
end

--Note: this function is inherently throttled to max-rate of ThunderdomeManager:Update invocation rate
function LobbyClientSearch:Update( thunderDome, deltaTime, time )

    if not self.searchRunning then
        return
    end

    if self.lastSearchTime + self.kSearchIntervalTime > time then
        return
    end

    --Halt searching while join attempt/target in-progress
    if self.activeTargetLobby then
        return
    end

    --Actual start of new search run
    if self.lastSearchTime == 0 then

        self.searchStartedTime = time
        self.lastSearchTime = time
        self.searchStepsAttempts = 1
        SLog("\t Starting initial search...")
        thunderDome:RunLobbySearch( kLobbySearchDefaultListSize )

    --Active Search running, continue stepping
    elseif self.lastSearchTime > 0 then

        if self.searchStartedTime + self.kSearchingTimeLimit <= time then    --XX max search steps limit?
        --Search failed, no results to this point
            SLog("\t Search start-time[%s] exceeded max timelimit[%s]", self.searchStartedTime, self.kSearchingTimeLimit)
            self.searchRunning = false
            self.searchStepsAttempts = self.searchStepsAttempts + 1
            self.totalSearchAttempts = self.totalSearchAttempts + 1
            self.lastSearchTime = time
            
            thunderDome:SignalSearchExhausted()  --No viable matches found, fail-out
        end

        --Make another search query and parse data
        if self.lastSearchTime + self.searchRunInterval <= time then
            SLog("\t Last search time hit search-interval, run search...")
            self.searchStepsAttempts = self.searchStepsAttempts + 1
            self.totalSearchAttempts = self.totalSearchAttempts + 1

            if self.searchStepsAttempts > self.kSearchStepAttemptsLimit then
                SLog("\t Number of attempts for current step[%s] hit, increase filter-bounds, run search...", self.totalSearchAttempts)
                self.searchStepsAttempts = 1

                --increase skill range, but clamp to +/- kSkillRangeLimit of local client skill
                self.currentSkillLimit = math.min( math.max(self.currentSkillLimit + self.kSkillRangeLimitStep, self.currentSkillLimit), self.kSkillRangeLimit )

                --increase max distance filter value, but always use smallest available within kMaxGeoDist
                self.currentDistanceLimit = math.min( self.currentDistanceLimit + self.kGeoDistStep, self.kMaxGeoDist )

                SLog("\t\t  currentSkillLimit:      %s", self.currentSkillLimit)
                SLog("\t\t  currentDistanceLimit:   %s", self.currentDistanceLimit)
            end

            self.lastSearchTime = time
            
            --gradually increase the size of the return lobby list for more possible matches
            thunderDome:RunLobbySearch( kLobbySearchDefaultListSize + ( self.totalSearchAttempts * kLobbySearchListSizeAttemptTick ))
        end

    end

end

function LobbyClientSearch:DebugDump(full)
    Log("\t [LobbyClientSearch]")
    Log("\t\t lastSearchTime: %s", self.lastSearchTime)
    Log("\t\t searchRunning: %s", self.searchRunning)
    Log("\t\t searchStepsAttempts: %s", self.searchStepsAttempts)
end


local TestSearchTimeout = function()
    Log("")
    Log("=== Running LobbyClientSearch - Searching Timeout ===\n")



    Log("=======================================================")
    Log("")
end
Event.Hook("Console_td_test_search_timeout", TestSearchTimeout)