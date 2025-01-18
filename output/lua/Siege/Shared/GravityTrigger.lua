Script.Load("lua/Trigger.lua")

class 'GravityTrigger' (Location)

GravityTrigger.kMapName = "gravity_section"

local networkVars =
{
    timeLastUpdate = "time"
}

function GravityTrigger:OnInitialized()
    Location.OnInitialized(self)
    self:SetTriggerCollisionEnabled(true)
end

if Server then

    function GravityTrigger:OnTriggerEntered(entity, triggerEnt)
        Location.OnTriggerEntered(self, entity, triggerEnt)

        if entity and entity:GetIsAlive() then
            if entity.SetGravity then
                entity:SetGravity(0.10)
            end
        end
    end

    function GravityTrigger:OnTriggerExited(entity, triggerEnt)
        Location.OnTriggerExited(self, entity, triggerEnt)
        if entity then
            if entity.SetGravity then
                entity:SetGravity(1)
            end
        end
    end
end

Shared.LinkClassToMap("GravityTrigger", GravityTrigger.kMapName, networkVars)