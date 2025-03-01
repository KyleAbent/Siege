-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\CragAbility.lua
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'CragAbility' (StructureAbility)

function CragAbility:GetEnergyCost()
    return kDropStructureEnergyCost
end

function CragAbility:GetDropRange()
    return 3
end

function CragAbility:GetIsPositionValid(position, player, normal, lastClickedPosition, lastClickedPositionNormal, entity)
    local entities = GetEntitiesWithinRange("ScriptActor", position, 2)

    for _, entity in ipairs(entities) do
        if not entity:isa("Infestation") and not entity:isa("Babbler") and entity ~= player and (not entity.GetIsAlive or entity:GetIsAlive()) then
            return false
        end
    end

    return true
end

function CragAbility:GetPrimaryAttackDelay()
    return 1.0
end

function CragAbility:GetGhostModelName()
    return Crag.kModelName
end

function CragAbility:GetDropStructureId()
    return kTechId.Crag
end

function CragAbility:GetSuffixName()
    return "crag"
end

function CragAbility:GetDropClassName()
    return "Crag"
end

function CragAbility:GetDropMapName()
    return Crag.kMapName
end

function CragAbility:IsAllowed(player)
    return true
end