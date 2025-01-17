
Script.Load("lua/bots/PlayerBrain.lua")
Script.Load("lua/bots/MarineBrain_Data.lua")
Script.Load("lua/IterableDict.lua")

------------------------------------------
--
------------------------------------------
class 'MarineBrain' (PlayerBrain)

MarineBrain.kClumpCheckRadius = 3.25
MarineBrain.kUnclumpDelayIntervalMin = 0.65
MarineBrain.kUnclumpDelayIntervalMax = 0.825
MarineBrain.kGuardHumanMimicDelay = 1.0 --seconds
MarineBrain.kCloakDelayTime = 3

--Med/Ammo/Struct request time delays/interval
MarineBrain.kCommanderRequestRateTime = 10
--MarineBrain.kCommanderCombatRequestRate = 1.25  --while IN combat only?

MarineBrain.kRailgunExoEnabled = true -- for cheat codes

MarineBrain.kUseObjectiveActions = true


function MarineBrain:Initialize()

    PlayerBrain.Initialize(self)
    self.senses = CreateMarineBrainSenses()

    self.hadAmmo = false
    self.hadGoodHealth = false

    self.unclumpDelayStart = 0
    self.unclumpCacheMoveTarget = nil

    self.lastJumpDodge = 0

    self.lastGateId = nil

    --Simple cache to record that we've decided to Buy X techId. Used to eliminate the
    --need to run through the WHOLE damned weapon-buy-decision steps, again...pointlessly
    self.activeWeaponPurchaseTechId = nil

    --simple world-space vec3 to cache where self should move-to in order to Use X entity
    --this is applied in numerous places, building, repairs, welding, etc.
    self.lastUseActionPosition = nil

    --Simple time cache for when self mimics guarded Human, and which key/move to store
    self.lastGuardStateMimicTime = 0
    self.lastGuardStateMimicKey = nil

    --TEST-- Randomize unclumping check delays across all bots, so we don't get
    --cacading blocking behaviors (e.g. multiple Bots trying to use same side of PG)
    self.kUnclumpDelayInterval = math.random( self.kUnclumpDelayIntervalMin, self.kUnclumpDelayIntervalMax )

    --Flag to denote if Marine should "sneak" (crouch) as const, because Action update rates are inherently variable

    -- Keeps track of entity ids and the last times they were seen as cloaked
    self.lastTargetCloakTimes = IterableDict()

    self.lastWeldTargetId = Entity.invalidId

    -- Keeps track of which 'side' of a usable we are attempting to move towards
    self.lastUseTargetId = Entity.invalidId
    self.lastUseTargetSide = nil

    -- Keeps track of the last order this bot received for interruption purposes
    self.lastOrderId = Entity.invalidId

    -- defend structure ent id -> time checked
    self.defendStructureCorrodedIds = IterableDict()

    self.phaseGateMovingDir = false

    --Commander Requests rate limiting
    self.lastCommanderRequestTime = 0

    --
    self.lastAttackTargetDistance = -1


    --Guard Mode tracking properties
    self.lastCoveringAlertTime = 0
    self.lastGuardLookAroundTime = 0
    self.timeTargetCrouchStart = 0
    self.lastGuardRandLookTarget = nil
    self.lastGuardEntId = Entity.invalidId

end

function MarineBrain:OnLeaveCombat()
    --Log("MarineBrain:OnLeaveCombat()")
    PlayerBrain.OnLeaveCombat(self)

    self.lastAttackTargetDistance = -1
end

function MarineBrain:ResetGuardState()
    self.lastCoveringAlertTime = 0
    self.lastGuardLookAroundTime = 0
    self.timeTargetCrouchStart = 0
    self.lastGuardRandLookTarget = nil
    self.lastGuardEntId = Entity.invalidId
end

