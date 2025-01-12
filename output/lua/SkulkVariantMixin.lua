-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\SkulkVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")  --FIXME including this in a skin is stupid wasteful, cosmetics should have thier own config-file

SkulkVariantMixin = CreateMixin(SkulkVariantMixin)
SkulkVariantMixin.type = "SkulkVariant"

SkulkVariantMixin.kDefaultModelName = PrecacheAsset("models/alien/skulk/skulk.model")
SkulkVariantMixin.kShadowVariantModel = PrecacheAsset("models/alien/skulk/skulk_shadow.model")
SkulkVariantMixin.kDefaultViewModelName = PrecacheAsset("models/alien/skulk/skulk_view.model")
local kSkulkAnimationGraph = PrecacheAsset("models/alien/skulk/skulk.animation_graph")

SkulkVariantMixin.networkVars =
{
    skulkVariant = "enum kSkulkVariants",
}

SkulkVariantMixin.optionalCallbacks =
{
    GetClassNameOverride = "Allows for implementor to specify what Entity class it should mimic",
}


function SkulkVariantMixin:__initmixin()
    PROFILE("SkulkVariantMixin:__initmixin")
    
    self.skulkVariant = kDefaultSkulkVariant

    if Client then
        self.dirtySkinState = true
        self.forceSkinsUpdate = true
        self.initViewModelEvent = true
        self.clientSkulkVariant = nil
    end
end

-- For Hallucinations, they don't have a client.
function SkulkVariantMixin:ForceUpdateModel()
    self:SetModel(self:GetVariantModel(), kSkulkAnimationGraph)
end

function SkulkVariantMixin:GetVariant()
    return self.skulkVariant
end

--Only used for Hallucinations
function SkulkVariantMixin:SetVariant(variant)
    assert(variant)
    assert(kSkulkVariants[variant])
    self.skulkVariant = variant
end

local shadowModelSkins = 
{
    kSkulkVariants.shadow,
    kSkulkVariants.auric,
    kSkulkVariants.tanith,
    kSkulkVariants.sleuth,
    kSkulkVariants.widow,
}
function SkulkVariantMixin:GetVariantModel()

    if table.icontains(shadowModelSkins, self.skulkVariant) then
        return SkulkVariantMixin.kShadowVariantModel
    end
    return SkulkVariantMixin.kDefaultModelName
end

function SkulkVariantMixin:GetVariantViewModel()
    return SkulkVariantMixin.kDefaultViewModelName
end

if Server then

    function SkulkVariantMixin:OnClientUpdated(client, isPickup)
        PROFILE("SkulkVariantMixin:OnClientUpdated")

        if not Shared.GetIsRunningPrediction() then
            Player.OnClientUpdated( self, client, isPickup )

            if not client.variantData or not client.variantData.skulkVariant then
                return
            end

            if self.GetIgnoreVariantModels and self:GetIgnoreVariantModels() then
                return
            end
            
            --Note, Skulks use two models for all their skins, Shadow is the only special-case
            if GetHasVariant( kSkulkVariantsData, client.variantData.skulkVariant, client ) or client:GetIsVirtual() then
                assert(client.variantData.skulkVariant ~= -1) --when would this ever be true?
                local isModelSwitch =   --Yes...this is garbage, I know...
                    (
                        (self.skulkVariant == kSkulkVariants.shadow and client.variantData.skulkVariant ~= kSkulkVariants.shadow) or
                        (self.skulkVariant ~= kSkulkVariants.shadow and client.variantData.skulkVariant == kSkulkVariants.shadow)
                    ) or
                    (
                        (self.skulkVariant == kSkulkVariants.auric and client.variantData.skulkVariant ~= kSkulkVariants.auric) or
                        (self.skulkVariant ~= kSkulkVariants.auric and client.variantData.skulkVariant == kSkulkVariants.auric)
                    ) or
                    (
                        (self.skulkVariant == kSkulkVariants.tanith and client.variantData.skulkVariant ~= kSkulkVariants.tanith) or
                        (self.skulkVariant ~= kSkulkVariants.tanith and client.variantData.skulkVariant == kSkulkVariants.tanith)
                    ) or
                    (
                        (self.skulkVariant == kSkulkVariants.sleuth and client.variantData.skulkVariant ~= kSkulkVariants.sleuth) or
                        (self.skulkVariant ~= kSkulkVariants.sleuth and client.variantData.skulkVariant == kSkulkVariants.sleuth)
                    ) or
                    (
                        (self.skulkVariant == kSkulkVariants.widow and client.variantData.skulkVariant ~= kSkulkVariants.widow) or
                        (self.skulkVariant ~= kSkulkVariants.widow and client.variantData.skulkVariant == kSkulkVariants.widow)
                    )
                    
                self.skulkVariant = client.variantData.skulkVariant

                if isModelSwitch then
                --only when switch going From or To the Shadow skin
                    local modelName = self:GetVariantModel()
                    assert( modelName ~= "" )
                    self:SetModel(modelName, kSkulkAnimationGraph)
                end
            else
                Log("ERROR: Client tried to request skulk variant they do not have yet")
            end
        end
    end

