------------------------------------------
--  Collection of useful, bot-specific utility functions
------------------------------------------

function SendResearchingChatMessage(bot, com, researchTechId)
    local researchTime = LookupTechData(researchTechId, kTechDataResearchTimeKey, 0)
    if researchTime and researchTime > 0 then

        local messageStr

        -- Biomass research starts out as three generic ones (each hive), then gets translated to it's 1-12 versions...
        if kBiomassResearchTechIds[researchTechId] then
            local team = com:GetTeam()
            local biomassResearchLevel = team and team:GetInProgressBiomassLevel() or GetResearchingBiomassLevel()
            if biomassResearchLevel <= 12 then
                messageStr = string.format("BOT_RESEARCH_START_BIOMASS_%s", ToString(biomassResearchLevel) or "NONAME")
            else
                -- We are already at 12 biomass, but want to research biomass at an existing hive for backup
                --messageStr = string.format("BOT_RESEARCH_START_BIOMASS_EXTRA")
            end
        else
            messageStr = string.format("BOT_RESEARCH_START_%s", string.upper(EnumToString(kTechId, researchTechId) or "NONAME"))
        end

        if messageStr then
            bot:SendTeamMessage(messageStr, 0.5, true, true)
        end
    end
end

function NotifyAlienBotCommanderOfTunnelDeath(tunnel)

    for _, comBot in ipairs(gCommanderBots) do
        if comBot.team == kTeam2Index and comBot.brain ~= nil then
            comBot.brain:SetTunnelDeathTime(tunnel)
        end
    end

end

function NotifyAlienBotCommanderOfStructureDeath(structure)

    if HasMixin(structure, "Team") and
            structure:GetTeamNumber() == kTeam2Index and
            structure.GetLocationName and
            not structure:isa("Player") then

        local structureLocationName = structure:GetLocationName()

        for _, comBot in ipairs(gCommanderBots) do
            if comBot.team == kTeam2Index and comBot.brain ~= nil and comBot.brain.timesLastStructureDeathByLocation and structureLocationName ~= "" then
                comBot.brain.timesLastStructureDeathByLocation[structureLocationName] = Shared.GetTime()
            end
        end

    end

end

-- Gets the "to-be" biomass level, including the currently researching biomass levels
function GetResearchingBiomassLevel()

    local totalBiomassLevel = 0
    local allHives = GetEntitiesForTeam("Hive", kTeam2Index)
    for _, hive in ipairs(allHives) do

        if hive:GetIsAlive() and hive:GetIsBuilt() then

            totalBiomassLevel = totalBiomassLevel + hive:GetBioMassLevel()

            local hiveResearchId = hive:GetResearchingId()
            if hiveResearchId and kBiomassResearchTechIds[hiveResearchId] then
                totalBiomassLevel = totalBiomassLevel + 1
            end

        end

    end

    return totalBiomassLevel

end

local kExploreTargetClassNameList =
{
    "TechPoint",
    "PowerPoint",
    "ResourcePoint"
}
function GetBotCanSeeExploreTarget(bot, targetPos)

    local botPlayer = bot:GetPlayer()
    if not botPlayer then return false end
    if not HasMixin(botPlayer, "CameraHolder") then return false end

    local traceStartPos = botPlayer:GetEyePos()

    local trace = Shared.TraceRay(traceStartPos, targetPos, CollisionRep.Default, PhysicsMask.ExploreTargets, EntityFilterAllButIsaList(kExploreTargetClassNameList))
    return trace.entity ~= nil

end

