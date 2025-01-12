-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\GorgeVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")

GorgeVariantMixin = CreateMixin(GorgeVariantMixin)
GorgeVariantMixin.type = "GorgeVariant"

GorgeVariantMixin.kDefaultModelName = PrecacheAsset("models/alien/gorge/gorge.model")
GorgeVariantMixin.kShadowModelName = PrecacheAsset("models/alien/gorge/gorge_shadow.model")
GorgeVariantMixin.kDefaultViewModelName = PrecacheAsset("models/alien/gorge/gorge_view.model")
local kGorgeAnimationGraph = PrecacheAsset("models/alien/gorge/gorge.animation_graph")

GorgeVariantMixin.networkVars =
{
    gorgeVariant = "enum kGorgeVariants",
}

GorgeVariantMixin.optionalCallbacks =
{
    GetClassNameOverride = "Allows for implementor to specify what Entity class it should mimic",
}


function GorgeVariantMixin:__initmixin()
    
    PROFILE("GorgeVariantMixin:__initmixin")
    
    self.gorgeVariant = kDefaultGorgeVariant

    if Client then
        self.dirtySkinState = true
        self.forceSkinsUpdate = true
        self.initViewModelEvent = true
        self.clientGorgeVariant = nil
    end

end

-- For Hallucinations, they don't have a client.
function GorgeVariantMixin:ForceUpdateModel()
    self:SetModel(self:GetVariantModel(), kGorgeAnimationGraph)
end

function GorgeVariantMixin:GetVariant()
    return self.gorgeVariant
end

--Only used for Hallucinations
function GorgeVariantMixin:SetVariant(variant)
    assert(variant)
    assert(kGorgeVariants[variant])
    self.gorgeVariant = variant
end

function GorgeVariantMixin:GetVariantModel()
    if self.gorgeVariant == kGorgeVariants.shadow or self.gorgeVariant == kGorgeVariants.auric then
        return GorgeVariantMixin.kShadowModelName
    end
    return GorgeVariantMixin.kDefaultModelName
end

function GorgeVariantMixin:GetVariantViewModel()
    return GorgeVariantMixin.kDefaultViewModelName
end

if Server then

    -- Usually because the client connected or changed their options
    function GorgeVariantMixin:OnClientUpdated(client, isPickup)

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
            if GetHasVariant( kGorgeVariantsData, client.variantData.gorgeVariant, client ) or client:GetIsVirtual() then
                assert(client.variantData.gorgeVariant ~= -1)
                local isModelSwitch = 
                    (
                        (self.gorgeVariant == kGorgeVariants.shadow and client.variantData.gorgeVariant ~= kGorgeVariants.shadow) or
                        (self.gorgeVariant ~= kGorgeVariants.shadow and client.variantData.gorgeVariant == kGorgeVariants.shadow)
                    ) or
                    (
                        (self.gorgeVariant == kGorgeVariants.auric and client.variantData.gorgeVariant ~= kGorgeVariants.auric) or
                        (self.gorgeVariant ~= kGorgeVariants.auric and client.variantData.gorgeVariant == kGorgeVariants.auric)
                    )

                self.gorgeVariant = client.variantData.gorgeVariant

                if isModelSwitch then
                --only when switch going From or To the Shadow skin
                    local modelName = self:GetVariantModel()
                    assert( modelName ~= "" )
                    self:SetModel(modelName, kGorgeAnimationGraph)

                    -- Trigger a weapon skin update, to update the view model
                    self:UpdateWeaponSkin(client)
                end
            else
                Log("ERROR: Client tried to request Gorge variant they do not have yet")
            end
        end
    end

end


if Client then

    function GorgeVariantMixin:OnGorgeSkinChanged()
        if self.clientGorgeVariant == self.gorgeVariant and not self.forceSkinsUpdate then
            return false
        end
        
        self.dirtySkinState = true
        
        if self.forceSkinsUpdate then
            self.forceSkinsUpdate = false
        end
    end

    function GorgeVariantMixin:OnUpdatePlayer(deltaTime)
        PROFILE("GorgeVariantMixin:OnUpdatePlayer")
        if not Shared.GetIsRunningPrediction() then
            if self.clientGorgeVariant ~= self.gorgeVariant or (Client.GetLocalPlayer() == self and self.initViewModelEvent)  then
                self:OnGorgeSkinChanged()
                self.initViewModelEvent = false
            end
        end
    end

    function GorgeVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self.forceSkinsUpdate = true
            self:OnGorgeSkinChanged()
        end
    end

    function GorgeVariantMixin:OnUpdateViewModelEvent()
        self.forceSkinsUpdate = true
        self:OnGorgeSkinChanged()
    end

    local kMaterialIndex = 0 --same for world & view

    function GorgeVariantMixin:OnUpdateRender()
        PROFILE("GorgeVariantMixin:OnUpdateRender")

        if self.dirtySkinState then
        --Note: overriding with the same material, doesn't perform changes to RenderModel

            local className = self.GetClassNameOverride and self:GetClassNameOverride() or self:GetClassName()

            --Handle world model
            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then

                if self.gorgeVariant ~= kDefaultGorgeVariant and self.gorgeVariant ~= kGorgeVariants.shadow then
                    local worldMat = GetPrecachedCosmeticMaterial( className, self.gorgeVariant )
                    worldModel:SetOverrideMaterial( kMaterialIndex, worldMat )
                else
                --reset model materials to baked/compiled ones
                    worldModel:ClearOverrideMaterials()
                end
                
                self:SetHighlightNeedsUpdate()

            else
                return false -- Skip a frame, not ready yet.
            end

            --Handle View model
            if self:GetIsLocalPlayer() then

                local viewModelEnt = self:GetViewModelEntity()
                if viewModelEnt then

                    local viewModel = viewModelEnt:GetRenderModel()
                    if viewModel and viewModel:GetReadyForOverrideMaterials() then

                        if self.gorgeVariant ~= kDefaultGorgeVariant and self.gorgeVariant ~= kGorgeVariants.shadow and self.gorgeVariant ~= kGorgeVariants.kodiak then
                            local viewMat = GetPrecachedCosmeticMaterial( className, self.gorgeVariant, true )
                            viewModel:SetOverrideMaterial( kMaterialIndex, viewMat )
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
            self.clientGorgeVariant = self.gorgeVariant
        end

    end

end

