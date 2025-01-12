-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\DeathTrigger.lua
--
--    Created by:   Brian Cronin (brian@unknownworlds.com)
--
-- Kill entity that touches this.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TechMixin.lua")
Script.Load("lua/Mixins/SignalListenerMixin.lua")

class 'DeathTrigger' (Trigger)

DeathTrigger.kMapName = "death_trigger"

local networkVars =
{
}

AddMixinNetworkVars(TechMixin, networkVars)

-- These are not compatible with global kDamageType and kTeamType!
DeathTrigger.kTeamType = enum({ "Both", "Marine", "Alien" })
DeathTrigger.kDamageType = enum({ "Normal", "Gas", "Fire", "Electric" })

function DeathTrigger:KillEntity(entity)

    if Server and HasMixin(entity, "Live") and entity:GetIsAlive() and entity:GetCanDie(true) then
    
        local direction = GetNormalizedVector(entity:GetModelOrigin() - self:GetOrigin())
        entity:Kill(self, self, self:GetOrigin(), direction)
        
    end
    
end

function DeathTrigger:KillAllInTrigger()

    for _, entity in ipairs(self:GetEntitiesInTrigger()) do
        self:KillEntity(entity)
    end
    
end

function DeathTrigger:OnCreate()

    Trigger.OnCreate(self)
    
    InitMixin(self, TechMixin)
    InitMixin(self, SignalListenerMixin)
    
    self.enabled = true
    self.nextExtraFunctionTime = 0

    self:RegisterSignalListener(self.KillAllInTrigger, "kill")
end

function DeathTrigger:GetDamageOverTimeIsEnabled()
    return self.damageOverTime ~= nil and self.damageOverTime > 0
end

function DeathTrigger:GetTeamType()
    return self.teamType
end

function DeathTrigger:GetDamageType()
    return self.damageType
end

function DeathTrigger:OnInitialized()

    Trigger.OnInitialized(self)
    
    self:SetTriggerCollisionEnabled(true)
    
end

if Server then

    function DeathTrigger:DoDamageOverTime(entity)

        if HasMixin(entity, "Live") then
            local deltaTime = self._deltaTime or 0
            local damage = self.damageOverTime * deltaTime
            local teamType = self:GetTeamType()

            if teamType == self.kTeamType.Both or teamType == nil then
                if entity:isa("Exo") then
                    entity:TakeDamage(damage, self, self, nil, nil, damage, 0, kDamageType.Normal, true)
                else
                    entity:TakeDamage(damage, self, self, nil, nil, 0, damage, kDamageType.Normal, true)
                end
            elseif teamType == self.kTeamType.Marine then
                if entity:isa("Marine") then
                    entity:TakeDamage(damage, self, self, nil, nil, 0, damage, kDamageType.Normal, true)
                elseif entity:isa("Exo") then
                    entity:TakeDamage(damage, self, self, nil, nil, damage, 0, kDamageType.Normal, true)
                end
            elseif teamType == self.kTeamType.Alien and entity:isa("Alien") then
                entity:TakeDamage(damage, self, self, nil, nil, 0, damage, kDamageType.Normal, true)
            end

            if self.nextExtraFunctionTime < Shared.GetTime() then
                local damageType = self:GetDamageType()

                local params =
                {
                    effecthostcoords = entity:GetCoords(),
                    damagetype = damageType
                }

                entity:TriggerEffects("damage_trigger", params)

                if damageType == self.kDamageType.Fire then
                    if entity.SetOnFire then
                        entity:SetOnFire(self, self)
                    end
                elseif damageType == self.kDamageType.Electric then
                    if entity.SetElectrified then
                        entity:SetElectrified(kElectrifiedDuration / 2)
                    end
                end

                self.nextExtraFunctionTime = Shared.GetTime() + 2
            end

        end

    end

    function DeathTrigger:DamageUpdate(deltaTime)

        if self:GetNumberOfEntitiesInTrigger() > 0 then
            self._deltaTime = deltaTime -- Used by DoDamageOverTime
            self:ForEachEntityInTrigger(self.DoDamageOverTime)
            self._deltaTime = nil

            return true -- Keep callback active
        end

        self.callbackEnabled = false
        return false -- Remove callback

    end

    function DeathTrigger:OnTriggerEntered(enterEnt)
        if not self.enabled then return end

        if self:GetDamageOverTimeIsEnabled() then
            if self.callbackEnabled then return end

            self.callbackEnabled = true
            self:AddTimedCallback(self.DamageUpdate, kRealTimeUpdateRate)
        else
            self:KillEntity(enterEnt)
        end
    end

end

Shared.LinkClassToMap("DeathTrigger", DeathTrigger.kMapName, networkVars)