function GetBotWalkDistance(botPlayerOrPos, targetEntOrPos, targetLocationHint)
    PROFILE("GetBotWalkDistance")

    local botLocationName
    local botPos

    if botPlayerOrPos:isa("Vector") then -- This can fail inside tunnels
        local posLocation = GetLocationForPoint(botPlayerOrPos)
        botLocationName = posLocation and posLocation:GetName() or nil
        botPos = botPlayerOrPos
    elseif botPlayerOrPos:isa("ScriptActor") then
        botLocationName = botPlayerOrPos:GetLocationName()
        botPos = botPlayerOrPos:GetOrigin()
    else
        assert(false, "targetEntOrPos must be a Vector or ScriptActor!")
    end

    local targetPos
    local targetLocationName

    if targetEntOrPos:isa("Vector") then -- This can fail inside tunnels
        targetLocationName = targetLocationHint
        targetPos = targetEntOrPos
    elseif targetEntOrPos:isa("ScriptActor") then
        --McG: Note: if entity (i.e. player) is in _some_ vents, they won't be in a location. depends on the map
        targetLocationName = targetEntOrPos:GetLocationName()
        targetPos = targetEntOrPos:GetOrigin()
    elseif targetEntOrPos:isa("Entity") then
        targetLocationName = targetLocationHint
        targetPos = targetEntOrPos:GetOrigin()
    else
        assert(false, "targetEntOrPos must be a Vector, Entity, or ScriptActor!")
    end

    if not targetLocationName then
    --Determine the target's location if it is not provided by ScriptActor or explicit hint
        local posLocation = GetLocationForPoint(targetPos)
        targetLocationName = posLocation and posLocation:GetName() or nil
    end

    if  not botLocationName or botLocationName == "" or
        not targetLocationName or targetLocationName == "" then
        return botPos:GetDistance(targetPos)
    end

    -- Same location name, so gateway distance shouldn't apply
    if botLocationName == targetLocationName then
        return botPos:GetDistance(targetPos)
    end

    local gatewayDistTable = GetLocationGraph():GetGatewayDistance(botLocationName, targetLocationName)
    local gatewayDistance = gatewayDistTable.distance
    local enterGatePos = gatewayDistTable.enterGatePos -- the gateway pos on the starting location we used
    local exitGatePos = gatewayDistTable.exitGatePos -- the gateway pos on the end location we used

    -- Calculate distance using gateway distance, and two linear distances for bot->enter gateway, and exit gateway->targetEntPos
    local enterDist = (enterGatePos - botPos):GetLength()
    local exitDist = (targetPos - exitGatePos):GetLength()

    return enterDist + gatewayDistance + exitDist

end

function GetTunnelForPos(point)

    local tunnelEntities = GetEntitiesWithinRange("Tunnel", point, 40)
    if #tunnelEntities > 0 and tunnelEntities[1] then
        return tunnelEntities[1]
    else
        return nil
    end
end

------------------------------------------
--
------------------------------------------
function GetBestAimPoint( target )

    if target.GetEngagementPoint then

        return target:GetEngagementPoint()

    elseif HasMixin( target, "Model" ) then

        local min, max = target:GetModelExtents()
        local o = target:GetOrigin()
        return (min+max)*0.5 + o - Vector(0, 0.2, 0)

    else

        return target:GetOrigin()

    end

end

--BOT-FIXME This does not take orientation of target into account, thus why Marines interacting with Robo (weld) is so problematic!
function GetDistanceToTouch( fromEntOrPos, target )
    PROFILE("GetDistanceToTouch")

    local entSize = 0

    if HasMixin(target, "Extents") then
        entSize = target:GetExtents():GetLengthXZ()
    end

    local targetPos = target:GetOrigin()

    if HasMixin( target, "Target" ) then
        targetPos = target:GetEngagementPoint()
    end
    
    return math.max( 0.0, GetBotWalkDistance(fromEntOrPos, target) - entSize )

end

------------------------------------------
--
------------------------------------------
function GetNearestFiltered(from, ents, isValidFunc)
    PROFILE("GetNearestFiltered")

    local bestDist, bestEnt

    for _, ent in ipairs(ents) do

        if isValidFunc == nil or isValidFunc(ent) then

            local dist = GetDistanceToTouch( from, ent )
            if bestDist == nil or dist < bestDist then
                bestDist = dist
                bestEnt = ent
            end

        end

    end

    return bestDist, bestEnt

end

