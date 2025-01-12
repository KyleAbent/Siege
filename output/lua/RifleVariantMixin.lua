-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\RifleVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")

RifleVariantMixin = CreateMixin(RifleVariantMixin)
RifleVariantMixin.type = "RifleVariant"

RifleVariantMixin.kDefaultModelName = "models/marine/rifle/rifle.model"
RifleVariantMixin.kRifleAnimationGraph = PrecacheAsset("models/marine/rifle/rifle_view.animation_graph")

RifleVariantMixin.networkVars =
{
    rifleVariant = "enum kRifleVariants"
}

function RifleVariantMixin:__initmixin()
    
    PROFILE("RifleVariantMixin:__initmixin")
    
    self.rifleVariant = kDefaultRifleVariant
    
    if Client then
        self.dirtySkinState = true
        self:AddFieldWatcher("rifleVariant", self.SetSkinStateDirty)
    end

end

function RifleVariantMixin:GetRifleVariant()
    return self.rifleVariant
end

function RifleVariantMixin:GetVariantModel()
    return RifleVariantMixin.kDefaultModelName
end

if Server then

    function RifleVariantMixin:UpdateWeaponSkins(client)
        assert(client.variantData)
        
        if GetHasVariant(kRifleVariantsData, client.variantData.rifleVariant, client) or client:GetIsVirtual() then
            self.rifleVariant = client.variantData.rifleVariant            
        else
            Log("ERROR: Client tried to request Rifle variant they do not have yet")
        end
    end
    
end

if Client then


    local kWorldMaterialIndex = 0
    local kViewMaterialIndex = 
    {
        [kMarineVariantsBaseType.male] = 1,
        [kMarineVariantsBaseType.female] = 1,
        [kMarineVariantsBaseType.bigmac] = 0
    }

    function RifleVariantMixin:SetSkinStateDirty()
        self.dirtySkinState = true
        return true
    end

    function RifleVariantMixin:GetViewMaterialIndex(player)
        assert(player)
        assert(player.GetMarineType)
        return kViewMaterialIndex[player:GetMarineType()]
    end

    function RifleVariantMixin:OnUpdateRender()
        PROFILE("RifleVariantMixin:OnUpdateRender")
        
        if self.dirtySkinState then

            local worldModel = self:GetRenderModel()

            if worldModel and worldModel:GetReadyForOverrideMaterials() then

                if self.rifleVariant ~= kDefaultRifleVariant then
                    local worldMat = GetPrecachedCosmeticMaterial( self:GetClassName(), self.rifleVariant )
                    worldModel:SetOverrideMaterial( kWorldMaterialIndex, worldMat )
                else
                    worldModel:RemoveOverrideMaterial(kWorldMaterialIndex)
                end

                self:SetHighlightNeedsUpdate()
            else
                return false --skip to next frame
            end

            local player = self:GetParent()
            if player and player:GetIsLocalPlayer() and player:GetActiveWeapon() == self then
                
                local viewModelEnt = player:GetViewModelEntity()
                if viewModelEnt then

                    local viewModel = viewModelEnt:GetRenderModel()
                    if viewModel and viewModel:GetReadyForOverrideMaterials() then

                        if self.rifleVariant ~= kDefaultRifleVariant then
                            local viewMat = GetPrecachedCosmeticMaterial( self:GetClassName(), self.rifleVariant, true )
                            assert(viewMat)
                            viewModel:SetOverrideMaterial( self:GetViewMaterialIndex(player), viewMat )
                        else
                            viewModel:RemoveOverrideMaterial( self:GetViewMaterialIndex(player) )
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