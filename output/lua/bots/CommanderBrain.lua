------------------------------------------
--
------------------------------------------

Script.Load("lua/bots/PlayerBrain.lua")

local gDebug = false

------------------------------------------
--  Utility funcs
------------------------------------------
function GetRandomBuildPosition(techId, aroundPos, maxDist)     --TODO Review & Revise, this needs a TON of work and per-type specificity

    local extents = GetExtents(techId)
    local validationFunc = LookupTechData(techId, kTechDataRequiresInfestation, nil) and GetIsPointOnInfestation or nil
    local randPos = GetRandomSpawnForCapsule(extents.y, extents.x, aroundPos, 0.01, maxDist, EntityFilterAll(), validationFunc)
    return randPos

end

------------------------------------------
--
------------------------------------------
class 'CommanderBrain' (PlayerBrain)

CommanderBrain.kActionDelay = 0.5

function CommanderBrain:Initialize()
    PlayerBrain.Initialize(self)
end

function CommanderBrain:GetShouldDebug(bot)
    --return true
    return gDebug
end

function CommanderBrain:GetStartingTechPoint()
    if self.teamBrain then
        return self.teamBrain.initialTechPointLoc
    end
end

function CommanderBrain:GetStartingLocationId()
    local startLocationName = self:GetStartingTechPoint()
    if not startLocationName then return 0 end

    return Shared.GetStringIndex(startLocationName)
end

function CommanderBrain:GetExpectedPlayerClass()
    return "Player"
end

function CommanderBrain:GetIsSafeToDropInLocation(locationName, forTeamNum, isEarlyGame, debug)

    if not locationName or locationName == "" then return false end

    local locationGroup = GetLocationContention():GetLocationGroup(locationName)
    return locationGroup:GetIsSafeForStructureDrop(forTeamNum, isEarlyGame, debug)

end

function CommanderBrain:GetIsSafeToDropHiveInLocation(locationName, forTeamNum, isEarlyGame, ignoreFriends, debug)

    if not locationName or locationName == "" then return false end

    local locationGroup = GetLocationContention():GetLocationGroup(locationName)
    return locationGroup:GetIsSafeForHiveDrop(forTeamNum, isEarlyGame, ignoreFriends, debug)

end


local function GetIsActionButton(techNode)

    return not techNode:GetIsPassive()
            and not techNode:GetIsMenu()

end

------------------------------------------
--  This enumerates EVERYTHING that the commander can do right now - EVERYTHING
--  The result is a hash table with techId as keys and an array of units as values. These are the units that you can perform the tech on (it may just be com)
------------------------------------------
function CommanderBrain:GetDoableTechIds(com)
    PROFILE("CommanderBrain:GetDoableTechIds")

    local teamNum = com:GetTeamNumber()
    local tree = GetTechTree(teamNum)

    local doables = {}

    -- Todo: Get rid of closures
    local function HandleUnitActionButton(unit, techNode)

        assert( techNode ~= nil )
        assert( GetIsActionButton(techNode) )
        local techId = techNode:GetTechId()

        if techNode:GetAvailable() then

            -- check cool down
            if com:GetIsTechOnCooldown(techId) then
                return
            end

            local allowed, canAfford = unit:GetTechAllowed( techId, techNode, com )

            if self.debug then
                Print("%s-%d.%s = %s (%s^%s)",
                        unit:GetClassName(),
                        unit:GetId(),
                        EnumToString(kTechId, techId),
                        ToString( allowed and canAfford ),
                        ToString(allowed),
                        ToString(canAfford) )
            end

            if allowed and canAfford then
                if doables[techId] == nil then
                    doables[techId] = {}
                end
                table.insert( doables[techId], unit )
            end

        end

    end

    ------------------------------------------
    -- Go through all units, gather all the things we can do with them
    ------------------------------------------

    local function CollectUnitDoableTechIds( unit, menuTechId, doables, visitedMenus )

        -- Very important. Menus are naturally cyclic, since there is always a "back" button
        visitedMenus[menuTechId] = true

        local techIds = unit:GetTechButtons( menuTechId ) or {}

        for _, techId in ipairs(techIds) do

            if techId ~= kTechId.None then

                local techNode = tree:GetTechNode(techId)
                if techNode ~= nil then

                    if techNode:GetIsMenu() and visitedMenus[techId] == nil then
                        CollectUnitDoableTechIds( unit, techId, doables, visitedMenus )
                    elseif GetIsActionButton(techNode) then
                        HandleUnitActionButton( unit, techNode )
                    end

                end
            end
        end

    end

    for _, unit in ipairs(GetEntitiesForTeam("ScriptActor", teamNum)) do
        CollectUnitDoableTechIds( unit, kTechId.RootMenu, doables, {} )
    end

    ------------------------------------------
    --  Now do commander buttons. They are all in a two-level table, so no need to recurse.
    ------------------------------------------

    local buttonTable = com:GetButtonTable()
    -- Now do commander buttons - all of them
    for _,menuId in ipairs( com:GetMenuIds() ) do

        local menu = buttonTable[menuId]
        for _,techId in ipairs(menu) do

            if techId ~= kTechId.None then

                local techNode = tree:GetTechNode(techId)
                if techNode ~= nil then

                    if GetIsActionButton(techNode) then
                        HandleUnitActionButton( com, techNode )
                    end

                end
            end
        end
    end

    return doables

