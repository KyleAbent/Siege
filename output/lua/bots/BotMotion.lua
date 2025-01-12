-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- Created by Steven An (steve@unknownworlds.com)
--
-- This class takes high-level motion-intents as input (ie. "I want to move here" or "I want to go in this direction")
-- and translates them into controller-inputs, ie. mouse direction and button presses.
--
-- ==============================================================================================

------------------------------------------
--  Provides an interface for higher level logic to specify desired motion.
--  The actual bot classes use this to compute move.move, move.yaw/pitch. Also, jump.
------------------------------------------

---@class BotMotion
BotMotion = nil

class "BotMotion"

function BotMotion:Initialize(player, bot)

    self.currMoveDir = Vector(0,0,0)
    self.currViewDir = Vector(1,0,0)
    self.lastMovedPos = player:GetOrigin()
    self.lastGroundHeight = nil

    self.currPathPoints = nil
    self.currPathPointsIt = 1
    self.unstuckUntil = 0
    self.nextMoveUpdate = 0
    self.bot = bot
    self.ignoreStuck = false

end

function BotMotion:SetIgnoreStuck(ignore)
    self.ignoreStuck = ignore

    -- Clear stuck vars
    self.unstuckUntil = 0
    self.lastStuckPos = nil
    self.lastStuckTime = nil
end

function BotMotion:ComputeLongTermTarget(player)

    local kTargetOffset = 1

    if self.desiredMoveDirection ~= nil then

        local toPoint = player:GetOrigin() + self.desiredMoveDirection * kTargetOffset
        return toPoint

    elseif self.desiredMoveTarget ~= nil then

        return self.desiredMoveTarget

    else

        return nil

    end
end

local function GetNearestPowerPoint(origin)

    local nearest
    local nearestDistance = 0

    for _, ent in ientitylist(Shared.GetEntitiesWithClassname("PowerPoint")) do

        local distance = (ent:GetOrigin() - origin):GetLengthSquared()
        if nearest == nil or distance < nearestDistance then

            nearest = ent
            nearestDistance = distance

        end

    end

    return nearest

end

-- Find the index of the next "major" path point in our current path.
-- Used to determine lookahead and querying small sub-sections of the pathing for move directions.
function BotMotion:ComputeNextPathPointIndex(from, index, collapseDist)
    if self.currPathPoints == nil or #self.currPathPoints == 0 then
        return index
    end

    -- Increase iterator forward for each points of the path below X meters
    local total = 0
    local len = #self.currPathPoints
    local last = from

    while index < len and self.currPathPoints[index]:GetDistance(last) + total < collapseDist do
        total = total + last:GetDistanceTo(self.currPathPoints[index])
        last = self.currPathPoints[index]
        index = index + 1
    end

    return index
end

function BotMotion:ComputePathHeightMean(groundPoint, index, dist)
    if self.currPathPoints == nil or #self.currPathPoints == 0 then
        return groundPoint.y
    end

    local heights = { groundPoint.y }

    local nextIndex = self:ComputeNextPathPointIndex(groundPoint, index, dist)
    for i = index, nextIndex do
        table.insert(heights, self.currPathPoints[i].y)
    end

    return table.mean(heights)
end

