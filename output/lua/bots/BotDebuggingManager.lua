-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/BotDebuggingManager.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
-- Keeps track of which clients are targetting which bots for debugging.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

assert(Server)

Script.Load("lua/IterableDict.lua")
Script.Load("lua/bots/ManyToOne.lua")
Script.Load("lua/UnorderedSet.lua")
Script.Load("lua/bots/BotDebugSection.lua")

local _botDebuggingManager
function GetBotDebuggingManager()
    if not _botDebuggingManager then
        _botDebuggingManager = BotDebuggingManager()
        _botDebuggingManager:Initialize()
    end
    return _botDebuggingManager
end

---@class BotDebuggingManager
class "BotDebuggingManager"

function BotDebuggingManager:Initialize()

    -- Client(s) -> Single Debugging Target.
    -- Each "Target" is a "group" which is just the entity id of a Bot (not it's player)
    self.botDebuggers = ManyToOne()
    self.botDebuggers:Initialize()

    -- EZ map to tell which clients are debugging bots and which one.
    self.debuggingClients = IterableDict()

    -- EZ map if bots that are being targetted for debugging
    self.targettedBots = UnorderedSet()

    -- EZ map to tell which clients have "Follow Target" selected on Bot debugging UI
    self.followingClients = UnorderedSet()

    -- When following, a bot's player entity may die (destroyed)
    -- This just keeps track of which clients were unable to do a follow,
    -- so we can keep trying until the player entity is available again.
    self.followingClientsQueue = UnorderedSet()

    -- BotEntId -> IterableDict(SectionType -> DebugSection)
    self.botDebugSections = IterableDict()

    -- For determining if we should send a update to
    -- a client because it hasn't received a netmessage for the debug section yet.
    self.newClients = UnorderedSet()

end

function BotDebuggingManager:SendDebugInfoForBot(botId)
    if not self:GetIsBotTargetted(botId) then return end

    local debugSections = self.botDebugSections[botId]
    local botDebuggers = self.botDebuggers:GetItems(botId) -- Returns empty table if none
    if debugSections and #botDebuggers > 0 then
        for i = 1, #debugSections do

            local debugSection = debugSections[i]
            local debugSectionType = debugSection:GetType()
            local displayString = debugSection:GetDisplayString()
            local sectionChanged = debugSection:GetHasChanged()

            for j = 1, #botDebuggers do
                local clientId = botDebuggers[j]
                local client = Server.GetClientById(clientId)
                if client then
                    local clientNeedsCatchUp = self.newClients[clientId] ~= nil
                    if sectionChanged or clientNeedsCatchUp then
                        Server.SendNetworkMessage(client, "BotDebuggingSectionUpdate", {sectionType = debugSectionType, contents = displayString}, true)
                    end
                end
            end
            debugSection:ResetChangedFlag()
        end

        -- Remove debuggers targeting the bot id from new clients
        for _, clientId in ipairs(botDebuggers) do
            self.newClients:RemoveElement(clientId)
        end

    end
end

function BotDebuggingManager:UpdateBotDebugSectionField(botId, sectionType, fieldName, fieldValue)
    if not self:GetIsBotTargetted(botId) then return end

    if not self.botDebugSections[botId] then
        self.botDebugSections[botId] = IterableDict()
    end

    if not self.botDebugSections[botId][sectionType] then
        local newDebugSection = BotDebugSection()
        newDebugSection:Initialize(sectionType)
        self.botDebugSections[botId][sectionType] = newDebugSection
    end

    local debugSection = self.botDebugSections[botId][sectionType]
    debugSection:SetField(fieldName, fieldValue)

end

function BotDebuggingManager:GetIsPlayerDebuggingBots(player)
    if not player then return false end
    local client = player:GetClient()
    if not client then return false end
    return self.debuggingClients[client:GetId()] ~= nil
end

function BotDebuggingManager:ProcessFollowingQueue()

    if #self.followingClientsQueue <= 0 then return end

    local succeededClientIds = {}
    for i, clientId in ipairs(self.followingClientsQueue) do
        if self:SetClientFollowing(clientId, true) then
            table.insert(clientId)
        end
    end

    -- Delete client ids that were sucessfully set to following.
    for i, clientId in ipairs(succeededClientIds) do
        self.followingClientsQueue:RemoveElement(clientId)
    end
end

function BotDebuggingManager:GetIsBotTargetted(botEntId)
    return self.targettedBots:Contains(botEntId)
end

function BotDebuggingManager:AddClient(clientId, botEntId)

    -- Clients should only target one bot at a time
    self:RemoveClient(clientId)

    self.botDebuggers:Assign(clientId, botEntId)
    self.debuggingClients[clientId] = botEntId
    self.targettedBots:Add(botEntId)
    self.newClients:Add(clientId)

end

function BotDebuggingManager:RemoveClient(clientId)

    local botEntId = self.botDebuggers:Unassign(clientId)
    self.followingClients:RemoveElement(clientId)
    self.followingClientsQueue:RemoveElement(clientId)
    self.debuggingClients[clientId] = nil
    self.newClients:RemoveElement(clientId)

    -- Make sure to clean up the set if noone is targetting the bot anymore.
    if botEntId and self.botDebuggers:GetNumAssignedTo(botEntId) <= 0 then
        self.botDebuggers:RemoveGroup(botEntId)
        self.targettedBots:RemoveElement(botEntId)
        if self.botDebugSections[botEntId] ~= nil then
            self.botDebugSections[botEntId]:Clear()
        end
    end

end

function BotDebuggingManager:SetClientFollowing(clientId, following)
    assert(self.debuggingClients[clientId] ~= nil)

    local followSuccess = false
    local client = Server.GetClientById(clientId)
    if client then
        local specPlayer = client:GetControllingPlayer()
        if specPlayer then

            if following then

                local botEnt = Shared.GetEntity(self.debuggingClients[clientId])
                local botPlayer = botEnt:GetPlayer()
                if botPlayer then
                    specPlayer:SetSpectatorMode(kSpectatorMode.Following)
                    specPlayer:SetFollowTarget(botPlayer)
                    followSuccess = true
                end

            else
                specPlayer:SetSpectatorMode(kSpectatorMode.Overhead)
                specPlayer:ResetOverheadModeHeight()
                specPlayer:SetFollowTarget(nil)
            end

        end
    end

    -- Add to following queue if we couldn't complete it right now.
    if following and not followSuccess then
        self.followingClientsQueue:Add(clientId)
    elseif not following or followSuccess then
        self.followingClients:Add(clientId)
        return clientId
    end

end

function BotDebuggingManager:RemoveBot(botEntId)

    -- Need to tell all clients that are targetting this bot
    -- that it has been deleted.

    local clients = self.botDebuggers:GetItems(botEntId) -- returns empty table if group doesn't exist
    for i, clientId in ipairs(clients) do
        self:RemoveClient(clientId)
        local client = Server.GetClientById(clientId)
        if client then
            Server.SendNetworkMessage(client, "BotDebuggingTargetDestroyed", {}, true)
        end
    end

end

Event.Hook("EntityDestroy", function(entity)
    if entity:isa("Bot") then
        GetBotDebuggingManager():RemoveBot(entity:GetId())
    end
end)

Event.Hook("ClientDisconnect", function(client)
    GetBotDebuggingManager():RemoveClient(client:GetId())
end)

Event.Hook("UpdateServer", function()
    GetBotDebuggingManager():ProcessFollowingQueue()
end)
