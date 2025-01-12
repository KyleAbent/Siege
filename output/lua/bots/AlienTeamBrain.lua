

Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/TeamBrain.lua")
Script.Load("lua/OrderedSet.lua")
Script.Load("lua/UnorderedSet.lua")
Script.Load("lua/IterableDict.lua")

local kTunnelQueueSortInterval = 1

---@class AlienTeamBrain : TeamBrain
class 'AlienTeamBrain' (TeamBrain)

function AlienTeamBrain:Initialize(label, teamNumber)

    TeamBrain.Initialize(self, label, teamNumber)

    self.tunnelQueues = IterableDict()
    self.tunnelPlayers = UnorderedSet()
    self.timeLastTunnelQueueSorted = 0

end

function AlienTeamBrain:Reset()
    TeamBrain.Reset(self)
    self.timeLastTunnelQueueSorted = 0

    -- Clear desired lifeform evolutions left over from warmup/last round
    for _, bot in ipairs(self.teamBots) do

        -- teamBots may not have been cleared on reset
        if IsValid(bot) then
            bot.lifeformEvolution = nil
        end
    end

end


function AlienTeamBrain:Update()

    TeamBrain.Update(self)

    local timeSinceLastSort = (Shared.GetTime() - self.timeLastTunnelQueueSorted)
    if timeSinceLastSort > kTunnelQueueSortInterval and self.tunnelPlayers:GetSize() > 0 then
        self:SortAllTunnelQueues()
    end

end

---@param mem TeamBrain.Memory
function AlienTeamBrain:CalcAttackerThreat( mem, entity )

    local threat = TeamBrain.CalcAttackerThreat(self, mem, entity)

    if entity:isa("Veil") or entity:isa("Shell") or entity:isa("Spur") then
    -- treat main-base tech structures like hives
        threat = threat + 1.0
    elseif entity:isa("Crag") or entity:isa("Shift") or entity:isa("Shade") or entity:isa("TunnelEntrance") then
    -- expensive forward structures need to be prioritized as well
        threat = threat + 0.5
    elseif entity:isa("Gorge") then
    -- protect the gorges!
        threat = threat + 0.25
    end

    return threat

end

local _tunnelPos -- For sorting by closest alien when enqueued
local function RemovePlayerFromTunnelQueue(self, playerId)

    if not self.tunnelPlayers:Contains(playerId) then return end

    -- Find where the bot's player is enqueue for the tunnel and remove it
    for tunnelId, iTable in pairs(self.tunnelQueues) do
        local findIdx = table.find(iTable, playerId)
        if findIdx then
            table.remove(iTable, findIdx)
            self.tunnelPlayers:RemoveElement(playerId)
            return
        end
    end

    assert(false, "Tunnel Players Set contains playerId, but could not find in any tunnel queues!")

end

local function SortByDistance(a, b)
    local aPos = Shared.GetEntity(a):GetOrigin()
    local bPos = Shared.GetEntity(b):GetOrigin()
    local aDist = _tunnelPos:GetDistance(aPos)
    local bDist = _tunnelPos:GetDistance(bPos)
    return aDist < bDist
end

function AlienTeamBrain:SortAllTunnelQueues()
    for tunnelEntId, queueTable in pairs(self.tunnelQueues) do
        if queueTable and #queueTable > 0 then
            self:SortTunnelQueue(tunnelEntId)
        end
    end

    self.timeLastTunnelQueueSorted = Shared.GetTime()
end

function AlienTeamBrain:SortTunnelQueue(tunnelEntranceId)

    local targetTunnelQueue = self.tunnelQueues[tunnelEntranceId]
    if targetTunnelQueue then

        _tunnelPos = Shared.GetEntity(tunnelEntranceId):GetOrigin()
        table.sort(targetTunnelQueue, SortByDistance)

    end

end

function AlienTeamBrain:EnqueueBotForTunnel(botPlayerId, tunnelEntranceId)

    if self.tunnelPlayers:Contains(botPlayerId) then
        local targetTunnelQueue = self.tunnelQueues[tunnelEntranceId]
        if targetTunnelQueue then
            if table.find(targetTunnelQueue, botPlayerId) then
                return
            end
        end
    end

    RemovePlayerFromTunnelQueue(self, botPlayerId)

    if self.tunnelQueues[tunnelEntranceId] == nil then
        self.tunnelQueues[tunnelEntranceId] = {}
    end

    local queue = self.tunnelQueues[tunnelEntranceId]
    table.insert(queue, botPlayerId)

    self:SortTunnelQueue(tunnelEntranceId)

    self.tunnelPlayers:Add(botPlayerId)

end

function AlienTeamBrain:DequeueBotForTunnel(botPlayerId)
    RemovePlayerFromTunnelQueue(self, botPlayerId)
end

function AlienTeamBrain:GetCanBotUseTunnel(botPlayerId, tunnelEntranceId)

    local tunnelQueue = self.tunnelQueues[tunnelEntranceId]
    assert(tunnelQueue ~= nil, "Tunnel queue was empty when bot asked if it's up next for tunnel!")
    assert(tunnelQueue[1] ~= nil, "No Players in INITIALIZED tunnel queue!")

    return (tunnelQueue[1] == botPlayerId), tunnelQueue[1]

end

function AlienTeamBrain:RemoveTunnelQueue(tunnelEntranceId)

    -- Theres a few seconds where a tunnel being removed
    -- due to an entrance relocation still exists which
    -- causes errors with the tunnel queue
    self:OnEntityChange(tunnelEntranceId, nil)

end

function AlienTeamBrain:OnEntityChange(oldId, newId)

    TeamBrain.OnEntityChange(self, oldId, newId)

    local isCreated = (oldId == nil and newId ~= nil)
    local isDeleted = (oldId ~= nil and newId == nil)
    local isReplaced = (oldId ~= nil and newId ~= nil)

    if isDeleted or isReplaced then

        local deletedEnt = Shared.GetEntity(oldId)
        local isTunnel = deletedEnt and deletedEnt:isa("TunnelEntrance")
        local isPlayer = deletedEnt and deletedEnt:isa("Player")

        if isTunnel then
            local deletedTunnelQueue = self.tunnelQueues[oldId]
            if deletedTunnelQueue then
                for i = 1, #deletedTunnelQueue do
                    self.tunnelPlayers:RemoveElement(deletedTunnelQueue[i])
                end
            end

            self.tunnelQueues[oldId] = nil

        elseif isPlayer then
            RemovePlayerFromTunnelQueue(self, oldId)
        end

    end

end