function GetMaxEnt(ents, valueFunc)

    local maxEnt, maxValue
    for _, ent in ipairs(ents) do
        local value = valueFunc(ent)
        if maxValue == nil or value > maxValue then
            maxEnt = ent
            maxValue = value
        end
    end

    return maxValue, maxEnt
end

function FilterTableEntries(ents, filterFunc)

    local result = {}
    for _, entry in ipairs(ents) do
        if filterFunc(entry) then
            table.insert(result, entry)
        end
    end
    
    return result
    
end

function GetMaxTableEntry(table, valueFunc)

    local maxEntry, maxValue
    for _, entry in ipairs(table) do
        local value = valueFunc(entry)
        if value == nil then
            -- skip this
        elseif maxValue == nil or value > maxValue then
            maxEntry = entry
            maxValue = value
        end
    end

    return maxValue, maxEntry
end

function GetMinTableEntry(table, valueFunc)

    local minEntry, minValue
    for _, entry in ipairs(table) do
        local value = valueFunc(entry)
        if value == nil then
            -- skip this
        elseif minValue == nil or value < minValue then
            minEntry = entry
            minValue = value
        end
    end

    return minValue, minEntry
end

------------------------------------------
--
------------------------------------------
function GetMinDistToEntities( fromEnt, toEnts )

    local minDist
    local fromPos = fromEnt:GetOrigin()

    for _, toEnt in ipairs(toEnts) do

        local dist = toEnt:GetOrigin():GetDistance( fromPos )
        if minDist == nil or dist < minDist then
            minDist = dist
        end

    end

    return minDist

end

------------------------------------------
--
------------------------------------------
local kDistCheckTimeIntervall = 3
function GetMinPathDistToEntities(fromEnt, toEnts)
    PROFILE("GetMinPathDistToEntities")

    local minDist
    local fromPos = fromEnt:GetOrigin()
    local fromEntId = fromEnt:GetId()
    local now = Shared.GetTime()

    if not fromEnt._pathDistances then
        fromEnt._pathDistances = {}
    end

    for i = 1, #toEnts do
        local toEnt = toEnts[i]
        local toEntId = toEnt:GetId()
        local dist = 0

        if not toEnt._pathDistances then
            toEnt._pathDistances = {}
        end

        if fromEnt._pathDistances[toEntId] and fromEnt._pathDistances[toEntId].validTill > now then
            --Log("Using cached fromEnt")
            dist = fromEnt._pathDistances[toEntId].dist
        elseif toEnt._pathDistances[fromEntId] and toEnt._pathDistances[fromEntId].validTill > now then
            --Log("Using cached toEnt")
            dist = toEnt._pathDistances[fromEntId].dist
        else
            --Log("Not using cache")
            -- Expensive !!!
            local path = PointArray()
            Pathing.GetPathPoints(fromPos, toEnt:GetOrigin(), path)
            dist = GetPointDistance(path)
            local distObj =  {
                dist = dist,
                validTill = now + kDistCheckTimeIntervall
            }
            fromEnt._pathDistances[toEntId] = distObj
            toEnt._pathDistances[fromEntId] = distObj
        end

        if not minDist or dist < minDist then
            minDist = dist
        end

    end

    return minDist

end


function FilterArray(ents, keepFunc)

    local out = {}
    for _, ent in ipairs(ents) do
        if keepFunc(ent) then
            table.insert(out, ent)
        end
    end
    return out

end

function GetPotentialTargetEntities(player)
    
    local origin = player:GetOrigin()
    local range = 20
    local teamNumber = GetEnemyTeamNumber(player:GetTeamNumber())
    
    local function filterFunction(entity)    
        return HasMixin(entity, "Team") and HasMixin(entity, "LOS") and HasMixin(entity, "Live")  and 
               entity:GetTeamNumber() == teamNumber and entity:GetIsSighted() and entity:GetIsAlive()     
    end
    return Shared.GetEntitiesWithTagInRange("class:ScriptActor", origin, range, filterFunction)
    
end

