-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
--    lua\PlayerRanking.lua
--    
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--    Modified by:  Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


--don't track games which are shorter than a minute
local kMinMatchTime = 60    --TODO Move to global (or Engine def)

gRankingDisabled = false
gDumpRoundStats = false

--TODO Move into PlayerRanking class
local avgNumPlayersSum = 0
local numPlayerCountSamples = 0

kXPBonusPerWin = 250
kXPBonusPerGame = 500
kXPGainPerSecond = 2000 / ( 14 * 60 )
kMaxLevel = 100
kMaxPrestige = 5


function GetGeoCoordsURL()
    return "https://uwe-thunderdome.azurewebsites.net/api/getgeo"
end

--client side utility functions
function PlayerRanking_GetXPNeededForLevel( level )
    local base = ( (level - 1 ) % kMaxLevel ) + 1
    local prestige = math.max( 0, math.floor(( level - 1 ) / kMaxLevel ) )

    if base == 1 and 0 < prestige then
        return 16500 -- Wrapping from 100 to 1 should be harder than 0 to 1
    end

    return math.min( 16500,                                 -- Maximum 16500 between levels
            math.min( base, 7 ) * 1250                      -- 1250 extra per level up to level 8
                    + Clamp( base - 7, 0, 14 - 7 ) * 750    -- 750 extra per level up to level 15
                    + math.max( 0, base - 14 ) * 500        -- 500 extra per level after
    )
end

function PlayerRanking_GetTotalXpNeededForLevel( level )

    local s1 = Clamp( level, 0, 7 )
    local s2 = Clamp( level - 7, 0, 14 - 7 )
    local s3 = Clamp( level - 14, 0, 19 - 14 )
    local s4 = math.max( 0, level - 19 )

    local needed = 0
            + ( s1 / 2.0 ) * ( PlayerRanking_GetXPNeededForLevel(1) + PlayerRanking_GetXPNeededForLevel( s1 ) ) -- 1250 series from 2 to 7
            + ( s2 / 2.0 ) * ( PlayerRanking_GetXPNeededForLevel(8) + PlayerRanking_GetXPNeededForLevel( s2 + 7 ) )   -- 750 series from 8 to 14
            + ( s3 / 2.0 ) * ( PlayerRanking_GetXPNeededForLevel(15) + PlayerRanking_GetXPNeededForLevel( s3 + 14 ) )    -- 500 series from 15 to 19
            + ( s4 * 16500 )    -- constant from 20 up

    return needed
end

function PlayerRankingUI_GetRelativeSkillFraction()

    local relativeSkillFraction = 0

    local gameInfo = GetGameInfoEntity()
    local player = Client.GetLocalPlayer()

    if gameInfo and player and HasMixin(player, "Scoring") then

        local averageSkill = gameInfo:GetAveragePlayerSkill()
        if averageSkill > 0 then

            local pT = HasMixin(player, "Team") and player:GetTeamNumber() or 0
            assert(pT == kTeam1Index or pT == kTeam2Index)

            local pS = player:GetPlayerSkill()
            local psO = player:GetPlayerSkillOffset()
            local ptSkill = ( pT == kTeam1Index ) and pS + psO or pS - psO

            relativeSkillFraction = Clamp( ptSkill / averageSkill, 0, 1)

        else
            relativeSkillFraction = 1
        end

    end

    return relativeSkillFraction

end

function PlayerRankingUI_GetLevelFraction()

    local levelFraction = 0

    local player = Client.GetLocalPlayer()
    if player and HasMixin(player, "Scoring") then
        levelFraction = Clamp(player:GetPlayerLevel() / kMaxPlayerLevel, 0, 1)
    end

    return levelFraction

end




class 'PlayerRanking'

function PlayerRanking:StartGame()

    self.gameStartTime = Shared.GetTime()

    self.gameStarted = true
    self.capturedPlayerData = {}

    avgNumPlayersSum = 0
    numPlayerCountSamples = 0

    self.roundTimeWeighted = 0

end

