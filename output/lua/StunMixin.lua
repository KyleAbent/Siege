-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\StunMixin.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

StunMixin = CreateMixin(StunMixin)
StunMixin.type = "Stun"

StunMixin.optionalCallbacks =
{
    OnStun = "Called when a knockback is triggered in OnProcessMove/OnUpdate.",
    OnStunEnd = "Called when a knockback is over in OnProcessMove/OnUpdate.",
    GetIsStunAllowed = "Return true/false to limit stuns only to certain situations."
}

StunMixin.networkVars =
{
    stunTime = "private time"
}

function StunMixin:__initmixin()
    
    PROFILE("StunMixin:__initmixin")
    
    -- time stamp when stun ends
    self.stunTime = 0
    
end

function StunMixin:SetStun(duration)

    local allowed = true
    
    if self.GetIsStunAllowed then
        allowed = self:GetIsStunAllowed()
    end
    
    if allowed then
    
        self.stunTime = Shared.GetTime() + duration
        self.timeLastStun = Shared.GetTime()
        
    end
    
end

function StunMixin:GetIsStunned()
    return Shared.GetTime() < self.stunTime
end

function StunMixin:GetCrouchCameraAnimationAllowed(result)
    result.allowed = result.allowed and not self:GetIsStunned()
end

local function SharedUpdate(self)

    if self.wasStunned ~= self:GetIsStunned() then
    
        self.wasStunned = self:GetIsStunned()
        
        if self.wasStunned then
        
            if self.OnStun then
                self:OnStun(self:GetRemainingStunTime())
            end
            
        else
        
            if self.OnStunEnd then
                self:OnStunEnd()
            end
            
            self.stunTime = 0
            
        end
        
    end
    
end

function StunMixin:GetRemainingStunTime()
    return self.stunTime - Shared.GetTime()
end

function StunMixin:OnProcessMove(input)
    SharedUpdate(self)
end

if Server then

    function StunMixin:OnUpdate(dt)
        PROFILE("StunMixin:OnUpdate")
        SharedUpdate(self)
    end
    
end