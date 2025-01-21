Script.Load("lua/Trigger.lua")

class 'AlienVent' (Location)

AlienVent.kMapName = "alien_vent"

local networkVars =
{
    timeLastUpdate = "time",
    enablePush = "boolean",
    pushForce = "float"
}

function AlienVent:OnInitialized()
    Location.OnInitialized(self)
    self:SetTriggerCollisionEnabled(true)

    self.entitiesInVent = {}
    self.timeLastUpdate = 0

    -- Initialize with default values if not set in editor
    self.enablePush = self.enablePush or false
    self.pushForce = self.pushForce or 10

    if Server then
        self:AddTimedCallback(AlienVent.UpdateVentEffects, 2)
    end
end

local function PushEntity(self, entity)
    if entity and entity:isa("Player") and not entity:isa("Commander") and entity:GetTeamNumber() == kMarineTeamType then
        -- Calculate push direction (opposite of player's current direction)
        local playerPos = entity:GetOrigin()
        local ventCenter = self:GetOrigin()
        local pushDir = (playerPos - ventCenter):GetUnit()

        -- Apply upward component to help "pop" them out
        pushDir.y = 0.3
        pushDir:Normalize()

        -- Get the entity off the ground if needed
        if entity.GetIsOnGround and entity:GetIsOnGround() then
            local extents = GetExtents(entity:GetTechId())
            if GetHasRoomForCapsule(extents, entity:GetOrigin() + Vector(0, extents.y + 0.2, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, nil, EntityFilterTwo(self, entity)) then
                entity:SetOrigin(entity:GetOrigin() + Vector(0, 0.2, 0))
            end

            entity.timeOfLastJump = Shared.GetTime()
            entity.onGroundNeedsUpdate = true
            entity.jumping = true
        end

        -- Apply the push force
        local velocity = pushDir * self.pushForce
        entity:SetVelocity(velocity)
    end
end

if Server then
    function AlienVent:UpdateVentEffects()
        local spawnedRupture = false
        for entityId, _ in pairs(self.entitiesInVent) do
            local entity = Shared.GetEntity(entityId)

            if entity and entity:GetIsAlive() then
                if entity:GetTeamNumber() == kMarineTeamType then
                    if self.enablePush then
                        PushEntity(self, entity)
                    else
                        -- Original vent behavior
                        if not spawnedRupture then
                            CreateEntity(Rupture.kMapName, entity:GetOrigin(), 2)
                            spawnedRupture = true
                        end

                        if entity:isa("JetpackMarine") then
                            entity:SetFuel(entity:GetFuel() - 0.5)
                        end

                        entity:SetWebbed(2, true)
                    end
                end
            else
                self.entitiesInVent[entityId] = nil
            end
        end

        return true
    end

    function AlienVent:OnTriggerEntered(entity, triggerEnt)
        Location.OnTriggerEntered(self, entity, triggerEnt)

        if entity and entity:GetIsAlive() then
            self.entitiesInVent[entity:GetId()] = true

            -- If push is enabled, immediately push marines
            if self.enablePush and entity:GetTeamNumber() == kMarineTeamType then
                PushEntity(self, entity)
            end
        end

        entity:SetGameEffectMask(kGameEffect.OnInfestation, true)
    end

    function AlienVent:OnTriggerExited(entity, triggerEnt)
        Location.OnTriggerExited(self, entity, triggerEnt)

        if entity then
            self.entitiesInVent[entity:GetId()] = nil
            entity:SetGameEffectMask(kGameEffect.OnInfestation, false)
        end
    end
end

Shared.LinkClassToMap("AlienVent", AlienVent.kMapName, networkVars)