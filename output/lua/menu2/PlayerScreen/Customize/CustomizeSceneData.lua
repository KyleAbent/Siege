-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/PlayerScreen/Customize/CustomizeSceneData.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Globals.lua")
Script.Load("lua/Vector.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/ItemUtils.lua")


k4x3_AspectRatio = 4/3
k16x9_AspectRatio = 16/9
k16x10_AspectRatio = 16/10
k21x9_AspectRatio = 21/9

k4x3_AspectKey = "4x3"
k16x9_AspectKey = "16x9"
k16x10_AspectKey = "16x10"
k21x9_AspectKey = "21x9"

kSupportedScreenAspects = { k4x3_AspectRatio, k16x9_AspectRatio, k16x10_AspectRatio, k21x9_AspectRatio }

function GetScreenAspectIndex( aspect )
    assert(aspect)
    if aspect > k21x9_AspectRatio then
        return k21x9_AspectKey
    elseif not table.icontains( kSupportedScreenAspects, aspect ) then
        return k16x9_AspectKey  --fail-over (not ideal, improve..)
    end

    if aspect == k4x3_AspectRatio then
        return k4x3_AspectKey
    elseif aspect == k16x9_AspectRatio then
        return k16x9_AspectKey
    elseif aspect == k16x10_AspectRatio then
        return k16x10_AspectKey
    elseif aspect == k21x9_AspectRatio then
        return k21x9_AspectKey
    end
end

function GetCustomizeCameraViewTargetFov( targetFov, clientAspect )
--Handle per screen-aspect ratio FOV settings
    assert(targetFov)
    assert(clientAspect)
    local adjFov
    local aspectIdx = GetScreenAspectIndex(clientAspect)
    if type(targetFov) == "table" then
        adjFov = targetFov[aspectIdx]
    else
        adjFov = targetFov   --assert isnum?
    end
    return adjFov
end



--Global for sake of ease of access
gCustomizeSceneData = {}

-------------------------------------------------------------------------------
--General Assets
gCustomizeSceneData.kSkyBoxCinematic = PrecacheAsset("maps/skyboxes/descent_clear.cinematic")

gCustomizeSceneData.kMacFlyby = PrecacheAsset("cinematics/menu/customize_mac_flyby.cinematic")

gCustomizeSceneData.kHiveWisps = PrecacheAsset("cinematics/alien/hive/specks.cinematic")
gCustomizeSceneData.kHiveWisps_Toxin = PrecacheAsset("cinematics/alien/hive/specks_catpack.cinematic")
gCustomizeSceneData.kHiveWisps_Shadow = PrecacheAsset("cinematics/alien/hive/specks_shadow.cinematic")
gCustomizeSceneData.kHiveWisps_Abyss = PrecacheAsset("cinematics/alien/hive/specks_abyss.cinematic")
gCustomizeSceneData.kHiveWisps_Kodiak = PrecacheAsset("cinematics/alien/hive/specks_kodiak.cinematic")
gCustomizeSceneData.kHiveWisps_Nocturne = PrecacheAsset("cinematics/alien/hive/specks_nocturne.cinematic")
gCustomizeSceneData.kHiveWisps_Reaper = PrecacheAsset("cinematics/alien/hive/specks_reaper.cinematic")
gCustomizeSceneData.kHiveWisps_Unearthed = PrecacheAsset("cinematics/alien/hive/specks_unearthed.cinematic")
gCustomizeSceneData.kHiveWisps_Auric = PrecacheAsset("cinematics/alien/hive/specks_auric.cinematic")

gCustomizeSceneData.kHiveMist = PrecacheAsset("cinematics/alien/hive/idle_mist.cinematic")
gCustomizeSceneData.kHiveTechpointFX = PrecacheAsset("cinematics/common/techpoint.cinematic")
gCustomizeSceneData.kHiveTechpointLightFX = PrecacheAsset("cinematics/menu/customize_techpoint_light.cinematic")
gCustomizeSceneData.kLavaFallFX = PrecacheAsset("cinematics/menu/customize_lava_fall.cinematic")
--gCustomizeSceneData.kLavaPoolFountainFX = PrecacheAsset("cinematics/environment/smelting_bucket_pourring_base.cinematic")
--gCustomizeSceneData.kLavaPoolSmokeFX = PrecacheAsset("cinematics/environment/fire_room_smoke_low.cinematic")
--gCustomizeSceneData.kLavaBubbleFX = PrecacheAsset("cinematics/menu/customize_lava_bubble.cinematic")
--gCustomizeSceneData.kWallSparksFX = PrecacheAsset("cinematics/environment/sparks_loop_3s.cinematic")
--gCustomizeSceneData.kMoseyingDrifter = PrecacheAsset("cinematics/environment/origin/alien_zoo_drifter.cinematic")
--gCustomizeSceneData.kLavaHeat = PrecacheAsset("cinematics/environment/origin/heat_distortion.cinematic")

--TODO either write a custom one, or find something better
gCustomizeSceneData.kMarineTeamHighlightMaterial = PrecacheAsset("cinematics/vfx_materials/modelMouse_marines.material")
gCustomizeSceneData.kAlienTeamHighlightMaterial = PrecacheAsset("cinematics/vfx_materials/modelMouse_aliens.material")

gCustomizeSceneData.kMarineTeamSelectableMaterial = PrecacheAsset("cinematics/vfx_materials/customize_marine_selectable.material")
gCustomizeSceneData.kAlienTeamSelectableMaterial = PrecacheAsset("cinematics/vfx_materials/customize_alien_selectable.material")

-------------------------------------------------------------------------------
---Scene Timings / Constants

gCustomizeSceneData.kMacFlybyMinInterval = 12
gCustomizeSceneData.kMacFlybyInterval = 48

gCustomizeSceneData.kZoomedBaseCameraOffset = Vector( 0, 0, 0 ) --model position offset (not angles) from Camera transform


gCustomizeSceneData.kMarineVariantsOption = "marineVariant"
gCustomizeSceneData.kShotgunVariantsOption = "shotgunVariant"
gCustomizeSceneData.kAxeVariantOption = "axeVariant"
gCustomizeSceneData.kRifleVariantsOption = "rifleVariant"
gCustomizeSceneData.kPistolVariantOption = "pistolVariant"
gCustomizeSceneData.kWelderVariantsOption = "welderVariant"
gCustomizeSceneData.kFlamethrowerVariantsOption = "flamethrowerVariant"
gCustomizeSceneData.kGrenadeLauncherVariantsOption = "grenadeLauncherVariant"
gCustomizeSceneData.kHmgVariantOption = "hmgVariant"
gCustomizeSceneData.kExoVariantsOption = "exoVariant"
gCustomizeSceneData.kMarineStructuresVariantOption = "marineStructuresVariant"
gCustomizeSceneData.kExtractorVariantOption = "extractorVariant"
gCustomizeSceneData.kMacVariantsOption = "macVariant"
gCustomizeSceneData.kArcVariantsOption = "arcVariant"
gCustomizeSceneData.kShoulderPatchVariantOption = "shoulderPad"

gCustomizeSceneData.kSkulkVariantsOption = "skulkVariant"
gCustomizeSceneData.kGorgeVariantsOption = "gorgeVariant"
gCustomizeSceneData.kLerkVariantsOption = "lerkVariant"
gCustomizeSceneData.kFadeVariantsOption = "fadeVariant"
gCustomizeSceneData.kOnosVariantsOption = "onosVariant"
gCustomizeSceneData.kTunnelsVariantOption = "alienTunnelsVariant"
gCustomizeSceneData.kAlienStructuresVariantOption = "alienStructuresVariant"
gCustomizeSceneData.kHarvesterVariantOption = "harvesterVariant"
gCustomizeSceneData.kEggVariantOption = "eggVariant"
gCustomizeSceneData.kAlienCystVariantOption = "cystVariant"
gCustomizeSceneData.kAlienDrifterVariantOption = "drifterVariant"

gCustomizeSceneData.kGorgeClogVariantsOption = "clogVariant"
gCustomizeSceneData.kGorgeHydraVariantsOption = "hydraVariant"
gCustomizeSceneData.kGorgeBabblerVariantsOption = "babblerVariant"
gCustomizeSceneData.kGorgeBabblerEggVariantsOption = "babblerEggVariant"


-------------------------------------------------------------------------------
---Customize Render Scene Data / Settings

--Labels to denote camera position data (and other references)
gCustomizeSceneData.kViewLabels = 
enum({

    --Primary Marine Views
    "DefaultMarineView",
    "Marines",
    "ShoulderPatches",
    "ExoBay",
    "MarineStructures",     --Extractor is in-view
    "Armory",               --All weapons are in-view

    --Primary Alien Views
    "DefaultAlienView",
    "AlienLifeforms",
    "AlienStructures",      --Harvester and cyst are in-view
    "AlienTunnels",

    "TeamTransition"        --"Special" view used to go between Team areas
})

--Reference table to denote which View belongs to which team
gCustomizeSceneData.kTeamViews = 
{
    [kTeam1Index] = 
    {
        gCustomizeSceneData.kViewLabels.DefaultMarineView,
        gCustomizeSceneData.kViewLabels.Armory,
        gCustomizeSceneData.kViewLabels.Marines,
        gCustomizeSceneData.kViewLabels.ShoulderPatches,
        gCustomizeSceneData.kViewLabels.ExoBay,
        gCustomizeSceneData.kViewLabels.MarineStructures,
    },
    [kTeam2Index] = 
    {
        gCustomizeSceneData.kViewLabels.DefaultAlienView,
        gCustomizeSceneData.kViewLabels.AlienLifeforms,
        gCustomizeSceneData.kViewLabels.AlienStructures,
        gCustomizeSceneData.kViewLabels.AlienTunnels,
    }
}

gCustomizeSceneData.kDefaultviews =
{
    gCustomizeSceneData.kViewLabels.DefaultMarineView,
    gCustomizeSceneData.kViewLabels.DefaultAlienView,
}

gCustomizeSceneData.kSceneObjectReferences = enum({ 
    "CommandStation", "Extractor", "Mac", "Arc",
    "Marine", "Exo", "Patches", 

    "Rifle", "Axe", "Welder", "Pistol",
    "Shotgun", "Flamethrower", "GrenadeLauncher",
    "HeavyMachineGun",

    "Hive", "Harvester", "Egg", "Cyst", "Drifter",
    "Tunnel",
    "Skulk", "Lerk", "Gorge", "Fade", "Onos",
    "Babbler", "Clog", "Hydra", "BabblerEgg"
})
gCustomizeSceneData.kSceneObjectVariantsMap = 
{
    [gCustomizeSceneData.kSceneObjectReferences.CommandStation] = kMarineStructureVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Extractor] = kExtractorVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Mac] = kMarineMacVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Arc] = kMarineArcVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Marine] = kMarineVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Exo] = kExoVariants,

    [gCustomizeSceneData.kSceneObjectReferences.Rifle] = kRifleVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Axe] = kAxeVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Welder] = kWelderVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Pistol] = kPistolVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Shotgun] = kShotgunVariants,
    [gCustomizeSceneData.kSceneObjectReferences.GrenadeLauncher] = kGrenadeLauncherVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Flamethrower] = kFlamethrowerVariants,
    [gCustomizeSceneData.kSceneObjectReferences.HeavyMachineGun] = kHMGVariants,

    [gCustomizeSceneData.kSceneObjectReferences.Hive] = kAlienStructureVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Harvester] = kHarvesterVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Egg] = kEggVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Cyst] = kAlienCystVariants,

    [gCustomizeSceneData.kSceneObjectReferences.Drifter] = kAlienDrifterVariants,

    [gCustomizeSceneData.kSceneObjectReferences.Tunnel] = kAlienTunnelVariants,

    [gCustomizeSceneData.kSceneObjectReferences.Skulk] = kSkulkVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Gorge] = kGorgeVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Lerk] = kLerkVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Fade] = kFadeVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Onos] = kOnosVariants,

    [gCustomizeSceneData.kSceneObjectReferences.Clog] = kClogVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Hydra] = kHydraVariants,
    [gCustomizeSceneData.kSceneObjectReferences.Babbler] = kBabblerVariants,
    [gCustomizeSceneData.kSceneObjectReferences.BabblerEgg] = kBabblerEggVariants,
}

gCustomizeSceneData.kSceneObjectVariantsDataMap =
{
    [gCustomizeSceneData.kSceneObjectReferences.CommandStation] = kMarineStructureVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Extractor] = kExtractorVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Mac] = kMarineMacVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Arc] = kMarineArcVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Marine] = kMarineVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Exo] = kExoVariantsData,

    [gCustomizeSceneData.kSceneObjectReferences.Rifle] = kRifleVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Axe] = kAxeVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Welder] = kWelderVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Pistol] = kPistolVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Shotgun] = kShotgunVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.GrenadeLauncher] = kGrenadeLauncherVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Flamethrower] = kFlamethrowerVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.HeavyMachineGun] = kHMGVariantsData,

    [gCustomizeSceneData.kSceneObjectReferences.Hive] = kAlienStructureVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Harvester] = kHarvesterVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Egg] = kEggVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Cyst] = kAlienCystVariantsData,

    [gCustomizeSceneData.kSceneObjectReferences.Drifter] = kAlienDrifterVariantsData,

    [gCustomizeSceneData.kSceneObjectReferences.Tunnel] = kAlienTunnelVariantsData,

    [gCustomizeSceneData.kSceneObjectReferences.Skulk] = kSkulkVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Gorge] = kGorgeVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Lerk] = kLerkVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Fade] = kFadeVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Onos] = kOnosVariantsData,

    [gCustomizeSceneData.kSceneObjectReferences.Clog] = kClogVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Hydra] = kHydraVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.Babbler] = kBabblerVariantsData,
    [gCustomizeSceneData.kSceneObjectReferences.BabblerEgg] = kBabblerEggVariantsData,
}

