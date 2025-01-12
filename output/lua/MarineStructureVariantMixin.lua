-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\MarineStructureVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")


MarineStructureVariantMixin = CreateMixin(MarineStructureVariantMixin)
MarineStructureVariantMixin.type = "MarineStructureVariant"

MarineStructureVariantMixin.expectedMixins =
{
    Team = "For making friendly players visible"
}

MarineStructureVariantMixin.networkVars =
{
    structureVariant = "enum kMarineStructureVariants",
}

MarineStructureVariantMixin.optionalCallbacks = 
{
    OnStructureSkinChangedExtras = "Optional callback when skins state changes to update extra cosmetic parts of entity"
}


function MarineStructureVariantMixin:__initmixin()
    self.structureVariant = kDefaultMarineStructureVariant

    if Client then
        self.dirtySkinState = true
        self.clientStructureVariant = nil
        self:AddFieldWatcher( "structureVariant", self.OnStructureSkinChanged )
    end

    self:ForceStructureSkinsUpdate()
end


local function UpdateStructureSkin(self)
    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local teamSkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot1 )
        if teamSkin ~= self.tunnelVariant then
            self.structureVariant = teamSkin
        end
    end

    if self.UpdateStructureEffects then
        self:UpdateStructureEffects()
    end
end

function MarineStructureVariantMixin:ForceStructureSkinsUpdate()
    UpdateStructureSkin(self)
end

function MarineStructureVariantMixin:OnUpdate(deltaTime)
    if not Shared.GetIsRunningPrediction() then
        UpdateStructureSkin(self)
    end
end


if Client then

    local kClassNameSkinKey = 
    {
        ["CommandStation"] = "command_station",
    }

    local function GetIndexName(className)  --TODO SHould be pulled from Globals
        assert(className)
        assert(kClassNameSkinKey[className])
        return kClassNameSkinKey[className]
    end

    local kCommandStationMatIndex = 0
    local kExtractorMatIndex = 0

    --Ref for which material index applies to the world model & skin-data table
    local kClassNameVariantMaterialIndices =
    {
        ["CommandStation"] = kCommandStationMatIndex,
    }
    
    local function GetClassMatIndex(className)
        assert(className)
        assert(kClassNameVariantMaterialIndices[className])
        return kClassNameVariantMaterialIndices[className]
    end

    function MarineStructureVariantMixin:GetSkinMaterialName( class, variant, index )
        assert(class)
        assert(variant)

        --yes, this is janky as hell...synchronizing the handling of the Customize Screen with In-Game is 
        --a bastard considering model handling constraints of the engine...lame, but this is how it be.
        local skinData = GetCustomizableWorldMaterialData( GetIndexName(class), nil, { marineStructuresVariant = variant } )
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

    function MarineStructureVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self:OnStructureSkinChanged()
        end
    end

    function MarineStructureVariantMixin:OnStructureSkinChanged()
        self.dirtySkinState = true
        return true
    end
    
    function MarineStructureVariantMixin:OnUpdateRender()

        if self.dirtySkinState and self:GetIsAlive() then
            local model = self:GetRenderModel()
            if model and model:GetReadyForOverrideMaterials() then
                local className = self:GetClassName()

                if self.structureVariant == kDefaultMarineStructureVariant then
                    model:ClearOverrideMaterials()
                else
                    local material = self:GetSkinMaterialName( className, self.structureVariant )
                    local materialIndex = GetClassMatIndex( className )
                    model:SetOverrideMaterial( materialIndex, material )
                end
                
                self:SetHighlightNeedsUpdate()
            else
                return false --skip to next frame
            end

            if self.OnStructureSkinChangedExtras then
                self:OnStructureSkinChangedExtras(self.structureVariant)
            end

            self.dirtySkinState = false
            self.clientStructureVariant = self.structureVariant
        end

    end

end --End-Client
