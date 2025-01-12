-- ======= Copyright (c) 2003-2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\AlienCommanderSkinsMixin.lua
--
-- Just a data tracking mixin, separated by teams to eliminate network field per-team
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")


AlienCommanderSkinsMixin = CreateMixin(AlienCommanderSkinsMixin)
AlienCommanderSkinsMixin.type = "AlienCommanderSkins"


AlienCommanderSkinsMixin.expectedMixins =
{
    Team = "For making friendly players visible"
}

AlienCommanderSkinsMixin.networkVars =
{
    structureVariant = "enum kAlienStructureVariants",
    drifterVariant = "enum kAlienDrifterVariants",
    harvesterVariant = "enum kHarvesterVariants",
    eggVariant = "enum kEggVariants",
    cystVariant = "enum kAlienCystVariants",
    tunnelVariant = "enum kAlienTunnelVariants",
}


function AlienCommanderSkinsMixin:__initmixin()
    self.structureVariant = kDefaultAlienStructureVariant
    self.tunnelVariant = kDefaultAlienTunnelVariant
    self.drifterVariant = kDefaultAlienDrifterVariant
    self.harvesterVariant = kDefaultHarvesterVariant
    self.eggVariant = kDefaultEggVariant
    self.cystVariant = kDefaultAlienCystVariant

    --Waste to send this when round is already in progress, so clamp to pregame/warmup only
    if Client and GetGameInfoEntity():GetState() < kGameState.Countdown then
        SendPlayerVariantUpdate()
    end
end

function AlienCommanderSkinsMixin:GetCommanderStructureSkin()
    return self.structureVariant
end

function AlienCommanderSkinsMixin:GetCommanderDrifterSkin()
    return self.drifterVariant
end

function AlienCommanderSkinsMixin:GetCommanderHarvesterSkin()
    return self.harvesterVariant
end

function AlienCommanderSkinsMixin:GetCommanderEggSkin()
    return self.eggVariant
end

function AlienCommanderSkinsMixin:GetCommanderCystSkin()
    return self.cystVariant
end

function AlienCommanderSkinsMixin:GetCommanderTunnelSkin()
    return self.tunnelVariant
end

if Server then

    function AlienCommanderSkinsMixin:OnClientUpdated(client, isPickup)

        Player.OnClientUpdated(self, client, isPickup)
        
        if not client.variantData or client:GetIsVirtual() then
            return
        end

        if not client.variantData.alienStructuresVariant then
            return
        elseif not client.variantData.harvesterVariant then
            return
        elseif not client.variantData.eggVariant then
            return
        elseif not client.variantData.cystVariant then
            return
        elseif not client.variantData.drifterVariant then
            return
        elseif not client.variantData.alienTunnelsVariant then
            return
        end

        if GetGamerules():GetGameState() < kGameState.Countdown then

            if GetHasVariant( kAlienStructureVariantsData, client.variantData.alienStructuresVariant, client) then
                self.structureVariant = client.variantData.alienStructuresVariant
                self:GetTeam():SetHiveSkinVariant( self.structureVariant )
            end
            
            if GetHasVariant( kHarvesterVariantsData, client.variantData.harvesterVariant, client) then
                self.harvesterVariant = client.variantData.harvesterVariant
                self:GetTeam():SetHarvesterSkinVariant( self.harvesterVariant )
            end

            if GetHasVariant( kEggVariantsData, client.variantData.eggVariant, client) then
                self.eggVariant = client.variantData.eggVariant
                self:GetTeam():SetEggSkinVariant( self.eggVariant )
            end

            if GetHasVariant( kAlienCystVariantsData, client.variantData.cystVariant, client) then
                self.cystVariant = client.variantData.cystVariant
                self:GetTeam():SetCystSkinVariant( self.cystVariant )
            end

            if GetHasVariant( kAlienDrifterVariantsData, client.variantData.drifterVariant, client) then
                self.drifterVariant = client.variantData.drifterVariant
                self:GetTeam():SetDrifterSkinVariant( self.drifterVariant )
            end

            if GetHasVariant( kAlienTunnelVariantsData, client.variantData.alienTunnelsVariant, client) then
                self.tunnelVariant = client.variantData.alienTunnelsVariant
                self:GetTeam():SetTunnelSkinVariant( self.tunnelVariant )
            end

        end

    end

end