end

if Client then

    function SkulkVariantMixin:OnSkulkSkinChanged()
        if self.clientSkulkVariant == self.skulkVariant and not self.forceSkinsUpdate then
            return false
        end
        self.dirtySkinState = true
        
        if self.forceSkinsUpdate then
            self.forceSkinsUpdate = false
        end
    end

    function SkulkVariantMixin:OnUpdatePlayer(deltaTime)
        PROFILE("SkulkVariantMixin:OnUpdatePlayer")
        if not Shared.GetIsRunningPrediction() then
            if ( self.clientSkulkVariant ~= self.skulkVariant ) or ( Client.GetLocalPlayer() == self and self.initViewModelEvent ) then
                self.initViewModelEvent = false --ensure this only runs once
                self:OnSkulkSkinChanged()
            end
        end
    end

    function SkulkVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self.forceSkinsUpdate = true
            self:OnSkulkSkinChanged()
        end
    end

    function SkulkVariantMixin:OnUpdateViewModelEvent()
        self.forceSkinsUpdate = true
        self:OnSkulkSkinChanged()
    end

    local kMouthMaterialIndex = 0
    local kForelegsMaterialIndex = 1

    function SkulkVariantMixin:OnUpdateRender()
        PROFILE("SkulkVariantMixin:OnUpdateRender")

        if self.dirtySkinState then
        --Note: overriding with the same material, doesn't perform changes to RenderModel

            local className = self.GetClassNameOverride and self:GetClassNameOverride() or self:GetClassName()

            --Handle world model
            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then

                if self.skulkVariant ~= kDefaultSkulkVariant and self.skulkVariant ~= kSkulkVariants.shadow then
                    local worldMat = GetPrecachedCosmeticMaterial( className, self.skulkVariant )
                    worldModel:SetOverrideMaterial( 0, worldMat ) --always 0 index for all model
                else
                    --reset model materials to baked/compiled ones
                    worldModel:ClearOverrideMaterials()
                end
                
                self:SetHighlightNeedsUpdate()
            else
                return false --delay a frame
            end

            --Handle View model
            if self:GetIsLocalPlayer() then

                local viewModelEnt = self:GetViewModelEntity()
                if viewModelEnt then
                    
                    local viewModel = viewModelEnt:GetRenderModel()
                    if viewModel and viewModel:GetReadyForOverrideMaterials() then

                        if self.skulkVariant ~= kDefaultSkulkVariant then
                            
                            local viewMats = GetPrecachedCosmeticMaterial( className, self.skulkVariant, true )

                            if viewMats[1] and viewMats[1] ~= "" then
                                --not all variants require view material override
                                viewModel:SetOverrideMaterial( kMouthMaterialIndex, viewMats[1] ) --Mouth
                            else
                                --Reset mouth material to model default
                                viewModel:RemoveOverrideMaterial( kMouthMaterialIndex )
                            end
                            viewModel:SetOverrideMaterial( kForelegsMaterialIndex, viewMats[2] )  --Front Legs
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
            self.clientSkulkVariant = self.skulkVariant
        end

    end

end
