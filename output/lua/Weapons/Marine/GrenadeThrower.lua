-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Marine\GrenadeThrower.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    Base class for hand grenades. Override GetViewModelName and GetGrenadeMapName in implementation.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kDefaultVariantData = kMarineVariantsData[ kDefaultMarineVariant ]
local kDefaultMacVariantData = kMarineVariantsData[ kDefaultMarineBigmacVariant ]

function GenerateMarineGrenadeViewModelPaths(grenadeType)

    local viewModels = { male = { }, female = { }, bigmac = {} }

    local function MakePath(prefix, suffix)
        return "models/marine/grenades/" .. prefix .. grenadeType .. "_view" .. suffix .. ".model"
    end

    for variant, data in pairs(kMarineVariantsData) do
        if data.isRobot then
            viewModels.bigmac[variant] = PrecacheAssetSafe(MakePath("", data.viewModelFilePart), MakePath("", kDefaultMacVariantData.viewModelFilePart))
        else
            viewModels.male[variant] = PrecacheAssetSafe(MakePath("", data.viewModelFilePart), MakePath("", kDefaultVariantData.viewModelFilePart))
            viewModels.female[variant] = PrecacheAssetSafe(MakePath("female_", data.viewModelFilePart), MakePath("female_", kDefaultVariantData.viewModelFilePart))
        end
    end

    return viewModels

end

class 'GrenadeThrower' (Weapon)

GrenadeThrower.kMapName = "grenadethrower"
GrenadeThrower.kBounceFactor = 0.7

kMaxHandGrenades = 1

local kGrenadeVelocity = 18

local networkVars =
{
    grenadesLeft = "integer (0 to ".. kMaxHandGrenades ..")",
    isQuickThrown = "private boolean"
}

local function DropGrenade(self, player)
    if Server then

        local startPoint = player:GetEyePos()
        local grenadeClassName = self:GetGrenadeClassName()
        player:CreatePredictedProjectile(grenadeClassName, startPoint, Vector(0,0,0), 0.7, 0.45)

    end
end

local function ThrowGrenade(self, player)

    if Server or (Client and Client.GetIsControllingPlayer()) then

        local viewCoords = player:GetViewCoords()
        local eyePos = player:GetEyePos()

        local startPointTrace = Shared.TraceCapsule(eyePos, eyePos + viewCoords.zAxis, 0.2, 0, CollisionRep.Move, PhysicsMask.PredictedProjectileGroup, EntityFilterTwo(self, player))
        local startPoint = startPointTrace.endPoint

        local direction = viewCoords.zAxis

        if startPointTrace.fraction ~= 1 then
            direction = GetNormalizedVector(direction:GetProjection(startPointTrace.normal))
        end

        local grenadeClassName = self:GetGrenadeClassName()
        player:CreatePredictedProjectile(grenadeClassName, startPoint, direction * kGrenadeVelocity, self.kBounceFactor, 0.45)

    end

end

function GrenadeThrower:GetHasSecondary(_)
    return false
end

function GrenadeThrower:OnCreate()

    Weapon.OnCreate(self)

    self.pinPulled = false
    self.grenadesLeft = kMaxHandGrenades
    self.isQuickThrown = false
    self.tertiaryButtonPressed = false
    self.primaryButtonPressed = false
    self.heldThrow = false
    self.deployed = false

    self:SetModel(self:GetThirdPersonModelName())

end

function GrenadeThrower:DropItLikeItsHot( player )
    if self.pinPulled then
        DropGrenade(self, player)
        if not player:GetDarwinMode() then
            self.grenadesLeft = math.max(0, self.grenadesLeft - 1)
        end
    end
end

function GrenadeThrower:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)

    -- Attach weapon to parent's hand.
    self:SetAttachPoint(Weapon.kHumanAttachPoint)

end

function GrenadeThrower:OnPrimaryAttack(_)
    self.primaryButtonPressed = true

    if self.grenadesLeft > 0 and (self.deployed or self:GetQuickThrown()) then
        self.primaryAttacking = true
    end

end

function GrenadeThrower:OnPrimaryAttackEnd(_)
    self.primaryButtonPressed = false
    self:CheckHeldGrenade()
