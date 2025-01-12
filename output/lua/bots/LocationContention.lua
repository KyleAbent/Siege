-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/LocationContention.lua
--
-- Created by: Darrell Gentry (darrell@unkownworlds.com)
--
-- Keeps track of locations by name, and updates the group's location state.
-- Location state is it's contention status
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

assert(Server, "LocationContention.lua must only be loaded on Server!")

Script.Load("lua/bots/LocationGroup.lua")
Script.Load("lua/IterableDict.lua")

local kLocationContention = nil
function GetLocationContention()
    if not kLocationContention then
        kLocationContention = LocationContention()
        kLocationContention:Initialize()
    end

    return kLocationContention
end

---@class LocationContention
---@see kLocationState
class "LocationContention"

function LocationContention:Initialize()

    -- Initialize Locations, keyed by name
    self.locationGroupsByName = IterableDict()

    local locations = GetLocations()
    for _, location in ipairs(locations) do
        local name = location:GetName()
        self:AddLocationGroup(name)
    end

end

function LocationContention:GetIsLocationFullyFeaturedTechRoom(locationName)
    local locGroup = self.locationGroupsByName[locationName]
    if not locGroup then return false end

    return locGroup:GetIsFullyFeaturedTechRoom()
end

function LocationContention:AddLocationGroup(locationGroupName)
    if not self.locationGroupsByName[locationGroupName] then
        self.locationGroupsByName[locationGroupName] = CreateLocationGroup(locationGroupName)
    end
end

function LocationContention:ResetAllGroups()
    for groupName, locationGroup in pairs(self.locationGroupsByName) do
        locationGroup:Reset()
    end
end

function LocationContention:ResetAllGroupsStaleness()
    for groupName, locationGroup in pairs(self.locationGroupsByName) do
        locationGroup:ResetStaleness()
    end
end

function LocationContention:GetLocationGroup(groupName)
    local locationGroup = self.locationGroupsByName[groupName]
    return locationGroup
end

function LocationContention:GetGroupHasTechPoint(groupName)
    local locationGroup = self.locationGroupsByName[groupName]
    assert(locationGroup, "Location Group does not exist!")
    return locationGroup.hasTechPoint
end

function LocationContention:GetGroupHasResNode(groupName)
    local locationGroup = self.locationGroupsByName[groupName]
    assert(locationGroup, "Location Group does not exist!")
    return locationGroup.hasResNode
end


Event.Hook("Console_dump_locgroups", function()
    Log("Location Groups:")
    for groupName, locationGroup in pairs(GetLocationContention().locationGroupsByName) do
        locationGroup:DebugDump()
    end
end)
