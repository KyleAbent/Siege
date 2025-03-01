-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\ShiftAbility.lua
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'ShiftAbility' (StructureAbility)

function ShiftAbility:GetEnergyCost()
    return kDropStructureEnergyCost
end

function ShiftAbility:GetDropRange()
    return 3
end

function ShiftAbility:GetIsPositionValid(position, player, normal, lastClickedPosition, lastClickedPositionNormal, entity)
    local entities = GetEntitiesWithinRange("ScriptActor", position, 2)

    for _, entity in ipairs(entities) do
        if not entity:isa("Infestation") and not entity:isa("Babbler") and entity ~= player and (not entity.GetIsAlive or entity:GetIsAlive()) then
            return false
        end
    end

    return true
end

function ShiftAbility:GetPrimaryAttackDelay()
    return 1.0
end

function ShiftAbility:GetGhostModelName()
    return Shift.kModelName
end

function ShiftAbility:GetDropStructureId()
    return kTechId.Shift
end

function ShiftAbility:GetSuffixName()
    return "shift"
end

function ShiftAbility:GetDropClassName()
    return "Shift"
end

function ShiftAbility:GetDropMapName()
    return Shift.kMapName
end

function ShiftAbility:IsAllowed(player)
    return true
end