function PlayerRanking:GetTrackServer()
    return Server.GetIsRankingActive()
end

function PlayerRanking:GetRelativeRoundTime()
    return math.max(0, Shared.GetTime() - (self.gameStartTime or 0 )) --to prevent float underflow
end


local steamIdToClientIdMap = {}

function PlayerRanking:LogPlayer( player )

    if gRankingDisabled then
        return
    end

    if not self.capturedPlayerData then
        return
    end

    local client = player:GetClient()
    -- only consider players who are connected to the server and ignore any uncontrolled players / ragdolls
    if client then  --Includes Bots

        local steamId = client:GetUserId()

        if steamId > 0 then
            steamIdToClientIdMap[steamId] = client:GetId()
        end

        local playerData =
        {
            steamId = steamId,  --Note: Bots are determined by this value being 0
            marineTime = player:GetMarinePlayTime(),
            alienTime = player:GetAlienPlayTime(),
            marineCommTime = player:GetMarineCommanderTime(),
            alienCommTime = player:GetAlienCommanderTime(),
            teamNumber = player:GetTeamNumber(),
            score = player:GetScore(),
            weightedTimeTeam1 = player:GetWeightedPlayTime( kTeam1Index ),
            weightedTimeTeam2 = player:GetWeightedPlayTime( kTeam2Index ),
            weightedTimeCommTeam1 = player:GetWeightedCommanderPlayTime( kTeam1Index ),
            weightedTimeCommTeam2 = player:GetWeightedCommanderPlayTime( kTeam2Index ),
        }

        table.insert( self.capturedPlayerData, playerData )

    end

end


function PlayerRanking:SetEntranceTime( player, teamNumber )

    player:SetEntranceTime( teamNumber, self:GetRelativeRoundTime() )

    if Server then
        StatsUI_AddHiveSkillEntry(player, teamNumber, true)
    end
end

function PlayerRanking:SetExitTime( player, teamNumber )

    player:SetExitTime( teamNumber, self:GetRelativeRoundTime() )

    if Server then
        StatsUI_AddHiveSkillEntry(player, teamNumber, false)
    end
end

function PlayerRanking:SetCommanderEntranceTime( comm, teamNumber )
    local gameRules = GetGamerules()
    local gameState = gameRules:GetGameState()
    local validEntryState = ( gameState == kGameState.Started or gameState == kGameState.Countdown or gameState == kGameState.NotStarted)
    
    if validEntryState then
        comm:SetCommanderEntranceTime( teamNumber, self:GetRelativeRoundTime() )
    end
end

--FIXME This will fail if a Comm goes to RR during countdown
function PlayerRanking:SetCommanderExitTime( comm, teamNumber )
    local gameRules = GetGamerules()
    local gameState = gameRules:GetGameState()
    local validExitState = 
        gameState == kGameState.Started or
        gameState == kGameState.Team1Won or 
        gameState == kGameState.Team2Won or 
        gameState == kGameState.Draw

    if validExitState then
        comm:SetCommanderExitTime( teamNumber, self:GetRelativeRoundTime() )
    end
end

