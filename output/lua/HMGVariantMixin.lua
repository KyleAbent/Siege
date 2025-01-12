-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\HMGVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")

HMGVariantMixin = CreateMixin(HMGVariantMixin)
HMGVariantMixin.type = "HMGVariant"

HMGVariantMixin.kDefaultModelName = "models/marine/hmg/hmg.model"
HMGVariantMixin.kHMGAnimationGraph = PrecacheAsset("models/marine/hmg/hmg_view.animation_graph")

HMGVariantMixin.networkVars =
{
    hmgVariant = "enum kHMGVariants"
}

function HMGVariantMixin:__initmixin()
    
    PROFILE("HMGVariantMixin:__initmixin")
    
    self.hmgVariant = kDefaultHMGVariant

    if Client then
        self.dirtySkinState = true
        self:AddFieldWatcher("hmgVariant", self.SetSkinStateDirty)
    end
    
end

function HMGVariantMixin:GetHMGVariant()
    return self.hmgVariant
end

function HMGVariantMixin:GetVariantModel()
    return HMGVariantMixin.kDefaultModelName
end

if Server then

    function HMGVariantMixin:UpdateWeaponSkins(client)
        local data = client.variantData
        if data == nil then
            return
        end
        
        if GetHasVariant(kHMGVariantsData, data.hmgVariant, client) or client:GetIsVirtual() then
            self.hmgVariant = data.hmgVariant            
        else
            Log("ERROR: Client tried to request HMG variant they do not have yet")
        end
    end
    
end


if Client then

    local kWorldMaterialIndex = 0
    local kViewMaterialIndexMap = 
    {
        ["View"] = 
        {
            [kMarineVariantsBaseType.male] = 0,
            [kMarineVariantsBaseType.female] = 1,
            [kMarineVariantsBaseType.bigmac] = 0
        }
    }

    --Utility when swapping weapons to force skin update
    function HMGVariantMixin:SetSkinStateDirty()
        self.dirtySkinState = true
        return true
    end

    function HMGVariantMixin:GetViewModelMaterialIndex( parent )
        assert(parent)
        assert(parent.GetMarineType)
        return kViewMaterialIndexMap["View"][parent:GetMarineType()]
    end

    function HMGVariantMixin:OnUpdateRender()
        PROFILE("HMGVariantMixin:OnUpdateRender")

        --Only update when skin state changed 
        --e.g. either entity created on client [entered relevancy], or local-client updated
        --their selected skin for the Axe. No updates otherwise

        if self.dirtySkinState then

            --Handle world model
            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then
                if self.hmgVariant ~= kDefaultHMGVariant then
                    local worldMat = GetPrecachedCosmeticMaterial( self:GetClassName(), self.hmgVariant )
                    worldModel:SetOverrideMaterial( kWorldMaterialIndex, worldMat )
                else
                --reset model materials to baked/compiled ones
                    worldModel:RemoveOverrideMaterial( kWorldMaterialIndex )
                end

                self:SetHighlightNeedsUpdate()
            else
                return false --skip to next frame
            end

            --Handle View model
            local player = self:GetParent()
            if player and player:GetIsLocalPlayer() and player:GetActiveWeapon() == self then

                local viewModelEnt = player:GetViewModelEntity()
                if viewModelEnt then

                    local viewModel = viewModelEnt:GetRenderModel()
                    if viewModel and viewModel:GetReadyForOverrideMaterials() then

                        if self.hmgVariant ~= kDefaultHMGVariant then
                            local viewMat = GetPrecachedCosmeticMaterial(self:GetClassName(), self.hmgVariant, true)
                            viewModel:SetOverrideMaterial( self:GetViewModelMaterialIndex(player), viewMat )
                        else
                        --Removal at specific index to prevent BMAC hands from getting cleared too
                            viewModel:RemoveOverrideMaterial( self:GetViewModelMaterialIndex(player) )
                        end
                    else
                        return false --skip to next frame
                    end
                    viewModelEnt:SetHighlightNeedsUpdate()
                end

            end

            self.dirtySkinState = false
        end
        
    end

end