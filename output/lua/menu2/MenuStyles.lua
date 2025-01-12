-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/MenuStyles.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--    
--    Contains all the GUI styles and sounds used for the new main menu.
--    
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/style/GUIStyleConfigurations.lua")
Script.Load("lua/menu2/MenuUtilities.lua")

MenuStyle = {}
-- Colors
    MenuStyle.kApplyGreyedOut = HexToColor("4a4f50")
    MenuStyle.kBasicBoxBackgroundColor = Color(0, 0, 0, 0.65)
    MenuStyle.kBasicStrokeColor = HexToColor("36393d", 0.5)
    MenuStyle.kBlack = HexToColor("101314")
    MenuStyle.kConflictedBackgroundColor = HexToColor("8d2626")
    MenuStyle.kConflictedStrokeColor = HexToColor("621b1b")
    MenuStyle.kConflictedHighlightColor = HexToColor("a73333")
    MenuStyle.kDarkGrey = HexToColor("242326")
    MenuStyle.kDarkHighlight = HexToColor("4f7e91")
    MenuStyle.kDropShadowColor = HexToColor("070a0f", 0.5)
    MenuStyle.kGlossColor = HexToColor("98bec5", 0.067)
    MenuStyle.kHighlight = HexToColor("36b4d4")
    MenuStyle.kHighlightBackground = HexToColor("121e27")
    MenuStyle.kHighlightStrokeColor = HexToColor("277a8f")
    MenuStyle.kLightGrey = HexToColor("6a6a6a")
    MenuStyle.kOptionHeadingColor = HexToColor("93b0b7")
    
    MenuStyle.kPingColorBad = HexToColor("d06814")
    MenuStyle.kPingColorGood = HexToColor("14d03c")
    MenuStyle.kPingColorOkay = HexToColor("94d014")
    MenuStyle.kPingColorTerrible = HexToColor("e1230a")
    
    MenuStyle.kRookieTextColor = HexToColor("1f9742")
    MenuStyle.kScrollBarWidgetBackgroundColor = Color(0, 0, 0, 0.6)
    MenuStyle.kScrollBarWidgetForegroundColor = HexToColor("6a6a6a")
    MenuStyle.kServerBrowserBackgroundGradientColor1 = Color(0,0,0,0.9)
    MenuStyle.kServerBrowserBackgroundGradientColor2 = HexToColor("262b35", 1.0)
    MenuStyle.kServerBrowserBackgroundInnerGlowColor = HexToColor("abbdcc", 0.1)
    MenuStyle.kServerBrowserBackgroundStrokeColor = HexToColor("8d96a0", 0.5)
    MenuStyle.kServerBrowserEntryDetailsBoxStrokeColor = HexToColor("0f445a", 0.4)
    MenuStyle.kServerBrowserEntryDetailsGradientColor1 = HexToColor("000000", 0.4)
    MenuStyle.kServerBrowserEntryDetailsGradientColor2 = HexToColor("000000", 0.64)
    MenuStyle.kServerBrowserEntryDetailsScrollerColor = HexToColor("1c5c6d")
    MenuStyle.kServerBrowserEntryDetailsScrollerDimColor = HexToColor("002a3a")
    MenuStyle.kServerBrowserEntryModsListFillColor = HexToColor("000000", 0.4)
    MenuStyle.kServerBrowserEntryModsListStrokeColor = HexToColor("104960", 0.3843)
    MenuStyle.kServerBrowserEntrySpecSelectedColor = HexToColor("758c92")
    MenuStyle.kServerBrowserHeaderColumnBoxFillColor = HexToColor("1e2127", 0.4)
    MenuStyle.kServerBrowserHeaderColumnBoxStrokeColor = Color(0, 0, 0, 0.4)
    MenuStyle.kServerBrowserHighlightDarker = HexToColor("216678")
    MenuStyle.kServerBrowserIconDim = HexToColor("4e4e4e")
    MenuStyle.kServerBrowserTopButtonGroupColor = HexToColor("0c0f14", 1.0)
    MenuStyle.kServerBrowserTopButtonGroupGradientColor1 = HexToColor("05070c", 0.0)
    MenuStyle.kServerBrowserTopButtonGroupGradientColor2 = HexToColor("282f3a", 1.0)
    MenuStyle.kServerBrowserTopButtonGroupStrokeColor = HexToColor("6c9ea3", 0.5)
    MenuStyle.kServerEntryHighlightGradientColor1 = HexToColor("016284")
    MenuStyle.kServerEntryHighlightGradientColor2 = HexToColor("268bad")
    MenuStyle.kServerEntryHighlightStrokeColor = HexToColor("00ebff")
    MenuStyle.kServerNameColor = HexToColor("91adb4")
    MenuStyle.kHeaderIconPlainColor = HexToColor("91adb4")
    MenuStyle.kTooltipText = HexToColor("b8b8b8")
    MenuStyle.kWarningColor = HexToColor("ac392d")
    MenuStyle.kWhite = Color(1,1,1,1)
    MenuStyle.kOffWhite = HexToColor("d1d1d1")
    MenuStyle.kButtonInnerStrokeColor = HexToColor("8d96a0", 0.3)
    MenuStyle.kPopupTitleColor = HexToColor("5dc0d9")
    
    MenuStyle.kServerBrowserFilterWindowSliderStrokeColor   = HexToColor("00ddf0")
    MenuStyle.kServerBrowserFilterWindowSliderFillColor     = HexToColor("215e6e")

    MenuStyle.kModDescriptionColor = HexToColor("277184")

    MenuStyle.kCustomizeAlienButtonColor = HexToColor("FF9F23")
    MenuStyle.kCustomizeAlienButtonColorGlow = HexToColor("FFCA3A")
    
    MenuStyle.kCustomizeAliensViewFontColor = HexToColor("FFCA3A")
    MenuStyle.kCustomizeMarinesViewFontColor = HexToColor("4DB1FF")

