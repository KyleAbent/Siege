Script.Load("lua/bots/BotDebug.lua")
Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/CommonActions.lua")

local kTunnelSearchRange = 20

local kAlienEvalImmediateThreatTime = 1.0
local kAlienImmediateThreatThreshold = 1.0
local kAlienChaseLostMemoryTime = 5.0

function FindNearestTunnelEntrance(alien, fromPos)

    local tunnels = GetEntitiesForTeam( "TunnelEntrance", alien:GetTeamNumber() )

    return GetMinTableEntry( tunnels,
            function(tunnel)

                assert( tunnel ~= nil )

                if tunnel:GetIsBuilt() and tunnel:GetIsConnected() and not tunnel.killWithoutCollapse then
                    return fromPos:GetDistance(tunnel:GetOrigin())
                else
                    return nil
                end

            end)

end

local function GetIsTunnelEntranceValidForTravel(entrance)
    return entrance:GetIsBuilt() and entrance:GetIsConnected() and not entrance.killWithoutCollapse and entrance:GetOtherEntrance() ~= nil
end

---@class kTunnelDistanceResult
kTunnelDistanceResult = enum({
    'NoTunnel', -- No tunnel sensible, move towards target normally
    'SameTunnel', -- In tunnel with target
    'WrongTunnel', -- In tunnel, target is not in this tunnel
    'EnterTunnel', -- Not in tunnel, but want to be
    'TunnelCollapse' -- We are in a collapsing tunnel
})

local function GetTunnelExitForPos(inWorldStartPos, targetPosTunnel)

    local exitA = targetPosTunnel:GetExitA()
    local exitB = targetPosTunnel:GetExitB()

    if exitA and exitB then
        local aDist = GetBotWalkDistance(inWorldStartPos, exitA)
        local bDist = GetBotWalkDistance(inWorldStartPos, exitB)
        return aDist <= bDist and exitA or exitB
    elseif exitA or exitB then
        return exitA or exitB
    end

end

local function GetInternalTunnelPosForExit(tunnel, exit, enter)
    local exitA = tunnel:GetExitA()
    local exitB = tunnel:GetExitB()
    if exitA and exitA:GetId() == exit:GetId() then
        return enter and tunnel:GetEntranceAPosition() or tunnel:GetExitAPosition()
    elseif exitB and exitB:GetId() == exit:GetId() then
        return enter and tunnel:GetEntranceBPosition() or tunnel:GetExitBPosition()
    end
end

local function GetClosestEntrancesBetweenTunnels(fromTunnel, toTunnel)

    local fromTunnelExits = { fromTunnel:GetExitA(), fromTunnel:GetExitB() }
    local toTunnelExits = { toTunnel:GetExitA(), toTunnel:GetExitB() }

    local closestDistance
    local bestFromExit, bestFromExitPos
    local bestToExit, bestToExitPos

    for _, fromTunnelExit in ipairs(fromTunnelExits) do
        if not fromTunnelExit then goto continue end
        for _, toTunnelExit in ipairs(toTunnelExits) do
            if not toTunnelExit then goto continue end

            local distanceBetweenExits = GetBotWalkDistance(fromTunnelExit, toTunnelExit)
            if not closestDistance or distanceBetweenExits < closestDistance then
                bestFromExit = fromTunnelExit
                bestFromExitPos = GetInternalTunnelPosForExit(fromTunnel, fromTunnelExit, false)
                bestToExit   = toTunnelExit
                bestToExitPos = GetInternalTunnelPosForExit(toTunnel, toTunnelExit, true)
            end

        end
        ::continue::
    end

    return bestFromExit, bestFromExitPos, bestToExit, bestToExitPos

end