---@return TeamBrain.Memory[]
function GetTeamMemories(teamNum)

    local team = GetGamerules():GetTeam(teamNum)
    assert(team)
    assert(team.brain)
    return team.brain:GetMemories()

end

---@return TeamBrain
function GetTeamBrain(teamNum)

    local team = GetGamerules():GetTeam(teamNum)
    assert(team)
    return team:GetTeamBrain()

end

-- TEMP(Salads): AI - debug info for old entity id bug
local kDebugLastEntityClass = {}
local kDebugDefaultEntClass = "None"

function GetLastEntityClass(entId)
    return kDebugLastEntityClass[entId] or kDebugDefaultEntClass
end

function UpdateEntityForTeamBrains(entity, destroy)
    
    if not entity then return end
    local entId = entity:GetId()
    if destroy then
        GetTeamBrain(kTeam1Index):DeleteKnownEntity(entId)
        GetTeamBrain(kTeam2Index):DeleteKnownEntity(entId)
        kDebugLastEntityClass[entId] = kDebugDefaultEntClass
        return
    end

    if not HasMixin(entity, "MapBlip") then return end

    local teamNum = HasMixin(entity, "Team") and entity:GetTeamNumber() or kTeamInvalid
    local isMapEntity = entity:GetIsMapEntity()
    if not (isMapEntity or teamNum == kTeam1Index or teamNum == kTeam2Index) then return end

    if isMapEntity then
        GetTeamBrain(kTeam1Index):AddKnownEntity(entId)
        GetTeamBrain(kTeam2Index):AddKnownEntity(entId)
        kDebugLastEntityClass[entId] = entity:GetClassName()
    else
        local entTeamIndex = entity:GetTeamNumber()
        local enemyTeamIndex = GetEnemyTeamNumber(entTeamIndex)

        -- Entities should be known to their own team under any condition.
        GetTeamBrain(entTeamIndex):AddKnownEntity(entId)
        kDebugLastEntityClass[entId] = entity:GetClassName()

        local shouldEnemyTeamKnow =
            (HasMixin(entity, "LOS") and entity:GetIsSighted()) or
            (HasMixin(entity, "ParasiteAble") and entity:GetIsParasited())

        if shouldEnemyTeamKnow then
            GetTeamBrain(enemyTeamIndex):AddKnownEntity(entId)
        else
            GetTeamBrain(enemyTeamIndex):RemoveKnownEntity(entId)
        end
    end

end

------------------------------------------
--  This is expensive.
--  It would be nice to piggy back off of LOSMixin, but that is delayed and also does not remember WHO can see what.
--  -- Fixed some bad logic.  Now, we simply look to see if the trace point is further away than the target, and if so,
--  It's a hit.  Previous logic seemed to assume that if the target itself wasn't hit (caused by the EngagementPoint not
--  being inside a collision solid -- the skulk for example moves around a lot) then it magically wasn't there anymore.
------------------------------------------
function GetBotCanSeeTarget(attacker, target)

    local p0 = attacker:GetEyePos()
    local p1 = target:GetEngagementPoint()
    local bias = 1.5 * 1.5 -- allow trace entity to be this far off and still say close enough

    local trace = Shared.TraceCapsule( p0, p1, 0.15, 0,
            CollisionRep.Damage, PhysicsMask.Bullets,
            EntityFilterTwo(attacker, attacker:GetActiveWeapon()) )
    --return trace.entity == target
    return trace.fraction == 1 or
            (trace.entity == target) or
            (trace.entity and trace.entity.GetTeamNumber and target.GetTeamNumber and (trace.entity:GetTeamNumber() == target:GetTeamNumber())) or
            ((trace.endPoint - p1):GetLengthSquared() <= bias)

end

function IsAimingAt(attacker, target)

    local toTarget = GetNormalizedVector(target:GetEngagementPoint() - attacker:GetEyePos())
    return toTarget:DotProduct(attacker:GetViewCoords().zAxis) > 0.99

end

