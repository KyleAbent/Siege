--[[
 File: lua/bots/BotTeamController.lua

 Description: This Singleton controls how player bots get assigned automatically to the playing teams.
    The controller only starts to assign bots if there is a human player in any of the playing teams
    and if the given maxbot value is et higher than 0. In case the last human player left the controller
    will also remove all bots

 Creator: Sebastian Schuck (ghoulofgsg9@gmail.com)

 Copyright (c) 2015, Unknown Worlds Entertainment, Inc.
]]
class 'BotTeamController'

BotTeamController.MaxBots = 0
BotTeamController.updateLock = 0

local humanNum = 0
local function CountHumanPlayers( player )
    if not player:GetIsVirtual() then
        humanNum = humanNum + 1
    end
end

--[[
-- Returns how many humans and bots given team has
 ]]
function BotTeamController:GetPlayerNumbersForTeam(teamNumber, humanOnly)
    PROFILE("BotTeamController:GetPlayerNumbersForTeam")

    local team = GetGamerules():GetTeam(teamNumber)

    humanNum = 0
    team:ForEachPlayer(CountHumanPlayers)

    if humanOnly then return humanNum end

    local botNum = 0
    for _, bot in ipairs(gServerBots) do
        if bot:GetTeamNumber() == teamNumber then
            botNum = botNum + 1
        end
    end

    return humanNum, botNum
end

function BotTeamController:GetCommanderBot(teamNumber)
    for _, commander in ipairs(gCommanderBots) do
        if commander:GetTeamNumber() == teamNumber then
            return commander
        end
    end
end

function BotTeamController:RemoveCommanderBots()
    while gCommanderBots[1] do
        gCommanderBots[1]:Disconnect()
    end
end

function BotTeamController:RemoveCommanderBot(teamNumber)
    local bot = self:GetCommanderBot(teamNumber)

    if bot then
        bot:Disconnect()
    end

    if teamNumber == kTeam1Index then
        self.addCommander1 = false
    elseif teamNumber == kTeam2Index then
        self.addCommander2 = false
    end
end

function BotTeamController:GetTeamHasCommander(teamNumber)
    if self:GetCommanderBot(teamNumber) then return true end

    local commandStructures = GetEntitiesForTeam("CommandStructure", teamNumber)

    for _, commandStructure in ipairs(commandStructures) do
        if commandStructure.occupied or commandStructure.gettingUsed then return true end
    end

    return false
end

function  BotTeamController:GetTeamNeedsCommander(teamNumber)
    if not self.addCommander1 and teamNumber == kTeam1Index then return false end
    if not self.addCommander2 and teamNumber == kTeam2Index then return false end

    return not self:GetTeamHasCommander(teamNumber)
end

function BotTeamController:AddBots(teamIndex, amount)
    if amount < 1 then return end

    self:DisableUpdate() -- lock update

    if self:GetTeamNeedsCommander(teamIndex) then
        OnConsoleAddBots(nil, 1, teamIndex, "com")
        amount = amount - 1
    end

    if amount > 0 then
        OnConsoleAddBots(nil, amount, teamIndex)
    end

    self:EnableUpdate() -- unlock update
end

function BotTeamController:RemoveBots(teamIndex, amount)
    self:DisableUpdate() -- lock update

    OnConsoleRemoveBots(nil, amount, teamIndex)

    self:EnableUpdate() -- unlock update
end

function BotTeamController:UpdateBotsForTeam(teamNumber)
    local teamHumanNum, teamBotsNum = self:GetPlayerNumbersForTeam(teamNumber)

    local teamCount = teamBotsNum + teamHumanNum 
    local maxTeamBots = math.floor(self.MaxBots / 2)

    if teamCount < maxTeamBots then
        self:AddBots(teamNumber, maxTeamBots - teamCount)
    elseif teamCount > maxTeamBots then
        if teamBotsNum > 0 then
            local amount = math.min(teamCount - maxTeamBots, teamBotsNum)
            self:RemoveBots(teamNumber, amount)
        end
    elseif self:GetTeamNeedsCommander(teamNumber) then
        self:RemoveBots(teamNumber, 1)
        self:AddBots(teamNumber, 1)
    end

end

function BotTeamController:DisableUpdate()
    self.updateLock = self.updateLock + 1
end

function BotTeamController:EnableUpdate()
    self.updateLock = self.updateLock - 1

    assert(self.updateLock >= 0) -- something broke !!!
end

function BotTeamController:GetUpdateEnabled()
    local isEnabled = self.MaxBots > 0 -- BotTeamController is disabled
    local isNotLocked = self.updateLock == 0 -- avoid recursive update calls
    return isEnabled and isNotLocked
end
--[[
-- Adds/removes a bot if needed, calling this method will trigger a recursive loop
-- over the PostJoinTeam method rebalancing the bots.
 ]]
function BotTeamController:UpdateBots()
    PROFILE("BotTeamController:UpdateBots")

    if not self:GetUpdateEnabled() then return end -- avoid recursive calls

    self:DisableUpdate() -- lock update

    -- Get current human player counts
    local team1HumanNum = self:GetPlayerNumbersForTeam(kTeam1Index, true)
    local team2HumanNum = self:GetPlayerNumbersForTeam(kTeam2Index, true)
    local humanCount = team1HumanNum + team2HumanNum

    -- Remove all bots if all humans left the playing teams, so servers don't run bots idle
    if humanCount == 0 then
        self:RemoveBots(nil, #gServerBots)
    else
        self:UpdateBotsForTeam(kTeam1Index)
        self:UpdateBotsForTeam(kTeam2Index)
    end

    self:EnableUpdate() --unlock update
end

--[[
--Sets the amount of maximal allowed bots totally (without considering the amount of human players)
 ]]
function BotTeamController:SetMaxBots(newMaxBots, com)
    self.MaxBots = newMaxBots
    self.addCommander1 = com
    self.addCommander2 = com

    if newMaxBots == 0 then
        self:RemoveBots(nil, #gServerBots)
    end
end