-- Return values
-- kTunnelDistanceResult  (always exists)
-- move target distance   (always exists)
-- move target position   (always exists)
-- tunnel entrance entity (only when EnterTunnel is returned for enum)
function GetTunnelDistanceForAlien(alien, destOrTarget, destLocHint)
    PROFILE("GetTunnelDistanceForAlien")

    local to
    local destLocName

    if destOrTarget:isa("Vector") then
        to = destOrTarget
        destLocName = destLocHint
    elseif destOrTarget:isa("ScriptActor") then
        to = destOrTarget:GetOrigin()
        destLocName = destOrTarget:GetLocationName()
    elseif destOrTarget:isa("Entity") then -- Pheromone, for example is not a ScriptActor
        to = destOrTarget:GetOrigin()
        destOrTarget = to
    else
        assert(false, "targetEntOrPos must be a Vector or ScriptActor!")
    end

    --Resolve destLocName the slow way if we can't get it from the ScriptActor
    if not destLocName then
        local destLoc = GetLocationForPoint(to)
        destLocName = destLoc and destLoc:GetName()
    end

    local alienPos = alien:GetOrigin()
    local euclidDist = alienPos:GetDistance(to)

    local alienTunnel = (alien.currentTunnelId and alien.currentTunnelId ~= Entity.invalidId) and Shared.GetEntity(alien.currentTunnelId) or nil
    local endPosTunnel = GetTunnelForPos(to)

    local bothTunnelsValid = alienTunnel and endPosTunnel
    local isSameTunnel = bothTunnelsValid and alienTunnel:GetId() == endPosTunnel:GetId()
    local isWrongTunnel = bothTunnelsValid and alienTunnel:GetId() ~= endPosTunnel:GetId()

    if isSameTunnel then
        return kTunnelDistanceResult.SameTunnel, euclidDist, to, nil
    elseif alienTunnel then -- Wrong tunnel, just pick the closest available tunnel exit to target, don't need to check all entrances!

        local exitA = alienTunnel:GetExitA()
        local exitB = alienTunnel:GetExitB()

        if exitA and exitB then

            local endPos = to

            -- If end goal is in a tunnel, we need to override it to it's in-world entrance pos,
            -- or else we'll get a very large distance
            if endPosTunnel then
                local targetTunnelExitA = endPosTunnel:GetExitA()
                local targetTunnelExitB = endPosTunnel:GetExitB()
                local curTunnelExit, curTunnelExitPos, toTunnelExit, toTunnelExitPos = GetClosestEntrancesBetweenTunnels(alienTunnel, endPosTunnel)

                -- Now that we have the best tunnel entrances for both our current tunnel and
                -- the end tunnel, we can use this new info to properly determine distance in both cases
                endPos = toTunnelExit:GetOrigin()
                local travelDistance = alienPos:GetDistance(curTunnelExitPos) + GetBotWalkDistance(curTunnelExit, toTunnelExit)
                return kTunnelDistanceResult.WrongTunnel, travelDistance, curTunnelExitPos, nil
            else
                -- End position is not in a tunnel
                local exitADist = GetBotWalkDistance(exitA, endPos)
                local exitBDist = GetBotWalkDistance(exitB, endPos)
                local bestExit
                local exitPos

                if exitADist <= exitBDist then
                    bestExit = exitA
                    exitPos = alienTunnel:GetExitAPosition()
                else
                    bestExit = exitB
                    exitPos = alienTunnel:GetExitBPosition()
                end

                local travelDistance = alienPos:GetDistance(exitPos) + GetBotWalkDistance(bestExit, endPos)
                return kTunnelDistanceResult.WrongTunnel, travelDistance, exitPos, nil

            end

        elseif exitA or exitB then -- Only one exit!

            if endPosTunnel then
                local targetTunnelExitA = endPosTunnel:GetExitA()
                local targetTunnelExitB = endPosTunnel:GetExitB()
                local curTunnelExit, curTunnelExitPos, toTunnelExit, toTunnelExitPos = GetClosestEntrancesBetweenTunnels(alienTunnel, endPosTunnel)

                -- Now that we have the best tunnel entrances for both our current tunnel and
                -- the end tunnel, we can use this new info to properly determine distance in both cases
                local travelDistance = alienPos:GetDistance(curTunnelExitPos) + GetBotWalkDistance(curTunnelExit, toTunnelExit)
                return kTunnelDistanceResult.WrongTunnel, travelDistance, curTunnelExitPos, nil
            else
                if exitA then
                    local exitPos = alienTunnel:GetExitAPosition()
                    local distanceToInternalExit = alienPos:GetDistance(exitPos)
                    local totalDistance = distanceToInternalExit + GetBotWalkDistance(exitA, to)
                    return kTunnelDistanceResult.WrongTunnel, totalDistance, exitPos, nil
                else
                    local exitPos = alienTunnel:GetExitBPosition()
                    local distanceToInternalExit = alienPos:GetDistance(exitPos)
                    local totalDistance = distanceToInternalExit + GetBotWalkDistance(exitB, to)
                    return kTunnelDistanceResult.WrongTunnel, totalDistance, exitPos, nil
                end
            end

        else -- It's collapsing, we're screwed!
            return kTunnelDistanceResult.TunnelCollapse, euclidDist, to, nil
        end

    else -- We are not in a tunnel

        local alienLocationName = alien:GetLocationName()
        local walkDistance

        -- If target position is in a tunnel, it'll be waaaay off the playing field,
        -- so we need to override it with the position of the proper tunnel entrance
        local endPos = to
        local endPosTunnelEntrance
        local endPosTunnelDistance
        if endPosTunnel then

            local exitA = endPosTunnel:GetExitA()
            local exitB = endPosTunnel:GetExitB()

            if not exitA and not exitB then -- Tunnel has no entrance, can't do anything
                return kTunnelDistanceResult.TunnelCollapse, euclidDist, to, nil
            elseif exitA and exitB then

                local exitADist = GetBotWalkDistance(alien, exitA)
                local exitBDist = GetBotWalkDistance(alien, exitB)

                if exitADist <= exitBDist then
                    endPos = exitA:GetOrigin()
                    endPosTunnelEntrance = exitA
                    endPosTunnelDistance = exitADist + endPosTunnel:GetEntranceAPosition():GetDistance(to)
                else
                    endPos = exitB:GetOrigin()
                    endPosTunnelEntrance = exitB
                    endPosTunnelDistance = exitBDist + endPosTunnel:GetEntranceBPosition():GetDistance(to)
                end

            elseif exitA then
                endPos = exitA:GetOrigin()
                endPosTunnelEntrance = exitA
                endPosTunnelDistance = GetBotWalkDistance(alien, exitA) + endPosTunnel:GetEntranceAPosition():GetDistance(to)
            elseif exitB then
                endPos = exitB:GetOrigin()
                endPosTunnelEntrance = exitB
                endPosTunnelDistance = GetBotWalkDistance(alien, exitB) + endPosTunnel:GetEntranceBPosition():GetDistance(to)
            end

            walkDistance = endPosTunnelDistance
        else
            walkDistance = GetBotWalkDistance(alien, to)
        end

        -- Finally, since we have a valid target move position
        -- we can now go ahead and find the most sensible tunnel to use
        local bestTunnelEnt
        local bestTunnelTravelDistance

        local tunnelEntrances = GetEntitiesWithinRange("TunnelEntrance", alienPos, kTunnelSearchRange)
        for i, tunnelEntrance in ipairs(tunnelEntrances) do

            if GetIsTunnelEntranceValidForTravel(tunnelEntrance) then

                local otherEntrance         = tunnelEntrance:GetOtherEntrance()
                local itTunnelDistToGoal    = GetBotWalkDistance(tunnelEntrance, endPos)
                local otherTunnelDistToGoal = GetBotWalkDistance(otherEntrance, endPos)

                local itTunnelLocation = tunnelEntrance:GetLocationName()
                local otherTunnelLocation = otherEntrance:GetLocationName()

                local bestTunnelEntrance
                local tunnelEnterDistance
                local tunnelExitDistance

                if itTunnelDistToGoal <= otherTunnelDistToGoal then
                    tunnelEnterDistance = GetBotWalkDistance(alien, otherEntrance)
                    tunnelExitDistance  = GetBotWalkDistance(tunnelEntrance, endPos)
                    bestTunnelEntrance  = otherEntrance
                else
                    tunnelEnterDistance = GetBotWalkDistance(alien, tunnelEntrance)
                    tunnelExitDistance  = GetBotWalkDistance(otherEntrance, endPos)
                    bestTunnelEntrance  = tunnelEntrance
                end

                if not endPosTunnel and alienLocationName and alienLocationName ~= "" and destLocName and
                    GetLocationGraph():GetDirectPathsForLocationName(alienLocationName):Contains(destLocName) and
                    bestTunnelEntrance:GetOtherEntrance():GetLocationName() ~= destLocName then
                    goto continue
                end

                local totalTunnelTravelDistance = tunnelEnterDistance + kTunnelLength + tunnelExitDistance

                if not bestTunnelEnt or totalTunnelTravelDistance < bestTunnelTravelDistance then
                    bestTunnelTravelDistance = totalTunnelTravelDistance
                    bestTunnelEnt = bestTunnelEntrance
                end

                ::continue::
            end

        end

        if bestTunnelEnt and (bestTunnelTravelDistance <= walkDistance) then
            return kTunnelDistanceResult.EnterTunnel, bestTunnelTravelDistance, bestTunnelEnt:GetOrigin(), bestTunnelEnt
        elseif endPosTunnel then
            return kTunnelDistanceResult.EnterTunnel, endPosTunnelDistance, endPosTunnelEntrance:GetOrigin(), endPosTunnelEntrance
        else
            return kTunnelDistanceResult.NoTunnel, euclidDist, endPos, nil
        end

    end

