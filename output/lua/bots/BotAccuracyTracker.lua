-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/BotAccuracyTracker.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
-- Works similarly ServerStats, and keeps track of all Bot's accuracy per-encounter, as well as lifetime.
-- Simply for data, but is used to control how often a bot hits a targett
--
-- ========= For more information, visit us at http://www.unknownworlds.com =======================

assert(Server, "BotAccuracyTracker can only be loaded on Server!")

local _BotAccInstance
function GetBotAccuracyTracker()
    if not _BotAccInstance then
        _BotAccInstance = BotAccuracyTracker()
        _BotAccInstance:Initialize()
    end
    return _BotAccInstance
end

--- Makes sure the table for the client, and the weapon classname exist.
local function EnsureAccTableExists(self, clientId, weaponGroup)
    if not self.lifetimeAccData[clientId] then
        self.lifetimeAccData[clientId] = {}
    end

    if not self.lifetimeAccData[clientId][weaponGroup] then
        self.lifetimeAccData[clientId][weaponGroup] = { hits = 0, total = 0 }
    end

    if not self.encounterAccData[clientId] then
        self.encounterAccData[clientId] = {}
    end

    if not self.encounterAccData[clientId][weaponGroup] then
        self.encounterAccData[clientId][weaponGroup] = { hits = 0, total = 0 }
    end
end

--- @class BotAccuracyTracker
class "BotAccuracyTracker"

function BotAccuracyTracker:Initialize()

    self.lifetimeAccData = {}
    self.encounterAccData = {}

end

--- Add a hit or miss stat to the bot owner's encounter stats. Weapon classname is
--- useful for mixed melee/ranged players like Lerks, where we could want
--- different accuracies depending which weapon is used.
---@param ownerClient ServerClient
---@param isHit boolean
---@param weaponGroup kBotAccWeaponGroup
function BotAccuracyTracker:AddAccuracyStat(ownerClient, isHit, weaponGroup)
    if not ownerClient then return end -- Hallucinations do not have a ServerClient, they are just Players with PlayerBrains that generate moves.
    assert(weaponGroup, "No weapon group was passed!")

    if not ownerClient:GetIsVirtual() then return end

    local botClientId = ownerClient:GetId()
    EnsureAccTableExists(self, botClientId, weaponGroup)

    -- Add to encounter stats.
    -- It's up to bot brains/actions to tell this tracker when an encounter has ended.
    local encounterAccTable = self.encounterAccData[botClientId][weaponGroup]
    local lifetimeAccTable = self.lifetimeAccData[botClientId][weaponGroup]
    encounterAccTable.total = encounterAccTable.total + 1
    lifetimeAccTable.total = lifetimeAccTable.total + 1

    if isHit then
        encounterAccTable.hits = encounterAccTable.hits + 1
        lifetimeAccTable.hits = lifetimeAccTable.hits + 1
    end

end

--- Ends the encounter for the specified Virtual Client.
--- Simply clears the encounter acc data for the bot in question.
---@param client ServerClient
function BotAccuracyTracker:EndEncounter(client)
    assert(client, "No ServerClient was passed!")

    if not client:GetIsVirtual() then return end

    local botClientId = client:GetId()
    if self.encounterAccData[botClientId] then
        self.encounterAccData[botClientId] = { }
    end

end

--- Gets the accuracy for a Bot, in regards to a weapon group.
---@param client ServerClient
---@param weaponGroup kBotAccWeaponGroup
---@param lifetime boolean If true, returns total of bot's existence + current encounter. Otherwise, just the current encounter.
---@return number Accuracy (represented as 0 - 100%)
function BotAccuracyTracker:GetBotAccuracy(client, weaponGroup, lifetime)
    assert(client, "No ServerClient was passed!")
    assert(weaponGroup, "No weapon group was passed!")

    if not client:GetIsVirtual() then return end

    local botClientId = client:GetId()
    EnsureAccTableExists(self, botClientId, weaponGroup)

    local hits = self.encounterAccData[botClientId][weaponGroup].hits
    local total = self.encounterAccData[botClientId][weaponGroup].total

    if lifetime then
        hits = self.lifetimeAccData[botClientId][weaponGroup].hits
        total = self.lifetimeAccData[botClientId][weaponGroup].total
    end

    if total == 0 then
        return 0
    end

    return (hits / total) * 100

end

function BotAccuracyTracker:ClearClient(client)
    assert(client, "No client passed when clearing!")

    local botClientId = client:GetId()
    if self.encounterAccData[botClientId] then
        self.encounterAccData[botClientId] = {}
    end

    if self.lifetimeAccData[botClientId] then
        self.lifetimeAccData[botClientId] = {}
    end

end

function BotAccuracyTracker:Reset()
    self.encounterAccData = {}
    self.lifetimeAccData = {}
end

function BotAccuracyTracker:GetAccuracySummaryString(client, lifetime)

    local clientId = client:GetId()
    local accTable = lifetime and self.lifetimeAccData or self.encounterAccData
    local botAccTable = accTable[clientId]
    if not botAccTable then
        return "No accuracy data"
    end

    local summaryString = lifetime and "Lifetime Accuracy\n" or "Encounter Accuracy\n"

    for i = 1, #kBotAccWeaponGroup do

        local groupName = kBotAccWeaponGroup[i]
        local actualGroup = kBotAccWeaponGroup[groupName]
        local weaponGroup = botAccTable[actualGroup]
        if weaponGroup then
            summaryString = string.format("%s- %s: %.2f%%\n", summaryString, groupName, self:GetBotAccuracy(client, actualGroup, lifetime))
        end

    end

    return summaryString

end

local function OnClientDisconnect(client)
    GetBotAccuracyTracker():ClearClient(client)
end
Event.Hook("ClientDisconnect", OnClientDisconnect)
