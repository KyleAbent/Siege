-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\WhipAbility.lua
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'WhipAbility' (StructureAbility)

function WhipAbility:GetEnergyCost()
    return kDropStructureEnergyCost
end

function WhipAbility:GetDropRange()
    return 3
end

function WhipAbility:GetIsPositionValid(position, player, normal, lastClickedPosition, lastClickedPositionNormal, entity)
    local entities = GetEntitiesWithinRange("ScriptActor", position, 2)

    for _, entity in ipairs(entities) do
        if not entity:isa("Infestation") and not entity:isa("Babbler") and entity ~= player and (not entity.GetIsAlive or entity:GetIsAlive()) then
            return false
        end
    end

    return true
end

function WhipAbility:GetPrimaryAttackDelay()
    return 1.0
end

function WhipAbility:GetGhostModelName()
    return Whip.kModelName
end

function WhipAbility:GetDropStructureId()
    return kTechId.Whip
end

function WhipAbility:GetSuffixName()
    return "whip"
end

function WhipAbility:GetDropClassName()
    return "Whip"
end

function WhipAbility:GetDropMapName()
    return Whip.kMapName
end

function WhipAbility:IsAllowed(player)
    return true
end