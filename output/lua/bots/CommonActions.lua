Script.Load("lua/bots/BotUtils.lua")

local kLocationVisitTimeout = 60

--Do nothing action returned if an action is invalid to take at this time
kNilAction = {
    name = "no action",
    weight = 0.0,
    perform = function(move) end
}

-- Utility methods
local kMapOrigin = Vector(0,0,0)
function GetIsAreaSafe(teamNumber, origin, radius)

    local memories = GetTeamMemories( teamNumber )
    for _,mem in ipairs(memories) do
        local target = Shared.GetEntity(mem.entId)
        if target and target:isa("Player") and teamNumber ~= target:GetTeamNumber() and HasMixin(target, "Live") and target:GetIsAlive() then

            local dist = origin:GetDistance( mem.lastSeenPos )

            -- hack because some memories are at the origin of the map...
            if dist < radius and kMapOrigin:GetDistance( mem.lastSeenPos ) > 5 then
                return false
            end

        end
    end
    return true

end

function GetGameMinutesPassed()
    return (Shared.GetTime() - GetGamerules():GetGameStartTime()) / 60.0
end

function GetNumHives()
    return GetNumEntitiesOfType("Hive", kTeam2Index)
end

------------------------------------------
-- Helper 'Move' functions
------------------------------------------

-- Randomly look at points around the given target
-- Expects targetPos to be a point on pathing/floor
function LookAroundAtTarget( bot, player, targetPos )

    if not bot.lastLookAround or bot.lastLookAround + 2 < Shared.GetTime() then

        bot.lastLookAround = Shared.GetTime()

        local viewTarget = GetRandomDirXZ()
        -- viewTarget:Normalize()
        viewTarget:Scale((player:GetOrigin() - targetPos):GetLength() / 10.0)
        viewTarget.y = math.random(0.4, 1.65)

        bot.lastLookTarget = targetPos + viewTarget

    end

    if bot.lastLookTarget then
        bot:GetMotion():SetDesiredViewTarget(bot.lastLookTarget)
    end

end

function LookAroundRandomly( bot, player )

    if not bot.lastLookAround or bot.lastLookAround + 2 < Shared.GetTime() then

        bot.lastLookAround = Shared.GetTime()

        local viewTarget = GetRandomDirXZ()
        viewTarget.y = math.random(0.4, 0.65)
        viewTarget:Normalize()

        bot.lastLookTarget = player:GetEyePos() + viewTarget * 30

    end

    if bot.lastLookTarget then
        bot:GetMotion():SetDesiredViewTarget(bot.lastLookTarget)
    end

end

--Utility to find a position behind the passed in 'target', 'marine' should be a Marine bot
function GetPositionBehindTarget( player, target, optDesiredDist ) 

    if not HasMixin(target, "Live") or not target.GetViewAngles then
    --we only operate on things that are valid for this usage (e.g. not points in space)
        return nil
    end

    --??? Add check for a class-list that is a "facing" valid, otherwise fail-out to random point in radius?
    local targetViewAxis = target:GetViewAngles():GetCoords().zAxis
    local isTargetInPlayerView = IsPointInCone( 
        player:GetOrigin(), 
        target:GetEyePos(), 
        targetViewAxis, 
        math.rad(GetClassDefaultFov(target:GetClassName())) 
    )

    if isTargetInPlayerView then
    -- we are in front, find out back positon
        
        local obstacleSize = 0
        if HasMixin(target, "Extents") then
            obstacleSize = target:GetExtents():GetLengthXZ()
        end

        local desiredDist = optDesiredDist ~= nil and optDesiredDist or kDefaultMarineEnagementRange

        -- we do not want to go straight through the player, instead we move behind and to the
        -- left or right
        local targetPos = target:GetOrigin()
        
        local toMidPos = targetViewAxis * (obstacleSize + desiredDist - 0.1)
        local midPos = targetPos - targetViewAxis * (obstacleSize + desiredDist - 0.4)
        local leftV = Vector(-targetViewAxis.z, targetViewAxis.y, targetViewAxis.x)
        local rightV = Vector(targetViewAxis.z, targetViewAxis.y, -targetViewAxis.x)
        local leftPos = midPos + leftV * desiredDist
        local rightPos = midPos + rightV * desiredDist

        local origin = player:GetOrigin()

        local behindPos = 
            (origin - leftPos):GetLengthSquared() < (origin - rightPos):GetLengthSquared() and
            leftPos or 
            rightPos

        return Pathing.GetClosestPoint(behindPos)
    end

    return target:GetEngagementPoint()        
