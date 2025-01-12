-- ======= Copyright (c) 2003-2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\ARCVariantMixin.lua
-- 
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")


ARCVariantMixin = CreateMixin(ARCVariantMixin)
ARCVariantMixin.type = "ARCVariant"

ARCVariantMixin.expectedMixins =
{
    Team = "For making friendly players visible"
}

ARCVariantMixin.networkVars =
{
    arcVariant = "enum kMarineArcVariants",
}

ARCVariantMixin.optionalCallbacks =
{
    SetupArcSkinEffects = "Special per-structure callback to handle dealing with effects specific per type",
    UpdateSkinEffects = "Same as setup but for regular updates",
    OnArcSkinChangedExtras = "Optional rendering related extras for skin-specific effects",
}


function ARCVariantMixin:__initmixin()
    self.arcVariant = kDefaultMarineArcVariant

    if Client then
        self.dirtySkinState = true
        self.clientArcVariant = nil
        self:AddFieldWatcher( "arcVariant", self.OnArcSkinChanged )
    end

    if Server then
        local gameInfo = GetGameInfoEntity()
        if gameInfo then
            local arcSkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot4 )
            if arcSkin ~= self.arcVariant then
                self.arcVariant = arcSkin
            end
        end
    end

    if self.SetupArcSkinEffects then
        self:SetupArcSkinEffects()
    end

end

local function UpdateArcSkin(self)
    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local arcSkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot4 )
        if arcSkin ~= self.arcVariant then
            self.arcVariant = arcSkin
        end
    end

    if self.UpdateSkinEffects then
        self:UpdateSkinEffects()
    end
end

function ARCVariantMixin:ForceSkinUpdate()
    UpdateArcSkin(self)
end

function ARCVariantMixin:OnUpdate(deltaTime)
    if not Shared.GetIsRunningPrediction() then
        UpdateArcSkin(self)
    end
end

if Client then

    function ARCVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self:OnArcSkinChanged()
        end
    end

    function ARCVariantMixin:OnArcSkinChanged()
        self.dirtySkinState = true
        return true
    end
    
    function ARCVariantMixin:OnUpdateRender()

        if self.dirtySkinState and self:GetIsAlive() then
            local model = self:GetRenderModel()
            if model and model:GetReadyForOverrideMaterials() then
                local className = self:GetClassName()

                if self.arcVariant == kDefaultMarineArcVariant then
                    model:ClearOverrideMaterials()
                else
                    local material = GetPrecachedCosmeticMaterial( className, self.arcVariant )
                    local materialIndex = 0
                    model:SetOverrideMaterial( materialIndex, material )
                end

                self:SetHighlightNeedsUpdate()
            else
                return false --skip to next frame
            end

            if self.OnArcSkinChangedExtras then
                self:OnArcSkinChangedExtras(self.arcVariant)
            end

            self.dirtySkinState = false
            self.clientArcVariant = self.arcVariant
        end

    end

end --End-Client
