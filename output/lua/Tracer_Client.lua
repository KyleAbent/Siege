--=============================================================================
--
-- lua\Weapons\Marine\Tracer_Client.lua
--
-- Created by Charlie Cleveland (charlie@unknownworlds.com)
-- Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
--
-- A client-side tracer object that disappears when it hits anything.
--
--=============================================================================

class 'Tracer'

Tracer.kMapName             = "tracer"

kDefaultTracerEffectName = PrecacheAsset("cinematics/marine/tracer.cinematic")
kMinigunTracerEffectName = PrecacheAsset("cinematics/marine/exo_tracer.cinematic")
kRailgunTracerEffectName = PrecacheAsset("cinematics/marine/railgun/tracer.cinematic")
kRailgunTracerResidueEffectName = PrecacheAsset("cinematics/marine/railgun/tracer_residue.cinematic")
kSpikeTracerEffectName = PrecacheAsset("cinematics/alien/tracer.cinematic")
kSpikeTracerResidueEffectName = PrecacheAsset("cinematics/alien/tracer_residue.cinematic")
kSpikeTracerFirstPersonResidueEffectName = PrecacheAsset("cinematics/alien/1p_tracer_residue.cinematic")

local kTracerResidueDistance = 0.75

function Tracer:OnDestroy()

    if self.tracerEffect then
    
        Client.DestroyCinematic(self.tracerEffect)
        self.tracerEffect = nil
        
    end
    
end

function Tracer:OnUpdate(deltaTime)

    PROFILE("Tracer:OnUpdate")

    self.timePassed = self.timePassed + deltaTime
    
    if not self.tracerCoords then
    
        self.tracerCoords = Coords()
        self.tracerCoords.origin = self.startPoint
        self.tracerCoords.zAxis = self.tracerVelocity:GetUnit()
        self.tracerCoords.yAxis = self.tracerCoords.zAxis:GetPerpendicular()
        self.tracerCoords.xAxis = Math.CrossProduct(self.tracerCoords.yAxis, self.tracerCoords.zAxis)
        
    end
    
    self.tracerCoords.origin = self.startPoint + self.timePassed * self.tracerVelocity

    if self.tracerEffect then
        self.tracerEffect:SetCoords(self.tracerCoords)
    end
    
    if self.residueEffectName then
        
        if not self.lastResidueOrigin then
            self.lastResidueOrigin = Vector(self.startPoint)
        end
        
        if (self.lastResidueOrigin - self.tracerCoords.origin):GetLength() > kTracerResidueDistance and (self.lifetime - self.timePassed > 0.005) then
        
            VectorCopy(self.tracerCoords.origin, self.lastResidueOrigin)
            local residueCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
            residueCinematic:SetCinematic(self.residueEffectName)
            residueCinematic:SetCoords(self.tracerCoords)
            
        end
        
    end
   
end

function Tracer:GetTimeToDie()
    
    -- Another NaN check here, just in case something slipped through.
    return self.lifetime ~= self.lifetime or self.timePassed >= self.lifetime
    
end

function BuildTracer(startPoint, endPoint, velocity, effectName, residueEffectName)
    
    -- Check for NaNs, or input that could cause a NaN. Lua really doesn't like these... causes
    -- WEIRD issues later with iterating the list of tracers (sometimes it just... SKIPS the
    -- iteration entirely!)
    if not VectorIsFinite(startPoint) or
       not VectorIsFinite(endPoint) or
       not VectorIsFinite(velocity) or
       velocity:GetLengthSquared() <= 0 then
       
       return nil
    end
    
    local tracer = Tracer()
    
    --All tracers can interact with the world collision scene, but are not culled when not rendered last frame
    --the third parameter prevents the particle emitter from being culled(not updated) when the creation point
    --is not alreacy in camera frustum.
    tracer.tracerEffect = Client.CreateCinematic(RenderScene.Zone_Default, false, true)
    
    tracer.tracerEffect:SetCinematic(effectName)
    tracer.tracerEffect:SetCoords(Coords.GetLookIn( startPoint, GetNormalizedVector(endPoint - startPoint) ))
    tracer.tracerEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
    tracer.effectName = effectName
    tracer.residueEffectName = residueEffectName
    
    tracer.tracerVelocity = Vector(0, 0, 0)
    VectorCopy(velocity, tracer.tracerVelocity)
    
    tracer.startPoint = Vector(0, 0, 0)
    VectorCopy(startPoint, tracer.startPoint)
    
    -- Calculate how long we should live so we can animate to that target
    tracer.lifetime = (endPoint - startPoint):GetLength() / velocity:GetLength()
    tracer.timePassed = 0
    
    -- Put a hard-limit on the lifetime of a tracer.  This is more than generous, and also serves
    -- to protect against NaNs and Infs.
    tracer.lifetime = math.min(kMaxTracerLifetime, tracer.lifetime)
    return tracer
    
end
