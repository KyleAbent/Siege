--[[
======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
    
 lua\ScoringMixin.lua    
   ScoringMixin keeps track of a score. It provides function to allow changing the score. 
    Created by:   Brian Cronin (brianc@unknownworlds.com)    
    
========= For more information, visit us at http://www.unknownworlds.com =====================    
--]]

local aT = math.pow( 2, 1 / 40 )


ScoringMixin = CreateMixin(ScoringMixin)
ScoringMixin.type = "Scoring"

local gSessionKills = {}

function GetSessionKills(clientIndex)
    return gSessionKills[clientIndex] or 0
end

ScoringMixin.networkVars =
{
    skill = "integer",
    skillOffset = "integer",
    commSkill = "integer",
    commSkillOffset = "integer",
    adagradSum = "float",
    commAdagradSum = "float",

    td_skill = "integer",
    td_skillOffset = "integer",
    td_commSkill = "integer",
    td_commSkillOffset = "integer",
    td_adagradSum = "float",
    td_commAdagradSum = "float",

    playTime = "private time",
    marineTime = "private time",
    alienTime = "private time",
    marineCommTime = "private time",
    alienCommTime = "private time",

    playerLevel = "integer",
    totalXP = "integer",
    teamAtEntrance = string.format("integer (-1 to %d)", kSpectatorIndex)
}

ScoringMixin.optionalConstants = {
    kMaxScore = "Max score"
}

function ScoringMixin:__initmixin()
    
    PROFILE("ScoringMixin:__initmixin")
    
    self.score = 0
    -- Some types of points are added continuously. These are tracked here.
    self.continuousScores = { }
    
    self.serverJoinTime = Shared.GetTime()

    self.playerLevel = -1
    self.totalXP = -1
    self.skill = -1
    self.skillOffset = -1
    self.commSkill = -1
    self.commSkillOffset = -1
    self.adagradSum = 0
    self.commAdagradSum = 0
    
    self.td_skill = -1
    self.td_skillOffset = -1
    self.td_commSkill = -1
    self.td_commSkillOffset = -1
    self.td_adagradSum = 0
    self.td_commAdagradSum = 0
    
    self.weightedEntranceTimes = {}
    self.weightedEntranceTimes[kTeam1Index] = {}
    self.weightedEntranceTimes[kTeam2Index] = {}
    
    self.weightedExitTimes = {}
    self.weightedExitTimes[kTeam1Index] = {}
    self.weightedExitTimes[kTeam2Index] = {}
    
    self.weightedCommanderTimes = {}
    self.weightedCommanderTimes[kTeam1Index] = {}
    self.weightedCommanderTimes[kTeam2Index] = {}

    self.playTime = 0
    self.marineTime = 0
    self.alienTime = 0
    self.alienCommTime = 0
    self.marineCommTime = 0

end

-- Add commander playing teams separate per team
-- Vanilla only tracks overall commanding time
function ScoringMixin:UpdatePlayerStats(deltaTime)

    local steamId = self:GetSteamId()
    if steamId > 0 then -- ignore players without a valid steamid (bots etc.)

        local clientStat = StatsUI_GetStatForClient(steamId)
        if self:GetIsPlaying() and clientStat then

            local teamNumber = self:GetTeamNumber()
            local statusPlayer = clientStat
            local statusRoot = clientStat["status"]
            local stat = clientStat[teamNumber]

            -- Make sure we update times only once per frame
            if not statusPlayer.lastUpdate or statusPlayer.lastUpdate < Shared.GetTime() then

                statusPlayer.lastUpdate = Shared.GetTime()

                if self:isa("Commander") then
                    stat.commanderTime = stat.commanderTime + deltaTime
                end

                stat.timePlayed = stat.timePlayed + deltaTime
                local status = StatsUI_GetStatusGrouping(self:GetPlayerStatusDesc()) or self:GetPlayerStatusDesc()

                statusRoot[status] = (statusRoot[status] or 0) + deltaTime
            end
        end
    end

