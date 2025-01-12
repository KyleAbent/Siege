--
-- lua\MucousableMixin.lua
--

MucousableMixin = CreateMixin( Mucousable )
MucousableMixin.type = "Mucousable"

local kMaxShield = 250

MucousableMixin.networkVars =
{
    mucousShield = "boolean",
    shieldRemaining = string.format("float (0 to %f by 1)", kMaxShield),
    lastMucousShield = "private time",
}

function MucousableMixin:__initmixin()
    
    PROFILE("MucousableMixin:__initmixin")
    
    self.mucousShield = false
    self.shieldRemaining = 0
    self.lastMucousShield = 0
    
end

function MucousableMixin:ClearShield()

    self.mucousShield = false
    self.shieldRemaining = 0    
    
end

function MucousableMixin:OnDestroy()

    if self:GetHasMucousShield() then
        self:ClearShield()
    end
    
end

function MucousableMixin:GetHasMucousShield()
    return self.mucousShield
end

function MucousableMixin:GetMuscousShieldAmount()
    return self.shieldRemaining
end

function MucousableMixin:GetMaxShieldAmount()

    if self:isa("Skulk") then
        return math.floor(math.min(self:GetBaseHealth() * kMucousShieldPercent, kMaxShield))
    else
        -- Yes, this uses babbler shield percentage, but the intended change is to match mucous to babbler shield...
        local mucousShieldPercent = self.GetBabblerShieldPercentage and self:GetBabblerShieldPercentage() or kBabblerShieldPercent
        return math.min(math.round(self:GetBaseHealth() * mucousShieldPercent), kBabblerShieldMaxAmount)
    end

end

function MucousableMixin:GetShieldPercentage()
    return (self.shieldRemaining / self:GetMaxShieldAmount())
end

function MucousableMixin:GetShieldTimeRemaining()
    local percentLeft = 0

    if self.mucousShield and self.lastMucousShield > 0 then
        percentLeft = Clamp( math.abs( (self.lastMucousShield + kMucousShieldDuration) - Shared.GetTime() ) / kMucousShieldDuration, 0.0, 1.0 )
    end

    return percentLeft
end

function MucousableMixin:ComputeDamageOverrideMixin(attacker, damage, damageType, hitPoint, overshieldDamage)

    overshieldDamage = overshieldDamage or 0
    local preShield = self.shieldRemaining
    if self:GetHasMucousShield() then

        if damage < self.shieldRemaining then
            self.shieldRemaining = math.max(self.shieldRemaining - damage, 0)
            damage = 0
        else
            damage = math.max(damage - self.shieldRemaining, 0)
            self.shieldRemaining = 0
        end

        if self.shieldRemaining == 0 then
            self.mucousShield = false
        end
    end

    local mucousDamage = preShield - self.shieldRemaining
    local totalOvershieldDamage = mucousDamage + overshieldDamage

    if gMucousDebug then
        Log("Mucous Debug [MucousableMixin:ComputeDamageOverrideMixin] - Damage: %f, Mucous Damage: %f, Overshield Total Damage: %f",
                damage, mucousDamage, totalOvershieldDamage)
    end

    return damage, totalOvershieldDamage
end
    
local function SharedUpdate(self)
    if Server then
        self.mucousShield = self.lastMucousShield + kMucousShieldDuration >= Shared.GetTime() and self.shieldRemaining > 0
        if not self.mucousShield and self.shieldRemaining > 0 then
            self.shieldRemaining = 0
        end
    end
end

function MucousableMixin:OnProcessMove(input)   
    SharedUpdate(self)
end

if Server then

    function MucousableMixin:SetMucousShield()

        -- Electrified effect prevents mucous.
        if self.GetElectrified and self:GetElectrified() then
            return
        end

        -- Hallucinations shouldn't have mucous applied to them
        if HasMixin(self, "PlayerHallucination") or self:isa("Hallucination") then
            return
        end

        local time = Shared.GetTime()
        if self.lastMucousShield + kMucousShieldCooldown < time then

            self.shieldRemaining = self:GetMaxShieldAmount()
            self.mucousShield = true
            self.lastMucousShield = time

        end
    end
    
end
