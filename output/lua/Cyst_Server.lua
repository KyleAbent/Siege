--=============================================================================
--
-- lua\Cyst_Server.lua
--
-- Created by Mats Olsson (mats.olsson@matsotech.se) and
-- Charlie Cleveland (charlie@unknownworlds.com)
--
-- Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
--
--============================================================================

Cyst.kThinkTime = 1

-- How long we can be without a confirmation impulse before we disconnect
Cyst.kImpulseDisconnectTime = 15
Cyst.kTouchRange = 0.9 -- Max model extents for "touch" uncloaking

function Cyst:GetCanAutoBuild()
    return true
end

-- NOTE: Cysts entities are destroyed here yet, otherwise infestation would immediately vanish.
-- InfestationMixin handles allowing the entity to be destroyed, which is then handled in
-- Cyst:OnUpdate(). -Beige
function Cyst:OnKill()

    self:TriggerEffects("death")
    self.connected = false
    self:SetModel(nil)

    -- Report killed cyst
    StatsUI_AddExportBuilding(self:GetTeamNumber(),
        self.GetTechId and self:GetTechId(),
        self:GetId(),
        self:GetOrigin(),
        StatsUI_kLifecycle.Destroyed,
        self:GetIsBuilt())


end

function Cyst:GetSendDeathMessageOverride()
    return false
end

function Cyst:OnEntityChange(entityId, newEntityId)
    
    if self.parentId == entityId then
        self.parentId = newEntityId or Entity.invalidId
    end

end


function Cyst:GetMaturityRate()
    return kCystMaturationTime
end

function Cyst:GetStarvationMaturityRate()
    return Cyst.kMaturityLossTime
end

function Cyst:ServerUpdate()

    if not self:GetIsAlive() then
        return
    end

    if self.bursted then
        self.bursted = self.timeBursted + Cyst.kBurstDuration > Shared.GetTime()
    end

    local now = Shared.GetTime()

    if now > self.nextUpdate then
        self.nextUpdate = self.nextUpdate + Cyst.kThinkTime
    end

end

function Cyst:OnUpdate(deltaTime)

    PROFILE("Cyst:OnUpdate")

    ScriptActor.OnUpdate(self, deltaTime)

    if self:GetIsAlive() then

        self:ServerUpdate(deltaTime)
    else

        local destructionAllowedTable = { allowed = true }
        if self.GetDestructionAllowed then
            self:GetDestructionAllowed(destructionAllowedTable)
        end

        if destructionAllowedTable.allowed then
            DestroyEntity(self)
        end

    end

end

function Cyst:UpdateInfestationCloaking()
    PROFILE("Cyst:UpdateInfestationCloaking")

    self.cloakInfestation = self.timeUncloaked < self.timeCloaked and self.timeCloaked > Shared.GetTime()

    return self:GetIsAlive()
end

function Cyst:ScanForNearbyEnemy()

    self.lastDetectedTime = self.lastDetectedTime or 0
    if self.lastDetectedTime + kDetectInterval < Shared.GetTime() then

        local done = false

        -- Check shades in range, and stop if a shade is in range and is cloaked.
        if not done then
            for _, shade in ipairs(GetEntitiesForTeamWithinRange("Shade", self:GetTeamNumber(), self:GetOrigin(), Shade.kCloakRadius)) do
                if shade:GetIsCloaked() then
                    done = true
                    break
                end
            end
        end

        -- Finally check if the cysts have players in range.
        if not done and #GetEntitiesForTeamWithinRange("Player", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kCystDetectRange) > 0 then
            self:TriggerUncloak()
            done = true
        end

        self.lastDetectedTime = Shared.GetTime()
    end

    return self:GetIsAlive()
end
