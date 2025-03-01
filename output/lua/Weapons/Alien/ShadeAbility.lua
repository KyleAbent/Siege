-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\ShadeAbility.lua
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'ShadeAbility' (StructureAbility)

function ShadeAbility:GetEnergyCost()
    return kDropStructureEnergyCost
end

function ShadeAbility:GetDropRange()
    return 3
end

function ShadeAbility:GetIsPositionValid(position, player, normal, lastClickedPosition, lastClickedPositionNormal, entity)
    local entities = GetEntitiesWithinRange("ScriptActor", position, 2)

    for _, entity in ipairs(entities) do
        if not entity:isa("Infestation") and not entity:isa("Babbler") and entity ~= player and (not entity.GetIsAlive or entity:GetIsAlive()) then
            return false
        end
    end

    return true
end

function ShadeAbility:GetPrimaryAttackDelay()
    return 1.0
end

function ShadeAbility:GetGhostModelName()
    return Shade.kModelName
end

function ShadeAbility:GetDropStructureId()
    return kTechId.Shade
end

function ShadeAbility:GetSuffixName()
    return "shade"
end

function ShadeAbility:GetDropClassName()
    return "Shade"
end

function ShadeAbility:GetDropMapName()
    return Shade.kMapName
end

function ShadeAbility:IsAllowed(player)
    return true
end