end

function ScoringMixin:GetScore()
    return self.score
end

function ScoringMixin:AddScore(points, res, wasKill)

    -- Should only be called on the Server.
    if Server then
    
        -- Tell client to display cool effect.
        if points and points ~= 0 and not GetGameInfoEntity():GetWarmUpActive() then
        
            local displayRes = ConditionalValue(type(res) == "number", res, 0)
            Server.SendNetworkMessage(Server.GetOwner(self), "ScoreUpdate", { points = points, res = displayRes, wasKill = wasKill == true }, true)
            self.score = Clamp(self.score + points, 0, self:GetMixinConstants().kMaxScore or 100)

            if not self.scoreGainedCurrentLife then
                self.scoreGainedCurrentLife = 0
            end

            self.scoreGainedCurrentLife = self.scoreGainedCurrentLife + points

            -- Handle Stats
            local steamId = self:GetSteamId()

            if steamId > 0 then

                local teamNumber = self:GetTeamNumber()
                StatsUI_MaybeInitClientStats(steamId, nil, teamNumber)

                local clientStat = StatsUI_GetStatForClient(steamId)
                local stat = clientStat and clientStat[teamNumber]

                if stat and stat.score then
                    stat.score = Clamp(stat.score + points, 0, kMaxScore)
                end
            end

        end
    
    end
    
end

function ScoringMixin:GetScoreGainedCurrentLife()
    return self.scoreGainedCurrentLife
end

function ScoringMixin:GetPlayerLevel()
    return self.playerLevel
end
  
function ScoringMixin:GetTotalXP()
    return self.totalXP
end

function ScoringMixin:GetPlayerSkill()
    return self.skill
end

function ScoringMixin:GetPlayerSkillOffset()
    return self.skillOffset
end

function ScoringMixin:GetPlayerTeamSkill()
    assert(HasMixin(self, "Team"))
    local team = self:GetTeamNumber()

    if team ~= kTeam1Index and team ~= kTeam2Index then
        return self.skill   --just stick with the "average" for RR players
    end

    return 
        ( team == kTeam1Index ) and 
        self.skill + self.skillOffset or
        self.skill - self.skillOffset
end

function ScoringMixin:GetCommanderTeamSkill()
    local team = self:GetTeamNumber()
    local commSkill = self.commSkill > 0 and self.commSkill or self.skill
    
    return 
        ( team == kTeam1Index ) and 
        commSkill + self.commSkillOffset or
        commSkill - self.commSkillOffset
end

function ScoringMixin:GetAdagradSum()
    return self.adagradSum
end

function ScoringMixin:GetCommanderSkill()
    return self.commSkill
end

function ScoringMixin:GetCommanderSkillOffset()
    return self.commSkillOffset
end

function ScoringMixin:GetCommanderAdagradSum()
    return self.commAdagradSum
end

function ScoringMixin:GetTDPlayerSkill()
    return self.td_skill
end

function ScoringMixin:GetTDPlayerSkillOffset()
    return self.td_skillOffset
end

function ScoringMixin:GetTDPlayerCommanderSkill()
    return self.td_commSkill
end

function ScoringMixin:GetTDPlayerCommanderSkillOffset()
    return self.td_commSkillOffset
end

function ScoringMixin:GetTDAdagradSum()
    return self.td_adagradSum
end

function ScoringMixin:GetTDCommanderAdagradSum()
    return self.td_commAdagradSum
end

function ScoringMixin:GetSkillTier()
    if self.GetIsVirtual and self:GetIsVirtual() then return -1 end

    local skill = self:GetPlayerSkill()
    if Shared.GetThunderdomeEnabled() then
        skill = self:GetTDPlayerSkill()
    end

    if skill < 0 then return -2 end

    if not self.skillTier then
        local isRookie = self:GetPlayerLevel() <= kRookieLevel
        self.skillTier = GetPlayerSkillTier(skill, isRookie, self:GetAdagradSum())
    end

    return self.skillTier