------------------------------------------
--
------------------------------------------
function FilterTable( dict, keepFunc )
    local out = {}
    for _,val in ipairs(dict) do
        if keepFunc(val) then
            table.insert(out, val)
        end
    end
    return out
end

------------------------------------------
--
------------------------------------------
function GetNumEntitiesOfType( className, teamNumber )
    local ents = GetEntitiesForTeam( className, teamNumber )
    return #ents
end

------------------------------------------
--
------------------------------------------
function GetAvailableTechPoints()

    local tps = {}
    for _,tp in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do

        if not tp:GetAttached() then
            table.insert( tps, tp )
        end

    end

    return tps

end

function GetAvailableResourcePoints()

    local rps = {}
    for _,rp in ientitylist(Shared.GetEntitiesWithClassname("ResourcePoint")) do

        if not rp:GetAttached() then
            table.insert( rps, rp )
        end

    end

    return rps

end

function GetServerContainsBots()

    local hasBots = false
    local players = Shared.GetEntitiesWithClassname("Player")
    for p = 0, players:GetSize() - 1 do
    
		local player = players:GetEntityAtIndex(p)
        local ownerClient = player and Server.GetOwner(player)
        if ownerClient and ownerClient:GetIsVirtual() then
        
            hasBots = true
            break
            
        end
        
    end
    
    return hasBots
    
end


--Read ahead 'steps' and compare the slope backwards, return avg-slope (+ is UP, - is DOWN)
function GetPathSlope(pathPoints, activeIdx, steps, startOrgY)
    assert(pathPoints)
    assert(activeIdx)
    assert(steps)

    if steps + activeIdx > #pathPoints then
    --auto-clamp so we don't need to deal with nil
    --BUT, in this scenario, it means our return is not that useful
        steps = #pathPoints
    end

    local heightSlopeSum = startOrgY
    local tick = 1
    local lookAheadDelta = {}
    for i = activeIdx, #pathPoints do

        --account for pathable spaces always being above world origin
        heightSlopeSum = (pathPoints[i].y < startOrgY) and 
            heightSlopeSum - pathPoints[i].y or 
            heightSlopeSum + pathPoints[i].y

        table.insert(lookAheadDelta, pathPoints[i].y)

        tick = tick + 1
        if tick >= steps then
            break
        end
    end

    return heightSlopeSum, table.mean(lookAheadDelta)
end

function GetPathHeightMean( pathPoints, activeIdx, steps )
    assert(pathPoints)
    assert(activeIdx)
    assert(steps)

    if steps + activeIdx > #pathPoints then
    --auto-clamp so we don't need to deal with nil
    --BUT, in this scenario, it means our return is not that useful
        steps = #pathPoints
    end

    local heightSlopeSum = startOrgY
    local tick = 1
    local lookAheadDelta = {}
    for i = activeIdx, #pathPoints do
        table.insert(lookAheadDelta, pathPoints[i].y)

        tick = tick + 1
        if tick >= steps then
            break
        end
    end
    
    return table.mean(lookAheadDelta)
end


local kBotPlayerFovLookup =   --values defined in BalanceMisc.lua
{
    ["Marine"] = kDefaultFov,
    ["JetpackMarine"] = kDefaultFov,
    ["Exo"] = kExoFov,
    ["Skulk"] = kSkulkFov,
    ["Gorge"] = kGorgeFov,
    ["Lerk"] = kLerkFov,
    ["Fade"] = kFadeFov,
    ["Onos"] = kOnosFov
}

--defined as global because this is useful for all Bot-types
function GetClassDefaultFov(entClass)
    if not kBotPlayerFovLookup[entClass] then
        return kDefaultFov
    end
    return kBotPlayerFovLookup[entClass]
end



-------------------------------------------------------------------------------
--  DEV / DEBUG Tools
--
--

if Server then

Event.Hook("Console_bot_setupdev", function()

    Shared.ConsoleCommand("tests 1")
    Shared.ConsoleCommand("cheats 1")
    Shared.ConsoleCommand("autobuild")

end)

end

--
-------------------------------------------------------------------------------