--Lookup for fetching the given customizable object (thus selectable skin(s)), per scene view name
gCustomizeSceneData.kSceneViewCustomizableObjectsMap = 
{
    [gCustomizeSceneData.kViewLabels.Armory] = 
    {
        gCustomizeSceneData.kSceneObjectReferences.Rifle,
        gCustomizeSceneData.kSceneObjectReferences.Pistol,
        gCustomizeSceneData.kSceneObjectReferences.Welder,
        gCustomizeSceneData.kSceneObjectReferences.Axe,
        gCustomizeSceneData.kSceneObjectReferences.Shotgun,
        gCustomizeSceneData.kSceneObjectReferences.Flamethrower,
        gCustomizeSceneData.kSceneObjectReferences.GrenadeLauncher,
        gCustomizeSceneData.kSceneObjectReferences.HeavyMachineGun
    },
    [gCustomizeSceneData.kViewLabels.Marines] = 
    {
        gCustomizeSceneData.kSceneObjectReferences.Marine
    },
    [gCustomizeSceneData.kViewLabels.MarineStructures] = 
    {
        gCustomizeSceneData.kSceneObjectReferences.CommandStation,
        gCustomizeSceneData.kSceneObjectReferences.Extractor,
        gCustomizeSceneData.kSceneObjectReferences.Mac,
        gCustomizeSceneData.kSceneObjectReferences.Arc,
    },
    [gCustomizeSceneData.kViewLabels.ExoBay] = 
    {
        gCustomizeSceneData.kSceneObjectReferences.Exo
    },
    --Note: ShoulderPatches are a special case

    [gCustomizeSceneData.kViewLabels.AlienStructures] = 
    {
        gCustomizeSceneData.kSceneObjectReferences.Hive,
        gCustomizeSceneData.kSceneObjectReferences.Harvester,
        gCustomizeSceneData.kSceneObjectReferences.Egg,
        gCustomizeSceneData.kSceneObjectReferences.Cyst,

        gCustomizeSceneData.kSceneObjectReferences.Drifter,
    },
    [gCustomizeSceneData.kViewLabels.AlienTunnels] = { gCustomizeSceneData.kSceneObjectReferences.Tunnel },
    [gCustomizeSceneData.kViewLabels.AlienLifeforms] = 
    {
        gCustomizeSceneData.kSceneObjectReferences.Skulk,
        gCustomizeSceneData.kSceneObjectReferences.Gorge,
        gCustomizeSceneData.kSceneObjectReferences.Lerk,
        gCustomizeSceneData.kSceneObjectReferences.Fade,
        gCustomizeSceneData.kSceneObjectReferences.Onos,

        gCustomizeSceneData.kSceneObjectReferences.Clog,
        gCustomizeSceneData.kSceneObjectReferences.Hydra,
        gCustomizeSceneData.kSceneObjectReferences.Babbler,
        gCustomizeSceneData.kSceneObjectReferences.BabblerEgg,
    },
}

--Note: Shoulder Patches are handled as one-off
gCustomizeSceneData.kOptionsFieldVariantDataMap = 
{
    [gCustomizeSceneData.kMarineStructuresVariantOption] = kMarineStructureVariantsData,
    [gCustomizeSceneData.kExtractorVariantOption] = kExtractorVariantsData,
    [gCustomizeSceneData.kMarineVariantsOption] = kMarineVariantsData,
    [gCustomizeSceneData.kExoVariantsOption] = kExoVariantsData,

    [gCustomizeSceneData.kArcVariantsOption] = kMarinArcVariantsData,
    [gCustomizeSceneData.kMacVariantsOption] = kMarineMacVariantsData,

    [gCustomizeSceneData.kRifleVariantsOption] = kRifleVariantsData,
    [gCustomizeSceneData.kAxeVariantOption] = kAxeVariantsData,
    [gCustomizeSceneData.kWelderVariantsOption] = kWelderVariantsData,
    [gCustomizeSceneData.kPistolVariantOption] = kPistolVariantsData,
    [gCustomizeSceneData.kShotgunVariantsOption] = kShotgunVariantsData,
    [gCustomizeSceneData.kGrenadeLauncherVariantsOption] = kGrenadeLauncherVariantsData,
    [gCustomizeSceneData.kFlamethrowerVariantsOption] = kFlamethrowerVariantsData,
    [gCustomizeSceneData.kHmgVariantOption] = kHMGVariantsData,

    [gCustomizeSceneData.kAlienStructuresVariantOption] = kAlienStructureVariantsData,
    [gCustomizeSceneData.kHarvesterVariantOption] = kHarvesterVariantsData,
    [gCustomizeSceneData.kEggVariantOption] = kEggVariantsData,
    [gCustomizeSceneData.kAlienCystVariantOption] = kAlienCystVariantsData,
    [gCustomizeSceneData.kAlienDrifterVariantOption] = kAlienDrifterVariantsData,

    [gCustomizeSceneData.kTunnelsVariantOption] = kAlienTunnelVariantsData,
    [gCustomizeSceneData.kSkulkVariantsOption] = kSkulkVariantsData,
    [gCustomizeSceneData.kGorgeVariantsOption] = kGorgeVariantsData,
    [gCustomizeSceneData.kLerkVariantsOption] = kLerkVariantsData,
    [gCustomizeSceneData.kFadeVariantsOption] = kFadeVariantsData,
    [gCustomizeSceneData.kOnosVariantsOption] = kOnosVariantsData,

    [gCustomizeSceneData.kGorgeHydraVariantsOption] = kHydraVariantsData,
    [gCustomizeSceneData.kGorgeClogVariantsOption] = kClogVariantsData,
    [gCustomizeSceneData.kGorgeBabblerVariantsOption] = kBabblerVariantsData,
    [gCustomizeSceneData.kGorgeBabblerEggVariantsOption] = kBabblerEggVariantsData,
}

