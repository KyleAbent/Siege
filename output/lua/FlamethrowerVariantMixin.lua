-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\FlamethrowerVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")

FlamethrowerVariantMixin = CreateMixin(FlamethrowerVariantMixin)
FlamethrowerVariantMixin.type = "FlamethrowerVariant"

FlamethrowerVariantMixin.kDefaultModelName = "models/marine/flamethrower/flamethrower.model"
FlamethrowerVariantMixin.kFlamethrowerAnimationGraph = PrecacheAsset("models/marine/flamethrower/flamethrower_view.animation_graph")

FlamethrowerVariantMixin.networkVars =
{
    flamethrowerVariant = "enum kFlamethrowerVariants"
}

function FlamethrowerVariantMixin:__initmixin()
    
    PROFILE("FlamethrowerVariantMixin:__initmixin")
    
    self.flamethrowerVariant = kDefaultFlamethrowerVariant
    
    if Client then
        --defaults to true in order for entity create to force a skin check
        self.dirtySkinState = true
        self:AddFieldWatcher( "flamethrowerVariant", self.SetSkinStateDirty )
    end

end

function FlamethrowerVariantMixin:GetFlamethrowerVariant()
    return self.flamethrowerVariant
end

function FlamethrowerVariantMixin:GetVariantModel()
    return FlamethrowerVariantMixin.kDefaultModelName
end

if Server then

    function FlamethrowerVariantMixin:UpdateWeaponSkins(client)
        local data = client.variantData
        if data == nil then
            return
        end
        
        if GetHasVariant(kFlamethrowerVariantsData, data.flamethrowerVariant, client) or client:GetIsVirtual() then
            self.flamethrowerVariant = data.flamethrowerVariant
        else
            Log("ERROR: Client tried to request Flamethrower variant they do not have yet")
        end        
    end
    
end

if Client then

    local kMaterialIndexMap = 
    {
        ["World"] = 0,
        ["View"] = 
        {
            [kMarineVariantsBaseType.male] = 1,
            [kMarineVariantsBaseType.female] = 0,
            [kMarineVariantsBaseType.bigmac] = 0
        }
    }

    function FlamethrowerVariantMixin:SetSkinStateDirty()
        self.dirtySkinState = true
        return true
    end

    function FlamethrowerVariantMixin:GetViewModelMaterialIndex( parent )
        assert(parent)
        assert(parent.GetMarineType)
        return kMaterialIndexMap["View"][parent:GetMarineType()]
    end

    function FlamethrowerVariantMixin:OnUpdateRender()
        PROFILE("FlamethrowerVariantMixin:OnUpdateRender")

        if self.dirtySkinState then

            --Handle world model
            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then
                if self.flamethrowerVariant ~= kDefaultFlamethrowerVariant then
                    local worldMat = GetPrecachedCosmeticMaterial( self:GetClassName(), self.flamethrowerVariant )
                    worldModel:SetOverrideMaterial( kMaterialIndexMap["World"], worldMat )
                else
                    --reset model materials to baked/compiled ones
                    worldModel:RemoveOverrideMaterial( kMaterialIndexMap["World"] )
                end

                self:SetHighlightNeedsUpdate()
            else
                return false --delay a frame
            end

            --Handle View model
            local player = self:GetParent()
            if player and player:GetIsLocalPlayer() and player:GetActiveWeapon() == self then

                local viewModelEnt = player:GetViewModelEntity()
                if viewModelEnt then

                    local viewModel = viewModelEnt:GetRenderModel()
                    if viewModel and viewModel:GetReadyForOverrideMaterials() then

                        if self.flamethrowerVariant ~= kDefaultFlamethrowerVariant then
                            local viewMat = GetPrecachedCosmeticMaterial(self:GetClassName(), self.flamethrowerVariant, true)
                            viewModel:SetOverrideMaterial( self:GetViewModelMaterialIndex(player), viewMat )
                        else
                            --Removal at specific index to prevent BMAC hands from getting cleared too
                            viewModel:RemoveOverrideMaterial( self:GetViewModelMaterialIndex(player) )
                        end
                    else
                        return false
                    end

                    viewModelEnt:SetHighlightNeedsUpdate()
                end

            end

            self.dirtySkinState = false
        end
        
    end

end