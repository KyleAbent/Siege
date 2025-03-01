-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\DropStructureAbilityExtra.lua
--
-- Advanced structures for Gorge
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/WhipAbility.lua")
Script.Load("lua/Weapons/Alien/CragAbility.lua")
Script.Load("lua/Weapons/Alien/ShiftAbility.lua")
Script.Load("lua/Weapons/Alien/ShadeAbility.lua")

class 'DropStructureAbilityExtra' (Ability)

local kMaxStructuresPerType = 20
local kDropCooldown = 1

DropStructureAbilityExtra.kMapName = "drop_structure_ability_extra"

PrecacheAsset("sound/NS2.fev/alien/gorge/create_fail")
local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")

DropStructureAbilityExtra.kSupportedStructures = { WhipAbility, CragAbility, ShiftAbility, ShadeAbility }

local networkVars =
{
    numWhipsLeft = string.format("private integer (0 to %d)", kMaxStructuresPerType),
    numCragsLeft = string.format("private integer (0 to %d)", kMaxStructuresPerType),
    numShiftsLeft = string.format("private integer (0 to %d)", kMaxStructuresPerType),
    numShadesLeft = string.format("private integer (0 to %d)", kMaxStructuresPerType),
}

function DropStructureAbilityExtra:GetAnimationGraphName()
    return kAnimationGraph
end

function DropStructureAbilityExtra:GetActiveStructure()

    if self.activeStructure == nil then
        return nil
    else
        return DropStructureAbilityExtra.kSupportedStructures[self.activeStructure]
    end

end

function DropStructureAbilityExtra:OnCreate()

    Ability.OnCreate(self)

    self.dropping = false
    self.mouseDown = false
    self.activeStructure = nil

    -- for GUI
    self.numWhipsLeft = 0
    self.numCragsLeft = 0
    self.numShiftsLeft = 0
    self.numShadesLeft = 0
    self.lastClickedPosition = nil
    self.lastClickedPositionNormal = nil

end

function DropStructureAbilityExtra:GetDeathIconIndex()
    return kDeathMessageIcon.Consumed
end

function DropStructureAbilityExtra:SetActiveStructure(structureNum)

    self.activeStructure = structureNum
    self.lastClickedPosition = nil
    self.lastClickedPositionNormal = nil

end

function DropStructureAbilityExtra:GetHasDropCooldown()
    return self.timeLastDrop ~= nil and self.timeLastDrop + kDropCooldown > Shared.GetTime()
end

function DropStructureAbilityExtra:GetSecondaryTechId()
    return kTechId.Spray
end

function DropStructureAbilityExtra:GetNumStructuresBuilt(techId)

    if techId == kTechId.Whip then
        return self.numWhipsLeft
    end

    if techId == kTechId.Crag then
        return self.numCragsLeft
    end

    if techId == kTechId.Shift then
        return self.numShiftsLeft
    end

    if techId == kTechId.Shade then
        return self.numShadesLeft
    end

    -- unlimited
    return -1
end

function DropStructureAbilityExtra:GetHUDSlot()
    return 5
end

function DropStructureAbilityExtra:OnPrimaryAttack(player)

    if Client then

        if self.activeStructure
                and not self.dropping
                and not self.mouseDown then

            self.mouseDown = true

            if player:GetEnergy() >= self:GetEnergyCost() then

                if self:PerformPrimaryAttack(player) then
                    self.dropping = true
                end

            else
                player:TriggerInvalidSound()
            end

        end

    end

end

function DropStructureAbilityExtra:OnPrimaryAttackEnd()

    if not Shared.GetIsRunningPrediction() then

        if Client and self.dropping then
            self:OnSetActive()
        end

        self.dropping = false
        self.mouseDown = false
        self.menuActive = false
    end

end

function DropStructureAbilityExtra:GetIsDropping()
    return self.dropping
end

function DropStructureAbilityExtra:GetEnergyCost()
    local activeStructure = self:GetActiveStructure()
    if activeStructure then
        return activeStructure:GetEnergyCost()
    end

    return kDropStructureEnergyCost
end

function DropStructureAbilityExtra:GetDamageType()
    return kHealsprayDamageType
end