end

------------------------------------------
-- Objective Weight Evaluator functions
------------------------------------------

local function GetBotActionWeight(self, actionId)
    local types = self.actionTypes
    local scale = self.actionScale

    assert(types[types[actionId]], "Error: Invalid action-id passed")

    local totalActions = #types
    local actionOrderId = types[types[actionId]] --numeric index, not string

    --invert numeric index value and scale, the results in lower value, the higher the index. Which means
    --the Enum of actions is shown and used in a natural order (i.e. order of enum value declaration IS the priority)
    local actionWeightOrder = totalActions - (actionOrderId - 1)

    --name, final action base-line weight value
    return actionWeightOrder * scale
end

local function GetBotActionInfo(self, actionId)
    return self.actionTypes[actionId], GetBotActionWeight(self, actionId)
end

function MakeBotActionWeights(actionTypes, actionScale)
    return {
        Get = GetBotActionInfo,
        GetWeight = GetBotActionWeight,
        actionTypes = actionTypes,
        actionScale = actionScale
    }
end

------------------------------------------
--  Collection of common actions shared between many brains
------------------------------------------

local function GetBotsExploreTargets(selfBot, teamNumber)
    local totals = {}

    local teamBots = GetTeamBrain(teamNumber).teamBots

    for i = 1, #teamBots do
        local brain = teamBots[i].brain

        if teamBots[i] ~= selfBot and brain and brain.exploreTarget then
            totals[brain.exploreTarget] = (totals[brain.exploreTarget] or 0) + 1
        end
    end

    return totals
end

