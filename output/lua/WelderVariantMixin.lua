-- ======= Copyright (c) 2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\WelderVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")

WelderVariantMixin = CreateMixin(WelderVariantMixin)
WelderVariantMixin.type = "WelderVariant"

WelderVariantMixin.kDefaultModelName = "models/marine/welder/welder.model"
WelderVariantMixin.kWelderAnimationGraph = PrecacheAsset("models/marine/welder/welder_view.animation_graph")

WelderVariantMixin.networkVars = 
{
    welderVariant = "enum kWelderVariants"
}

function WelderVariantMixin:__initmixin()
    
    PROFILE("WelderVariantMixin:__initmixin")
    
    self.welderVariant = kDefaultWelderVariant
    
    if Client then
        self.dirtySkinState = true
        self:AddFieldWatcher("welderVariant", self.SetSkinStateDirty)
    end
end

function WelderVariantMixin:GetWelderVariant()
    return self.welderVariant
end

function WelderVariantMixin:GetVariantModel()
    return WelderVariantMixin.kDefaultModelName
end

if Server then
    
    function WelderVariantMixin:UpdateWeaponSkins(client)
        if not Shared.GetIsRunningPrediction() then
            local data = client.variantData
            if data == nil then
                return
            end
            
            if GetHasVariant(kWelderVariantsData, data.welderVariant, client) or client:GetIsVirtual() then
                self.welderVariant = data.welderVariant            
            else
                Log("ERROR: Client tried to request Welder variant they do not have yet")
            end
        end
    end
    
end

if Client then

    local kWorldMaterialIndex = 0

    function WelderVariantMixin:SetSkinStateDirty()
        self.dirtySkinState = true
        return true
    end

    function WelderVariantMixin:OnUpdateRender()
        
        if self.dirtySkinState then

            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then
                if self.welderVariant ~= kDefaultWelderVariant then
                    local worldMat = GetPrecachedCosmeticMaterial( self:GetClassName(), self.welderVariant )
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

                        local isBmac = table.icontains( kRoboticMarineVariantIds, player.clientVariant )
                        local viewMatIdx = isBmac and 0 or 1
                        if self.welderVariant ~= kDefaultWelderVariant then
                            local viewMat = GetPrecachedCosmeticMaterial(self:GetClassName(), self.welderVariant, true)
                            viewModel:SetOverrideMaterial( viewMatIdx, viewMat )
                        else
                        --Removal at specific index to prevent BMAC hands from getting cleared too
                            viewModel:RemoveOverrideMaterial( viewMatIdx )
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