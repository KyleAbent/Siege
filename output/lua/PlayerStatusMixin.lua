-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/PlayerStatusMixin.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- Keeps track status for certain hp/armor altering sources, that don't have a explicit state (just damage) otherwise.
-- Used for GUIPlayerStatus
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/IterableDict.lua")

PlayerStatusMixin = CreateMixin(PlayerStatusMixin)
PlayerStatusMixin.type = "PlayerStatus"

PlayerStatusMixin.defaultConstants =
{
    kDamageSourceStatusSustain = 0.5
}

PlayerStatusMixin.networkVars =
{
    isInNerveGas = "private boolean",
    isInSporeCloud = "private boolean",
    isBeingWelded = "private boolean",
}

local kDoersToStateMap =
{
    ["NerveGasCloud"] = "isInNerveGas",
    ["SporeCloud"] = "isInSporeCloud",
}

local kWeldDoersToStateMap =
{
    ["Welder"] = "isBeingWelded",
    ["Exo"] = "isBeingWelded", -- self repair, maybe have a separate icon in the future
    ["MAC"] = "isBeingWelded",
}

function PlayerStatusMixin:__initmixin()
    if Server then
        self.lastDoerTimes = IterableDict()
        self.activeDoers = IterableDict()
        self:AddTimedCallback(self.CheckExpireStates, self:GetMixinConstants().kDamageSourceStatusSustain)
    end
end

if Server then

    function PlayerStatusMixin:OnTakeDamage(damage, attacker, doer, point)

        if doer and doer.GetClassName then
            local doerName = doer:GetClassName()
            if  kDoersToStateMap[doerName] then
                self.lastDoerTimes[doerName] = Shared.GetTime()
                self:StateOn(doerName)
            end
        end

    end
    
    function PlayerStatusMixin:OnArmorWelded(doer)

        if doer and doer.GetClassName then
            local doerName = doer:GetClassName()
            if kWeldDoersToStateMap[doerName] then
                self.lastDoerTimes[doerName] = Shared.GetTime()
                self:StateOn(doerName)
            end
        end
        
    end
    
    function PlayerStatusMixin:StateOn(doerName)

        local netVarName = kDoersToStateMap[doerName] or kWeldDoersToStateMap[doerName]
        if netVarName then
            self[netVarName] = true
            self.activeDoers[doerName] = true
        end
        
    end
    
    function PlayerStatusMixin:CheckExpireStates()
        local now = Shared.GetTime()
        local ttl = self:GetMixinConstants().kDamageSourceStatusSustain
        for k, v in pairs(self.activeDoers) do
            local lastTime = self.lastDoerTimes[k]
            if (now - lastTime) > ttl then
                local netvarName = kDoersToStateMap[k] or kWeldDoersToStateMap[k]
                self[netvarName] = false
                self.activeDoers[k] = nil
            end
        end
        return true
    end
    
end

if Client then

    function PlayerStatusMixin:GetIsDoerActive(doerClassName)
        local netvarName = kDoersToStateMap[doerClassName] or kWeldDoersToStateMap[doerClassName]
        return self[netvarName] or false
    end
    
end