-- Fonts
    MenuStyle.kBindingFont                             = ReadOnly{family = "MicrogrammaBold", size = 32}
    MenuStyle.kHeadingFont                             = ReadOnly{family = "MicrogrammaBold", size = 32}
    MenuStyle.kNavBarFont                              = ReadOnly{family = "MicrogrammaBold", size = 46}
    MenuStyle.kOptionFont                              = ReadOnly{family = "AgencyBold", size = 37}
    MenuStyle.kOptionHeadingFont                       = ReadOnly{family = "AgencyBold", size = 46}
    MenuStyle.kOptionGroupHeadingFont                  = ReadOnly{family = "AgencyBold", size = 56}
    MenuStyle.kPlayMatchMakingFont                     = ReadOnly{family = "Microgramma", size = 28}
    MenuStyle.kPlayMenuFont                            = ReadOnly{family = "Microgramma", size = 28}
    MenuStyle.kServerAllFilterFont                     = ReadOnly{family = "Microgramma", size = 32}
    MenuStyle.kServerListHeaderFont                    = ReadOnly{family = "Microgramma", size = 24}
    MenuStyle.kServerNameFont                          = ReadOnly{family = "AgencyBold", size = 40}
    MenuStyle.kTooltipFont                             = ReadOnly{family = "Agency", size = 32}
    MenuStyle.kServerBrowserFiltersWindowFont          = ReadOnly{family = "Microgramma", size = 22}
    MenuStyle.kServerBrowserFiltersWindowChoiceFont    = ReadOnly{family = "Microgramma", size = 32}
    MenuStyle.kServerBrowserPopulationTextFont         = ReadOnly{family = "Microgramma", size = 27}
    MenuStyle.kServerBrowserGameModeFilter             = ReadOnly{family = "AgencyBold", size = 28}
    MenuStyle.kModDescriptionFont                      = ReadOnly{family = "AgencyBold", size = 28}
    MenuStyle.kButtonFont                              = ReadOnly{family = "MicrogrammaBold", size = 40}
    MenuStyle.kDialogTitleFont                         = ReadOnly{family = "MicrogrammaBold", size = 53}
    MenuStyle.kDialogMessageFont                       = ReadOnly{family = "Agency", size = 55}

    MenuStyle.kCustomizeViewBarMarineButtonFont     = ReadOnly{family = "AgencyBold", size = 44}
    MenuStyle.kCustomizeViewBarAlienButtonFont      = ReadOnly{family = "AgencyBold", size = 44}

    MenuStyle.kCustomizeViewAliensButtonFont           = ReadOnly{family = "AgencyBold", size = 68}
    MenuStyle.kCustomizeViewMarinesButtonFont          = ReadOnly{family = "MicrogrammaBold", size = 44}
    MenuStyle.kCustomizeViewBuyButtonFont              = ReadOnly{family = "MicrogrammaBold", size = 36}

    MenuStyle.kRewardsOverlayTextFont                  = ReadOnly{family = "Agency", size = 80}
    MenuStyle.kRewardsPlayScreenTitleFont              = ReadOnly{family = "MicrogrammaBold", size = 42}
    MenuStyle.kRewardsPlayScreenButtonTopTextFont      = ReadOnly{family = "AgencyBold", size = 55}
    MenuStyle.kRewardsPlayScreenButtonBottomTextFont   = ReadOnly{family = "AgencyBold", size = 71}
    MenuStyle.kRewardsPlayScreenDescFont               = ReadOnly{family = "Agency", size = 34}
    MenuStyle.kRewardsLineFlagLabelFont                = ReadOnly{family = "Agency", size = 40}
    MenuStyle.kRewardsDetailsDescriptionFont           = ReadOnly{family = "Agency", size = 34}
    MenuStyle.kRewardsDetailsTitleFont                 = ReadOnly{family = "MicrogrammaBold", size = 48}
    MenuStyle.kRewardsDetailsProgressLabelFont         = ReadOnly{family = "AgencyBold", size = 46}
    MenuStyle.kRewardsDetailsProgressFont              = ReadOnly{family = "AgencyBold", size = 60}
    MenuStyle.kRewardsNodeCommanderTagFont             = ReadOnly{family = "Agency", size = 25}
    MenuStyle.kRewardsNodeBlankTagFont                 = ReadOnly{family = "AgencyBold", size = 30}

    MenuStyle.kExpansionAutoCropPadding = Vector(4, 4, 0)
    MenuStyle.kExpansionBottomPadding = 10
    MenuStyle.kExpansionTopPadding = 60

