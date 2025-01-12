

Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/TeamBrain.lua")
Script.Load("lua/IterableDict.lua")

local kPGQueueResortTime = 1

---@class MarineTeamBrain : TeamBrain
MarineTeamBrain = nil
class 'MarineTeamBrain' (TeamBrain)

function MarineTeamBrain:Initialize(label, teamNumber)

    TeamBrain.Initialize(self, label, teamNumber)

    --?? Marine specific? Make path-points for all Res-node to Power? or whatever pre-caching is ideal

    -- PhaseGate ent id -> iTable "queue"
    self.phaseGateQueues = IterableDict()

    -- Easy way to determine if a player is waiting for a phase gate
    -- Player end id -> phase gate ent id (key of phase gate queue)
    self.phaseGateWaiters = IterableDict()
    self.timeLastPGQueuesSorted = 0

    self.teamArmories = UnorderedSet()

    local armories = GetEntitiesForTeam("Armory", teamNumber)

    for i = 1, #armories do
        self.teamArmories:Add(armories[i]:GetId())
    end

end

function MarineTeamBrain:Update()
    TeamBrain.Update(self)      --TODO Review/Revise once White/Black goal-board is in place

    local now = Shared.GetTime()
    local timeSinceLastSort = (now - self.timeLastPGQueuesSorted)
    if timeSinceLastSort > kPGQueueResortTime and self.phaseGateQueues:GetSize() > 0 then

        for pgEntId, _ in pairs(self.phaseGateQueues) do
            self:SortPGQueue(pgEntId)
        end

        self.timeLastPGQueuesSorted = now

    end

end

function MarineTeamBrain:GetIsNextForPGQueue(playerId)

    --Log("$ MarineTeamBrain:GetIsNextForPGQueue")
    local pgEntId = self.phaseGateWaiters[playerId]

    --Log("\tPGEntId: %s", pgEntId)

    if not pgEntId then return false end

    local pgQueue = self.phaseGateQueues[pgEntId]

    --Log("\tPGQueue: %s", pgQueue)

    if not pgQueue then return false end -- Could cause every marine in a very busy PG to try at once causing stuck issues
    if #pgQueue <= 0 then return false end

    return pgQueue[1] == playerId
end

function MarineTeamBrain:GetNextInQueue(phaseGateId)

    local pgQueue = self.phaseGateQueues[phaseGateId]
    if not pgQueue then return false end -- Could cause every marine in a very busy PG to try at once causing stuck issues
    if #pgQueue <= 0 then return false end

    return pgQueue[1]

end

function MarineTeamBrain:RemovePlayerFromPGQueue(playerId)
    PROFILE("MarineTeamBrain:RemovePlayerFromPGQueue")

    local phaseGateId = self.phaseGateWaiters[playerId]
    if not phaseGateId then return end -- Not in a queue!

    self.phaseGateWaiters[playerId] = nil

    local phaseGateQueue = self.phaseGateQueues[phaseGateId]
    if not phaseGateQueue then return end -- Queue doesn't exist... assert?

    table.removevalue(phaseGateQueue, playerId)

end

function MarineTeamBrain:AddPlayerToPGQueue(phaseGateId, playerId)
    PROFILE("MarineTeamBrain:AddPlayerToPGQueue")

    -- Handle previous queue if exists
    local prevPGId = self.phaseGateWaiters[playerId]
    if prevPGId then
        if prevPGId == phaseGateId then -- We are already in the correct queue, skip!
            return
        else
            self:RemovePlayerFromPGQueue(playerId)
        end
    end

    -- Now we can add the player to the proper queue
    if not self.phaseGateQueues[phaseGateId] then
        self.phaseGateQueues[phaseGateId] = {}
    end

    -- If a marine phases it will start IN the next gate,
    -- and therefore will be the closest one.
    -- However, when the marine bot enters the next queue it should do a sort
    -- so it would then be first in line.

    table.insert(self.phaseGateQueues[phaseGateId], playerId)
    self.phaseGateWaiters[playerId] = phaseGateId

    self:SortPGQueue(phaseGateId)

end

local pgToSortPos
local function SortByEntDist(a, b)
    if not pgToSortPos then
        return true
    end

    local aEnt = Shared.GetEntity(a)
    local bEnt = Shared.GetEntity(b)
    if aEnt and bEnt then
        local aDist = (aEnt:GetOrigin() - pgToSortPos):GetLengthSquared()
        local bDist = (bEnt:GetOrigin() - pgToSortPos):GetLengthSquared()
        return aDist < bDist
    else
        return aEnt ~= nil -- Existing ents first (should never happen)
    end
end

function MarineTeamBrain:SortPGQueue(phaseGateId)
    local pgQueue = self.phaseGateQueues[phaseGateId]
    if not pgQueue then return end -- Queue does not exist!

    local phaseGateEnt = Shared.GetEntity(phaseGateId)
    if not phaseGateEnt or not phaseGateEnt:isa("PhaseGate") then return end

    pgToSortPos = phaseGateEnt:GetOrigin()
    table.sort(pgQueue, SortByEntDist)
    pgToSortPos = nil
end

---@param mem TeamBrain.Memory
function MarineTeamBrain:CalcAttackerThreat( mem, entity )

    local threat = TeamBrain.CalcAttackerThreat(self, mem, entity)

    -- treat main-base tech structures like command chairs
    if entity:isa("InfantryPortal") or entity:isa("ArmsLab") or entity:isa("PrototypeLab") then
        threat = threat + 1.0
    -- expensive forward structures need to be prioritized as well
    elseif entity:isa("Observatory") or entity:isa("PhaseGate") then
        threat = threat + 0.5
    end

    return threat

end

function MarineTeamBrain:OnEntityChange(oldId, newId)

    TeamBrain.OnEntityChange(self, oldId, newId)

    --??

    if oldId then

        self.teamArmories:RemoveElement(oldId)

        -- PhaseGate queues
        local deletedEnt = Shared.GetEntity(oldId)
        local isPhaseGate = deletedEnt and deletedEnt:isa("PhaseGate")
        local isPlayer = deletedEnt and deletedEnt:isa("Player")

        if isPhaseGate then
            local deletedPGQueue = self.phaseGateQueues[oldId]
            if deletedPGQueue then -- Remove every player that was in that queue from phaseGateWaiters IterableDict
                for _, playerId in ipairs(deletedPGQueue) do
                    self.phaseGateWaiters[playerId] = nil
                end
            end

            -- Then remove the phase gate queue itself
            self.phaseGateQueues[oldId] = nil

        elseif isPlayer then
            self:RemovePlayerFromPGQueue(oldId)
        end

    end

    if newId then

        local ent = Shared.GetEntity(newId)

        if ent and ent:isa("Armory") then
            self.teamArmories:Add(newId)
        end

    end

end

