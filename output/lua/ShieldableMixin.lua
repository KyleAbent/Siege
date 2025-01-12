--
-- lua\ShieldableMixin.lua
--

-- Todo: Rename
ShieldableMixin = CreateMixin( Shieldable )
ShieldableMixin.type = "Shieldable"

kOverShieldMaxCapRatio = 1.5
kOverShieldDuration = 0.5
kOverShieldDecayDuration = 4.5

-- Arbitrary, but in fact it's the same value as the max mucous shield amount
local kMaxShield = 250

ShieldableMixin.networkVars =
{
    overShielded = "boolean",
    overShieldRemaining = string.format("float (0 to %f by 1)", kMaxShield),
    lastOverShield = "private time",
    decayStart = "private time",
}

function ShieldableMixin:__initmixin()

    PROFILE("ShieldableMixin:__initmixin")

    self.overShielded = false
    self.overShieldRemaining = 0
    self.lastOverShield = 0
    self.decayStart = 0

    if Server then
        self.lastDecayTime = 0
    end

end

function ShieldableMixin:ClearShield()

    self.overShielded = false
    self.overShieldRemaining = 0

end

function ShieldableMixin:OnDestroy()

    if self:GetHasOverShield() then
        self:ClearShield()
    end

end

function ShieldableMixin:GetHasOverShield()
    return self.overShielded
end

function ShieldableMixin:GetOverShieldAmount()
    return self.overShieldRemaining
end

-- Todo: Create getter in each class
local kShieldClassNameScalars
function ShieldableMixin:GetMaxOverShieldAmount()
    if not kShieldClassNameScalars then
        kShieldClassNameScalars = {
            [Skulk.kMapName] = kBiteLeapVampirismScalar,
            [Gorge.kMapName] = kSpitVampirismScalar,
            [Lerk.kMapName] = kLerkBiteVampirismScalar,
            [Fade.kMapName] = kSwipeVampirismScalar,
            [Onos.kMapName] = kGoreVampirismScalar
        }
    end

    local maxRatio = kOverShieldMaxCapRatio
    local maxHealth = self:GetMaxHealth()
    local className = self:GetMapName()
    local scalar = kShieldClassNameScalars[className] * 3 or 0 -- * 3 to get scalar for 3 shells

    return maxRatio * maxHealth * scalar
end

function ShieldableMixin:GetOverShieldPercentage()
    return (self:GetOverShieldAmount() / self:GetMaxOverShieldAmount())
end

-- Overshield total duration
function ShieldableMixin:GetOverShieldDuration()
    return kOverShieldDuration + kOverShieldDecayDuration -- Ghoul: static? If so create new constant
end

function ShieldableMixin:GetOverShieldDecayDuration()
    return kOverShieldDecayDuration
end

function ShieldableMixin:GetOverShieldTimeRemaining()
    local percentLeft = 0
    if self.overShielded and self.lastOverShield > 0 then

        local startTime = self.lastOverShield
        local endTime = self.decayStart + kOverShieldDecayDuration

        local totalDuration = endTime - startTime
        local timeElapsed = Shared.GetTime() - self.lastOverShield

        percentLeft = 1 - Clamp( timeElapsed / totalDuration, 0.0, 1.0 )
    end

    return percentLeft
end

function ShieldableMixin:ShieldComputeDamageOverrideMixin(attacker, damage, damageType, hitPoint, overshieldDamage)

    overshieldDamage = overshieldDamage or 0
    local preShield = self.overShieldRemaining
    if self:GetHasOverShield() then
        if damage < self.overShieldRemaining then
            self.overShieldRemaining = math.max(self.overShieldRemaining - damage, 0)
            damage = 0
        else
            damage = math.max(damage - self.overShieldRemaining, 0)
            self.overShieldRemaining = 0
        end

        if self.overShieldRemaining == 0 then
            self.overShielded = false
        end
    end

    return damage, ((preShield - self.overShieldRemaining) + overshieldDamage)
end

-- Apply shield decay
local function SharedUpdate(self)
    if Server then
        self.overShielded = self.overShieldRemaining > 0

        if not self.overShielded then -- No shield left. Nothing to do
            return
        end

        local now = Shared:GetTime()
        if now < self.decayStart then -- decay hasn't started. Nothing to do yet
            return
        end

        -- Apply decay for time passed
        local elapsed = now - self.lastDecayTime
        local decayDuration = self:GetOverShieldDecayDuration()
        local decayPerSecond = self.overShieldStartAmount / decayDuration
        local decayAmount = elapsed * decayPerSecond

        self.overShieldRemaining = math.max(self.overShieldRemaining - decayAmount, 0) -- Todo: Check for float pointer precession issues
        self.lastDecayTime = now


    end
end

function ShieldableMixin:OnProcessMove(input)
    SharedUpdate(self) -- why local? Todo: Look into using move delta for time diff to support artificial time speed
end

if Server then

    function ShieldableMixin:AddOverShield(shieldAmount)
        local time = Shared.GetTime()

        self.overShielded = true
        self.overShieldRemaining = Clamp(self.overShieldRemaining + shieldAmount, 0, self:GetMaxOverShieldAmount())
        self.overShieldStartAmount = self.overShieldRemaining
        self.lastOverShield = time

        -- Reset decay timers Todo: Make method
        local overshieldDuration = self:GetShellLevel() * kOverShieldDuration
        self.decayStart = self.lastOverShield + overshieldDuration
        self.lastDecayTime = self.decayStart
    end

end
