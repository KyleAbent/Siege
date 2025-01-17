-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Marine\Grenade.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")

class 'Grenade' (PredictedProjectile)

--Any speed below this will freeze the grenade in place
Grenade.kMinVelocityToMove = 1

Grenade.kMapName = "grenade"
Grenade.kModelName = PrecacheAsset("models/marine/rifle/rifle_grenade.model")

--Grenade.kProjectileCinematic = PrecacheAsset("cinematics/marine/grenade.cinematic")

Grenade.kRadius = 0.05
Grenade.kDetonateRadius = 0.17
Grenade.kMinLifeTime = 0
Grenade.kClearOnImpact = false
Grenade.kClearOnEnemyImpact = true
Grenade.kNeedsHitEntity = true

local kGrenadeCameraShakeDistance = 15
local kGrenadeMinShakeIntensity = 0.02
local kGrenadeMaxShakeIntensity = 0.13

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function Grenade:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, DamageMixin)

    if Server then    
        self:AddTimedCallback(Grenade.TimedDetonateCallback, kGrenadeLifetime)        
    end
    
end

function Grenade:GetDeathIconIndex()
    return kDeathMessageIcon.Grenade
end

function Grenade:GetDamageType()
    return kGrenadeLauncherGrenadeDamageType
end

function Grenade:GetIsAffectedByWeaponUpgrades()
    return true
end

function Grenade:GetWeaponTechId()
    return kTechId.GrenadeLauncher
end

function Grenade:GetTechId()
    return self:GetWeaponTechId()
end

function Grenade:ProcessNearMiss( targetHit, endPoint )
    if targetHit and GetAreEnemies(self, targetHit) then
        if Server then
            self:Detonate( targetHit )
        end
        return true
    end
end

if Server then
        
    function Grenade:ProcessHit(targetHit, surface, normal, endPoint )

        if targetHit and GetAreEnemies(self, targetHit) then
            
            self:Detonate(targetHit, hitPoint )
                
        elseif self:GetVelocity():GetLength() > 2 then
            
            self:TriggerEffects("grenade_bounce")
            
        end
        
    end
  
    function Grenade:TimedDetonateCallback()
        self:Detonate()
    end
    
    function Grenade:Detonate(targetHit)
    
        -- Do damage to nearby targets.
        local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius)
        
        -- Remove grenade and add firing player.
        table.removevalue(hitEntities, self)
        
        -- full damage on direct impact
        if targetHit then
            table.removevalue(hitEntities, targetHit)
            self:DoDamage(kGrenadeLauncherGrenadeDamage, targetHit, self:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
        end

        RadiusDamage(hitEntities, self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius, kGrenadeLauncherGrenadeDamage, self)
        
        -- TODO: use what is defined in the material file
        local surface = GetSurfaceFromEntity(targetHit)
        
        local params = { surface = surface }
        params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis)
        
        if GetDebugGrenadeDamage() then
            DebugWireSphere( self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius, 0.65, 1, 0, 0, 1 )
        end

        self:TriggerEffects("grenade_explode", params)
        
        CreateExplosionDecals(self)
        TriggerCameraShake(self, kGrenadeMinShakeIntensity, kGrenadeMaxShakeIntensity, kGrenadeCameraShakeDistance)
        
        DestroyEntity(self)
        
    end
    
end

Shared.LinkClassToMap("Grenade", Grenade.kMapName, networkVars)
