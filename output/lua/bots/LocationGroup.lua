-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/LocationGroup.lua
--
-- Created by: Darrell Gentry (darrell@unkownworlds.com)
--
-- Group of Location entities, with the same name.
-- Keeps track of marine/aliens stuff, with seperate counts for structures and players.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

class "LocationGroup"

Script.Load("lua/IterableDict.lua")
Script.Load("lua/UnorderedSet.lua")

function CreateLocationGroup(groupName)
    local newLocationGroup = LocationGroup()
    newLocationGroup:Initialize(groupName)
    return newLocationGroup
end

function LocationGroup:Initialize(groupName)

    self.groupName = groupName

    -- Only store entity ids
    self.marineStructures = UnorderedSet()
    self.marinePlayers = UnorderedSet()

    self.alienStructures = UnorderedSet()
    self.alienPlayers = UnorderedSet()

    -- For AI explore route spread, provides notion of "staleness"
    self.timeLastAlienPlayerEntered = 0
    self.timeLastMarinePlayerEntered = 0

    self.hasTechPoint = false
    self.hasResNode = false

    self.contentionState = kLocationState.Neutral

end

function LocationGroup:Reset()
    self.marinePlayers = UnorderedSet()
    self.marineStructures = UnorderedSet()

    self.alienPlayers = UnorderedSet()
    self.alienStructures = UnorderedSet()

    self.contentionState = kLocationState.Neutral

    self:ResetStaleness()
end

function LocationGroup:ResetStaleness()
    self.timeLastAlienPlayerEntered = 0
    self.timeLastMarinePlayerEntered = 0
end

--- Returns actual reference! Be careful!
function LocationGroup:GetPlayersForTeamType(teamType)
    if teamType == kTeam1Type then
        return self.marinePlayers
    elseif teamType == kTeam2Type then
        return self.alienPlayers
    else
        assert(false, "Invalid team type when getting players!")
    end
end

--- Returns actual reference! Be careful!
function LocationGroup:GetStructuresForTeamType(teamType)
    if teamType == kTeam1Type then
        return self.marineStructures
    elseif teamType == kTeam2Type then
        return self.alienStructures
    else
        assert(false, "Invalid team type when getting players!")
    end
end

-- Should only be called in brainsenses for performance
function LocationGroup:GetHasBuiltMarineStructures()

    for i = 1, #self.marineStructures do

        local ent = Shared.GetEntity(self.marineStructures[i])
        if ent and GetIsUnitActive(ent) then
            return true
        end

    end

    return false

end

function LocationGroup:GetStaleTimeForTeam(teamType)
    if teamType == kTeam1Type then
        return self.timeLastMarinePlayerEntered
    elseif teamType == kTeam2Type then
        return self.timeLastAlienPlayerEntered
    else
        assert(false, "Tried to call GetStaleTimeForTeam with invalid team type!")
    end
end

function LocationGroup:GetHasStrategicEnts()
    return self.hasResNode or self.hasTechPoint
end

function LocationGroup:GetIsFullyFeaturedTechRoom()
    return self.hasResNode and self.hasTechPoint
end

function LocationGroup:UpdateStaleForTeam(teamType)
    if teamType == kTeam1Type then
        self.timeLastMarinePlayerEntered = Shared.GetTime()
    elseif teamType == kTeam2Type then
        self.timeLastAlienPlayerEntered = Shared.GetTime()
    end
end

function LocationGroup:GetNumMarineStructures()
    return #self.marineStructures
end

function LocationGroup:GetHasActiveStructuresForTeam(forTeam)

    if forTeam ~= kTeam1Type and forTeam ~= kTeam1Type then
        return false
    end

    -- GetIsUnitActive
    local list = forTeam == kTeam1Type and self.marineStructures or self.alienStructures
    for i = 1, #list do

        local ent = Shared.GetEntity(list[i])
        if ent and GetIsUnitActive(ent) then
            return true
        end

    end

    return false

end

function LocationGroup:GetNumAlienStructures()
    return #self.alienStructures
end

--- Includes structures and players
function LocationGroup:GetNumMarines()
    return #self.marineStructures + #self.marinePlayers
