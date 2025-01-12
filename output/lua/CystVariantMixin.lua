-- ======= Copyright (c) 2003-2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\CystVariantMixin.lua
-- 
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")


CystVariantMixin = CreateMixin(CystVariantMixin)
CystVariantMixin.type = "CystVariantMixin"

CystVariantMixin.expectedMixins =
{
    Team = "For making friendly players visible"
}

CystVariantMixin.networkVars =
{
    cystVariant = "enum kAlienCystVariants",
}

CystVariantMixin.optionalCallbacks =
{
    SetupStructureEffects = "Special per-structure callback to handle dealing with effects specific per type",
    UpdateStructureEffects = "Same as setup but for regular updates",
    OnCystSkinChangedExtras = "Optional rendering related extras for skin-specific effects",
}


function CystVariantMixin:__initmixin()
    self.cystVariant = kDefaultAlienCystVariant

    if Client then
        self.dirtySkinState = true
        self.clientCystVariant = nil
        self:AddFieldWatcher( "cystVariant", self.OnCystSkinChanged )
    end

    if Server then
        local gameInfo = GetGameInfoEntity()
        if gameInfo then
            local cystSkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot5 )
            if cystSkin ~= self.cystVariant then
                self.cystVariant = cystSkin
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
        local cystSkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot5 )
        if cystSkin ~= self.cystVariant then
            self.cystVariant = cystSkin
        end
    end

    if self.UpdateStructureEffects then
        self:UpdateStructureEffects()
    end
end

function CystVariantMixin:ForceCystSkinsUpdate()
    UpdateStructureSkin(self)
end

function CystVariantMixin:OnUpdate(deltaTime)
    if not Shared.GetIsRunningPrediction() then
        UpdateStructureSkin(self)
    end
end

if Client then

    function CystVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self:OnCystSkinChanged()
        end
    end

    function CystVariantMixin:OnCystSkinChanged()
        self.dirtySkinState = true
        return true
    end
    
    function CystVariantMixin:OnUpdateRender()

        if self.dirtySkinState and self:GetIsAlive() then
            local model = self:GetRenderModel()
            if model and model:GetReadyForOverrideMaterials() then
                local className = self:GetClassName()

                if self.cystVariant == kDefaultAlienCystVariant then
                    model:ClearOverrideMaterials()
                else
                    local material = GetPrecachedCosmeticMaterial( className, self.cystVariant )
                    local materialIndex = 0
                    model:SetOverrideMaterial( materialIndex, material )
                end

                self:SetHighlightNeedsUpdate()
            else
                return false --skip to next frame
            end

            if self.OnCystSkinChangedExtras then
                self:OnCystSkinChangedExtras(self.cystVariant)
            end

            self.dirtySkinState = false
            self.clientCystVariant = self.cystVariant
        end

    end

end --End-Client
