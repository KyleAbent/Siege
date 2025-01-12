-- ======= Copyright (c) 2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\GrenadeLauncherVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")

GrenadeLauncherVariantMixin = CreateMixin(GrenadeLauncherVariantMixin)
GrenadeLauncherVariantMixin.type = "GrenadeLauncherVariant"

GrenadeLauncherVariantMixin.kDefaultModelName = "models/marine/grandelauncher/grandelauncher.model"
GrenadeLauncherVariantMixin.kGrenadeLauncherAnimationGraph = PrecacheAsset("models/marine/grenadelauncher/grenadelauncher_view.animation_graph")

GrenadeLauncherVariantMixin.networkVars = 
{
    grenadeLauncherVariant = "enum kGrenadeLauncherVariants"
}


if Client then
    PrecacheCosmeticMaterials( "GrenadeLanucher", kGrenadeLauncherVariantsData )
end

function GrenadeLauncherVariantMixin:__initmixin()
    
    PROFILE("GrenadeLauncherVariantMixin:__initmixin")
    
    self.grenadeLauncherVariant = kDefaultGrenadeLauncherVariant
    
    if Client then
        self.dirtySkinState = true
        self:AddFieldWatcher( "grenadeLauncherVariant", self.SetSkinStateDirty )
    end

end

function GrenadeLauncherVariantMixin:GetGrenadeLauncherVariant()
    return self.grenadeLauncherVariant
end

function GrenadeLauncherVariantMixin:GetVariantModel()
    return GrenadeLauncherVariantMixin.kDefaultModelName
end

if Server then
    
    -- Usually because the client connected or changed their options.
    function GrenadeLauncherVariantMixin:UpdateWeaponSkins(client)
        local data = client.variantData
        if data == nil then
            return
        end
        
        if GetHasVariant(kGrenadeLauncherVariantsData, data.grenadeLauncherVariant, client) or client:GetIsVirtual() then
            self.grenadeLauncherVariant = data.grenadeLauncherVariant
        else
            Print("ERROR: Client tried to request Grenade Launcher variant they do not have yet")
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
            [kMarineVariantsBaseType.female] = 2,
            [kMarineVariantsBaseType.bigmac] = 0
        }
    }


    --Utility when swapping weapons to force skin update
    function GrenadeLauncherVariantMixin:SetSkinStateDirty()
        self.dirtySkinState = true
        return true
    end

    function GrenadeLauncherVariantMixin:GetWorldMaterialIndex()
        return kMaterialIndexMap["World"]
    end

    function GrenadeLauncherVariantMixin:GetViewModelMaterialIndex( parent )
        assert(parent)
        assert(parent.GetMarineType)
        return kMaterialIndexMap["View"][parent:GetMarineType()]
    end

    function GrenadeLauncherVariantMixin:OnUpdateRender()
        PROFILE("GrenadeLauncherVariantMixin:OnUpdateRender")

        if self.dirtySkinState then
        --Only update when skin state changed 
        --e.g. either entity created on client [enter relevancy], or local-client updated
        --their selected skin. No updates otherwise

            local worldMatIndex = self:GetWorldMaterialIndex()

            --Handle world model
            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then

                if self.grenadeLauncherVariant ~= kDefaultGrenadeLauncherVariant then
                    local worldMat = GetPrecachedCosmeticMaterial( self:GetClassName(), self.grenadeLauncherVariant )
                    assert(worldMat)
                    worldModel:SetOverrideMaterial( worldMatIndex, worldMat )
                else
                    worldModel:RemoveOverrideMaterial( worldMatIndex )
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
                    if viewModel and viewModel:GetReadyForOverrideMaterials() and player:GetActiveWeapon() == self then

                        local viewMatIndex = self:GetViewModelMaterialIndex( player )
                        if self.grenadeLauncherVariant ~= kDefaultGrenadeLauncherVariant then
                            local viewMat = GetPrecachedCosmeticMaterial( self:GetClassName(), self.grenadeLauncherVariant, true )
                            assert(viewMat)
                            viewModel:SetOverrideMaterial( viewMatIndex, viewMat )
                        else
                            viewModel:RemoveOverrideMaterial( viewMatIndex )
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