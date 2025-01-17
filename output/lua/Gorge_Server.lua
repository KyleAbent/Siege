-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Gorge_Server.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function Gorge:InitWeapons()

    Alien.InitWeapons(self)

    self:GiveItem(SpitSpray.kMapName)
    self:GiveItem(DropStructureAbility.kMapName)
    
    self:SetActiveWeapon(SpitSpray.kMapName)
    
end

function Gorge:GetTierTwoTechId()
    return kTechId.BabblerAbility
end

function Gorge:GetTierThreeTechId()
    return kTechId.BileBomb
end

function Gorge:OnCommanderStructureLogin(_)

    DestroyEntity(self.slideLoopSound)
    self.slideLoopSound = nil

end

function Gorge:OnCommanderStructureLogout(_)

    self.slideLoopSound = Server.CreateEntity(SoundEffect.kMapName)
    self.slideLoopSound:SetAsset(Gorge.kSlideLoopSound)
    self.slideLoopSound:SetParent(self)

end

function Gorge:OnOverrideOrder(order)
    
    if(order:GetType() == kTechId.Default and GetOrderTargetIsHealTarget(order, self:GetTeamNumber())) then
    
        order:SetType(kTechId.Heal)
        
    end
    
end