-- Animation Speeds
    MenuStyle.kTextAutoScrollSpeedMult = 2 -- auto scroll speed = speedMult * font local size
    MenuStyle.kTextAutoScrollFrontDelay = 1
    MenuStyle.kTextAutoScrollBackDelay = 1.5
    MenuStyle.kTextAutoScrollSmoothTime = 0.5
--[=[
    MenuStyle.kExpandAnimationSpeed = 25
    MenuStyle.kFlashSpeed = 25
    MenuStyle.kItemFadeOutSpeed = 10
    MenuStyle.kItemFlySpeed = 25
    MenuStyle.kMenuScreenFlySpeed = 12.5
    MenuStyle.kScrollSmoothingSpeed = 25
    MenuStyle.kServerBrowserArrangeSpeed = 25
--]=]

-- Measurements
    MenuStyle.kDropShadowOffset = Vector(0, 7.5, 0)
    MenuStyle.kDropShadowRadius = 60.0
    MenuStyle.kInnerGlowRadius = 40.0
    MenuStyle.kStrokeWidth = 1.0
    MenuStyle.kScrollBarWidgetDefaultThickness = 34
    MenuStyle.kScrollBarWidgetDefaultLength = 400
    
    MenuStyle.kDefaultWidgetSize = Vector(1024, 84, 0) -- 960 + 64 (64 is size of reset button)
    MenuStyle.kLabelSpacing = 16 -- spacing between label and contents.
    MenuStyle.kWidgetPadding = 16 -- spacing between widget contents and edge of widget.
    MenuStyle.kWidgetContentsSpacing = 16 -- spacing between contents of a widget.
    MenuStyle.kKeybindWidgetSize = Vector(960, 75, 0)
    
    MenuStyle.kDividerHeight = 128