end

local kAlienClassSlowMoveMap =
{
    ["Skulk"] = Move.MovementModifier, -- Sneak
    ["Gorge"] = 0,
    ["Lerk"]  = 0,
    ["Fade"]  = 0,
    ["Onos"]  = 0,
}

-- This function will automatically handle tunnel movement, and set the according move target/view target for it
function HandleAlienTunnelMove( alienPos, targetPos, bot, brain, move )
    PROFILE("HandleAlienTunnelMove")

    -- Should caller avoid setting move target/dir
    -- For example, Skulk likes to jump which can cause it to overshoot tunnel entrances
    local shouldIgnorePostMove = false

    bot:GetMotion():SetIgnoreStuck(false)

    local alien = bot:GetPlayer()
    local eResult, targetDistance, goalPos, entranceTunnel = GetTunnelDistanceForAlien(alien, targetPos)
    GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Tunnel eResult", EnumToString(kTunnelDistanceResult, eResult))
    GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Tunnel Target Distance", targetDistance)
    local goalDistance = alienPos:GetDistance(goalPos)

    if eResult == kTunnelDistanceResult.NoTunnel then -- No good tunnel available, just move normally
        brain.teamBrain:DequeueBotForTunnel(alien:GetId())
        bot:GetMotion():SetDesiredMoveTarget( goalPos )
    elseif eResult == kTunnelDistanceResult.SameTunnel then -- We are in the same tunnel as the target!

        brain.teamBrain:DequeueBotForTunnel(alien:GetId())
        local moveDirection = (goalPos - alienPos):GetUnit()
        bot:GetMotion():SetDesiredMoveDirection(moveDirection)
        bot:GetMotion():SetDesiredViewTarget(goalPos)

    elseif eResult == kTunnelDistanceResult.WrongTunnel then -- In a tunnel, but the wrong one (or one on the way to target)

        brain.teamBrain:DequeueBotForTunnel(alien:GetId())
        local moveDirection = (goalPos - alienPos):GetUnit()
        bot:GetMotion():SetDesiredMoveDirection(moveDirection)
        bot:GetMotion():SetDesiredViewTarget(goalPos)

    elseif eResult == kTunnelDistanceResult.TunnelCollapse then -- No exits to use! we should be dead already but just in case we'll just stay still here

        brain.teamBrain:DequeueBotForTunnel(alien:GetId())
        shouldIgnorePostMove = true

    elseif eResult == kTunnelDistanceResult.EnterTunnel then -- We want to enter a tunnel.

        brain.teamBrain:EnqueueBotForTunnel(alien:GetId(), entranceTunnel:GetId())

        local tunnelOrigin = entranceTunnel:GetOrigin()
        local isThisBotsTurn, nextPlayerId = brain.teamBrain:GetCanBotUseTunnel(alien:GetId(), entranceTunnel:GetId())

        bot:GetMotion():SetDesiredMoveTarget( goalPos )

        local xzAlienPos = Vector(alienPos.x, 0, alienPos.z)
        local xzGoalPos = Vector(goalPos.x, 0, goalPos.z)
        local xzGoalDistance = xzAlienPos:GetDistance(xzGoalPos)

        if isThisBotsTurn then

            if xzGoalDistance < 3 then

                local moveDir = (goalPos - alien:GetOrigin()):GetUnit()
                bot:GetMotion():SetDesiredMoveDirection(moveDir)

                -- Go slow here, so we don't constantly overshoot and get stuck
                local slowMoveCommand = kAlienClassSlowMoveMap[alien:GetClassName()] or 0
                move.commands = AddMoveCommand( move.commands, slowMoveCommand )

                if xzGoalDistance < 0.8 then -- STOP! Any movement will cancel entering the tunnel!
                    bot:GetMotion():SetDesiredMoveTarget( nil )
                end

                shouldIgnorePostMove = true
                if alien:isa("Lerk") then
                    goalPos.y = goalPos.y + 0.3 -- Just so that lerk can more easily step over the tunnel
                    bot:GetMotion():SetIgnoreStuck(true)
                    bot:GetMotion():SetDesiredViewTarget( goalPos )
                else
                    bot:GetMotion():SetDesiredViewTarget( goalPos )
                end

            end
        elseif xzGoalDistance < 4 then
            local nextPlayer = Shared.GetEntity(nextPlayerId)
            bot:GetMotion():SetDesiredMoveTarget( nil )
            bot:GetMotion():SetDesiredViewTarget( nextPlayer and nextPlayer:GetOrigin() or nil )
            if brain.lastTunnelEntranceId ~= entranceTunnel:GetId() then
                -- When we just enter the "stop and wait" phase, re-sort so we make sure that the closest
                -- bot is the first one.
                GetTeamBrain(alien:GetTeamNumber()):SortTunnelQueue(entranceTunnel:GetId())
                brain.lastTunnelEntranceId = entranceTunnel:GetId()
            end

            bot:GetMotion():SetIgnoreStuck(true)
            shouldIgnorePostMove = true -- Stop and wait for the next bot in queue
        end
    end

    return shouldIgnorePostMove, targetDistance, goalPos, entranceTunnel

