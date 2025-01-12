-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. ============
--
-- lua\ThunderdomeRules.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =======================


Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")

local gThunderdomeRulesEntId = Entity.invalidId

local gTimerTickRate = 1

--Max time after _last_ client connected server will wait for more clients to connect 
--before flipping to assigning teams
local kMaxAwaitingConnectingClients = 30    --seconds       --TD-TODO change to global (for tweaks via extension)?

--Max time after last client connected server will wait before processing unbalanced-teams forfeit check
local kMaxAwaitingAssignForfeitDelay = 2    -- seconds

local kPollRRPlayersRate = 0.5     -- ~2 times a second

--Max amount of time, after initial team-assign + lastClientConnect that auto-concede checks begin
local kMaxWaitForPlayersOnTeams = 60 --seconds

--Time after countdown has completed which a team entirely made of Bots will auto-concede outside a round
local kForfeitExecutionDelay = 12  --seconds

--time before forfeit match is set, to triggering during a round
local kForfeitExecutionGameDelay = 3

local kFullBotTeamCount = 6

--Number of players missing from a team at which point automatic forfeit should concede the match
local kTeamImbalanceThreshold = 2

--multiplier used to decrease any of the default-value Timers, so no undue waiting before proceeding
local kForcedConcedeTimerDelayDecreaseFactor = 0.4

--Percentage of total round-time required for a player with Commander time to be considered a victory
local kMinCommTimeForWinPercent = 0.3   --%


-------------------------------------------------------------------------------


class 'ThunderdomeRules' (Entity)

ThunderdomeRules.kMapName = "thunderdome_rules"

ThunderdomeRules.kMatchStates = enum({'AwaitingPlayers', 'PreMatch', 'RoundOne', 'Intermission', 'RoundTwo', 'RematchVote', 'Shutdown'})

ThunderdomeRules.kTimerTypes = enum({ 'PreMatch', 'VoteDrawMatch', 'Intermission', 'RematchVote', 'Shutdown', 'None' })

ThunderdomeRules.kForfeitTypes = enum({ 'None', 'InactiveRound', 'ActiveRound', 'DrawMatch', 'RoundTimeLimit' })


local kTimerTypeStartValues = 
{
    [ThunderdomeRules.kTimerTypes.PreMatch] = 10,           --Triggers AFTER at least some _expected_ clients joined server
    [ThunderdomeRules.kTimerTypes.VoteDrawMatch] = 60,      --Triggers after round start with 5/6 players on one or both teams
    [ThunderdomeRules.kTimerTypes.Intermission] = 90,       --Triggers AFTER post-end pause happens on first Round
    [ThunderdomeRules.kTimerTypes.RematchVote] = 5,         --Triggers after second round end, and delays long enough for stats viewing, trigger a vote
    [ThunderdomeRules.kTimerTypes.Shutdown] = 10,           --Triggers AFTER all clients assigned to RR (useful for Remain votes, etc)
}

local kTimerTypeDelayValues =
{
    [ThunderdomeRules.kTimerTypes.PreMatch] = 5,
    [ThunderdomeRules.kTimerTypes.VoteDrawMatch] = 5,
    [ThunderdomeRules.kTimerTypes.Intermission] = 15,
    [ThunderdomeRules.kTimerTypes.RematchVote] = 35,
    [ThunderdomeRules.kTimerTypes.Shutdown] = 30,
}


ThunderdomeRules.networkVars =      --TD-TODO int upper limits should be (local)globals, which reference TD globals
{
    --Note: will need to increase if rematch or sudden-death added
    round = "integer (0 to 2)",
    state = "enum ThunderdomeRules.kMatchStates",
    activeTimer = "integer (-1 to 600)",
    forfeitTimer = "integer (-1 to 120)",
    --Note: we don't need milliseconds for this time, don't use "time" field-type
    timerStart = "integer",
    timerStarted = "boolean",
    timerType = "enum ThunderdomeRules.kTimerTypes",
    matchCompleted = "boolean",
    isForcdedConcedeCleanupPending = "boolean",
    isForcedConcedePending = "boolean",
    forfeitWarningEnabled = "boolean",
    forfeitingTeam = "integer (0 to 2)",    --TD-TODO hook up team-index globals
    forfeitType = "enum ThunderdomeRules.kForfeitTypes",
    privateMatch = "boolean",
}


ThunderdomeRules.kStatsNotifyDelay = 5  --seconds



if Client then

ThunderdomeRules.kClientTimerGUIScriptName = "Hud2/thunderdome/GUIReadyRoomDelayTimer"

ThunderdomeRules.kTimerLeadTickSound = "sound/NS2.fev/common/select"
Client.PrecacheLocalSound(ThunderdomeRules.kTimerLeadTickSound)

--Value indicates when .activeTimer is at or below this, the kTimerTickSound will play
ThunderdomeRules.kTimeLeadInSoundThreshold = 15
ThunderdomeRules.kTimeWarnSoundThreshold = 5

end


function ThunderdomeRules:OnCreate()

    Log("ThunderdomeRules:OnCreate()")

    if not Predict then
        assert( Shared.GetThunderdomeEnabled(), "ThunderdomeRules initialized when Thunderdome-Mode not enabled" )
    end
    
    self:SetUpdates(true, kDefaultUpdateRate)

    --track the number of rounds played thus far
    self.round = 0

    --the current state of the system(game-rules)
    self.state = self.kMatchStates.AwaitingPlayers

    --hold current value of actively running timer. Only ever counts down, never up
    self.activeTimer = -1

    --Countdown time until forfeit condition triggers, for gui display
    self.forfeitTimer = -1

    --flag indicates if TD instance is set as private or not. Private matches cannot earn rewards or update skills
    self.privateMatch = false

    if Client then

        self.timerTickVolume = 1

        self:AddFieldWatcher( "activeTimer", 
            function(self2)
                local skipSound = self2.state == self2.kMatchStates.RematchVote

                if self2.timerType == self2.kTimerTypes.None or self2.activeTimer <= 0 or skipSound then
                    return true
                end

                if self2.activeTimer <= self2.kTimeLeadInSoundThreshold then
                    local aTSv = self2:GetStartTimerValue(self2.timerType)
                    local scaled = self2.activeTimer / aTSv
                    self.timerTickVolume = Clamp( 1 - (scaled + 0.1), 0, 1) --0-1 scaling, inverted, with a minimum

                    if self2.activeTimer <= self2.kTimeWarnSoundThreshold then
                        self.timerTickVolume = 1
                    end

                    Shared.PlaySound(nil, self2.kTimerLeadTickSound, self.timerTickVolume, (-0.9 - ( scaled - 0.1 )) )
                end

                return true
            end
        )

        self.clientMatchState = nil
        self.clientRound = 0

    end

    --Indicates the class/type of current active timer. Timers are only
    --running after/before rounds are played, and used to break-up a
    --match into more digestable chunks
    self.timerType = self.kTimerTypes.None

    --Rate which the timer value updates (seconds)
    --self.timeTick = gTimerTickRate

    --Ensure this is relevant to all clients, all the time
    self:SetRelevancyDistance(Math.infinity)
    self:SetPropagate(Entity.Propagate_Always)

    gThunderdomeRulesEntId = self:GetId()   --Note: will differ on Server vs Client

    --time when timer starts 
    self.timerStart = -1
    self.timerStarted = false

    self.matchCompleted = false

    --flag to dentone the match is over, because of an "empty" team, one-shot tasks and shutdown
    self.isForcdedConcedeCleanupPending = false

    --Flag to denote this class needs to forcibly end a round shortly after it started. This is only used
    --in scenarios where an entire team leaves, no clients are connecting, and X time has passed. We use this
    --to prevent dead-lock situations when the Match could not proceed unless a game against Bots was forcibly played (bleh).
    self.isForcedConcedePending = false

    --Flag denotes if clients should be notified match will forfeit soon if teams remain imbalanced
    self.forfeitWarningEnabled = false

    --Team Index of which team is going to forfeit the match
    self.forfeitingTeam = kNeutralTeamType

    --Flag to denote the manner/type of forfeit actions to be taken (replicated for client use)
    self.forfeitType = self.kForfeitTypes.None


    if Server then

        self.hasRematched = false

        self.hasShutdown = false

        self.pendinClientStatsNotify = false

        --Delay before concede triggers in order for round start sequence to fully complete
        self.timeForfeitStart = 0

        --dentoes the shared-time which possible forfeit conditions are met, reset when conditions are not met
        self.timeForfeitWarningStart = 0

        --used to track time between clients connecting, so timeout can occur if a client crashed, alt-f4'd, etc.
        --without this tracked, matches will never begin until _all_ clients are connected.
        self.lastClientConnectTime = 0

        self.lastReadyRoomPollTime = 0

        self.initialCommanders = 
        {
            [kTeam1Index] = 0,
            [kTeam2Index] = 0,
        }

        --data store to track player assignments when
        self.initialTeams =         --TD-FIXME Need to handle players leaving match mid-round(s)
        {
            [kTeam1Index] = {},
            [kTeam2Index] = {},
        }

        --data store to track team sizes for auto-forfeit thresholds
        self.initialTeamSize =
        {
            [kTeam1Index] = 0,
            [kTeam2Index] = 0,
        }

        self.initializedTeamAssignments = false

        self.privateMatch = Server.GetThunderdomeIsPrivate()

    end