end

--- Includes structures and players
function LocationGroup:GetNumAliens()
    return #self.alienStructures + #self.alienPlayers
end

function LocationGroup:GetNumPlayersForTeamType(teamType)
    if teamType == kTeam1Type then
        return self:GetNumMarinePlayers()
    elseif teamType == kTeam2Type then
        return self:GetNumAlienPlayers()
    else
        assert(false, "Tried to call GetNumPlayersForTeamType with invalid team type!")
    end
end

function LocationGroup:GetNumStructuresForTeamType(teamType)
    if teamType == kTeam1Type then
        return self:GetNumMarineStructures()
    elseif teamType == kTeam2Type then
        return self:GetNumAlienStructures()
    else
        assert(false, "Tried to call GetNumPlayersForTeamType with invalid team type!")
    end
end

function LocationGroup:GetNumMarinePlayers()
    return #self.marinePlayers
end

function LocationGroup:GetNumAlienPlayers()
    return #self.alienPlayers
end

function LocationGroup:SetHasTechPoint(hasTechPoint)
    self.hasTechPoint = hasTechPoint
end

function LocationGroup:SetHasResNode(hasResNode)
    self.hasResNode = hasResNode
end

local kStructureSafeDropRatio = 2.5 -- <#friendlies/#enemies>
function LocationGroup:GetIsSafeForStructureDrop(forTeam, isEarlyGame, debug)

    local numEnemyPlayers = #self:GetPlayersForTeamType(GetEnemyTeamNumber(forTeam))
    local numEnemyStructures = self:GetNumStructuresForTeamType(GetEnemyTeamNumber(forTeam))
    local numFriendlyPlayers = #self:GetPlayersForTeamType(forTeam)
    local numFriendlyStuctures = self:GetNumStructuresForTeamType(forTeam)

    -- No Enemies
    -- No Players, but friendly structures
    --

    if debug then
        Log("SafeForStructureDrop (%s)", self.groupName)
        Log("\tisEarlyGame: %s", isEarlyGame)
        Log("\tNum Enemy Players: %s", numEnemyPlayers)
        Log("\tNum Enemy Structures: %s", numEnemyStructures)
        Log("\tNum Friendly Players: %s", numFriendlyPlayers)
        Log("\tNum Friendly Structures: %s", numFriendlyStuctures)
    end

    if numEnemyPlayers <= 0 and numEnemyStructures <= 0 then return true end -- Each commander brain should handle looking for nearby friendlies
    if numEnemyPlayers > 0 or numEnemyStructures > 0 then return false end

    return numEnemyPlayers <= 0 and numEnemyStructures <= 0

end

function LocationGroup:GetIsSafeForHiveDrop(forTeam, isEarlyGame, ignoreFriends, debug)

    local numEnemyPlayers = #self:GetPlayersForTeamType(GetEnemyTeamNumber(forTeam))
    local numEnemyStructures = self:GetNumStructuresForTeamType(GetEnemyTeamNumber(forTeam))
    local numFriendlyPlayers = #self:GetPlayersForTeamType(forTeam)
    local numFriendlyStuctures = self:GetNumStructuresForTeamType(forTeam)

    if debug then
        Log("GetIsSafeForHiveDrop (%s)", self.groupName)
        Log("\tIgnore Friends: %s", ignoreFriends)
        Log("\tNum Enemy Players: %s", numEnemyPlayers)
        Log("\tNum Enemy Structures: %s", numEnemyStructures)
        Log("\tNum Friendly Players: %s", numFriendlyPlayers)
        Log("\tNum Friendly Structures: %s", numFriendlyStuctures)
    end

    return
        numEnemyPlayers <= 0 and
        not self:GetHasBuiltMarineStructures() and
        (
            ignoreFriends or
            numFriendlyPlayers > 0 or
            numFriendlyStuctures > 0
        )

end

local function Debug_PrintEntSets(uSet)

    local resultStr = ""
    for i = 1, #uSet do

        local entId = uSet[i]
        local ent = Shared.GetEntity(entId)
        resultStr = string.format("%s%s:%s", resultStr, entId, ToString(ent))

        if i ~= #uSet then
            resultStr = string.format("%s%s", resultStr, ", ")
        end

    end

    return resultStr

