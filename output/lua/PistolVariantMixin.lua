-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\PistolVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")

PistolVariantMixin = CreateMixin(PistolVariantMixin)
PistolVariantMixin.type = "PistolVariant"

local kDefaultVariantData = kPistolVariantsData[ kDefaultPistolVariant ]

-- precache models for all variants
PistolVariantMixin.kModelNames = { pistol = { } }

local function MakeModelPath( suffix )
    return "models/marine/pistol/pistol"..suffix..".model"
end

for variant, data in pairs(kPistolVariantsData) do
    PistolVariantMixin.kModelNames.pistol[variant] = PrecacheAssetSafe( MakeModelPath( data.modelFilePart), MakeModelPath( kDefaultVariantData.modelFilePart) )
end

PistolVariantMixin.kDefaultModelName = PistolVariantMixin.kModelNames.pistol[kDefaultPistolVariant]

PistolVariantMixin.kPistolAnimationGraph = PrecacheAsset("models/marine/pistol/pistol_view.animation_graph")

PistolVariantMixin.networkVars =
{
    pistolVariant = "enum kPistolVariants"
}

function PistolVariantMixin:__initmixin()
    
    PROFILE("PistolVariantMixin:__initmixin")
    
    self.pistolVariant = kDefaultPistolVariant

    if Client then
        self.dirtySkinState = true
        self:AddFieldWatcher("pistolVariant", self.SetSkinStateDirty)
    end
    
end

function PistolVariantMixin:GetPistolVariant()
    return self.pistolVariant
end

function PistolVariantMixin:GetVariantModel()
    return PistolVariantMixin.kModelNames.pistol[ self.pistolVariant ]
end

if Server then

    -- Usually because the client connected or changed their options.
    function PistolVariantMixin:UpdateWeaponSkins(client)

        local data = client.variantData
        if data == nil then
            return
        end
        
        if GetHasVariant(kPistolVariantsData, data.pistolVariant, client) or client:GetIsVirtual() then
            self.pistolVariant = data.pistolVariant            
        else
            Log("ERROR: Client tried to request Pistol variant they do not have yet")
        end
        
    end
    
end

if Client then

    local kWorldMaterialIndex = 0
    local kViewMaterialIndex = 0

    function PistolVariantMixin:SetSkinStateDirty()
        self.dirtySkinState = true
        return true
    end

    function PistolVariantMixin:OnUpdateRender()
    
        if self.dirtySkinState then

            local worldModel = self:GetRenderModel()
            if worldModel and worldModel:GetReadyForOverrideMaterials() then
                
                if self.pistolVariant ~= kDefaultPistolVariant then
                    local worldMat = GetPrecachedCosmeticMaterial( self:GetClassName(), self.pistolVariant )
                    worldModel:SetOverrideMaterial( kWorldMaterialIndex, worldMat )
                else
                    worldModel:RemoveOverrideMaterial( kWorldMaterialIndex )
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
                        if self.pistolVariant ~= kDefaultPistolVariant then
                            local viewMat = GetPrecachedCosmeticMaterial( self:GetClassName(), self.pistolVariant, true )
                            assert(viewMat)
                            viewModel:SetOverrideMaterial( kViewMaterialIndex, viewMat )
                        else
                            viewModel:RemoveOverrideMaterial( kViewMaterialIndex )
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