-- Colored text background, with small inner glow on top of light gradient, with large outer glow.
MenuStyle.kMainBarButtonGlow = PrecacheGUIStyleConfig(
{
    padding = 17, -- extra pixels added to all 4 sides to make room for outer glow.  Scales with gui object.
    shader = "shaders/GUI/menu/mainBarButtonGlow.surface_shader",
    inputs =
    {
        [1] = {
            name = "innerGlowBlur",
            value = GUIStyle.TextBlur(3)
        },
        [2] = { name = "innerGlowColor", value = HexToColor("7df7ff", 0.32) },
        
        [3] = {
            name = "outerGlowBlur",
            value = GUIStyle.TextBlur(15)
        },
        [4] = { name = "outerGlowColor", value = HexToColor("4f74e1") },
        
        [5] = { name = "baseTexture", value = "__Text", },
        [6] = { name = "textColor", value = HexToColor("42d9ff") },
    },
})

-- Colored text background, with small inner glow on top of light gradient, with large outer glow.
MenuStyle.kCustomizeButtonGlow = PrecacheGUIStyleConfig(
{
    padding = 17, -- extra pixels added to all 4 sides to make room for outer glow.  Scales with gui object.
    shader = "shaders/GUI/menu/mainBarButtonGlow.surface_shader",
    inputs =
    {
        [1] = {
            name = "innerGlowBlur",
            value = GUIStyle.TextBlur(3)
        },
        [2] = { name = "innerGlowColor", value = HexToColor("7df7ff", 0.32) },
        
        [3] = {
            name = "outerGlowBlur",
            value = GUIStyle.TextBlur(15)
        },
        [4] = { name = "outerGlowColor", value = HexToColor("4f74e1") },
        
        [5] = { name = "baseTexture", value = "__Text", },
        [6] = { name = "textColor", value = HexToColor("ffffff") },
    },
})

MenuStyle.kCustomizeBarButtonAlienGlow = PrecacheGUIStyleConfig(
{
    padding = 17, -- extra pixels added to all 4 sides to make room for outer glow.  Scales with gui object.
    shader = "shaders/GUI/menu/mainBarButtonGlow.surface_shader",
    inputs =
    {
        [1] = {
            name = "innerGlowBlur",
            value = GUIStyle.TextBlur(3)
        },
        [2] = { name = "innerGlowColor", value = HexToColor("ffca3a", 0.32) },
        
        [3] = {
            name = "outerGlowBlur",
            value = GUIStyle.TextBlur(15)
        },
        [4] = { name = "outerGlowColor", value = HexToColor("FFCA3A") },
        
        [5] = { name = "baseTexture", value = "__Text", },
        [6] = { name = "textColor", value = HexToColor("ffca3a") },
    },
})

