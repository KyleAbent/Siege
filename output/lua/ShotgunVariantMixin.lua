-- ======= Copyright (c) 2016, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\ShotgunVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")

ShotgunVariantMixin = CreateMixin(ShotgunVariantMixin)
ShotgunVariantMixin.type = "ShotgunVariant"

ShotgunVariantMixin.kDefaultModelName = "models/marine/shotgun/shotgun.model"
ShotgunVariantMixin.kShotgunAnimationGraph = PrecacheAsset("models/marine/shotgun/shotgun_view.animation_graph")

ShotgunVariantMixin.networkVars = 
{
    shotgunVariant = "enum kShotgunVariants"
}

function ShotgunVariantMixin:__initmixin()
    
    PROFILE("ShotgunVariantMixin:__initmixin")
    
    self.shotgunVariant = kDefaultShotgunVariant
    
    if Client then
        --defaults to true in order for entity create to force a skin check
        self.dirtySkinState = true
        self:AddFieldWatcher( "shotgunVariant", self.SetSkinStateDirty )
    end
end

function ShotgunVariantMixin:GetShotgunVariant()
    return self.shotgunVariant
end

function ShotgunVariantMixin:GetVariantModel()
    return ShotgunVariantMixin.kDefaultModelName
end

if Server then
    
    -- Usually because the client connected or changed their options.
    function ShotgunVariantMixin:UpdateWeaponSkins(client)
        assert(client.variantData)
        
        if GetHasVariant(kShotgunVariantsData, client.variantData.shotgunVariant, client) or client:GetIsVirtual() then
            self.shotgunVariant = client.variantData.shotgunVariant            
        else
            Log("ERROR: Client tried to request Shotgun variant they do not have yet")
        end
    end
    
end


if Client then

    local kMaterialIndexMap = 
    {
        ["World"] = 0,
        ["View"] = 
        {
            ["Gun"] = 
            {
                [kMarineVariantsBaseType.male] = 2,
                [kMarineVariantsBaseType.female] = 2,
                [kMarineVariantsBaseType.bigmac] = 1
            },
            ["Lights"] = 
            {
                [kMarineVariantsBaseType.male] = 4,
                [kMarineVariantsBaseType.female] = 4,
                [kMarineVariantsBaseType.bigmac] = 3
            }
        }
    }

    --Utility when swapping weapons to force skin update
    function ShotgunVariantMixin:SetSkinStateDirty()
        self.dirtySkinState = true
        return true
    end

    function ShotgunVariantMixin:GetViewModelMaterialIndex( parent, isLights )
        assert(parent)
        assert(parent.GetMarineType)
        if isLights then
            return kMaterialIndexMap["View"]["Lights"][parent:GetMarineType()]
        else
            return kMaterialIndexMap["View"]["Gun"][parent:GetMarineType()]
        end
    end

    function ShotgunVariantMixin:OnUpdateRender()
        PROFILE("ShotgunVariantMixin:OnUpdateRender")
        
        if self.dirtySkinState then
            
            --Handle world model
            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then
                
                if self.shotgunVariant ~= kDefaultShotgunVariant then
                    local worldMat = GetPrecachedCosmeticMaterial( self:GetClassName(), self.shotgunVariant )
                    worldModel:SetOverrideMaterial( kMaterialIndexMap["World"], worldMat )
                else
                --reset model materials to baked/compiled ones
                    worldModel:RemoveOverrideMaterial(kMaterialIndexMap["World"])
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
                        
                        if self.shotgunVariant ~= kDefaultShotgunVariant then
                            local viewMats = GetPrecachedCosmeticMaterial(self:GetClassName(), self.shotgunVariant, true)
                            viewModel:SetOverrideMaterial( self:GetViewModelMaterialIndex(player, false), viewMats[1] ) --gun
                            viewModel:SetOverrideMaterial( self:GetViewModelMaterialIndex(player, true), viewMats[2] )  --lights
                        else
                        --Removal at specific index to prevent BMAC hands from getting cleared too
                            viewModel:RemoveOverrideMaterial( self:GetViewModelMaterialIndex(player, false) )
                            viewModel:RemoveOverrideMaterial( self:GetViewModelMaterialIndex(player, true) )
                        end
                    else
                        return false --delay a frame
                    end

                    viewModelEnt:SetHighlightNeedsUpdate()
                else
                    return false --delay a frame
                end

            end

            self.dirtySkinState = false
        end

    end

end