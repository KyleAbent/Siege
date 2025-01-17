-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\OrderSelfMixin.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

OrderSelfMixin = CreateMixin(OrderSelfMixin)
OrderSelfMixin.type = "OrderSelf"

local kFindStructureRange = 20
local kFindFriendlyPlayersRange = 15
local kTimeToDefendSinceTakingDamage = 5
-- What percent of health an enemy structure is below when it is considered a priority for attacking.
local kPriorityAttackHealthScalar = 0.6
-- How far away (squared) a move order location needs to be from the player's current location in
-- order to copy it. We want to avoid copying move orders if they are close to the player as
-- it is very likely the player has already completed nearby move orders and they are just
-- continuously being copied between nearby players unless all of them complete the order
-- at the same time.
local kMoveOrderDistSqRequiredForCopy = 15 * 15

OrderSelfMixin.expectedCallbacks = 
{
    GetTeamNumber = "Returns the team number this Entity is on." 
}

OrderSelfMixin.expectedConstants = 
{
    kPriorityAttackTargets = "Which target types to prioritize for attack orders after the low health priority has been considered." 
}

OrderSelfMixin.expectedMixins =
{
    Orders = ""
}

OrderSelfMixin.optionalCallbacks =
{
    OnOrderSelfComplete = "Called client side after the player has completed an order. Order type is passed."
}

OrderSelfMixin.networkVars =
{
    timeOfLastOrderComplete   = "private time",
    lastOrderType             = "private enum kTechId",
}

-- How often to look for orders.
local kOrderSelfUpdateRate = 1

function OrderSelfMixin:__initmixin()
    
    PROFILE("OrderSelfMixin:__initmixin")
    
    if Server then
        self.timeOfLastOrderComplete = 0
        self.lastOrderType = kTechId.None
        self:AddTimedCallback(OrderSelfMixin._UpdateOrderSelf, kOrderSelfUpdateRate)
    elseif Client then
        self.clientTimeOrderComplete = 0
    end
    
end

function OrderSelfMixin:FindBuildOrder(structuresNearby)

    if self.GetCheckForAutoConstructOrder and not self:GetCheckForAutoConstructOrder() then
        return false
    end

    local closestStructure
    local closestStructureDist = Math.infinity

    for _, structure in ipairs(structuresNearby) do

        local verticalDist = structure:GetOrigin().y - self:GetOrigin().y

        if verticalDist < 3 then

            local structureDist = (structure:GetOrigin() - self:GetOrigin()):GetLengthSquared()
            local closerThanClosest = structureDist < closestStructureDist

            if closerThanClosest and not structure:GetIsBuilt() and structure:GetCanConstruct(self) then

                if not structure:isa( "PowerPoint" ) then -- never order player to build powepoints unless needed, see below
                    closestStructure = structure
                    closestStructureDist = structureDist
                end
            end

        end

    end

    -- if closest structure needs power, build power source first
    if HasMixin( closestStructure, "PowerConsumer" ) then

        local nearPowerSources = GetEntitiesWithMixin("PowerSource")
        Shared.SortEntitiesByDistance(closestStructure:GetOrigin(), nearPowerSources)

        for _, powerSource in ipairs(nearPowerSources) do

            if powerSource:GetCanPower(closestStructure) then

                if not powerSource:GetIsBuilt() and not powerSource:GetIsPowering() and powerSource:GetCanConstruct(self) then
                    closestStructure = powerSource
                end

                break
            end

        end
    end

    if closestStructure then
        return kTechId.None ~= self:GiveOrder(kTechId.AutoConstruct, closestStructure:GetId(), closestStructure:GetOrigin(), nil, true, false)
    end

    return false

end