--TODO Utilize Location centroid and possible explore-to points
--!!!!!HUGE-BOT-FIXME  ...Bots **MUST** react to hostile targets when exploring...they'll run RIGHT past hostile structures without hesitation, and go to explore goal, stupid.
--BOT-FIXME Need to make sure this NEVER sets an Explore goal for our base. Why would we do that? Can't think of a good reason to do so...
function CreateExploreAction( weightIfTargetAcquired, moveToFunction )  --TODO Add type constraints/goal-filters (e.g. Resnode only, or technode only, location-centroids, no tech/res nodes, etc.)

    local function hasExploredTarget(bot, brain, player)

        local locGroup = GetLocationContention():GetLocationGroup(brain.exploreTarget)
        local isTargetLocationStrategic = locGroup and locGroup:GetHasStrategicEnts()

        -- If location group has nothing we need to "check" (Techpoints/Resnodes), we're done once we enter the room
        -- if not isTargetLocationStrategic then
        do
            -- NOTE: this is required to ensure equivalent behavior with non-Objective explore actions
            return player:GetLocationName() == brain.exploreTarget
        end
        -- end

        local dist = GetBotWalkDistance(player, brain.exploreTargetPos, brain.exploreTarget)
        return (dist <= 10) and GetBotCanSeeExploreTarget(bot, brain.exploreTargetPos)

    end

    local function execExploreAction(move, bot, brain, player, action)

        if brain.debug then
            DebugPrint("exploring to move target %s", ToString(brain.exploreTargetPos))
        end

        if brain.exploreTargetPos ~= nil then
            moveToFunction( player:GetOrigin(), brain.exploreTargetPos, bot, brain, move )
        end

        if hasExploredTarget(bot, brain, player) then
            return kPlayerObjectiveComplete
        end

    end

    return function(bot, brain, player)
        PROFILE("CommonBot - Explore")

        local name = "explore"
        local currentLocationName = player:GetLocationName()

        -- if we have absolutely no start location at all (e.g. exo brains sometimes)
        -- fall back to reinitializing the start location from the closest TP
        if not player.startLocation and not bot.startLocation then

            SetPlayerStartingLocation(player)

        end

        -- If start location changed (respawned, joined team, reset, etc)
        -- then make sure bot's field is updated as well.
        -- Used for when a bot might buy a Jetpack, which replaces the
        -- class instance so the field would be cleared. (especially in a weird place like Hub)
        if player.startLocationChanged then

            brain:AddVisitedLocation(player.startLocation)
            bot.startLocation = player.startLocation
            -- Force a regen of explore target, it could be invalid at this point. (Reset game)
            brain.exploreTargetPos = nil
            brain.exploreTarget = nil
            player.startLocationChanged = false

        end

        if not player.startLocation then

            brain:AddVisitedLocation(bot.startLocation)
            player.startLocation = bot.startLocation
            brain.exploreTargetPos = nil
            brain.exploreTarget = nil

        end

        local startLocation = player.startLocation
        local currentLocationValid = currentLocationName and currentLocationName ~= ""
        local locationsValid = player.startLocation and player.startLocation ~= "" and currentLocationValid
        local locationDesync = false

        -- Sometimes, this action gets processed before the correct location name is set on a player.
        if brain.exploreTarget ~= nil then
            locationDesync = currentLocationValid and
                    not GetLocationGraph():GetDirectPathsForLocationName(currentLocationName):Contains(brain.exploreTarget)
        end

        -- If we have a location desync, this means that the player does not have the correct location name set.... yet
        if locationDesync then
            --Log("   LocationDesync!!")
            brain.exploreTarget = nil
            brain.exploreTargetPos = nil
            return
            {
                name = name,
                weight = weightIfTargetAcquired,
                perform =
                function(move) end
            }
        end

        local findNew = true

        -- Determine if we should change our current explore target
        if brain.exploreTarget ~= "" and brain.exploreTargetPos ~= nil then

            findNew = currentLocationValid and hasExploredTarget(bot, brain, player)

        end


        if findNew and locationsValid then

            local locGraph = GetLocationGraph()
            local locContention = GetLocationContention()
            local directLocationsSet = locGraph:GetDirectPathsForLocationName(currentLocationName)

            -- Make a copy, since GetDirectPathsForLocationName returns an actual table reference
            local unvisitedLocations = {}
            local visitedLocations = {}
            for i = 1, #directLocationsSet do

                local location = directLocationsSet[i]
                local visited = brain:GetLocationVisited(location)
                if visited and (Shared.GetTime() - visited) < kLocationVisitTimeout then
                   table.insert(visitedLocations, location)
                else
                    table.insert(unvisitedLocations, location)
                end

            end

            local botExploreTargetsTally = GetBotsExploreTargets(bot, player:GetTeamNumber())

            if #unvisitedLocations > 0 then

                local function CalcLocationWeight(loc)

                    local locGroup = GetLocationContention():GetLocationGroup(loc)
                    local numTargets = (botExploreTargetsTally[loc] or 0) + locGroup:GetNumPlayersForTeamType(player:GetTeamNumber())
                    local depth = locGraph:GetDepthForExploreLocation(startLocation, loc)
                    local isStrategic = locGroup:GetHasStrategicEnts()

                    local enterTime = Shared.GetTime() - locGroup:GetStaleTimeForTeam(player:GetTeamType())

                    return ( isStrategic and 1.2 or 1.0 )       -- prioritize exploring techpoints / rt rooms over exploring "empty" rooms
                        * ( 1.0 / (numTargets + 1) )            -- prioritize entering rooms which have fewer bots present
                        * ( 1.0 + (depth / 2) )                 -- add a small amount of priority for rooms that are further down the chain
                        * ( Clamp(enterTime / 20, 0.5, 1.0) )   -- full-weight if no teammates have been in the room in at least 20 seconds

                end

                local function SortLocations2(a, b)
                    return CalcLocationWeight(a) > CalcLocationWeight(b)
                end

                table.sort(unvisitedLocations, SortLocations2)

                local nextExploreLocation = unvisitedLocations[1]

                brain.exploreTargetPos = GetLocationGraph():GetExplorePointForLocationName(nextExploreLocation)
                brain.exploreTarget = nextExploreLocation

            else
                if #visitedLocations > 0 then -- Only in dead ends, which should never happen...

                    local randomLocation = visitedLocations[math.random(#visitedLocations)]
                    brain.exploreTargetPos = GetLocationGraph():GetExplorePointForLocationName(randomLocation)
                    brain.exploreTarget = randomLocation
                    brain:ClearVisitedLocation(randomLocation)
                else -- Should never happen
                    brain.exploreTargetPos = nil
                    brain.exploreTarget = nil
                end

            end
        end

        local weight = 0.0
        if brain.exploreTargetPos ~= nil then
            weight = weightIfTargetAcquired
            GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Explore Target", brain.exploreTarget or "none")
        end

        return 
        {
            name = name,
            weight = weight,
            perform = execExploreAction
        }
    end

end

------------------------------------------
--  Commander stuff
------------------------------------------

function CreateBuildStructureAction( techId, className, numExistingToWeightLPF, buildNearClass, maxDist )

    return function(bot, brain)

        local name = "build"..EnumToString( kTechId, techId )
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local coms = doables[techId]
        local isMarineCom = brain:GetExpectedPlayerClass() == "MarineCommander"

        -- find structures we can build near
        local hosts = GetEntitiesAliveForTeam( buildNearClass, com:GetTeamNumber() )

        -- Pick a random host for now
        local host = hosts[ math.random(#hosts) ]

        if coms ~= nil and #coms > 0
                and hosts ~= nil and #hosts > 0 then
            assert( coms[1] == com )

            -- figure out how many exist already
            local existingEnts = GetEntitiesForTeam( className, com:GetTeamNumber() )
            weight = EvalLPF( #existingEnts, numExistingToWeightLPF )
        end

        -- Make sure it isn't a recently poofed ghost structure.
        if isMarineCom and host then

            local lastPoofTime = brain:GetLastPoofTime(host:GetLocationName())
            if Shared.GetTime() < lastPoofTime + kPoofRetryDelay then
                weight = 0
            end

        end
        
        return 
        { 
            name = name, 
            weight = weight,
            perform = 
                function(move)
                     local pos = GetRandomBuildPosition( techId, host:GetOrigin(), maxDist )
                     if pos ~= nil then
                         brain:ExecuteTechId( com, techId, pos, com )
                     end
                 end 
        }
    end

end

function CreateBuildStructureActionForEach( techId, className, numExistingToWeightLPF, buildNearClass, maxDist)

    return function(bot, brain)

        local name = "build"..EnumToString( kTechId, techId )
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local coms = doables[techId]
        local isMarineCom = brain:GetExpectedPlayerClass() == "MarineCommander"

        -- find structures we can build near
        local hosts = GetEntitiesAliveForTeam( buildNearClass, com:GetTeamNumber() )
        local mainHost
        if coms ~= nil and #coms > 0
                and hosts ~= nil and #hosts > 0 then
            assert( coms[1] == com )

            for _, host in ipairs(hosts) do

                local hostLocationPoofed = false
                if isMarineCom then
                    local lastPoofTime = brain:GetLastPoofTime(host:GetLocationName())
                    hostLocationPoofed = Shared.GetTime() < lastPoofTime + kPoofRetryDelay
                end

                if not hostLocationPoofed and host:GetIsBuilt() and host:GetIsAlive() then
                    local existingEnts = GetEntitiesForTeamWithinRange( className, com:GetTeamNumber(), host:GetOrigin(), maxDist + 1)
                    local newWeight = EvalLPF( #existingEnts, numExistingToWeightLPF )
                    if newWeight > weight then
                        weight = newWeight
                        mainHost = host
                    end
                end
            end
        end

        return { name = name, weight = weight,
                 perform = function(move)

                     if mainHost then
                         if mainHost:GetIsBuilt() and mainHost:GetIsAlive() then

                             local pos = GetRandomBuildPosition( techId, mainHost:GetOrigin(), maxDist )
                             if pos ~= nil then
                                 brain:ExecuteTechId( com, techId, pos, com )
                             end

                         end
                     end

                 end }
    end

end

local function GetEmptyTechPoints( conditionFunc, TechId )

    local resultList = {}

    for _, techPoint in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do

        local attached = techPoint:GetAttached()

        if ( not attached ) and
                ( not conditionFunc or conditionFunc(techPoint) ) then

            table.insert(resultList, techPoint)

        end

    end


    return resultList

end

local techpointDist = 15.0
local friendlyDist = 15.0
function CreateBuildStructureActionNearTechpoints( techId, className, numExistingToWeightLPF)

    return function(bot, brain)

        local name = "build"..EnumToString( kTechId, techId )
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local coms = doables[techId]
        local isMarineCom = brain:GetExpectedPlayerClass() == "MarineCommander"

        -- find techpoints we can build near
        local conditionFunc = function(techPoint)
            return #GetEntitiesForTeamWithinRange("Player", com:GetTeamNumber(), techPoint:GetOrigin(), friendlyDist) > 0
        end

        local hosts = GetEmptyTechPoints( conditionFunc )
        local mainHost
        if coms ~= nil and #coms > 0
                and hosts ~= nil and #hosts > 0 then
            assert( coms[1] == com )

            for _, host in ipairs(hosts) do

                local hostLocationPoofed = false
                if isMarineCom then
                    local lastPoofTime = brain:GetLastPoofTime(host:GetLocationName())
                    hostLocationPoofed = Shared.GetTime() < lastPoofTime + kPoofRetryDelay
                end

                local existingEnts = GetEntitiesForTeamWithinRange( className, com:GetTeamNumber(), host:GetOrigin(), techpointDist + 1)
                local newWeight = EvalLPF( #existingEnts, numExistingToWeightLPF )
                if not hostLocationPoofed and newWeight > weight then
                    weight = newWeight
                    mainHost = host
                end
            end
        end

        return { name = name, weight = weight,
                 perform = function(move)

                     if mainHost then
                         local pos = GetRandomBuildPosition( techId, mainHost:GetOrigin(), techpointDist )
                         if pos ~= nil then
                             brain:ExecuteTechId( com, techId, pos, com )
                         end
                     end

                 end }
    end

end

---@param techId kTechId
---@param weightIfCanDo number
---@param existingTechId kTechId
---@param weightIfExists number
function CreateUpgradeStructureAction( techId, weightIfCanDo, existingTechId, weightIfExists )

    return function(bot, brain)

        local name = EnumToString( kTechId, techId )
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local structures = doables[techId]

        if structures ~= nil then

            weight = weightIfCanDo

            if existingTechId ~= nil then
                if GetTechTree(com:GetTeamNumber()):GetHasTech(existingTechId) then
                    weight = weightIfExists or (weight * 0.3)
                end
            end

        end

        return {
            name = name, weight = weight,
            perform = function(move)

                if structures == nil then return end
                -- choose a random host
                local host = structures[ math.random(#structures) ]
                local success = brain:ExecuteTechId( com, techId, Vector(0,0,0), host )
                if success then
                    SendResearchingChatMessage(bot, com, techId)
                end
            end }
    end

end

------------------------------------------
--  Location Graph utility functions
------------------------------------------

-- Returns the "best guess" gateway we expect a hostile threat to enter this location from
function GetThreatGatewayForLocation( locationName, enemyTechpoint )

    local locGraph = GetLocationGraph()

    local depth = locGraph:GetDepthForExploreLocation(enemyTechpoint, locationName)

    local nearby = locGraph:GetDirectPathsForLocationName(locationName)

    for _, loc in ipairs(nearby) do

        -- Just pick the first gateway that takes us closer to the enemy techpoint - it might not be "correct" but it's cheap
        if locGraph:GetDepthForExploreLocation(enemyTechpoint, loc) < depth then
            return locGraph.locationGateways[locationName][loc]
        end

    end

end
