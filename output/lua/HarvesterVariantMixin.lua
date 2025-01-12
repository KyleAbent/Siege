-- ======= Copyright (c) 2003-2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\HarvesterVariantMixin.lua
-- 
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")


HarvesterVariantMixin = CreateMixin(HarvesterVariantMixin)
HarvesterVariantMixin.type = "HarvesterVariant"

HarvesterVariantMixin.expectedMixins =
{
    Team = "For making friendly players visible"
}

HarvesterVariantMixin.networkVars =
{
    harvesterVariant = "enum kHarvesterVariants",
}

HarvesterVariantMixin.optionalCallbacks =
{
    SetupStructureEffects = "Special per-structure callback to handle dealing with effects specific per type",
    UpdateStructureEffects = "Same as setup but for regular updates",
    OnHarvesterSkinChangedExtras = "Optional rendering related extras for skin-specific effects",
}


function HarvesterVariantMixin:__initmixin()
    self.harvesterVariant = kDefaultHarvesterVariant

    if Client then
        self.dirtySkinState = true
        self.clientHarvesterVariant = nil
        self:AddFieldWatcher( "harvesterVariant", self.OnHarvesterSkinChanged )
    end

    if Server then
        local gameInfo = GetGameInfoEntity()
        if gameInfo then
            local harvySkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot2 )
            if harvySkin ~= self.harvesterVariant then
                self.harvesterVariant = harvySkin
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
        local harvySkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot2 )
        if harvySkin ~= self.harvesterVariant then
            self.harvesterVariant = harvySkin
        end
    end

    if self.UpdateStructureEffects then
        self:UpdateStructureEffects()
    end
end

function HarvesterVariantMixin:ForceStructureSkinsUpdate()
    UpdateStructureSkin(self)
end

function HarvesterVariantMixin:OnUpdate(deltaTime)
    if not Shared.GetIsRunningPrediction() then
        UpdateStructureSkin(self)
    end
end

if Client then

    function HarvesterVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self:OnHarvesterSkinChanged()
        end
    end

    function HarvesterVariantMixin:OnHarvesterSkinChanged()
        self.dirtySkinState = true
        return true
    end
    
    function HarvesterVariantMixin:OnUpdateRender()

        if self.dirtySkinState and self:GetIsAlive() then
            local model = self:GetRenderModel()
            if model and model:GetReadyForOverrideMaterials() then
                local className = self:GetClassName()

                if self.harvesterVariant == kDefaultHarvesterVariant then
                    model:ClearOverrideMaterials()
                else
                    local material = GetPrecachedCosmeticMaterial( className, self.harvesterVariant )
                    local materialIndex = 0
                    model:SetOverrideMaterial( materialIndex, material )
                end

                self:SetHighlightNeedsUpdate()
            else
                return false --skip to next frame
            end

            if self.OnHarvesterSkinChangedExtras then
                self:OnHarvesterSkinChangedExtras(self.harvesterVariant)
            end

            self.dirtySkinState = false
            self.clientHarvesterVariant = self.harvesterVariant
        end

    end

end --End-Client