function DropStructureAbilityExtra:GetHasSecondary(player)
    return true
end

function DropStructureAbilityExtra:OnSecondaryAttack(player)
    if player then
        -- Don't switch to the previous weapon if it's the other build menu
        if self.previousWeaponMapName and
           player:GetWeapon(self.previousWeaponMapName) and
           self.previousWeaponMapName ~= DropStructureAbility.kMapName then
            player:SetActiveWeapon(self.previousWeaponMapName)
        else
            -- Default to healspray if we're coming from the other build menu
            local healspray = player:GetWeapon("spit_spray")
            if healspray then
                player:SetActiveWeapon(healspray:GetMapName())
            end
        end
    end
end

function DropStructureAbilityExtra:GetSecondaryEnergyCost()
    return 0
end

function DropStructureAbilityExtra:PerformPrimaryAttack(player)

    if self.activeStructure == nil then
        return false
    end

    local success = false

    -- Ensure the current location is valid for placement.
    local coords, valid, _, normal = self:GetPositionForStructure(player:GetEyePos(), player:GetViewCoords().zAxis, self:GetActiveStructure(), self.lastClickedPosition, self.lastClickedPositionNormal)
    local secondClick = true

    if LookupTechData(self:GetActiveStructure().GetDropStructureId(), kTechDataSpecifyOrientation, false) then
        secondClick = self.lastClickedPosition ~= nil
    end

    if secondClick then

        if valid then

            -- Ensure they have enough resources.
            local cost = GetCostForTech(self:GetActiveStructure().GetDropStructureId())
            if player:GetResources() >= cost and not self:GetHasDropCooldown() then

                local message = BuildGorgeAdvancedStructureMessage(player:GetEyePos(), player:GetViewCoords().zAxis, self.activeStructure, self.lastClickedPosition, self.lastClickedPositionNormal)
                Client.SendNetworkMessage("GorgeBuildAdvancedStructure", message, true)
                Print("DropStructureAbilityExtra sending GorgeBuildAdvancedStructure for structure: " .. self.activeStructure)
                self.timeLastDrop = Shared.GetTime()
                success = true

            end

        end

        self.lastClickedPosition = nil
        self.lastClickedPositionNormal = nil

    elseif valid then
        self.lastClickedPosition = Vector(coords.origin)
        self.lastClickedPositionNormal = normal

    end

    if not valid then
        player:TriggerInvalidSound()
    end

    return success

end

function DropStructureAbilityExtra:DropStructure(player, origin, direction, structureAbility, lastClickedPosition, lastClickedPositionNormal)

    -- If we have enough resources
    if Server then

        local coords, valid, onEntity = self:GetPositionForStructure(origin, direction, structureAbility, lastClickedPosition, lastClickedPositionNormal)
        local techId = structureAbility:GetDropStructureId()

        local maxStructures = -1

        if not LookupTechData(techId, kTechDataAllowConsumeDrop, false) then
            maxStructures = LookupTechData(techId, kTechDataMaxAmount, 0)
        end

        valid = valid and self:GetNumStructuresBuilt(techId) ~= maxStructures -- -1 is unlimited

        local cost = LookupTechData(structureAbility:GetDropStructureId(), kTechDataCostKey, 0)
        local enoughRes = player:GetResources() >= cost
        local energyCost = structureAbility:GetEnergyCost()
        local enoughEnergy = player:GetEnergy() >= energyCost

        if valid and enoughRes and structureAbility:IsAllowed(player) and enoughEnergy and not self:GetHasDropCooldown() then

            -- Create structure
            local structure = self:CreateStructure(coords, player, structureAbility)

            if structure then

                structure:SetOwner(player)

                if HasMixin(structure, "ClogFall") then
                    if onEntity then
                        if onEntity:isa("Clog") then
                            onEntity:ConnectToClog(structure)
                        elseif structure:isa("Clog") and onEntity:isa("Web") then
                            onEntity:ConnectToClog(structure)
                        else
                            structure.fallWaiting = 0.0
                            structure:SetUpdates(true, kDefaultUpdateRate)
                        end
                    else
                        -- touching level, therefore can never move again, as the level doesn't move.
                        structure.doneFalling = true
                    end
                end

                player:GetTeam():AddGorgeStructure(player, structure)

                -- Check for space
                if structure:SpaceClearForEntity(coords.origin) then

                    local angles = Angles()
                    angles:BuildFromCoords(coords)
                    structure:SetAngles(angles)

                    if structure.SetVariant then
                        local client = player:GetClient()
                        if client and client.variantData then
                            -- We don't need variant handling for advanced structures
                        end
                    end

                    if structure.OnCreatedByGorge then
                        structure:OnCreatedByGorge()
                    end

                    player:AddResources(-cost)

                    player:DeductAbilityEnergy(energyCost)
                    player:TriggerEffects("spit_structure", {effecthostcoords = Coords.GetLookIn(origin, direction)} )

                    if structureAbility.OnStructureCreated then
                        structureAbility:OnStructureCreated(structure, lastClickedPosition)
                    end

                    self.timeLastDrop = Shared.GetTime()

                    return true

                else

                    player:TriggerInvalidSound()
                    DestroyEntity(structure)

                end

            else
                player:TriggerInvalidSound()
            end

        else

            if not valid then
                player:TriggerInvalidSound()
            elseif not enoughRes then
                player:TriggerInvalidSound()
            end

        end

    end

    return true

