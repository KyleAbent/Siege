-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. ============
--
-- lua\TournamentMode.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--    Modified By:  Brock Gillespie (brock@naturalselection2.com)
--
-- Process chat commands when tournament mode is enabled.
--
-- (McG) This the bottom section of this file has nothing to do with Thunderdome. It was added much earlier to it.
-- And, unfortunately, is now used by some mods. Thus, it's left for compatibility. All TD related code is in the
-- top part of this file.
-- ========= For more information, visit us at http://www.unknownworlds.com =======================


Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")
Script.Load("lua/thunderdome/ThunderdomeRules.lua")


---------------------------------------
-- Map Loading / Modifying

local kTeleportEntityClassName = "teleport_trigger"
local kTeleportDestinationEntityClassName = "teleport_destination"

--List of props to remove
local kThunderdomeRemovePropsList = 
{
    "models/props/generic/join_spec.model",
    "models/props/generic/join_alien.model",
    "models/props/generic/join_marine.model",
    "models/props/generic/join_random.model",
    "models/props/generic/random_join.model",
    "models/props/generic/spectate_join.model",
    "models/props/generic/join_text_01.model",
    "models/props/generic/join_text_05.model",
    "models/props/generic/alien_join.model",
    "models/props/generic/marine_join.model",
}

--List of entity map-names which should be tested for "removal" when TD-mode active
local kThunderdomeRemoveEntityTestList = { "prop_static" }
local kThunderdomeSwapEntityTestList = { "team_join" }
local kThunderdomeReadEntityTestList = { "ns2_gamerules" }

local gameRulesCoords = nil

local kTeleporterDestinationIds =       --TD-TODO Review / Revise for TD
{
    [kThunderdomeMaps.ns2_mineshaft] = 1928471234,  --TD-FIXME Make this a defined constant (table with X elements)
    [kThunderdomeMaps.ns2_refinery] = 1929871234,
    [kThunderdomeMaps.ns2_tram] = 1929871234,
}

local kThunderdomeMapForceFields = 
{
    [kThunderdomeMaps.ns2_refinery] = 
    {
        type = "forcefield",
        origin = Vector(0.02, -19.62, -172.36),
        scale = Vector(17.46, 0.12, 12.38),
    },
}

local kThunderdomeMapTeleportDestinations =     --TD-TODO Review once Tanith is "fully added" to build
{
    [kThunderdomeMaps.ns2_mineshaft] = 
    {
        type = "teleport_destination",
        origin = Vector(34.29, 169.36, 254.51),
        teleportDestinationId = kTeleporterDestinationIds[kThunderdomeMaps.ns2_mineshaft],
    },
    [kThunderdomeMaps.ns2_refinery] = 
    {
        type = "teleport_destination",
        origin = Vector(-14.41, -16.15, -195),
        teleportDestinationId = kTeleporterDestinationIds[kThunderdomeMaps.ns2_refinery],
    },
    [kThunderdomeMaps.ns2_tram] = 
    {
        type = "teleport_destination",
        origin = Vector(-136.1, 22.46, -58.93),
        teleportDestinationId = kTeleporterDestinationIds[kThunderdomeMaps.ns2_tram],
    },
}

local kTemplateTeleportTrigger = 
{
    origin = "0, 0, 0",
    teleportDestinationId = 0,
    scale = "0, 0, 0",
    name = ""
}

local kThunderdomeMapTriggerSwapMap = 
{
    [kThunderdomeMaps.ns2_mineshaft] = { type = "team_join", team = 0 },    --Spectate
    [kThunderdomeMaps.ns2_refinery] = { type = "team_join", team = 3 },     --Random
    [kThunderdomeMaps.ns2_tram] = { type = "team_join", team = 3 },         --Random
}


function GetThunderdomeInjectEntities()
    Log("GetThunderdomeInjectEntities()")

    local entList = {}
    if not Shared.GetThunderdomeEnabled() then
        return entList
    end

    local mapKey = kThunderdomeMaps[Shared.GetMapName()]

    --TODO revise to allow for multiple entity entries (table of defs)

    if kThunderdomeMapTeleportDestinations[mapKey] ~= nil then
        Log("Have matching map-name for Teleport Destination entity injection...")

        local destination = kThunderdomeMapTeleportDestinations[mapKey]
        Log("\t destination: %s", destination)
        table.insert( entList, 
            { 
                class = kTeleportDestinationEntityClassName, 
                props = 
                { 
                    origin = destination.origin,
                    teleportDestinationId = kTeleporterDestinationIds[mapKey],
                    __editorData = {}
                } 
            } 
        )
    end

    --[[    -Removed until needed, as this was a one-off
    if kThunderdomeMapForceFields[mapKey] ~= nil then
        Log("Have matching map-name for Forcefield entity injection...")
        local forceField = kThunderdomeMapForceFields[mapKey]
        Log("\t forcefield: %s", forceField)
        table.insert( entList, 
            { 
                class = forceField.type, 
                props = 
                { 
                    origin = forceField.origin,
                    scale = forceField.scale,
                    __editorData = {}
                } 
            } 
        )
    end
    --]]

    --Always add TDRules last
    local tdRules = 
    {
        class = "thunderdome_rules",
        props = 
        {
            origin = gameRulesCoords,
            __editorData = {}
        }
    }
    table.insert( entList, tdRules )

    return entList