end

if Server then

    --Callback handlers from CommandStrcuture_Server, logs in/out times for commanders
    function ScoringMixin:OnCommanderStructureLogin(structure)
        assert(structure)
        local teamIdx = structure:GetTeamNumber()
        local gameRules = GetGamerules()
        assert(gameRules)

        gameRules.playerRanking:SetCommanderEntranceTime( self, teamIdx )
    end

    function ScoringMixin:OnCommanderStructureLogout(structure)
        assert(structure)
        local teamIdx = structure:GetTeamNumber()
        local gameRules = GetGamerules()
        assert(gameRules)

        gameRules.playerRanking:SetCommanderExitTime( self, teamIdx )
    end

    function ScoringMixin:CopyPlayerDataFrom(player)
    
        self.scoreGainedCurrentLife = player.scoreGainedCurrentLife    
        self.score = player.score or 0
        self.kills = player.kills or 0
        self.assistkills = player.assistkills or 0
        self.deaths = player.deaths or 0
        self.playTime = player.playTime or 0
        self.alienCommTime = player.alienCommTime or 0
        self.marineCommTime = player.marineCommTime or 0
        self.marineTime = player.marineTime or 0
        self.alienTime = player.alienTime or 0
        
        self.weightedEntranceTimes = player.weightedEntranceTimes
        self.weightedExitTimes = player.weightedExitTimes
        
        self.weightedCommanderTimes = player.weightedCommanderTimes

        self.teamAtEntrance = player.teamAtEntrance
        
        self.totalKills = player.totalKills
        self.totalAssists = player.totalAssists
        self.totalDeaths = player.totalDeaths
        self.skill = player.skill
        self.skillOffset = player.skillOffset
        self.commSkill = player.commSkill
        self.commSkillOffset = player.commSkillOffset
        self.adagradSum = player.adagradSum
        self.commAdagradSum = player.commAdagradSum

        self.td_skill = player.td_skill
        self.td_skillOffset = player.td_skillOffset
        self.td_commSkill = player.td_commSkill
        self.td_commSkillOffset = player.td_commSkillOffset
        self.td_adagradSum = player.td_adagradSum
        self.td_commAdagradSum = player.td_commAdagradSum

        self.skillTier = player.skillTier
        self.totalScore = player.totalScore
        self.totalPlayTime = player.totalPlayTime
        self.playerLevel = player.playerLevel
        self.totalXP = player.totalXP
        
    end

    function ScoringMixin:OnKill()    
        self.scoreGainedCurrentLife = 0
    end
    
    function ScoringMixin:GetMarinePlayTime()
        return self.marineTime
    end
    
    function ScoringMixin:GetAlienPlayTime()
        return self.alienTime
    end
    
    function ScoringMixin:GetAlienCommanderTime()
        return self.alienCommTime or 0
    end
    
    function ScoringMixin:GetMarineCommanderTime()
        return self.marineCommTime or 0
    end
    
    local function SharedUpdate(self, deltaTime)
    
        if not self.marineCommTime then
            self.marineCommTime = 0
        end
        
        if not self.alienCommTime then
            self.alienCommTime = 0
        end

        if not self.playTime then
            self.playTime = 0
        end
        
        if not self.marineTime then
            self.marineTime = 0
        end
        
        if not self.alienTime then
            self.alienTime = 0
        end    
        
        if self:GetIsPlaying() then
        
            local teamType = self:GetTeamType()

            self.playTime = self.playTime + deltaTime

            if self:isa("Commander") and teamType == kMarineTeamType then
                self.marineCommTime = self.marineCommTime + deltaTime
            end
            
            if self:isa("Commander") and teamType == kAlienTeamType then
                self.alienCommTime = self.alienCommTime + deltaTime
            end
            
            if teamType == kMarineTeamType then
                self.marineTime = self.marineTime + deltaTime
            end
            
            if teamType == kAlienTeamType then
                self.alienTime = self.alienTime + deltaTime
            end
        
        end

        self:UpdatePlayerStats(deltaTime)
    end
    
    function ScoringMixin:OnProcessMove(input)
        SharedUpdate(self, input.time)
    end
    
    function ScoringMixin:OnUpdate(deltaTime)
        PROFILE("ScoringMixin:OnUpdate")
        SharedUpdate(self, deltaTime)
    end

