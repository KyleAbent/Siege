-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\LerkVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")

LerkVariantMixin = CreateMixin(LerkVariantMixin)
LerkVariantMixin.type = "LerkVariant"

LerkVariantMixin.kDefaultModelName = PrecacheAsset("models/alien/lerk/lerk.model")
LerkVariantMixin.kShadowModelName = PrecacheAsset("models/alien/lerk/lerk_shadow.model")
LerkVariantMixin.kDefaultViewModelName = PrecacheAsset("models/alien/lerk/lerk_view.model")
local kLerkAnimationGraph = PrecacheAsset("models/alien/lerk/lerk.animation_graph")

LerkVariantMixin.networkVars =
{
    lerkVariant = "enum kLerkVariants",
}

LerkVariantMixin.optionalCallbacks =
{
    GetClassNameOverride = "Allows for implementor to specify what Entity class it should mimic",
}


function LerkVariantMixin:__initmixin()
    PROFILE("LerkVariantMixin:__initmixin")
    self.lerkVariant = kDefaultLerkVariant

    if Client then
        self.dirtySkinState = true
        self.forceSkinsUpdate = true
        self.initViewModelEvent = true
        self.clientLerkVariant = nil
    end
end

-- For Hallucinations, they don't have a client.
function LerkVariantMixin:ForceUpdateModel()
    self:SetModel(self:GetVariantModel(), kLerkAnimationGraph)
end

function LerkVariantMixin:GetVariant()
    return self.lerkVariant
end

--Only used for Hallucinations
function LerkVariantMixin:SetVariant(variant)
    assert(variant)
    assert(kLerkVariants[variant])
    self.lerkVariant = variant
end

function LerkVariantMixin:GetVariantModel()
    if self.lerkVariant == kLerkVariants.shadow or self.lerkVariant == kLerkVariants.auric then
        return LerkVariantMixin.kShadowModelName
    end
    return LerkVariantMixin.kDefaultModelName
end

function LerkVariantMixin:GetVariantViewModel()
    return LerkVariantMixin.kDefaultViewModelName
end

if Server then

    -- Usually because the client connected or changed their options
    function LerkVariantMixin:OnClientUpdated(client, isPickup)

        if not Shared.GetIsRunningPrediction() then
            Player.OnClientUpdated( self, client, isPickup )

            local data = client.variantData
            if data == nil then
                return
            end

            if self.GetIgnoreVariantModels and self:GetIgnoreVariantModels() then
                return
            end

            if GetHasVariant( kLerkVariantsData, data.lerkVariant, client ) or client:GetIsVirtual() then
                local isModelSwitch = 
                    (
                        (self.lerkVariant == kLerkVariants.shadow and client.variantData.lerkVariant ~= kLerkVariants.shadow) or
                        (self.lerkVariant ~= kLerkVariants.shadow and client.variantData.lerkVariant == kLerkVariants.shadow)
                    ) or
                    (
                        (self.lerkVariant == kLerkVariants.auric and client.variantData.lerkVariant ~= kLerkVariants.auric) or
                        (self.lerkVariant ~= kLerkVariants.auric and client.variantData.lerkVariant == kLerkVariants.auric)
                    )

                self.lerkVariant = client.variantData.lerkVariant
                
                if isModelSwitch then
                    local modelName = self:GetVariantModel()
                    assert( modelName ~= "" )
                    self:SetModel(modelName, kLerkAnimationGraph)

                    self:UpdateWeaponSkin(client)
                end
            else
                Log("ERROR: Client tried to request lerk variant they do not have yet")
            end
        end

    end

end


if Client then

    function LerkVariantMixin:OnLerkSkinChanged()
        if self.clientLerkVariant == self.lerkVariant and not self.forceSkinsUpdate then
            return false
        end
        
        self.dirtySkinState = true
        
        if self.forceSkinsUpdate then
            self.forceSkinsUpdate = false
        end
    end

    function LerkVariantMixin:OnUpdatePlayer(deltaTime)
        PROFILE("LerkVariantMixin:OnUpdatePlayer")
        if not Shared.GetIsRunningPrediction() then
            if ( self.clientLerkVariant ~= self.lerkVariant ) or ( Client.GetLocalPlayer() == self and self.initViewModelEvent ) then
                self.initViewModelEvent = false --ensure this only runs once
                self:OnLerkSkinChanged()
            end
        end
    end

    function LerkVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self.forceSkinsUpdate = true
            self:OnLerkSkinChanged()
        end
    end

    function LerkVariantMixin:OnUpdateViewModelEvent()
        self.forceSkinsUpdate = true
        self:OnLerkSkinChanged()
    end

    local kMaterialIndex = 0 --same for world & view

    function LerkVariantMixin:OnUpdateRender()
        PROFILE("LerkVariantMixin:OnUpdateRender")

        if self.dirtySkinState then
        --Note: overriding with the same material, doesn't perform changes to RenderModel

            local className = self.GetClassNameOverride and self:GetClassNameOverride() or self:GetClassName()

            --Handle world model
            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then

                if self.lerkVariant ~= kDefaultLerkVariant and self.lerkVariant ~= kLerkVariants.shadow then
                    local worldMat = GetPrecachedCosmeticMaterial( className, self.lerkVariant )
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

                        if self.lerkVariant ~= kDefaultLerkVariant and self.lerkVariant ~= kLerkVariants.shadow and self.lerkVariant ~= kLerkVariants.kodiak then
                            local viewMat = GetPrecachedCosmeticMaterial( className, self.lerkVariant, true )
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
            self.clientLerkVariant = self.lerkVariant
        end

    end

end