end

function ThunderdomeRules:GetTimerTypeStartDelay( type )
    local timerDelay =  kTimerTypeDelayValues[type]
    if self.isForcdedConcedeCleanupPending and timerDelay then
        timerDelay = math.floor( timerDelay * kForcedConcedeTimerDelayDecreaseFactor )
    end
    return timerDelay
end

function ThunderdomeRules:GetStartTimerValue( type )
    return kTimerTypeStartValues[type]
end


if Server then

    function ThunderdomeRules:SetupInitialTeamAssignments()
        Log("ThunderdomeRules:SetupInitialTeamAssignments()")

        local team1 = {}
        local team2 = {}

        Server.GetTDTeamAssignments( team1, kTeam1Index )
        Server.GetTDTeamAssignments( team2, kTeam2Index )

        Log("\t  team1: %s",team1)
        Log("\t  team2: %s",team2)

        local team1CommId = Server.GetTDCommanderAssignments( kTeam1Index )
        local team2CommId = Server.GetTDCommanderAssignments( kTeam2Index )

        Log("\t   team1CommId:  %s", team1CommId)
        Log("\t   team2CommId:  %s", team2CommId)

        --Crap asserts (borderline useless in this format), to allow single-dev testing of system  --  TODO Remove for prod
        assert( #team1 > 0 or #team2 > 0, "One or more teams-list is empty" )
        assert( team1CommId or team2CommId, "One or more teams does not have a CommanderID set")

        for m = 1, #team1 do    --Marines
            local clientId = Shared.ConvertSteamId64To32(team1[m])
            table.insert(self.initialTeams[kTeam1Index], clientId)
        end

        for a = 1, #team2 do    --Aliens
            local clientId = Shared.ConvertSteamId64To32(team2[a])
            table.insert(self.initialTeams[kTeam2Index], clientId)
        end

        --Cache initial team sizes for forfeit calculations
        self.initialTeamSize[kTeam1Index] = #team1
        self.initialTeamSize[kTeam2Index] = #team2

        --Cache Commander IDs, per Round 1 team assignments
        self.initialCommanders[kTeam1Index] = Shared.ConvertSteamId64To32(team1CommId)
        self.initialCommanders[kTeam2Index] = Shared.ConvertSteamId64To32(team2CommId)

        Log("\t initialTeams[kTeam1Index]: %s", self.initialTeams[kTeam1Index])
        Log("\t initialTeams[kTeam2Index]: %s", self.initialTeams[kTeam2Index])

        self.initializedTeamAssignments = true

    end

    function ThunderdomeRules:GetRound()
        return self.round
    end

    function ThunderdomeRules:GetMatchState()
        return self.state
    end

    function ThunderdomeRules:GetIsPrivateMatch()
        return self.privateMatch
    end

    function ThunderdomeRules:OnVotedSkipIntermissionSuccess()
        Log("ThunderdomeRules:OnVotedSkipIntermissionSuccess()")
        if self:GetMatchState() == self.kMatchStates.Intermission and self.timerType == self.kTimerTypes.Intermission then
            self.activeTimer = 1
        else
            Log("  Warning: skipping intermission while not in intermission phase!")
            self:DebugDump()
        end
    end

    function ThunderdomeRules:OnVotedRematchSuccess(data)
        Log("ThunderdomeRules:OnVotedRematchSuccess()")
        self.round = 0
        self.hasRematched = true
        self:ResetTimer()
        self:SetupRematch()
    end

    function ThunderdomeRules:OnVotedRematchFailed()
        Log("ThunderdomeRules:OnVotedRematchFailed()")
        self:ResetTimer()
        self:FinalizeMatch()
    end

    function ThunderdomeRules:OnVotedDrawGameSuccess(data)
        Log("ThunderdomeRules:OnVotedDrawGameSuccess()")

        self:DebugDump()

        self:ResetForcedRoundLimitEnd()

        self.forfeitType = self.kForfeitTypes.DrawMatch
        self.forfeitingTeam = kNeutralTeamType  --Draw Game
        self.timeForfeitStart = Shared.GetTime()
        self.isForcedConcedePending = true
        Log("\n\t !!!  self.isForcedConcedePending = TRUE   \n")
    end

    function ThunderdomeRules:SetupRematch()
        Log("ThunderdomeRules:SetupRematch()")
        self.matchCompleted = false
        self:SetMatchState( self.kMatchStates.PreMatch )
        self:SetTimerActive( self.kTimerTypes.PreMatch )
    end
    
    function ThunderdomeRules:FinalizeMatch()
        Log("ThunderdomeRules:FinalizeMatch()")
        self:SetMatchState( self.kMatchStates.Shutdown )
        self:SetTimerActive( self.kTimerTypes.Shutdown )

        --mostly complete rest in order for UI focused fields to be in correct state
        self.forfeitType = self.kForfeitTypes.None
        self.forfeitWarningEnabled = false
        self.timeForfeitWarningStart = 0
        self.isForcedConcedePending = false
        self.forfeitingTeam = kNeutralTeamType
        self.forfeitTimer = 0
        self.timeForfeitStart = 0

        --Notify clients the match is complete
        Server.SendNetworkMessage("Thunderdome_MatchFinalized", {}, true)
    end

    function ThunderdomeRules:SetTimerActive( type )
        Log("ThunderdomeRules:SetTimerActive( %s )", type)
        assert(type)
        assert(self.kTimerTypes[type])
        self:ResetTimer()
        local time = math.floor(Shared.GetTime())
        self.timerType = type
        self.activeTimer = self:GetStartTimerValue(type)
        self.timerStart = time
        self.timerStarted = false
        Log("\t    Add timer callback['UpdateTimer']...")
        self:AddTimedCallback( self.UpdateTimer, gTimerTickRate )
    end
    
    function ThunderdomeRules:ResetForcedRoundLimitEnd()
        self.forfeitType = self.kForfeitTypes.None
        self.forfeitWarningEnabled = false
        self.timeForfeitWarningStart = 0
        self.isForcdedConcedeCleanupPending = false
        self.isForcedConcedePending = false
        self.forfeitingTeam = kNeutralTeamType
        self.forfeitTimer = 0
        self.timeForfeitStart = 0
    end

    function ThunderdomeRules:StartRound()  --TD-TODO Review/revise if tie-breaker added
        Log("ThunderdomeRules:StartRound()")

        self.round = self.round + 1

        self:ResetForcedRoundLimitEnd()

        if self.round == 1 then
            self:SetMatchState( self.kMatchStates.RoundOne )
        elseif self.round == 2 then
            self:SetMatchState( self.kMatchStates.RoundTwo )
        end
        self:ResetTimer()

        local team1Size, team2Size = self:GetInitialTeamSizes()

        local gameRules = GetGamerules()

        local t1P, _, t1B = gameRules:GetTeam1():GetNumPlayers()
        local t2P, _, t2B = gameRules:GetTeam2():GetNumPlayers()
        
        local team1Players = t1P - t1B
        local team2Players = t2P - t2B

        Log("ThunderdomeRules:StartRound()")
        Log("")
        Log("  team1Size: %s", team1Size)
        Log("  team2Size: %s", team2Size)
        Log("  team1Players: %s", team1Players)
        Log("  team2Players: %s", team2Players)
        Log("")
        
        -- Start a vote to optionally draw the match at 5v6 or 5v5
        -- If we've lost more than 1 player, auto-forfeit kicks in
        if (team1Size - team1Players == 1) or (team2Size - team2Players == 1) then
            self:SetTimerActive( self.kTimerTypes.VoteDrawMatch )
        end
    end

    function ThunderdomeRules:EndRound()    --TD-TODO revise later so tie-breaker game can occur?
        Log("ThunderdomeRules:EndRound()")

        if self.isForcdedConcedeCleanupPending then
        --In this scenario, the match is now in non-playable state, end it quickly, but not for round-limit hit during Round 1
            if self.forfeitType ~= self.kForfeitTypes.RoundTimeLimit then
                self:FinalizeMatch()
                return
            else
            --Round 1 was a forced-draw due to time-limit hit, reset and proceed to Round 2
                self:ResetForcedRoundLimitEnd()
            end
        end

        if self.round == 1 then
            self:SetMatchState( self.kMatchStates.Intermission )
            self:SetTimerActive( self.kTimerTypes.Intermission )

        elseif self.round == 2 then

            -- Make sure we have all required players in the server before trying to do a rematch.
            local numClients = Server.GetNumClientsTotal()
            local numSpecs   = Server.GetNumSpectators()
            local numPlayers = numClients - numSpecs - #gServerBots

            self.matchCompleted = true

            local isRematchVoteEnabled = numPlayers == Server.GetThunderdomeExpectedPlayerCount()

            if isRematchVoteEnabled and not self.hasRematched then
            --No rematch vote triggered, and all still connected, setup vote step
                self:ResetTimer()
                self:SetMatchState( self.kMatchStates.RematchVote )
                self:SetTimerActive( self.kTimerTypes.RematchVote )
                return
            end

            self:FinalizeMatch()
        end
    end

    --Note: this is stubbed out this way incase need to compare before/after (or other game-state data)
    --is ever needed. For TD Beta1, it's not needed.
    function ThunderdomeRules:SetMatchState( newState )
        Log("ThunderdomeRules:SetMatchState( %s )", newState)
        assert(newState)
        assert(self.kMatchStates[newState])

        local oldState = self.state

        --ensure no unintentionaly "reset / duplicate" event occurs
        if oldState ~= newState then
            self.state = newState
        end

    end

    function ThunderdomeRules:ResetTimer()
        Log("ThunderdomeRules:ResetTimer()")
        self.activeTimer = -1
        self.timerStart = -1
        self.timerStarted = false
        self.timerType = self.kTimerTypes.None
    end

    function ThunderdomeRules:GetHasForcedMatchConcede()
        return self.isForcdedConcedeCleanupPending
    end

    function ThunderdomeRules:AssignPlayersToTeam( teamIdx, clientListOpt, commIdOpt )
        Log("ThunderdomeRules:AssignPlayersToTeam( %s )", teamIdx)

        assert(teamIdx == kTeam1Index or teamIdx == kTeam2Index)    --TD-TODO revise for spec-support

        local gameRules = GetGamerules()
        assert(gameRules)

        local clientsList = clientListOpt and clientListOpt or self.initialTeams[teamIdx]
        local commanderId = commIdOpt and commIdOpt or self.initialCommanders[teamIdx]
        Log("  Team-%s CommanderID: %s", teamIdx, commanderId)
        if #clientsList == 0 or commanderId == 0 then
            Log("  Empty team[%s] list, skip auto-assign...", teamIdx)
            return
        end
        
        local worldPlayers = gameRules:GetWorldTeam():GetPlayers()

        for p = 1, #worldPlayers do

            local player = worldPlayers[p]
            local client = Server.GetOwner(player)

            if client then

                local clientSteamId = client:GetUserId()

                for i = 1, #clientsList do

                    local steamId = clientsList[i]
                    if steamId == clientSteamId then

                        gameRules:JoinTeam( player, teamIdx, true )

                        if commanderId == clientSteamId then

                            --refresh to include team-data update, so Team object is valid
                            player = client:GetControllingPlayer()

                            local hasComm = player:GetTeam():GetCommander()
                            if not hasComm then
                                local ents = GetEntitiesForTeam("CommandStructure", teamIdx)
                                if #ents > 0 then
                                    player:SetOrigin(ents[1]:GetOrigin() + Vector(0, 1, 0))
                                    player:UseTarget(ents[1], 0)
                                    ents[1]:UpdateCommanderLogin(true)
                                else
                                    Log("Warning: Failed to find required entity to auto-login Commander[%s]", Shared.ConvertSteamId32To64( client:GetUserId() ) )
                                end
                            end
                        end

                    end

                end
                
            else
                Log("Error: Found player[%s] with no associated ServerClient object!", player:GetId())
            end

        end

        --Note: if below asserts...the round is basically broken, and match will fail. Only cause would be Commander client crashed while awaiting team-assignment
        --....that or the Commander is an asshole and bailed on their team.
        --TODO Review and revise team-assignment...potentially prompt a TEAM to vote Bot-Commander if this occurs??
        --assert(commAssigned, "Error: Failed to correctly assigned Team-%s Commander for Client: %s", teamIdx, commanderId)

    end
    
    function ThunderdomeRules:UpdateConnectedClients()

        local time = Shared.GetTime()
        if self.lastReadyRoomPollTime + kPollRRPlayersRate > time then
        --throttle, as we don't need per-tick rates
            return
        end
        --Log("ThunderdomeRules:UpdateConnectedClients( -- )")
        self.lastReadyRoomPollTime = time

        local gameRules = GetGamerules()
        assert(gameRules)

        --Allow joining once PreMatch timer is completed, or during RoundOne or RoundTwo match states
        local isTimerActive = ( self.timerType ~= self.kTimerTypes.None and self.activeTimer ~= -1 )
        local skipTeamAssignments =
            (
                self.state == self.kMatchStates.AwaitingPlayers or
                ( self.state == self.kMatchStates.PreMatch and isTimerActive ) or -- allow after PreMatch expired
                ( self.state == self.kMatchStates.Intermission and isTimerActive ) or -- allow after Intermission expired
                self.state == self.kMatchStates.RematchVote or
                self.state == self.kMatchStates.Shutdown
            )
        
        --Don't re-assign teams if match is done and no rematch vote passed
        if skipTeamAssignments or self.matchCompleted then
            return
        end

        local worldPlayers = gameRules:GetWorldTeam():GetPlayers()
        if #worldPlayers < 1 then
            return
        end

        local team1
        local team2
        local team1Comm
        local team2Comm

        if self.round > 1 or self.state == self.kMatchStates.Intermission then
        --Round Two is starting or has already started, so only read as swapped teams. Team assignments are provided to server as Round One format.
            local swappedTeams, swappedComms = self:GetSwappedTeams()
            team1 = swappedTeams[kTeam1Index]
            team2 = swappedTeams[kTeam2Index]
            team1Comm = swappedComms[kTeam1Index]
            team2Comm = swappedComms[kTeam2Index]
        else
            team1 = self.initialTeams[kTeam1Index]
            team2 = self.initialTeams[kTeam2Index]
            team1Comm = self.initialCommanders[kTeam1Index]
            team2Comm = self.initialCommanders[kTeam2Index]
        end

        for p = 1, #worldPlayers do

            local player = worldPlayers[p]
            local client = Server.GetOwner(player)

            if client and not client:GetIsVirtual() then    --safety check in case a Bot is bounced to RR at any point

                local clientSteamId = client:GetUserId()    --SteamID3 [without Universe/version]
                local kickClient = false
                local joinedTeamIdx = -1

                local isComm = clientSteamId == team1Comm or clientSteamId == team2Comm

                --Just assign clients to a team right now. Once all are on teams, then Commanders will
                --be assigned, and as byproduct, the round(s) will start.
                if table.icontains( team1, clientSteamId ) then
                    gameRules:JoinTeam( player, kTeam1Index, true )
                    joinedTeamIdx = kTeam1Index
                elseif table.icontains( team2, clientSteamId ) then
                    gameRules:JoinTeam( player, kTeam2Index, true )
                    joinedTeamIdx = kTeam2Index
                else
                    kickClient = true
                end

                if kickClient then

                    --Player was not in any of the ClientID lists set on TD-Server start, kick them out
                    Log("Kicking Client[S32: %s | S64: %s] due to not existing in any Team List!", clientSteamId, Shared.ConvertSteamId32To64(clientSteamId))
                    Server.DisconnectClient( client, "No Team assignment found" )      --TD-TODO Localize

                elseif isComm then

                    --force refresh to ensure Team data updated for this entity
                    player = client:GetControllingPlayer()

                    local hasComm = player:GetTeam():GetCommander()
                    if not hasComm then

                        local ents = GetEntitiesForTeam("CommandStructure", joinedTeamIdx)
                        if #ents > 0 then
                            Log("\t\t  Assigned Player[%s] As Commander!", player:GetId())
                            player:SetOrigin(ents[1]:GetOrigin() + Vector(0, 1, 0))
                            player:UseTarget(ents[1], 0)
                            ents[1]:UpdateCommanderLogin(true)
                        else
                            Log("Warning: Failed to find required entity to auto-login Commander[%s]", Shared.ConvertSteamId32To64( client:GetUserId() ) )
                        end

                    end

                end

            else
            --This can only occur if it's a Ghost Client (e.g. crashed) and timed out. it's VERY rare this will occur,
            --as once a ServerClient times out, their associated Player entity will be destroyed. However, it's possible
            --game-update timing could hit this, so log for it at a minimum.
                Log("Error: Found player[%s] with no associated ServerClient object!", player:GetId())  --??TD-TODO post this as error to SM?
            end

        end

    end

    -- Disconnect any players remaining on the server if we're in post-shutdown phase
    function ThunderdomeRules:DisconnectClientsPostMatch()

        local time = Shared.GetTime()
        if self.lastReadyRoomPollTime + kPollRRPlayersRate > time then
        --throttle, as we don't need per-tick rates
            return
        end
        Log("ThunderdomeRules:DisconnectClientsPostMatch()")
        self.lastReadyRoomPollTime = time

        local gameRules = GetGamerules()
        assert(gameRules)

        local worldPlayers = gameRules:GetWorldTeam():GetPlayers()
        if #worldPlayers < 1 then
            return
        end

        for p = 1, #worldPlayers do

            local player = worldPlayers[p]
            local client = Server.GetOwner(player)

            if client and not client:GetIsVirtual() then    --safety check in case a Bot is bounced to RR at any point

                local clientSteamId = client:GetUserId()    --SteamID3 [without Universe/version]

                Log("Kicking Client[S32: %s | S64: %s] due to server shutdown!", clientSteamId, Shared.ConvertSteamId32To64(clientSteamId))
                Server.DisconnectClient( client, "Server is shutting down" )      --TD-TODO Localize

            else
            --This can only occur if it's a Ghost Client (e.g. crashed) and timed out. it's VERY rare this will occur,
            --as once a ServerClient times out, their associated Player entity will be destroyed. However, it's possible
            --game-update timing could hit this, so log for it at a minimum.
                Log("Error: Found player[%s] with no associated ServerClient object!", player:GetId())  --??TD-TODO post this as error to SM?
            end
        end

    end

    --utility method to force-disconnect all clients, so server will auto-shutdown
    function ThunderdomeRules:DisconnectAllClients()
        Log("== ThunderdomeRules:DisconnectAllClients() ==")

        --Forcibly disconnect all clients on the server, since match is complete
        --run through all teams, as a safety measure in-case push back to RR failed
        --for any reason.
        local allPlayers = GetGamerules():GetWorldTeam():GetPlayers()
        for i = 1, #allPlayers do
            Server.SendCommand( allPlayers[i], "td_cl_matchend" )
        end
        allPlayers = nil

        allPlayers = GetGamerules():GetSpectatorTeam():GetPlayers()
        for i = 1, #allPlayers do
            Server.SendCommand( allPlayers[i], "td_cl_matchend" )
        end
        allPlayers = nil

        allPlayers = GetGamerules():GetTeam1():GetPlayers()
        for i = 1, #allPlayers do
            Server.SendCommand( allPlayers[i], "td_cl_matchend" )
        end
        allPlayers = nil

        allPlayers = GetGamerules():GetTeam2():GetPlayers()
        for i = 1, #allPlayers do
            Server.SendCommand( allPlayers[i], "td_cl_matchend" )
        end
        allPlayers = nil

    end

    function ThunderdomeRules:TriggerTimerStartEvent()
        Log("**  ThunderdomeRules:TriggerTimerStartEvent()  **")

        if self.timerType == self.kTimerTypes.Intermission then
            SetupThunderdomeIntermissionVote()
            StartVote("VoteThunderdomeSkipIntermission", nil, {})
        end

    end

    function ThunderdomeRules:TriggerTimerEndEvent()
        Log("**  ThunderdomeRules:TriggerTimerEndEvent()  **")

        if self.timerType == self.kTimerTypes.PreMatch then
        --Note: this should only ever be hit when ALL _expected_ players have joined the server
            Log("\t End   PreMatch Timer")
            self:AssignPlayersToTeam( kTeam1Index )
            self:AssignPlayersToTeam( kTeam2Index )
            self:ResetTimer()

        elseif self.timerType == self.kTimerTypes.Intermission then
        --This should only trigger upon a completed Round One, and after X delay to give players a quick break
            Log("\t End   Intermission Timer")
            local swappedTeams, swappedComms = self:GetSwappedTeams()
            assert(swappedTeams)
            assert(swappedComms)

            self:AssignPlayersToTeam( kTeam1Index, swappedTeams[kTeam1Index], swappedComms[kTeam1Index] )
            self:AssignPlayersToTeam( kTeam2Index, swappedTeams[kTeam2Index], swappedComms[kTeam2Index] )
            self:ResetTimer()
        
        elseif self.timerType == self.kTimerTypes.VoteDrawMatch then
            Log("\t End   VoteDrawMatch Timer")
            self:ResetTimer()

            -- FIXME: if another vote is active during this time, starting the vote will fail and it will be silently lost
            StartVote("VoteThunderdomeDrawGame", nil, {})

        elseif self.timerType == self.kTimerTypes.RematchVote then
            Log("\t End   RematchVote Timer")
            self:ResetTimer()
            
            -- FIXME: if another vote is active during this time, starting the vote will fail and it will be silently lost
            StartVote("VoteThunderdomeRematch", nil, {})

        elseif self.timerType == self.kTimerTypes.Shutdown then
            Log("\t End   Shutdown Timer")
            self:DisconnectAllClients()
            self:ResetTimer()

            -- any future connecting clients will be kicked directly
            self.hasShutdown = true

            -- delay slightly before forcibly disconnecting remaining clients
            self.lastReadyRoomPollTime = Shared.GetTime() + 2

            -- notify the server the match is completely finalized
            Server.SetThunderdomeMatchFinalized()
        end

    end

    function ThunderdomeRules:ProcessClientUnlocks( client, statFieldName, statValue )
        Log("ThunderdomeRules:ProcessClientUnlocks( -- )")

        if not client or not statFieldName or statValue == 0 then
            return
        end

        if statFieldName == kThunderdomeStatFields_TimePlayed then
            HandleFieldTimeUnlocks( client, statValue )

        elseif statFieldName == kThunderdomeStatFields_TimePlayedCommander then
            HandleCommanderTimeUnlocks( client, statValue )

        elseif statFieldName == kThunderdomeStatFields_Victories then
            HandleFieldWinsUnlocks( client, statValue )

        elseif statFieldName == kThunderdomeStatFields_CommanderVictories then
            HandleCommanderWinsUnlocks( client, statValue )

        end

    end
    
    --Parse data generated and feed in from PlayerRanking.lua -> PlayerRanking:EndGame()
    function ThunderdomeRules:RecordRoundSteamStats( round, clientMap )
        Log("ThunderdomeRules:RecordRoundSteamStats( -- )")
        
        if not round or not clientMap then
            Log("ERROR: Round data or clientMap was nil")
            return
        end

        local GetPlayerClient = function(steamId)
            if steamId == 0 then
                return false    --virtual
            end

            if clientMap[steamId] then
                return Server.GetClientById( clientMap[steamId] )
            end
            return false
        end

        -- Don't award "extra" wins if processing the same steamId multiple times
        local winAwardedMap = {}

        -- List of "player session records", may have multiple entries per steamid
        local roundPlayers = round.players
        for p = 1, #roundPlayers do

            --Note: All clients, when TD enabled, have their stats requested in the ClientConnect event (see ThunderdomeRules:OnPlayerConnect())
            local playerData = roundPlayers[p]

            if playerData.teamNumber ~= kTeam1Index and playerData.teamNumber ~= kTeam2Index then
            --ensure all RR or Spectator players are not processed for rewards (future proofing)
                goto continue
            end

            local client = GetPlayerClient( playerData.steamId )

            --Note: if a client's stats failed to fetch when they connected, all stat read/writes will fail
            --Also only allow rewards if player has completed the unlock requirement(s)

            local unlockedAwards = false
            if client then
            --Require all training missions before allowing unlocks
                unlockedAwards = Server.GetUserAchievement(client, "First_0_6")
                unlockedAwards = unlockedAwards and Server.GetUserAchievement(client, "First_0_7")
                unlockedAwards = unlockedAwards and Server.GetUserAchievement(client, "First_0_8")
                unlockedAwards = unlockedAwards and Server.GetUserAchievement(client, "First_0_9")
                unlockedAwards = unlockedAwards and Server.GetUserAchievement(client, "First_0_10")
                unlockedAwards = unlockedAwards and Server.GetUserAchievement(client, "First_1_0")
            end

            if client and unlockedAwards then

                --stats stored in seconds, displayed in hours
                local fieldTime = Server.GetUserStat_Int(client, kThunderdomeStatFields_TimePlayed) or 0
                local commTime = Server.GetUserStat_Int(client, kThunderdomeStatFields_TimePlayedCommander) or 0
                local fieldWins = Server.GetUserStat_Int(client, kThunderdomeStatFields_Victories) or 0
                local commWins = Server.GetUserStat_Int(client, kThunderdomeStatFields_CommanderVictories) or 0

                --Note: Commanders earn playtime just like everyone else, always
                fieldTime = fieldTime + math.round(playerData.marineTime + playerData.alienTime)

                Server.SetUserStat_Int(client, kThunderdomeStatFields_TimePlayed, fieldTime )
                self:ProcessClientUnlocks( client, kThunderdomeStatFields_TimePlayed, fieldTime )

                if playerData.alienCommTime > 0 or playerData.marineCommTime > 0 then
                    commTime = commTime + math.round(playerData.marineCommTime + playerData.alienCommTime)

                    Server.SetUserStat_Int(client, kThunderdomeStatFields_TimePlayedCommander, commTime )
                    self:ProcessClientUnlocks( client, kThunderdomeStatFields_TimePlayedCommander, commTime )
                end

                if round.winner == playerData.teamNumber and not winAwardedMap[playerData.steamId] then
                --Note: commanders earn wins like everyone else, always
                    fieldWins = fieldWins + 1

                    Server.SetUserStat_Int(client, kThunderdomeStatFields_Victories, fieldWins )
                    self:ProcessClientUnlocks( client, kThunderdomeStatFields_Victories, fieldWins )

                    if playerData.alienCommTime > 0 or playerData.marineCommTime > 0 then
                        local commTime = playerData.alienCommTime > 0 and playerData.alienCommTime or playerData.marineCommTime
                        local isCommWin = ( math.round(commTime) / math.round(round.gameTime) ) >= kMinCommTimeForWinPercent
                    
                        if isCommWin then
                            commWins = commWins + 1

                            Server.SetUserStat_Int(client, kThunderdomeStatFields_CommanderVictories, commWins )
                            self:ProcessClientUnlocks( client, kThunderdomeStatFields_CommanderVictories, commWins )
                        end
                    end

                    winAwardedMap[playerData.steamId] = true
                end

            else
            --User crashed or immediately bailed (split-second before this was called...or, Steam is down / server-offline)
            --either way, in these scenarios there isn't anything we can really do...sucks.
                if playerData.steamId ~= 0 then
                    Log("Warning: Failed to fetch ServerClient for player-data - SteamID: %s", playerData.steamId)
                end
            end

            ::continue::
        end

        --Flip flag to notify clients in X seconds. This is done to allow Steam some time to
        --deal with updating data, so when Clients go to read it, it's updated.
        self.lastStatsUpdateTime = Shared.GetTime()
        self.pendinClientStatsNotify = true

    end

    --Log the timestamp each time a client connects, for later checks in timer
    function ThunderdomeRules:OnPlayerConnect( client )
        if not client or client:GetIsVirtual() then
            return
        end
        self.lastClientConnectTime = Shared.GetTime()
    end

    --Handle/Log all incoming clients connecting to Thunderdome Server Instances
    Event.Hook("ClientConnect", 
        function( client )
            if Shared.GetThunderdomeEnabled() then
                GetThunderdomeRules():OnPlayerConnect( client )
            end
        end
    )

    function ThunderdomeRules:GetSwappedTeams()
        local swappedTeams = 
        {
            [kTeam1Index] = self.initialTeams[kTeam2Index],
            [kTeam2Index] = self.initialTeams[kTeam1Index],
        }

        local swappedComms = 
        {
            [kTeam1Index] = self.initialCommanders[kTeam2Index],
            [kTeam2Index] = self.initialCommanders[kTeam1Index],
        }

        return swappedTeams, swappedComms
    end

    function ThunderdomeRules:GetInitialTeamSizes()
        local isRound2 = self:GetMatchState() == self.kMatchStates.Intermission or self.round == 2

        local team1Size = isRound2 and self.initialTeamSize[kTeam2Index] or self.initialTeamSize[kTeam1Index]
        local team2Size = isRound2 and self.initialTeamSize[kTeam1Index] or self.initialTeamSize[kTeam2Index]

        return team1Size, team2Size
    end

    function ThunderdomeRules:UpdateTimer()
        Log("ThunderdomeRules:UpdateTimer()")
        local time = Shared.GetTime()
        
        if self.timerStart ~= -1 then

            local timerStartDelay = self:GetTimerTypeStartDelay( self.timerType )
            local preTimerDelayTime = self.timerStart + timerStartDelay
            if preTimerDelayTime > time then
                Log("\t  pre-timer delay[%s]...", preTimerDelayTime)
                return true
            end

            if not self.timerStarted then
                self:TriggerTimerStartEvent()
                self.timerStarted = true
            end

            self.activeTimer = self.activeTimer - gTimerTickRate
            if self.activeTimer == 0 then
                self:TriggerTimerEndEvent()
                return false
            end

            Log("\t Timer tick[%s]...", self.activeTimer)
            return true
        end

        Log("\t No timer active, stop callback-update...")
        return false
    end

    --This is called from OnUpdate, and only used when needing to trigger based on internal data/state
    function ThunderdomeRules:UpdateState()

        if self.state == self.kMatchStates.AwaitingPlayers then

            local beginPreMatch =   --TD-FIXME Revise/Review for use-case when client explicitly LEAVES/QUITS mid-match
                ( Server.GetNumPlayers() == Server.GetThunderdomeExpectedPlayerCount() ) and
                ( #self.initialTeams[kTeam1Index] + #self.initialTeams[kTeam2Index] == Server.GetThunderdomeExpectedPlayerCount() )

            --don't run awaiting-timer unless someone connected already
            if self.lastClientConnectTime > 0 and not beginPreMatch then
                if self.lastClientConnectTime + kMaxAwaitingConnectingClients < Shared.GetTime() then
                    beginPreMatch = true  --force team assignments, as kMaxAwaitingConnectingClients should've been enough time for additional/final clients to connect
                end
            end

            if beginPreMatch then
                self:SetTimerActive( self.kTimerTypes.PreMatch )
                self:SetMatchState( self.kMatchStates.PreMatch )
            end
        end
        
        if self.timerType == self.kTimerTypes.VoteDrawMatch then

            local gameRules = GetGamerules()

            local team1Size, team2Size = self:GetInitialTeamSizes()
            local t1P, _, t1B = gameRules:GetTeam1():GetNumPlayers()
            local t2P, _, t2B = gameRules:GetTeam2():GetNumPlayers()

            local team1Count = t1P - t1B
            local team2Count = t2P - t2B

            -- All players have connected and been assigned to teams
            -- Cancel pending draw-game vote
            if team1Count == team1Size and team2Count == team2Size then
                self:ResetTimer()
            end

        end
    
    end

    --Handle case when player leaves the server after they sucessfully connected. We do this in order for the
    --cached (per lobby shuffle) team/role assignments are safe to parse should it occur again (regardless of match-state).
    function ThunderdomeRules:OnClientDisconnect(client)
        Log("ThunderdomeRules:OnClientDisconnect( [client] )")
        assert(client)
        assert(client.GetUserId)

        local cUserId = client:GetUserId()

        for i = 1, #self.initialTeams[kTeam1Index] do
            if self.initialTeams[kTeam1Index][i] == cUserId then
                table.remove( self.initialTeams[kTeam1Index], i )
                break
            end
        end
        
        for i = 1, #self.initialTeams[kTeam2Index] do
            if self.initialTeams[kTeam2Index][i] == cUserId then
                table.remove( self.initialTeams[kTeam2Index], i )
                break
            end
        end

        --TODO Ideally, need to trigger a re-selection of volunteers if a commander leaves
        ----If this is done, need a TeamMessage sent to the applicable team (worded in a way that makes sense)
        if self.initialCommanders[kTeam1Index] == cUserId then
            self.initialCommanders[kTeam1Index] = 0
        end
        
        if self.initialCommanders[kTeam2Index] == cUserId then
            self.initialCommanders[kTeam2Index] = 0
        end
        
    end

    function ThunderdomeRules:TriggerMatchForfeit(gameRules, conceedingTeamIdx)
        
        if not self.isForcedConcedePending then
            Log("ERROR:  ThunderdomeRules  -  ForceConcedeRound call without force-pending flag set!")
            return
        end

        if gameRules and gameRules:GetGameStarted() then
        --Rounds must be started before concede sequence works correctly

            self.isForcedConcedePending = false
            Log("\n\t !!!  self.isForcedConcedePending = TRUE   \n")
            self.timeForfeitStart = 0

            self.isForcdedConcedeCleanupPending = true

            if conceedingTeamIdx == kTeam1Index then

                Log("||||||||||  Forcing Team1 to auto-concede")
                gameRules.team1.conceded = true
                gameRules:EndGame( gameRules.team2, true )

            elseif conceedingTeamIdx == kTeam2Index then

                Log("||||||||||  Forcing Team2 to auto-concede")
                gameRules.team2.conceded = true
                gameRules:EndGame( gameRules.team1, true )

            elseif conceedingTeamIdx == kNeutralTeamType then

                --Absolute round-time scenario, both teams lose
                Log("||||||||||  Forcing DRAW game, absolute round-time hit")
                gameRules:DrawGame()

            else
                
                if conceedingTeamIdx == nil then
                    Log("ERROR: Force-Concede called with invalid concede-team index!")
                end

                gameRules:DrawGame()    --fail-over, because we need to always ensure match is ended

            end

        end

        --assert?
    end

    function ThunderdomeRules:CheckAbsoluteRoundTimeDraw(gameRules, numConnecting)

        if not gameRules:GetGameStarted() then
            return
        end

        if self.forfeitType ~= self.kForfeitTypes.None and self.forfeitType ~= self.kForfeitTypes.RoundTimeLimit then
            return
        end

        local time = Shared.GetTime()
        local gameStartTime = gameRules:GetGameStartTime()
        local curRoundLen = time - gameStartTime
        local absoluteEndWarnTime = kThunderdomeRoundMaxTimeLimit - kAbsoluteRoundTimeWarningStartTime
        local isInAbsoluteWarnPeriod = (curRoundLen - absoluteEndWarnTime) >= 0

        if isInAbsoluteWarnPeriod and not self.forfeitWarningEnabled then

            self.forfeitWarningEnabled = true
            self.forfeitType = self.kForfeitTypes.RoundTimeLimit
            self.timeForfeitWarningStart = time
            self.forfeitTimer = kAbsoluteRoundTimeWarningStartTime
            self:AddTimedCallback( self.UpdateForfeitTimer, gTimerTickRate )

        end

        if isInAbsoluteWarnPeriod and self.forfeitWarningEnabled and self.timeForfeitWarningStart + kAbsoluteRoundTimeWarningStartTime < time then

            self.forfeitingTeam = kNeutralTeamType  --Draw Game

            self.timeForfeitStart = time
            self.isForcedConcedePending = true
            Log("\n\t !!!  self.isForcedConcedePending = TRUE   \n")

            self.forfeitWarningEnabled = false
            self.timeForfeitWarningStart = 0

        end

    end

    --evaluate team members currently on the server to determine which team (if any)
    --should automatically forfeit the match
    function ThunderdomeRules:CheckTeamSizeForfeit(gameRules, forfeitOnImbalance)

        local team1Ids = self.initialTeams[kTeam1Index]
        local team2Ids = self.initialTeams[kTeam2Index]
        local team1Size, team2Size = self:GetInitialTeamSizes()

        if self.round == 2 or self:GetMatchState() == self.kMatchStates.Intermission then
            team1Ids, team2Ids = self:GetSwappedTeams()
        end

        --Players, Rookies, Bots
        local t1P, _, t1B = gameRules:GetTeam1():GetNumPlayers()
        local t2P, _, t2B = gameRules:GetTeam2():GetNumPlayers()

        local team1Players = t1P - t1B
        local team2Players = t2P - t2B

        local worldPlayers = gameRules:GetWorldTeam():GetPlayers()
        if self:GetMatchState() == self.kMatchStates.Intermission then
            --parse RR player-pool, and compare against team-assignments, per next round number. For intermission phase only

            for p = 1, #worldPlayers do
                local player = worldPlayers[p]
                local client = Server.GetOwner(player)

                if client then
                    local clientSteamId = client:GetUserId()
                    if table.icontains(team1Ids, clientSteamId) then
                        team1Players = team1Players + 1
                    elseif table.icontains(team2Ids, clientSteamId) then
                        team2Players = team2Players + 1
                    end
                end
            end

        end

        --if one team is completely empty, immediately end the match
        local hasTeamOfBots = team1Players == 0 or team2Players == 0

        --otherwise, end the match if two or more members of a team quit the server
        local team1Forfeit = team1Size - team1Players >= kTeamImbalanceThreshold
        local team2Forfeit = team2Size - team2Players >= kTeamImbalanceThreshold

        if hasTeamOfBots then
            return team1Players == 0 and kTeam1Index or kTeam2Index
        elseif forfeitOnImbalance and team1Forfeit then
            return kTeam1Index
        elseif forfeitOnImbalance and team2Forfeit then
            return kTeam2Index
        end

    end

    --Checks the match state and times associated if either team is now empty
    local kInactiveCheck_InvalidCallWarn = false
    function ThunderdomeRules:CheckInactiveRoundConcede(gameRules, numConnecting)
        
        if gameRules:GetGameStarted() then
        --yes, this is trapped for where it's called, this is a safety check
            if not kInactiveCheck_InvalidCallWarn then
                Log("ERROR: ThunderdomeRules:CheckInactiveRoundConcede() called while game is started!")
                kInactiveCheck_InvalidCallWarn = true
            end
            return
        end

        if self.forfeitType ~= self.kForfeitTypes.None and self.forfeitType ~= self.kForfeitTypes.InactiveRound then
            return
        end

        local time = Shared.GetTime()

        -- Forfeit will only be considered once timers have stopped and players are assigned to teams.
        local isValidTestPhase =
            self.timerType == self.kTimerTypes.None and
            self.lastClientConnectTime > 0 and
            kMaxWaitForPlayersOnTeams + self.lastClientConnectTime < time

        -- Only forfeit during intermission phase if one team is completely empty
        -- (grace period for players to timeout / go AFK / reconnect etc.)
        local forfeitTeam = self:CheckTeamSizeForfeit(gameRules, false)

        local isForfeitCondition = isValidTestPhase and numConnecting == 0 and forfeitTeam ~= nil

        if isForfeitCondition and not self.forfeitWarningEnabled then
        --trigger UI warning message immediately
            
            self.forfeitWarningEnabled = true
            self.forfeitType = self.kForfeitTypes.InactiveRound
            self.timeForfeitWarningStart = time
            self.forfeitTimer = kForfeitWarningActivateDelay
            self:AddTimedCallback( self.UpdateForfeitTimer, gTimerTickRate )
        
        elseif not isForfeitCondition and self.forfeitWarningEnabled then

            self:ResetForcedRoundLimitEnd()

        end

        if isForfeitCondition and self.forfeitWarningEnabled and self.timeForfeitWarningStart + kForfeitWarningActivateDelay < time then
        
            self.forfeitingTeam = forfeitTeam

            if self.state == self.kMatchStates.Intermission then
            --force assign teams now to get this going, we don't care about per-round team assignments
                self:AssignPlayersToTeam(kTeam1Index)
                self:AssignPlayersToTeam(kTeam2Index)
                self:ResetTimer()
            end

            gameRules:ResetGame()
            gameRules.lastCountdownPlayed = 0
            gameRules:SetGameState(kGameState.Started)
            gameRules.playerRanking:StartGame()    --hack

            self.timeForfeitStart = time
            self.isForcedConcedePending = true
            Log("\n\t !!!  self.isForcedConcedePending = TRUE   \n")

            self.forfeitWarningEnabled = false
            self.timeForfeitWarningStart = 0

        end

    end

    --Only applicable when a round is in progress, checks for teams compositions against assigned teams, forfeit on all bots or threshold
    local kActiveCheck_InvalidCallWarn = false
    function ThunderdomeRules:CheckActiveRoundConcede(gameRules, numConnecting)
        
        if not gameRules:GetGameStarted() then
        --yes, this is trapped for where it's called, this is a safety check
            if not kActiveCheck_InvalidCallWarn then
                Log("ERROR: ThunderdomeRules:CheckActiveRoundConcede() called while game is not started!")
                kActiveCheck_InvalidCallWarn = true
            end
            return
        end

        if self.forfeitType ~= self.kForfeitTypes.None and self.forfeitType ~= self.kForfeitTypes.ActiveRound then
            return
        end

        local time = Shared.GetTime()

        local gameStartTime = gameRules:GetGameStartTime()
        if time - gameStartTime < kForfeitRoundCheckingDelay then
        --Not enough round-time has passed to consider checking Forfeit conditions
            return
        end

        -- Don't run a forfeit check if a client has connected recently; assume they'll be shuffled on a team
        local isValidTestPhase = self.lastClientConnectTime + kMaxAwaitingAssignForfeitDelay < Shared.GetTime()
            -- Don't run a forfeit check if voting to draw the match
            and self.timerType ~= self.kTimerTypes.VoteDrawMatch

        -- Forfeit during "live play" if either team dips below 70% of their initial team size
        -- (e.g. 2 of 6 players leave or crash during the match)
        local forfeitTeam = self:CheckTeamSizeForfeit(gameRules, true)

        local isForfeitCondition = numConnecting == 0 and forfeitTeam ~= nil and isValidTestPhase

        if isForfeitCondition and not self.forfeitWarningEnabled then
        --trigger UI warning message immediately

            self.forfeitWarningEnabled = true
            self.forfeitType = self.kForfeitTypes.ActiveRound
            self.timeForfeitWarningStart = time
            self.forfeitTimer = kForfeitWarningActivateDelay
            self:AddTimedCallback( self.UpdateForfeitTimer, gTimerTickRate )

        end

        if not isForfeitCondition and self.forfeitWarningEnabled and self.forfeitType == self.kForfeitTypes.ActiveRound then
        --Reset forfeit warning if the condition is no longer met

            self:ResetForcedRoundLimitEnd()

        end

        if isForfeitCondition and self.forfeitWarningEnabled and self.timeForfeitWarningStart + kForfeitWarningActivateDelay < time then
        --Round already setup in this context, no need for anything else, time to wrap up

            self.forfeitingTeam = forfeitTeam

            self.timeForfeitStart = time
            self.isForcedConcedePending = true
            Log("\n\t !!!  self.isForcedConcedePending = TRUE   \n")

            self.forfeitWarningEnabled = false
            self.timeForfeitWarningStart = 0

        end

    end

    function ThunderdomeRules:UpdateForfeitTimer()
        if self.forfeitWarningEnabled then
            Log("ThunderdomeRules:UpdateForfeitTimer() - %s", self.forfeitTimer)
            self.forfeitTimer = self.forfeitTimer - gTimerTickRate
            return true
        end
        return false
    end

    --Note: this should ONLY ever be called from bottom of NS2GameRules:OnUpdate() and no other time
    function ThunderdomeRules:CheckForAutoConcede(gameRules)

        local time = Shared.GetTime()
        if kForfeitMinServerTimeBeforeChecking > time then
        --don't even bother checking if the server has only been up a few seconds, etc.
        --this has nothing to do with game started times, rather its server uptime.
            return
        end

        if self.isForcdedConcedeCleanupPending then
        --already processed, match will be ended, bail out
            return
        end

        local numConnecting = gameRules:GetNumPlayersConnecting()

        if self.forfeitWarningEnabled then
            if numConnecting > 0 and self.forfeitType ~= self.kForfeitTypes.RoundTimeLimit then
            --connecting clients changes from time forfeit notice start to now, halt and wait
                Log("\n***** RESET FORFEIT DUR TO NEW CONNECTIONS  *****\n")
                self:ResetForcedRoundLimitEnd()
                return
            end
        end

        --TD-TODO refine this and catch edgy-edge cases of slow client connecting as __last__ possible moment...need to "show" that occurred to not be confusing
        if self.isForcedConcedePending then
        --Already performed check and setup round to auto-end

            local forfeitExecuteDelayTime = kForfeitExecutionGameDelay
            if self.forfeitType == self.kForfeitTypes.InactiveRound then
                forfeitExecuteDelayTime = kForfeitExecutionDelay
            end
            
            local forfeitExecuteDelayDone = self.timeForfeitStart + forfeitExecuteDelayTime < time

            if forfeitExecuteDelayDone then
                self:TriggerMatchForfeit(gameRules, self.forfeitingTeam)
            end

            return

        end

        if gameRules:GetGameStarted() then
            self:CheckActiveRoundConcede(gameRules, numConnecting)

            if self.forfeitType ~= self.kForfeitTypes.None or self.forfeitType ~= self.kForfeitTypes.RoundTimeLimit then
                self:CheckAbsoluteRoundTimeDraw( gameRules, numConnecting )
            end
        else
            self:CheckInactiveRoundConcede(gameRules, numConnecting)
        end

    end

    local unprocessedErrors = {}

    if Shared.GetThunderdomeEnabled() then
        Event.Hook("ErrorCallback", function(error, log)
            local index = #unprocessedErrors
            unprocessedErrors[index + 1] = error or ""
            unprocessedErrors[index + 2] = log or ""
        end)
    end

    --trap repeating errors, only send once
    local lastError
    local seenErrors = {}

    local function HandleError(error, log)
        local newError = not seenErrors[error]
        local repeatingError = error == lastError
        lastError = error
        seenErrors[error] = (seenErrors[error] or 0) + 1

        if not repeatingError and newError then
            --Note: no response handler, as this should be fire-n-forget
            Shared.SendHTTPRequest(
                kTDErrorReportUrl,
                "POST",
                {
                    error = error,
                    log_msg = log,
                    version = 0,
                    branch = "",
                    build = Shared.GetBuildNumber(),
                    source = "server"
                }
            )
            Print("Error '%s' sent", error)
        end
    end

    if Shared.GetThunderdomeEnabled() then
        Event.Hook("UpdateServer", function()
            if #unprocessedErrors ~= 0 then
                Print("Sending %d error reports", #unprocessedErrors/2)
            end

            for i=1,#unprocessedErrors,2 do
                local success, msg = pcall(HandleError, unprocessedErrors[i], unprocessedErrors[i+1])

                if not success then
                    Print("Error handler failed with error %s", msg)
                end
            end
            table.clear(unprocessedErrors)
        end)
    end
end     --End-Server


if Client then

    function ThunderdomeRules:UpdateClientTimerUI()

        local timerGui = ClientUI.GetScript( self.kClientTimerGUIScriptName )

        if timerGui then

            local time = Shared.GetTime()

            local gameStartTime = PlayerUI_GetGameStartTime()
            local absoluteEndWarnTime = kThunderdomeRoundMaxTimeLimit - kAbsoluteRoundTimeWarningStartTime
            local isInAbsoluteWarnPeriod = (time - gameStartTime) - absoluteEndWarnTime >= 0

            if isInAbsoluteWarnPeriod  then
            --Update GUI five minutes before absolute end, so text is shown accurately
                timerGui:UpdateMessageForMaxRoundTime()
            end

            timerGui:ShowForcedConcedeMessage( self.isForcedConcedePending and self.forfeitType ~= self.kForfeitTypes.RoundTimeLimit, self.forfeitingTeam )

            if self.forfeitWarningEnabled and not timerGui:GetShowingForfeitWarning() then
                timerGui:UpdateForfeitWarningTextColors()
            end

            if self.forfeitWarningEnabled then
                if self.forfeitType == self.kForfeitTypes.RoundTimeLimit then
                    timerGui:UpdateForfeitAbsoluteTimerText(self.forfeitTimer)
                else
                    timerGui:UpdateForfeitTimerText(self.forfeitTimer)
                end
            end

            timerGui:ShowForfeitWarning(self.forfeitWarningEnabled)

            if self.timerType == self.kTimerTypes.None then
            --Just to ensure GUI in valid init-state on client-connect
                local label = self:GetMatchStateLabel()
                timerGui:SetStateLabel( label )
            end

            local timerStartDelay = self:GetTimerTypeStartDelay( self.timerType ) or 0
            --hack, 0.275 is a lame attempt to deal with latency. This "should" read client latency and adjust
            local preTimerDelayTime = self.timerStart + (timerStartDelay - 0.275)
            local isVisible = not (preTimerDelayTime > time)

            if self.state == self.kMatchStates.RematchVote then
                isVisible = false   --override in steps which _showing_ the timer isn't applicable
            end

            local label = self:GetMatchStateLabel()
            timerGui:SetStateLabel( label )
            if self.forfeitType == self.kForfeitTypes.None then
                timerGui:SetTimerRemaining( self.activeTimer )  --tweak to handle minutes vs sec?
            else
            --set to zero so hides timer, when not applicable (e.g. forfeit during X phase countdown)
                timerGui:SetTimerRemaining( 0 )
            end

            timerGui:SetVisible(isVisible or (self.isForcedConcedePending or self.forfeitWarningEnabled))
            
        end

    end

    function ThunderdomeRules:GetMatchStateLabel()
        local label = ""

        if self.state == self.kMatchStates.AwaitingPlayers then
            label = Locale.ResolveString("THUNDERDOME_RULES_TIMER_WAITCONNECT_PLAYERS")
        elseif self.state == self.kMatchStates.PreMatch then
            label = Locale.ResolveString("THUNDERDOME_RULES_TIMER_ASSIGN_PLAYERS")
        elseif self.state == self.kMatchStates.RoundOne then
            -- TODO: localize
            if self.timerType == self.kTimerTypes.VoteDrawMatch then
                label = "Vote to Draw Match starts in:" --Locale.ResolveString("THUNDERDOME_RULES_TIMER_DRAW_MATCH")
            end
        elseif self.state == self.kMatchStates.Intermission then
            label = Locale.ResolveString("THUNDERDOME_RULES_TIMER_NEXTROUND_DELAY")
        elseif self.state == self.kMatchStates.RoundTwo then
            -- TODO: localize
            if self.timerType == self.kTimerTypes.VoteDrawMatch then
                label = "Vote to Draw Match starts in:" --Locale.ResolveString("THUNDERDOME_RULES_TIMER_DRAW_MATCH")
            end
        elseif self.state == self.kMatchStates.RematchVote then
            label = Locale.ResolveString("THUNDERDOME_RULES_TIMER_REMATCHVOTE")
        elseif self.state == self.kMatchStates.Shutdown then
            label = Locale.ResolveString("THUNDERDOME_RULES_TIMER_SERVER_SHUTDOWN")
        end

        return label
    end
    
    function ThunderdomeRules:GetIsMatchForceConceded()
        return self.isForcedConcedePending or self.isForcdedConcedeCleanupPending
    end
    
    function ThunderdomeRules:GetIsMatchCompleted()
        SLog("ThunderdomeRules:GetIsMatchCompleted()")
        SLog("")
        SLog("  ThunderdomeRules:")
        SLog("\t        clientRound:        %s", self.clientRound)
        SLog("\t        clientMatchState:   %s", self.clientMatchState)
        SLog("\t        matchCompleted:     %s", self.matchCompleted)
        
        local gameInfo = GetGameInfoEntity()
        SLog("  GameInfoEntity:")
        SLog("\t        state:              %s", gameInfo:GetState())
        SLog("\t        roundCompleted:     %s", gameInfo:GetRoundCompleted())
        
        --Note: ignores game-state, as this could be called when local-client is moved back to RR
        return self.matchCompleted
    end

    --TODO Use lobby data and "predicted" team-swap to display Which team player is about to player (in all pre-round steps)
    ---- Could read roles thing too and display those as well
    ---- Bold/Icon if player is Commander?

end     --End-Client



--Shared Scope for Client & Server, should be ignored by Predict
function ThunderdomeRules:OnUpdate(delta)

    if Server then
        if not self.initializedTeamAssignments then
            self:SetupInitialTeamAssignments()
        end

        if Server.GetNumPlayers() == 0 then
            return
        end

        --Tick any active Timer and run its actions
        self:UpdateState()

        --Disconnect any clients who may have reconnected during post-match
        if self.state == self.kMatchStates.Shutdown and self.hasShutdown then
            self:DisconnectClientsPostMatch()
        else
        --Force refresh of all connected clients team-assignments (e.g. handle late-joiners)
            self:UpdateConnectedClients()
        end

        if self.pendinClientStatsNotify and ( self.lastStatsUpdateTime + self.kStatsNotifyDelay < Shared.GetTime() ) then
        --Broadcast and notify all clients they should check their inventories for new items
            Log("*** Notifying Clients if Steam STATS changes ***")
            Server.SendNetworkMessage("Thunderdome_EndRoundItemsCheck", {}, true)
            self.pendinClientStatsNotify = false
        end
        
    end

    if Client then
        self:UpdateClientTimerUI( delta )
        self.clientMatchState = self.state
        self.clientRound = self.round
    end

end


-------------------------------------------------------------------------------


local gThunderdomeRules = nil
function GetThunderdomeRules()
    if not gThunderdomeRules then
        assert(gThunderdomeRulesEntId ~= Entity.invalidId)
        gThunderdomeRules = Shared.GetEntity(gThunderdomeRulesEntId)
    end
    return gThunderdomeRules
end

function ThunderdomeRules:DebugDump()
    local tr = self

    Log("=================================================")
    Log("   Thunderdome Rules - State Dump")
    Log("")
    Log("ThunderdomeRules:")
    Log("")
    Log("        isForcedConcedePending:      %s", tr.isForcedConcedePending)
    Log("isForcdedConcedeCleanupPending:      %s", tr.isForcdedConcedeCleanupPending)
    Log("         forfeitWarningEnabled:      %s", tr.forfeitWarningEnabled)
    Log("                   forfeitType:      %s", ThunderdomeRules.kForfeitTypes[tr.forfeitType])
    Log("              timeForfeitStart:      %s", tr.timeForfeitStart)
    Log("       timeForfeitWarningStart:      %s", tr.timeForfeitWarningStart)
    Log("                forfeitingTeam:      %s", tr.forfeitingTeam)
    Log("")
    Log("             round:      %s", tr.round)
    Log("             state:      %s", ThunderdomeRules.kMatchStates[tr.state])
    Log("         timerType:      %s", ThunderdomeRules.kTimerTypes[tr.timerType])
    Log("        timerStart:      %s", tr.timerStart)
    Log("       activeTimer:      %s", tr.activeTimer)
    Log("     matchCompleted:     %s", tr.matchCompleted)
    Log("")
    Log("-------------------------------------------------")
    Log("")
end

Event.Hook("Console_td_dumprules", function()
        
    local tr = GetThunderdomeRules()
    local gr = GetGamerules()

    tr:DebugDump()

    if Server then
    Log("NS2Gamerules:")
    Log("\t     GameState:  %s", kGameState[gr.gameState])
    Log("\t GameStartTime:  %s", gr:GetGameStartTime())
    Log("")
    Log("-------------------------------------------------")
    Log("")
    end

end)


Shared.LinkClassToMap("ThunderdomeRules", ThunderdomeRules.kMapName, ThunderdomeRules.networkVars)