------------------------------------------
--  Expensive pathing call
------------------------------------------
function BotMotion:GetOptimalMoveDirection(from, to)
    PROFILE("BotMotion:GetOptimalMoveDirection")

    local minDistOpti = 4 -- Distance below which the next point in the path is removed.
    local newMoveDir, reachable

    if self.currPathPoints == nil or self.forcePathRegen or from:GetDistanceTo(to) < minDistOpti then

        -- Generate a full path to follow (expensive)
        self.currPathPoints = PointArray()
        self.currPathPointsIt = 1
        self.forcePathRegen = nil
        reachable = Pathing.GetPathPoints(from, to, self.currPathPoints)
        if reachable and #self.currPathPoints > 0 then
            newMoveDir = (self.currPathPoints[1] - from):GetUnit()
        end

    else

        -- Follow the path we have generated earlier: It is much much faster to compute a
        -- direction using a small portion of the path, and reliable since it gaves us the
        -- real direction to use (regardless of any displacement, pos we could be in)
        if self.currPathPoints and #self.currPathPoints > 0 then
            -- Increase iterator forward for each points of the path below X meters
            self.currPathPointsIt = self:ComputeNextPathPointIndex(from, self.currPathPointsIt, minDistOpti)

            if self.currPathPointsIt == #self.currPathPoints then
                self.currPathPoints = nil
            else
                -- Compute reliable direction using previously generated path
                local pathPoints = PointArray()
                reachable = Pathing.GetPathPoints(from, self.currPathPoints[self.currPathPointsIt], pathPoints)
                if reachable and #pathPoints > 0 then
                    newMoveDir = (pathPoints[1] - from):GetUnit()
                end
            end
        end
    end

    local travelDistanceSuqared = (to - from):GetLengthSquared()
    if not newMoveDir and travelDistanceSuqared > 100 then -- first fallback

        local pathPoints = PointArray()
        local nearestResNode = GetNearest(to, "ResourcePoint")
        if nearestResNode then
            reachable = Pathing.GetPathPoints(from, nearestResNode:GetOrigin(), pathPoints)
            if reachable and #pathPoints > 0 then
                newMoveDir = (pathPoints[1] - from):GetUnit()
            end
        end

    end

    if not newMoveDir and travelDistanceSuqared > 100 then -- second fallback

        local pathPoints = PointArray()
        local nearestPower = GetNearestPowerPoint(to)
        if nearestPower then
            reachable = Pathing.GetPathPoints(from, nearestPower:GetOrigin(), pathPoints)
            if reachable and #pathPoints > 0 then
                newMoveDir = (pathPoints[1] - from):GetUnit()
            end
        end

    end

    if not newMoveDir then -- third fallback
        newMoveDir = (to - from):GetUnit()
    end

    self.currMoveDir = newMoveDir
end

------------------------------------------
--
------------------------------------------
local maxDistOffPath = 0.65
local minDistToUnstuck = 3.0
local timeToBeStuck = 60.0
local kMaxRotateSpeed = 1.0
local kTooFastRotateSpeed = 0.7 --- target whipped past very fast
local kSlowRotateSpeed = 0.5 -- target is too high

local kAimStateToRotateSpeeds =
{
    [kAimDebuffState.None] = kMaxRotateSpeed,
    [kAimDebuffState.TooFast] = kTooFastRotateSpeed,
    [kAimDebuffState.UpHigh] = kSlowRotateSpeed,
}