end

function ScoringMixin:GetPlayTime()
    return self.playTime
end

function ScoringMixin:GetLastTeam()
    return self.teamAtEntrance
end

function ScoringMixin:AddKill()
    if GetWarmupActive() then return end

    if not self.kills then
        self.kills = 0
    end    

    self.kills = Clamp(self.kills + 1, 0, kMaxKills)
    
    if self.clientIndex and self.clientIndex > 0 then
        if not gSessionKills[self.clientIndex] then
            gSessionKills[self.clientIndex] = 0
        end
        gSessionKills[self.clientIndex] = gSessionKills[self.clientIndex] + 1
    end

    -- Handle Stats
    if Server then

        local steamId = self:GetSteamId()
        if steamId > 0 then
            local teamNumber = self:GetTeamNumber()
            StatsUI_MaybeInitClientStats(steamId, nil, teamNumber)

            local clientStat = StatsUI_GetStatForClient(steamId)
            local stat = clientStat and clientStat[teamNumber]

            if stat and stat.kills then
                stat.kills = Clamp(stat.kills + 1, 0, kMaxKills)
            end
        end
    end

end

function ScoringMixin:AddAssistKill()
    if GetWarmupActive() then return end

    if not self.assistkills then
        self.assistkills = 0
    end    

    self.assistkills = Clamp(self.assistkills + 1, 0, kMaxKills)

    -- Handle Stats
    if Server then

        local steamId = self:GetSteamId()
        if steamId > 0 then

            local teamNumber = self:GetTeamNumber()
            StatsUI_MaybeInitClientStats(steamId, nil, teamNumber)

            local clientStat = StatsUI_GetStatForClient(steamId)
            local stat = clientStat and clientStat[teamNumber]

            if stat and stat.assists then
                stat.assists = Clamp(stat.assists + 1, 0, kMaxKills)
            end
        end
    end

end

function ScoringMixin:GetKills()
    return self.kills
end

function ScoringMixin:GetAssistKills()
    return self.assistkills
end

function ScoringMixin:GetDeaths()
    return self.deaths
end

function ScoringMixin:AddDeaths()
    if GetWarmupActive() then return end

    if not self.deaths then
        self.deaths = 0
    end

    self.deaths = Clamp(self.deaths + 1, 0, kMaxDeaths)

    -- Handle Stats
    if Server then

        local steamId = self:GetSteamId()
        if steamId > 0 then

            local teamNumber = self:GetTeamNumber()
            StatsUI_MaybeInitClientStats(steamId, nil, teamNumber)

            local clientStat = StatsUI_GetStatForClient(steamId)
            local stat = clientStat and clientStat[teamNumber]

            if stat and stat.deaths then
                stat.deaths = Clamp(stat.deaths + 1, 0, kMaxDeaths)
            end
        end
    end

end

function ScoringMixin:SetEntranceTime( teamNumber, time )
    if time and teamNumber and ( teamNumber == kTeam1Index or teamNumber == kTeam2Index ) then
        self.teamAtEntrance = teamNumber
        table.insert( self.weightedEntranceTimes[teamNumber], time )
    end
end

function ScoringMixin:SetExitTime( teamNumber, time ) 
    if time and teamNumber and ( teamNumber == kTeam1Index or teamNumber == kTeam2Index ) then
        table.insert( self.weightedExitTimes[teamNumber], time )
    end