PlayerRanking.EndGameStatsResults = function()

    local self = GetGamerules().playerRanking

    local statsData = {}
    if not Server.GetLastProcessedRoundStats(statsData) then
        Log("Failed to retrieve processed round-stats data. No data processed, or failure occurred")
        return
    end

    assert(#statsData.players > 0, "No players found in round-data")

    for i = 1, #statsData.players do

        local steamId3 = Shared.ConvertSteamId64To32( statsData.players[i].steamId64 )

        local clientId = steamIdToClientIdMap[steamId3]
        if not clientId then
            Log("Error: No ClientID for SteamID3[ %s ] in clients-map", steamId3)
            goto CONT
        end

        local client = clientId and Server.GetClientById(clientId)

        if not client then
            Log("Warning: No active Client found for ID[%s]", clientId)
            goto CONT
        end
            
        local player = client:GetControllingPlayer()

        if player then

            Log("   Player[%s]:  %s", steamId3, statsData.players[i])

            player:SetTotalXP( statsData.players[i].xp )
            player:SetTotalScore( statsData.players[i].score )
            player:SetPlayerLevel( statsData.players[i].level )

            if Shared.GetThunderdomeEnabled() then

                player:SetTDPlayerSkill( statsData.players[i].td_skill )
                player:SetTDPlayerSkillOffset( statsData.players[i].td_skillOffset )
                player:SetTDCommanderSkill( statsData.players[i].td_commSkill )
                player:SetTDCommanderSkillOffset( statsData.players[i].td_commSkillOffset )
                player:SetTDAdagradSum( statsData.players[i].td_adagrad )
                player:SetTDCommanderAdagradSum( statsData.players[i].td_commAdagrad )

            else

                player:SetPlayerSkill( statsData.players[i].skill )
                player:SetPlayerSkillOffset( statsData.players[i].skillOffset )
                player:SetCommanderSkill( statsData.players[i].commSkill )
                player:SetCommanderSkillOffset( statsData.players[i].commSkillOffset )
                player:SetAdagradSum( statsData.players[i].adagrad )
                player:SetCommanderAdagradSum( statsData.players[i].commAdagrad )

            end

        end

        ::CONT::

    end

    Server.SendNetworkMessage("RoundStatsProcessingCompleted", {}, true)

end
Event.Hook("ProcessRoundStatsCompleted", PlayerRanking.EndGameStatsResults)

function PlayerRanking:EndGame(winningTeam)
    PROFILE("PlayerRanking:EndGame")
    
    if gRankingDisabled then
        return
    end

    local roundLength = math.max(0, Shared.GetTime() - self.gameStartTime)

    local tdForcedEnd = winningTeam == nil
    if Shared.GetThunderdomeEnabled() then
    --simple flag to force stats to be processed, but round not submitted
        local tdRules = GetThunderdomeRules()

        tdForcedEnd = tdRules:GetHasForcedMatchConcede() or winningTeam == nil

        if tdRules:GetIsPrivateMatch() then
        --We never update skills for Private matches (or rewards), so bail-out now
            return
        end
    end

    Log("PlayerRanking: Beginning player skill updates (started: %s, ranked: %s, roundLength: %s, forcedEnd: %s)",
        self.gameStarted, self:GetTrackServer(), roundLength, tdForcedEnd)

    if self.gameStarted and ( self:GetTrackServer() or gDumpRoundStats ) and ( roundLength >= kMinMatchTime or tdForcedEnd ) then

        local gameEndTime = self:GetRelativeRoundTime()
        local aT = math.pow( 2, 1 / 40 )
        local sT = 1 -- start time is always 0 = math.pow( aT, self.gameStartTime * -1 )
        local eT = math.pow( aT, gameEndTime * -1 )
        self.roundTimeWeighted = sT - eT
        
        local LogPlayer = Closure [=[
            self this gameEndTime
            args player
            player:SetExitTime( player:GetTeamNumber(), gameEndTime )
            this:LogPlayer( player )
        ]=]{self, gameEndTime}

        GetGamerules():GetTeam1():ForEachPlayer(LogPlayer)
        GetGamerules():GetTeam2():ForEachPlayer(LogPlayer)
        GetGamerules():GetWorldTeam():ForEachPlayer(LogPlayer)
        GetGamerules():GetSpectatorTeam():ForEachPlayer(LogPlayer)

        local gameInfo =
        {
            gameMode = GetGamemode(),
            gameTime = roundLength,
            winner = winningTeam and winningTeam:GetTeamNumber() or 0,
            numBots = GetGameInfoEntity():GetNumBots(),
            players = {}
        }

        for _, playerData in ipairs(self.capturedPlayerData) do
            self:InsertPlayerData(gameInfo.players, playerData, winningTeam, roundLength, marineSkill, alienSkill, self.roundTimeWeighted)
        end

        if gDumpRoundStats then
            Log("RoundEnd Data-----------------------------")
            Log("%s", gameInfo)

        else
            
            if Shared.GetThunderdomeEnabled() then 
            --Handle updating progression stats, per client
                GetThunderdomeRules():RecordRoundSteamStats( gameInfo, steamIdToClientIdMap )
                --Note: this call is also responsible for comitting unlock stats data to Client's profiles
            end
            
            --Begin round data processing steps. Completion of this will be triggered via 'ProcessRoundStatsCompleted' Event    
            if not tdForcedEnd and not Server.ProcessRoundStats(gameInfo) then
                Log("Error: Failed to complete round stats processing, player skills not updated")
            end

        end

    end

    self.roundTimeWeighted = 0
    self.gameStarted = false

end


function PlayerRanking:InsertPlayerData(playerTable, recordedData, winningTeam, gameTime, marineSkill, alienSkill, roundTimeWeighted)

    PROFILE("PlayerRanking:InsertPlayerData")

    -- Can't calculate isCommander or weightedTimeTeam values until the game is over, which is why this part is deferred
    local playerData =
    {
        steamId = recordedData.steamId, --Note: will be 0 for Bots

    --Note: playtime values are not used for anything, just extraneous data...
        playTime = recordedData.playTime,
        marineTime = recordedData.marineTime,
        alienTime = recordedData.alienTime,
        marineCommTime = recordedData.marineCommTime,
        alienCommTime = recordedData.alienCommTime,
        teamNumber = recordedData.teamNumber,
        score = recordedData.score or 0,
        weightedTimeTeam1 = recordedData.weightedTimeTeam1 / roundTimeWeighted,
        weightedTimeTeam2 = recordedData.weightedTimeTeam2 / roundTimeWeighted,

        weightedTimeCommTeam1 = recordedData.weightedTimeCommTeam1 / roundTimeWeighted,
        weightedTimeCommTeam2 = recordedData.weightedTimeCommTeam2 / roundTimeWeighted,
    }

    -- Filter out players who did not play on a team
    if playerData.marineTime > 0 or playerData.alienTime > 0 then

        table.insert(playerTable, playerData)

    end

end

function PlayerRanking:UpdatePlayerSkills()     --FIXME Having team of pure bots results in NaNs

    PROFILE("PlayerRanking:UpdatePlayerSkill")

    -- update this only max once per frame
    if not self.timeLastSkillUpdate or self.timeLastSkillUpdate < Shared.GetTime() then

        self.playerSkills = 
        {
            [kNeutralTeamType] = {},
            [kMarineTeamType] = {},
            [kAlienTeamType] = {},
            [kRandomTeamType] = {},
        }

        for _, player in ipairs(GetEntitiesWithMixin("Scoring")) do

            local client = Server.GetOwner(player)

            if client and not client:GetIsVirtual() then

                local skill = player:GetPlayerSkill() and math.max(player:GetPlayerSkill(), 0)
                local skillOffset = player:GetPlayerSkillOffset()
                
                local teamSkill = skill
                local pTeam = HasMixin(player, "Team") and player:GetTeamNumber() or 0

                --Note: primary 'skill' property is set as "default" skill value
                if pTeam == kTeam1Index or pTeam == kTeam2Index then
                    teamSkill = ( pTeam == kTeam1Index ) and ( skill + skillOffset ) or ( skill - skillOffset )
                end

                if teamSkill then
                    table.insert(self.playerSkills[pTeam], teamSkill)
                    table.insert(self.playerSkills[kRandomTeamType], teamSkill)
                end

            end

        end

        self.timeLastSkillUpdate = Shared.GetTime()

    end

end

function PlayerRanking:GetPlayerSkills()
    if not self.playerSkills then 
        self:UpdatePlayerSkills() 
    end
    return self.playerSkills
end

function PlayerRanking:GetAveragePlayerSkill(teamtype)
    teamtype = teamtype or 3

    self:UpdatePlayerSkills()

    return table.mean(self.playerSkills[teamtype])
end

if Server then

    local function FetchClientStatsComplete(client)
        PROFILE("PlayerRanking:FetchClientStatsComplete")
        Log("PlayerRanking:FetchClientStatsComplete")

        local player = client and client:GetControllingPlayer() or nil
        local steamId = client and client:GetUserId() or nil

        if player and steamId then
            
            local skillData = 
            {
                skill = Server.GetUserStat_Int(client, Server.kSkillFields_Skill) or 0,
                skill_offset = Server.GetUserStat_Int(client, Server.kSkillFields_SkillOffset) or 0,
                comm_skill = Server.GetUserStat_Int(client, Server.kSkillFields_CommSkill) or 0,
                comm_skill_offset = Server.GetUserStat_Int(client, Server.kSkillFields_CommSkillOffset) or 0,
                adagrad = Server.GetUserStat_Float(client, Server.kSkillFields_Adagrad) or 0,
                comm_adagrad = Server.GetUserStat_Float(client, Server.kSkillFields_CommAdagrad) or 0,
                skill_sign = Server.GetUserStat_Int(client, Server.kSkillFields_SkillSign) or 0,
                comm_skill_sign = Server.GetUserStat_Int(client, Server.kSkillFields_CommSkillSign) or 0,

                td_skill = Server.GetUserStat_Int(client, Server.kSkillFields_TD_Skill) or 0,
                td_skill_offset = Server.GetUserStat_Int(client, Server.kSkillFields_TD_SkillOffset) or 0,
                td_comm_skill = Server.GetUserStat_Int(client, Server.kSkillFields_TD_CommSkill) or 0,
                td_comm_skill_offset = Server.GetUserStat_Int(client, Server.kSkillFields_TD_CommSkillOffset) or 0,
                td_adagrad = Server.GetUserStat_Float(client, Server.kSkillFields_TD_Adagrad) or 0,
                td_comm_adagrad = Server.GetUserStat_Float(client, Server.kSkillFields_TD_CommAdagrad) or 0,
                td_skill_sign = Server.GetUserStat_Int(client, Server.kSkillFields_TD_SkillSign) or 0,
                td_comm_skill_sign = Server.GetUserStat_Int(client, Server.kSkillFields_TD_CommSkillSign) or 0,

                score = Server.GetUserStat_Int(client, Server.kSkillFields_Score) or 0,
                level = Server.GetUserStat_Int(client, Server.kSkillFields_Level) or 0,
                xp = Server.GetUserStat_Int(client, Server.kSkillFields_Xp) or 0,
            }
            
            if Shared.GetThunderdomeEnabled() then

                local firstTimeUser = 
                    skillData.td_skill == 0 and
                    skillData.td_comm_skill == 0 and
                    skillData.td_skill_offset == 0 and
                    skillData.td_comm_skill_offset == 0

                if firstTimeUser then
                --All zeros in init'd state, copy over and proceed

                    skillData.td_skill = skillData.skill
                    skillData.td_comm_skill = skillData.comm_skill
                    skillData.td_skill_offset = skillData.skill_offset
                    skillData.td_comm_skill_offset = skillData.comm_skill_offset
                    skillData.td_adagrad = skillData.adagrad
                    skillData.td_comm_adagrad = skillData.comm_adagrad
                    skillData.td_skill_sign = skillData.skill_sign
                    skillData.td_comm_skill_sign = skillData.comm_skill_sign

                end

            end
            
            Log("Fetched connected player[%s] stats:", steamId)
            Log("%s", skillData)
            
            player:SetPlayerSkill( skillData.skill )
            --Note: this god awful hack is because of how Steam "supposidly" handles _signed_ INTs
            player:SetPlayerSkillOffset( skillData.skill_sign < 1 and skillData.skill_offset * -1 or skillData.skill_offset )
            player:SetCommanderSkill( skillData.comm_skill )
            player:SetCommanderSkillOffset( skillData.comm_skill_sign < 1 and skillData.comm_skill_offset * -1 or skillData.comm_skill_offset )
            player:SetAdagradSum( skillData.adagrad )
            player:SetCommanderAdagradSum( skillData.comm_adagrad )
            
            player:SetTDPlayerSkill( skillData.td_skill )
            player:SetTDPlayerSkillOffset( skillData.td_skill_sign < 1 and skillData.td_skill_offset * -1 or skillData.td_skill_offset )
            player:SetTDCommanderSkill( skillData.td_comm_skill )
            player:SetTDCommanderSkillOffset( skillData.td_comm_skill_sign < 1 and skillData.td_comm_skill_offset * -1 or skillData.td_comm_skill_offset )
            player:SetTDAdagradSum( skillData.td_adagrad )
            player:SetTDCommanderAdagradSum( skillData.td_comm_adagrad )

            player:SetTotalScore(skillData.score)
            player:SetPlayerLevel(skillData.level)
            player:SetTotalXP(skillData.xp)

            if player:GetPlayerLevel() ~= -1 and player:GetPlayerLevel() < kRookieLevel then
                player:SetRookie(true)
            end
            
            Badges_FetchBadges(client:GetId(), nil)

        end

    end

    Event.Hook("ReceivedSteamStatsForClient", function(clientId64)
        Log("  --  ReceivedSteamStatsForClient  EVENT  --")
        local steam32Id = Shared.ConvertSteamId64To32(clientId64)
        Log("      SteamID64:  %s", clientId64)
        Log("      SteamID32:  %s", steam32Id)

        if steam32Id > 0 and steamIdToClientIdMap[steam32Id] then

            local client = Server.GetClientById(steamIdToClientIdMap[steam32Id])

            if client then
                FetchClientStatsComplete(client)
            else
                Log("ERROR: No matching SteamID in Client-Map!!")
            end

        end

    end)

    --Note: we do NOT flush stats data on client disconnect. Doing so just adds a bunch of extra state-crap that's not worth
    --dealing with due to timings and round processing.
    local function OnConnect(client)
        PROFILE("PlayerRanking:OnConnect")
        
        if client and not client:GetIsVirtual() then
            local steamId = client:GetUserId()

            if steamIdToClientIdMap[steamId] == nil then
                steamIdToClientIdMap[steamId] = client:GetId()
            end

            if not Server.RequestUserStats(client) then
                Log("ERROR: Failed to trigger stats-request for Client[%s]", steamId)
            end

        end

    end

    local function OnDisconnect(client)
        PROFILE("PlayerRanking:OnDisconnect")

        if client and not client:GetIsVirtual() then
            local steamId = client:GetUserId()
            steamIdToClientIdMap[steamId] = nil
        end
    end

    local gConfigChecked
    local function UpdatePlayerStats()

        PROFILE("PlayerRanking:UpdatePlayerStats")

        if not gConfigChecked and Server.GetConfigSetting then
            gRankingDisabled = gRankingDisabled
            gConfigChecked = true

            Log("Loaded player ranking config, ranking: %s", Server.GetIsRankingActive())
        end
        
        if ( Shared.GetCheatsEnabled() or Shared.GetTestsEnabled() ) and not gDumpRoundStats then
            gRankingDisabled = true
        end

        if gRankingDisabled then
            return
        end

        local gameRules = GetGamerules()

        if gameRules then
            local team1PlayerNum = gameRules:GetTeam1():GetNumPlayers()
            local team2PlayerNum = gameRules:GetTeam2():GetNumPlayers()

            avgNumPlayersSum = avgNumPlayersSum + team1PlayerNum + team2PlayerNum
            numPlayerCountSamples = numPlayerCountSamples + 1
        end

    end
    
    Event.Hook("ClientDisconnect", OnDisconnect)
    Event.Hook("ClientConnect", OnConnect)
    Event.Hook("UpdateServer", UpdatePlayerStats)

    --This is only applicable in server scope, but clients notified when toggled
    Event.Hook("Console_sv_dumproundstats", function()
        gDumpRoundStats = not gDumpRoundStats
        Server.SendNetworkMessage("DumpRoundStats", { dumpRoundStats = gDumpRoundStats }, true)
        Log("Dumping round stats %s", ( gDumpRoundStats and "ENABLED" or "DISABLED" ))
    end)

end