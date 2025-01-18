Script.Load("lua/Trigger.lua")

class 'AlienVent' (Location)

AlienVent.kMapName = "alien_vent"

local networkVars =
{
    timeLastUpdate = "time"
}

function AlienVent:OnInitialized()
    Location.OnInitialized(self)
    self:SetTriggerCollisionEnabled(true)

    self.entitiesInVent = {}
    self.timeLastUpdate = 0

    if Server then
        self:AddTimedCallback(AlienVent.UpdateVentEffects, 2)
    end
end

if Server then
    function AlienVent:UpdateVentEffects()
        spawnedRupture = False
        for entityId, _ in pairs(self.entitiesInVent) do
            local entity = Shared.GetEntity(entityId)

            if entity and entity:GetIsAlive() then
                if entity:GetTeamNumber() == kMarineTeamType then
                    if not spawnedRupture then
                        --Will always apply to first person who entered I guess
                        CreateEntity(Rupture.kMapName, entity:GetOrigin(), 2)
                        spawnedRupture = true
                    end
                    -- Direct jetpack fuel modification
                    if entity:isa("JetpackMarine") then
                        entity:SetFuel(entity:GetFuel() - 0.5)
                    end

                    -- Apply slow effect
                    entity:SetWebbed(2, true)

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
        end
        entity:SetGameEffectMask(kGameEffect.OnInfestation, true)
    end

    function AlienVent:OnTriggerExited(entity, triggerEnt)
        Location.OnTriggerExited(self, entity, triggerEnt)

        if entity then
            self.entitiesInVent[entity:GetId()] = nil

            if entity:GetTeamNumber() == kMarineTeamType then
            end
            entity:SetGameEffectMask(kGameEffect.OnInfestation, false)
        end
    end
end

Shared.LinkClassToMap("AlienVent", AlienVent.kMapName, networkVars)