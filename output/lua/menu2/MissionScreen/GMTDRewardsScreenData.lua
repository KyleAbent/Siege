-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GMTDRewardsScreenData.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Data about rewards for the thunderdome rewards screen.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/Utility.lua")
Script.Load("lua/OrderedIterableDict.lua")

---Constructs the full locale string from the shortened version found in the rewards data table. (title or desc)
---@param shortLocaleId string Shortened Locale id (Ex: "BADGE_T0")
---@return string Full Locale id (Ex: "THUNDERDOME_REWARD_BADGE_T0_TITLE" or "THUNDERDOME_REWARD_BADGE_T0_DESC")
function GetThunderdomeRewardLocale(shortLocaleId, isDescription)
    local postFix = isDescription and "DESC" or "TITLE"
    return string.format("%s%s%s%s", "THUNDERDOME_REWARD_", shortLocaleId, "_", postFix)
end

local kBaseThunderdomeIconPath = "ui/thunderdome_rewards_icons/"

---Constructs the full icon path from the shortened version found in the rewards data table. (big or small)
---@param baseIconPath string Shortened Icon Path (Ex: "badge_t0.dds")
---@return string Full Icon Path (Ex: "ui/thunderdome_rewards/badge_t0.dds")
function GetThunderdomeRewardIconPath(baseIconPath, isSmall)
    if baseIconPath == "" then
        return ""
    end
    local specifier = isSmall and "_small" or ""
    return string.format("%s%s%s.dds", kBaseThunderdomeIconPath, baseIconPath, specifier)
end