local kLowHealthUrgencyTime = 25
function MarineBrain:Update( bot, move )
    PROFILE("MarineBrain:Update")

    if gBotDebug:Get("spam") then
        Print("MarineBrain:Update")
    end

    if PlayerBrain.Update( self, bot, move ) == false then
        return false
    end

    local marine = bot:GetPlayer()
    local time = Shared.GetTime()
    
    if marine ~= nil then

        local marinePos = marine:GetOrigin()

        -- handle firing pistol
        local weapon = marine:GetActiveWeapon() --XX Ammo check?
        if weapon and weapon:isa("Pistol") and bit.band(move.commands, Move.PrimaryAttack) ~= 0 and marine.primaryAttackLastFrame then
            move.commands = bit.bxor(move.commands, Move.PrimaryAttack)
        end

        --We're mimicing our Guarded human, check state(s) and update, expire after X, otherwise, keep it pressed
        if self.lastGuardStateMimicKey ~= nil and self.lastGuardStateMimicTime > 0 then

            if self.lastGuardStateMimicTime + self.kGuardHumanMimicDelay < time then
                move.commands = RemoveMoveCommand( move.commands, self.lastGuardStateMimicKey )
                self.lastGuardStateMimicKey = nil
                self.lastGuardStateMimicTime = 0

            elseif self.lastGuardStateMimicKey ~= nil then
                move.commands = AddMoveCommand( move.commands, self.lastGuardStateMimicKey )

            end

        end

        local lightMode
        local powerPoint = GetPowerPointForLocation(marine:GetLocationName())
        if powerPoint then
            lightMode = powerPoint:GetLightMode()
        end
        
        if not lightMode or lightMode == kLightMode.NoPower and not marine:GetCrouching() then
            if not marine:GetFlashlightOn() then
                marine:SetFlashlightOn(true)
            end
        else
            if marine:GetFlashlightOn() then
                marine:SetFlashlightOn(false)
            end
        end

        if not marine:GetIsInCombat() then
        --while traveling, make sure we're not clumping
            
            if self.unclumpCacheMoveTarget == nil then
                local nearPlayers = GetEntitiesWithinRange("Player", marinePos, self.kClumpCheckRadius)
                
                if #nearPlayers > 0 then --Marine, Exo, JP. Won't be hostiles, becuase no combat
                    --Log("Marine-%s  -  %s Players nearby", marine:GetId(), #nearPlayers)

                    table.sort(
                        nearPlayers,
                        function(a, b)
                            return (marinePos - a:GetOrigin()):GetLength() > (marinePos - b:GetOrigin()):GetLength()
                        end
                    )

                    --Check nearby, sorted for closest, break on action taken
                    for i = 1, #nearPlayers do 
                        if nearPlayers[i] == marine then
                            goto continue --skip ourself
                        end

                        local friend = nearPlayers[i]
                        local shouldPauseMovement = 
                            friend:GetId() ~= marine:GetId() and 
                            friend:GetIsAlive() and 
                            friend:GetTeamNumber() == kTeam1Index and
                            friend:GetVelocity():GetLength() > 0.1  --ignore Marines building, using armory, etc.       
                            --FIXME Above is NOT sufficient for this type of check  ...could be an AFK Human. Thus, we'll just try to
                            --continually walk through an idle/motionless player. In an ideal world, we'd have a "move-around" (e.g. arc-paths) sub-routine.

                        if shouldPauseMovement then
                            if IsPointInCone( friend:GetOrigin(), marine:GetEyePos(), marine:GetViewCoords().zAxis, bot.aim.viewAngle * 0.5 ) then
                            --target ahead and in fov, at this range...that means we're a clump. Halt out progress temporarily and proceed
                                self.unclumpCacheMoveTarget = bot:GetMotion().desiredMoveTarget
                                self.unclumpDelayStart = time
                                bot:GetMotion().desiredMoveTarget = nil     --HACKS!
                                break
                            end
                        end

                        ::continue::
                    end
                    
                end

            else
                if self.unclumpCacheMoveTarget ~= nil and self.unclumpDelayStart + self.kUnclumpDelayInterval < time then
                    bot:GetMotion().desiredMoveTarget = self.unclumpCacheMoveTarget
                    self.unclumpCacheMoveTarget = nil
                    self.unclumpDelayStart = 0
                end
            end

        end

    --FIXME Need to review/reise below, Bots will SPAM pack requests, way WAY too often...at least throttle the rate (global or perbot-global)
        if not GetWarmupActive() then
            -- Send ammo/med requests

            local armoryDist = self.senses:Get("nearestArmory").distance
            local tNow = Shared.GetTime()

            if armoryDist and armoryDist > 30 then

                -- Scale the frequency of medpack requests the more dire the situation
                local hpFrac = marine:GetHealthFraction()
                local hpReqInterval = math.max(self.kCommanderRequestRateTime * hpFrac, 4.0)

                local ammoFrac = self.senses:Get("ammoFraction")
                local ammoReqInterval = math.max(self.kCommanderRequestRateTime * ammoFrac, 5.0)

                if hpFrac < 0.6 and self.lastCommanderRequestTime + hpReqInterval < tNow then
                    CreateVoiceMessage( marine, kVoiceId.MarineRequestMedpack )
                    self.lastCommanderRequestTime = tNow
                end

                if ammoFrac < 0.2 and self.lastCommanderRequestTime + ammoReqInterval < tNow then
                    CreateVoiceMessage( marine, kVoiceId.MarineRequestAmmo )
                    self.lastCommanderRequestTime = tNow
                end

            end

            --[[
            --TODO All pack related things should be locked into single function, so it's overall rate can be easily controlled
            local nearbyArmories = GetEntitiesWithinRange("Armory", marinePos, 30)  --BOT-FIXME This won't get AdvancedArmories...

            if self.hadAmmo then
                if self.senses:Get("ammoFraction") <= 0.0 and #nearbyArmories == 0 then
                    CreateVoiceMessage( marine, kVoiceId.MarineRequestAmmo )    --???? Shouldn't this just perform the Key-press instead of triggering this?
                    self.hadAmmo = false
                end
            else
                if self.senses:Get("ammoFraction") > 0.0 then
                    self.hadAmmo = true
                end
            end

            local hpFrac = marine:GetHealthFraction()

            -- Med kit request
            if self.hadGoodHealth then
                if hpFrac <= 0.5 then
                    if math.random() < 0.2 and #nearbyArmories == 0 then
                        CreateVoiceMessage( marine, kVoiceId.MarineRequestMedpack )
                    end
                    self.hadGoodHealth = false
                end
            else
                if hpFrac > 0.5 then
                    self.hadGoodHealth = true
                end
            end

            if self.hadGoodHealth then
                self.medPackTimer = nil
            end
            
            -- persistent med kit request
            if hpFrac <= 0.5 then
                if not self.medPackTimer then
                    self.medPackTimer = Shared.GetTime()
                end
                local fractionTime = kLowHealthUrgencyTime * hpFrac + 3
                if self.medPackTimer < Shared.GetTime() - fractionTime and #nearbyArmories == 0 then
                    self.medPackTimer = Shared.GetTime()
                    CreateVoiceMessage( marine, kVoiceId.MarineRequestMedpack )
                end
            end
            --]]
        end

    else
        self.hadAmmo = false
        self.hadGoodHealth = false
    end

end

function MarineBrain:GetExpectedPlayerClass()
    return "Marine"
end

function MarineBrain:GetExpectedTeamNumber()
    return kMarineTeamType
end

function MarineBrain:GetActions()
    return kMarineBrainActions
end

function MarineBrain:GetObjectiveActions()
    return kMarineBrainObjectiveActions
end

function MarineBrain:GetSenses()
    return self.senses
end

