-- ======= Copyright (c) 2003-2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\MarineCommanderSkinsMixin.lua
--
-- Just a data tracking mixin, separated by teams to eliminate network field per-team
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")


MarineCommanderSkinsMixin = CreateMixin(MarineCommanderSkinsMixin)
MarineCommanderSkinsMixin.type = "MarineCommanderSkins"


MarineCommanderSkinsMixin.expectedMixins =
{
    Team = "For making friendly players visible"
}

MarineCommanderSkinsMixin.networkVars =
{
    structureVariant = "enum kMarineStructureVariants",
    extractorVariant = "enum kExtractorVariants",
    macVariant = "enum kMarineMacVariants",
    arcVariant = "enum kMarineArcVariants",
}


function MarineCommanderSkinsMixin:__initmixin()
    self.structureVariant = kDefaultMarineStructureVariant
    self.extractorVariant = kDefaultExtractorVariant
    self.macVariant = kDefaultMarineMacVariant
    self.arcVariant = kDefaultMarineArcVariant

    --Waste to send this when round is already in progress, so clamp to pregame/warmup only
    if Client and GetGameInfoEntity():GetState() < kGameState.Countdown then
        SendPlayerVariantUpdate()
    end

end

function MarineCommanderSkinsMixin:GetCommanderStructureSkin()
    return self.structureVariant
end

function MarineCommanderSkinsMixin:GetCommanderExtractorSkin()
    return self.extractorVariant
end

function MarineCommanderSkinsMixin:GetCommanderMacSkin()
    return self.macVariant
end

function MarineCommanderSkinsMixin:GetCommanderArcSkin()
    return self.arcVariant
end

if Server then

    function MarineCommanderSkinsMixin:OnClientUpdated(client, isPickup)

        Player.OnClientUpdated(self, client, isPickup)

        if not client.variantData or client:GetIsVirtual() then
            return
        end

        if not client.variantData.marineStructuresVariant then
            return
        elseif not client.variantData.extractorVariant then
            return
        elseif not client.variantData.macVariant then
            return
        elseif not client.variantData.arcVariant then
            return
        end

        if GetHasVariant( kMarineStructureVariantsData, client.variantData.marineStructuresVariant, client ) then
        --Only set field(s) when actually ows (only DLC check is performed in this context), saves tiny amount of network traffic
            self.structureVariant = client.variantData.marineStructuresVariant
            self:GetTeam():SetStructureSkinVariant( client.variantData.marineStructuresVariant )
        else
            Log("Commander failed authorization/ownership of CommandStation ItemID!!")
        end
        
        if GetHasVariant( kExtractorVariantsData, client.variantData.extractorVariant, client ) then
        --Only set field(s) when actually ows (only DLC check is performed in this context), saves tiny amount of network traffic
            self.extractorVariant = client.variantData.extractorVariant
            self:GetTeam():SetExtractorSkinVariant( client.variantData.extractorVariant )
        else
            Log("Commander failed authorization/ownership of Extractor ItemID!!")
        end

        if GetHasVariant( kMarineMacVariantsData, client.variantData.macVariant, client ) then
        --Only set field(s) when actually ows (only DLC check is performed in this context), saves tiny amount of network traffic
            self.macVariant = client.variantData.macVariant
            self:GetTeam():SetMacSkinVariant( client.variantData.macVariant )
        else
            Log("Commander failed authorization/ownership of MAC ItemID!!")
        end

        if GetHasVariant( kMarineArcVariantsData, client.variantData.arcVariant, client ) then
        --Only set field(s) when actually ows (only DLC check is performed in this context), saves tiny amount of network traffic
            self.arcVariant = client.variantData.arcVariant
            self:GetTeam():SetArcSkinVariant( client.variantData.arcVariant )
        else
            Log("Commander failed authorization/ownership of ARC ItemID!!")
        end

    end

end