---@return table,table
---Gets Sorted tables for time/victory rewards.
---Returns Time Rewards, Victory Rewards in that order
function GetSortedThunderdomeRewards()

    local sortedTimeRewards = {}
    local sortedVictoryRewards = {}

    local rewardsWithMissingData = {} -- For error checking

    for i = 1, #kThunderdomeRewards do

        local rewardEnumName = kThunderdomeRewards[i]
        local rewardEnumIndex = kThunderdomeRewards[rewardEnumName]

        local isTimeReward = kThunderdomeTimeRewardsData[rewardEnumIndex] ~= nil
        local isVictoryReward = kThunderdomeVictoryRewardsData[rewardEnumIndex] ~= nil

        if (not isTimeReward and not isVictoryReward) then
            if rewardEnumIndex ~= kThunderdomeRewards.None then
                table.insert(rewardsWithMissingData, rewardEnumName)
            end
        else

            local rewardTable = isTimeReward and kThunderdomeTimeRewardsData[rewardEnumIndex] or kThunderdomeVictoryRewardsData[rewardEnumIndex]
            local sortedTable = isTimeReward and sortedTimeRewards or sortedVictoryRewards

            local tableEntry = { id = rewardEnumIndex, data = rewardTable }
            table.insert(sortedTable, tableEntry)

        end

    end -- End For, Finished sorting by time/victory

    if #rewardsWithMissingData > 0 then
        local errorStr = string.format("%d rewards have missing data! { %s }", #rewardsWithMissingData, ToString(rewardsWithMissingData))
        error(errorStr)
    end

    local function SortByProgress(a,b)
        return a.data.progressRequired < b.data.progressRequired
    end

    table.sort(sortedTimeRewards, SortByProgress)
    table.sort(sortedVictoryRewards, SortByProgress)

    return sortedTimeRewards, sortedVictoryRewards

end

kThunderdomeRewards = enum({
    "None",
    "WoodRifle",
    "Badge1",
    "WoodPistol",
    "WoodAxe",
    "DamascusPistolGreen",
    "Badge2",
    "DamascusAxeGreen",
    "MadAxeGorge",
    "ChromaFT",
    "AuricSkulk",
    "Badge3",
    "ChromaAxe",
    "AuricBabbler",
    "DamascusRifleGreen",
    "AuricHarvester",
    "ChromaWelder",
    "AuricBileMine",
    "Badge4",
    "WidowSkulk",
    "Badge5",
    "ChromaExosuit",
    "ChromaBmac",
    "Badge6",
    "ChromaBmacMilitary",
    "AuricOnos",
    "Badge7",
    "ChromaMarine",
    "Badge8",
    "ChromaExtractor",
    "ChromaArc",
    "AuricCyst",
    "AuricDrifter",
    "ChromaMac",
    "ChromaGL",
    "DamascusRiflePurple",
    "DamascusAxePurple",
    "DamascusAxeBlack",
    "DamascusPistolPurple",
    "ChromaHMG",
    "AuricClog",
    "DamascusPistolBlack",
    "ChromaShotgun",
    "AuricGorge",
    "AuricHydra",
    "DamascusRifleBlack",
    "AuricLerk",
    "AuricFade",
    "AuricEgg",
    "AuricTunnel",
    "AuricHive",
    "ChromaCommandStation",

    -- Calling Cards
    "CCSkulkHug",
    "CCDontBlink",
    "CCBabyMarine",
    "CCLockedAndLoaded",
    "CCNedRage",
    "CCUrpaBooty",
    "CCSadBabbler",
    "CCJobWeldDone",
    "CCBalanceGorge",
    "CCLork",
    "CCLazyGorge",
    "CCUrpa",
    "CCSlipperSkulk",
    "CCShadowFade",
    "CCBurnoutFade",
    "CCOver9000Degrees",
    "CCLerked",
    "CCTableFlipGorge",
    "CCAngryOnos",
    "CCOhNoes",

    "CCForScience",
    "CCTurboDrifter",
    "CCBattleGorge",
})

kThunderdomeTimeRewardsData =
{
    -- Field Hours Rewards
    [kThunderdomeRewards.WoodRifle] =            { progressRequired = 1,    itemId = kWoodRifleItemId,                  locale = "RIFLE_WOOD"           ,  iconPath = "rifle_wood" },
    [kThunderdomeRewards.Badge1] =               { progressRequired = 2,    itemId = kTDTier1BadgeItemId,               locale = "BADGE_T1"             ,  iconPath = "Badges_Progression_1" },
    [kThunderdomeRewards.WoodPistol] =           { progressRequired = 2,    itemId = kWoodPistolItemId,                 locale = "PISTOL_WOOD"          ,  iconPath = "pistol_wood" },
    [kThunderdomeRewards.WoodAxe] =              { progressRequired = 3,    itemId = kWoodAxeItemId,                    locale = "AXE_WOOD"             ,  iconPath = "axe_wood" },
    [kThunderdomeRewards.DamascusPistolGreen] =  { progressRequired = 4,    itemId = kDamascusGreenPistolItemId,        locale = "PISTOL_DAMASCUS_GREEN",  iconPath = "pistol_damascus_green" },
    [kThunderdomeRewards.Badge2] =               { progressRequired = 5,    itemId = kTDTier2BadgeItemId,               locale = "BADGE_T2"             ,  iconPath = "Badges_Progression_2" },
    [kThunderdomeRewards.DamascusAxeGreen] =     { progressRequired = 6,    itemId = kDamascusGreenAxeItemId,           locale = "AXE_DAMASCUS_GREEN"   ,  iconPath = "axe_damascus_green" },
    [kThunderdomeRewards.MadAxeGorge] =          { progressRequired = 9,    itemId = kBattleGorgeShoulderPatchItemId,   locale = "PATCH_MADAXEGORGE"    ,  iconPath = "Decal_MadAxeGorge" },
    [kThunderdomeRewards.ChromaFT] =             { progressRequired = 12,   itemId = kChromaFlamethrowerItemId,         locale = "FT_CHROMA"            ,  iconPath = "FT" },
    [kThunderdomeRewards.AuricSkulk] =           { progressRequired = 16,   itemId = kAuricSkulkItemId,                 locale = "SKULK_AURIC"          ,  iconPath = "skulk_auric" },
    [kThunderdomeRewards.Badge3] =               { progressRequired = 20,   itemId = kTDTier3BadgeItemId,               locale = "BADGE_T3"             ,  iconPath = "Badges_Progression_3" },
    [kThunderdomeRewards.ChromaAxe] =            { progressRequired = 26,   itemId = kChromaAxeItemId,                  locale = "AXE_CHROMA"           ,  iconPath = "axe_chroma" },
    [kThunderdomeRewards.AuricBabbler] =         { progressRequired = 35,   itemId = kAuricGorgeBabblerItemId,          locale = "BABBLER_AURIC"        ,  iconPath = "babbler_auric" },
    [kThunderdomeRewards.DamascusRifleGreen] =   { progressRequired = 45,   itemId = kDamascusGreenRifleItemId,         locale = "RIFLE_DAMASCUS_GREEN" ,  iconPath = "rifle_damascus_green" },
    [kThunderdomeRewards.AuricHarvester] =       { progressRequired = 55,   itemId = kAuricHarvesterItemId,             locale = "HARVESTER_AURIC"      ,  iconPath = "harvester_auric" },
    [kThunderdomeRewards.ChromaWelder] =         { progressRequired = 75,   itemId = kChromaWelderItemId,               locale = "WELDER_CHROMA"        ,  iconPath = "welder_chroma" },
    [kThunderdomeRewards.AuricBileMine] =        { progressRequired = 95,   itemId = kAuricGorgeBabblerEggItemId,       locale = "BILEMINE_AURIC"       ,  iconPath = "bilemine_auric" },
    [kThunderdomeRewards.Badge4] =               { progressRequired = 115,  itemId = kTDTier4BadgeItemId,               locale = "BADGE_T4"             ,  iconPath = "Badges_Progression_4" },
    [kThunderdomeRewards.WidowSkulk] =           { progressRequired = 150,  itemId = kWidowSkulkItemId,                 locale = "SKULK_WIDOW"          ,  iconPath = "skulk_widow" },
    [kThunderdomeRewards.Badge5] =               { progressRequired = 200,  itemId = kTDTier5BadgeItemId,               locale = "BADGE_T5"             ,  iconPath = "Badges_Progression_5" },
    [kThunderdomeRewards.ChromaExosuit] =        { progressRequired = 200,  itemId = kChromaExoItemId,                  locale = "EXOSUIT_CHROMA"       ,  iconPath = "exo_chroma" },
    [kThunderdomeRewards.ChromaBmac] =           { progressRequired = 300,  itemId = kChromaBigmacItemId,               locale = "BMAC_CHROMA"          ,  iconPath = "bmac_chroma" },
    [kThunderdomeRewards.Badge6] =               { progressRequired = 500,  itemId = kTDTier6BadgeItemId,               locale = "BADGE_T6"             ,  iconPath = "Badges_Progression_6" },
    [kThunderdomeRewards.ChromaBmacMilitary] =   { progressRequired = 500,  itemId = kChromaMilitaryBmacItemId,         locale = "BMACMIL_CHROMA"       ,  iconPath = "bmac_military_chroma" },
    [kThunderdomeRewards.AuricOnos] =            { progressRequired = 700,  itemId = kAuricOnosItemId,                  locale = "ONOS_AURIC"           ,  iconPath = "onos_auric" },
    [kThunderdomeRewards.Badge7] =               { progressRequired = 1000, itemId = kTDTier7BadgeItemId,               locale = "BADGE_T7"             ,  iconPath = "Badges_Progression_7" },
    [kThunderdomeRewards.ChromaMarine] =         { progressRequired = 1000, itemId = kChromaArmorItemId,                locale = "MARINE_ELITEASSAULT"  ,  iconPath = "marines_eliteassault" },
    [kThunderdomeRewards.Badge8] =               { progressRequired = 1500, itemId = kTDTier8BadgeItemId,               locale = "BADGE_T8"             ,  iconPath = "Badges_Progression_8" },

    -- Comm Hours Rewards
    [kThunderdomeRewards.ChromaExtractor] =      { progressRequired = 10,   itemId = kChromaExtractorItemId,            locale = "EXTRACTOR_CHROMA"     ,  iconPath = "extractor_chroma" },
    [kThunderdomeRewards.ChromaArc] =            { progressRequired = 20,   itemId = kChromaArcItemId,                  locale = "ARC_CHROMA"           ,  iconPath = "arc_chroma" },
    [kThunderdomeRewards.AuricCyst] =            { progressRequired = 45,   itemId = kAuricCystItemId,                  locale = "CYST_AURIC"           ,  iconPath = "cyst_auric" },
    [kThunderdomeRewards.AuricDrifter] =         { progressRequired = 60,   itemId = kAuricDrifterItemId,               locale = "DRIFTER_AURIC"        ,  iconPath = "drifter_auric" },
    [kThunderdomeRewards.ChromaMac] =            { progressRequired = 90,   itemId = kChromaMacItemId,                  locale = "MAC_CHROMA"           ,  iconPath = "mac_chroma" },

}

kThunderdomeVictoryRewardsData =
{
    -- Field Victory Rewards
    [kThunderdomeRewards.CCSkulkHug] =           { progressRequired = 3,    locale = "CC_SKULK_HUG"          },
    [kThunderdomeRewards.ChromaGL] =             { progressRequired = 5,    itemId = kChromaGrenadeLauncherItemId, locale = "GRENADELAUNCHER_CHROMA",  iconPath = "GL_chroma" },
    [kThunderdomeRewards.CCDontBlink] =          { progressRequired = 7,    locale = "CC_DONT_BLINK"         },
    [kThunderdomeRewards.DamascusRiflePurple] =  { progressRequired = 10,   itemId = kDamascusPurpleRifleItemId,   locale = "RIFLE_DAMASCUS_PURPLE" ,  iconPath = "rifle_damascus_purple" },
    [kThunderdomeRewards.CCBabyMarine] =         { progressRequired = 13,   locale = "CC_BABY_MARINE"        },
    [kThunderdomeRewards.DamascusAxePurple] =    { progressRequired = 15,   itemId = kDamascusPurpleAxeItemId,     locale = "AXE_DAMASCUS_PURPLE"   ,  iconPath = "axe_damascus_purple" },
    [kThunderdomeRewards.CCLockedAndLoaded] =    { progressRequired = 17,   locale = "CC_LOCKED_AND_LOADED"  },
    [kThunderdomeRewards.DamascusAxeBlack] =     { progressRequired = 20,   itemId = kDamascusAxeItemId,           locale = "AXE_DAMASCUS_BLACK"    ,  iconPath = "axe_damascus_black" },
    [kThunderdomeRewards.CCNedRage] =            { progressRequired = 23,   locale = "CC_NED_RAGE"           },
    [kThunderdomeRewards.DamascusPistolPurple] = { progressRequired = 25,   itemId = kDamascusPurplePistolItemId,  locale = "PISTOL_DAMASCUS_PURPLE",  iconPath = "pistol_damascus_purple" },
    [kThunderdomeRewards.CCUrpaBooty] =          { progressRequired = 27,   locale = "CC_URPA_BOOTY"         },
    [kThunderdomeRewards.ChromaHMG] =            { progressRequired = 30,   itemId = kChromaHMGItemId,             locale = "HMG_CHROMA"            ,  iconPath = "HMG_chroma" },
    [kThunderdomeRewards.CCSadBabbler] =         { progressRequired = 33,   locale = "CC_SAD_BABBLER"        },
    [kThunderdomeRewards.CCJobWeldDone] =        { progressRequired = 37,   locale = "CC_WELD_DONE"          },
    [kThunderdomeRewards.AuricClog] =            { progressRequired = 40,   itemId = kAuricGorgeClogItemId,        locale = "CLOG_AURIC"            ,  iconPath = "clog_auric" },
    [kThunderdomeRewards.CCBalanceGorge] =       { progressRequired = 43,   locale = "CC_BALANCE_GORGE"      },
    [kThunderdomeRewards.DamascusPistolBlack] =  { progressRequired = 45,   itemId = kDamascusPistolItemId,        locale = "PISTOL_DAMASCUS_BLACK" ,  iconPath = "pistol_damascus_black" },
    [kThunderdomeRewards.CCLork] =               { progressRequired = 47,   locale = "CC_LORK"               },
    [kThunderdomeRewards.ChromaShotgun] =        { progressRequired = 50,   itemId = kChromaShotgunItemId,         locale = "SHOTGUN_CHROMA"        ,  iconPath = "SG_chroma" },
    [kThunderdomeRewards.CCLazyGorge] =          { progressRequired = 55,   locale = "CC_LAZY_GORGE"         },
    [kThunderdomeRewards.CCUrpa] =               { progressRequired = 60,   locale = "CC_URPA"               },
    [kThunderdomeRewards.AuricGorge] =           { progressRequired = 65,   itemId = kAuricGorgeItemId,            locale = "GORGE_AURIC"           ,  iconPath = "gorge_auric" },
    [kThunderdomeRewards.CCSlipperSkulk] =       { progressRequired = 70,   locale = "CC_SLIPPER_SKULK"      },
    [kThunderdomeRewards.CCShadowFade] =         { progressRequired = 75,   locale = "CC_SHADOW_FADE"        },
    [kThunderdomeRewards.AuricHydra] =           { progressRequired = 80,   itemId = kAuricGorgeHydraItemId,       locale = "HYDRA_AURIC"           ,  iconPath = "hydra_auric" },
    [kThunderdomeRewards.CCBurnoutFade] =        { progressRequired = 85,   locale = "CC_BURNOUT_FADE"       },
    [kThunderdomeRewards.CCOver9000Degrees] =    { progressRequired = 90,   locale = "CC_OVER9000_DEGREES"   },
    [kThunderdomeRewards.DamascusRifleBlack] =   { progressRequired = 110,  itemId = kDamascusRifleItemId,         locale = "RIFLE_DAMASCUS_BLACK"  ,  iconPath = "rifle_damascus_black" },
    [kThunderdomeRewards.CCLerked] =             { progressRequired = 200,  locale = "CC_LERKED"             },
    [kThunderdomeRewards.CCTableFlipGorge] =     { progressRequired = 250,  locale = "CC_TABLE_FLIP_GORGE"   },
    [kThunderdomeRewards.AuricLerk] =            { progressRequired = 300,  itemId = kAuricLerkItemId,             locale = "LERK_AURIC"            ,  iconPath = "lerk_auric" },
    [kThunderdomeRewards.CCAngryOnos] =          { progressRequired = 350,  locale = "CC_ANGRY_ONOS"         },
    [kThunderdomeRewards.CCOhNoes] =             { progressRequired = 400,  locale = "CC_OHNOES"             },
    [kThunderdomeRewards.AuricFade] =            { progressRequired = 500,  itemId = kAuricFadeItemId,             locale = "FADE_AURIC"            ,  iconPath = "fade_auric" },

    -- Comm Victory Rewards
    [kThunderdomeRewards.AuricEgg] =             { progressRequired = 10,   itemId = kAuricEggItemId,              locale = "EGG_AURIC"             ,  iconPath = "egg_auric" },
    [kThunderdomeRewards.CCForScience] =         { progressRequired = 15,   locale = "CC_FOR_SCIENCE"        },
    [kThunderdomeRewards.AuricTunnel] =          { progressRequired = 20,   itemId = kAuricTunnelItemId,           locale = "TUNNEL_AURIC"          ,  iconPath = "tunnel_auric" },
    [kThunderdomeRewards.CCTurboDrifter] =       { progressRequired = 25,   locale = "CC_TURBO_DRIFTER"      },
    [kThunderdomeRewards.AuricHive] =            { progressRequired = 45,   itemId = kAuricHiveItemId,             locale = "HIVE_AURIC"            ,  iconPath = "hive_auric" },
    [kThunderdomeRewards.CCBattleGorge] =        { progressRequired = 60,   locale = "CC_BATTLE_GORGE"       },
    [kThunderdomeRewards.ChromaCommandStation] = { progressRequired = 80,   itemId = kChromaCommandStationItemId,  locale = "COMMANDSTATION_CHROMA" ,  iconPath = "CC_chroma" },
}

local kThunderdomeRewardToCallingCard =
{
    [kThunderdomeRewards.CCSkulkHug]        = kCallingCards.SkulkHuggies,
    [kThunderdomeRewards.CCDontBlink]       = kCallingCards.DontBlink,
    [kThunderdomeRewards.CCBabyMarine]      = kCallingCards.BabyMarine,
    [kThunderdomeRewards.CCLockedAndLoaded] = kCallingCards.LockedAndLoaded,
    [kThunderdomeRewards.CCNedRage]         = kCallingCards.NedRage,
    [kThunderdomeRewards.CCUrpaBooty]       = kCallingCards.UrpaBooty,
    [kThunderdomeRewards.CCSadBabbler]      = kCallingCards.SadBabbler,
    [kThunderdomeRewards.CCJobWeldDone]     = kCallingCards.WeldDone,
    [kThunderdomeRewards.CCBalanceGorge]    = kCallingCards.BalanceGorge,
    [kThunderdomeRewards.CCLork]            = kCallingCards.Lork,
    [kThunderdomeRewards.CCLazyGorge]       = kCallingCards.LazyGorge,
    [kThunderdomeRewards.CCUrpa]            = kCallingCards.Urpa,
    [kThunderdomeRewards.CCSlipperSkulk]    = kCallingCards.SkulkSlippers,
    [kThunderdomeRewards.CCShadowFade]      = kCallingCards.ShadowFade,
    [kThunderdomeRewards.CCBurnoutFade]     = kCallingCards.BurnoutFade,
    [kThunderdomeRewards.CCOver9000Degrees] = kCallingCards.Over9000Degrees,
    [kThunderdomeRewards.CCLerked]          = kCallingCards.Lerked,
    [kThunderdomeRewards.CCTableFlipGorge]  = kCallingCards.GorgeTableFlip,
    [kThunderdomeRewards.CCAngryOnos]       = kCallingCards.AngryOnos,
    [kThunderdomeRewards.CCOhNoes]          = kCallingCards.OhNoes,
    [kThunderdomeRewards.CCForScience]      = kCallingCards.ForScience,
    [kThunderdomeRewards.CCTurboDrifter]    = kCallingCards.TurboDrifter,
    [kThunderdomeRewards.CCBattleGorge]     = kCallingCards.BattleGorge,
}

local kThunderdomeCommanderRewards = set
{
    kThunderdomeRewards.AuricEgg,
    kThunderdomeRewards.CCForScience,
    kThunderdomeRewards.AuricTunnel,
    kThunderdomeRewards.CCTurboDrifter,
    kThunderdomeRewards.AuricHive,
    kThunderdomeRewards.CCBattleGorge,
    kThunderdomeRewards.ChromaCommandStation,

    kThunderdomeRewards.ChromaExtractor,
    kThunderdomeRewards.ChromaArc,
    kThunderdomeRewards.AuricCyst,
    kThunderdomeRewards.AuricDrifter,
    kThunderdomeRewards.ChromaMac,
}

function GetThunderdomeRewardCallingCardId(thunderdomeReward)
    return kThunderdomeRewardToCallingCard[thunderdomeReward]
end

function GetIsThunderdomeRewardCommander(thunderdomeReward)
    return kThunderdomeCommanderRewards[thunderdomeReward] == true
end

function GetIsThunderdomeRewardUnlocked(thunderdomeReward)

    local rewardData = kThunderdomeTimeRewardsData[thunderdomeReward] or kThunderdomeVictoryRewardsData[thunderdomeReward]
    local rewardCallingCard = kThunderdomeRewardToCallingCard[thunderdomeReward]

    if rewardCallingCard then

        return GetIsCallingCardUnlocked(rewardCallingCard)

    end

    return GetOwnsItem(rewardData.itemId)

end

local function OnDumpTDRewardsData()

    Print("\n\nDumping Rewards Data")
    Print("============================================================\n")

    Print("\nTime Rewards\n-------------------------------------------")

    local sortedTimeRewards, sortedVictoryRewards = GetSortedThunderdomeRewards()

    -- Group rewards by progression units
    local timeRewards = OrderedIterableDict()
    for i = 1, #sortedTimeRewards do

        local reward = sortedTimeRewards[i]

        if not timeRewards[reward.data.progressRequired] then
            timeRewards[reward.data.progressRequired] = {}
        end

        table.insert(timeRewards[reward.data.progressRequired], reward)

    end

    for i, v in pairs(timeRewards) do

        local numRewardsInGroup = #v
        if numRewardsInGroup > 1 then
            Print("Unlock Hours: %s (%s Rewards)", i, numRewardsInGroup)
            for k = 1, numRewardsInGroup do
                local reward = v[k]
                Print("\tTitle: %s, Commander: %s", Locale.ResolveString(GetThunderdomeRewardLocale(reward.data.locale, false)), reward.data.commander)
            end
        else
            Print("Unlock Hours: %s - Title: %s, Commander: %s", i, Locale.ResolveString(GetThunderdomeRewardLocale(v[1].data.locale, false)), v[1].data.commander)
        end

    end

    Print("\nVictory Rewards\n-------------------------------------------")

    local victoryRewards = OrderedIterableDict()
    for i = 1, #sortedVictoryRewards do

        local reward = sortedVictoryRewards[i]

        if not victoryRewards[reward.data.progressRequired] then
            victoryRewards[reward.data.progressRequired] = {}
        end

        table.insert(victoryRewards[reward.data.progressRequired], reward)

    end

    for i, v in pairs(victoryRewards) do

        local numRewardsInGroup = #v
        if numRewardsInGroup > 1 then
            Print("Unlock Hours: %s (%s Rewards)", i, numRewardsInGroup)
            for k = 1, numRewardsInGroup do
                local reward = v[k]
                Print("\tTitle: %s, Commander: %s", Locale.ResolveString(GetThunderdomeRewardLocale(reward.data.locale, false)), reward.data.commander)
            end
        else
            Print("Unlock Hours: %s - Title: %s, Commander: %s", i, Locale.ResolveString(GetThunderdomeRewardLocale(v[1].data.locale, false)), v[1].data.commander)
        end

    end

    Print("")

end

Event.Hook("Console_tdrewards_dump", OnDumpTDRewardsData)
