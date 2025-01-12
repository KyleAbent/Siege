-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\MaturityMixin.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    Responsible for letting alien structures become maturity. Determine "Mature Fraction" which
--    increases over time, 0.0 - 1.0.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

MaturityMixin = CreateMixin(MaturityMixin)
MaturityMixin.type = "Maturity"

kMaturityLevel = enum({ 'Newborn', 'Grown', 'Mature' })

-- 1 minute until structure is fully grown
local kDefaultMaturityRate = 60

MaturityMixin.networkVars =
{
    maturityFraction = "float (0 to 1 by 0.01)" -- gets only update once per second to keep network traffic low
}

MaturityMixin.expectedMixins =
{
    Live = "MaturityMixin will adjust max health/armor over time.",
}

MaturityMixin.optionalCallbacks = 
{
    GetMaturityRate = "Return individual maturity rate in seconds.",
    GetMatureMaxHealth = "Return individual maturity health.",
    GetMatureMaxArmor = "Return individual maturity armor.",
    OnMaturityComplete = "Callback once 100% maturity has been reached."
}

local function GetMaturityRate(self)

    if self.GetMaturityRate then
        return (self:GetMaturityRate())
    end

    return kDefaultMaturityRate

end

function MaturityMixin:__initmixin()
    
    PROFILE("MaturityMixin:__initmixin")

    self.maturityFraction = 0
    
    if Server then

        self._maturityFraction = 0 -- server only maturity faction that get updated every tick
        self.maturityHealth = 0
        self.maturityArmor = 0
        self.timeMaturityLastUpdate = 0
        self.updateMaturity = false
        self.maturityStartTime = 0

        if self.startsMature then
            self:SetMature()
        end
        
    end

    if HasMixin(self, "Model") then
        self:AddTimedCallback(MaturityMixin.OnMaturityUpdate, 0.1)
    end
    
end

function MaturityMixin:OnConstructionComplete()
    self.updateMaturity = true
end

function MaturityMixin:OnKill()
    self.updateMaturity = false
end

function MaturityMixin:GetIsMature()
    return self:GetMaturityFraction() == 1
end

function MaturityMixin:GetMaturityFraction()
    return Server and self._maturityFraction or self.maturityFraction
end

function MaturityMixin:GetMaxMaturityMistBonus()
    return kNutrientMistMaturitySpeedup + kMaturityBuiltSpeedup
end

function MaturityMixin:GetMaturityThresholdRate()
    local updateRate = GetMaturityRate(self)
    local baseMaxRate = (1 / updateRate) * self:GetMaxMaturityMistBonus()

    return baseMaxRate * kMaturitySoftcapThreshold
end

function MaturityMixin:GetMaturityMistBonus()

    local mistBonus = 0

    mistBonus = ConditionalValue(HasMixin(self, "Catalyst") and self:GetIsCatalysted(), kNutrientMistMaturitySpeedup, 0)
    mistBonus = mistBonus + ( (not HasMixin(self, "Construct") or self:GetIsBuilt()) and kMaturityBuiltSpeedup or 0 )

    return mistBonus

end

function MaturityMixin:GetMaturityLevel()
    local maturityFraction = self:GetMaturityFraction()

    if maturityFraction < 0.5 then
        return kMaturityLevel.Newborn
    elseif maturityFraction < 1 then
        return kMaturityLevel.Grown
    else
        return kMaturityLevel.Mature
    end
end

function MaturityMixin:GetMaturitySoftCappedAmount(amount)

    local averageRate = (self._maturityFraction + amount) / (Shared.GetTime() - self.maturityStartTime)
    local rateThreshold = self:GetMaturityThresholdRate()

    if averageRate > rateThreshold then

        local uncappedFraction = rateThreshold / averageRate
        local cappedFraction = 1 - uncappedFraction

        amount = (amount * uncappedFraction) + (amount * cappedFraction * kMaturityCappedEfficiency)
    end

    return amount
end

