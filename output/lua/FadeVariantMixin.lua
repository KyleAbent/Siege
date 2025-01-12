-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\FadeVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")

FadeVariantMixin = CreateMixin(FadeVariantMixin)
FadeVariantMixin.type = "FadeVariant"

FadeVariantMixin.kDefaultModelName = PrecacheAsset("models/alien/fade/fade.model")
FadeVariantMixin.kShadowVariantModel = PrecacheAsset("models/alien/fade/fade_shadow.model")
FadeVariantMixin.kDefaultViewModelName = PrecacheAsset("models/alien/fade/fade_view.model")
FadeVariantMixin.kShadowViewModelName = PrecacheAsset("models/alien/fade/fade_shadow_view.model")
local kFadeAnimationGraph = PrecacheAsset("models/alien/fade/fade.animation_graph")

FadeVariantMixin.networkVars =
{
    fadeVariant = "enum kFadeVariants",
}

FadeVariantMixin.optionalCallbacks =
{
    GetClassNameOverride = "Allows for implementor to specify what Entity class it should mimic",
}


function FadeVariantMixin:__initmixin()
    PROFILE("FadeVariantMixin:__initmixin")
    
    self.fadeVariant = kDefaultFadeVariant

    if Client then
        self.dirtySkinState = true
        self.forceSkinsUpdate = true
        self.initViewModelEvent = true
        self.clientFadeVariant = nil
    end

end

-- For Hallucinations, they don't have a client.
function FadeVariantMixin:ForceUpdateModel()
    self:SetModel(self:GetVariantModel(), kFadeAnimationGraph)
end

function FadeVariantMixin:GetVariant()
    return self.fadeVariant
end

--Only used for Hallucinations
function FadeVariantMixin:SetVariant(variant)
    assert(variant)
    assert(kFadeVariants[variant])
    self.fadeVariant = variant
end

function FadeVariantMixin:GetVariantModel()
    if self.fadeVariant == kFadeVariants.shadow or self.fadeVariant == kFadeVariants.auric then
        return FadeVariantMixin.kShadowVariantModel
    end
    return FadeVariantMixin.kDefaultModelName
end

function FadeVariantMixin:GetVariantViewModel()
    if self.fadeVariant == kFadeVariants.shadow or self.fadeVariant == kFadeVariants.auric then
        return FadeVariantMixin.kShadowViewModelName
    end
    return FadeVariantMixin.kDefaultViewModelName
end

if Server then

    -- Usually because the client connected or changed their options
    function FadeVariantMixin:OnClientUpdated(client, isPickup)
        
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
            if GetHasVariant( kFadeVariantsData, client.variantData.fadeVariant, client ) or client:GetIsVirtual() then
                assert(client.variantData.fadeVariant ~= -1)
                local isModelSwitch = 
                    (
                        (self.fadeVariant == kFadeVariants.shadow and client.variantData.fadeVariant ~= kFadeVariants.shadow) or
                        (self.fadeVariant ~= kFadeVariants.shadow and client.variantData.fadeVariant == kFadeVariants.shadow)
                    ) or
                    (
                        (self.fadeVariant == kFadeVariants.auric and client.variantData.fadeVariant ~= kFadeVariants.auric) or
                        (self.fadeVariant ~= kFadeVariants.auric and client.variantData.fadeVariant == kFadeVariants.auric)
                    )

                self.fadeVariant = client.variantData.fadeVariant

                if isModelSwitch then
                --only when switch going From or To the Shadow skin
                    local modelName = self:GetVariantModel()
                    assert( modelName ~= "" )
                    self:SetModel(modelName, kFadeAnimationGraph)

                    -- Trigger a weapon skin update, to update the view model
                    self:UpdateWeaponSkin(client)
                end
            else
                Log("ERROR: Client tried to request skulk variant they do not have yet")
            end
        end
    end

end

if Client then

    function FadeVariantMixin:OnFadeSkinChanged()
        if self.clientFadeVariant == self.fadeVariant and not self.forceSkinsUpdate then
            return false
        end
        
        self.dirtySkinState = true
        
        if self.forceSkinsUpdate then
            self.forceSkinsUpdate = false
        end
    end

    function FadeVariantMixin:OnUpdatePlayer(deltaTime)
        PROFILE("FadeVariantMixin:OnUpdatePlayer")
        if not Shared.GetIsRunningPrediction() then
            if ( self.clientFadeVariant ~= self.fadeVariant ) or  ( Client.GetLocalPlayer() == self and self.initViewModelEvent ) then
                self.initViewModelEvent = false --ensure this only runs once
                self:OnFadeSkinChanged()
            end
        end
    end

    function FadeVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self.forceSkinsUpdate = true
            self:OnFadeSkinChanged()
        end
    end

    function FadeVariantMixin:OnUpdateViewModelEvent()
        self.forceSkinsUpdate = true
        self:OnFadeSkinChanged()
    end

    local kMaterialIndex = 0 --same for world & view

    function FadeVariantMixin:OnUpdateRender()
        PROFILE("FadeVariantMixin:OnUpdateRender")

        if self.dirtySkinState then
        --Note: overriding with the same material, doesn't perform changes to RenderModel

            local className = self.GetClassNameOverride and self:GetClassNameOverride() or self:GetClassName()

            --Handle world model
            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then

                if self.fadeVariant ~= kDefaultFadeVariant and self.fadeVariant ~= kFadeVariants.shadow then
                    local worldMat = GetPrecachedCosmeticMaterial( className, self.fadeVariant )
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

                        if self.fadeVariant ~= kDefaultFadeVariant and self.fadeVariant ~= kFadeVariants.shadow then
                            local viewMat = GetPrecachedCosmeticMaterial( className, self.fadeVariant, true )
                            viewModel:SetOverrideMaterial( kMaterialIndex, viewMat )
                        else
                            --Default and Shadow model use bot default view model and default textures
                            viewModel:ClearOverrideMaterials()
                        end

                    else
                        return false --delay frame
                    end

                    viewModelEnt:SetHighlightNeedsUpdate()
                end
            end

            self.dirtySkinState = false
            self.clientFadeVariant = self.fadeVariant
        end

    end

end