function BotMotion:GetRotateSpeed()

    if not self.bot then return kMaxRotateSpeed end -- Hallucinations do not have a bot set. (They don't have one)
    if not self.bot.aim then return kMaxRotateSpeed end

    local aimTurnRate = self.bot.aim:GetAimTurnRateModifier()
    local aimDebuffState = self.bot.aim:GetAimDebuffState()

    return aimTurnRate * kAimStateToRotateSpeeds[aimDebuffState]

end

function BotMotion:GetCurPathLook(eyePos)
    local lookDir = self.currMoveDir
    local lookDistance = 4
    if self.desiredViewTarget then
        lookDir = (self.desiredViewTarget - eyePos):GetUnit()
    end
    if self.desiredViewTarget and (self.desiredViewTarget - eyePos):GetLength() < lookDistance then     --FIXME/REVIEW: If no actions are taken...why perform this check at all?
        -- leave it
    elseif self.currPathPoints ~= nil then
        local iter = self.currPathPointsIt + 1
        while iter < #self.currPathPoints
                and self.currPathPoints[iter]:GetDistanceTo(eyePos) < lookDistance
        do
            iter = iter + 1
        end
        if iter < #self.currPathPoints then
            lookDir = (self.currPathPoints[iter] - eyePos):GetUnit()
        end
    end
    return lookDir
end

function BotMotion:OnGenerateMove(player)
    PROFILE("BotMotion:OnGenerateMove")
    
    if not player:GetIsAlive() then
        Log("WARNING: Bot GenerateMove called while player[%s] is dead!", player:GetId())
    end

    local currentPos = player:GetOrigin()
    local viewCoords = player:GetViewCoords()
    local onGround = player.GetIsOnGround and player:GetIsOnGround()
    local eyePos = player:GetEyePos()
    local isSneaking = (player.GetCrouching and player:GetCrouching() and player:isa("Marine")) or (player:isa("Skulk") and player.movementModiferState)
    local isGroundMover = player:isa("Marine") or player:isa("Exo") or player:isa("Onos") or player:isa("Gorge")
    local isInCombat = (player.GetIsInCombat and player:GetIsInCombat())
    local doJump = false
    local groundPoint = Pathing.GetClosestPoint(currentPos)
    local isStuck = false

    local delta = currentPos - self.lastMovedPos
    local distToTarget = 100
    local now = Shared.GetTime()
    ------------------------------------------
    --  Update ground motion
    ------------------------------------------

    local moveTargetPos = self:ComputeLongTermTarget(player)

    if moveTargetPos ~= nil and not player:isa("Embryo") then

        distToTarget = currentPos:GetDistance(moveTargetPos)
        
        if distToTarget <= 0.01 then

            -- Basically arrived, stay here
            self.currMoveDir = Vector(0,0,0)

        else

            local updateMoveDir = self.nextMoveUpdate <= now
            local unstuckDuration = 1.2
            isStuck = not self.ignoreStuck and (delta:GetLength() < 1e-2 or self.unstuckUntil > now)

            if not isGroundMover and not isStuck and not isSneaking then
                if not self.lastFlyingPos then
                    self.lastFlyingPos = currentPos
                    self.lastFlyingTime = Shared.GetTime()
                else
                    if self.lastFlyingTime + 3 < Shared.GetTime() then
                        local flyingDelta = currentPos - self.lastFlyingPos
                        if not self.ignoreStuck and flyingDelta:GetLength() < 2.5 then
                            isStuck = true
                            self.unstuckUntil = now + unstuckDuration * math.random()
                        else
                            self.lastFlyingPos = currentPos
                            self.lastFlyingTime = Shared.GetTime()
                        end
                    end
                end
            end

            -- are we moving towards our move target?
            local forwardProgress = self.desiredMoveTarget and delta:GetUnit():DotProduct((self.currMoveDir):GetUnit())

            if self.desiredMoveTarget and isGroundMover and (not isStuck and (forwardProgress < 0.9 or delta:GetLength() < 1e-2)) then
            -- not actually stuck, just want to try to jump over the obstacle
                local moveTargetDelta = self.desiredMoveTarget - player:GetOrigin()
                local vertDist = math.abs(moveTargetDelta.y)

                if not self.ignoreStuck and vertDist > 0.5 and vertDist > moveTargetDelta:GetLengthXZ() then
                    isStuck = true
                    -- but not actually stuck! we just want the random movement/jumping
                    self.lastStuckPos = nil
                    self.lastStuckTime = nil
                    self.unstuckUntil = now + unstuckDuration * math.random()
                end
            end


            if updateMoveDir then

                self.nextMoveUpdate = now + kPlayerBrainTickFrametime
                -- If we have not actually moved much since last frame, then maybe pathing is failing us
                -- So for now, move in a random direction for a bit and jump
                if isStuck and not isSneaking then

                    if not self.lastStuckPos or (currentPos - self.lastStuckPos):GetLength() > minDistToUnstuck then
                        self.lastStuckPos = currentPos
                        self.lastStuckTime = now
                    end

                    if self.unstuckUntil < now then
                        -- Move randomly during Xs
                        self.unstuckUntil = now + unstuckDuration * math.random()

                        self.currMoveDir = GetRandomDirXZ() - GetNormalizedVectorXZ(viewCoords.zAxis) * GetSign((forwardProgress or 0) + 0.0001)

                        if isGroundMover then
                            doJump = true
                            self.lastJumpTime = Shared.GetTime()
                            self:SetDesiredMoveDirection(self.currMoveDir)
                        else
                            self.currMoveDir.y = math.sin(Shared.GetTime() * 0.3) * 4 - 2
                            self.desiredViewTarget = nil
                            groundPoint = nil
                        end

                        self.currMoveDir:Normalize()

                    end

                elseif distToTarget <= 1.0 then

                    -- Optimization: If we are close enough to target, just shoot straight for it.
                    -- We assume that things like lava pits will be reasonably large so this shortcut will
                    -- not cause bots to fall in
                    -- NOTE NOTE STEVETEMP TODO: We should add a visiblity check here. Otherwise, units will try to go through walls
                    self.currMoveDir = (moveTargetPos - currentPos):GetUnit()

                    if self.lastStuckPos then
                        self.lastStuckPos = nil
                        self.lastStuckTime = nil
                    end

                else

                    -- We are pretty far - do the expensive pathing call
                    self:GetOptimalMoveDirection(currentPos, moveTargetPos)

                    if self.lastStuckPos and (currentPos - self.lastStuckPos):GetLength() > minDistToUnstuck then
                        self.lastStuckPos = nil
                        self.lastStuckTime = nil
                    end

                    --[[
                    if groundPoint then

                        local wantedHeight = self:ComputePathHeightMean(groundPoint, self.currPathPointsIt, 4.0)

                        if player:isa("Fade") then
                            -- wantedHeight = wantedHeight + 1.3
                            wantedHeight = currentPos.y
                        elseif player:isa("Lerk") then
                            wantedHeight = wantedHeight + 1.1
                        elseif player:isa("Skulk") then
                            wantedHeight = wantedHeight + 0.4
                        end

                        -- adjust move direction to ensure bots stay off the ground as needed
                        local heightDiff = wantedHeight - currentPos.y

                        if math.abs(heightDiff) > 0.4 then
                            self.currMoveDir.y = heightDiff
                        else
                            self.currMoveDir.y = 0.0
                        end

                    end
                    --]]

                    --[[
                    McG: I'm removing this for now, because it just adds a bunch of crap pathing, sends Bots into walls, gets stuck in corners, etc, etc.
                    if isSneaking then

                        local time = Shared.GetTime()
                        local strafeTarget = self.currMoveDir:CrossProduct(Vector(0,1,0))
                        strafeTarget:Normalize()

                        -- numbers chosen arbitrarily to give some appearance of sneaking
                        strafeTarget = strafeTarget * ConditionalValue( math.sin(time * 1.5 ) + math.sin(time * 0.2 ) > 0 , -1, 1)
                        strafeTarget = (strafeTarget + self.currMoveDir):GetUnit()

                        if strafeTarget:GetLengthSquared() > 0 then
                            self.currMoveDir = strafeTarget
                        end

                    end
                    --]]

                end

                self.currMoveTime = Shared.GetTime()

            end

            self.lastMovedPos = currentPos
        end

    else

        -- Did not want to move anywhere - stay still
        self.currMoveDir = Vector(0,0,0)

    end

    --Need specific one-off for Marines, so they can navigate PhaseGates cleanly
    local skipOnNavMeshTweak = false
    if player:isa("Marine") then
        if self.bot and self.bot.brain and self.bot.brain.lastGateId ~= nil then    --Note: have to check for .brain because lazy-init garbage
            skipOnNavMeshTweak = true
        end
    end

    -- don't move there if it's off pathing
    if self.desiredMoveDirection and distToTarget <= 2.0 and not skipOnNavMeshTweak then 
        local roughNextPoint = currentPos + self.currMoveDir * delta:GetLength()
        local closestPoint = Pathing.GetClosestPoint(roughNextPoint)
        if closestPoint and groundPoint and
                ((closestPoint - roughNextPoint):GetLengthXZ() > maxDistOffPath) and
                ((groundPoint - currentPos):GetLengthXZ() > 0.1) then
            self.currMoveDir = (closestPoint - currentPos):GetUnit()
        end
    end

    ------------------------------------------
    --  View direction
    ------------------------------------------
    local desiredDir
    if self.desiredViewTarget ~= nil then

        -- Look at target
        desiredDir = (self.desiredViewTarget - eyePos):GetUnit()

    elseif self.currMoveDir:GetLength() > 1e-4 and not isStuck then

        -- Look in move dir
        if self:isa("Marine") or self:isa("Exo") then
            desiredDir = self:GetCurPathLook(eyePos) -- self.currMoveDir
        else
            desiredDir = self.currMoveDir
            if isGroundMover or player:isa("Skulk") then
                desiredDir.y = 0.0  -- pathing points are slightly above ground, which leads to funny looking-up
            end
            desiredDir = desiredDir:GetUnit()
        end

        if player:isa("Exo") or player:isa("Marine") or player:isa("Fade") then
            if doJump or not onGround then
                desiredDir.y = 0.2
            else
                desiredDir.y = 0.0  -- pathing points are slightly above ground, which leads to funny looking-up
            end
        end

        if player:isa("Lerk") and isInCombat and distToTarget > 8.5 and (not HasMixin(player, "Live") or player:GetHealthScalar() < 0.75) then
        -- lerk juking, use a very aggressive sine wave to simulate "good player" lerk movements

            local time = Shared.GetTime()
            desiredDir.y = (math.sin(time * 5.78 ) + math.cos(time * 8.35 )) * 0.8      --BOT-TODO Tune based on "allowable" space for X Location(segment) (note, this would be usefil for JP-Marine too)

            -- this is expensive!!!(-ish, only 8-10us)
            local trace = Shared.TraceRay(eyePos, eyePos + desiredDir * 3, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterAll())

            -- emergency dive/climb back to "normal" levels if we detect we're going to fly into something while attempting to juke
            if trace.fraction < 1 or (groundPoint and (currentPos.y - groundPoint.y) > 2.0) then
                desiredDir = self:GetCurPathLook(eyePos)
                desiredDir.y = desiredDir.y - 0.3 -- fallback approximation

                if groundPoint then
                    -- better approximation using angle to the ground to pick a vertical look component
                    -- still not perfect but would need round-trip through a Coords for actual mathematically-correct rotation
                    local heightDiff = 0.8 - (currentPos.y - groundPoint.y)
                    local desiredAng = math.atan2(heightDiff, (trace.endPoint - currentPos):GetLengthXZ() * 0.8) -- increase the vertical dive factor here with tuned constants
                    desiredDir.y = math.sin(desiredAng)
                end
            end

        else
            -- calculate the height off the ground we want to attempt to reach
            local desiredHeight = groundPoint and groundPoint.y + 1.1 or 0
            local desiredDist = 4.0

            -- Determine if we're going to run into anything and adjust our "achievable distance"
            -- this is expensive!!!(-ish, only 8-10us)
            local traceDir = self.currMoveDir
            if player:isa("Lerk") or player:isa("Fade") then
                traceDir = player:GetVelocity():GetUnit()
            end

            local trace = Shared.TraceRay(eyePos, eyePos + traceDir * desiredDist, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterAll())

            if trace.fraction < 1 then
                desiredDist = (trace.endPoint - currentPos):GetLengthXZ()
            end

            if player:isa("Skulk") then
                local heightAvg = groundPoint and self:ComputePathHeightMean(groundPoint, self.currPathPointsIt, 3.0) + 0.2
                desiredHeight = heightAvg or currentPos.y

            elseif player:isa("Fade") then
                local heightAvg = groundPoint and self:ComputePathHeightMean(groundPoint, self.currPathPointsIt, 4.0) + 1.3
                desiredDir.y = 0

                if isInCombat and distToTarget < 8.5 then
                    desiredHeight = moveTargetPos.y
                else
                    desiredHeight = heightAvg or currentPos.y
                end

            elseif player:isa("Lerk") and not isInCombat then
                desiredDir.y = 0

                local fromPoint = groundPoint or Vector(currentPos.x, self.lastGroundHeight or currentPos.y, currentPos.z)
                local heightMean = self:ComputePathHeightMean(fromPoint, self.currPathPointsIt, 4.0)

                if not self.lastGroundHeight then
                    self.lastGroundHeight = heightMean
                end

                heightMean = Lerp(self.lastGroundHeight, heightMean, 0.8)

                if self.currPathPoints and #self.currPathPoints > 0 then

                    -- Find the next point we'll be attempting to move to
                    local nextPointIdx = self:ComputeNextPathPointIndex(eyePos, self.currPathPointsIt, 6)
                    local nextPoint = self.currPathPoints[nextPointIdx]

                    local currentPoint = self.currPathPoints[self.currPathPointsIt]
                    local steerDist = (currentPoint - currentPos):GetLengthXZ()

                    local nextDir = GetNormalizedVectorXZ(nextPoint - currentPoint)
                    local progress = Clamp(steerDist / 4.0, 0.0, 1.0)

                    -- Progressively steer towards our next path point
                    desiredDir = Lerp(desiredDir, nextDir, 1.0 - progress)

                end

                -- gentle up/down gliding flight pattern
                local height = 1.3 + (math.sin(now * 1.45) + math.cos(now * 2.15)) * 0.45
                desiredHeight = heightMean + height

            end

            if player:isa("Lerk") or player:isa("Skulk") or player:isa("Fade") then

                local yaw = GetYawFromVector(desiredDir)
                local pitch = -math.atan2(desiredHeight - currentPos.y, desiredDist)

                local currentPitch = player:GetViewAngles().pitch
                local newPitch = SlerpRadians(currentPitch, pitch, 0.8)

                desiredDir = Vector(math.sin(yaw), -math.sin(newPitch), math.cos(yaw))

            end

        end

        desiredDir:Normalize()

    else
        -- leave it alone
    end

    if desiredDir then
        -- TODO: change the frametime to the actual time spent
        -- since we could be in combat doing 26fps or out of combat and doing 8fps
        local slerpSpeed = kPlayerBrainTickFrametime * self:GetRotateSpeed()

        local currentYaw = player:GetViewAngles().yaw
        local targetYaw = GetYawFromVector(desiredDir)

        local xzLen = desiredDir:GetLengthXZ()

        local newYaw = SlerpRadians(currentYaw, targetYaw, slerpSpeed)

        local currentPitch = player:GetViewAngles().pitch
        local targetPitch = GetPitchFromVector(desiredDir)
        local newPitch = SlerpRadians(currentPitch, targetPitch, slerpSpeed)

        local inBetween = Vector(math.sin(newYaw) * xzLen, -math.sin(newPitch), math.cos(newYaw) * xzLen)
        self.currViewDir = inBetween:GetUnit()

    end

    if player:isa("Exo") and (self.lastJumpTime and self.lastJumpTime > Shared.GetTime() - 2) then
        doJump = true
    end

    if self.lastStuckPos and self.lastStuckTime and
            (currentPos - self.lastStuckPos):GetLength() < minDistToUnstuck and
            self.lastStuckTime + timeToBeStuck < now then

        -- we've been stuck for a very long time... we can't get out
        player:Kill(nil, nil, player:GetOrigin())
        self.lastStuckPos = nil
        self.lastStuckTime = nil
    end

    return self.currViewDir, self.currMoveDir, doJump

end

------------------------------------------
--  Higher-level logic interface
------------------------------------------
function BotMotion:SetDesiredMoveTarget(toPoint)

    -- Mutually exclusive
    self:SetDesiredMoveDirection(nil)


    if not VectorsApproxEqual( toPoint, self.desiredMoveTarget, 1e-4 ) then
        self.desiredMoveTarget = toPoint
        self.forcePathRegen = true -- TODO: if target is far, we could still reuse the same path and regen later
    end

end

------------------------------------------
--  Higher-level logic interface
------------------------------------------
-- Note: while a move direction is set, it overrides a target set by SetDesiredMoveTarget
function BotMotion:SetDesiredMoveDirection(direction)

    if not VectorsApproxEqual( direction, self.desiredMoveDirection, 1e-4 ) then
        self.desiredMoveDirection = direction
    end

end

------------------------------------------
--  Higher-level logic interface
--  Set to nil to clear view target
------------------------------------------
function BotMotion:SetDesiredViewTarget(target)

    self.desiredViewTarget = target

end

------------------------------------------
--  Utils to handle the path
--  Can be used to make the bot retreat easily or follow a precomputed path
------------------------------------------

function BotMotion:GetPath()

   return self.currPathPoints

end

function BotMotion:GetPathIndex()

   return self.currPathPointsIt

end
