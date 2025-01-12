-- ======= Copyright (c) 2022, Unknown Worlds Entertainment, Inc. All rights reserved. ============
--
-- lua\bots\PerceiverMixin.lua
--
--     Created By: Brock Gillespie
--
-- This Mixin is for creating the causal effect of Bots having limited Field of VISION(not view)
-- A trigger is created which all "perceive-able" object interact with, OnUpdate tests if the Bot
-- can actually perceive, thus SEE the Entity.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


Script.Load("lua/IterableDict.lua")



dbgDrawBotPerceptionRadius = false
local gBotViz_PlayerEntIds = {}
local gBotPercepVisEntityId = Entity.invalid
local gBotViz_ActiveVizIndex = -1


--Note: Values defined in BalanceMisc.lua
gClassFovLookup = {}
gClassFovLookup["Marine"] = kDefaultFov
gClassFovLookup["JetpackMarine"] = kDefaultFov
gClassFovLookup["Exo"] = kExoFov
gClassFovLookup["Skulk"] = kSkulkFov
gClassFovLookup["Gorge"] = kGorgeFov
gClassFovLookup["Lerk"] = kLerkFov
gClassFovLookup["Fade"] = kFadeFov
gClassFovLookup["Onos"] = kOnosFov
gClassFovLookup["Embryo"] = kEmbryoFov



PerceiverMixin = {}
PerceiverMixin.type = "PerceiverMixin"

PerceiverMixin.expectedCallbacks = 
{
    OnPerceivedEntity = "Callback to filter what entities this Perceiver can see. Return false to ignore",
    GetCanPerceiveEntity = "Testing to determine if we can actually see an entity. First param is perceived entity",
}

PerceiverMixin.expectedConstants =
{
    kPhysicsGroup = "physics group of perception collider",
    kFilterMask = "physics filter mask for perception collider collisions",
    kPerceptionRadius = "Radius in which Perceiver can detect applicable entity types",
    kFieldOfView = "Value in degrees which denotes effective sight-frustum",
}

PerceiverMixin.optionalConstants =
{
    kPerceivedRetriggerDelay = "Minimum amount of time required after first perception of an Entity, which will trigger RE-perception of Entities",
}



PerceiverMixin.kDefaultPerceptionRadius = 20
--PerceiverMixin.kEnabledDebugVisualize = Server.GetVerbosityLevel() > 0        --?? was this wired up?

PerceiverMixin.kUpdateInterval = 0.1425   --tuned any faster (when debug enabled) will choke server

--Minimum amount of time from _first_ perception of an Entity to the second time it is "perceived"
PerceiverMixin.kDefaultPerceiveRetriggerDelay = 1   --TODO review/refine, smaller is better if possible


function PerceiverMixin:__initmixin()           --FIXME if possible...we need to prevent (via filters?) self colliding with self.perceiveTrig
    PROFILE("PerceiverMixin:__initmixin")

    assert(Server, "Error: PerceiverMixin can only be used in Server context")
    assert(self:GetIsVirtual(), "Error: Only VirtualClients can utilize PerceiverMixin")

    self.detectableEntities = unique_set()      --Detectable
    self.perceivedEntities = unique_set()       --Perceived
    self.perceivedEntsTime = IterableDict()     --Last time perceived

    self:InitializePerception()

    self:AddTimedCallback( PerceiverMixin.UpdatePerception, PerceiverMixin.kUpdateInterval, true )

    assert( self:GetMixinConstants().kFieldOfView > 0 and self:GetMixinConstants().kFieldOfView <= 360, "Error: Invalid FieldOfView constant in PerceiverMixin" )

    --TEMP--  --TODO Wrap in verbose or debug-state
    table.insertunique( gBotViz_PlayerEntIds, self:GetId() )
    self._vizTrackingId = table.find(gBotViz_PlayerEntIds, self:GetId())

end

function PerceiverMixin:OnDestroy()
    Shared.DestroyCollisionObject(self.perceiveTrig)
    self.perceiveTrig = nil

    self.detectableEntities:Clear()
    self.detectableEntities = nil

    self.perceivedEntities:Clear()
    self.perceivedEntities = nil

    --TEMP--  --TODO Wrap in verbose or debug-state
    if self:GetId() == gBotPercepVisEntityId then
        gBotPercepVisEntityId = Entity.invalid
    end

    table.remove( gBotViz_PlayerEntIds, self._vizTrackingId )
