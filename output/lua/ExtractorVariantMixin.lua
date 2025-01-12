-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\ExtractorVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")


ExtractorVariantMixin = CreateMixin(ExtractorVariantMixin)
ExtractorVariantMixin.type = "ExtractorVariant"

ExtractorVariantMixin.expectedMixins =
{
    Team = "For making friendly players visible"
}

ExtractorVariantMixin.networkVars =
{
    extractorVariant = "enum kExtractorVariants",
}

ExtractorVariantMixin.optionalCallbacks = 
{
    OnStructureSkinChangedExtras = "Optional callback when skins state changes to update extra cosmetic parts of entity"
}


function ExtractorVariantMixin:__initmixin()
    self.extractorVariant = kDefaultExtractorVariant

    if Client then
        self.dirtySkinState = true
        self.clientExtractorVariant = nil
        self:AddFieldWatcher( "extractorVariant", self.OnExtractorSkinChanged )
    end

    self:ForceSkinUpdate()
end


local function UpdateStructureSkin(self)
    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local cosmeticId = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot2 )
        if cosmeticId ~= self.extractorVariant then
            self.extractorVariant = cosmeticId
        end
    end

    if self.UpdateStructureEffects then
        self:UpdateStructureEffects()
    end
end

function ExtractorVariantMixin:ForceSkinUpdate()
    UpdateStructureSkin(self)
end

function ExtractorVariantMixin:OnUpdate(deltaTime)
    if not Shared.GetIsRunningPrediction() then
        UpdateStructureSkin(self)
    end
end


if Client then

    local kClassNameSkinKey = 
    {
        ["Extractor"] = "extractor"
    }

    local function GetIndexName(className)  --TODO SHould be pulled from Globals
        assert(className)
        assert(kClassNameSkinKey[className])
        return kClassNameSkinKey[className]
    end

    local kExtractorMatIndex = 0

    --Ref for which material index applies to the world model & skin-data table
    local kClassNameVariantMaterialIndices =
    {
        ["Extractor"] = kExtractorMatIndex,
    }
    
    local function GetClassMatIndex(className)
        assert(className)
        assert(kClassNameVariantMaterialIndices[className])
        return kClassNameVariantMaterialIndices[className]
    end

    function ExtractorVariantMixin:GetSkinMaterialName( class, variant, index )
        assert(class)
        assert(variant)

        --yes, this is janky as hell...synchronizing the handling of the Customize Screen with In-Game is 
        --a bastard considering model handling constraints of the engine...lame, but this is how it be.
        local skinData = GetCustomizableWorldMaterialData( GetIndexName(class), nil, { extractorVariant = variant } )
        if type(skinData) == "table" then
            local cIdx = (index ~= nil and index >= 0) and index or GetClassMatIndex(class)
            for i = 1, #skinData do
                if skinData[i].idx == cIdx then
                    return skinData[i].mat
                end
                i = i + 1
            end
        else
            return skinData
        end

        return false
    end

    function ExtractorVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self:OnExtractorSkinChanged()
        end
    end

    function ExtractorVariantMixin:OnExtractorSkinChanged()
        self.dirtySkinState = true
        return true
    end
    
    function ExtractorVariantMixin:OnUpdateRender()

        if self.dirtySkinState and self:GetIsAlive() then
            local model = self:GetRenderModel()
            if model and model:GetReadyForOverrideMaterials() then
                local className = self:GetClassName()

                if self.extractorVariant == kDefaultExtractorVariant then
                    model:ClearOverrideMaterials()
                else
                    local material = self:GetSkinMaterialName( className, self.extractorVariant )
                    local materialIndex = GetClassMatIndex( className )
                    model:SetOverrideMaterial( materialIndex, material )
                end
                
                self:SetHighlightNeedsUpdate()
            else
                return false --skip to next frame
            end

            if self.OnStructureSkinChangedExtras then
                self:OnStructureSkinChangedExtras(self.extractorVariant)
            end

            self.dirtySkinState = false
            self.clientExtractorVariant = self.extractorVariant
        end

    end

end --End-Client
