
function Gorge:GetHealthbarOffset()
    return 1
end

function Gorge:OverrideInput(input)
    local activeWeapon = self:GetActiveWeapon()

    -- Only let the active build menu handle input
    if activeWeapon then
        if activeWeapon:isa("DropStructureAbility") then
            -- Handle the original DropStructureAbility
            input = activeWeapon:OverrideInput(input)
--             Print("ActiveWeapon is DropStructureAbility")
        elseif activeWeapon:isa("DropStructureAbilityExtra") then
            -- Handle the new DropStructureAbilityExtra
--             Print("ActiveWeapon is DropStructureAbilityExtra")
            input = activeWeapon:OverrideInput(input)
        end
    end

    return Player.OverrideInput(self, input)
end


function Gorge:GetShowGhostModel()

    local weapon = self:GetActiveWeapon()
    if weapon and ( weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbilityExtra") ) then
        return weapon:GetShowGhostModel()
    end

    return false

end

function Gorge:GetGhostModelOverride()

    local weapon = self:GetActiveWeapon()
    if weapon and ( weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbilityExtra") ) then
        return weapon:GetGhostModelName(self)
    end

end

function Gorge:GetGhostModelTechId()

    local weapon = self:GetActiveWeapon()
    if weapon and ( weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbilityExtra") )  then
        return weapon:GetGhostModelTechId()
    end

end

function Gorge:GetGhostModelCoords()

    local weapon = self:GetActiveWeapon()
    if weapon and ( weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbilityExtra") )  then
        return weapon:GetGhostModelCoords()
    end

end

function Gorge:GetLastClickedPosition()

    local weapon = self:GetActiveWeapon()
    if weapon and ( weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbilityExtra") )  then
        return weapon.lastClickedPosition
    end

end

function Gorge:GetIsPlacementValid()

    local weapon = self:GetActiveWeapon()
    if weapon and ( weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbilityExtra") )  then
        return weapon:GetIsPlacementValid()
    end

end

function Gorge:GetIgnoreGhostHighlight()

    local weapon = self:GetActiveWeapon()
    if weapon and ( weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbilityExtra") ) and weapon.GetIgnoreGhostHighlight then
        return weapon:GetIgnoreGhostHighlight()
    end

end