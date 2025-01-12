-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\OnosVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")

OnosVariantMixin = CreateMixin(OnosVariantMixin)
OnosVariantMixin.type = "OnosVariant"

OnosVariantMixin.kDefaultModelName = PrecacheAsset("models/alien/onos/onos.model")
OnosVariantMixin.kShadowModelName = PrecacheAsset("models/alien/onos/onos_shadow.model")
OnosVariantMixin.kDefaultViewModelName = PrecacheAsset("models/alien/onos/onos_view.model")
OnosVariantMixin.kShadowViewModelName = PrecacheAsset("models/alien/onos/onos_shadow_view.model")
local kOnosAnimationGraph = PrecacheAsset("models/alien/onos/onos.animation_graph")

OnosVariantMixin.networkVars =
{
    onosVariant = "enum kOnosVariants",
}

OnosVariantMixin.optionalCallbacks =
{
    GetClassNameOverride = "Allows for implementor to specify what Entity class it should mimic",
}

function OnosVariantMixin:__initmixin()
    
    PROFILE("OnosVariantMixin:__initmixin")
    
    self.onosVariant = kDefaultOnosVariant

    if Client then
        self.dirtySkinState = true
        self.forceSkinsUpdate = true
        self.initViewModelEvent = true
        self.clientOnosVariant = nil
    end

end

-- For Hallucinations, they don't have a client.
function OnosVariantMixin:ForceUpdateModel()
    self:SetModel(self:GetVariantModel(), kOnosAnimationGraph)
end

function OnosVariantMixin:GetVariant()
    return self.onosVariant
end

--Only used for Hallucinations
function OnosVariantMixin:SetVariant(variant)
    assert(variant)
    assert(kOnosVariants[variant])
    self.onosVariant = variant
end

function OnosVariantMixin:GetVariantModel()
    if self.onosVariant == kOnosVariants.shadow or self.onosVariant == kOnosVariants.auric then
        return OnosVariantMixin.kShadowModelName
    end
    return OnosVariantMixin.kDefaultModelName
end

function OnosVariantMixin:GetVariantViewModel()
    if self.onosVariant == kOnosVariants.shadow or self.onosVariant == kOnosVariants.auric then
        return OnosVariantMixin.kShadowViewModelName
    end
    return OnosVariantMixin.kDefaultViewModelName
end

if Server then

    -- Usually because the client connected or changed their options
    function OnosVariantMixin:OnClientUpdated(client, isPickup)

        if not Shared.GetIsRunningPrediction() then
            Player.OnClientUpdated( self, client, isPickup )

            local data = client.variantData
            if data == nil then
                return
            end

            if self.GetIgnoreVariantModels and self:GetIgnoreVariantModels() then
                return
            end

            --Note, Skulks use two models for all their skins, Shadow is the only special-case
            if GetHasVariant( kOnosVariantsData, client.variantData.onosVariant, client ) or client:GetIsVirtual() then
                assert(client.variantData.onosVariant ~= -1)
                local isModelSwitch = 
                    (
                        (self.onosVariant == kOnosVariants.shadow and client.variantData.onosVariant ~= kOnosVariants.shadow) or
                        (self.onosVariant ~= kOnosVariants.shadow and client.variantData.onosVariant == kOnosVariants.shadow)
                    ) or
                    (
                        (self.onosVariant == kOnosVariants.auric and client.variantData.onosVariant ~= kOnosVariants.auric) or
                        (self.onosVariant ~= kOnosVariants.auric and client.variantData.onosVariant == kOnosVariants.auric)
                    )

                self.onosVariant = client.variantData.onosVariant

                if isModelSwitch then
                --only when switch going From or To the Shadow skin
                    local modelName = self:GetVariantModel()
                    assert( modelName ~= "" )
                    self:SetModel(modelName, kOnosAnimationGraph)

                    -- Trigger a weapon skin update, to update the view model
                    self:UpdateWeaponSkin(client)
                end
            else
                Log("ERROR: Client tried to request skulk onosVariant they do not have yet")
            end
        end

    end

end


if Client then

    function OnosVariantMixin:OnOnosSkinChanged()
        if self.clientOnosVariant == self.onosVariant and not self.forceSkinsUpdate then
            return false
        end
        
        self.dirtySkinState = true
        
        if self.forceSkinsUpdate then
            self.forceSkinsUpdate = false
        end
    end

    function OnosVariantMixin:OnUpdatePlayer(deltaTime)
        PROFILE("OnosVariantMixin:OnUpdatePlayer")
        if not Shared.GetIsRunningPrediction() then
            if ( self.clientOnosVariant ~= self.onosVariant ) or ( Client.GetLocalPlayer() == self and self.initViewModelEvent ) then
                self.initViewModelEvent = false --ensure this only runs once
                self:OnOnosSkinChanged()
            end
        end
    end

    function OnosVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self.forceSkinsUpdate = true
            self:OnOnosSkinChanged()
        end
    end

    function OnosVariantMixin:OnUpdateViewModelEvent()
        self.forceSkinsUpdate = true
        self:OnOnosSkinChanged()
    end

    local kMaterialIndex = 0 --same for world & view
    local kViewMaterialHornIndex = 0
    local kViewMaterialBodyIndex = 1

    function OnosVariantMixin:OnUpdateRender()
        PROFILE("OnosVariantMixin:OnUpdateRender")

        if self.dirtySkinState then
        --Note: overriding with the same material, doesn't perform changes to RenderModel

            local className = self.GetClassNameOverride and self:GetClassNameOverride() or self:GetClassName()

            --Handle world model
            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then

                if self.onosVariant ~= kDefaultOnosVariant and self.onosVariant ~= kOnosVariants.shadow then

                    local worldMat = GetPrecachedCosmeticMaterial( className, self.onosVariant )
                    worldModel:SetOverrideMaterial( kMaterialIndex, worldMat )

                else
                --reset model materials to baked/compiled ones
                    worldModel:ClearOverrideMaterials()
                end
                
                self:SetHighlightNeedsUpdate()
            else
                return false--bail now, so we can try again (model not fully loaded)
            end

            --Handle View model
            if self:GetIsLocalPlayer() then

                local viewModelEnt = self:GetViewModelEntity()
                if viewModelEnt then

                    local viewModel = viewModelEnt:GetRenderModel()
                    if viewModel and viewModel:GetReadyForOverrideMaterials() then

                        if self.onosVariant ~= kDefaultOnosVariant and self.onosVariant ~= kOnosVariants.shadow then
                            local viewMat = GetPrecachedCosmeticMaterial( className, self.onosVariant, true )
                            viewModel:SetOverrideMaterial( kViewMaterialHornIndex, viewMat[1] )
                            viewModel:SetOverrideMaterial( kViewMaterialBodyIndex, viewMat[2] )
                        else
                        --Default and Shadow model use bot default view model and default textures
                            viewModel:ClearOverrideMaterials()
                        end

                    else
                        return false
                    end

                    viewModelEnt:SetHighlightNeedsUpdate()
                end
            end

            self.dirtySkinState = false
            self.clientOnosVariant = self.onosVariant
        end

    end

end