end

-------------------------------------------------
-- Alien "template" actions
-------------------------------------------------

function CreateAlienInterruptAction()

    return function(bot, brain, player)
        PROFILE("AlienBrain - InterruptObjective")

        -- This thinker returns no valid actions, but will interrupt the bot's current goal
        -- if it is required to react to a high-priority outside action

        local sb = brain:GetSenses()
        local now = Shared.GetTime()

        local shouldInterrupt = false

        if brain.lastThreatResponseCalcTime + kAlienEvalImmediateThreatTime < now then

            local highThreat = sb:Get("highestThreat")

            if highThreat.memory and highThreat.threat > kAlienImmediateThreatThreshold then
                shouldInterrupt = true
            end

            brain.lastThreatResponseCalcTime = now

        end

        if shouldInterrupt then
            brain:InterruptCurrentGoalAction()
        end

        return kNilAction

    end -- INTERRUPT OBJECTIVE FOR HIGH-THREAT MEMORY
end

function CreateAlienRespondToThreatAction(actionWeights, actionType, PerformMove)

    local kValidateRespondToThreats = function( bot, brain, player, action )
        if not action.threat then
            return false
        end

        local sdb = brain:GetSenses()

        -- bail-out if we cannot possibly hope to engage and defeat the threat
        if player:GetHealthScalar() < 0.2 then
            return false
        end

        ---@type TeamBrain.Memory
        local memory = action.threat

        -- if the entity doesn't exist, the threat is dead
        local target = Shared.GetEntity(memory.entId)
        if not target then
            return false
        end

        -- if the threat doesn't have a memory in the team brain anymore, go check it out anyways if it was recent
        -- (if the threat finished attacking a structure it won't be "known" after a short delay, but we should still secure the area)
        local hasMem = brain.teamBrain:GetMemoryOfEntity(memory.entId)
        if hasMem or memory.lastSeenTime + kAlienChaseLostMemoryTime > Shared.GetTime() then
            return true
        end

        return false
    end

    local kExecRespondToThreats = function(move, bot, brain, player, action)
        local memory = action.threat

        brain.teamBrain:UnassignPlayer(player)
        brain.teamBrain:AssignPlayerToEntity(player, action.key)

        PerformMove( player:GetOrigin(), memory.lastSeenPos, bot, brain, move )

        if player:GetOrigin():GetDistance(memory.lastSeenPos) < 5 then
            return kPlayerObjectiveComplete
        end
    end

    return function(bot, brain, player)
        PROFILE("AlienBrain - RespondToThreats")

        local name, weight = actionWeights:Get(actionType)

        local highestThreat = brain:GetSenses():Get("highestThreat")
        local memory = highestThreat.memory

        local key = nil

        if not memory then
            return kNilAction
        end

        key = "respond-" .. memory.entId

        return
        {
            name = name,
            weight = weight,
            threat = memory,
            key = key,
            validate = kValidateRespondToThreats,
            perform = kExecRespondToThreats
        }

    end -- RESPOND TO STRATEGIC THREATS

end

function CreateAlienThreatSense(senses, CalcUtilityFunc)
    senses:Add("highestThreat",
        function(db, player)

            local teamBrain = GetTeamBrain(player:GetTeamNumber())
            local enemyTeam = GetEnemyTeamNumber(player:GetTeamNumber())

            -- BOT-TODO: sort TeamBrain memories based on team index
            local memories = teamBrain:GetMemories()
            local bestWeight = 0.01
            local bestThreat = 0.0
            local bestMemory = nil

            -- basic filtering for threats this bot can respond to
            for _, mem in ipairs(memories) do
                local shouldIgnore = mem.btype == kMinimapBlipType.SensorBlip
                    or mem.btype == kMinimapBlipType.PowerPoint
                    or mem.btype == kMinimapBlipType.DestroyedPowerPoint
                    or mem.btype == kMinimapBlipType.UnsocketedPowerPoint
                    or mem.btype == kMinimapBlipType.BlueprintPowerPoint

                if mem.team == enemyTeam and mem.threat > 0.0 and not shouldIgnore then

                    local target = Shared.GetEntity(mem.entId)

                    local responseWeight = mem.threat * CalcUtilityFunc(player, target)

                    local attackers = teamBrain:GetNumAssignedToEntity(mem.entId)
                    local responders = teamBrain:GetNumAssignedToEntity("respond-" .. mem.entId)
                    local idealResponders = math.ceil(mem.threat)

                    -- prioritize responding to threats that aren't currently being responded to by a friendly
                    responseWeight = responseWeight * (1.0 - (attackers + responders) / idealResponders)

                    if responseWeight > bestWeight then
                        bestWeight = responseWeight
                        bestThreat = mem.threat
                        bestMemory = mem
                    end

                end
            end

            return { memory = bestMemory, threat = bestThreat }
        end)
end

function CreateAlienCommPingSense(senses)
    senses:Add("comPingElapsed",
        function(db, player)

            local pingTime = GetGamerules():GetTeam(player:GetTeamNumber()):GetCommanderPingTime()

            if pingTime > 0 and pingTime ~= nil and pingTime < Shared.GetTime() then
                return Shared.GetTime() - pingTime
            else
                return nil
            end

        end)

    senses:Add("comPingPosition",
        function(db, player)

            local rawPos = GetGamerules():GetTeam(player:GetTeamNumber()):GetCommanderPingPosition()
            -- the position is usually up in the air somewhere, so pretend we did a commander pick to put it somewhere sensible
            local trace = GetCommanderPickTarget(
                player, -- not right, but whatever
                rawPos,
                true, -- worldCoords Specified
                false, -- isBuild
                true -- ignoreEntities
                )

            if trace ~= nil and trace.fraction < 1 then
                return trace.endPoint
            else
                return  nil
            end

        end)

end

-------------------------------------------------
-- Lifeform evolution "template" action
-------------------------------------------------

local kEvolutions = 
{
    kTechId.Gorge,
    kTechId.Lerk,
    kTechId.Fade,
    kTechId.Onos
}

-- 'aggro' personality bots prioritize the "most dangerous" lifeform and shouldn't evolve into gorges
local kAggroEvolutions =
{
    kTechId.Onos,
    kTechId.Fade,
    kTechId.Lerk,
}

local function UpdateBotDesiredUpgrades(bot, brain, player)
    if not player.lifeformUpgrades then
        local chosenChamberUpgrades = {}

        local kUpgradeStructureTable = AlienTeam.GetUpgradeStructureTable()
        for i = 1, #kUpgradeStructureTable do
            -- Choose a random upgrade from each chamber (Spur, Shell, Veil)
            local upgrades = kUpgradeStructureTable[i].upgrades
            table.insert(chosenChamberUpgrades, table.random(upgrades))       --TODO Try using Bot persona to augment this instead of random
        end

        player.lifeformUpgrades = chosenChamberUpgrades
    end

end

local function UpdateBotDesiredEvolution(bot, brain, player)

    if ( gLifeformTypeLock and bot.lifeformEvolution ~= gLifeformTypeLockType ) or not bot.lifeformEvolution then

        if gLifeformTypeLock then
        --purely for debugging purposes to restrict evolving to only X lifeform types
            bot.lifeformEvolution = gLifeformTypeLockType
            brain.teamBrain:ReportBotRole(gLifeformTypeLockType)

        else

            if GetWarmupActive() then
                bot.lifeformEvolution = kEvolutions[math.random(1, #kEvolutions)]
            else

                --First come, first serve. Flip for aggro
                local roleOptions =
                    ( bot.aggroAbility and bot.aggroAbility > 0.75 ) and
                    kAggroEvolutions or
                    kEvolutions

                for i = 1, #roleOptions do
                    local roleId = roleOptions[i]

                    if roleId == kTechId.Gorge and math.random() > 0.3 then
                    --randomized bias towards higher lifeforms
                        goto _NEXT_EVO_STEP

                    elseif brain.teamBrain:GetRoleCount(roleId) > 1 and math.random() < 0.6 then
                    --We already have one of said lifeforms, skip to next one and retry. Spread selection out some
                        goto _NEXT_EVO_STEP
                    end

                    if brain.teamBrain:GetIsRoleAllowed(roleId) then
                        bot.lifeformEvolution = roleId
                        brain.teamBrain:ReportBotRole(roleId)
                        break
                    end
                    ::_NEXT_EVO_STEP::
                end

            end

        end
        --Log("  %s[%s] set lifeform-evo to: %s", bot.name, player:GetId(), bot.lifeformEvolution)
    end

end

function CreateAlienEvolveAction(actionWeights, actionType, lifeformTechId)

    local kExecEvolveObjective = function(move, bot, brain, player, action)
        player:ProcessBuyAction( action.desiredUpgrades )
        return kPlayerObjectiveComplete
    end

    return function(bot, brain, player)
        PROFILE("AlienBrain - Evolve")

        local name, weight = actionWeights:Get(actionType)

        -- Hallucinations don't evolve
        if player.isHallucination then
            return kNilAction
        end

        if player:isa("Skulk") then
        --only evolve "upwards" if we're a skulk, otherwise assume we're the target lifeform we want to be
            UpdateBotDesiredEvolution(bot, brain, player)
        end

        UpdateBotDesiredUpgrades(bot, brain, player)

        local allowedToBuy = player:GetIsAllowedToBuy()

        local s = brain:GetSenses()
        local res = player:GetPersonalResources()

        local distanceToNearestThreat = s:Get("nearestThreat").distance
        local distanceToNearestHive = s:Get("nearestHive").distance
        local desiredUpgrades = {}

        local canEvolve = allowedToBuy and
            (distanceToNearestThreat == nil or distanceToNearestThreat > 25) and 
            (distanceToNearestHive ~= nil and distanceToNearestHive < 8) and
            --TODO Refine with lastInCombatTime > X (ensure we're well out of harms way, not just ducking around a corner, etc.)
            (player.GetIsInCombat == nil or not player:GetIsInCombat())

        if not canEvolve then
            return kNilAction
        end

        -- Safe enough to try to evolve            

        local existingUpgrades = player:GetUpgrades()
        local lifeformUpgrade = bot.lifeformEvolution
        local chosenChamberUpgrades = player.lifeformUpgrades
        local evolvingId = lifeformTechId

        if lifeformUpgrade and lifeformUpgrade ~= lifeformTechId then

            local techId = lifeformUpgrade
            local techNode = player:GetTechTree():GetTechNode(techId)
            local isAvailable = techNode and techNode:GetAvailable(player, techId, false)
            local cost = isAvailable and GetCostForTech(techId) or math.huge

            if res >= cost then
                res = res - cost
                evolvingId = techId -- Each lifeform has a different cost to the chamber upgrades (Spur, Shell, Veil)

                table.insert(desiredUpgrades, techId)
            end

        end

        -- Check upgrades
        for i = 1, #chosenChamberUpgrades do
            local techId = chosenChamberUpgrades[i]
            local techNode = player:GetTechTree():GetTechNode(techId)
            local isAvailable = techNode and techNode:GetAvailable(player, techId, false)
            local cost = isAvailable and LookupTechData(evolvingId, kTechDataUpgradeCost, 0) or math.huge

            if res >= cost and not table.icontains(existingUpgrades, techId) and
                    GetIsUpgradeAllowed(player, techId, existingUpgrades) and
                    GetIsUpgradeAllowed(player, techId, desiredUpgrades) then
                res = res - cost
                table.insert(desiredUpgrades, techId)
            end
        end

        if #desiredUpgrades == 0 then
            return kNilAction
        end

        return
        {
            name = name,
            weight = weight,
            desiredUpgrades = desiredUpgrades,
            perform = kExecEvolveObjective
        }

    end

end


-------------------------------------------------
-- Lifeform Pheromone "template" action
-------------------------------------------------
function CreateAlienPheromoneAction(actionWeights, actionType, pheromoneWeights, PerformMove)

    local kValidatePheromone = function(bot, brain, player, action)
        if not IsValid(action.pheromone) then
            return false
        end

        return true
    end

    local kExecPheromoneObjective = function(move, bot, brain, player, action)
        PerformMove(player:GetOrigin(), action.pheromoneLocation, bot, brain, move)

        local distance = select(2, GetTunnelDistanceForAlien(player, action.pheromoneLocation))

        if distance < 5 then
            table.insert(action.pheromone.visitedBy, bot)
            return kPlayerObjectiveComplete
        end
    end

    return function(bot, brain, player)
        PROFILE("AlienBrain - Pheromone")

        local name, weight = actionWeights:Get(actionType)

        local pheromones = GetEntities( "Pheromone" )
        local bestPheromone
        local bestPheromoneLocation
        local bestValue = 0

        for _, currentPheromone in ipairs(pheromones) do

            local techId = currentPheromone:GetType()
            local techWeight = pheromoneWeights[techId]

            if techWeight and techWeight > 0 then

                local location = currentPheromone:GetOrigin()
                local locationOnMesh = Pathing.GetClosestPoint(location)
                local distanceFromMesh = location:GetDistance(locationOnMesh)

                if distanceFromMesh > 0.001 and distanceFromMesh < 2 then

                    local _, distance = GetTunnelDistanceForAlien(player, location)

                    if currentPheromone.visitedBy == nil then
                        currentPheromone.visitedBy = {}
                    end

                    if not table.icontains(currentPheromone.visitedBy, bot) and distance > 5 then

                        -- Value goes from 5 to 10
                        local value = 5.0 + 5.0 / math.max(distance, 1.0) - #(currentPheromone.visitedBy)

                        if value > bestValue then
                            bestPheromone = currentPheromone
                            bestPheromoneLocation = locationOnMesh
                            bestValue = value
                        end

                    end

                end

            end

        end

        if not bestPheromone then
            return kNilAction
        end

        return
        {
            name = name,
            weight = weight,
            pheromoneLocation = bestPheromoneLocation,
            pheromone = bestPheromone,
            validate = kValidatePheromone,
            perform = kExecPheromoneObjective
        }
    end

end


-------------------------------------------------
-- Lifeform Go-To-Ping "template" action
-------------------------------------------------
function CreateAlienGoToCommPingAction(actionWeights, actionType, PerformMove)

    local kValidateGoToPing = function(bot, brain, skulk, action)
        return action.expireTime > Shared.GetTime()
    end

    local kExecGoToCommPing = function(move, bot, brain, player, action)
        PerformMove( player:GetOrigin(), action.pingPos, bot, brain, move )

        if (player:GetOrigin() - action.pingPos):GetLengthXZ() < 5 then
            brain.lastReachedPingPos = action.pingPos
            return kPlayerObjectiveComplete
        end
    end

    return function( bot, brain, player )
        PROFILE("AlienBrain - GoToCommPing")

        local name, weight = actionWeights:Get(actionType)
        local db = brain:GetSenses()

        local kPingLifeTime = 30.0
        local pingTime = db:Get("comPingElapsed")
        local pingPos

        --BOT-TODO: rate limiting or distance filter so not all bots run for the ping?
        if pingTime ~= nil and pingTime < kPingLifeTime then

            pingPos = db:Get("comPingPosition")

            if not pingPos then
            -- ping is invalid
                return kNilAction

            elseif brain.lastReachedPingPos ~= nil and pingPos:GetDistance(brain.lastReachedPingPos) < 1e-2 then
            -- we already reached this ping - ignore it
                return kNilAction

            end

        else

            return kNilAction

        end

        return
        {
            name = name,
            weight = weight,
            pingPos = pingPos,
            expireTime = pingTime + kPingLifeTime,
            validate = kValidateGoToPing,
            perform = kExecGoToCommPing
        }

    end

end
