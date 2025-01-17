-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\UpgradableMixin.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--
-- UpgradableMixin handles two forms of upgrades. There are the upgrades that it owns (upgrade1 - upgrade4).
-- It can also handle upgrading the entire entity to another tech Id independent of the upgrades it owns.
--
UpgradableMixin = CreateMixin(UpgradableMixin)
UpgradableMixin.type = "Upgradable"

UpgradableMixin.expectedCallbacks =
{
    SetTechId = "Sets the current tech Id of this entity.",
    GetTechId = "Returns the current tech Id of this entity."
}

UpgradableMixin.optionalCallbacks =
{
    OnPreUpgradeToTechId = "Called right before upgrading to a new tech Id.",
    OnGiveUpgrade = "Called to notify that an upgrade was given with the tech Id as the single parameter."
}

UpgradableMixin.networkVars =
{
    upgrade1 = "enum kTechId",
    upgrade2 = "enum kTechId",
    upgrade3 = "enum kTechId",
    upgrade4 = "enum kTechId",
    upgrade5 = "enum kTechId",
    upgrade6 = "enum kTechId",
}

function UpgradableMixin:__initmixin()
    
    PROFILE("UpgradableMixin:__initmixin")
    
    self.upgrade1 = kTechId.None
    self.upgrade2 = kTechId.None
    self.upgrade3 = kTechId.None
    self.upgrade4 = kTechId.None
    self.upgrade5 = kTechId.None
    self.upgrade6 = kTechId.None
    
end

function UpgradableMixin:GetHasUpgrade(techId)

    return techId ~= kTechId.None and (techId == self.upgrade1 or techId == self.upgrade2 or techId == self.upgrade3
                                       or techId == self.upgrade4 or techId == self.upgrade5 or techId == self.upgrade6)
    
end

function UpgradableMixin:GetUpgradeList()

    local list = { self.upgrade1, self.upgrade2, self.upgrade3, self.upgrade4, self.upgrade5, self.upgrade6 }
    
    for i = #list, 1 , -1 do
    
        local upgrade = list[i]
        local techTree = GetTechTree(self:GetTeamNumber())
        
        if upgrade == kTechId.None or ( techTree and not techTree:GetIsTechAvailable(upgrade) ) then
            table.remove(list, i)
        end
        
    end
    
    return list
    
end

function UpgradableMixin:GetUpgradeListName()

    local list = self:GetUpgradeList()
    local listName = { }
    
    for i, id in ipairs(list) do
        table.insert(listName, kTechId[id])
    end
    
    return listName
    
end

function UpgradableMixin:GetUpgrades()

    local upgrades = { }
    
    if self.upgrade1 ~= kTechId.None then
        table.insert(upgrades, self.upgrade1)
    end
    if self.upgrade2 ~= kTechId.None then
        table.insert(upgrades, self.upgrade2)
    end
    if self.upgrade3 ~= kTechId.None then
        table.insert(upgrades, self.upgrade3)
    end
    if self.upgrade4 ~= kTechId.None then
        table.insert(upgrades, self.upgrade4)
    end
    if self.upgrade5 ~= kTechId.None then
        table.insert(upgrades, self.upgrade5)
    end
    if self.upgrade6 ~= kTechId.None then
        table.insert(upgrades, self.upgrade6)
    end
    
    return upgrades
    
end

function UpgradableMixin:GiveUpgrade(techId) 

    local upgradeGiven = false
    
    if not self:GetHasUpgrade(techId) then
    
        if self.upgrade1 == kTechId.None then
        
            self.upgrade1 = techId
            upgradeGiven = true
            
        elseif self.upgrade2 == kTechId.None then
        
            self.upgrade2 = techId
            upgradeGiven = true
            
        elseif self.upgrade3 == kTechId.None then
        
            self.upgrade3 = techId
            upgradeGiven = true
            
        elseif self.upgrade4 == kTechId.None then
        
            self.upgrade4 = techId
            upgradeGiven = true
            
        elseif self.upgrade5 == kTechId.None then
        
            self.upgrade5 = techId
            upgradeGiven = true
            
        elseif self.upgrade6 == kTechId.None then
        
            self.upgrade6 = techId
            upgradeGiven = true
            
        end
        
        assert(upgradeGiven, "Entity already has the max of four upgrades.")
        
    end
    
    if upgradeGiven and self.OnGiveUpgrade then
        self:OnGiveUpgrade(techId)
    end
    
    return upgradeGiven
    
end

function UpgradableMixin:RemoveUpgrade(techId)

    local removed = false
    
    if self:GetHasUpgrade(techId) then
    
        if self.upgrade1 == techId then
        
            self.upgrade1 = kTechId.None
            removed = true
            
        elseif self.upgrade2 == techId then
        
            self.upgrade2 = kTechId.None
            removed = true
            
        elseif self.upgrade3 == techId then
        
            self.upgrade3 = kTechId.None
            removed = true
            
        elseif self.upgrade4 == techId then
        
            self.upgrade4 = kTechId.None
            removed = true
            
        elseif self.upgrade5 == techId then
        
            self.upgrade5 = kTechId.None
            removed = true
            
        elseif self.upgrade6 == techId then
        
            self.upgrade6 = kTechId.None
            removed = true
            
        end
        
    end
    
    return removed
    
end

function UpgradableMixin:Reset()

    self:ClearUpgrades()
    
end

function UpgradableMixin:OnKill()
    self:ClearUpgrades()
end

function UpgradableMixin:ClearUpgrades()

    self.upgrade1 = kTechId.None
    self.upgrade2 = kTechId.None
    self.upgrade3 = kTechId.None
    self.upgrade4 = kTechId.None
    self.upgrade5 = kTechId.None
    self.upgrade6 = kTechId.None
    
end