end

function DropStructureAbilityExtra:OnDropStructure(origin, direction, structureIndex, lastClickedPosition, lastClickedPositionNormal)
    local player = self:GetParent()

    if player then
        local structureAbility = DropStructureAbilityExtra.kSupportedStructures[structureIndex]
        if structureAbility then
            self:DropStructure(player, origin, direction, structureAbility, lastClickedPosition, lastClickedPositionNormal)
            Print("[DropStructureAbilityExtra] OnDropStructure called with structureIndex: " .. structureIndex)
        Print("Structure type: " .. (structureAbility and structureAbility:GetDropMapName() or "unknown"))
        end
    end
end

local function RemoveSupply(self, player, structure)


        local team = player:GetTeam()
        if team and team.RemoveSupplyUsed then

            team:RemoveSupplyUsed(LookupTechData(self.techId, kTechDataSupply, 0))
            structure.supplyAdded = false

        end

end

function DropStructureAbilityExtra:CreateStructure(coords, player, structureAbility, lastClickedPosition)
    local created_structure = structureAbility:CreateStructure(coords, player, lastClickedPosition)
    if created_structure then
        return created_structure
    else
        local structure = CreateEntity(structureAbility:GetDropMapName(), coords.origin, player:GetTeamNumber())
        if HasMixin(structure, "Supply") then RemoveSupply(self, player, structure) end
        if HasMixin(structure, "Builder") then structure:SetBuilder(player) end
        return structure
    end
end

local function FilterBabblersAndTwo(ent1, ent2)
    return function (test) return test == ent1 or test == ent2 or test:isa("Babbler") end
end