end

function GrenadeThrower:OnSecondaryAttack(_)
end

function GrenadeThrower:OnSecondaryAttackEnd(_)
end

function GrenadeThrower:OnTertiaryAttack(_)

    self.tertiaryButtonPressed = true

    if not self:GetQuickThrown() and not self.primaryAttacking and self.grenadesLeft > 0 then
        self:SetQuickThrown(true)
        self.primaryAttacking = true
    end

end

function GrenadeThrower:OnTertiaryAttackEnd(_)
    self.tertiaryButtonPressed = false
    self:CheckHeldGrenade()
end

function GrenadeThrower:CheckHeldGrenade()
    if self.heldThrow and not self.primaryButtonPressed and not self.tertiaryButtonPressed then
        self.primaryAttacking = false
        self.heldThrow = false
    end
end

function GrenadeThrower:SetQuickThrown(isQuickThrown)
    self.isQuickThrown = isQuickThrown
end

function GrenadeThrower:GetQuickThrown()
    return self.isQuickThrown
end

function GrenadeThrower:OnHolster()

    Weapon.OnHolster(self)

    self:OnTertiaryAttackEnd()
    self:SetQuickThrown(false)
    self.pinPulled = false
    self.primaryButtonPressed = false
    self.tertiaryButtonPressed = false
    self.heldThrow = false
    self.deployed = false

end

function GrenadeThrower:OnTag(tagName)

    local player = self:GetParent()

    if tagName == "pinpull_start" then

        self:TriggerEffects("grenade_pull_pin")

    elseif tagName == "deploy_end" then

        self.deployed = true

    elseif tagName == "pinpull_end" then

        self.pinPulled = true

        if not self.primaryButtonPressed and not self.tertiaryButtonPressed then
            self.primaryAttacking = false
        else
            self.heldThrow = true
        end

    elseif tagName == "throw" then

        if player then

            ThrowGrenade(self, player)
            if not player:GetDarwinMode() then
                self.grenadesLeft = math.max(0, self.grenadesLeft - 1)
            end
            self.pinPulled = false
            self:SetIsVisible(false)
            self:TriggerEffects("grenade_throw")

        end

    elseif tagName == "cancel_start" then

        self:SetQuickThrown(false)
        self.heldThrow = false

    elseif tagName == "attack_end" then

        self:SetQuickThrown(false)
        self.heldThrow = false

        if self.grenadesLeft == 0 then
            self.readyToDestroy = true
        else
            self:SetIsVisible(true)
        end

    end

end

function GrenadeThrower:GetHUDSlot()
    return 5
end

function GrenadeThrower:GetViewModelName()
    assert(false)
end

function GrenadeThrower:GetAnimationGraphName()
    assert(false)
end

function GrenadeThrower:GetWeight()
    return kHandGrenadeWeight
end

function GrenadeThrower:GetGrenadeClassName()
    assert(false)
end

function GrenadeThrower:OnUpdateAnimationInput(modelMixin)

    local activity = "none"
    if self.secondaryAttacking then
        activity = "secondary"
    elseif self.primaryAttacking then
        activity = "primary"
    end

    modelMixin:SetAnimationInput("quickthrown", self:GetQuickThrown())
    modelMixin:SetAnimationInput("activity", activity)
    modelMixin:SetAnimationInput("grenadesLeft", self.grenadesLeft)

end

function GrenadeThrower:OverrideWeaponName()
    return "grenades"
end

if Server then

    function GrenadeThrower:OnProcessMove(input)

        Weapon.OnProcessMove(self, input)

        local player = self:GetParent()
        if player then

            local activeWeapon = player:GetActiveWeapon()
            local allowDestruction = self.readyToDestroy or (activeWeapon ~= self and self.grenadesLeft == 0)

            if allowDestruction then

                if activeWeapon == self then

                    self:OnHolster(player)
                    player:QuickSwitchWeapon()

                end

                player:RemoveWeapon(self)
                DestroyEntity(self)

            end

        end

    end

end

function GrenadeThrower:GetCatalystSpeedBase()
    return 1
end

Shared.LinkClassToMap("GrenadeThrower", GrenadeThrower.kMapName, networkVars)