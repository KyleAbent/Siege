-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/MissionDefs/NewPlayerMission.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Mission for new players to earn the "eat your greens" shoulder patch.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

local kGreensIcon = PrecacheAsset("ui/progress/skulk.dds")

local marineTutorialConfig = CreateAchievementMissionStepConfig
{
    name = "newPlayer_marineTutorialStep",
    title = Locale.ResolveString("THUNDERDOME_TUTORIAL_MARINE_TITLE"),
    description = Locale.ResolveString("THUNDERDOME_TUTORIAL_MARINE_DESC"),
    achievement = "First_0_6",
    pressCallback = function(self)
        GetScreenManager():DisplayScreen("Training")
    end,
}

local alienTutorialConfig = CreateAchievementMissionStepConfig
{
    name = "newPlayer_alienTutorialStep",
    title = Locale.ResolveString("THUNDERDOME_TUTORIAL_ALIEN_TITLE"),
    description = Locale.ResolveString("THUNDERDOME_TUTORIAL_ALIEN_DESC"),
    achievement = "First_0_7",
    pressCallback = function(self)
        GetScreenManager():DisplayScreen("Training")
    end,
}

local marineCommanderTutorialConfig = CreateAchievementMissionStepConfig
{
    name = "newPlayer_marineCommanderTutorialStep",
    title = Locale.ResolveString("THUNDERDOME_TUTORIAL_MARINECOM_TITLE"),
    description = Locale.ResolveString("THUNDERDOME_TUTORIAL_MARINECOM_DESC"),
    achievement = "First_0_8",
    legacy = true,
    pressCallback = function(self)
        GetScreenManager():DisplayScreen("Training")
    end,
}

local alienCommanderTutorialConfig = CreateAchievementMissionStepConfig
{
    name = "newPlayer_alienCommanderTutorialStep",
    title = Locale.ResolveString("THUNDERDOME_TUTORIAL_ALIENCOM_TITLE"),
    description = Locale.ResolveString("THUNDERDOME_TUTORIAL_ALIENCOM_DESC"),
    achievement = "First_0_9",
    legacy = true,
    pressCallback = function(self)
        GetScreenManager():DisplayScreen("Training")
    end,
}

local playSkulkChallengeConfig = CreateAchievementMissionStepConfig
{
    name = "newPlayer_skulkChallengeStep",
    title = Locale.ResolveString("THUNDERDOME_TUTORIAL_SKULKCHALLENGE_TITLE"),
    description = Locale.ResolveString("THUNDERDOME_TUTORIAL_SKULKCHALLENGE_DESC"),
    achievement = "First_0_10",
    pressCallback = function(self)
        GetScreenManager():DisplayScreen("Challenges")
    end,
}

assert(GUIMenuMissionScreen) -- *should* have been loaded by now...
GUIMenuMissionScreen.AddMissionConfig(
{
    name = "mission_newPlayer",
    class = GUIMenuMission,
    params =
    {
        title1 = Locale.ResolveString("THUNDERDOME_MISSION_TITLE1"),
        title2 = Locale.ResolveString("THUNDERDOME_MISSION_TITLE2"),
        completionCheckTex = kGreensIcon,
        completionDescription = Locale.ResolveString("MISSION_NEW_PLAYER_COMPLETION_DESCRIPTION"),
        stepConfigs =
        {
            marineTutorialConfig,
            alienTutorialConfig,
            marineCommanderTutorialConfig,
            alienCommanderTutorialConfig,
            playSkulkChallengeConfig,
        },
        completedCallback = function()
            if not Client.GetAchievement("First_1_0") then
                Client.SetAchievement("First_1_0")
                Client.GrantPromoItems()
                InventoryNewItemNotifyPush( kRookieShoulderPatchItemId )
            end
        end,
    }
})

Script.Load("lua/GUI/GUIDebug.lua")