-- Given a gorge player's position and view angles, return a position and orientation
-- for structure. Used to preview placement via a ghost structure and then to create it.
-- Also returns bool if it's a valid position or not.
function DropStructureAbilityExtra:GetPositionForStructure(startPosition, direction, structureAbility, lastClickedPosition, lastClickedPositionNormal)

    PROFILE("DropStructureAbilityExtra:GetPositionForStructure")

    local validPosition = false
    local range = structureAbility:GetDropRange(lastClickedPosition)
    local origin = startPosition + direction * range
    local player = self:GetParent()

    -- Trace short distance in front
    local trace = Shared.TraceRay(player:GetEyePos(), origin, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, FilterBabblersAndTwo(player, self))

    local displayOrigin = trace.endPoint

    -- If we hit nothing, trace down to place on ground
    if trace.fraction == 1 then
        origin = startPosition + direction * range
        trace = Shared.TraceRay(origin, origin - Vector(0, range, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, FilterBabblersAndTwo(player, self))
    end

    -- If it hits something, position on this surface (must be the world or another structure)
    if trace.fraction < 1 then

        if trace.entity == nil then
            validPosition = true
        elseif trace.entity:isa("Infestation") then
            validPosition = true
        end

        displayOrigin = trace.endPoint
    end

    -- Can only be built on infestation
--     local requiresInfestation = true --LookupTechData(structureAbility.GetDropStructureId(), kTechDataRequiresInfestation)
    if not GetIsPointOnInfestation(displayOrigin) then
--         if self:GetActiveStructure().OverrideInfestationCheck then
--             validPosition = self:GetActiveStructure():OverrideInfestationCheck(trace)
--         else
        validPosition = false
--         end

    end

--     --Valid requires inability to palce in siege
--     if validPosition and GetWhereIsSiege(origin) then
--         validPosition = false
--     end

    -- Don't allow placing above or below us and don't draw either
    local structureFacing = Vector(direction)

    if math.abs(Math.DotProduct(trace.normal, structureFacing)) > 0.9 then
        structureFacing = trace.normal:GetPerpendicular()
    end

    -- Coords.GetLookIn will prioritize the direction when constructing the coords,
    -- so make sure the facing direction is perpendicular to the normal so we get
    -- the correct y-axis.
    local perp = Math.CrossProduct( trace.normal, structureFacing )
    structureFacing = Math.CrossProduct( perp, trace.normal )

    local coords = Coords.GetLookIn( displayOrigin, structureFacing, trace.normal )

    if structureAbility.ModifyCoords then
        structureAbility:ModifyCoords(coords, lastClickedPosition, trace.normal, player)
    end

    -- Don't allow dropped structures to go too close to techpoints and resource nozzles
    if GetPointBlocksAttachEntities(displayOrigin) then
        validPosition = false
    end

    if not structureAbility:GetIsPositionValid(displayOrigin, player, trace.normal, lastClickedPosition, lastClickedPositionNormal, trace.entity) then
        validPosition = false
    end

    -- perform a final check to ensure the gorge isn't trying to build from inside a clog.
    if GetIsPointInsideClogs(player:GetEyePos()) then
        validPosition = false
    end

    return coords, validPosition, trace.entity, trace.normal

end

function DropStructureAbilityExtra:OnDraw(player, previousWeaponMapName)

    Ability.OnDraw(self, player, previousWeaponMapName)

    self.previousWeaponMapName = previousWeaponMapName
    self.dropping = false
    self.activeStructure = nil

end

function DropStructureAbilityExtra:OnTag(tagName)
    if tagName == "shoot" then
        self.dropping = false
    end
end

function DropStructureAbilityExtra:OnUpdateAnimationInput(modelMixin)

    PROFILE("DropStructureAbilityExtra:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("ability", "chamber")

    local activityString = "none"
    if self.dropping then
        activityString = "primary"
    end
    modelMixin:SetAnimationInput("activity", activityString)

end

function DropStructureAbilityExtra:ProcessMoveOnWeapon(input)

    -- Show ghost if we're able to create structure, and if menu is not visible
    local player = self:GetParent()
    if player and player:GetIsAlive() then

        if Server then

            local team = player:GetTeam()
            local numAllowedWhips = LookupTechData(kTechId.Whip, kTechDataMaxAmount, -1)
            local numAllowedCrags = LookupTechData(kTechId.Crag, kTechDataMaxAmount, -1)
            local numAllowedShifts = LookupTechData(kTechId.Shift, kTechDataMaxAmount, -1)
            local numAllowedShades = LookupTechData(kTechId.Shade, kTechDataMaxAmount, -1)

            if numAllowedWhips >= 0 then
                self.numWhipsLeft = team:GetNumDroppedGorgeStructures(player, kTechId.Whip)
            end

            if numAllowedCrags >= 0 then
                self.numCragsLeft = team:GetNumDroppedGorgeStructures(player, kTechId.Crag)
            end

            if numAllowedShifts >= 0 then
                self.numShiftsLeft = team:GetNumDroppedGorgeStructures(player, kTechId.Shift)
            end

            if numAllowedShades >= 0 then
                self.numShadesLeft = team:GetNumDroppedGorgeStructures(player, kTechId.Shade)
            end

        end

    end

end

function DropStructureAbilityExtra:GetShowGhostModel()
    return self.activeStructure ~= nil and not self:GetHasDropCooldown()
end

function DropStructureAbilityExtra:GetGhostModelCoords()
    return self.ghostCoords
end

function DropStructureAbilityExtra:GetIsPlacementValid()
    return self.placementValid
end

function DropStructureAbilityExtra:GetIgnoreGhostHighlight()
    if self.activeStructure ~= nil and self:GetActiveStructure().GetIgnoreGhostHighlight then
        return self:GetActiveStructure():GetIgnoreGhostHighlight()
    end

    return false

end

function DropStructureAbilityExtra:GetGhostModelTechId()

    if self.activeStructure == nil then
        return nil
    else
        return self:GetActiveStructure():GetDropStructureId()
    end

end

function DropStructureAbilityExtra:GetGhostModelName(player)

    if self.activeStructure ~= nil and self:GetActiveStructure().GetGhostModelName then
        return self:GetActiveStructure():GetGhostModelName(self)
    end

    return nil

end

if Client then

    function DropStructureAbilityExtra:OnProcessIntermediate(input)

        local player = self:GetParent()
        local viewDirection = player:GetViewCoords().zAxis

        if player and self.activeStructure then

            self.ghostCoords, self.placementValid = self:GetPositionForStructure(player:GetEyePos(), viewDirection, self:GetActiveStructure(), self.lastClickedPosition, self.lastClickedPositionNormal)

            if player:GetResources() < LookupTechData(self:GetActiveStructure():GetDropStructureId(), kTechDataCostKey) then
                self.placementValid = false
            end

        end

    end

    function DropStructureAbilityExtra:CreateBuildMenu()

        if not self.buildMenu then
            self.buildMenu = GetGUIManager():CreateGUIScript("GUIGorgeBuildMenuExtra")
        end

    end

    function DropStructureAbilityExtra:DestroyBuildMenu()

        if self.buildMenu ~= nil then

            GetGUIManager():DestroyGUIScript(self.buildMenu)
            self.buildMenu = nil

        end

    end

    function DropStructureAbilityExtra:OnDestroy()

        self:DestroyBuildMenu()
        Ability.OnDestroy(self)

    end

    function DropStructureAbilityExtra:OnKillClient()
        self.menuActive = false
    end

    function DropStructureAbilityExtra:OnDrawClient()

        Ability.OnDrawClient(self)

        -- We need this here in case we switch to it via Prev/NextWeapon keys

        -- Do not show menu for other players or local spectators.
        local player = self:GetParent()
        if player:GetIsLocalPlayer() and self:GetActiveStructure() == nil and Client.GetIsControllingPlayer() then
            self.menuActive = true
        end

    end

    local function UpdateGUI(self, player)

        local localPlayer = Client.GetLocalPlayer()
        if localPlayer == player then
            self:CreateBuildMenu()
        end

        if self.buildMenu then
            self.buildMenu:SetIsVisible(player and localPlayer == player and player:isa("Gorge") and self.menuActive and not HelpScreen_GetHelpScreen():GetIsBeingDisplayed() and not GetMainMenu():GetVisible())
        end

    end

    function DropStructureAbilityExtra:OnHolsterClient()

        self.menuActive = false
        Ability.OnHolsterClient(self)
        self.activeStructure = nil

    end

    function DropStructureAbilityExtra:OnSetActive()
    end

    function DropStructureAbilityExtra:GetIsGUIVisible()
        return self.buildMenu:GetIsVisible()
    end

    function DropStructureAbilityExtra:OverrideInput(input)

        if self.buildMenu then

            -- Build menu is up, let it handle input
            if self.buildMenu:GetIsVisible() then

                local selected = false
                input, selected = self.buildMenu:OverrideInput(input)
                self.menuActive = not selected
            else

                -- If player wants to switch to this, open build menu immediately
                local weaponSwitchCommands = { Move.Weapon1, Move.Weapon2, Move.Weapon3, Move.Weapon4, Move.Weapon5 }
                local thisCommand = weaponSwitchCommands[ self:GetHUDSlot() ]

                if bit.band( input.commands, thisCommand ) ~= 0 then
                    self.menuActive = true
                end

            end

        end
        return input

    end

    function DropStructureAbilityExtra:OnUpdateRender()
        UpdateGUI(self, self:GetParent())
    end

end

Shared.LinkClassToMap("DropStructureAbilityExtra", DropStructureAbilityExtra.kMapName, networkVars)