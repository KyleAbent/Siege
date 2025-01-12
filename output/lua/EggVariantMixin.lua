-- ======= Copyright (c) 2003-2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\EggVariantMixin.lua
-- 
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")


EggVariantMixin = CreateMixin(EggVariantMixin)
EggVariantMixin.type = "EggVariant"

EggVariantMixin.expectedMixins =
{
    Team = "For making friendly players visible"
}

EggVariantMixin.networkVars =
{
    eggVariant = "enum kEggVariants",
}

EggVariantMixin.optionalCallbacks =
{
    SetupStructureEffects = "Special per-structure callback to handle dealing with effects specific per type",
    UpdateStructureEffects = "Same as setup but for regular updates",
    OnEggSkinChangedExtras = "Optional rendering related extras for skin-specific effects",
}


function EggVariantMixin:__initmixin()
    self.eggVariant = kDefaultEggVariant

    if Client then
        self.dirtySkinState = true
        self.clientEggVariant = nil
        self:AddFieldWatcher( "eggVariant", self.OnEggSkinChanged )
    end

    if Server then
        local gameInfo = GetGameInfoEntity()
        if gameInfo then
            local eggSkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot4 )
            if eggSkin ~= self.eggVariant then
                self.eggVariant = eggSkin
            end
        end
    end

    if self.SetupStructureEffects then
        self:SetupStructureEffects()
    end

end

local function UpdateStructureSkin(self)
    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local eggSkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot4 )
        if eggSkin ~= self.eggVariant then
            self.eggVariant = eggSkin
        end
    end

    if self.UpdateStructureEffects then
        self:UpdateStructureEffects()
    end
end

function EggVariantMixin:ForceEggSkinsUpdate()
    UpdateStructureSkin(self)
end

function EggVariantMixin:OnUpdate(deltaTime)
    if not Shared.GetIsRunningPrediction() then
        UpdateStructureSkin(self)
    end
end

if Client then

    function EggVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self:OnEggSkinChanged()
        end
    end

    function EggVariantMixin:OnEggSkinChanged()
        self.dirtySkinState = true
        return true
    end
    
    function EggVariantMixin:OnUpdateRender()

        if self.dirtySkinState and self:GetIsAlive() then
            local model = self:GetRenderModel()
            if model and model:GetReadyForOverrideMaterials() then
                local className = self:GetClassName()

                if self.eggVariant == kDefaultEggVariant then
                    model:ClearOverrideMaterials()
                else
                    local material = GetPrecachedCosmeticMaterial( className, self.eggVariant )
                    local materialIndex = 0
                    model:SetOverrideMaterial( materialIndex, material )
                end

                self:SetHighlightNeedsUpdate()
            else
                return false --skip to next frame
            end

            if self.OnEggSkinChangedExtras then
                self:OnEggSkinChangedExtras(self.eggVariant)
            end

            self.dirtySkinState = false
            self.clientEggVariant = self.eggVariant
        end

    end

end --End-Client