end

local kIgnoreConstructStructures = set
{
    "BabblerEgg",
}

local function GetIsEntityValidStructure(entity)
    return
        HasMixin(entity, "Construct") and
        not kIgnoreConstructStructures[entity:GetClassName()]
end

function LocationGroup:UpdateForEntity(changedEnt, added)

    local entity = changedEnt
    if not entity then return end -- should be assert?

    if entity:isa("ResourcePoint") then
        self:SetHasResNode(true)
    elseif entity:isa("TechPoint") then
        self:SetHasTechPoint(true)
    end

    local entityId = changedEnt:GetId()
    if not HasMixin(entity, "Team") then return end

    if entity:isa("Spectator") or entity:isa("Commander") then
        added = false
    end

    if added then

        local isPlayer = entity:isa("Player")
        local teamType = entity:GetTeamType()
        if teamType == kTeam1Type then
            if isPlayer then
                self.marinePlayers:Add(entityId)
            elseif GetIsEntityValidStructure(entity) then
                self.marineStructures:Add(entityId)
            end
        elseif teamType == kTeam2Type then
            if isPlayer then
                self.alienPlayers:Add(entityId)
            elseif GetIsEntityValidStructure(entity) then
                self.alienStructures:Add(entityId)
            end
        end

        if isPlayer then
            self:UpdateStaleForTeam(teamType)
        end

    else -- Removed, possible that it doesn't exist anymore.

        -- Might as well, feels dumb but its simpler/safer
        self.marineStructures:RemoveElement(entityId)
        self.marinePlayers:RemoveElement(entityId)
        self.alienStructures:RemoveElement(entityId)
        self.alienPlayers:RemoveElement(entityId)

    end

    self:UpdateContentionState()

    --Log("$ LocationGroup Changed (%s)", self.groupName)
    --Log("\tHas TechPoint: %s", self.hasTechPoint)
    --Log("\tHas Res Point: %s", self.hasResNode)
    --Log("\t#Marine Structures: %s", #self.marineStructures)
    --Log("\t\t%s", Debug_PrintEntSets(self.marineStructures))
    --Log("\t#Alien Structures:  %s", #self.alienStructures)
    --Log("\t\t%s", Debug_PrintEntSets(self.alienStructures))
    --Log("\t#Marine Players:  %s", #self.marinePlayers)
    --Log("\t\t%s", Debug_PrintEntSets(self.marinePlayers))
    --Log("\t#Alien Players:   %s", #self.alienPlayers)
    --Log("\t\t%s", Debug_PrintEntSets(self.alienPlayers))

end

---Updates the contention status of the locations with the given name.
---@param groupName string The name of the location(s) you want to update.
---@param changedEntId EntityId EntityId that was removed or added
---@param added boolean true if added, false if removed.
function LocationGroup:UpdateContentionState()

    local totalMarines = self:GetNumMarines()
    local totalAliens = self:GetNumAliens()

    local locationState = kLocationState.Neutral
    if totalMarines > 0 and totalAliens > 0 then
        locationState = kLocationState.Contested
    elseif totalMarines > 0 then
        locationState = kLocationState.Marine
    elseif totalAliens > 0 then
        locationState = kLocationState.Alien
    end

    self.contentionState = locationState

end

function LocationGroup:GetIsSafeForTeam(teamType)
    if teamType == kMarineTeamType then
        return self.contentionState == kLocationState.Neutral or self.contentionState == kLocationState.Marine
    elseif teamType == kAlienTeamType then
        return self.contentionState == kLocationState.Neutral or self.contentionState == kLocationState.Alien
    end
end

function LocationGroup:DebugDump()
    Log("\t%s:\n\t\t%d mp, %d ms, %d ap, %d as; tp: %s, rp: %s",
        self.groupName,
        #self.marinePlayers, #self.marineStructures,
        #self.alienPlayers, #self.alienStructures,
        self.hasTechPoint, self.hasResNode)
end