if Server then

    local function GetMaturityHealth(self, fraction)

        local maxHealth = LookupTechData(self:GetTechId(), kTechDataMaxHealth, 100)
        -- use 1.5 times normal health as default
        local maturityHealth = maxHealth * 1.5

        if self.GetMatureMaxHealth then
            maturityHealth = self:GetMatureMaxHealth()
        end

        local newMatureHealth = (maturityHealth - maxHealth) * self:GetMaturityFraction()
        -- Health is a interger value so we have to make sure the delta is always an int as well to not loose data
        local healthDelta = math.floor(newMatureHealth - self.maturityHealth)

        self.maturityHealth = self.maturityHealth + healthDelta

        return self:GetMaxHealth() + healthDelta

    end

    local function GetMaturityArmor(self, fraction)

        local maxArmor = LookupTechData(self:GetTechId(), kTechDataMaxArmor, 0)
        -- use 1.5 times normal armor as default
        local maturityArmor = maxArmor * 1.5

        if self.GetMatureMaxArmor then
            maturityArmor = self:GetMatureMaxArmor()
        end

        local newMatureArmor = (maturityArmor - maxArmor) * fraction
        -- Armor is a interger value so we have to make sure the delta is always an int as well to not loose data
        local armorDelta = math.floor(newMatureArmor - self.maturityArmor)

        self.maturityArmor = self.maturityArmor + armorDelta
        return self:GetMaxArmor() + armorDelta

    end

    function MaturityMixin:UpdateMaturity(forceUpdate)

        local fraction = self._maturityFraction
        if not forceUpdate and self.maturityFraction == fraction then return end

        self.maturityFraction = fraction

        -- health/armor fractions are maintained by using "Adjust" functions
        local newMaxHealth = GetMaturityHealth(self, fraction)
        self:AdjustMaxHealth(newMaxHealth)

        local newMaxArmor = GetMaturityArmor(self, fraction)
        self:AdjustMaxArmor(newMaxArmor)

    end


    function MaturityMixin:OnMaturityUpdate(deltaTime)

        PROFILE("MaturityMixin:OnMaturityUpdate")

        local isMature = false
        if self.updateMaturity then

            if self.maturityStartTime == 0 then
                self.maturityStartTime = Shared.GetTime()
            end

            local updateRate = GetMaturityRate(self)
            local mistBonus = self:GetMaturityMistBonus()

            local maturityRate = (1 / updateRate) * mistBonus
            local maturityIncrease = maturityRate * deltaTime
            maturityIncrease = self:GetMaturitySoftCappedAmount(maturityIncrease)

            self._maturityFraction = math.min(self._maturityFraction + maturityIncrease, 1)

            isMature = self._maturityFraction == 1

            if isMature and self.OnMaturityComplete then
                self:OnMaturityComplete()
            end

            -- to prevent too much network spam from happening we update only every second the max health
            if self.maturityFraction ~= self._maturityFraction and (isMature or self.timeMaturityLastUpdate + 1 < Shared.GetTime()) then

                self:UpdateMaturity()
                self.timeMaturityLastUpdate = Shared.GetTime()

            end

        end

        -- Stop processing maturity once we reach full maturity.
        return not isMature
    end

    -- For testing.
    function MaturityMixin:SetMature()
        self.maturityFraction = 0.99
    end

    function MaturityMixin:ResetMaturity()

        self.maturityHealth = 0
        self.maturityArmor = 0
        self.maturityFraction = 0
        self._maturityFraction = 0
        self.updateMaturity = true

    end
    
    -- Add some maturity to this object, measured in seconds
    function MaturityMixin:AddMaturity(amount)

        if self.updateMaturity then

            -- Misnomer... NOT a rate, but 1/rate... grrr
            local secondsToMature = GetMaturityRate(self)
            local fractionalChange = amount / secondsToMature
            fractionalChange = self:GetMaturitySoftCappedAmount(fractionalChange)

            local maturityFractionBefore = self._maturityFraction
            self._maturityFraction = Clamp(self._maturityFraction + fractionalChange, 0, 1)

            -- Don't update if it didn't change (eg already full).
            if maturityFractionBefore ~= self._maturityFraction then

                -- update immediately, despite the update throttle, since this is likely the result of a
                -- player's actions.
                self:UpdateMaturity()
                self.timeMaturityLastUpdate = Shared.GetTime()

            end
        end
    end

end

if Client then
    function MaturityMixin:OnMaturityUpdate()

        PROFILE("MaturityMixin:OnMaturityUpdate")

        -- TODO: maturity effects, shaders
        local model = self:GetRenderModel()
        if model then
            local fraction = self:GetMaturityFraction()
            model:SetMaterialParameter("maturity", fraction)
        end

        return kUpdateIntervalLow

    end
end