end

--Utility to parse and change and entity map-data at map load time
--Note: annoyingly, each entity "type" needs its own conversion routine
function ThunderdomeEntitySwap( className, values )
    assert(className)
    
    if not Shared.GetThunderdomeEnabled() then
        return className, values
    end

    if table.icontains( kThunderdomeSwapEntityTestList, className ) then
    --this entity needs to be changed into another type
        Log("ThunderdomeEntitySwap( %s, %s )", className, values)
        Log("Have matching type for entity swap...")

        local mapKey = kThunderdomeMaps[Shared.GetMapName()]
        Log("\t mapKey: %s[%s]", kThunderdomeMaps[mapKey], mapKey)
        local triggerSwapAsTeleport = 
            kThunderdomeMapTriggerSwapMap[mapKey]

        Log("\t triggerSwapAsTeleport: %s", triggerSwapAsTeleport)

        --Only swap specific team_join triggers for specific maps, not all maps require entity swaps
        if triggerSwapAsTeleport ~= nil and values.teamNumber == triggerSwapAsTeleport.team then

            local newVals = kTemplateTeleportTrigger
            newVals.origin = values.origin
            newVals.scale = values.scale
            newVals.name = values.name
            newVals.teleportDestinationId = kTeleporterDestinationIds[mapKey]
            newVals.__editorData = {}

            Log("Swapped Entity Type[%s] with '%s'", className, kTeleportEntityClassName)
            Log("\t Old Data: %s", values)
            Log("\t New Data: %s", newVals)

            return kTeleportEntityClassName, newVals
        end

    end

    if table.icontains( kThunderdomeReadEntityTestList, className ) then
    --cache Gamerule coordinates for TDRules object injection
        Log("\t Copied NS2GameRules coordinates for ThunderdomeRules placement...")
        gameRulesCoords = values.origin
    end

    return className, values
end

function ThunderdomeEntityRemove( className, values )

    if not Shared.GetThunderdomeEnabled() then
        return false
    end

    if table.icontains( kThunderdomeRemoveEntityTestList, className ) then

        if className == "prop_static" then
            return table.icontains( kThunderdomeRemovePropsList, values.model )
        
        elseif className == "team_join" then

            local teamJoinTeleportSwap = 
                kThunderdomeMapTriggerSwapMap[ kThunderdomeMaps[ Shared.GetMapName() ] ]

            if teamJoinTeleportSwap ~= nil and teamJoinTeleportSwap.team == values.team then
            --skip over team join triggers that need to be changed into another entity
                return false
            end

            return true

        end

    end

    return false
end


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--
-- Old Tournament Mode code - Left here for legacy support and/or mods that use it
--
---------------------------------------------------------------------------------------------------

local gTournamentModeEnabled = false
local gReadyTeams = {}


function EnableTournamentMode(client)

    if not gTournamentModeEnabled then
        GetGamerules():OnTournamentModeEnabled()
        ServerAdminPrint(client, "Tournament mode enabled.")
        Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, kTeamReadyRoom, kNeutralTeamType, "Tournament mode enabled."), true)
    end

    gTournamentModeEnabled = true
    
end

function DisableTournamentMode(client)

    if gTournamentModeEnabled then
        GetGamerules():OnTournamentModeDisabled()
        ServerAdminPrint(client, "Tournament mode disabled.")
        Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, kTeamReadyRoom, kNeutralTeamType, "Tournament mode disabled."), true)
    end

    gTournamentModeEnabled = false
    
end

function GetTournamentModeEnabled()
    return gTournamentModeEnabled
end

function TournamentModeOnGameEnd()
    gReadyTeams = {}
end

function TournamentModeOnReset()
    gReadyTeams = {}
end

local function CheckReadyness()

    if gReadyTeams[kTeam1Index] and gReadyTeams[kTeam2Index] then
        GetGamerules():SetTeamsReady(true)
        Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, kTeamReadyRoom, kNeutralTeamType, "Both teams ready."), true)
    else
        GetGamerules():SetTeamsReady(false)
    end

end

local function SetTeamReady(player)

    local teamNumber = player:GetTeamNumber()
    gReadyTeams[teamNumber] = true
    CheckReadyness()
    
end

local function SetTeamNotReady(player)

    local teamNumber = player:GetTeamNumber()
    gReadyTeams[teamNumber] = false
    CheckReadyness()
    
end

local function SetTeamPauseDesired(player)
    --GetGamerules():SetPaused()
end

local function SetTeamPauseNotDesired()
     --GetGamerules():DisablePause()
end

local kSayCommands =
{
    ["ready"] = SetTeamReady,
    ["rdy"] = SetTeamReady,
    ["unready"] = SetTeamNotReady,
    ["unrdy"] = SetTeamNotReady,
    ["pause"] = SetTeamPauseDesired,
    ["unpause"] = SetTeamPauseNotDesired
}

function ProcessSayCommand(player, command)

    if gTournamentModeEnabled then

        for validCommand, func in pairs(kSayCommands) do
        
            if validCommand == string.lower(command) then
                func(player)
            end
        
        end
    
    end

end