end

local kBuildTunnelTechIds = 
{
    kTechId.BuildTunnelEntryOne, kTechId.BuildTunnelEntryTwo, kTechId.BuildTunnelEntryThree, kTechId.BuildTunnelEntryFour,
    kTechId.BuildTunnelExitOne, kTechId.BuildTunnelExitTwo, kTechId.BuildTunnelExitThree, kTechId.BuildTunnelExitFour
}

local function GetIsBuildTunnelTech(techId)
    return table.icontains(kBuildTunnelTechIds, techId)
end

------------------------------------------
--  Helper function for subclasses
------------------------------------------
function CommanderBrain:ExecuteTechId( commander, techId, position, hostEntity, targetId, trace)
    PROFILE("CommanderBrain:ExecuteTechId")

    --DebugPrint("Combrain executing %s at %s on %s", EnumToString(kTechId, techId),
    --ToString(position),
    --hostEntity == nil and "<no target>" or hostEntity:GetClassName())

    local techNode = commander:GetTechTree():GetTechNode( techId )

    local allowed, canAfford = hostEntity:GetTechAllowed( techId, techNode, commander )
    if not ( allowed and canAfford ) then return end

    -- We should probably use ProcessTechTreeAction instead here...
    commander.isBotRequestedAction = true -- Hackapalooza...
    local success, keepGoing
    if techId == kTechId.Cyst or GetIsBuildTunnelTech(techId) then
        commander:ProcessTechTreeAction(
                techId,
                position,
                0,  -- orientation?
                position
        )
    else
        success, keepGoing = commander:ProcessTechTreeActionForEntity(
                techNode,
                position,
                Vector(0,1,0),  -- normal
                true,   -- isCommanderPicked
                0,  -- orientation
                hostEntity,
                trace, -- trace
                targetId
        )
    end
    if success then

        -- set cooldown
        local cooldown = LookupTechData(techId, kTechDataCooldown, 0)
        if cooldown ~= 0 then
            commander:SetTechCooldown(techId, cooldown, Shared.GetTime())
        end

    else
        DebugPrint("COM BOT ERROR: Failed to perform action %s", EnumToString(kTechId, techId))
    end

    return success
end

------------------------------------------
--
------------------------------------------
Event.Hook("Console_bot_com",
    function()
        gDebug = not gDebug
        Print("CommanderBrain debug = %s", ToString(gDebug))
    end)
