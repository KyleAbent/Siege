-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua\ExoFlashlight_Client.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

kExoFlashlightGoboTexture = PrecacheAsset("models/marine/male/flashlight.dds")

-- So we don't have dulicate code in Exo.lua and Exosuit.lua...
function CreateExoFlashlight()
    
    local flashlight = Client.CreateRenderLight()
    
    flashlight:SetType(RenderLight.Type_Spot)
    flashlight:SetColor( kDefaultMarineFlashlightColor )
    flashlight:SetInnerCone(math.rad(25))
    flashlight:SetOuterCone(math.rad(48))
    flashlight:SetIntensity(10)
    flashlight:SetRadius(30)
    flashlight:SetAtmosphericDensity( kDefaultMarineFlashlightAtmoDensity )
    flashlight:SetGoboTexture(kExoFlashlightGoboTexture)
    flashlight:SetSpecular( true )
    
    --Exos tend to not be bunched nor 10+ in a room, so shadows should be "ok",
    --but avg perf cost is ~2fps per light (changes based on num shadow casters ofc)
    --so this may need to be removed
    flashlight:SetCastsShadows( true )
    
    return flashlight
    
end