--McG: Yes, this is clunky but with Item data structure(s), no simpler way around this. Item data needs a big refactor
--This table should only be used for purchasing NEW items, it should not be referenced for innate/default items.
gCustomizeSceneData.kVariantItemOptionsMap = --Note: does not contain "default" items (as they're all effectively 0/nil)
{
    --Marine Weapons
    [kTundraRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,
    [kKodiakRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,
    [kForgeRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,
    [kSandstormRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,
    [kRedRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,
    [kDragonRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,
    [kGoldRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,
    [kChromaRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,
    [kWoodRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,
    [kDamascusRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,
    [kDamascusGreenRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,
    [kDamascusPurpleRifleItemId] = gCustomizeSceneData.kRifleVariantsOption,

    [kTundraShotgunItemId] = gCustomizeSceneData.kShotgunVariantsOption,
    [kForgeShotgunItemId] = gCustomizeSceneData.kShotgunVariantsOption,
    [kSandstormShotgunItemId] = gCustomizeSceneData.kShotgunVariantsOption,
    [kKodiakShotgunItemId] = gCustomizeSceneData.kShotgunVariantsOption,
    [kChromaShotgunItemId] = gCustomizeSceneData.kShotgunVariantsOption,

    [kTundraAxeItemId] = gCustomizeSceneData.kAxeVariantOption,
    [kKodiakAxeItemId] = gCustomizeSceneData.kAxeVariantOption,
    [kForgeAxeItemId] = gCustomizeSceneData.kAxeVariantOption,
    [kSandstormAxeItemId] = gCustomizeSceneData.kAxeVariantOption,
    [kChromaAxeItemId] = gCustomizeSceneData.kAxeVariantOption,
    [kWoodAxeItemId] = gCustomizeSceneData.kAxeVariantOption,
    [kDamascusAxeItemId] = gCustomizeSceneData.kAxeVariantOption,
    [kDamascusGreenAxeItemId] = gCustomizeSceneData.kAxeVariantOption,
    [kDamascusPurpleAxeItemId] = gCustomizeSceneData.kAxeVariantOption,

    [kTundraPistolItemId] = gCustomizeSceneData.kPistolVariantOption,
    [kKodiakPistolItemId] = gCustomizeSceneData.kPistolVariantOption,
    [kForgePistolItemId] = gCustomizeSceneData.kPistolVariantOption,
    [kSandstormPistolItemId] = gCustomizeSceneData.kPistolVariantOption,
    [kViperPistolItemId] = gCustomizeSceneData.kPistolVariantOption,
    [kGoldPistolItemId] = gCustomizeSceneData.kPistolVariantOption,
    [kChromaPistolItemId] = gCustomizeSceneData.kPistolVariantOption,
    [kWoodPistolItemId] = gCustomizeSceneData.kPistolVariantOption,
    [kDamascusPistolItemId] = gCustomizeSceneData.kPistolVariantOption,
    [kDamascusGreenPistolItemId] = gCustomizeSceneData.kPistolVariantOption,
    [kDamascusPurplePistolItemId] = gCustomizeSceneData.kPistolVariantOption,

    [kTundraWelderItemId] = gCustomizeSceneData.kWelderVariantsOption,
    [kForgeWelderItemId] = gCustomizeSceneData.kWelderVariantsOption,
    [kKodiakWelderItemId] = gCustomizeSceneData.kWelderVariantsOption,
    [kSandstormWelderItemId] = gCustomizeSceneData.kWelderVariantsOption,
    [kChromaWelderItemId] = gCustomizeSceneData.kWelderVariantsOption,

    [kKodiakFlamethrowerItemId] = gCustomizeSceneData.kFlamethrowerVariantsOption,
    [kTundraFlamethrowerItemId] = gCustomizeSceneData.kFlamethrowerVariantsOption,
    [kForgeFlamethrowerItemId] = gCustomizeSceneData.kFlamethrowerVariantsOption,
    [kSandstormFlamethrowerItemId] = gCustomizeSceneData.kFlamethrowerVariantsOption,
    [kChromaFlamethrowerItemId] = gCustomizeSceneData.kFlamethrowerVariantsOption,

    [kSandstormGrenadeLauncherItemId] = gCustomizeSceneData.kGrenadeLauncherVariantsOption,
    [kTundraGrenadeLauncherItemId] = gCustomizeSceneData.kGrenadeLauncherVariantsOption,
    [kForgeGrenadeLauncherItemId] = gCustomizeSceneData.kGrenadeLauncherVariantsOption,
    [kKodiakGrenadeLauncherItemId] = gCustomizeSceneData.kGrenadeLauncherVariantsOption,
    [kChromaGrenadeLauncherItemId] = gCustomizeSceneData.kGrenadeLauncherVariantsOption,

    [kTundraHMGItemId] = gCustomizeSceneData.kHmgVariantOption,
    [kKodiakHMGItemId] = gCustomizeSceneData.kHmgVariantOption,
    [kForgeHMGItemId] = gCustomizeSceneData.kHmgVariantOption,
    [kSandstormHMGItemId] = gCustomizeSceneData.kHmgVariantOption,
    [kChromaHMGItemId] = gCustomizeSceneData.kHmgVariantOption,

    --Marine Armors
    [kBlackArmorItemId] = gCustomizeSceneData.kMarineVariantsOption,
    [kTundraArmorItemId] = gCustomizeSceneData.kMarineVariantsOption,
    [kKodiakArmorItemId] = gCustomizeSceneData.kMarineVariantsOption,
    [kDeluxeArmorItemId] = gCustomizeSceneData.kMarineVariantsOption,
    [kAssaultArmorItemId] = gCustomizeSceneData.kMarineVariantsOption,
    [kEliteAssaultArmorItemId] = gCustomizeSceneData.kMarineVariantsOption,
    [kForgeArmorItemId] = gCustomizeSceneData.kMarineVariantsOption,
    [kSandstormArmorItemId] = gCustomizeSceneData.kMarineVariantsOption,
    [kChromaArmorItemId] = gCustomizeSceneData.kMarineVariantsOption,
    
    [kBigMacVariantOneId] = gCustomizeSceneData.kMarineVariantsOption,      --TD-TODO Add Chroma item-id
    [kBigMacVariantTwoId] = gCustomizeSceneData.kMarineVariantsOption,
    [kBigMacVariantThreeId] = gCustomizeSceneData.kMarineVariantsOption,
    [kMilitaryBigMacVariantOneId] = gCustomizeSceneData.kMarineVariantsOption,
    [kMilitaryBigMacVariantTwoId] = gCustomizeSceneData.kMarineVariantsOption,
    [kMilitaryBigMacVariantThreeId] = gCustomizeSceneData.kMarineVariantsOption,
    [kBigMacEliteId] = gCustomizeSceneData.kMarineVariantsOption,
    [kMilitaryBigMacEliteId] = gCustomizeSceneData.kMarineVariantsOption,

    --Exosuits
    [kTundraExosuitItemId] = gCustomizeSceneData.kExoVariantsOption,
    [kKodiakExosuitItemId] = gCustomizeSceneData.kExoVariantsOption,
    [kForgeExosuitItemId] = gCustomizeSceneData.kExoVariantsOption,
    [kSandstormExosuitItemId] = gCustomizeSceneData.kExoVariantsOption,
    [kChromaExoItemId] = gCustomizeSceneData.kExoVariantsOption,
    
    --Marine Structures
    [kSandstormStructuresId] = gCustomizeSceneData.kMarineStructuresVariantOption,
    [kForgeStructuresItemId] = gCustomizeSceneData.kMarineStructuresVariantOption,
    [kTundraStructuresItemId] = gCustomizeSceneData.kMarineStructuresVariantOption,
    [kKodiakMarineStructuresItemId] = gCustomizeSceneData.kMarineStructuresVariantOption,
    [kChromaCommandStationItemId] = gCustomizeSceneData.kMarineStructuresVariantOption,

    [kSandstormStructuresId] = gCustomizeSceneData.kExtractorVariantOption,
    [kForgeStructuresItemId] = gCustomizeSceneData.kExtractorVariantOption,
    [kTundraStructuresItemId] = gCustomizeSceneData.kExtractorVariantOption,
    [kKodiakMarineStructuresItemId] = gCustomizeSceneData.kExtractorVariantOption,
    [kChromaExtractorItemId] = gCustomizeSceneData.kExtractorVariantOption,

    [kReinforcedShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kShadowShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kNS2WC14GlobeShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kGodarShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kSaunamenShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kSnailsShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kTitusGamingShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kKodiakShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kReaperShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kTundraShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kRookieShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kHalloween16ShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kSNLeviathanPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kSNPeeperPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kSummerGorgePatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kHauntedBabblerPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    [kBattleGorgeShoulderPatchItemId] = gCustomizeSceneData.kShoulderPatchVariantOption,
    
    --Marine Units
    [kChromaMacItemId] = gCustomizeSceneData.kMacVariantsOption,
    [kChromaArcItemId] = gCustomizeSceneData.kArcVariantsOption,


    --Alien Lifeforms
    [kKodiakSkulkItemId] = gCustomizeSceneData.kSkulkVariantsOption,
    [kAbyssSkulkItemId] = gCustomizeSceneData.kSkulkVariantsOption,
    [kShadowSkulkItemId] = gCustomizeSceneData.kSkulkVariantsOption,
    [kReaperSkulkItemId] = gCustomizeSceneData.kSkulkVariantsOption,
    [kNocturneSkulkItemId] = gCustomizeSceneData.kSkulkVariantsOption,
    [kToxinSkulkItemId] = gCustomizeSceneData.kSkulkVariantsOption,
    [kAuricSkulkItemId] = gCustomizeSceneData.kSkulkVariantsOption,
    [kTanithSkulkItemId] = gCustomizeSceneData.kSkulkVariantsOption,
    [kWidowSkulkItemId] = gCustomizeSceneData.kSkulkVariantsOption,
    [kSleuthSkulkItemId] = gCustomizeSceneData.kSkulkVariantsOption,

    [kKodiakGorgeItemId] = gCustomizeSceneData.kGorgeVariantsOption,
    [kReaperGorgeItemId] = gCustomizeSceneData.kGorgeVariantsOption,
    [kAbyssGorgeItemId] = gCustomizeSceneData.kGorgeVariantsOption,
    [kShadowGorgeItemId] = gCustomizeSceneData.kGorgeVariantsOption,
    [kNocturneGorgeItemId] = gCustomizeSceneData.kGorgeVariantsOption,
    [kToxinGorgeItemId] = gCustomizeSceneData.kGorgeVariantsOption,
    [kAuricGorgeItemId] = gCustomizeSceneData.kGorgeVariantsOption,

    [kReaperLerkItemId] = gCustomizeSceneData.kLerkVariantsOption,
    [kShadowLerkItemId] = gCustomizeSceneData.kLerkVariantsOption,
    [kNocturneLerkItemId] = gCustomizeSceneData.kLerkVariantsOption,
    [kToxinLerkItemId] = gCustomizeSceneData.kLerkVariantsOption,
    [kAbyssLerkItemId] = gCustomizeSceneData.kLerkVariantsOption,
    [kKodiakLerkItemId] = gCustomizeSceneData.kLerkVariantsOption,
    [kAuricLerkItemId] = gCustomizeSceneData.kLerkVariantsOption,

    [kReaperFadeItemId] = gCustomizeSceneData.kFadeVariantsOption,
    [kShadowFadeItemId] = gCustomizeSceneData.kFadeVariantsOption,
    [kNocturneFadeItemId] = gCustomizeSceneData.kFadeVariantsOption,
    [kToxinFadeItemId] = gCustomizeSceneData.kFadeVariantsOption,
    [kKodiakFadeItemId] = gCustomizeSceneData.kFadeVariantsOption,
    [kAbyssFadeItemId] = gCustomizeSceneData.kFadeVariantsOption,
    [kAuricFadeItemId] = gCustomizeSceneData.kFadeVariantsOption,

    [kReaperOnosItemId] = gCustomizeSceneData.kOnosVariantsOption,
    --TODO finally refactor this table item-def ids into oblivion
    [kShadowOnosItemIds[1]] = gCustomizeSceneData.kOnosVariantsOption,
    [kShadowOnosItemIds[2]] = gCustomizeSceneData.kOnosVariantsOption,
    [kNocturneOnosItemId] = gCustomizeSceneData.kOnosVariantsOption,
    [kToxinOnosItemId] = gCustomizeSceneData.kOnosVariantsOption,
    [kKodiakOnosItemId] = gCustomizeSceneData.kOnosVariantsOption,
    [kAbyssOnosItemId] = gCustomizeSceneData.kOnosVariantsOption,
    [kAuricOnosItemId] = gCustomizeSceneData.kOnosVariantsOption,

    [kShadowTunnelItemId] = gCustomizeSceneData.kTunnelsVariantOption,
    [kUnearthedTunnelItemId] = gCustomizeSceneData.kTunnelsVariantOption,
    [kReaperTunnelItemId] = gCustomizeSceneData.kTunnelsVariantOption,
    [kNocturneTunnelItemId] = gCustomizeSceneData.kTunnelsVariantOption,
    [kKodiakTunnelItemId] = gCustomizeSceneData.kTunnelsVariantOption,
    [kAbyssTunnelItemId] = gCustomizeSceneData.kTunnelsVariantOption,
    [kToxinTunnelItemId] = gCustomizeSceneData.kTunnelsVariantOption,

    --Alien Structures (note, Tunnels share these ids...for now)
    [kAbyssStructuresItemId] = gCustomizeSceneData.kAlienStructuresVariantOption,
    [kKodiakAlienStructuresItemId] = gCustomizeSceneData.kAlienStructuresVariantOption,
    [kNocturneStructuresItemId] = gCustomizeSceneData.kAlienStructuresVariantOption,
    [kReaperStructuresItemId] = gCustomizeSceneData.kAlienStructuresVariantOption,
    [kUnearthedStructuresItemId] = gCustomizeSceneData.kAlienStructuresVariantOption,
    [kToxinStructuresItemId] = gCustomizeSceneData.kAlienStructuresVariantOption,
    [kShadowStructuresItemId] = gCustomizeSceneData.kAlienStructuresVariantOption,

    [kAuricCystItemId] = gCustomizeSceneData.kAlienCystVariantOption,

    [kAuricDrifterItemId] = gCustomizeSceneData.kAlienDrifterVariantOption,

    --TD-TODO Add remaining items
}

gCustomizeSceneData.kSceneObjects = 
{
    
---------------------------------------
--Marine Zone Objects
    {
        name = "CommandStation",
        defaultPos = { origin = Vector(0.04, 0.53, 11), angles = Vector(0,0,0) },
        inputParams = 
        {
            { name = "occupied", value = true },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/command_station/command_station.model"),
        graphFile = "cinematics/menu/customize_command_station.animation_graph",
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,    --Indicates this object ONLY uses material swapping for its skins
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.CommandStation,
        zoomedInputParams =  --Denotes what params should be set when object _begins_ to be Zoomed
        { 
            { name = "occupied", value = true }, 
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -20, max = 20},  --Only allow +/- 20 degrees of Pitch
            yaw = { min = nil, max = nil }, --Allow any degree of Yaw
            roll = false                    --Prevent any rotation
        },
        zoomedPositionOffset = Vector( 0, 0, 0 )
    },
    {
        name = "Extractor", 
        defaultPos = { origin = Vector(4.88, -0.48, 10.57), angles = Vector(0,180,0) },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/extractor/extractor.model"),
        graphFile = "cinematics/menu/customize_extractor.animation_graph",
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,    --Indicates this object ONLY uses material swapping for its skins
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Extractor,
        zoomedRotationLocks = 
        { 
            pitch = {min = -20, max = 20},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Mac",
        defaultPos = { origin = Vector(3.925, 1.7315, 12.1085), angles = Vector(0, -135, 0) },
        inputParams = 
        {
            { name = "activity", value = "none", },
            { name = "move", value = "run", },
            { name = "flinch", value = false },
            { name = "alive", value = true },
        },
        poseParams = 
        {
            { name = "move_speed", value = 0.0 },
            { name = "intensity", value = 0.0 },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/mac/mac.model"),
        graphFile = "models/marine/mac/mac.animation_graph",        --TODO! TEMP - Review / Refine
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,    --Indicates this object ONLY uses material swapping for its skins
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Mac,
        zoomedRotationLocks = 
        { 
            pitch = {min = -20, max = 20},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Arc",
        defaultPos = { origin = Vector(5.085, -0.21, 7.565), angles = Vector(0, -100, 0) },
        inputParams = 
        {
            { name = "activity", value = "none", },
            { name = "move", value = "idle", },
            { name = "flinch", value = false },
            { name = "deployed", value = false },
            { name = "alive", value = true },
        },
        poseParams = 
        {
            { name = "arc_yaw", value = 0.0 },
            { name = "arc_pitch", value = 0.0 },
            { name = "move_pitch", value = 0.0 },
            { name = "move_speed", value = 0.0 },
            { name = "intensity", value = 0.0 },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/arc/arc.model"),
        graphFile = "models/marine/arc/arc.animation_graph",           --TODO! TEMP - Review / Refine
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,    --Indicates this object ONLY uses material swapping for its skins
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Arc,
        zoomedRotationLocks = 
        { 
            pitch = {min = -20, max = 20},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },

    {
        name = "MarineLeft", --"Reflects" player's cosmetic choice, but not gender
        defaultPos = { origin = Vector(1.38, -0.75, 3.12), angles = Vector(0, -75, 0) },
        poseParams = 
        {
            { name = "body_pitch", value = -18 },
            { name = "body_yaw", value = -10 },
        },
        inputParams = 
        {
            { name = "move", value = "idle" },
        },
        modelFile = PrecacheAsset("models/marine/male/male.model"),
        graphFile = "cinematics/menu/customize_marine.animation_graph",
        team = kTeam1Index,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Marine,
        customizable = true,
    },
    {
        name = "MarineCenter", --Never changes variant, static scene object
        defaultPos = { origin = Vector(0.19, -0.75, 5.22), angles = Vector(0, -175, 0) },
        poseParams = 
        {
            { name = "body_pitch", value = -32 },
            { name = "body_yaw", value = 6 },
        },
        inputParams = 
        {
            { name = "move", value = "idle" },
        },
        modelFile = PrecacheAsset("models/marine/female/female_special.model"),
        graphFile = "cinematics/menu/customize_marine.animation_graph",
        team = kTeam1Index,
        customizable = true,
        staticVariant = kMarineVariants.special
    },
    {
        name = "MarineRight",  --Target for Player customizations / viewing
        defaultPos = { origin = Vector(-1.84, -0.74, 3), angles = Vector(0, 180, 0) },
        poseParams = 
        {
            { name = "body_pitch", value = 0 }, -- -14
            { name = "body_yaw", value = 0 }, -- 9
        },
        inputParams = 
        {
            { name = "move", value = "idle" },
        },
        modelFile = PrecacheAsset("models/marine/male/male.model"),
        graphFile = "cinematics/menu/customize_marine.animation_graph",
        team = kTeam1Index,
        customizable = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Marine,
        zoomedInputParams = 
        { 
            { name = "activity", value = "none" },
            { name = "move", value = "idle" },
            { name = "alive", value = true },
        },
        zoomedPoseParams = --Denotes what params to set when zoom _begins_
        {
            { name = "body_pitch", value = 0 },
            { name = "body_yaw", value = 0 },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -28, max = 28},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },

    {
        name = "ExoMiniguns", --Target for Player customizations
        defaultPos = { origin = Vector(-8.09, 0.38, 4.92), angles = Vector(0, 90, 0) },
        defaultAnim = "idle",
        poseParams = 
        {
            { name = "body_pitch", value = -50 },
            { name = "body_yaw", value = 8.5 },
        },
        inputParams = 
        {
            { name = "move", value = "idle" },
            { name = "alive", value = true },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/exosuit/exosuit_mm.model"),
        graphFile = "cinematics/menu/customize_exosuit_mm.animation_graph",
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,
        classNameAlias = "Minigun",
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Exo,
        zoomedInputParams = 
        { 
            { name = "move", value = "idle" },
            { name = "alive", value = true },
        },
        zoomedPoseParams = 
        {
            { name = "body_pitch", value = 0 },   --TODO Update to be "straight"
            { name = "body_yaw", value = 0 },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -20, max = 20},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "ExoRailguns", --"Reflects" player's cusmetic choice
        defaultPos = { origin = Vector( -8.09, 0.38, 1.74 ), angles = Vector( 0, 90, 0 ) },
        defaultAnim = "equip",
        isStatic = true,
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/exosuit/exosuit_rr.model"),
        --graphFile = "models/marine/exosuit/exosuit_rr.animation_graph",
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,
        classNameAlias = "Railgun",
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Exo,
        zoomedRotationLocks = 
        { 
            pitch = {min = -18, max = 18},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },

    {
        name = "Rifle",
        defaultPos = { origin = Vector(7.09, 2.1, 4.12), angles = Vector( -90, 90, 0 ) },
        isStatic = true,
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/rifle/rifle.model"),
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Rifle,
        zoomedRotationLocks = 
        { 
            pitch = {min = -32, max = 32},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Pistol",
        defaultPos = { origin = Vector( 7.09, 2.21, 4.97 ), angles = Vector( -90, 90, 0 ) },
        isStatic = true,
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/pistol/pistol.model"),
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Pistol,
        zoomedRotationLocks = 
        { 
            pitch = {min = -32, max = 32},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Welder",
        defaultPos = { origin = Vector( 7.1, 1.83, 4.6 ), angles = Vector( 0, 0, 90 ) },
        isStatic = true,
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/welder/welder.model"),
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Welder,
        zoomedRotationLocks = 
        { 
            pitch = {min = -32, max = 32},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Axe",
        defaultPos = { origin = Vector( 7.1, 1.85, 5.32 ), angles = Vector( -75, 0, 90 ) },
        isStatic = true,
        modelFile = PrecacheAsset("models/marine/axe/axe.model"),
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,    --Indicates this object ONLY uses material swapping for its skins
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Axe,
        zoomedRotationLocks = 
        { 
            pitch = {min = -32, max = 32},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Shotgun",
        defaultPos = { origin = Vector( 7.08, 2.11, 5.95 ), angles = Vector( 90, 90, 0 ) },
        isStatic = true,
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/shotgun/shotgun.model"),
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Shotgun,
        zoomedRotationLocks = 
        { 
            pitch = {min = -32, max = 32},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "GrenadeLauncher",
        defaultPos = { origin = Vector( 7.07, 1.56, 4.38 ), angles = Vector( 90, 90, 0 ) },
        isStatic = true,
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/grenadelauncher/grenadelauncher.model"),
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.GrenadeLauncher,
        zoomedRotationLocks = 
        { 
            pitch = {min = -32, max = 32},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Flamethrower",
        defaultPos = { origin = Vector( 7.07, 1.66, 6 ), angles = Vector( -77.5, -90, -180 ) },
        isStatic = true,
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/flamethrower/flamethrower.model"),
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Flamethrower,
        zoomedRotationLocks = 
        { 
            pitch = {min = -32, max = 32},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "HeavyMachineGun",
        --defaultPos = { origin = Vector( 6.84, 1.22, 4.982 ), angles = Vector( 22.89, -85.53, -5.16 ) },
        defaultPos = { origin = Vector( 6.84, 1.18, 4.982 ), angles = Vector( 23.19, -97.65, -10.58 ) },
        isStatic = true,
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/marine/hmg/hmg.model"),
        team = kTeam1Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.HeavyMachineGun,
        zoomedRotationLocks = 
        { 
            pitch = {min = -32, max = 32},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },

---------------------------------------
--Transition Zone Objects
    {
        name = "VentSkulk", --XXX Could have this be updated on Skin changes too
        defaultPos = { origin = Vector(1.38, -2.38, -0.47), angles = Vector(0, -165, 0) },
        poseParams = 
        {
            { name = "body_pitch", value = -7.65 },
            { name = "body_yaw", value = 90 },
        },
        inputParams = 
        {
            { name = "move", value = "idle" },
            { name = "alive", value = true },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/skulk/skulk.model"),
        graphFile = "models/alien/skulk/skulk.animation_graph",
        team = kTeam2Index,
        customizable = false,  --Could change to true for a little extra fluff
    },
    {
        name = "VentSkulkBabblerBuddy", 
        defaultPos = { origin = Vector(-1.5, -2.34, -0.4), angles = Vector(0, 80, 0) },
        inputParams = 
        {
            { name = "move", value = "wag" },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/babbler/babbler.model"),
        graphFile = "models/alien/babbler/babbler.animation_graph",
        team = kTeam2Index,
    },

---------------------------------------
--Alien Zone Objects

    --Filler Objects
    {
        name = "FillerCyst",
        defaultPos = { origin = Vector(-7.75, -8.22, 4.22 ), angles = Vector(-3.21, -14.65, -14.16) },
        inputParams = 
        {
            { name = "alive", value = true },
        },
        defaultTexIndex = 0,
        usesMaterialSwapping = true,
        customizable = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Cyst,
        modelFile = PrecacheAsset("models/alien/cyst/cyst.model"),
        graphFile = "models/alien/cyst/cyst.animation_graph",
        team = kTeam2Index,
    },

    --Strutures
    {
        name = "AlienTechPoint", 
        defaultPos = { origin = Vector(3.05, -10.33, 11.31 ), angles = Vector(0, 0, 0) },
        inputParams = 
        {
            { name = "hive_deploy", value = true },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/misc/tech_point/tech_point.model"),
        graphFile = "models/misc/tech_point/tech_point.animation_graph",
        team = kTeam2Index
    },
    {
        name = "Hive", 
        defaultPos = { origin = Vector(3.13, -8.175, 10.92 ), angles = Vector(0, 0, 0) },
        inputParams = 
        {
            { name = "built", value = true },
            { name = "alive", value = true },
            { name = "occupied", value = true },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/hive/hive.model"),
        graphFile = "models/alien/hive/hive.animation_graph",
        team = kTeam2Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Hive,
        zoomedInputParams = 
        {
            { name = "built", value = true },
            { name = "alive", value = true },
            { name = "occupied", value = true },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -15, max = 15},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Harvester", 
        defaultPos = { origin = Vector(-1.88, -10.35, 11.88 ), angles = Vector(0, 155, 0) },
        inputParams = 
        {
            { name = "built", value = true },
            { name = "alive", value = true },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/harvester/harvester.model"),
        graphFile = "models/alien/harvester/harvester.animation_graph",
        team = kTeam2Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Harvester,
        zoomedInputParams = 
        {
            { name = "built", value = true },
            { name = "alive", value = true },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -18, max = 18},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Egg", 
        defaultPos = { origin = Vector(-0.61, -10.38, 9.51 ), angles = Vector(0, -55, 0) },
        inputParams = 
        {
            { name = "built", value = true },
            { name = "alive", value = true },
            { name = "spawned", value = true },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/egg/egg.model"),
        graphFile = "models/alien/egg/egg.animation_graph",
        team = kTeam2Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Egg,
        zoomedInputParams = 
        {
            { name = "built", value = true },
            { name = "alive", value = true },
            { name = "spawned", value = true },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -22, max = 22},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Cyst", 
        defaultPos = { origin = Vector(-0.06, -10.38, 12.81 ), angles = Vector(0, 65, 0) },
        inputParams = 
        {
            { name = "alive", value = true },
            { name = "spawning", value = false },
            { name = "popped", value = false },
        },
        poseParams = 
        {
            { name = "intensity", value = 0.0 },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/cyst/cyst.model"),
        graphFile = "models/alien/cyst/cyst.animation_graph", --?? replace with trimmed?
        team = kTeam2Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Cyst,
        zoomedInputParams = 
        {
            { name = "alive", value = true },
            { name = "spawning", value = false },
            { name = "popped", value = false },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -22, max = 22},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Drifter", 
        defaultPos = { origin = Vector(4.5, -9.325, 8.125 ), angles = Vector(0, -100, 0) },
        inputParams = 
        {
            { name = "alive", value = true },
            { name = "onfire", value = false },
            { name = "flinch", value = false },
            { name = "activity", value = "none" },
            { name = "move", value = "run" },
        },
        poseParams = 
        {
            { name = "move_yaw", value = 90.0 },
            { name = "move_speed", value = 1.0 },
            { name = "intensity", value = 0.0 },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/drifter/drifter.model"),
        graphFile = "models/alien/drifter/drifter.animation_graph", --?? replace with trimmed?
        team = kTeam2Index,
        customizable = true,
        usesMaterialSwapping = true,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Drifter,
        zoomedInputParams = 
        {
            { name = "alive", value = true },
            { name = "onfire", value = false },
            { name = "flinch", value = false },
            { name = "activity", value = "none" },
            { name = "move", value = "run" },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -22, max = 22},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },

    --Lifeforms
    {
        name = "Skulk", 
        --defaultPos = { origin = Vector( -7.59, -9.35, 6.87 ), angles = Vector(16.74, 157.3, 63.07) },
        defaultPos = { origin = Vector( -7.5, -9, 7 ), angles = Vector( 13.95, 164.73, 69.77 ) },
        poseParams = 
        {
            { name = "body_pitch", value = 38 },
            { name = "body_yaw", value = 12 },
        },
        inputParams = 
        {
            { name = "alive", value = true },
            { name = "move", value = "idle" },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/skulk/skulk.model"),
        graphFile = "cinematics/menu/customize_skulk.animation_graph",
        team = kTeam2Index,
        customizable = true,
        usesHybridSkins = true,     --Denotes this cosmetic uses a mix of material swapping and model switching
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Skulk,
        zoomedPoseParams = 
        {
            { name = "body_pitch", value = 0 },
            { name = "body_yaw", value = 0 },
        },
        zoomedInputParams = 
        {
            { name = "alive", value = true },
            { name = "move", value = "idle" }, --taunt
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -35, max = 35},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Lerk", 
        --defaultPos = { origin = Vector( -9.35, -7.75, 6.7 ), angles = Vector(5, 84, 0) },
        defaultPos = { origin = Vector( -8.88, -7.75, 7.5 ), angles = Vector(5, 84, 0) },
        poseParams = 
        {
            { name = "body_pitch", value = 16 },   --{ name = "body_pitch", value = -15 },
            { name = "body_yaw", value = -24 },     --{ name = "body_yaw", value = -75 },
        },
        inputParams = 
        {
            { name = "alive", value = true },
            { name = "move", value = "idle" },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/lerk/lerk.model"),
        graphFile = "cinematics/menu/customize_lerk.animation_graph",
        team = kTeam2Index,
        customizable = true,
        usesHybridSkins = true,     --Denotes this cosmetic uses a mix of material swapping and model switching
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Lerk,
        zoomedPoseParams = 
        {
            { name = "body_pitch", value = 0 },
            { name = "body_yaw", value = 0 },
        },
        zoomedInputParams = 
        {
            { name = "alive", value = true },
            { name = "move", value = "idle" },
            { name = "activity", value = "none" },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -36, max = 36},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Fade", 
        defaultPos = { origin = Vector( -4.3, -10.38, 11.95 ), angles = Vector(0, 218.5, 0) },
        poseParams = 
        {
            { name = "body_pitch", value = 12 },
            { name = "body_yaw", value = 90 },
            { name = "crouch", value = 0 }, --0.285
        },
        inputParams = 
        {
            { name = "alive", value = true },
            { name = "move", value = "idle" },
            { name = "activity", value = "none" },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/fade/fade.model"),
        graphFile = "cinematics/menu/customize_fade.animation_graph",
        team = kTeam2Index,
        customizable = true,
        usesHybridSkins = true,     --Denotes this cosmetic uses a mix of material swapping and model switching
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Fade,
        zoomedPoseParams = 
        {
            { name = "body_pitch", value = 0 },
            { name = "body_yaw", value = 0 },
        },
        zoomedInputParams = 
        {
            { name = "alive", value = true },
            { name = "move", value = "idle" },
            { name = "activity", value = "none" },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -30, max = 30},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Onos", 
        defaultPos = { origin = Vector( -7.25, -10.38, 11.85 ), angles = Vector(0, 140, 0) },
        poseParams = 
        {
            { name = "body_pitch", value = 11.45 },
            { name = "body_yaw", value = 0 },
            { name = "stoop", value = 0.5 },
        },
        inputParams = 
        {
            { name = "alive", value = true },
            { name = "move", value = "idle" },
            { name = "activity", value = "none" },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/onos/onos.model"),
        graphFile = "cinematics/menu/customize_onos.animation_graph",
        team = kTeam2Index,
        customizable = true,
        usesHybridSkins = true,     --Denotes this cosmetic uses a mix of material swapping and model switching
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Onos,
        zoomedPoseParams = 
        {
            { name = "body_pitch", value = 0 },
            { name = "body_yaw", value = 0 },
        },
        zoomedInputParams = 
        {
            { name = "alive", value = true },
            { name = "move", value = "idle" },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -28, max = 28},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },

    --Gorge-n-Toys
    {
        name = "Gorge", 
        defaultPos = { origin = Vector( -6.425, -10.325, 8.65 ), angles = Vector( 0, 115, 0 ) },
        poseParams = 
        {
            { name = "body_pitch", value = 20 },
            { name = "body_yaw", value = -45.75 },
        },
        inputParams = 
        {
            { name = "alive", value = true },
            { name = "move", value = "idle" },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/gorge/gorge.model"),
        graphFile = "cinematics/menu/customize_gorge.animation_graph",
        team = kTeam2Index,
        customizable = true,
        usesHybridSkins = true,     --Denotes this cosmetic uses a mix of material swapping and model switching
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Gorge,
        zoomedPoseParams = 
        {
            { name = "body_pitch", value = 0 },
            { name = "body_yaw", value = 0 },
        },
        zoomedInputParams = 
        {
            { name = "alive", value = true },
            { name = "move", value = "idle" },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -28, max = 28},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
    {
        name = "Hydra", 
        --defaultPos = { origin = Vector( -8.3, -8.725, 9.76 ), angles = Vector( -41.7, 11.59, -60.63 ) },
        defaultPos = { origin = Vector( -9.13, -7.88, 9.72 ), angles = Vector( -27.61, -13.01, -30.6 ) },
        inputParams = 
        {
            { name = "alive", value = true },
            { name = "built", value = true },
            --{ name = "alerting", value = true },  --TODO Change to idle-timed routine to trigger for X seconds
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/hydra/hydra.model"),
        graphFile = "models/alien/hydra/hydra.animation_graph",
        team = kTeam2Index,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Hydra,
        customizable = true,
        usesHybridSkins = true,
    },
    {
        name = "Clog",
        --defaultPos = { origin = Vector(-5.45, -10.7, 7.4), angles = Vector(0, -30, 35) },
        defaultPos = { origin = Vector(-8.365, -8.785, 9.615), angles = Vector(0, -30, 35) },
        isStatic = true,
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/gorge/clog.model"),
        team = kTeam2Index,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Clog,
        customizable = true,
    },
    {
        name = "BabblerEgg", 
        --defaultPos = { origin = Vector(-5.35, -9.88, 9.25), angles = Vector(-74.21, 108.02, 71.32) },
        defaultPos = { origin = Vector(-6.15, -10.13, 7), angles = Vector(-74.21, 108.02, 71.32) },
        poseParams = 
        {
            { name = "grow", value = 0.8 },
        },
        inputParams = 
        {
            { name = "alive", value = true },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/babbler/babbler_egg.model"),
        graphFile = "models/alien/babbler/babbler_egg.animation_graph",
        team = kTeam2Index,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.BabblerEgg,
        customizable = true,
        usesHybridSkins = true,
    },
    {
        name = "Babbler",
        defaultPos = { origin = Vector(-5.60, -10.38, 9.4), angles = Vector( -7.5, 180, -2 ) },
        inputParams = 
        {
            { name = "move", value = "idle" },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/babbler/babbler.model"),
        graphFile = "models/alien/babbler/babbler.animation_graph",
        team = kTeam2Index,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Babbler,
        customizable = true,
        usesHybridSkins = true,
    },
    {
        name = "BabblerTwo",
        defaultPos = { origin = Vector(-5.13, -10.38, 9.93), angles = Vector( -7.5, 125, -2 ) },
        inputParams = 
        {
            { name = "move", value = "idle" },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/babbler/babbler.model"),
        graphFile = "models/alien/babbler/babbler.animation_graph",
        team = kTeam2Index,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Babbler,
        customizable = true,
        usesHybridSkins = true,
    },
    {
        name = "BabblerThree",
        defaultPos = { origin = Vector(-4.5, -10.38, 10.3), angles = Vector( -7.5, 100, -2 ) },
        inputParams = 
        {
            { name = "move", value = "idle" },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/babbler/babbler.model"),
        graphFile = "models/alien/babbler/babbler.animation_graph",
        team = kTeam2Index,
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Babbler,
        customizable = true,
        usesHybridSkins = true,
    },

    --Tunnels
    {
        name = "Tunnel", 
        defaultPos = { origin = Vector(-2.85, -10.64, 6.53 ), angles = Vector(0, 0, 0) },
        inputParams = 
        {
            { name = "built", value = true },
            { name = "open", value = true },
            { name = "skip_open", value = true },
        },
        defaultTexIndex = 0,
        modelFile = PrecacheAsset("models/alien/tunnel/mouth.model"),
        graphFile = "models/alien/tunnel/mouth.animation_graph",
        team = kTeam2Index,
        customizable = true,
        usesHybridSkins = true,     --Denotes this cosmetic uses a mix of material swapping and model switching
        cosmeticId = gCustomizeSceneData.kSceneObjectReferences.Tunnel,
        zoomedInputParams = 
        {
            { name = "built", value = true },
            { name = "open", value = true },
            { name = "skip_open", value = true },
        },
        zoomedRotationLocks = 
        { 
            pitch = {min = -18, max = 18},
            yaw = { min = nil, max = nil },
            roll = false
        }
    },
}

local function PreacheGraphs()
    for i = 1, #gCustomizeSceneData.kSceneObjects do
        if gCustomizeSceneData.kSceneObjects[i].graphFile then
            Client.PrecacheLoadAnimationGraph(gCustomizeSceneData.kSceneObjects[i].graphFile)
        end
    end
end
--This must be done via this event because the needed function isn't active until then
Event.Hook("LoadComplete", PreacheGraphs)


local function GetSceneCinematicCoords( origin, yaw, pitch, roll )
    assert(origin)
    local angle = Angles()
    angle.yaw = yaw and yaw or 0
    angle.pitch = pitch and pitch or 0
    angle.roll = roll and roll or 0
    return angle:GetCoords( origin )
end

gCustomizeSceneData.kSceneCinematics =
{
    {
        fileName = gCustomizeSceneData.kHiveTechpointFX,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 3.05, -10.33, 11.31 ) ),
    },
    {
        fileName = gCustomizeSceneData.kHiveTechpointLightFX,
        playbackType = Cinematic.Repeat_Loop,
        coords = GetSceneCinematicCoords( Vector( 3.05, -10.33, 11.31 ) ),
    },
    {
        fileName = gCustomizeSceneData.kHiveWisps,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 3.13, -9.5, 10.92 ) ),
    },
    {
        fileName = gCustomizeSceneData.kHiveWisps_Toxin,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 3.13, -9.5, 10.92 ) ),
        initVisible = false
    },
    {
        fileName = gCustomizeSceneData.kHiveWisps_Reaper,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 3.13, -9.5, 10.92 ) ),
        initVisible = false
    },
    {
        fileName = gCustomizeSceneData.kHiveWisps_Shadow,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 3.13, -9.5, 10.92 ) ),
        initVisible = false
    },
    {
        fileName = gCustomizeSceneData.kHiveWisps_Kodiak,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 3.13, -9.5, 10.92 ) ),
        initVisible = false
    },
    {
        fileName = gCustomizeSceneData.kHiveWisps_Abyss,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 3.13, -9.5, 10.92 ) ),
        initVisible = false
    },
    {
        fileName = gCustomizeSceneData.kHiveWisps_Nocturne,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 3.13, -9.5, 10.92 ) ),
        initVisible = false
    },
    {
        fileName = gCustomizeSceneData.kHiveWisps_Unearthed,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 3.13, -9.5, 10.92 ) ),
        initVisible = false
    },
    {
        fileName = gCustomizeSceneData.kHiveWisps_Auric,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 3.13, -9.5, 10.92 ) ),
        initVisible = false
    },
    {
        fileName = gCustomizeSceneData.kHiveMist,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 2.925, -7.88, 10.9 ) ),
    },

    --[[
    {
        fileName = gCustomizeSceneData.kLavaBubbleFX,
        playbackType = Cinematic.Repeat_Loop,
        coords = GetSceneCinematicCoords( Vector( 2.31, -14, 5.2 ) ),
    },
    {
        fileName = gCustomizeSceneData.kLavaBubbleFX,
        playbackType = Cinematic.Repeat_Loop,
        coords = GetSceneCinematicCoords( Vector( 2.63, -13.75, 6.13 ), -90 ),
    },
    {
        fileName = gCustomizeSceneData.kLavaBubbleFX,
        playbackType = Cinematic.Repeat_Loop,
        coords = GetSceneCinematicCoords( Vector( -6.75, -14, 5 ), 45 ),
    },
    --]]
    {
        fileName = gCustomizeSceneData.kLavaFallFX,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 7, -7.925, 6 ), -90 ),
    },
    {
        fileName = gCustomizeSceneData.kLavaFallFX,
        playbackType = Cinematic.Repeat_Endless,
        coords = GetSceneCinematicCoords( Vector( 5.65, -12.36, 5.88 ), -90 ),
    },
    --[[
    {
        fileName = gCustomizeSceneData.kMoseyingDrifter,
        playbackType = Cinematic.Repeat_Loop,
        coords = GetSceneCinematicCoords( Vector( 2.2425, -4.865, 6.975 ), -89 ),
    },
    --]]
}

--[[
k4x3_AspectRatio = 4/3
k16x9_AspectRatio = 16/9
k16x10_AspectRatio = 16/10
k21x9_AspectRatio = 21/9
--]]

gCustomizeSceneData.kCameraViewPositions = 
{

    ---------------------------------------
    --Marine Camera View Positions
    [gCustomizeSceneData.kViewLabels.DefaultMarineView] = 
    { 
        origin = Vector( 1.425, 1.75, -1.45 ),
        target = Vector( 0.115, 0.115, 8.9 ),
        fov = 
        {
            [k4x3_AspectKey] = 109,
            [k16x9_AspectKey] = 92,
            [k16x10_AspectKey] = 98,
            [k21x9_AspectKey] = 76,
        },
        animTime = 2,
        activationDist = 0.3,
        team = kTeam1Index
    },
    [gCustomizeSceneData.kViewLabels.Marines] = 
    {
        origin = Vector( -1.985, 0.65, 1 ),
        target = Vector( -1.68, -0.125, 5.98 ),
        fov = 
        {
            [k4x3_AspectKey] = 66,
            [k16x9_AspectKey] = 68,
            [k16x10_AspectKey] = 67,
            [k21x9_AspectKey] = 68,
        },
        animTime = 1.75,
        activationDist = 0.0085,
        team = kTeam1Index,
        --TODO Add "LookUp" callback (needs reset when moving away...so "OnBlur" and "OnFocus")
    },
    [gCustomizeSceneData.kViewLabels.ShoulderPatches] = 
    {
        origin = Vector( -2.6, 1, 2.585 ),
        target = Vector( -1.05, 0.35, 3.39 ),
        fov = 
        {
            [k4x3_AspectKey] = 58,
            [k16x9_AspectKey] = 54,
            [k16x10_AspectKey] = 56,
            [k21x9_AspectKey] = 56,
        },
        animTime = 0.5,
        activationDist = 0.0085,
        team = kTeam1Index
    },
    [gCustomizeSceneData.kViewLabels.ExoBay] = 
    {
        origin = Vector(-2.55, 3.4925, 3.15),
        target = Vector( -11.5, 1.05, 3.5 ),
        fov = 
        {
            [k4x3_AspectKey] = 58,
            [k16x9_AspectKey] = 48,
            [k16x10_AspectKey] = 50,
            [k21x9_AspectKey] = 50,
        },
        animTime = 4.5,
        activationDist = 0.0085,
        team = kTeam1Index
    },
    [gCustomizeSceneData.kViewLabels.Armory] = 
    {
        origin = Vector(4.25, 1.785, 4.9328),
        target = Vector( 7.11, 1.5, 4.9225 ),
        fov = 
        {
            [k4x3_AspectKey] = 56,
            [k16x9_AspectKey] = 50,
            [k16x10_AspectKey] = 51,
            [k21x9_AspectKey] = 50,
        },
        animTime = 6,
        activationDist = 0.0085,
        team = kTeam1Index
    },
    [gCustomizeSceneData.kViewLabels.MarineStructures] = 
    {
        origin = Vector( 1.65, 4, 4.15 ),
        target = Vector( 2.88, 0.1, 12.5 ),
        fov = 
        {
            [k4x3_AspectKey] = 84,
            [k16x9_AspectKey] = 74,
            [k16x10_AspectKey] = 72,
            [k21x9_AspectKey] = 72,
        },
        animTime = 1,
        activationDist = 0.0085,
        team = kTeam1Index
    },
    

    ---------------------------------------
    --Transition Vent / Team-View change mid-point
    [gCustomizeSceneData.kViewLabels.TeamTransition] = 
    {
        origin = Vector( 0.65, -1.5, -4.5 ),
        target = Vector( 0, -1.38, 1.38 ),
        fov = 88,
        animTime = 1.75,
        activationDist = 0.2,
        startMoveDelay = 0.8,
        --These "relay" into their intended views, based on the team-value of a target view
        targetTeam1View = gCustomizeSceneData.kViewLabels.DefaultMarineView,
        targetTeam2View = gCustomizeSceneData.kViewLabels.DefaultAlienView
    },

    ---------------------------------------
    --Alien Camera View Positions
    [gCustomizeSceneData.kViewLabels.DefaultAlienView] = 
    {
        origin = Vector( -0.07, -5.725, -2.6 ),
        target = Vector( -3.35, -11, 16.5 ),
        fov = 
        {
            [k4x3_AspectKey] = 80,
            [k16x9_AspectKey] = 69,
            [k16x10_AspectKey] = 72,
            [k21x9_AspectKey] = 58,
        },
        animTime = 2,
        activationDist = 0.3,
    },
    [gCustomizeSceneData.kViewLabels.AlienStructures] = 
    {
        origin = Vector( -1.75, -7.25, 5.25 ),
        target = Vector( 3.125, -10.4925, 13.705 ),
        fov = 
        {
            [k4x3_AspectKey] = 81,
            [k16x9_AspectKey] = 65,
            [k16x10_AspectKey] = 67,
            [k21x9_AspectKey] = 68,
        },
        animTime = 2,
        activationDist = 0.0085,
    },
    [gCustomizeSceneData.kViewLabels.AlienLifeforms] = 
    {
        origin = Vector( -2.1, -8.2, 6.585 ),
        target = Vector( -9.25, -10, 11.25 ),
        fov = 
        {
            [k4x3_AspectKey] = 84,
            [k16x9_AspectKey] = 70,
            [k16x10_AspectKey] = 74,
            [k21x9_AspectKey] = 67,
        },
        animTime = 4,
        activationDist = 0.0085,
    },
    [gCustomizeSceneData.kViewLabels.AlienTunnels] = 
    {
        origin = Vector( -1.25, -8, 1.88 ),
        target = Vector( -3.7, -12.15, 8.45 ),
        fov = 
        {
            [k4x3_AspectKey] = 40,
            [k16x9_AspectKey] = 38,
            [k16x10_AspectKey] = 40,
            [k21x9_AspectKey] = 36,
        },
        animTime = 3.75,
        activationDist = 0.0085,
    },

}

gCustomizeSceneData.kDefaultViewLabel = gCustomizeSceneData.kViewLabels.DefaultMarineView
gCustomizeSceneData.kDefaultView = gCustomizeSceneData.kCameraViewPositions[gCustomizeSceneData.kDefaultViewLabel]


-------------------------------------------------------------------------------
--- Customize Scene Button World Positions data

--Index for world-button world-position data sets
gCustomizeSceneData.kWorldButtonLabels = enum({

--Marine Default View
    "MarineArmors", "MarineWeapons", "MarineStructures", "MarineExos",

    --Marine Weapons View
    "Rifle", "Pistol", "Axe", "Welder",
    "Shotgun", "Flamethrower", "HeavyMachineGun", "GrenadeLauncher",

    --Marine Armors View
    "Armors", "Gender", "Voices",

    --Shoulder Patch View
    "ShoulderPatchMale", "ShoulderPatchFemale", "ShoulderPatchBigmac",

    --Marine Structures View
    "CommandStation", "Extractor", "MAC", "ARC",

    --Marine Exosuits View
    "Minigun", "Railgun",


--Default Alien View
    "AlienLifeforms", "AlienTunnels", "AlienStructures",

    --Alien Lifeforms View
    "Skulk", "Lerk", "Gorge", "Fade", "Onos",
    "Babblers", "Hydra", "Clog", "BileMine",

    --Alien Tunnels View
    "Tunnel",

    --Alien Structures View
    "Hive", "Harvester", "Egg", "Cyst", "Drifter"

})

--Table contains lists of customize-scene world-positions of button polygon points
--vector lists in this are used to construct the GUI Shaped buttons for each interactive "group".
--See GUIMenuCustomizeWorldButton.lua
gCustomizeSceneData.WorldButtonPositionSets = 
{

--Marine Default View Buttons -------------------
    [gCustomizeSceneData.kWorldButtonLabels.MarineWeapons] = 
    {
        Vector(6.63, 2.25, 3.5),
        Vector(6.63, 1, 3.5),
        Vector(6.63, 1, 6.38),
        Vector(6.63, 2.25, 6.38)
    },

    [gCustomizeSceneData.kWorldButtonLabels.MarineArmors] = 
    {
        Vector(1.63, 1.13, 2.98),
        Vector(1.88, -0.88, 2.98),
        Vector(-2.38, -0.88, 2.75),
        Vector(-2.63, 1.13, 3.25),
        Vector(0.13, 1.13, 5.25)
    },

    [gCustomizeSceneData.kWorldButtonLabels.MarineExos] = 
    {
        Vector( -8.18, 2.78, 5.75 ),
        Vector( -6.88, 2.15, 5.63 ),
        Vector( -7.5, 0.37, 5.5 ),
        Vector( -8.25, 0.38, 4.13 ),
        Vector( -9.25, 1.63, 3.75 ),
        Vector( -8.38, 2.72, 4.13 ),
        Vector( -8.5, 3.25, 4.75 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.MarineStructures] = 
    {
        Vector( 6.52, 0, 7.14 ),
        Vector( 5.9, 0.82, 7.52 ),
        Vector( 5.77, 1.28, 10.38 ),
        Vector( 4.87, 1.73, 10.49 ),
        Vector( 4.55, 3.11, 11.79 ),
        Vector( 0.89, 3.79, 9.99 ),
        Vector( -0.91, 3.71, 10 ),
        Vector( -2.22, 0.53, 8.62 ),
        Vector( 2.26, 0.52, 8.6 ),
        Vector( 3.94, -0.25, 7.14 ),
    },

--Marine Structures View ------------------------
    [gCustomizeSceneData.kWorldButtonLabels.CommandStation] = 
    {
        Vector( 0.85, 0.43, 7.72 ),
        Vector( -0.8, 0.43, 7.71 ),
        Vector( -2.08, 0.54, 8.99 ),
        Vector( -2.4, 0.54, 10.03 ),
        Vector( -1.12, 2.51, 10.06 ),
        Vector( -1.4, 2.19, 12.99 ),
        Vector( -0.95, 2.56, 13.07 ),
        Vector( -0.88, 3.52, 13.07 ),
        Vector( 0.45, 3.48, 13.07 ),
        Vector( 0.46, 2.56, 13.07 ),
        Vector( 1.34, 2.23, 13.07 ),
        Vector( 2.28, 0.67, 13.22 ),
        Vector( 2.41, 0.54, 10.21 ),
        Vector( 1.93, 0.54, 8.83 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Extractor] = 
    {
        Vector( 3.93, -0.43, 9.66 ),
        Vector( 3.87, -0.39, 11.47 ),
        Vector( 3.96, 1.2, 11.47 ),
        Vector( 5.1, 1.54, 11.47 ),
        Vector( 6.14, 1.08, 11.47 ),
        Vector( 6.14, 0.74, 10.24 ),
        Vector( 5.89, -0.56, 9.73 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.MAC] = 
    {
        Vector( 3.19, 1.74, 11.67 ),
        Vector( 3.35, 2.15, 11.7 ),
        Vector( 3.32, 2.83, 11.7 ),
        Vector( 3.9, 3.2, 11.93 ),
        Vector( 4.49, 2.98, 11.93 ),
        Vector( 4.32, 2.36, 12.09 ),
        Vector( 3.92, 1.75, 11.61 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.ARC] = 
    {
        Vector( 4.17, -0.25, 6.62 ),
        Vector( 3.79, -0.25, 8.3 ),
        Vector( 5, -0.25, 8.84 ),
        Vector( 6.55, -0.26, 9.18 ),
        Vector( 6.57, 1.29, 8.21 ),
        Vector( 6.44, 1.09, 7.55 ),
        Vector( 6.48, -0.21, 6.97 ),
    },

--Marine Weapons View ---------------------------
    [gCustomizeSceneData.kWorldButtonLabels.Rifle] = 
    {
        Vector( 7.11, 1.84, 3.95 ),
        Vector( 7.11, 2.05, 3.57 ),
        Vector( 6.93, 2.14, 3.63 ),
        Vector( 7.11, 2.2, 3.89 ),
        Vector( 7.05, 2.19, 4.12 ),
        Vector( 7.11, 2.15, 4.5 ),
        Vector( 7.15, 2.01, 4.49 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Pistol] = 
    {
        Vector( 7.11, 2.13, 4.76 ),
        Vector( 7.11, 2.25, 4.76 ),
        Vector( 7.11, 2.25, 5.04 ),
        Vector( 7.11, 2.09, 5.08 ),
        Vector( 7.11, 2.05, 5.01 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Welder] = 
    {
        Vector( 7.11, 1.74, 4.57 ),
        Vector( 7.11, 1.92, 4.55 ),
        Vector( 7.11, 1.97, 4.76 ),
        Vector( 7.11, 1.91, 4.78 ),
        Vector( 7.11, 1.88, 4.72 ),
        Vector( 7.11, 1.75, 4.7 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Axe] = 
    {
        Vector( 7.11, 1.78, 4.97 ), 
        Vector( 7.11, 1.8, 4.88 ),
        Vector( 7.11, 1.98, 4.93 ),
        Vector( 7.11, 1.86, 5.35 ),
        Vector( 7.11, 1.78, 5.33 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Shotgun] = 
    {
        Vector( 7.11, 2.01, 5.36 ),
        Vector( 7.11, 2.11, 5.29 ),
        Vector( 7.11, 2.17, 5.91 ),
        Vector( 7.11, 2.14, 6.21 ),
        Vector( 7.11, 1.98, 6.21 ),
        Vector( 7.11, 1.93, 6 ),
        Vector( 7.11, 1.97, 5.91 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.GrenadeLauncher] = 
    {
        Vector( 7.11, 1.45, 3.93 ),
        Vector( 7.11, 1.57, 3.72 ),
        Vector( 7.11, 1.81, 3.73 ),
        Vector( 7.11, 1.78, 4.12 ),
        Vector( 7.11, 1.72, 4.49 ),
        Vector( 7.11, 1.67, 4.62 ),
        Vector( 7.11, 1.57, 4.61 ),
        Vector( 7.11, 1.45, 4.33 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Flamethrower] = 
    {
        Vector( 7.11, 1.41, 5.55 ),
        Vector( 7.11, 1.52, 5.14 ),
        Vector( 7.11, 1.57, 4.87 ),
        Vector( 7.11, 1.68, 5.02 ),
        Vector( 7.11, 1.73, 5.4 ),
        Vector( 7.11, 1.85, 5.61 ),
        Vector( 7.11, 1.72, 5.89 ),
        Vector( 7.11, 1.73, 6.14 ),
        Vector( 7.11, 1.64, 6.28 ),
        Vector( 7.11, 1.55, 6.25 ),
        Vector( 7.11, 1.43, 5.87 ),
        Vector( 7.11, 1.32, 5.78 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.HeavyMachineGun] = 
    {
        Vector( 6.68, 1.13, 4.8 ),
        Vector( 6.75, 1.27, 4.45 ),
        Vector( 6.75, 1.43, 4.45 ),
        Vector( 6.75, 1.5, 4.52 ),
        Vector( 6.75, 1.41, 5.08 ),
        Vector( 6.75, 1.24, 5.61 ),
        Vector( 6.75, 1.2, 5.61 ),
        Vector( 6.75, 1.15, 5.41 ),
        Vector( 6.75, 1.18, 5.04 ),
        Vector( 6.75, 1.04, 4.96 ),
    },

--Marine Shoulder Patches -----------------------
    [gCustomizeSceneData.kWorldButtonLabels.ShoulderPatchMale] = 
    {
        Vector( -2, 0.7, 2.8 ),
        Vector( -2, 0.85, 2.8 ),
        Vector( -2.02, 0.85, 2.91 ),
        Vector( -2.02, 0.69, 2.96 ),
    },
    
    [gCustomizeSceneData.kWorldButtonLabels.ShoulderPatchFemale] =  --TODO Update
    {
        Vector( -2, 0.72, 2.92 ),
        Vector( -2, 0.88, 2.92 ),
        Vector( -2.02, 0.88, 3.02 ),
        Vector( -2.02, 0.72, 3.09 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.ShoulderPatchBigmac] = --TODO Update
    {
        Vector( -2.05, 0.83, 2.755 ),
        Vector( -2.05, 0.91, 2.755 ),
        Vector( -1.98, 0.91, 2.865 ),
        Vector( -1.98, 0.83, 2.915 ),
    },

--Marine Armor View -----------------------------
    [gCustomizeSceneData.kWorldButtonLabels.Armors] = 
    {
        Vector( -1.38, -0.8, 3.03 ),
        Vector( -1.46, 0.71, 3.05 ),
        Vector( -1.67, 1.17, 3.04 ),
        Vector( -1.92, 1.17, 3 ),
        Vector( -2.15, 0.63, 2.92 ),
        Vector( -2.18, -0.75, 2.99 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Gender] = 
    {
        Vector( 0.58, -0.75, 5.22 ),
        Vector( 0.58, 0.84, 5.26 ),
        Vector( 0.34, 1.11, 5.25 ),
        Vector( 0.13, 1.13, 5.38 ),
        Vector( -0.16, 0.63, 5.38 ),
        Vector( -0.21, -0.75, 5.12 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Voices] = 
    {
        Vector( -1.96, 1.06, 3.13 ),
        Vector( -2.10, 1.145, 3.13 ),
        Vector( -2.10, 0.98, 3.13 ),
    },

--Marine Exosuits View --------------------------
    [gCustomizeSceneData.kWorldButtonLabels.Minigun] = 
    {
        Vector( -7.5, 0.37, 5.88 ),
        Vector( -7.07, 1.86, 5.9 ),
        Vector( -8.18, 2.78, 5.75 ),
        Vector( -8.5, 3.19, 5.27 ),
        Vector( -8.5, 3.19, 4.46 ),
        Vector( -8.38, 2.62, 3.85 ),
        Vector( -8.5, 1.77, 3.8 ),
        Vector( -7.92, 0.38, 3.92 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Railgun] = 
    {
        Vector( -7.42, 0.38, 2.76 ),
        Vector( -7.8, 1.66, 2.65 ),
        Vector( -8.16, 2.22, 2.44 ),
        Vector( -8.41, 2.57, 2.09 ),
        Vector( -8.58, 3.38, 1.88 ),
        Vector( -8.65, 3.38, 1.53 ),
        Vector( -8.39, 2.55, 1.33 ),
        Vector( -8.26, 2.21, 0.99 ),
        Vector( -7.8, 1.66, 0.77 ),
        Vector( -7.45, 0.38, 0.46 ),
    },
    

--Alien Default View Buttons --------------------
    [gCustomizeSceneData.kWorldButtonLabels.AlienStructures] = 
    {
        Vector( 5.13, -10.03, 8.38 ),
        Vector( 6.17, -9.43, 8.97 ),
        Vector( 6.04, -5.29, 10.92 ),
        Vector( 0.36, -4.86, 9.79 ),
        Vector( 1.43, -9.95, 14.42 ),
        Vector( -1.3, -10.32, 14.43 ),
        Vector( -1.9, -8.22, 14.39 ),
        Vector( -3.42, -8.3, 14.36 ),
        Vector( -3.33, -10.44, 12.89 ),
        Vector( -1.77, -10.37, 9.25 ),
        Vector( 0, -10.38, 8.51 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.AlienTunnels] = 
    {
        Vector( -2.71, -10.6, 5.13 ),
        Vector( -1.25, -10.44, 6.12 ),
        Vector( -2, -9.38, 6.63 ),
        Vector( -3.88, -9.88, 7.13 ),
        Vector( -4, -10.4, 5.88 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.AlienLifeforms] = 
    {
        Vector( -5.99, -10.73, 6.93 ),
        Vector( -5.54, -10.38, 8.31 ),
        Vector( -4.05, -10.38, 9.95 ),
        Vector( -3.47, -10.37, 12.53 ),
        Vector( -4.4, -9.37, 14.42 ),
        Vector( -5.72, -9.31, 14.43 ),
        Vector( -6, -10.38, 13.4 ),
        Vector( -6.6, -10.38, 13.5 ),
        Vector( -6.89, -7.58, 14.77 ),
        Vector( -10.33, -7.63, 14.78 ),
        Vector( -11.23, -8.48, 14.39 ),
        Vector( -8.88, -6.88, 9.66 ),
        Vector( -10.89, -6.82, 10.3 ),
        Vector( -11.15, -7.18, 9.11 ),
        Vector( -9.51, -7.73, 6.86 ),
        Vector( -7.61, -8.08, 6.43 ),
        Vector( -6.88, -8.77, 5.23 ),
        Vector( -7.48, -10.21, 7.66 ),
    },

--Alien Tunnel View Button ----------------------
    [gCustomizeSceneData.kWorldButtonLabels.Tunnel] = 
    {
        Vector( -2.88, -10.73, 5.13 ),
        Vector( -1.88, -10.69, 5.75 ),
        Vector( -1.49, -10.41, 6.38 ),
        Vector( -2.13, -10.13, 8.4 ),
        Vector( -3.63, -9.75, 7.13 ),
        Vector( -4.63, -10.5, 6.82 ),
        Vector( -4, -10.69, 5.54 ),
    },

--Alien Structures View Buttons -----------------
    [gCustomizeSceneData.kWorldButtonLabels.Drifter] = 
    {
        Vector( 5, -9.85, 8.2 ),
        Vector( 5.63, -9.64, 7.88 ),
        Vector( 6.28, -9, 8.63 ),
        Vector( 5.88, -9.64, 9.92 ),
        Vector( 4.88, -10.38, 8.84 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Cyst] = 
    {
        Vector( -0.25, -10.38, 11.88 ),
        Vector( 0.63, -10.35, 12.85 ),
        Vector( 0.67, -10.36, 14.3 ),
        Vector( -0.1, -10.34, 14.36 ),
        Vector( -0.51, -10.37, 13.46 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Egg] = 
    {
        Vector( -0.49, -10.38, 8.55 ),
        Vector( 0.37, -10.38, 9.12 ),
        Vector( 0.45, -10.38, 10.15 ),
        Vector( -0.38, -10.38, 11 ),
        Vector( -1.14, -10.48, 10.66 ),
        Vector( -1.53, -10.38, 9.62 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Harvester] = 
    {
        Vector( -1.69, -10.24, 11.13 ),
        Vector( -0.99, -10.4, 12.11 ),
        Vector( -1.05, -8.41, 14.32 ),
        Vector( -1.87, -7.81, 14.45 ),
        Vector( -2.64, -7.77, 14.51 ),
        Vector( -3.17, -8.21, 14.36 ),
        Vector( -3.37, -9.04, 14.36 ),
        Vector( -3.31, -10.19, 14.41 ),
        Vector( -2.87, -10.48, 12.89 ),
        Vector( -2.38, -10.27, 11.42 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Hive] = 
    {
        Vector( 1.66, -10.32, 9.1 ),
        Vector( 3.99, -10.32, 10.68 ),
        Vector( 5.92, -10.24, 10.77 ),
        Vector( 6.63, -9.28, 10.48 ),
        Vector( 6.77, -6.93, 9.96 ),
        Vector( 4.34, -6.01, 10.2 ),
        Vector( 5.87, -4.96, 13.63 ),
        Vector( 4.29, -5.03, 14.75 ),
        Vector( 3.05, -6.76, 14.78 ),
        Vector( 2.9, -8.27, 14.67 ),
        Vector( 3.44, -9.85, 14.42 ),
        Vector( 2.71, -10.02, 11.48 ),
    },

--Alien Lifeforms View Buttons -----------------
    [gCustomizeSceneData.kWorldButtonLabels.Skulk] = 
    {
        Vector( -6.82, -9.4, 6.61 ),
        Vector( -7.13, -9.25, 7.38 ),
        Vector( -7.13, -9.13, 7.88 ),
        Vector( -7.13, -8.63, 7.88 ),
        Vector( -7.25, -8.25, 7.63 ),
        Vector( -7.25, -8.38, 7.13 ),
        Vector( -7.25, -8.5, 6.63 ),
        Vector( -7.25, -8.5, 6.25 ),
        Vector( -7.25, -8.88, 5.88 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Gorge] = 
    {
        Vector( -5.72, -10.38, 8.33 ),
        Vector( -5.76, -10.38, 8.87 ),
        Vector( -7.5, -10.5, 10.25 ),
        Vector( -6.13, -9.26, 8.88 ),
        Vector( -6.44, -9.13, 8.5 ),
        Vector( -9.13, -10.25, 9 ),
        Vector( -8.25, -10.5, 8.63 ),
        Vector( -6.71, -10.28, 8.13 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Lerk] = 
    {
        Vector( -7.25, -8, 7.63 ),
        Vector( -7.13, -7.88, 8 ),
        Vector( -7.25, -7.25, 7.75 ),
        Vector( -7.13, -7.05, 7.38 ),
        Vector( -7.5, -7.25, 7 ),
        Vector( -7.25, -7.63, 6.88 ),
        Vector( -7.25, -7.88, 6.88 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Fade] = 
    {
        Vector( -3.97, -10.38, 11.58 ),
        Vector( -3.57, -10.38, 12.04 ),
        Vector( -4.04, -10.38, 14.08 ),
        Vector( -3.63, -9, 11.38 ),
        Vector( -4.25, -8.78, 11.73 ),
        Vector( -4.5, -8.88, 11 ),
        Vector( -4.97, -9.51, 11.5 ),
        Vector( -5.14, -10.38, 12.03 ),
        Vector( -4.59, -10.38, 11.64 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Onos] = 
    {
        Vector( -6, -10.38, 12.25 ),
        Vector( -4.88, -9.13, 10.88 ),
        Vector( -4.88, -8.5, 11 ),
        Vector( -5.13, -7.75, 11 ),
        Vector( -5.5, -7.63, 10.5 ),
        Vector( -6.13, -7.5, 9.88 ),
        Vector( -6.25, -7.88, 9.63 ),
        Vector( -6.38, -8.38, 9.63 ),
        Vector( -6.38, -9, 9.63 ),
        Vector( -7.38, -10.5, 10.75 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Clog] = 
    {
        Vector( -6.38, -9, 9 ),
        Vector( -6.38, -8.63, 9.25 ),
        Vector( -6.5, -8.13, 9.13 ),
        Vector( -8.27, -8.05, 9.59 ),
        Vector( -8.48, -8.34, 9.05 ),
        Vector( -8.35, -8.79, 8.84 ),
        Vector( -8.07, -9.25, 9.05 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Hydra] = 
    {
        Vector( -8.5, -8, 9.88 ),
        Vector( -8.6, -7.5, 10.07 ),
        Vector( -9.13, -6.75, 9.38 ),
        Vector( -9.38, -7.2, 9 ),
        Vector( -9.13, -7.75, 9.13 ),
        Vector( -9, -8.04, 9.38 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.Babblers] = 
    {
        Vector( -4.16, -10.38, 10.44 ),
        Vector( -5.07, -10.38, 11.5 ),
        Vector( -6.13, -10.38, 10.88 ),
        Vector( -6.88, -10.5, 10 ),
        Vector( -5.65, -10.38, 9.13 ),
        Vector( -5, -10.38, 9.75 ),
    },

    [gCustomizeSceneData.kWorldButtonLabels.BileMine] = 
    {
        Vector( -6.25, -10.7, 7.38 ),
        Vector( -6.38, -10.63, 7.75 ),
        Vector( -6.75, -10, 7.63 ),
        Vector( -6.88, -9.75, 7.38 ),
        Vector( -6.75, -10, 7 ),
        Vector( -6.63, -10.5, 6.88 ),
        Vector( -6.25, -10.7, 7 ),
    },

}


-------------------------------------------------------------------------------
---Helper Functions

function GetCustomizeWorldButtonPoints( buttonSetLabel )
    assert(buttonSetLabel, "Invalid type for Button Set label")
    assert(gCustomizeSceneData.WorldButtonPositionSets[buttonSetLabel], "Button Label set is not defined")
    return gCustomizeSceneData.WorldButtonPositionSets[buttonSetLabel]
end

function GetCustomizeScenePosition( posLabel )
    assert(posLabel)  --isenum?
    return gCustomizeSceneData.kCameraViewPositions[posLabel]
end

function GetIsViewForTeam( viewLabel, teamIndex )
    assert(viewLabel and teamIndex)
    if gCustomizeSceneData.kTeamViews[teamIndex] then
        return table.icontains( gCustomizeSceneData.kTeamViews[teamIndex], viewLabel )
    end
    Log("Error: Invalid team index[%s] in view list data", teamIndex)
    return false
end

function GetViewTeamIndex( viewLabel )
    return ( table.icontains( gCustomizeSceneData.kTeamViews[kTeam1Index], viewLabel ) and kTeam1Index or kTeam2Index )
end

function GetIsDefaultView( viewLabel )
    return table.icontains( gCustomizeSceneData.kDefaultviews, viewLabel )
end

function GetObjectSelectableMaterial( teamIndex )
    return (teamIndex == kTeam1Index and gCustomizeSceneData.kMarineTeamSelectableMaterial
    or gCustomizeSceneData.kAlienTeamSelectableMaterial)
end

function GetObjectHighlightMaterial( teamIndex )
    return (teamIndex == kTeam1Index and gCustomizeSceneData.kMarineTeamHighlightMaterial
    or gCustomizeSceneData.kAlienTeamHighlightMaterial)
end

function GetSceneObjectInitData( objectName )
    assert(objectName)
    for i = 1, #gCustomizeSceneData.kSceneObjects do
        if gCustomizeSceneData.kSceneObjects[i].name == objectName then
            return gCustomizeSceneData.kSceneObjects[i]
        end
    end
    return nil
end

--Build list of all items client currently owns
function FetchAllAvailableItems()
    
    local availableItems = {}

    GetAllBundleItems() --init the bundle data

    availableItems[gCustomizeSceneData.kMarineVariantsOption] = {}
    for i = 1, #kMarineVariants do
        local key = kMarineVariants[i]
        local itemId = kMarineVariantsData[kMarineVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kMarineVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kMarineVariantsOption], key)
        end
    end
    
    availableItems[gCustomizeSceneData.kExoVariantsOption] = {}
    for i = 1, #kExoVariants do
        local key = kExoVariants[i]
        local itemId = kExoVariantsData[kExoVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kExoVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kExoVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kMarineStructuresVariantOption] = {}
    for i = 1, #kMarineStructureVariants do
        local key = kMarineStructureVariants[i]
        local itemId = kMarineStructureVariantsData[kMarineStructureVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kMarineStructureVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kMarineStructuresVariantOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kExtractorVariantOption] = {}
    for i = 1, #kExtractorVariants do
        local key = kExtractorVariants[i]
        local itemId = kExtractorVariantsData[kExtractorVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kExtractorVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kExtractorVariantOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kRifleVariantsOption] = {}
    for i = 1, #kRifleVariants do
        local key = kRifleVariants[i]
        local itemId = kRifleVariantsData[kRifleVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kRifleVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kRifleVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kPistolVariantOption] = {}
    for i = 1, #kPistolVariants do
        local key = kPistolVariants[i]
        local itemId = kPistolVariantsData[kPistolVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kPistolVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kPistolVariantOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kAxeVariantOption] = {}
    for i = 1, #kAxeVariants do
        local key = kAxeVariants[i]
        local itemId = kAxeVariantsData[kAxeVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kAxeVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kAxeVariantOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kWelderVariantsOption] = {}
    for i = 1, #kWelderVariants do
        local key = kWelderVariants[i]
        local itemId = kWelderVariantsData[kWelderVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kWelderVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kWelderVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kShotgunVariantsOption] = {}
    for i = 1, #kShotgunVariants do
        local key = kShotgunVariants[i]
        local itemId = kShotgunVariantsData[kShotgunVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kShotgunVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kShotgunVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kGrenadeLauncherVariantsOption] = {}
    for i = 1, #kGrenadeLauncherVariants do
        local key = kGrenadeLauncherVariants[i]
        local itemId = kGrenadeLauncherVariantsData[kGrenadeLauncherVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kGrenadeLauncherVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kGrenadeLauncherVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kFlamethrowerVariantsOption] = {}
    for i = 1, #kFlamethrowerVariants do
        local key = kFlamethrowerVariants[i]
        local itemId = kFlamethrowerVariantsData[kFlamethrowerVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kFlamethrowerVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kFlamethrowerVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kHmgVariantOption] = {}
    for i = 1, #kHMGVariants do
        local key = kHMGVariants[i]
        local itemId = kHMGVariantsData[kHMGVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kHMGVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kHmgVariantOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kMacVariantsOption] = {}
    for i = 1, #kMarineMacVariants do
        local key = kMarineMacVariants[i]
        local itemId = kMarineMacVariantsData[kMarineMacVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kMarineMacVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kMacVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kArcVariantsOption] = {}
    for i = 1, #kMarineArcVariants do
        local key = kMarineArcVariants[i]
        local itemId = kMarineArcVariantsData[kMarineArcVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kMarineArcVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kArcVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kSkulkVariantsOption] = {}
    for i = 1, #kSkulkVariants do
        local key = kSkulkVariants[i]
        local itemId = kSkulkVariantsData[kSkulkVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kSkulkVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kSkulkVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kGorgeVariantsOption] = {}
    for i = 1, #kGorgeVariants do
        local key = kGorgeVariants[i]
        local itemId = kGorgeVariantsData[kGorgeVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kGorgeVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kGorgeVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kLerkVariantsOption] = {}
    for i = 1, #kLerkVariants do
        local key = kLerkVariants[i]
        local itemId = kLerkVariantsData[kLerkVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kLerkVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kLerkVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kFadeVariantsOption] = {}
    for i = 1, #kFadeVariants do
        local key = kFadeVariants[i]
        local itemId = kFadeVariantsData[kFadeVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kFadeVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kFadeVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kOnosVariantsOption] = {}
    for i = 1, #kOnosVariants do
        local key = kOnosVariants[i]
        local itemId = nil
        --hack, always force Bundle item. Note, ofc this will break if item def format changes (for Shadow)
        if kOnosVariantsData[kOnosVariants[key]].itemIds then
            if not GetHasVariant( kOnosVariantsData, kOnosVariantsData[kOnosVariants[key]].itemIds[1], nil ) then
                itemId = kOnosVariantsData[kOnosVariants[key]].itemIds[2]
            end    
        else
            itemId = kOnosVariantsData[kOnosVariants[key]].itemId
        end

        local ownsItem = itemId == nil or GetHasVariant( kOnosVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable( itemId ) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kOnosVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kAlienStructuresVariantOption] = {}
    for i = 1, #kAlienStructureVariants do
        local key = kAlienStructureVariants[i]
        local itemId = kAlienStructureVariantsData[kAlienStructureVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kAlienStructureVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kAlienStructuresVariantOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kHarvesterVariantOption] = {}
    for i = 1, #kHarvesterVariants do
        local key = kHarvesterVariants[i]
        local itemId = kHarvesterVariantsData[kHarvesterVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kHarvesterVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kHarvesterVariantOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kEggVariantOption] = {}
    for i = 1, #kEggVariants do
        local key = kEggVariants[i]
        local itemId = kEggVariantsData[kEggVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kEggVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kEggVariantOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kAlienCystVariantOption] = {}
    for i = 1, #kAlienCystVariants do
        local key = kAlienCystVariants[i]
        local itemId = kAlienCystVariantsData[kAlienCystVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kAlienCystVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kAlienCystVariantOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kAlienDrifterVariantOption] = {}
    for i = 1, #kAlienDrifterVariants do
        local key = kAlienDrifterVariants[i]
        local itemId = kAlienDrifterVariantsData[kAlienDrifterVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kAlienDrifterVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kAlienDrifterVariantOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kTunnelsVariantOption] = {}
    for i = 1, #kAlienTunnelVariants do
        local key = kAlienTunnelVariants[i]
        local itemId = kAlienTunnelVariantsData[kAlienTunnelVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kAlienTunnelVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kTunnelsVariantOption], key)
        end
    end
    
    availableItems[gCustomizeSceneData.kGorgeClogVariantsOption] = {}
    for i = 1, #kClogVariants do
        local key = kClogVariants[i]
        local itemId = kClogVariantsData[kClogVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kClogVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kGorgeClogVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kGorgeHydraVariantsOption] = {}
    for i = 1, #kHydraVariants do
        local key = kHydraVariants[i]
        local itemId = kHydraVariantsData[kHydraVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kHydraVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kGorgeHydraVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kGorgeBabblerVariantsOption] = {}
    for i = 1, #kBabblerVariants do
        local key = kBabblerVariants[i]
        local itemId = kBabblerVariantsData[kBabblerVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kBabblerVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kGorgeBabblerVariantsOption], key)
        end
    end

    availableItems[gCustomizeSceneData.kGorgeBabblerEggVariantsOption] = {}
    for i = 1, #kBabblerEggVariants do
        local key = kBabblerEggVariants[i]
        local itemId = kBabblerEggVariantsData[kBabblerEggVariants[key]].itemId
        local ownsItem = itemId == nil or GetHasVariant( kBabblerEggVariantsData, i, nil )
        if ownsItem or GetIsItemPurchasable(itemId) or GetIsItemThunderdomeUnlock(itemId) then
            table.insert(availableItems[gCustomizeSceneData.kGorgeBabblerEggVariantsOption], key)
        end
    end

    availableItems["shoulderPatches"] = {}
    for i = 1, #kShoulderPadNames do
        local padItemId = kShoulderPad2ItemId[i]
        local ownsItem = padItemId == 0 or GetHasShoulderPad(i)
        if ownsItem or GetIsItemPurchasable(padItemId) or GetIsItemThunderdomeUnlock(padItemId) then
            table.insert(availableItems["shoulderPatches"], i)
        end
    end

    return availableItems
end

--[[
function CompareAvailableItemSets( currentSet, previousSet )
    Log("Checking item purchases...")
    local hasNew = false
    local newItems = {}
    
    for optionName, variants in pairs(currentSet) do
        assert(previousSet[optionName])
        assert(type(previousSet[optionName]) == "table")

        for i = 1, #variants do
            local variantData = gCustomizeSceneData.kOptionsFieldVariantDataMap[optionName]
            if not table.icontains( previousSet[optionName], variants[i] ) and GetHasVariant( variantData, variants[i]) then
                table.insert( newItems, variants[i] )
            end
        end
    end

    Log("\t --------------------\n Found %s new items\n", #newItems)

    return hasNew, newItems
end
--]]

function GetVariantData( costmeticTypeId )
    assert(costmeticTypeId and gCustomizeSceneData.kSceneObjectVariantsDataMap[costmeticTypeId])
    return gCustomizeSceneData.kSceneObjectVariantsDataMap[costmeticTypeId]
end

function GetPrevAvailableVariant( variants, availableVariants, curIdx )
    assert(variants and type(variants) == "table")
    assert(availableVariants and type(availableVariants) == "table")
    assert(curIdx and type(curIdx) == "number" and curIdx > 0)

    local prevIdx = curIdx - 1
    if prevIdx < 1 then
        prevIdx = #availableVariants
    end

    assert(variants[availableVariants[prevIdx]])
    return variants[availableVariants[prevIdx]], prevIdx
end

function GetNextAvailableVariant( variants, availableVariants, curIdx )
    assert(variants and type(variants) == "table")
    assert(availableVariants and type(availableVariants) == "table")
    assert(curIdx and type(curIdx) == "number" and curIdx > 0)
    
    local nextIdx = curIdx + 1
    if nextIdx > #availableVariants then
        nextIdx = 1
    end

    assert(variants[availableVariants[nextIdx]])
    return variants[availableVariants[nextIdx]], nextIdx
end

--Return index of availableVariants from key of passed full-variants-list 
function GetAvailableVariantWithFullVariantList( variants, availableVariants, variantIndex )
    assert(variants)            --full variants list for a given cosmetic item
    assert(availableVariants)   --list of all available variants to client
    assert(variantIndex)        --full-list index

    local availableIndex
    for i, v in ipairs(variants) do
        for x = 1, #availableVariants do
            if availableVariants[x] == v and variantIndex == i then
                availableIndex = x
            end
        end
    end

    return availableIndex
end

function GetFullVariantWithAvailableVariantIndex( availableVariantIndexLbl, variants )
    assert(variants)
    assert(availableVariantIndexLbl) --enum 'key'   --FIXME This is asserting in many cases where new TD rewards skins selected, or similar ...likely due to skin-order changes, or avail-list not including TD-reward items...

    for variantIdx, variantKey in ipairs(variants) do
        if variantKey == availableVariantIndexLbl then
            return variantIdx
        end
    end

    return -1
end

function GetOwnedVariantIndexByVariantId( availableVariants, variantId, variants )
    --Log("GetOwnedVariantIndexByVariantId( -- )")
    --Log("\t availableVariants: %s", availableVariants)
    --Log("\t         variantId: %s", variantId)
    --Log("\t          variants: %s", EnumAsTable(variants))

    assert(availableVariants and type(availableVariants) == "table")
    assert(variants and type(variants) == "table")
    assert(variantId and type(variantId) == "number" and variantId > 0)

    local availableIndex

    for i = 1, #availableVariants do
        local tVarId = variants[availableVariants[i]]
        if type(tVarId) == "table" then
            for i = 1, #tVarId do
                if tVarId[i] == variantId then
                    availableIndex = i
                end
            end
        elseif tVarId == variantId then
            availableIndex = i
        end
    end

    if not availableIndex then
        return false
    else
        return availableIndex
    end
end

function GetBabblerVariantModel( variant )
    assert(variant)
    if variant == kBabblerVariants.Shadow or variant == kBabblerEggVariants.Auric then
        return "models/alien/babbler/babbler_shadow.model"
    end
    return "models/alien/babbler/babbler.model"
end

function GetBabblerEggVariantModel(variant)
    assert(variant)
    if variant == kBabblerEggVariants.Shadow or variant == kBabblerEggVariants.Auric then
        return "models/alien/babbler/babbler_egg_shadow.model"
    end
    return "models/alien/babbler/babbler_egg.model"
end

local kClogVariantModels = 
{
    [kClogVariants.normal] = "models/alien/gorge/clog.model",
    [kClogVariants.Shadow] = "models/alien/gorge/clog_shadow.model",
    [kClogVariants.Reaper] = "models/alien/gorge/clog_reaper.model",
    [kClogVariants.Nocturne] = "models/alien/gorge/clog_nocturne.model",
    [kClogVariants.Kodiak] = "models/alien/gorge/clog_kodiak.model",
    [kClogVariants.Toxin] = "models/alien/gorge/clog_toxin.model",
    [kClogVariants.Abyss] = "models/alien/gorge/clog_abyss.model",
    [kClogVariants.Auric] = "models/alien/gorge/clog_auric.model",
}
function GetClogVariantModel( variant )
    assert(variant)
    return kClogVariantModels[variant]
end

function GetHydraVariantModel( variant )
    assert(variant)
    if variant == kHydraVariants.Shadow or variant == kBabblerEggVariants.Auric then
        return "models/alien/hydra/hydra_shadow.model"
    end
    return "models/alien/hydra/hydra.model"
end

function GetCustomizableModelPath( label, marineType, options )
    assert(label and type(label) == "string" and label ~= "")
    assert(options)

    local modelType = string.lower(label)
    local modelPath = nil

    if modelType == "skulk" then
        modelPath =  "models/alien/skulk/skulk" .. GetVariantModel(kSkulkVariantsData, options.skulkVariant)

    elseif modelType == "gorge" then
        modelPath =  "models/alien/gorge/gorge" .. GetVariantModel(kGorgeVariantsData, options.gorgeVariant)

    elseif modelType == "lerk" then
        modelPath =  "models/alien/lerk/lerk" .. GetVariantModel(kLerkVariantsData, options.lerkVariant)

    elseif modelType == "fade" then
        modelPath =  "models/alien/fade/fade" .. GetVariantModel(kFadeVariantsData, options.fadeVariant)

    elseif modelType == "onos" then
        modelPath =  "models/alien/onos/onos" .. GetVariantModel(kOnosVariantsData, options.onosVariant)

    elseif modelType == "marine" then
        modelPath = "models/marine/" .. marineType .. "/" .. marineType .. GetVariantModel(kMarineVariantsData, options.marineVariant)

    elseif modelType == "exo_mm" then
        modelPath =  "models/marine/exosuit/exosuit_mm.model"

    elseif modelType == "exo_rr" then
        modelPath =  "models/marine/exosuit/exosuit_rr.model"

    elseif modelType == "rifle" then
        modelPath = "models/marine/rifle/rifle.model"

    elseif modelType == "pistol" then
        modelPath = "models/marine/pistol/pistol.model"

    elseif modelType == "axe" then
        modelPath = "models/marine/axe/axe.model"

    elseif modelType == "shotgun" then
        modelPath = "models/marine/shotgun/shotgun.model"

    elseif modelType == "flamethrower" then
        modelPath = "models/marine/flamethrower/flamethrower.model"

    elseif modelType == "grenadelauncher" then
        modelPath = "models/marine/grenadelauncher/grenadelauncher.model"

    elseif modelType == "welder" then
        modelPath = "models/marine/welder/welder.model"

    elseif modelType == "hmg" then
        modelPath = "models/marine/hmg/hmg.model"

    elseif modelType == "command_station" then
        modelPath = "models/marine/command_station/command_station.model"

    elseif modelType == "mac" then
        modelPath = "models/marine/mac/mac.model"

    elseif modelType == "arc" then
        modelPath = "models/marine/arc/arc.model"

    elseif modelType == "extractor" then
        modelPath = "models/marine/extractor/extractor.model"

    elseif modelType == "hive" then
        modelPath = "models/alien/hive/hive.model"

    elseif modelType == "egg" then
        modelPath = "models/alien/egg/egg.model"
    
    elseif modelType == "cyst" then
        modelPath = "models/alien/cyst/cyst.model"

    elseif modelType == "drifter" then
        modelPath = "models/alien/drifter/drifter.model"

    elseif modelType == "drifter_egg" then
        modelPath = "models/alien/cocoon/cocoon.model"

    elseif modelType == "harvester" then
        modelPath = "models/alien/harvester/harvester.model"

    elseif modelType == "hydra" then
        modelPath = GetHydraVariantModel(options.hydraVariant)

    elseif modelType == "babbler" then
        modelPath = GetBabblerVariantModel(options.babblerVariant)

    elseif modelType == "babbler_egg" then
        modelPath = GetBabblerEggVariantModel(options.babblerEggVariant)

    elseif modelType == "clog" then
        modelPath = GetClogVariantModel(options.clogVariant)

    elseif modelType == "tunnel" then
        modelPath = "models/alien/tunnel/mouth" .. GetVariantModel(kAlienTunnelVariantsData, options.alienTunnelsVariant)
    end

    return modelPath
end

--dumb util for logging enums
function EnumAsTable( enum )
    assert(enum)

    local t = {}

    for i = 1, #enum do
        local kv = enum[i]
        local key = enum[enum[i]]
        t.key = i
        table.insert(t, kv)
    end

    return t
end

local function PrecacheCustomizeMaterials()

    PrecacheCosmeticMaterials( "Axe", kAxeVariantsData )
    PrecacheCosmeticMaterials( "Pistol", kPistolVariantsData )
    PrecacheCosmeticMaterials( "Rifle", kRifleVariantsData )
    PrecacheCosmeticMaterials( "Welder", kWelderVariantsData )
    PrecacheCosmeticMaterials( "Shotgun", kShotgunVariantsData )
    PrecacheCosmeticMaterials( "Flamethrower", kFlamethrowerVariantsData )
    PrecacheCosmeticMaterials( "GrenadeLauncher", kGrenadeLauncherVariantsData )
    PrecacheCosmeticMaterials( "HeavyMachineGun", kHMGVariantsData )
    PrecacheCosmeticMaterials( "Minigun", kExoVariantsData )
    PrecacheCosmeticMaterials( "Railgun", kExoVariantsData )
    PrecacheCosmeticMaterials( "CommandStation", kMarineStructureVariantsData )
    PrecacheCosmeticMaterials( "Extractor", kExtractorVariantsData )
    PrecacheCosmeticMaterials( "MAC", kMarineMacVariantsData )
    PrecacheCosmeticMaterials( "ARC", kMarineArcVariantsData )

    PrecacheCosmeticMaterials( "Skulk", kSkulkVariantsData )
    PrecacheCosmeticMaterials( "Gorge", kGorgeVariantsData )
    PrecacheCosmeticMaterials( "Lerk", kLerkVariantsData )
    PrecacheCosmeticMaterials( "Fade", kFadeVariantsData )
    PrecacheCosmeticMaterials( "Onos", kOnosVariantsData )
    PrecacheCosmeticMaterials( "Hive", kAlienStructureVariantsData )
    PrecacheCosmeticMaterials( "Egg", kEggVariantsData )
    PrecacheCosmeticMaterials( "Embryo", kEggVariantsData )
    PrecacheCosmeticMaterials( "Harvester", kHarvesterVariantsData )
    PrecacheCosmeticMaterials( "Cyst", kAlienCystVariantsData )

    PrecacheCosmeticMaterials( "Drifter", kAlienDrifterVariantsData )
    PrecacheCosmeticMaterials( "DrifterEgg", kAlienDrifterVariantsData )

    PrecacheCosmeticMaterials( "Tunnel", kAlienTunnelVariantsData )

    PrecacheCosmeticMaterials( "Babbler", kBabblerVariantsData )
    PrecacheCosmeticMaterials( "BabblerEgg", kBabblerEggVariantsData )
    PrecacheCosmeticMaterials( "Hydra", kHydraVariantsData )
    --Clogs are only models, no extra materials

end

local function PrecacheCustomizeAssets()

    local cachedList = {} --simple dumb list to ensure only call precache once per model

    for i = 1, #kMarineVariants do
        if not table.icontains(kRoboticMarineVariantIds, i) then
            local model = GetCustomizableModelPath( "marine", "male", { marineVariant = i } )
            if model and not table.icontains(cachedList, model) then
                PrecacheAsset( model )
                table.insert(cachedList, model)
            end
        end
    end

    for i = 1, #kMarineVariants do
        if not table.icontains(kRoboticMarineVariantIds, i) then
            local model = GetCustomizableModelPath( "marine", "female", { marineVariant = i } )
            if model and not table.icontains(cachedList, model) then
                PrecacheAsset( model )
                table.insert(cachedList, model)
            end
        end
    end

    for i = 1, #kMarineVariants do
        if table.icontains(kRoboticMarineVariantIds, i) then
            local model = GetCustomizableModelPath( "marine", "bigmac", { marineVariant = i } )
            if model and not table.icontains(cachedList, model) then
                PrecacheAsset( model )
                table.insert(cachedList, model)
            end
        end
    end

    for i = 1, #kOnosVariants do
        local model = GetCustomizableModelPath( "onos", "male", { onosVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kFadeVariants do
        local model = GetCustomizableModelPath( "fade", "male", { fadeVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kLerkVariants do
        local model = GetCustomizableModelPath( "lerk", "male", { lerkVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kSkulkVariants do
        local model = GetCustomizableModelPath( "skulk", "male", { skulkVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kRifleVariants do
        local model = GetCustomizableModelPath( "rifle", "male", { rifleVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kShotgunVariants do
        local model = GetCustomizableModelPath( "shotgun", "male", { shotgunVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kPistolVariants do
        local model = GetCustomizableModelPath( "pistol", "male", { pistolVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    --This is left to ensure the base model is cached, even though material-swapping is used (only cached 1 model)
    for i = 1, #kAxeVariants do
        local model = GetCustomizableModelPath( "axe", "male", { axeVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kFlamethrowerVariants do
        local model = GetCustomizableModelPath( "flamethrower", "male", { flamethrowerVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kGrenadeLauncherVariants do
        local model = GetCustomizableModelPath( "grenadelauncher", "male", { grenadeLauncherVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kHMGVariants do
        local model = GetCustomizableModelPath( "hmg", "male", { hmgVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kWelderVariants do
        local model = GetCustomizableModelPath( "welder", "male", { welderVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kExoVariants do
        local model = GetCustomizableModelPath( "exo", "male", { exoVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kMarineMacVariants do
        local model = GetCustomizableModelPath( "mac", "male", { macVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kMarineArcVariants do
        local model = GetCustomizableModelPath( "arc", "male", { arcVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kMarineStructureVariants do
        local model = GetCustomizableModelPath( "command_station", "male", { } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kExtractorVariants do
        local model = GetCustomizableModelPath( "extractor", "male", { } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kAlienStructureVariants do
        local model = GetCustomizableModelPath( "hive", "male", { } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kHarvesterVariants do
        local model = GetCustomizableModelPath( "harvester", "male", { } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kEggVariants do
        local model = GetCustomizableModelPath( "egg", "male", { } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kAlienCystVariants do
        local cystModel = GetCustomizableModelPath( "cyst", "male", { } )
        if cystModel and not table.icontains(cachedList, cystModel) then
            PrecacheAsset( cystModel )
            table.insert(cachedList, cystModel)
        end
    end

    for i = 1, #kAlienDrifterVariants do
        local drifterModel = GetCustomizableModelPath( "drifter", "male", { } )
        if drifterModel and not table.icontains(cachedList, drifterModel) then
            PrecacheAsset( drifterModel )
            table.insert(cachedList, drifterModel)
        end
    end

    for i = 1, #kAlienDrifterVariants do
        local drifterEggModel = GetCustomizableModelPath( "drifter_egg", "male", { } )
        if drifterEggModel and not table.icontains(cachedList, drifterEggModel) then
            PrecacheAsset( drifterEggModel )
            table.insert(cachedList, drifterEggModel)
        end
    end

    for i = 1, #kAlienTunnelVariants do
        local model = GetCustomizableModelPath( "tunnel", "male", { alienTunnelsVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kGorgeVariants do
        local model = GetCustomizableModelPath( "gorge", "male", { gorgeVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kClogVariants do
        local model = GetCustomizableModelPath( "clog", "male", { clogVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kHydraVariants do
        local model = GetCustomizableModelPath( "hydra", "male", { hydraVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kBabblerVariants do
        local model = GetCustomizableModelPath( "babbler", "male", { babblerVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end

    for i = 1, #kBabblerEggVariants do
        local model = GetCustomizableModelPath( "babbler_egg", "male", { babblerEggVariant = i } )
        if model and not table.icontains(cachedList, model) then
            PrecacheAsset( model )
            table.insert(cachedList, model)
        end
    end


    PrecacheCustomizeMaterials()

end
PrecacheCustomizeAssets()