--
-- Find closest structure with health less than the kPriorityAttackHealthScalar, otherwise just closest matching kPriorityAttackTargets, otherwise closest structure.
--
function OrderSelfMixin:FindWeldOrder(entitiesNearby)

    local closestStructure
    local closestStructureDist = Math.infinity

    if self:isa("Marine") and not self:GetWeapon(Welder.kMapName) then
        return
    end

    -- Do not give weld orders during combat.
    if GetAnyNearbyUnitsInCombat(self:GetOrigin(), 15, self:GetTeamNumber()) then
        return
    end

    for _, entity in ipairs(entitiesNearby) do

        if entity ~= self then

            local entityDist = (entity:GetOrigin() - self:GetOrigin()):GetLengthSquared()
            local closerThanClosest = entityDist < closestStructureDist

            local weldAble = false

            if self:isa("Marine") then

                -- Weld friendly players if their armor is below 75%.
                -- Weld non-players when they are below 50%.
                weldAble = HasMixin(entity, "Weldable")
                weldAble = weldAble and (((entity:isa("Player") and not entity:isa("Spectator")) and entity:GetArmorScalar() < 0.75) or
                        (not entity:isa("Player") and entity:GetArmorScalar() < 0.5))

            end

            if self:isa("Gorge") then
                weldAble = entity:GetHealthScalar() < 1 and entity:isa("Player")
            end

            if HasMixin(entity, "Construct") and not entity:GetIsBuilt() then
                weldAble = false
            end

            if entity.GetCanBeHealed and not entity:GetCanBeHealed() then
                weldAble = false
            end

            if closerThanClosest and weldAble then

                closestStructure = entity
                closestStructureDist = entityDist

            end

        end

    end

    if closestStructure then

        local orderTechId = kTechId.AutoWeld
        if self:isa("Gorge") then
            orderTechId = kTechId.AutoHeal
        end

        return kTechId.None ~= self:GiveOrder(orderTechId, closestStructure:GetId(), closestStructure:GetOrigin(), nil, true, false)
    end

    return false

end

function OrderSelfMixin:GetCanOverwriteOrderType(orderType)
    return orderType == kTechId.AutoHeal or orderType == kTechId.AutoWeld
end

function OrderSelfMixin:_UpdateOrderSelf()

    local alive = not HasMixin(self, "Live") or self:GetIsAlive()

    if not alive then
        return true
    end

    if self:GetClient():GetIsVirtual() then
    --Bots do not require the self/auto-orders, stop updating for them
        return false --halt further updates, thus this is one-shot expense
    end

    local currentOrder = self:GetCurrentOrder()
    local currentOrderType = currentOrder and currentOrder:GetType() or nil

    if not currentOrder or self:GetCanOverwriteOrderType( currentOrderType ) then
        local friendlyStructuresNearby = GetEntitiesWithMixinForTeamWithinRange("Construct", self:GetTeamNumber(), self:GetOrigin(), kFindStructureRange)
        self:FindBuildOrder(friendlyStructuresNearby)
        --?? weld orders?
    end

    --routine to confirm PowerSource still have PowerConsumers
    if currentOrder and ( currentOrderType == kTechId.AutoConstruct ) then
        local order = self:GetCurrentOrder()
        local orderTarget = Shared.GetEntity(order.orderParam)

        if orderTarget and HasMixin(orderTarget, "PowerSource") then
            if not orderTarget:GetHasPowerConsumers() then
                self:ClearCurrentOrder()
            end
        end
    end

    -- Continue forever.
    return true

end

if Server then

    function OrderSelfMixin:OnOrderComplete(currentOrder)

        self.timeOfLastOrderComplete = Shared.GetTime()
        self.lastOrderType = currentOrder:GetType()
    
    end

elseif Client then

    function OrderSelfMixin:OnProcessMove(_)
    
        if not Shared.GetIsRunningPrediction() and self.OnOrderSelfComplete then
        
            if self.timeOfLastOrderComplete ~= self.clientTimeOrderComplete then            
                self.clientTimeOrderComplete = self.timeOfLastOrderComplete
                self:OnOrderSelfComplete(self.lastOrderType)
            end
        
        end 
    
    end

end