end


function PerceiverMixin:InitializePerception()
    PROFILE("PerceiverMixin:__initmixin")

    if self.perceiveTrig then
        Shared.DestroyCollisionObject(self.perceiveTrig)
        self.perceiveTrig = nil
    end

    local sightRadius = self:GetMixinConstants().kPerceptionRadius
    local coords = self:GetCoords()

--FIXME Something about the Physics groups is preventing some Entities from colliding with below
--      Cysts, Drifters, MACs, ResourceNode, TechPoint
--      (Note: It's likely because some entities do NOT interact with triggers, will need to be enabled)
--None of the above Entity-types interact with the trigger sphere
    self.perceiveTrig = Shared.CreatePhysicsSphereBody(false, sightRadius, 0, coords)   --Note: the first param(dynamic) doesn't do a damn thing. Ignored in engine scope
    self.perceiveTrig:SetTriggerEnabled(true)
    self.perceiveTrig:SetCollisionEnabled(true) --?? Is this infact, NOT required?  ...having collider constantly update may ditry CollisionScene cells, constantly (bad)
    self.perceiveTrig:SetGroup(self:GetMixinConstants().kPhysicsGroup)
    self.perceiveTrig:SetGroupFilterMask(self:GetMixinConstants().kFilterMask)
    self.perceiveTrig:SetEntity(self)

    self.perceivedInterval = 
        self:GetMixinConstants().kPerceivedRetriggerDelay and 
            self:GetMixinConstants().kPerceivedRetriggerDelay or
            PerceiverMixin.kDefaultPerceiveRetriggerDelay

    self._selfId = self:GetId() --cache so it doesn't need to be called over and over
end

function PerceiverMixin:Reset()
    Log("PerceiverMixin:Reset()")
    self.detectableEntities:Clear()
    self.perceivedEntities:Clear()
    self.perceivedEntsTime:Clear()

    --Update world-space position of detection trigger-sphere
    self.perceiveTrig:SetPosition( self:GetOrigin(), true )

end

function PerceiverMixin:GetNumberOfDetectableEntities()
    return self.detectableEntities:GetCount()
end

function PerceiverMixin:GetNumberOfPerceivedEntities()
    return self.detectableEntities:GetCount()
end

function PerceiverMixin:GetDetectableEntityIds()
    return self.detectableEntities:GetList()
end

function PerceiverMixin:GetPerceivedEntityIds()
    return self.perceivedEntities:GetList()
end

function PerceiverMixin:GetDetectableEntities()
    local entities = { }
    for entId in self.detectableEntities:Iterate() do
        local ent = Shared.GetEntity(entId)
        if ent then
            table.insert(entities, ent)
        end
    end
    return entities
end

function PerceiverMixin:GetPerceivedEntities()
    local entities = {}
    for entId in self.perceivedEntities:Iterate() do
        local ent = Shared.GetEntity(entId)
        if ent then
            table.insert(entities, ent)
        end
    end
    return entities
end

function PerceiverMixin:GetPerceivedEntitiesWithTime()  --ideally, this should require usage of IterableDict on callee
    local entities = {}
    for entId in self.perceivedEntities:Iterate() do
        entities[entId] = self.perceivedEntsTime[entId]
    end 
    return entities --sort first?
end

--Note: we can't do any sort of "track-type", because the Entity (old)
--could be destroyed by the time this is called
function PerceiverMixin:OnEntityChange(oldId, newId)
    local oldEnt = oldId ~= nil and Shared.GetEntity(oldId) or nil

    local ignoredTypeOld = false
    if oldEnt then
        ignoredTypeOld = 
            (
                oldEnt:isa("Blip") or
                oldEnt:isa("MapBlip") or
                oldEnt:isa("Commander") or
                oldEnt:isa("Spectator") or
                oldEnt:isa("TeamSpectator")
            )
    end

    if not ignoredTypeOld and oldId ~= self._selfId then
        self.detectableEntities:Remove(oldId)
        self:FlushPerceivedEntity(oldId)
    end
end

function PerceiverMixin:GetIsDetectableEntity(entity)       --FIXME Change to table lookup? ...would have to use explicit list, :isa() isn't
    assert(entity, "Error: No trackable entity passed")
    
    return 
        ( 
            not entity:isa("Commander") and 
            not entity:isa("Spectator") and
            not entity:isa("TeamSpectator") and
            not entity:isa("Blip") and
            not entity:isa("MapBlip")
        ) and
        entity:GetId() ~= self._selfId
end

function PerceiverMixin:OnTriggerEntered(entity)
    PROFILE("PerceiverMixin:__initmixin")

    --Ideally, this would just be handled via Physics FilterMasks, but that's not always viable
    if not self:GetIsDetectableEntity(entity) then
        return
    end
    
    if self.detectableEntities:Insert(entity:GetId()) then
        --perception is handled in UpdatePerception callback
        if gBotPercepVisEntityId == self._selfId then
            Log("\t Entity#%s[%s] ENTERED %s perception radius", entity:GetId(), entity:GetClassName(), self.name)
        end
    end
end

function PerceiverMixin:OnTriggerExited(entity)
    PROFILE("PerceiverMixin:__initmixin")

    local exitEntId = entity:GetId()

    if self.detectableEntities:Remove(exitEntId) then
        if gBotPercepVisEntityId == self._selfId then
            Log("\t Entity#%s[%s] LEFT %s perception radius", exitEntId, entity:GetClassName(), self.name)
        end
    end

    --safety, ensure perceived list is updated
    self:FlushPerceivedEntity(exitEntId)
end

--Log _when_ we perceived an Entity, so we can know when our awareness is "stale" or not
function PerceiverMixin:PerceivedEntity(entity)
    local entityId = entity:GetId()

    self.perceivedEntities:Insert(entityId)
    self.perceivedEntsTime[entityId] = Shared.GetTime()

    self:OnPerceivedEntity(entity)    --trigger implementor callback
end

function PerceiverMixin:GetEntityPerceivedTime(entityId)
    return self.perceivedEntsTime[entityId]
end

function PerceiverMixin:FlushPerceivedEntity(entityId)
    if entityId then
        self.perceivedEntities:Remove(entityId)
        self.perceivedEntsTime[entityId] = nil
    end
end

--[[
Rando Thought:

Instead of tring to reinvent the wheel with Bots. We could make ALL target-acquisition routines use 
the entities list derived from THIS mixin ONLY and __nothing__ else.?! No more GetEntitiesWithTeam(GetEnemyTeam(self.teamNumber), kRadius)  etc.

- If done this route, target look-up would, effectively, be cached, per Bot!
- If done this way, there would be no need for ANY "GetEntitiesRadInRadiusBLAH" type calls, per Bot

***HOWEVER*** In order for above to work...ALL entities MUST be parsed by this routine (e.g. Cysts, ResourceNodes, etc., etc...)
- If ents are NOT flaged by this mixin, and ONLY targets from this list are used....would makes Bots UTTERYLY incapable of targeting X
  things which are NOT triggered by this.  ...yeesh, so...this means STATIC Ents may be a _BIG_ problem when it comes to "collisions"
- This would also complicate some scenarios, and we'd need "auto-add" to the list (e.g. Any structure under attack "broadcasts" its attacker, etc.)

...hmm, this ^ might not be worth the headache, maybe. We need more complete image of _exactly_ how Bots manage their relevant data.
--]]

--simple util function to determine the SoundEffect attentuation, based on distance
local kMaxHearingRange = 25
local kMaxHearingRangeSqr = kMaxHearingRange * kMaxHearingRange
--"fake" ambient sound level. AmbientSounds don't exists in Server context, let's fake it.
--Note ^: thing is...ambients _could_ be loaded by server, at least to generate a "Location Ambient Level" type value...hmmm
local kDefaultPseudoAmbientVolume = 0.1

--Minimum pseudo-effective volume of a SoundEffect to be heard
local kMinimumHearingAttenuation = 0.125

local function GetSoundFalloffVolume(vol, dist)
    if dist > kMaxHearingRange then
        return 0
    end
    --Compute fake sound falloff and "noise" from map ambient sounds
    local distFrac = math.min(math.max(dist / kMaxHearingRangeSqr, 0), 1)
    return ( vol * (1 - distFrac) ) - kDefaultPseudoAmbientVolume
end


local kDebugDrawTime = 0.2975    --tuned
--[[
Important: This function and normal run-time isn't bad, but if the debug mode is enabled, it takes a HUGE hit on
Server perf. Namely because _all_ of the debug-draw functions are sent out via network messages, which is a _lot_.
Thus, debug should not be used with anymore than 8 Bots, total. Any higher and the ServerWorld will respond so
slowly, client-predict frams will burst and a desync.

Note: Debug mode is only viable on localhost
--]]
function PerceiverMixin:UpdatePerception()
    PROFILE("PerceiverMixin:UpdatePerception")

    if not self:GetIsVirtual() then --Note: leaving this in, until 100% certain this _never_ gets call for actual clients
        Log("WARNING: PerceiverMixin update run for non-virtual Player[%s]!", self._selfId)
        return false
    end

    if self.GetIsAlive and not self:GetIsAlive() then
        return false    --stop cb
    end
    
    --Update world-space position of detection trigger-sphere
    self.perceiveTrig:SetPosition( self:GetOrigin(), true )

--TODO Try utilizing the GetIsInCone instead of all the FOV garbage, might be just as fast and more reliable

    local lookVec = GetNormalizedVector(self:GetViewCoords().zAxis)  --FIXME Needs a height added (simulate frustums, etc.)
    local selfEyePos = GetEntityEyePos(self)
    local percepFov = self:GetMixinConstants().kFieldOfView
    local percepRadius = self:GetMixinConstants().kPerceptionRadius
    local fovRads = math.rad(percepFov / 2)
    local angYaw = self:GetViewAngles().yaw
    local facing = selfEyePos + lookVec
    local time = Shared.GetTime()

    local function CanTriggerPerceived(entId)   --TODO Refactor away
        local lastPerceive = self.perceivedEntsTime[entId]
        return 
            lastPerceive == nil or
            ( lastPerceive ~= nil and lastPerceive + self.perceivedInterval <= time )
    end

    -- iterate backwards b/c sometimes callFunc can result in the entity being destroyed.
    for entId in self.detectableEntities:IterateBackwards() do
        local ent = Shared.GetEntity(entId)
        
        if not ent or (ent.GetIsAlive and not ent:GetIsAlive()) then
            --assume clean-up will happen elsewhere
            goto NEXT_ENT
        end

        local entOrg = ent.GetEngagementPoint and ent:GetEngagementPoint() or ent:GetOrigin()
        local toTarg = selfEyePos - entOrg

        --This means ent moved outside percepRadius during update interval(s). Skip it
        if toTarg:GetLength() > percepRadius then
            goto NEXT_ENT
        end

        toTarg:Normalize()
        local tarAng = GetAngleBetweenVectors(lookVec, toTarg)
        --FIXME appears to NOT be entirely taking self YAW into account (facing) ...math is wrong for this use-case
        -- not sure this handles left/right of FOV anyways, effectively speaking

        if tarAng >= fovRads then   --Check Vision--
                    
            --Shows in fov perceivable object
            if dbgDrawBotPerceptionRadius and gBotPercepVisEntityId == self._selfId then
                --Line to target
                DebugLine( selfEyePos, ent:GetOrigin(), kDebugDrawTime, 1, 1, 0, 1 )
            end

            if not self:GetCanPerceiveEntity(ent) then
                --incase of something falling outside perception, AFTER already being perceived
                --Note: this won't always occur, but is safe to run either way
                self.perceivedEntities:Remove(ent:GetId())
                goto NEXT_ENT
            end
            
            if CanTriggerPerceived(ent:GetId()) then
            --Only trigger perception on _first_ sighted, or sighted again after X interval
                self:PerceivedEntity(ent)
            end

        else                        --Check Hearing--

            --Note: this is much faster than polling for _all_ SoundEffects.
            --Note-Note: a LOT of sounds are not parented, so...this is likely not worth it, dammit.
            local numChildren = ent:GetNumChildren()
            if numChildren > 0 then
                for i = 0, ent:GetNumChildren() - 1 do  --...inner loop, yuck
                    local child = ent:GetChildAtIndex(i)
                    if child and child:isa("SoundEffect") then
                        if child:GetIsPlaying() then
                            local dist = (selfEyePos - child:GetOrigin()):GetLength()
                            if GetSoundFalloffVolume(child.volume, dist) > kMinimumHearingAttenuation then
                            --bleh, finally, yes we heard something. Add to and trigger Perceived
                                if CanTriggerPerceived(ent:GetId()) then
                                    self:PerceivedEntity(ent)
                                    goto NEXT_ENT --no point checking other children
                                end
                            end
                        end
                    end
                end
            end

            --safety check to auto-clean Perceived entities
            self:FlushPerceivedEntity(ent:GetId())

            --Shows "potential" perceivable object
            if dbgDrawBotPerceptionRadius and gBotPercepVisEntityId == self._selfId then
                --Line to target
                DebugLine( selfEyePos, ent:GetOrigin(), kDebugDrawTime, 1, 0, 0.8, 1 )
            end

        end

        ::NEXT_ENT::
    end

    if dbgDrawBotPerceptionRadius then

        --Visualize the potential perception radius and the fov of self
        if gBotPercepVisEntityId == self._selfId then
            
            --local lookVec2 = GetNormalizedVector(self:GetViewCoords().zAxis)
            local heading = selfEyePos + lookVec * percepRadius
            
            local fovLeft = Vector(math.sin(fovRads + angYaw), 0, math.cos(fovRads + angYaw))
            local fovRight = Vector(math.sin(-fovRads + angYaw), 0, math.cos(-fovRads + angYaw))
            
            local leftFar = selfEyePos + fovLeft * percepRadius
            local rightFar = selfEyePos + fovRight * percepRadius

            DebugLine( selfEyePos, heading, kDebugDrawTime, 1, 1, 1, 1 )   --Sight Line (center)

            DebugLine( selfEyePos, leftFar, kDebugDrawTime, 0,1,0,1 )        --Left FOV arc
            DebugLine( selfEyePos, rightFar, kDebugDrawTime, 1,0,0,1 )       --Right FOV arc

            local trigSphereOrg = self.perceiveTrig:GetPosition()
            DebugWireSphere( trigSphereOrg, percepRadius, kDebugDrawTime, 0, 0.6, 1, 0.75 )
            
        end

    end

    return true --keep callback alive
end


Event.Hook("Console_bv_percep", function()

    if not Shared.GetTestsEnabled() or not Shared.GetCheatsEnabled() then
        Shared.ConsoleCommand("tests 1")
        Shared.ConsoleCommand("cheats 1")
        Shared.ConsoleCommand("spectate")
    end

    if not Server then
        return
    end

    dbgDrawBotPerceptionRadius = not dbgDrawBotPerceptionRadius
    Log("|BOT-DEBUG|  Debug visualize Bot perception radius %s", ( dbgDrawBotPerceptionRadius and "ENABLED" or "DISABLED" ))
end)

Event.Hook("Console_bv_cycle", function()

    if not Server then
        return
    end

    if #gBotViz_PlayerEntIds == 0 then
        Log("No Bots found")
        return
    end

    if not dbgDrawBotPerceptionRadius then
        Shared.ConsoleCommand("botviz_perception")
    end

    if gBotPercepVisEntityId == Entity.invalid then
        gBotViz_ActiveVizIndex = 1
        gBotPercepVisEntityId = gBotViz_PlayerEntIds[1]
        Log("O___O   -    Displaying Bot[%s] perception", gBotPercepVisEntityId)
        return
    end

    local nIdx = gBotViz_ActiveVizIndex + 1
    if nIdx > #gBotViz_PlayerEntIds then
        nIdx = 1
    end

    if nIdx < gBotViz_ActiveVizIndex or nIdx > gBotViz_ActiveVizIndex then      --FIXME This is a train-wreck 
        gBotPercepVisEntityId = gBotViz_PlayerEntIds[nIdx]
        gBotViz_ActiveVizIndex = nIdx
        Log("O___O   -    Displaying Bot[%s] perception", gBotPercepVisEntityId)
    else
        Log("Only one Bot to display")
    end

end)

Event.Hook("Console_bv_list", function()

    if not Server then
        return
    end

    Print("\n Dump all PerceptionMixin tracked Entities...\n")
    for i = 1, #gBotViz_PlayerEntIds do
        local ent = Shared.GetEntity(gBotViz_PlayerEntIds[i])
        if ent then
            Print("\t Entity[%s] is a (%s)\n", gBotViz_PlayerEntIds[i], ent:GetClassName())
        else
            Print("\t NIL Slot for [%s]- This is a bug", gBotViz_PlayerEntIds[i])
        end
    end
end)

