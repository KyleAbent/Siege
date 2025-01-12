-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/items/itemDefs.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Definitions of all items available to be awarded to the player.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

kItemDefs = --Unlockables
{
    --[[
        McG: removed below, as we don't grant these items anymore

    [907] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_PUMPKIN_PATCH_TITLE")),
        message = Locale.ResolveString("ITEM_PUMPKIN_PATCH_DESC"),
        icon = PrecacheAsset("ui/items/achievements/item_pumpkin_patch.dds"),
    },
    
    [910] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_SUMMER_GORGE_TITLE")),
        message = Locale.ResolveString("ITEM_SUMMER_GORGE_DESC"),
        icon = PrecacheAsset("ui/items/achievements/item_summergorge_patch.dds"),
    },
    
    [911] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_HAUNTED_BABBLER_TITLE")),
        message = Locale.ResolveString("ITEM_HAUNTED_BABBLER_DESC"),
        icon = PrecacheAsset("ui/items/achievements/item_hauntedbabbler_patch.dds"),
    },
    --]]

    [kTanithSkulkItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_TANITH_SKULK")),
        message = Locale.ResolveString("ITEM_TANITH_SKULK"),
        icon = PrecacheAsset("ui/items/specials/item_tanith_skulk.dds"),
    },

    [kSleuthSkulkItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_SLEUTH_SKULK")),
        message = Locale.ResolveString("ITEM_SLEUTH_SKULK"),
        icon = PrecacheAsset("ui/items/specials/item_sleuth_skulk.dds"),
    },

    -------------------------------------------------------
    --TD Tier Badges --------------------------------------

    [kTDTier1BadgeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_TIER1_BADGE")),
        message = Locale.ResolveString("ITEM_BADGE_TDTIER1"),
        icon = PrecacheAsset("ui/items/thunderdome/item_badge_tier1.dds"),
    },

    [kTDTier2BadgeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_TIER2_BADGE")),
        message = Locale.ResolveString("ITEM_BADGE_TDTIER2"),
        icon = PrecacheAsset("ui/items/thunderdome/item_badge_tier2.dds"),
    },

    [kTDTier3BadgeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_TIER3_BADGE")),
        message = Locale.ResolveString("ITEM_BADGE_TDTIER3"),
        icon = PrecacheAsset("ui/items/thunderdome/item_badge_tier3.dds"),
    },

    [kTDTier4BadgeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_TIER4_BADGE")),
        message = Locale.ResolveString("ITEM_BADGE_TDTIER4"),
        icon = PrecacheAsset("ui/items/thunderdome/item_badge_tier4.dds"),
    },

    [kTDTier5BadgeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_TIER5_BADGE")),
        message = Locale.ResolveString("ITEM_BADGE_TDTIER5"),
        icon = PrecacheAsset("ui/items/thunderdome/item_badge_tier5.dds"),
    },

    [kTDTier6BadgeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_TIER6_BADGE")),
        message = Locale.ResolveString("ITEM_BADGE_TDTIER6"),
        icon = PrecacheAsset("ui/items/thunderdome/item_badge_tier6.dds"),
    },

    [kTDTier7BadgeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_TIER7_BADGE")),
        message = Locale.ResolveString("ITEM_BADGE_TDTIER7"),
        icon = PrecacheAsset("ui/items/thunderdome/item_badge_tier7.dds"),
    },

    [kTDTier8BadgeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_TIER8_BADGE")),
        message = Locale.ResolveString("ITEM_BADGE_TDTIER8"),
        icon = PrecacheAsset("ui/items/thunderdome/item_badge_tier8.dds"),
    },

    -------------------------------------------------------
    --TD Chroma Items -------------------------------------

    [kChromaArmorItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_ARMOR")),
        message = Locale.ResolveString("ITEM_CHROMA_ARMOR"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_armor.dds"),
    },

    [kChromaBigmacItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_BMAC")),
        message = Locale.ResolveString("ITEM_CHROMA_BMAC"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_bmac.dds"),
    },

    [kChromaMilitaryBmacItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_MILBMAC")),
        message = Locale.ResolveString("ITEM_CHROMA_MILBMAC"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_milbmac.dds"),
    },

    [kChromaExoItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_EXO")),
        message = Locale.ResolveString("ITEM_CHROMA_EXO"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_exo.dds"),
    },

    [kChromaAxeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_AXE")),
        message = Locale.ResolveString("ITEM_CHROMA_AXE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_axe_chroma.dds"),
    },

    [kChromaWelderItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_WELDER")),
        message = Locale.ResolveString("ITEM_CHROMA_WELDER"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_welder.dds"),
    },

    [kChromaShotgunItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_SHOTGUN")),
        message = Locale.ResolveString("ITEM_CHROMA_SHOTGUN"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_shotgun.dds"),
    },

    [kChromaFlamethrowerItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_FLAMETHROWER")),
        message = Locale.ResolveString("ITEM_CHROMA_FLAMETHROWER"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_flamethrower.dds"),
    },

    [kChromaGrenadeLauncherItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_GL")),
        message = Locale.ResolveString("ITEM_CHROMA_GL"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_grenadelauncher.dds"),
    },

    [kChromaHMGItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_HMG")),
        message = Locale.ResolveString("ITEM_CHROMA_HMG"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_hmg.dds"),
    },

    [kChromaMacItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_MAC")),
        message = Locale.ResolveString("ITEM_CHROMA_MAC"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_mac.dds"),
    },

    [kChromaArcItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_ARC")),
        message = Locale.ResolveString("ITEM_CHROMA_ARC"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_arc.dds"),
    },

    [kChromaExtractorItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_EXTRACTOR")),
        message = Locale.ResolveString("ITEM_CHROMA_EXTRACTOR"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_extractor.dds"),
    },

    [kChromaCommandStationItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CHROMA_CS")),
        message = Locale.ResolveString("ITEM_CHROMA_CS"),
        icon = PrecacheAsset("ui/items/thunderdome/item_chroma_commandstation.dds"),
    },

    -------------------------------------------------------
    --TD Auric Items --------------------------------------

    [kAuricSkulkItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_SKULK")),
        message = Locale.ResolveString("ITEM_AURIC_SKULK"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_skulk.dds"),
    },

    [kAuricGorgeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_GORGE")),
        message = Locale.ResolveString("ITEM_AURIC_GORGE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_gorge.dds"),
    },

    [kAuricLerkItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_LERK")),
        message = Locale.ResolveString("ITEM_AURIC_LERK"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_lerk.dds"),
    },

    [kAuricFadeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_FADE")),
        message = Locale.ResolveString("ITEM_AURIC_FADE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_fade.dds"),
    },

    [kAuricOnosItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_ONOS")),
        message = Locale.ResolveString("ITEM_AURIC_ONOS"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_onos.dds"),
    },

    [kAuricGorgeClogItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_CLOG")),
        message = Locale.ResolveString("ITEM_AURIC_CLOG"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_clog.dds"),
    },

    [kAuricGorgeHydraItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_HYDRA")),
        message = Locale.ResolveString("ITEM_AURIC_HYDRA"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_hydra.dds"),
    },

    [kAuricGorgeBabblerItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_BABBLER")),
        message = Locale.ResolveString("ITEM_AURIC_BABBLER"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_babbler.dds"),
    },

    [kAuricGorgeBabblerEggItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_BABBLEREGG")),
        message = Locale.ResolveString("ITEM_AURIC_BABBLEREGG"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_babbleregg.dds"),
    },

    [kAuricHiveItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_HIVE")),
        message = Locale.ResolveString("ITEM_AURIC_HIVE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_hive.dds"),
    },

    [kAuricHarvesterItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_HARVESTER")),
        message = Locale.ResolveString("ITEM_AURIC_HARVESTER"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_harvester.dds"),
    },

    [kAuricEggItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_EGG")),
        message = Locale.ResolveString("ITEM_AURIC_EGG"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_egg.dds"),
    },

    [kAuricCystItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_CYST")),
        message = Locale.ResolveString("ITEM_AURIC_CYST"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_cyst.dds"),
    },

    [kAuricDrifterItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_DRIFTER")),
        message = Locale.ResolveString("ITEM_AURIC_DRIFTER"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_drifter.dds"),
    },

    [kAuricTunnelItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_AURIC_TUNNEL")),
        message = Locale.ResolveString("ITEM_AURIC_TUNNEL"),
        icon = PrecacheAsset("ui/items/thunderdome/item_auric_tunnel.dds"),
    },

    -------------------------------------------------------
    --TD Unique non-set items -----------------------------

    [kWidowSkulkItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_WIDOW_SKULK")),
        message = Locale.ResolveString("ITEM_WIDOW_SKULK"),
        icon = PrecacheAsset("ui/items/thunderdome/item_widow_skulk.dds"),
    },

    [kWoodAxeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_WOOD_AXE")),
        message = Locale.ResolveString("ITEM_WOOD_AXE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_axe_wood.dds"),
    },

    [kWoodRifleItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_WOOD_RIFLE")),
        message = Locale.ResolveString("ITEM_WOOD_RIFLE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_rifle_wood.dds"),
    },

    [kWoodPistolItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_WOOD_PISTOL")),
        message = Locale.ResolveString("ITEM_WOOD_PISTOL"),
        icon = PrecacheAsset("ui/items/thunderdome/item_pistol_wood.dds"),
    },

    [kDamascusAxeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_DAMAS_AXE")),
        message = Locale.ResolveString("ITEM_DAMAS_AXE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_axe_damascus.dds"),
    },

    [kDamascusRifleItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_DAMAS_RIFLE")),
        message = Locale.ResolveString("ITEM_DAMAS_RIFLE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_rifle_damascus.dds"),
    },

    [kDamascusPistolItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_DAMAS_PISTOL")),
        message = Locale.ResolveString("ITEM_DAMAS_PISTOL"),
        icon = PrecacheAsset("ui/items/thunderdome/item_pistol_damascus.dds"),
    },

    [kDamascusGreenAxeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_DAMAS_GREEN_AXE")),
        message = Locale.ResolveString("ITEM_DAMAS_GREEN_AXE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_axe_damascus.dds"),
    },

    [kDamascusGreenRifleItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_DAMAS_GREEN_RIFLE")),
        message = Locale.ResolveString("ITEM_DAMAS_GREEN_RIFLE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_rifle_damascus_green.dds"),
    },

    [kDamascusGreenPistolItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_DAMAS_GREEN_PISTOL")),
        message = Locale.ResolveString("ITEM_DAMAS_GREEN_PISTOL"),
        icon = PrecacheAsset("ui/items/thunderdome/item_pistol_damascus_green.dds"),
    },

    [kDamascusPurpleAxeItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_DAMAS_PURPLE_AXE")),
        message = Locale.ResolveString("ITEM_DAMAS_PURPLE_AXE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_axe_damascus.dds"),
    },

    [kDamascusPurpleRifleItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_DAMAS_PURPLE_RIFLE")),
        message = Locale.ResolveString("ITEM_DAMAS_PURPLE_RIFLE"),
        icon = PrecacheAsset("ui/items/thunderdome/item_rifle_damascus_purple.dds"),
    },

    [kDamascusPurplePistolItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_DAMAS_PURPLE_PISTOL")),
        message = Locale.ResolveString("ITEM_DAMAS_PURPLE_PISTOL"),
        icon = PrecacheAsset("ui/items/thunderdome/item_pistol_damascus_purple.dds"),
    },

    -------------------------------------------------------
    --TD Calling Card Items -------------------------------

    [kSkulkHugCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_SKULK_HUG")),
        message = Locale.ResolveString("ITEM_CC_SKULK_HUG"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_skulk_hug.dds"),
    },

    [kDoNotBlinkCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_DONTBLINK")),
        message = Locale.ResolveString("ITEM_CC_DONTBLINK"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_dont_blink.dds"),
    },

    [kBabyMarineCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_BABY_MARINE")),
        message = Locale.ResolveString("ITEM_CC_BABY_MARINE"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_baby_marine.dds"),
    },

    [kLockedLoadedCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_LOCKNLOAD")),
        message = Locale.ResolveString("ITEM_CC_LOCKNLOAD"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_locked_loaded.dds"),
    },

    [kNedRageCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_NEDRAGE")),
        message = Locale.ResolveString("ITEM_CC_NEDRAGE"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_nedrage.dds"),
    },

    [kUrpaBootyCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_URPA_BOOTY")),
        message = Locale.ResolveString("ITEM_CC_URPA_BOOTY"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_urpabooty.dds"),
    },

    [kSadbabblerCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_SADBAB")),
        message = Locale.ResolveString("ITEM_CC_SADBAB"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_sad_babbler.dds"),
    },

    [kJobWeldDoneCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_JOBWELD")),
        message = Locale.ResolveString("ITEM_CC_JOBWELD"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_job_weld_done.dds"),
    },

    [kBalanceGorgeCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_BALANCEGORGE")),
        message = Locale.ResolveString("ITEM_CC_BALANCEGORGE"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_balance_gorge.dds"),
    },

    [kLorkCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_LORK")),
        message = Locale.ResolveString("ITEM_CC_LORK"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_l0rk.dds"),
    },

    [kLazyGorgeCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_LAZYGORGE")),
        message = Locale.ResolveString("ITEM_CC_LAZYGORGE"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_lazy_gorge.dds"),
    },

    [kUrpaCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_URPA")),
        message = Locale.ResolveString("ITEM_CC_URPA"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_urpa.dds"),
    },

    [kSlipperSkulkCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_SLIPPERS")),
        message = Locale.ResolveString("ITEM_CC_SLIPPERS"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_slipper_skulk.dds"),
    },

    [kShadowFadeCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_SHADOWFADE")),
        message = Locale.ResolveString("ITEM_CC_SHADOWFADE"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_shadowfade.dds"),
    },

    [kBurnoutFadeCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_BURNTFADE")),
        message = Locale.ResolveString("ITEM_CC_BURNTFADE"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_burnt_fade.dds"),
    },

    [kOverNineCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_OVER9K")),
        message = Locale.ResolveString("ITEM_CC_OVER9K"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_over9k.dds"),
    },

    [kLerkedCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_LERKED")),
        message = Locale.ResolveString("ITEM_CC_LERKED"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_lerked.dds"),
    },

    [kTableFlipGorgeCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_TABLEFLIP")),
        message = Locale.ResolveString("ITEM_CC_TABLEFLIP"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_tableflip.dds"),
    },

    [kAngryOnosCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_ANGRYONOS")),
        message = Locale.ResolveString("ITEM_CC_ANGRYONOS"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_angry_onos.dds"),
    },

    [kOhNoesCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_OHNOES")),
        message = Locale.ResolveString("ITEM_CC_OHNOES"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_ohnoes.dds"),
    },

    [kForScienceCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_FORSCI")),
        message = Locale.ResolveString("ITEM_CC_FORSCI"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_for_science.dds"),
    },

    [kTurboDrifterCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_TURBODRIFT")),
        message = Locale.ResolveString("ITEM_CC_TURBODRIFT"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_turbo_drifter.dds"),
    },

    [kBattleGorgeCardItemId] =
    {
        title = string.format(Locale.ResolveString("NEW_ITEM"), Locale.ResolveString("ITEM_TITLE_CC_BATTLEGORGE")),
        message = Locale.ResolveString("ITEM_CC_BATTLEGORGE"),
        icon = PrecacheAsset("ui/items/callcards/item_cc_battle_gorge.dds"),
    },

}



local kItemIcons = 
{
    [kTundraArmorItemId] = PrecacheAsset("ui/items/tundra/item_tundra_armors.dds"),
    [kTundraExosuitItemId] = PrecacheAsset("ui/items/tundra/item_tundra_exosuit.dds"),
    [kTundraAxeItemId] = PrecacheAsset("ui/items/tundra/item_axe.dds"),
    [kTundraWelderItemId] = PrecacheAsset("ui/items/tundra/item_welder.dds"),
    [kTundraWelderItemId] = PrecacheAsset("ui/items/tundra/item_pistol.dds"),
    [kTundraRifleItemId] = PrecacheAsset("ui/items/tundra/item_tundra_rifle.dds"),
    [kTundraShotgunItemId] = PrecacheAsset("ui/items/tundra/item_tundra_shotgun.dds"),
    [kTundraShoulderPatchItemId] = PrecacheAsset("ui/items/tundra/item_tundra_patch.dds"),
    [kTundraFlamethrowerItemId] = PrecacheAsset("ui/items/tundra/item_flamethrower.dds"),
    [kTundraGrenadeLauncherItemId] = PrecacheAsset("ui/items/tundra/item_grenadlauncher.dds"),
    [kTundraStructuresItemId] = PrecacheAsset("ui/items/tundra/item_structures.dds"),

    [kShadowSkulkItemId] = PrecacheAsset("ui/items/shadow/item_shadow_skulk.dds"),
    [kShadowFadeItemId] = PrecacheAsset("ui/items/shadow/item_shadow_fade.dds"),
    [kShadowLerkItemId] = PrecacheAsset("ui/items/shadow/item_shadow_lerk.dds"),
    [kShadowOnosItemIds[1]] = PrecacheAsset("ui/items/shadow/item_shadow_onos.dds"),
    [kShadowOnosItemIds[2]] = PrecacheAsset("ui/items/shadow/item_shadow_onos.dds"),
    [kShadowStructuresItemId] = PrecacheAsset("ui/items/shadow/item_hive.dds"),

    [kNocturneSkulkItemId] = PrecacheAsset("ui/items/nocturne/item_nocturne_skulk.dds"),
    [kNocturneGorgeItemId] = PrecacheAsset("ui/items/nocturne/item_nocturne_gorge.dds"),
    [kNocturneLerkItemId] = PrecacheAsset("ui/items/nocturne/item_nocturne_lerk.dds"),
    [kNocturneFadeItemId] = PrecacheAsset("ui/items/nocturne/item_nocturne_fade.dds"),
    [kNocturneOnosItemId] = PrecacheAsset("ui/items/nocturne/item_nocturne_onos.dds"),
    [kNocturneStructuresItemId] = PrecacheAsset("ui/items/nocturne/item_hive.dds"),

    [kForgeArmorItemId] = PrecacheAsset("ui/items/forge/item_forge_armors.dds"),
    [kForgeRifleItemId] = PrecacheAsset("ui/items/forge/item_forge_rifle.dds"),
    [kForgePistolItemId] = PrecacheAsset("ui/items/forge/item_forge_pistol.dds"),
    [kForgeShotgunItemId] = PrecacheAsset("ui/items/forge/item_forge_shotgun.dds"),
    [kForgeFlamethrowerItemId] = PrecacheAsset("ui/items/forge/item_forge_flamethrower.dds"),
    [kForgeAxeItemId] = PrecacheAsset("ui/items/forge/item_forge_axe.dds"),
    [kForgeExosuitItemId] = PrecacheAsset("ui/items/forge/item_forge_exosuit.dds"),
    [kForgeGrenadeLauncherItemId] = PrecacheAsset("ui/items/forge/item_grenadelauncher.dds"),
    [kForgeStructuresItemId] = PrecacheAsset("ui/items/forge/item_structures.dds"),
    
    [kKodiakArmorItemId] = PrecacheAsset("ui/items/kodiak/item_kodiak_armor.dds"),
    [kKodiakRifleItemId] = PrecacheAsset("ui/items/kodiak/item_kodiak_rifle.dds"),
    [kKodiakShoulderPatchItemId] = PrecacheAsset("ui/items/kodiak/item_kodiak_patch.dds"),
    [kKodiakExosuitItemId] = PrecacheAsset("ui/items/kodiak/item_kodiak_exosuit.dds"),
    [kKodiakGrenadeLauncherItemId] = PrecacheAsset("ui/items/kodiak/item_grenadlauncher.dds"),
    [kKodiakFlamethrowerItemId] = PrecacheAsset("ui/items/kodiak/item_flamethrower.dds"),
    [kKodiakMarineStructuresItemId] = PrecacheAsset("ui/items/kodiak/item_marine-structures.dds"),

    [kKodiakSkulkItemId] = PrecacheAsset("ui/items/kodiak/item_kodiak_skulk.dds"),
    [kKodiakGorgeItemId] = PrecacheAsset("ui/items/kodiak/item_gorge.dds"),
    [kKodiakLerkItemId] = PrecacheAsset("ui/items/kodiak/item_lerk.dds"),
    [kKodiakFadeItemId] = PrecacheAsset("ui/items/kodiak/item_fade.dds"),
    [kKodiakOnosItemId] = PrecacheAsset("ui/items/kodiak/item_onos.dds"),
    [kKodiakAlienStructuresItemId] = PrecacheAsset("ui/items/kodiak/item_hive.dds"),
    
    [kDeluxeArmorItemId] = PrecacheAsset("ui/items/deluxe/item_deluxe_armor.dds"),

    [kAssaultArmorItemId] = PrecacheAsset("ui/items/reinforced/item_reinforced_armor.dds"),
    [kReinforcedShoulderPatchItemId] = PrecacheAsset("ui/items/reinforced/item_reinforced_patch.dds"),

    --One-offs(Rifle)
    [kRedRifleItemId] = PrecacheAsset("ui/items/item_marine_skullnfire_rifle.dds"),
    [kDragonRifleItemId] = PrecacheAsset("ui/items/specials/item_rifle_dragon.dds"),
    [kGoldRifleItemId] = PrecacheAsset("ui/items/specials/item_rifle_gold.dds"),
    [kChromaRifleItemId] = PrecacheAsset("ui/items/specials/item_rifle_chroma.dds"),

    --One-offs(Pistol)
    [kViperPistolItemId] = PrecacheAsset("ui/items/specials/item_pistol_viper.dds"),
    [kGoldPistolItemId] = PrecacheAsset("ui/items/specials/item_pistol_gold.dds"),
    [kChromaPistolItemId] = PrecacheAsset("ui/items/specials/item_pistol_chroma.dds"),

    [kEliteAssaultArmorItemId] = PrecacheAsset("ui/items/item_marine_eliteassault_armor.dds"),

    [kUnearthedStructuresItemId] = PrecacheAsset("ui/items/unearthed/item_unearthedskin.dds"),

    [kAbyssSkulkItemId] = PrecacheAsset("ui/items/abyss/item_abyss_skulk.dds"),
    [kAbyssGorgeItemId] = PrecacheAsset("ui/items/abyss/item_abyss_gorge.dds"),
    [kAbyssLerkItemId] = PrecacheAsset("ui/items/abyss/item_abyss_lerk.dds"),
    [kAbyssFadeItemId] = PrecacheAsset("ui/items/abyss/item_abyss_fade.dds"),
    [kAbyssOnosItemId] = PrecacheAsset("ui/items/abyss/item_abyss_onos.dds"),
    [kAbyssTunnelItemId] = PrecacheAsset("ui/items/abyss/item_abyss_structures.dds"),
    [kAbyssStructuresItemId] = PrecacheAsset("ui/items/abyss/item_abyss_structures.dds"),

    [kReaperSkulkItemId] = PrecacheAsset("ui/items/reaper/item_reaper_skulk.dds"),
    [kReaperGorgeItemId] = PrecacheAsset("ui/items/reaper/item_reaper_gorge.dds"),
    [kReaperLerkItemId] = PrecacheAsset("ui/items/reaper/item_reaper_lerk.dds"),
    [kReaperFadeItemId] = PrecacheAsset("ui/items/reaper/item_reaper_fade.dds"),
    [kReaperOnosItemId] = PrecacheAsset("ui/items/reaper/item_reaper_onos.dds"),
    [kReaperStructuresItemId] = PrecacheAsset("ui/items/reaper/item_hive.dds"),

}


local AutoAddPurchasableItemDefs = function()

    local purchasableItems = {}
    if not Client.GetPurchasableItems(purchasableItems) then
        Log("Failed to fetch purchasble items list")
        return
    end
    
    for i = 1, #purchasableItems do
        local itemId = purchasableItems[i][1]
        local name = purchasableItems[i][2]
        local description = purchasableItems[i][3]
        local isBundle = purchasableItems[i][6]

        if not isBundle then
            kItemDefs[itemId] = 
            {
                title = string.format(Locale.ResolveString("NEW_ITEM"), name),
                message = description,
                icon = kItemIcons[itemId]
            }
        end
    end
end

--Must be delayed until Client is in "loaded" state, otherwise, needed binding aren't in socpe
Event.Hook("LoadComplete", AutoAddPurchasableItemDefs)