end

function ScoringMixin:SetCommanderEntranceTime( teamNumber, time )
    assert(teamNumber and (teamNumber == kTeam1Index or teamNumber == kTeam2Index))
    assert(time and time >= 0)  --entrance can be round-releative start-time (0)
    local newEntry = { enter = time, exit = -1 }
    table.insert(self.weightedCommanderTimes[teamNumber], newEntry)
end

function ScoringMixin:SetCommanderExitTime( teamNumber, time )
    assert(teamNumber and (teamNumber == kTeam1Index or teamNumber == kTeam2Index))
    assert(time and time > 0)

    --must only be called AFTER SetCommanderEntranceTime
    assert(#self.weightedCommanderTimes[teamNumber] >= 1)

    --work through time-sets backwards
    local i = #self.weightedCommanderTimes[teamNumber]
    repeat
        if self.weightedCommanderTimes[teamNumber][i].exit == -1 then
            self.weightedCommanderTimes[teamNumber][i].exit = time
            return true
        end
        i = i - 1
    until i < 1

    Log("Warning: Did not find empty exit slot in Commander time-sets")
    return false
end


if Server then
Event.Hook("Console_dumpcommtimes", function(client)

    for _, comm in ientitylist(Shared.GetEntitiesWithClassname("Commander")) do
        Log("Comm Times for Player[%s] on Team-%s", comm:GetId(), comm:GetTeamNumber())
        if comm.weightedCommanderTimes then
            Log("\tCommander Time-Sets:")
            Log("\t%s", comm.weightedCommanderTimes)
        else
            Log("Failed to find object fields of ScoringMixin for Player[%s]", comm:GetId())
        end
    end
    
end)
end

function ScoringMixin:GetWeightedCommanderPlayTime( teamIdx )
    local weightedTime = 0

    if #self.weightedCommanderTimes[teamIdx] < 1 then
        return weightedTime --no entries, skip
    end

    for i, set in ipairs(self.weightedCommanderTimes[teamIdx]) do
        if set.enter >= 0 and set.exit > 0 then
            weightedTime = weightedTime + ( math.pow( aT, (set.enter * -1) ) - math.pow( aT, (set.exit * -1) ) )
        else
            Log("Warning: incomplete time-set for weighted commander times on Team[%s]!", teamIdx)
            Log("\t Idx[%s]  -  enter: %s   exit: %s", i, set.enter, set.exit)
        end
    end

    return weightedTime
end


function ScoringMixin:GetWeightedPlayTime( forTeamIdx )
    
    local weightedTime = 0

    if forTeamIdx ~= kTeam1Index and forTeamIdx ~= kTeam2Index then
        return weightedTime
    end
    
    if not self.weightedEntranceTimes[forTeamIdx] or #self.weightedEntranceTimes[forTeamIdx] <= 0 then
    --bail early to avoid loops
        return weightedTime
    end

    --Since time-spent on teams doesn't exceed allotted gameTime, additive is used
    local entrance, exit
    local te, tx = 1, 1
    repeat
        -- get entrance
        repeat 
            entrance, te = self.weightedEntranceTimes[forTeamIdx][te], te + 1
        until not entrance or not exit or entrance > exit -- Ensure non-paired times are skipped.
        
        -- get corresponding exit
        if entrance then
            repeat 
                exit, tx = self.weightedExitTimes[forTeamIdx][tx], tx + 1
            until not exit or exit > entrance -- Ensure non-paired times are skipped.
            
            if exit then
                weightedTime = weightedTime + ( math.pow( aT, (entrance * -1) ) - math.pow( aT, (exit * -1) ) )
            end
        end
        
    until not entrance or not exit
    
    return weightedTime
    
end

function ScoringMixin:ResetScores()
    
    self.score = 0
    self.kills = 0
    self.assistkills = 0
    self.deaths = 0    

    self.commanderTime = 0
    self.playTime = 0
    self.marineTime = 0
    self.alienTime = 0
    self.marineCommTime = 0
    self.alienCommTime = 0
    
    self.weightedEntranceTimes = {}
    self.weightedEntranceTimes[kTeam1Index] = {}
    self.weightedEntranceTimes[kTeam2Index] = {}
    
    self.weightedExitTimes = {}
    self.weightedExitTimes[kTeam1Index] = {}
    self.weightedExitTimes[kTeam2Index] = {}

    self.weightedCommanderTimes = {}
    self.weightedCommanderTimes[kTeam1Index] = {}
    self.weightedCommanderTimes[kTeam2Index] = {}

end

-- Only award the pointsGivenOnScore once the amountNeededToScore are added into the score
-- determined by the passed in name.
-- An example, to give points based on health healed:
-- AddContinuousScore("Heal", amountHealed, 100, 1)
function ScoringMixin:AddContinuousScore(name, addAmount, amountNeededToScore, pointsGivenOnScore)

    if Server then
    
        self.continuousScores[name] = self.continuousScores[name] or { amount = 0 }
        self.continuousScores[name].amount = self.continuousScores[name].amount + addAmount
        while self.continuousScores[name].amount >= amountNeededToScore do
        
            self:AddScore(pointsGivenOnScore, 0)
            self.continuousScores[name].amount = self.continuousScores[name].amount - amountNeededToScore
            
        end
        
    end
    
end

if Server then

    function ScoringMixin:SetTotalKills(totalKills)
        self.totalKills = math.round(totalKills)
    end
    
    function ScoringMixin:SetTotalAssists(totalAssists)
        self.totalAssists = math.round(totalAssists)
    end
    
    function ScoringMixin:SetTotalDeaths(totalDeaths)
        self.totalDeaths = math.round(totalDeaths)
    end
    
    function ScoringMixin:SetPlayerSkill(skill)
        self.skill = math.round(skill)
    end

    function ScoringMixin:SetPlayerSkillOffset( skillOffset )
        self.skillOffset = skillOffset
    end

    function ScoringMixin:SetAdagradSum(adagradSum)
        self.adagradSum = adagradSum
    end

    function ScoringMixin:SetCommanderAdagradSum(adagradSum)
        self.commAdagradSum = adagradSum
    end

    function ScoringMixin:SetCommanderSkill( commSkill )
        self.commSkill = math.round(commSkill)
    end

    function ScoringMixin:SetCommanderSkillOffset( commSkillOffset )
        self.commSkillOffset = commSkillOffset
    end

    function ScoringMixin:SetTDPlayerSkill(skill)
        self.td_skill = math.round(skill)
    end

    function ScoringMixin:SetTDPlayerSkillOffset( skillOffset )
        self.td_skillOffset = skillOffset
    end

    function ScoringMixin:SetTDAdagradSum(adagradSum)
        self.td_adagradSum = adagradSum
    end

    function ScoringMixin:SetTDCommanderAdagradSum(adagradSum)
        self.td_commAdagradSum = adagradSum
    end

    function ScoringMixin:SetTDCommanderSkill( commSkill )
        self.td_commSkill = math.round(commSkill)
    end

    function ScoringMixin:SetTDCommanderSkillOffset( commSkillOffset )
        self.td_commSkillOffset = commSkillOffset
    end
    
    function ScoringMixin:SetTotalScore(totalScore)
        self.totalScore = math.round(totalScore)
    end
    
    function ScoringMixin:SetTotalPlayTime(totalPlayTime)
        self.totalPlayTime = math.round(totalPlayTime)
    end
    
    function ScoringMixin:SetPlayerLevel(playerLevel)
        self.playerLevel = math.round(playerLevel)
    end 

    function ScoringMixin:SetTotalXP(playerLevel)
        self.totalXP = math.round(playerLevel)
    end 

end --End-Server

