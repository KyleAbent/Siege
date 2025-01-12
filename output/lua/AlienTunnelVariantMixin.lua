-- ======= Copyright (c) 2003-2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\AlienTunnelVariantMixin.lua
-- 
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")


AlienTunnelVariantMixin = CreateMixin(AlienTunnelVariantMixin)
AlienTunnelVariantMixin.type = "AlienTunnelVariant"

AlienTunnelVariantMixin.expectedMixins =
{
    Team = "For making friendly players visible"
}

AlienTunnelVariantMixin.networkVars =
{
    tunnelVariant = "enum kAlienTunnelVariants",
}

AlienTunnelVariantMixin.optionalCallbacks =
{
    SetupStructureEffects = "Special per-structure callback to handle dealing with effects specific per type",
    UpdateStructureEffects = "Same as setup but for regular updates"
}


local function UpdateTunnelSkin(self)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local tunnelSkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot3 )
        if tunnelSkin ~= self.tunnelVariant then
            self.tunnelVariant = tunnelSkin
        end
    end

    if self.UpdateStructureEffects then
        self:UpdateStructureEffects()
    end

end

function AlienTunnelVariantMixin:__initmixin()

    self.tunnelVariant = kDefaultAlienTunnelVariant

    if Client then
        self.dirtySkinState = true
        self.clientTunnelVariant = nil
        self:AddFieldWatcher( "tunnelVariant", self.OnTunnelSkinChanged )
    end

    if Server then
        local gameInfo = GetGameInfoEntity()
        if gameInfo then
            local teamSpecSkin = gameInfo:GetTeamCosmeticSlot( self:GetTeamNumber(), kTeamCosmeticSlot3 )
            if teamSpecSkin ~= self.tunnelVariant then
                self.tunnelVariant = teamSpecSkin
            end
        end

        self:SetVariant(self.tunnelVariant)
    end
    
    if self.SetupStructureEffects then
        self:SetupStructureEffects()
    end

end

function AlienTunnelVariantMixin:ForceStructureSkinsUpdate()
    UpdateTunnelSkin(self)
end

function AlienTunnelVariantMixin:OnUpdate(deltaTime)
    if not Shared.GetIsRunningPrediction() then
        UpdateTunnelSkin(self)
    end
end


if Client then

    function AlienTunnelVariantMixin:OnModelChanged(hasModel)
        if hasModel then
            self:OnTunnelSkinChanged()
        end
    end

    function AlienTunnelVariantMixin:OnTunnelSkinChanged()
        self.dirtySkinState = true
        return true
    end

    function AlienTunnelVariantMixin:OnUpdateRender()
    
        if self.dirtySkinState and self:GetIsAlive() then

            local model = self:GetRenderModel()
            if model and model:GetReadyForOverrideMaterials() then

                if self.tunnelVariant == kDefaultAlienTunnelVariant or self.tunnelVariant == kAlienTunnelVariants.Shadow then
                    model:ClearOverrideMaterials()
                else
                    local material = GetPrecachedCosmeticMaterial( "Tunnel", self.tunnelVariant )
                    assert(material)
                    model:SetOverrideMaterial( 0, material )
                end

                self:SetHighlightNeedsUpdate()
            else
                return false --delay a frame
            end

            if self.OnStructureSkinChangedExtras then
                self:OnStructureSkinChangedExtras(self.tunnelVariant)
            end

            self.dirtySkinState = false
            self.clientTunnelVariant = self.tunnelVariant
        end

    end

end --End-Client