-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\AxeVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")

AxeVariantMixin = CreateMixin(AxeVariantMixin)
AxeVariantMixin.type = "AxeVariant"

AxeVariantMixin.kAxeAnimationGraph = PrecacheAsset("models/marine/axe/axe_view.animation_graph")

AxeVariantMixin.networkVars =
{
    axeVariant = "enum kAxeVariants"
}


function AxeVariantMixin:__initmixin()
    
    PROFILE("AxeVariantMixin:__initmixin")
    
    self.axeVariant = kDefaultAxeVariant

    if Client then
        --defaults to true in order for entity create to force a skin check
        self.dirtySkinState = true
        self:AddFieldWatcher( "axeVariant", self.SetSkinStateDirty )
    end
    
end


function AxeVariantMixin:GetAxeVariant()
    return self.axeVariant
end

if Server then

    -- Usually because the client connected or changed their options.
    function AxeVariantMixin:UpdateWeaponSkins(client)
        if not Shared.GetIsRunningPrediction() then
            local data = client.variantData
            if data == nil then
                return
            end
            
            if GetHasVariant(kAxeVariantsData, data.axeVariant, client) or client:GetIsVirtual() then
                self.axeVariant = data.axeVariant
            else
                Log("ERROR: Client tried to request Axe variant they do not have yet")
            end
        end
    end
    
end


if Client then

    local kWorldMatIndex = 0
    local kViewMaterialIndexMap = 
    {
        ["View"] = 
        {
            [kMarineVariantsBaseType.male] = 1,
            [kMarineVariantsBaseType.female] = 1,
            [kMarineVariantsBaseType.bigmac] = 0
        }
    }

    --Utility when swapping weapons to force skin update
    function AxeVariantMixin:SetSkinStateDirty()
        self.dirtySkinState = true
        return true
    end

    function AxeVariantMixin:GetViewModelMaterialIndex( parent )
        assert(parent)
        assert(parent.GetMarineType)
        return kViewMaterialIndexMap["View"][parent:GetMarineType()]
    end

    function AxeVariantMixin:OnUpdateRender()
        PROFILE("AxeVariantMixin:OnUpdateRender")
    
    --Only update when skin state changed 
    --e.g. either entity created on client [entered relevancy], or local-client updated
    --their selected skin for the Axe. No updates otherwise

        if self.dirtySkinState then

            --Handle world model
            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then

                if self.axeVariant ~= kDefaultAxeVariant then
                    local worldMat = GetPrecachedCosmeticMaterial( self:GetClassName(), self.axeVariant )
                    worldModel:SetOverrideMaterial( kWorldMatIndex, worldMat )
                else
                --reset model materials to baked/compiled ones
                    worldModel:RemoveOverrideMaterial( kWorldMatIndex )
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
                        if self.axeVariant ~= kDefaultAxeVariant then
                            local viewMat = GetPrecachedCosmeticMaterial(self:GetClassName(), self.axeVariant, true)
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

end --End-Client