MenuStyle.kMainBarButtonText = PrecacheGUIStyleConfig(
{
    shader = "shaders/GUI/menu/textGradient.surface_shader",
    padding = 3, -- some text extends slightly outside its bounds :(
    inputs =
    {
        [1] = { name = "baseTexture", value = "__Text", },
        [2] = { name = "opacity", value = 0.34, },
        [3] = { name = "gradScale", value = 0.8, },
        [4] = { name = "textColor", value = HexToColor("d5faff"), },
    }
})

MenuStyle.kMainBarDisabledButtonText = PrecacheGUIStyleConfig(
{
    shader = "shaders/GUI/menu/textGradient.surface_shader",
    padding = 3, -- some text extends slightly outside its bounds :(
    inputs =
    {
        [1] = { name = "baseTexture", value = "__Text", },
        [2] = { name = "opacity", value = 0.22, },
        [3] = { name = "gradScale", value = 0.8, },
        [4] = { name = "textColor", value = HexToColor("242326"), },
    }
})

MenuStyle.kThunderdomeActionSelectLabel = PrecacheGUIStyleConfig(
{
    shader = "shaders/GUI/menu/textGradient.surface_shader",
    padding = 3, -- some text extends slightly outside its bounds :(
    inputs =
    {
        [1] = { name = "baseTexture", value = "__Text", },
        [2] = { name = "opacity",     value = 128/255, },
        [3] = { name = "gradScale",   value = 48/96, },
        [4] = { name = "textColor",   value = MenuStyle.kOptionHeadingColor, },
    }
})

MenuStyle.kThunderdomeActionSelectLabelActive = PrecacheGUIStyleConfig(
{
    shader = "shaders/GUI/menu/textGradient.surface_shader",
    padding = 3, -- some text extends slightly outside its bounds :(
    inputs =
    {
        [1] = { name = "baseTexture", value = "__Text", },
        [2] = { name = "opacity",     value = 64/255, },
        [3] = { name = "gradScale",   value = 48/96, },
        [4] = { name = "textColor",   value = MenuStyle.kWhite, },
    }
})

MenuStyle.kThunderdomeMapSelectionLabel = PrecacheGUIStyleConfig(
{
    shader = "shaders/GUI/menu/textGradient.surface_shader",
    padding = 3, -- some text extends slightly outside its bounds :(
    inputs =
    {
        [1] = { name = "baseTexture", value = "__Text", },
        [2] = { name = "opacity",     value = 144/231, },
        [3] = { name = "gradScale",   value = 41/47, },
        [4] = { name = "textColor",   value = HexToColor("e7e7e7"), },
    }
})

MenuStyle.kThunderdomePlayerNameLabel = PrecacheGUIStyleConfig(
{
    shader = "shaders/GUI/menu/textGradient.surface_shader",
    padding = 3, -- some text extends slightly outside its bounds :(
    inputs =
    {
        [1] = { name = "baseTexture", value = "__Text", },
        [2] = { name = "opacity",     value = 144/231, },
        [3] = { name = "gradScale",   value = 48/54, },
        [4] = { name = "textColor",   value = HexToColor("dfeef1"), },
    }
})

MenuStyle.kThunderdomeRewardsOverlayText = PrecacheGUIStyleConfig(
{
    padding = 17, -- extra pixels added to all 4 sides to make room for outer glow.  Scales with gui object.
    shader = "shaders/GUI/menu/mainBarButtonGlow.surface_shader",
    inputs =
    {
        [1] = {
            name = "innerGlowBlur",
            value = GUIStyle.TextBlur(3)
        },
        [2] = { name = "innerGlowColor", value = HexToColor("7df7ff", 0) },

        [3] = {
            name = "outerGlowBlur",
            value = GUIStyle.TextBlur(15)
        },
        [4] = { name = "outerGlowColor", value = HexToColor("2497e7") },

        [5] = { name = "baseTexture", value = "__Text", },
        [6] = { name = "textColor", value = HexToColor("31b7df") },
    }
})

MenuStyle.kThunderdomeRewardsPlayButtonOff = PrecacheGUIStyleConfig(
{
    padding = 17, -- extra pixels added to all 4 sides to make room for outer glow.  Scales with gui object.
    shader = "shaders/GUI/menu/mainBarButtonGlow.surface_shader",
    inputs =
    {
        [1] = {
            name = "innerGlowBlur",
            value = GUIStyle.TextBlur(3)
        },
        [2] = { name = "innerGlowColor", value = HexToColor("7df7ff", 0.1) },

        [3] = {
            name = "outerGlowBlur",
            value = GUIStyle.TextBlur(15)
        },
        [4] = { name = "outerGlowColor", value = HexToColor("75c6ff", 0) },

        [5] = { name = "baseTexture", value = "__Text", },
        [6] = { name = "textColor", value = HexToColor("ffffff") },
    }
})

MenuStyle.kThunderdomeRewardsPlayButtonOn = PrecacheGUIStyleConfig(
{
    padding = 17, -- extra pixels added to all 4 sides to make room for outer glow.  Scales with gui object.
    shader = "shaders/GUI/menu/mainBarButtonGlow.surface_shader",
    inputs =
    {
        [1] = {
            name = "innerGlowBlur",
            value = GUIStyle.TextBlur(3)
        },
        [2] = { name = "innerGlowColor", value = HexToColor("7df7ff", 0.1) },

        [3] = {
            name = "outerGlowBlur",
            value = GUIStyle.TextBlur(15)
        },
        [4] = { name = "outerGlowColor", value = HexToColor("75c6ff", 0.49) },

        [5] = { name = "baseTexture", value = "__Text", },
        [6] = { name = "textColor", value = HexToColor("ffffff") },
    }
})

MenuSounds = {}
MenuSounds.SliderSound = "sound/NS2.fev/common/hovar"
MenuSounds.ScrollSound = "sound/NS2.fev/common/hovar"
MenuSounds.ButtonHover = "sound/NS2.fev/common/hovar"
MenuSounds.ButtonClick = "sound/NS2.fev/common/button_click"

MenuSounds.BeginChoice = "sound/NS2.fev/common/arrow"
MenuSounds.CancelChoice = "sound/NS2.fev/common/checkbox_off"
MenuSounds.AcceptChoice = "sound/NS2.fev/common/checkbox_on"

MenuSounds.Notification = "sound/NS2.fev/common/tooltip_on"

MenuSounds.MenuLoop = "sound/NS2.fev/common/menu_loop"

MenuSounds.MissionStepFinish = "sound/NS2.fev/alien/fade/swipe"

MenuSounds.InvalidSound        = "sound/NS2.fev/common/invalid"

--Customize Scene Marine voiceover samples
MenuSounds.CustomizeMaleVoice1 = "sound/NS2.fev/marine/voiceovers/hostiles"
MenuSounds.CustomizeMaleVoice2 = "sound/NS2.fev/marine/voiceovers/covering"
MenuSounds.CustomizeMaleVoice3 = "sound/NS2.fev/marine/voiceovers/need_orders"
MenuSounds.CustomizeMaleVoice4 = "sound/NS2.fev/marine/voiceovers/lets_move"
MenuSounds.CustomizeMaleVoice5 = "sound/NS2.fev/marine/voiceovers/taunt"
MenuSounds.CustomizeMaleVoice6 = "sound/NS2.fev/marine/voiceovers/ack"
MenuSounds.CustomizeMaleVoice7 = "sound/NS2.fev/marine/voiceovers/complete"
MenuSounds.CustomizeMaleVoice8 = "sound/NS2.fev/marine/voiceovers/all_clear"
MenuSounds.CustomizeMaleVoice9 = "sound/NS2.fev/marine/voiceovers/follow_me"

MenuSounds.CustomizeFemaleVoice1 = "sound/NS2.fev/marine/voiceovers/hostiles_female"
MenuSounds.CustomizeFemaleVoice2 = "sound/NS2.fev/marine/voiceovers/covering_female"
MenuSounds.CustomizeFemaleVoice3 = "sound/NS2.fev/marine/voiceovers/need_orders_female"
MenuSounds.CustomizeFemaleVoice4 = "sound/NS2.fev/marine/voiceovers/lets_move_female"
MenuSounds.CustomizeFemaleVoice5 = "sound/NS2.fev/marine/voiceovers/taunt_female"
MenuSounds.CustomizeFemaleVoice6 = "sound/NS2.fev/marine/voiceovers/ack_female"
MenuSounds.CustomizeFemaleVoice7 = "sound/NS2.fev/marine/voiceovers/complete_female"
MenuSounds.CustomizeFemaleVoice8 = "sound/NS2.fev/marine/voiceovers/follow_me_female"

MenuSounds.CustomizeBmacFriendVoice1 = "sound/NS2.fev/marine/voiceovers/bigmac_friendly/hostiles"
MenuSounds.CustomizeBmacFriendVoice2 = "sound/NS2.fev/marine/voiceovers/bigmac_friendly/covering"
MenuSounds.CustomizeBmacFriendVoice3 = "sound/NS2.fev/marine/voiceovers/bigmac_friendly/need_orders"
MenuSounds.CustomizeBmacFriendVoice4 = "sound/NS2.fev/marine/voiceovers/bigmac_friendly/lets_move"
MenuSounds.CustomizeBmacFriendVoice5 = "sound/NS2.fev/marine/voiceovers/bigmac_friendly/taunt"
MenuSounds.CustomizeBmacFriendVoice6 = "sound/NS2.fev/marine/voiceovers/bigmac_friendly/ack"
MenuSounds.CustomizeBmacFriendVoice7 = "sound/NS2.fev/marine/voiceovers/bigmac_friendly/complete"
MenuSounds.CustomizeBmacFriendVoice8 = "sound/NS2.fev/marine/voiceovers/bigmac_friendly/all_clear"
MenuSounds.CustomizeBmacFriendVoice9 = "sound/NS2.fev/marine/voiceovers/bigmac_friendly/follow_me"

MenuSounds.CustomizeBmacCombatVoice1 = "sound/NS2.fev/marine/voiceovers/bigmac_combat/hostiles"
MenuSounds.CustomizeBmacCombatVoice2 = "sound/NS2.fev/marine/voiceovers/bigmac_combat/covering"
MenuSounds.CustomizeBmacCombatVoice3 = "sound/NS2.fev/marine/voiceovers/bigmac_combat/need_orders"
MenuSounds.CustomizeBmacCombatVoice4 = "sound/NS2.fev/marine/voiceovers/bigmac_combat/lets_move"
MenuSounds.CustomizeBmacCombatVoice5 = "sound/NS2.fev/marine/voiceovers/bigmac_combat/taunt"
MenuSounds.CustomizeBmacCombatVoice6 = "sound/NS2.fev/marine/voiceovers/bigmac_combat/ack"
MenuSounds.CustomizeBmacCombatVoice7 = "sound/NS2.fev/marine/voiceovers/bigmac_combat/complete"
MenuSounds.CustomizeBmacCombatVoice8 = "sound/NS2.fev/marine/voiceovers/bigmac_combat/all_clear"
MenuSounds.CustomizeBmacCombatVoice9 = "sound/NS2.fev/marine/voiceovers/bigmac_combat/follow_me"

--Thunderdome-specific sounds
MenuSounds.ThunderdomeAttention = "sound/NS2.fev/marine/commander/ping"

PrecacheMenuSounds()


-- Animations
local function ExponentialAnimation(obj, time, params, currentValue, startValue, endValue, startTime)
    local diff = startValue - endValue
    local t = 1 - (1 / (2 ^ (params.speed * time)))
    return currentValue + diff * (1 - t), t > 0.999
end

local function LinearAnimation(obj, time, params, currentValue, startValue, endValue, startTime)
    local diff = startValue - endValue
    local dist = diff:GetLength()
    local duration = dist / params.speed
    local t = Clamp(time / duration, 0, 1)
    return currentValue + diff * (1.0 - t), t >= 1
end

local function PulseColorAnimation(obj, time, params, currentValue, startValue, endValue, startTime)
    local mult = math.cos(time * math.pi * 2 * params.frequency) -- in range -1..1
    mult = mult * 0.5 + 0.5 -- in range 0..1
    mult = mult * params.strength + (1.0 - params.strength) -- in range 1-strength..1
    return currentValue * Color(1, 1, 1, mult), false
end

local function LerpColorAnimation(obj, time, params, currentValue, startValue, endValue, startTime)
    local mult = math.sin(time * math.pi * 2 * params.frequency) -- in range -1..1
    mult = mult * 0.5 + 0.5 -- in range 0..1
    return LerpColor(params.startValue, params.endValue, mult), false
end

local function PulseOpacityAnimation(obj, time, params, currentValue, startValue, endValue, startTime)
    local mult = math.cos(time * math.pi * 2 * params.frequency) -- in range -1..1
    mult = mult * 0.5 + 0.5 -- in range 0..1
    mult = mult * params.strength + (1.0 - params.strength) -- in range 1-strength..1
    return currentValue * mult, false
end

local function HighlightFlashAnimation(obj, time, params, currentValue, startValue, endValue, startTime)
    local t = 1 - (1 / (2 ^ (params.speed * time)))
    return currentValue + Color(2, 2, 2, 1) * (1 - t), t > 0.999
end

local function ScaleOutAnimation(obj, time, params, currentValue, startValue, endValue, startTime)
    local t = Clamp(time / params.duration, 0, 1)
    local minScale = 0.0001
    t = 1 - t*t
    local scale = t * (1-minScale) + minScale
    return currentValue * scale, time >= params.duration
end

local function ScaleInAnimation(obj, time, params, currentValue, startValue, endValue, startTime)
    local t = Clamp(time / params.duration, 0, 1)
    local minScale = 0.0001
    t = 2*t - t*t
    local scale = t * (1-minScale) + minScale
    return currentValue * scale, time >= params.duration
end

MenuAnimations = {}

MenuAnimations.FlashColor = ReadOnly
{
    func = ExponentialAnimation,
    speed = 25,
}

MenuAnimations.HighlightFlashColor = ReadOnly
{
    func = HighlightFlashAnimation,
    speed = 25,
}

MenuAnimations.Fade = ReadOnly
{
    func = ExponentialAnimation,
    speed = 10,
}

MenuAnimations.FadeFast = ReadOnly
{
    func = ExponentialAnimation,
    speed = 25,
}

MenuAnimations.FlyIn = ReadOnly
{
    func = ExponentialAnimation,
    speed = 25,
}

MenuAnimations.FlyInFast = ReadOnly
{
    func = ExponentialAnimation,
    speed = 50,
}

MenuAnimations.Linear = ReadOnly
{
    func = LinearAnimation,
    speed = 200,
}

MenuAnimations.PulseColor = ReadOnly
{
    func = PulseColorAnimation,
    strength = 0.25,
    frequency = 2.0,
}

MenuAnimations.TDLerpLifeformColor = ReadOnly
{
    func = LerpColorAnimation,
    frequency = 0.4,
    startValue = ColorFrom255(88, 87, 87),
    endValue = ColorFrom255(211, 159, 58),
}

MenuAnimations.PulseOpacity = ReadOnly
{
    func = PulseOpacityAnimation,
    strength = 0.25,
    frequency = 2.0,
}

MenuAnimations.TDStatusBarActiveStage = ReadOnly
{
    func = PulseOpacityAnimation,
    strength = 0.7,
    frequency = 0.4,
}

MenuAnimations.TDPulseOpacity = ReadOnly
{
    func = PulseOpacityAnimation,
    strength = 0.9,
    frequency = 0.15,
}

MenuAnimations.DeathScreenFade = ReadOnly
{
    func = ExponentialAnimation,
    speed = 5,
}

MenuAnimations.ScaleOut = ReadOnly
{
    func = ScaleOutAnimation,
    duration = 0.5,
}

MenuAnimations.ScaleIn = ReadOnly
{
    func = ScaleInAnimation,
    duration = 0.5,
}
