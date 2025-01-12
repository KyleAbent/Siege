-- ======= Copyright (c) 2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\BuilderVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")

BuilderVariantMixin = CreateMixin(BuilderVariantMixin)
BuilderVariantMixin.type = "BuilderVariant"

BuilderVariantMixin.kDefaultModelName = PrecacheAsset("models/marine/welder/builder.model")

BuilderVariantMixin.networkVars = 
{
    welderVariant = "enum kWelderVariants"
}

--Note: this only pertains to the World model a marine carries
function BuilderVariantMixin:__initmixin()
    
    PROFILE("BuilderVariantMixin:__initmixin")
    
    self.welderVariant = kDefaultWelderVariant
    
    if Client then
        self.dirtySkinState = true
        self:AddFieldWatcher("welderVariant", self.SetSkinStateDirty)
    end

end

function BuilderVariantMixin:GetBuilderVariant()
    return self.welderVariant
end

function BuilderVariantMixin:GetVariantModel()
    return BuilderVariantMixin.kDefaultModelName
end

if Server then
    
    -- Usually because the client connected or changed their options.
    function BuilderVariantMixin:UpdateWeaponSkins(client)
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

    function BuilderVariantMixin:SetSkinStateDirty()
        self.dirtySkinState = true
        return true
    end

    function BuilderVariantMixin:OnUpdateRender()
        PROFILE("BuilderVariantMixin:OnUpdateRender")

        if self.dirtySkinState then

            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then
                if self.welderVariant ~= kDefaultWelderVariant then
                    local worldMat = GetPrecachedCosmeticMaterial( "Welder", self.welderVariant )
                    worldModel:SetOverrideMaterial( 0, worldMat )
                else
                    worldModel:RemoveOverrideMaterial( 0 )
                end

                self:SetHighlightNeedsUpdate()
            else
                return false
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
                            local viewMat = GetPrecachedCosmeticMaterial( "Welder", self.welderVariant, true)
                            viewModel:SetOverrideMaterial( viewMatIdx, viewMat )
                        else
                            --Removal at specific index to prevent BMAC hands from getting cleared too
                            viewModel:RemoveOverrideMaterial( viewMatIdx )
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
