-- ======= Copyright (c) 2003-2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\DrifterVariantMixin.lua
-- 
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")


DrifterVariantMixin = CreateMixin(DrifterVariantMixin)
DrifterVariantMixin.type = "DrifterVariant"

DrifterVariantMixin.expectedMixins =
{
    Team = "For making friendly players visible"
}

DrifterVariantMixin.networkVars =
{
    drifterVariant = "enum kAlienDrifterVariants",
}

DrifterVariantMixin.optionalCallbacks =
{
    SetupSkinEffects = "Special per-structure callback to handle dealing with effects specific per type",
    UpdateSkinEffects = "Same as setup but for regular updates",
    OnDrifterSkinChangedExtras = "Optional rendering related extras for skin-specific effects",
}


function DrifterVariantMixin:__initmixin()
    self.drifterVariant = kDefaultAlienDrifterVariant

    if Client then
        self.dirtySkinState = true
        self.clientDrifterVariant = nil
        self:AddFieldWatcher( "drifterVariant", self.OnDrifterSkinChanged )
    end

    if Server then
        local gameInfo = GetGameInfoEntity()
        if gameInfo then
            local driftSkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot6 )
            if driftSkin ~= self.drifterVariant then
                self.drifterVariant = driftSkin
            end
        end
    end

    if self.SetupSkinEffects then
        self:SetupSkinEffects()
    end

end

local function UpdateSkin(self)
    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local driftSkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot6 )
        if driftSkin ~= self.drifterVariant then
            self.drifterVariant = driftSkin
        end
    end

    if self.UpdateSkinEffects then
        self:UpdateSkinEffects()
    end
end

function DrifterVariantMixin:ForceDrifterSkinUpdate()
    UpdateSkin(self)
end

function DrifterVariantMixin:OnUpdate(deltaTime)
    if not Shared.GetIsRunningPrediction() then
        UpdateSkin(self)
    end
end

if Client then

    function DrifterVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self:OnDrifterSkinChanged()
        end
    end

    function DrifterVariantMixin:OnDrifterSkinChanged()
        self.dirtySkinState = true
        return true
    end
    
    function DrifterVariantMixin:OnUpdateRender()

        if self.dirtySkinState and self:GetIsAlive() then
            local model = self:GetRenderModel()
            if model and model:GetReadyForOverrideMaterials() then
                local className = self:GetClassName()

                if self.drifterVariant == kDefaultAlienDrifterVariant then
                    model:ClearOverrideMaterials()
                else
                    local material = GetPrecachedCosmeticMaterial( className, self.drifterVariant )
                    local materialIndex = 0
                    model:SetOverrideMaterial( materialIndex, material )
                end

                self:SetHighlightNeedsUpdate()
            else
                return false --skip to next frame
            end

            if self.OnDrifterSkinChangedExtras then
                self:OnDrifterSkinChangedExtras(self.drifterVariant)
            end

            self.dirtySkinState = false
            self.clientDrifterVariant = self.drifterVariant
        end

    end

end --End-Client
