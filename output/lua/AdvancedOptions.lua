-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/AdvancedOptions.lua
--
-- Ported by: Darrell Gentry (darrell@naturalselection2.com)
--
-- Port of the NS2+ Advanced options data.
-- Originally Created By: Juanjo Alfaro "Mendasp"
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/OrderedIterableDict.lua")
Script.Load("lua/Utility.lua")

local kMainVM = decoda_name == "Main"

AdvancedOptions = OrderedIterableDict()

function GetAdvancedOption(optionName)

	local option = AdvancedOptions[optionName]
	if option ~= nil then

		local casterOption = AdvancedOptions["castermode"]
		local getter = GetOptionValueGetterFunctionForType(option.optionType)

		if option.disabled then

			return ConditionalValue(option.disabledValue == nil, option.default, option.disabledValue)

		elseif casterOption and Client.GetOptionBoolean(casterOption.optionPath, casterOption.default) and not option.ignoreCasterMode then

			if option.optionType == "color" then
				return ColorIntToColor(option.default)
			end

			return option.default

		else

			return getter(option.optionPath, option.default)

		end
	end

	return nil
end

--============================================
-- UI Category (User Interface)
--============================================

AdvancedOptions["banners"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_BANNERS"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_BANNERS_TOOLTIP"),
	category = "UI",

	optionPath = "CHUD_Banners",
	optionType = "bool",
	guiType = "checkbox",
	default = true,

	immediateUpdate = function()

		if not kMainVM then

			local player = Client.GetLocalPlayer()
			if player and HasMixin(player, "TeamMessage") then
				player:SetTeamMessageEnabled(GetAdvancedOption("banners"))
			end

		end

	end,
}

-- TODO(Salads): Convert - Should be checkbox?
AdvancedOptions["unlocks"] =
{
	label    = Locale.ResolveString("ADVANCED_OPTION_RESEARCH_NOTIFICATIONS") .. ": ",
	tooltip  = Locale.ResolveString("ADVANCED_OPTION_RESEARCH_NOTIFICATIONS_TOOLTIP"),
	category = "UI",

	guiType    = "dropdown",
	optionPath = "CHUD_Unlocks",
	optionType = "bool",
	choices    =
	{
		Locale.ResolveString("DISABLED"),
		Locale.ResolveString("ENABLED")
	},

	default    = true,

	immediateUpdate = function()

		if not kMainVM and Client and ClientUI then

			ClientUI.RestartScripts
			{
				"Hud/Marine/GUIMarineHUD",
				"GUIAlienHUD",
			}

			local script = ClientUI.GetScript("GUIChat")
			if script then
				script:UpdatePosition(Client.GetLocalPlayer())
			end

		end

	end,
}

AdvancedOptions["inventory"] =
{
	label    = Locale.ResolveString("ADVANCED_OPTION_INVENTORY") .. ": ",
	tooltip  = Locale.ResolveString("ADVANCED_OPTION_INVENTORY_TOOLTIP"),
	category = "UI",

	guiType    = "dropdown",
	optionPath = "CHUD_Inventory",
	optionType = "int",
	choices    =
	{
		Locale.ResolveString("ADVANCED_OPTION_INVENTORY_CHOICE_DEFAULT"),
		Locale.ResolveString("ADVANCED_OPTION_INVENTORY_CHOICE_HIDE"),
		Locale.ResolveString("ADVANCED_OPTION_INVENTORY_CHOICE_SHOWAMMO"),
		Locale.ResolveString("ADVANCED_OPTION_INVENTORY_CHOICE_ALWAYSON"),
		Locale.ResolveString("ADVANCED_OPTION_INVENTORY_CHOICE_ALWAYSONAMMO"),
	},
	default    = 0,

	immediateUpdate = function()
		if not kMainVM and ClientUI and GUIInventory then

			GUIInventory.kInventoryMode = GetAdvancedOption("inventory")
			ClientUI.RestartScripts
			{
				"Hud/Marine/GUIMarineHUD",
				"GUIAlienHUD",
				"GUIProgressBar",
			}
		end
	end,
}

AdvancedOptions["hivestatus"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_HIVESTATUS"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_HIVESTATUS_TOOLTIP"),
	category = "UI",

	guiType = "checkbox",
	optionPath = "CHUD_HiveStatus",
	optionType = "bool",
	default = true,

	immediateUpdate =
	function()

		if not kMainVM and ClientUI then

			ClientUI.RestartScripts
			{
				"GUIHiveStatus",
			}
		end

	end,
}

AdvancedOptions["hpbar"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_MARINE_HEALTHBARS"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_MARINE_HEALTHBARS_TOOLTIP"),
	category = "UI",

	guiType = "checkbox",
	optionPath = "CHUD_HPBar",
	optionType = "bool",
	default = true,

	immediateUpdate = function()
		if not kMainVM and Client and ClientUI then
			ClientUI.RestartScripts
			{
				"Hud/Marine/GUIMarineHUD"
			}
		end
	end,
}

AdvancedOptions["classicammo"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_CLASSICAMMO"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_CLASSICAMMO_TOOLTIP"),
	category = "UI",

	guiType = "checkbox",
	optionPath = "CHUD_ClassicAmmo",
	optionType = "bool",
	default = false,

	immediateUpdate = function()

		if Client and ClientUI then

			ClientUI.RestartScripts
			{
				"GUIClassicAmmo"
			}

		end

	end,
}

AdvancedOptions["lowammowarning"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_LOWAMMOWARNING"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_LOWAMMOWARNING_TOOLTIP"),
	category = "UI",

	optionPath = "CHUD_LowAmmoWarning",
	optionType = "bool",
	guiType = "checkbox",
	default = true,

	immediateUpdate = function()
		if not kMainVM and Weapon ~= nil then
			Weapon.kLowAmmoWarningEnabled = GetAdvancedOption("lowammowarning")
		end
	end,
}

AdvancedOptions["avstate"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_AV_INITIALSTATE"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_AV_INITIALSTATE_TOOLTIP"),
	category = "UI",

	guiType = "checkbox",
	optionPath = "CHUD_AVState",
	optionType = "bool",
	default = true,

	immediateUpdate = function()

		if not kMainVM then
			Client.SendNetworkMessage("InitAVState",
			{
				startsOn = GetAdvancedOption("avstate")
			}, true)
		end

	end
}

AdvancedOptions["instantalienhealth"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_INSTANT_ALIENHEALTH"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_INSTANT_ALIENHEALTH_TOOLTIP"),
	category = "UI",

	guiType = "checkbox",
	optionPath = "CHUD_InstantAlienHealth",
	optionType = "bool",
	default = true,

	immediateUpdate = function()

		if not kMainVM and GUIAlienHUD then
			GUIAlienHUD.kInstantAlienHealthBall = GetAdvancedOption("instantalienhealth")
		end

	end,
}

AdvancedOptions["uiscale"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_UI_SCALING") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_UI_SCALING_TOOLTIP"),
	category = "UI",

	guiType = "slider",
	optionPath = "CHUD_UIScaling",
	optionType = "float",
	default = 1,
	minValue = 0.05,
	maxValue = 2,

	immediateUpdate = function()

		if not kMainVM then
			GUISetUserScale(GetAdvancedOption("uiscale"))
		end
	end,
}

--============================================
-- HUD Category (Heads Up Display)
--============================================

AdvancedOptions["hudbars_m"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_HUDBARS_MARINE") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_HUDBARS_MARINE_TOOLTIP"),
	category = "HUD",

	guiType = "dropdown",
	optionPath = "CHUD_CustomHUD_M",
	optionType = "int",
	choices  =
	{
		Locale.ResolveString("ADVANCED_OPTION_HUDBARS_MARINE_CHOICE_DEFAULT"),
		Locale.ResolveString("ADVANCED_OPTION_HUDBARS_MARINE_CHOICE_CENTRALIZED"),
		Locale.ResolveString("ADVANCED_OPTION_HUDBARS_MARINE_CHOICE_NS1"),
	},

	default = 0,

	immediateUpdate = function()

		if not kMainVM and Client and ClientUI then

			ClientUI.RestartScripts
			{
				"Hud/Marine/GUIMarineHUD",
				"GUIJetpackFuel",
				"GUIClassicAmmo",
			}

			HelpScreen_ForceUpdate()
		end
	end,
}

AdvancedOptions["hudbars_a"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_HUDBARS_ALIENS") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_HUDBARS_ALIENS_TOOLTIP"),
	category = "HUD",

	guiType = "dropdown",
	optionPath = "CHUD_CustomHUD_A",
	optionType = "int",
	choices  =
	{
		Locale.ResolveString("ADVANCED_OPTION_HUDBARS_ALIENS_CHOICE_DEFAULT"),
		Locale.ResolveString("ADVANCED_OPTION_HUDBARS_ALIENS_CHOICE_CENTRALIZED"),
		Locale.ResolveString("ADVANCED_OPTION_HUDBARS_ALIENS_CHOICE_NS1"),
	},

	default = 0,

	immediateUpdate = function()
		if not kMainVM and Client and ClientUI then

			ClientUI.RestartScripts
			{
				"GUIAlienHUD",
				"GUIUpgradeChamberDisplay",
			}

			-- Make sure the "evolution available" popup doesn't overlap ns1 hudbars.
			local script = ClientUI.GetScript("GUILifeformPopup")
			if script then
				script:UpdateBackgroundYPos()
			end

			HelpScreen_ForceUpdate()
		end
	end,
}

AdvancedOptions["topbar_a"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_TOPBAR_ALIENS"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_TOPBAR_ALIENS_TOOLTIP"),
	category = "HUD",
	
	guiType = "dropdown",
	optionPath = "advanced/topbar_aliens",
	optionType = "int",
	choices = 
	{
		Locale.ResolveString("ADVANCED_OPTION_TOPBAR_ALIENS_CHOICE_SHOWALWAYS"),
		Locale.ResolveString("ADVANCED_OPTION_TOPBAR_ALIENS_CHOICE_PLAYERONLY"),
		Locale.ResolveString("ADVANCED_OPTION_TOPBAR_ALIENS_CHOICE_COMMANDERONLY"),
		Locale.ResolveString("ADVANCED_OPTION_TOPBAR_ALIENS_CHOICE_HIDDEN"),
	},
	
	default = 0,
	
	immediateUpdate = function()
		local topBarScript = ClientUI.GetScript("Hud2/topBar/GUIHudTopBarForLocalTeam")
		if topBarScript then
			topBarScript:OnLocalPlayerChanged(Client.GetLocalPlayer())
		end
	end
}

AdvancedOptions["topbar_m"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_TOPBAR_MARINES"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_TOPBAR_MARINES_TOOLTIP"),
	category = "HUD",

	guiType = "dropdown",
	optionPath = "advanced/topbar_marines",
	optionType = "int",
	choices =
	{
		Locale.ResolveString("ADVANCED_OPTION_TOPBAR_MARINES_CHOICE_SHOWALWAYS"),
		Locale.ResolveString("ADVANCED_OPTION_TOPBAR_MARINES_CHOICE_PLAYERONLY"),
		Locale.ResolveString("ADVANCED_OPTION_TOPBAR_MARINES_CHOICE_COMMANDERONLY"),
		Locale.ResolveString("ADVANCED_OPTION_TOPBAR_MARINES_CHOICE_HIDDEN"),
	},

	default = 0,

	immediateUpdate = function()
		local topBarScript = ClientUI.GetScript("Hud2/topBar/GUIHudTopBarForLocalTeam")
		if topBarScript then
			topBarScript:OnLocalPlayerChanged(Client.GetLocalPlayer())
		end
	end
}

-- TODO(Salads): Option Parenting - Support for more than one level of parenting. (Killfeed Highlight)
-- TODO(Salads): Convert - Should be a checkbox?
AdvancedOptions["killfeedhighlight"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_KILLFEED_HIGHLIGHT") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_KILLFEED_HIGHLIGHT_TOOLTIP"),
	category = "HUD",

	guiType = "dropdown",
	optionPath = "CHUD_KillFeedHighlight",
	optionType = "int",
	choices =
	{
		Locale.ResolveString("DISABLED"),
		Locale.ResolveString("ENABLED"),
	},

	default = 1,

	immediateUpdate = function()

		if not kMainVM and GUIDeathMessages then
			GUIDeathMessages.kKillfeedHighlightEnabled = GetAdvancedOption("killfeedhighlight") == 1
		end

	end,
}

AdvancedOptions["killfeedcolorcustom"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_KILLFEED_USECOLOR"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_KILLFEED_USECOLOR_TOOLTIP"),
	category = "HUD",

	guiType = "checkbox",
	optionPath = "CHUD_KillFeedHighlightColorCustom",
	optionType = "bool",
	default = false,

	hideValues = { false },

	immediateUpdate = function()

		if not kMainVM and GUIDeathMessages then
			GUIDeathMessages.kKillfeedCustomColorEnabled = GetAdvancedOption("killfeedcolorcustom")
		end

	end,
}

AdvancedOptions["killfeedcolor"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_KILLFEED_CUSTOMCOLOR") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_KILLFEED_CUSTOMCOLOR_TOOLTIP"),
	category = "HUD",

	guiType = "colorPicker",
	optionPath = "CHUD_KillFeedHighlightColor",
	optionType = "color",
	default = 0xFF0000,

	immediateUpdate = function()

		if not kMainVM and GUIDeathMessages then

			GUIDeathMessages.kKillfeedCustomColor = GetAdvancedOption("killfeedcolor")

		end

	end,

	parent = "killfeedcolorcustom"
}

AdvancedOptions["killfeedscale"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_KILLFEED_SCALE") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_KILLFEED_SCALE_TOOLTIP"),
	category = "HUD",

	guiType = "slider",
	optionPath = "CHUD_KillFeedScale",
	optionType = "float",
	default = 1,
	minValue = 1,
	maxValue = 2,

	immediateUpdate = function()

		if not kMainVM and ClientUI and GUIDeathMessages then
			GUIDeathMessages.kKillfeedScale = GetAdvancedOption("killfeedscale")
			ClientUI.RestartScripts
			{
				"GUIDeathMessages"
			}
		end

	end,
}

AdvancedOptions["nameplates"] =
{
	label      = Locale.ResolveString("ADVANCED_OPTION_NAMEPLATE_STYLE") .. ": ",
	tooltip    = Locale.ResolveString("ADVANCED_OPTION_NAMEPLATE_STYLE_TOOLTIP"),
	category   = "HUD",

	guiType    = "dropdown",
	optionPath = "CHUD_Nameplates",
	optionType = "int",
	choices    =
	{
		Locale.ResolveString("ADVANCED_OPTION_NAMEPLATE_STYLE_CHOICE_DEFAULT"),
		Locale.ResolveString("ADVANCED_OPTION_NAMEPLATE_STYLE_CHOICE_NUMBERS"),
		Locale.ResolveString("ADVANCED_OPTION_NAMEPLATE_STYLE_CHOICE_BARSONLY"),
		Locale.ResolveString("ADVANCED_OPTION_NAMEPLATE_STYLE_CHOICE_NUMBERSANDBARS"),
	},

	default    = 0,
}

AdvancedOptions["smallnps"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_SMALLNAMEPLATES"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_SMALLNAMEPLATES_TOOLTIP"),
	category = "HUD",

	guiType = "checkbox",
	optionPath = "CHUD_SmallNameplates",
	optionType = "bool",
	default = false,

	immediateUpdate = function()

		if not kMainVM and ClientUI and GUIUnitStatus then
			GUIUnitStatus.kUseSmallNameplates = GetAdvancedOption("smallnps")
			ClientUI.RestartScripts{ "GUIUnitStatus" }
		end
	end,
}

AdvancedOptions["score"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_SCORE_POPUP"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_SCORE_POPUP_TOOLTIP"),
	category = "HUD",

	optionPath = "CHUD_ScorePopup",
	optionType = "bool",
	default = true,
	guiType = "checkbox",

	immediateUpdate = function()

		if not kMainVM and ScoreDisplayUI_SetScoreEnabled then

			ScoreDisplayUI_SetScoreEnabled(GetAdvancedOption("score"))

		end

	end,

	hideValues = { false },
}

AdvancedOptions["scorecolor"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_SCORE_COLOR") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_SCORE_COLOR_TOOLTIP"),
	category = "HUD",

	guiType = "colorPicker",
	optionPath = "CHUD_ScorePopupColor",
	optionType = "color",
	default = 0x19FF19,

	immediateUpdate = function()

		if not kMainVM and GUINotifications ~= nil then
			GUINotifications.kScoreDisplayKillTextColor = GetAdvancedOption("scorecolor")
		end

	end,

	parent = "score"
}

AdvancedOptions["assists"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_ASSISTS_POPUP"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_ASSISTS_POPUP_TOOLTIP"),
	category = "HUD",

	optionPath = "CHUD_Assists",
	optionType = "bool",
	default = true,
	guiType = "checkbox",

	immediateUpdate = function()

		if not kMainVM and ScoreDisplayUI_SetAssistsEnabled then

			ScoreDisplayUI_SetAssistsEnabled(GetAdvancedOption("assists"))

		end

	end,

	hideValues = { false },
}

AdvancedOptions["assistscolor"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_ASSISTS_COLOR") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_ASSISTS_COLOR_TOOLTIP"),
	category = "HUD",

	optionPath = "CHUD_AssistsPopupColor",
	optionType = "color",
	default = 0xBFBF19,
	guiType = "colorPicker",

	immediateUpdate = function()
		if not kMainVM and GUINotifications ~= nil then
			GUINotifications.kScoreDisplayTextColor = GetAdvancedOption("assistscolor")
		end
	end,

	parent = "assists"
}

AdvancedOptions["wps"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_WAYPOINTS"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_WAYPOINTS_TOOLTIP"),
	category = "HUD",

	guiType = "checkbox",
	optionPath = "CHUD_Waypoints",
	optionType = "bool",
	default = true,

	immediateUpdate = function()

		if not kMainVM and Client then
			Client.kWayPointsEnabled = GetAdvancedOption("wps")
		end

	end,
}

AdvancedOptions["pickupexpire"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_PICKUP_EXPIREBAR") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_PICKUP_EXPIREBAR_TOOLTIP"),
	category = "HUD",

	guiType = "dropdown",
	optionType = "int",
	optionPath = "CHUD_PickupExpire",
	choices  =
	{
		Locale.ResolveString("DISABLED"),
		Locale.ResolveString("ADVANCED_OPTION_PICKUP_EXPIREBAR_CHOICE_EQUIPMENTONLY"),
		Locale.ResolveString("ADVANCED_OPTION_PICKUP_EXPIREBAR_CHOICE_ALLPICKUPABLES"),
	},

	default = 2,

	immediateUpdate = function()

		if not kMainVM and GUIPickups then
			GUIPickups.kExpirationBarMode = GetAdvancedOption("pickupexpire")
		end

	end,
}

-- TODO(Salads): Convert - Should be checkbox
AdvancedOptions["pickupexpirecolor"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_PICKUP_EXPIREBAR_DYNAMIC") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_PICKUP_EXPIREBAR_DYNAMIC_TOOLTIP"),
	category = "HUD",

	guiType = "dropdown",
	optionPath = "CHUD_PickupExpireBarColor",
	optionType = "int",
	choices =
	{
		Locale.ResolveString("DISABLED"),
		Locale.ResolveString("ENABLED"),
	},

	default = 1,

	immediateUpdate = function()

		if not kMainVM and GUIPickups then
			GUIPickups.kUseColorIndicatorForExpirationBars = GetAdvancedOption("pickupexpirecolor") == 1
		end
	end,
}

-- TODO(Salads): Convert - Should be checkbox
AdvancedOptions["wrenchicon"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DYNAMIC_REPAIR_ICON") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DYNAMIC_REPAIR_ICON_TOOLTIP"),
	category = "HUD",

	guiType = "dropdown",
	optionPath = "CHUD_DynamicWrenchColor",
	optionType = "int",
	choices =
	{
		Locale.ResolveString("DISABLED"),
		Locale.ResolveString("ENABLED"),
	},

	default = 1,

	immediateUpdate = function()

		if not kMainVM and GUIUnitStatus then
			GUIUnitStatus.kUseColoredWrench = GetAdvancedOption("wrenchicon") == 1
		end
	end,
}

--============================================
-- Damage Category
--============================================

AdvancedOptions["serverblood"] =
{
	label    = Locale.ResolveString("ADVANCED_OPTION_SERVER_BLOOD_HITS") .. ": ",
	tooltip  = Locale.ResolveString("ADVANCED_OPTION_SERVER_BLOOD_HITS_TOOLTIP"),
	category = "DAMAGE",

	guiType    = "dropdown",
	optionPath = "CHUD_ServerBlood",
	optionType = "bool",
	choices    =
	{
		Locale.ResolveString("ADVANCED_OPTION_SERVER_BLOOD_HITS_CHOICE_PREDICTED"),
		Locale.ResolveString("ADVANCED_OPTION_SERVER_BLOOD_HITS_CHOICE_SERVERCONFIRMED"),
	},

	default = false,

	immediateUpdate = function()

		if not kMainVM then

			local serverBlood = GetAdvancedOption("serverblood")
			Client.SendNetworkMessage("ServerConfirmedHitEffects", { serverBlood = serverBlood }, true)

			local player = Client.GetLocalPlayer()
			if player then
				player.serverBlood = serverBlood
			end
		end

	end,
}

AdvancedOptions["damagenumbertime"] =
{
	label    = Locale.ResolveString("ADVANCED_OPTION_DAMAGE_NUMBER_FADETIME") .. ": ",
	tooltip  = Locale.ResolveString("ADVANCED_OPTION_DAMAGE_NUMBER_FADETIME_TOOLTIP"),
	category = "DAMAGE",

	guiType    = "slider",
	optionPath = "CHUD_DamageNumberTime",
	optionType = "float",

	default = kWorldMessageLifeTime,
	minValue = 0,
	maxValue = 3,

	immediateUpdate = function()

		if not kMainVM and Client ~= nil then
			Client.DamageNumberLifeTime = GetAdvancedOption("damagenumbertime")
		end

	end,
}

AdvancedOptions["dmgscale"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DAMAGE_NUMBER_SCALE") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DAMAGE_NUMBER_SCALE_TOOLTIP"),
	category = "DAMAGE",

	guiType = "slider",
	optionPath = "CHUD_DMGScale",
	optionType = "float",

	default = 1,
	minValue = 0.5,
	maxValue = 2,

	immediateUpdate = function()

		if not kMainVM and GUIWorldText ~= nil then
			GUIWorldText.kCustomScale = GetAdvancedOption("dmgscale")
		end

	end,
}

AdvancedOptions["dmgcolor_m"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DAMAGE_NUMBER_COLOR_MARINE") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DAMAGE_NUMBER_COLOR_MARINE_TOOLTIP"),
	category = "DAMAGE",

	guiType = "colorPicker",
	optionPath = "CHUD_DMGColorM",
	optionType = "color",
	default = 0x4DDBFF,

	immediateUpdate = function()

		if not kMainVM and GUIWorldText ~= nil then
			GUIWorldText.kMarineDamageColor = GetAdvancedOption("dmgcolor_m")
		end

	end,
}

AdvancedOptions["dmgcolor_a"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DAMAGE_NUMBER_COLOR_ALIEN") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DAMAGE_NUMBER_COLOR_ALIEN_TOOLTIP"),
	category = "DAMAGE",

	guiType = "colorPicker",
	optionPath = "CHUD_DMGColorA",
	optionType = "color",
	default = 0xFFCA3A,

	immediateUpdate = function()

		if not kMainVM and GUIWorldText ~= nil then
			GUIWorldText.kAlienDamageColor = GetAdvancedOption("dmgcolor_a")
		end

	end,
}

AdvancedOptions["dmgcolor_b"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DAMAGE_NUMBER_COLOR_BONESHIELD") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DAMAGE_NUMBER_COLOR_BONESHIELD_TOOLTIP"),
	category = "DAMAGE",

	guiType = "colorPicker",
	optionPath = "CHUD_DMGColorB",
	optionType = "color",
	default = 0xffb43f,

	immediateUpdate = function()

		if not kMainVM and GUIWorldText ~= nil then
			GUIWorldText.kBoneshieldDamageColor = GetAdvancedOption("dmgcolor_b")
		end

	end,
}

--============================================
-- Map Category
--============================================

AdvancedOptions["minimap"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_MARINE_MINIMAP"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_MARINE_MINIMAP_TOOLTIP"),
	category = "MAP",

	guiType = "checkbox",
	optionPath = "CHUD_Minimap",
	optionType = "bool",
	default = true,

	immediateUpdate = function()

		if not kMainVM and GUIMarineHUD and ClientUI then

			GUIMarineHUD.kHudMapEnabled = GetAdvancedOption("minimap")

			local marineHud = ClientUI.GetScript("Hud/Marine/GUIMarineHUD")
			if marineHud then
				marineHud:Reset()
			end

		end

	end,
}

AdvancedOptions["minimapalpha"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_MAP_BACKGROUND_OPACITY") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_MAP_BACKGROUND_OPACITY_TOOLTIP"),
	category = "MAP",

	optionPath = "CHUD_MinimapAlpha",
	optionType = "float",

	guiType = "slider",
	default = 0.60,
	minValue = 0,
	maxValue = 1,

	immediateUpdate = function()

		if not kMainVM then
			local minimapScript = ClientUI.GetScript("GUIMinimapFrame")
			if minimapScript then
				minimapScript:GetMinimapItem():SetColor(Color(1,1,1, GetAdvancedOption("minimapalpha")))
			end
		end
	end,
}

AdvancedOptions["locationalpha"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_MAP_LOCATION_TEXT_OPACITY") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_MAP_LOCATION_TEXT_OPACITY_TOOLTIP"),
	category = "MAP",

	optionPath = "CHUD_LocationAlpha",
	optionType = "float",
	guiType = "slider",
	default = 0.65,
	minValue = 0,
	maxValue = 1,

	immediateUpdate = function()
		if OnCommandSetMapLocationColor then
			OnCommandSetMapLocationColor(255, 255, 255, tonumber(GetAdvancedOption("locationalpha"))*255)
		end
	end,
}

AdvancedOptions["friends"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_MAP_FRIENDS_HIGHLIGHT"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_MAP_FRIENDS_HIGHLIGHT_TOOLTIP"),
	category = "MAP",

	guiType = "checkbox",
	optionPath = "CHUD_Friends",
	optionType = "bool",
	default = true,

	immediateUpdate = function()

		if not kMainVM and MapBlip ~= nil then

			MapBlip.kFriendsHighlightingEnabled = GetAdvancedOption("friends")

		end
	end,
}

AdvancedOptions["pglines"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_PHASEGATE_LINES") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_PHASEGATE_LINES_TOOLTIP"),
	category = "MAP",

	guiType = "dropdown",
	optionPath = "CHUD_MapConnectorLines",
	optionType = "int",
	choices  =
	{
		Locale.ResolveString("ADVANCED_OPTION_PHASEGATE_LINES_CHOICE_SOLID"),
		Locale.ResolveString("ADVANCED_OPTION_PHASEGATE_LINES_CHOICE_STATICARROWS"),
		Locale.ResolveString("ADVANCED_OPTION_PHASEGATE_LINES_CHOICE_ANIMATEDLINES"),
		Locale.ResolveString("ADVANCED_OPTION_PHASEGATE_LINES_CHOICE_ANIMATEDARROWS"),
	},

	default = 3,

	immediateUpdate = function()

		if not kMainVM and GUIMinimapConnection and ClientUI then

			GUIMinimapConnection.kLineMode = GetAdvancedOption("pglines")

			local script = ClientUI.GetScript("GUIMinimapFrame")
			if script then
				script:CheckMinimapConnectionTextures()
			end

			local marineHUD = ClientUI.GetScript("Hud/Marine/GUIMarineHUD")
			if marineHUD and marineHUD.minimapScript then
				marineHUD.minimapScript:CheckMinimapConnectionTextures()
			end
		end

	end,
}

AdvancedOptions["minimaptoggle"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_MAP_TOGGLE") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_MAP_TOGGLE_TOOLTIP"),
	category = "MAP",

	guiType    = "dropdown",
	optionPath = "CHUD_MinimapToggle",
	optionType = "int",
	choices    =
	{
		Locale.ResolveString("ADVANCED_OPTION_MAP_TOGGLE_CHOICE_HOLD"),
		Locale.ResolveString("ADVANCED_OPTION_MAP_TOGGLE_CHOICE_TOGGLE"),
	},

	default = 0,

	immediateUpdate = function()

		if not kMainVM and GUIMinimap then
			GUIMinimap.kToggleMap = GetAdvancedOption("minimaptoggle") == 1
		end

	end,
}

AdvancedOptions["minimaparrowcolor"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_PLAYER_ARROWCOLOR") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_PLAYER_ARROWCOLOR_TOOLTIP"),
	category = "MAP",

	guiType = "colorPicker",
	optionPath = "CHUD_MinimapArrowColor",
	optionType = "color",
	default = 0xFFFF00,

	immediateUpdate = function()

		if not kMainVM and ClientUI then

			local newColor = GetAdvancedOption("minimaparrowcolor")

			local minimapScript = ClientUI.GetScript("GUIMinimapFrame")
			if minimapScript then
				minimapScript:SetPlayerIconColor(Color(newColor))
			end

			local marineHudScript = ClientUI.GetScript("Hud/Marine/GUIMarineHUD")
			if marineHudScript and marineHudScript.minimapScript then
				marineHudScript.minimapScript:SetPlayerIconColor(Color(newColor))
			end
		end
	end,
}

AdvancedOptions["mapelementscolor"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_MAP_ELEMENTSCOLOR") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_MAP_ELEMENTSCOLOR_TOOLTIP"),
	category = "MAP",

	guiType = "colorPicker",
	optionPath = "CHUD_MapElementsColor",
	optionType = "color",
	default = 0x00FF80,

	immediateUpdate = function()

		if not kMainVM and MapBlip ~= nil then
			MapBlip.kCustomMapEntityColor = GetAdvancedOption("mapelementscolor")
		end
	end,
}

AdvancedOptions["playercolor_m"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_MARINE_PLAYERCOLOR") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_MARINE_PLAYERCOLOR_TOOLTIP"),
	category = "MAP",

	guiType = "colorPicker",
	optionPath = "CHUD_PlayerColor_M",
	optionType = "color",
	default = 0x00D8FF,

	immediateUpdate =
	function()

		if not kMainVM and MapBlip ~= nil then
			MapBlip.kCustomMarineColor = GetAdvancedOption("playercolor_m")
		end
	end,
}

AdvancedOptions["playercolor_a"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_ALIEN_PLAYERCOLOR") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_ALIEN_PLAYERCOLOR_TOOLTIP"),
	category = "MAP",

	guiType = "colorPicker",
	optionPath = "CHUD_PlayerColor_A",
	optionType = "color",
	default = 0xFF8A00,

	immediateUpdate =
	function()

		if not kMainVM and MapBlip ~= nil then
			MapBlip.kCustomAlienColor = GetAdvancedOption("playercolor_a")
		end
	end,
}

AdvancedOptions["commhighlight"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_COMMANDER_BUILDING_HIGHLIGHT"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_COMMANDER_BUILDING_HIGHLIGHT_TOOLTIP"),
	category = "MAP",

	guiType = "checkbox",
	optionPath = "CHUD_CommHighlight",
	optionType = "bool",
	default = true,

	immediateUpdate = function()

		if not kMainVM and MapBlip then
			MapBlip.kHighlightSameBuildings = GetAdvancedOption("commhighlight")
		end

	end,

	hideValues = { false },
}

AdvancedOptions["commhighlightcolor"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_COMMANDER_BUILDING_HIGHLIGHT_COLOR") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_COMMANDER_BUILDING_HIGHLIGHT_COLOR_TOOLTIP"),
	category = "MAP",

	guiType = "colorPicker",
	optionPath = "CHUD_CommHighlightColor",
	optionType = "color",
	default = 0xFFFF00,

	immediateUpdate = function()

		if not kMainVM and MapBlip then
			MapBlip.kHighlightSameBuildingsColor = GetAdvancedOption("commhighlightcolor")
		end

	end,

	parent = "commhighlight"
}

--============================================
-- Stats Category
--============================================

AdvancedOptions["deathstats"] =
{
	label    = Locale.ResolveString("ADVANCED_OPTION_DEATHSTATS") .. ": ",
	tooltip  = Locale.ResolveString("ADVANCED_OPTION_DEATHSTATS_TOOLTIP"),
	category = "STATS",

	guiType    = "dropdown",
	optionPath = "CHUD_DeathStats",
	optionType = "int",
	choices    =
	{
		Locale.ResolveString("ADVANCED_OPTION_DEATHSTATS_CHOICE_DISABLED"),
		Locale.ResolveString("ADVANCED_OPTION_DEATHSTATS_CHOICE_VOICEOVERONLY"),
		Locale.ResolveString("ENABLED"),
	},

	default       = 2,
	disabledValue = 0,
}

--============================================
-- Graphics Category
--============================================

AdvancedOptions["mapparticles"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_MAP_PARTICLES") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_MAP_PARTICLES_TOOLTIP"),
	category = "GRAPHICS",

	guiType = "dropdown",
	optionPath = "CHUD_MapParticles",
	optionType = "bool",
	choices  =
	{
		Locale.ResolveString("DISABLED"),
		Locale.ResolveString("ENABLED"),
	},

	default = true,

	immediateUpdate = function()

		if not kMainVM and Client and MapParticlesOption_Update then

			Client.kMapParticlesEnabled = GetAdvancedOption("mapparticles")
			MapParticlesOption_Update()

		end

	end,
}

AdvancedOptions["particles"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_PARTICLES") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_PARTICLES_TOOLTIP"),
	category = "GRAPHICS",

	guiType = "dropdown",
	optionType = "bool",
	optionPath = "CHUD_Particles",
	choices  =
	{
		Locale.ResolveString("DISABLED"),
		Locale.ResolveString("ENABLED"),
	},

	default = false,

	immediateUpdate = function()

		if not kMainVM and Client then
			MinimalParticlesOption_Update()
		end

	end,
}

AdvancedOptions["tracers"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_WEAPON_TRACERS"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_WEAPON_TRACERS_TOOLTIP"),
	category = "GRAPHICS",

	guiType = "checkbox",
	optionPath = "CHUD_Tracers",
	optionType = "bool",
	default = true,

	immediateUpdate = function()

		if not kMainVM and Player then
			Player.kTracersEnabled = GetAdvancedOption("tracers")
		end

	end,
}

--============================================
-- Crosshair Category (Needs custom entry in sorting table)
--============================================

AdvancedOptions["hitindicator"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_CROSSHAIR_HIT_FADETIME") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_CROSSHAIR_HIT_FADETIME_TOOLTIP"),
	category = "CROSSHAIR",

	guiType = "slider",
	optionPath = "CHUD_HitIndicator",
	optionType = "float",
	default = 0.25,
	minValue = 0,
	maxValue = 1,

	immediateUpdate = function()
		if not kMainVM and Player then
			Player.kShowGiveDamageTime = GetAdvancedOption("hitindicator")
		end
	end,
}

AdvancedOptions["crosshairscale"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_CROSSHAIR_SCALE") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_CROSSHAIR_SCALE_TOOLTIP"),
	category = "CROSSHAIR",

	guiType = "slider",
	optionPath = "CHUD_CrosshairScale",
	optionType = "float",
	default = 1,
	minValue = 0.01,
	maxValue = 2,

	immediateUpdate = function()

		if not kMainVM and ClientUI and GUICrosshair then

			GUICrosshair.kCrosshairScale = GetAdvancedOption("crosshairscale")

			ClientUI.RestartScripts
			{
				"GUICrosshair"
			}
		end
	end,
}

AdvancedOptions["reloadindicator"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_RELOAD_INDICATOR"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_RELOAD_INDICATOR_TOOLTIP"),
	category = "CROSSHAIR",

	guiType = "checkbox",
	optionPath = "CHUD_ReloadIndicator",
	optionType = "bool",
	default = false,

	immediateUpdate = function()

		if not kMainVM and ClientUI and GUICrosshair then

			GUICrosshair.kReloadIndicatorEnabled = GetAdvancedOption("reloadindicator")
			ClientUI.RestartScripts
			{
				"GUICrosshair"
			}
		end
	end,

	hideValues = { false },
}

AdvancedOptions["reloadindicatorcolor"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_RELOAD_INDICATOR_COLOR") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_RELOAD_INDICATOR_COLOR_TOOLTIP"),
	category = "CROSSHAIR",

	guiType = "colorPicker",
	optionPath = "CHUD_ReloadIndicatorColor",
	optionType = "color",
	default = 0x00A0FF,

	immediateUpdate = function()

		if not kMainVM and ClientUI and GUICrosshair then

			GUICrosshair.kReloadIndicatorColor = GetAdvancedOption("reloadindicatorcolor")
			ClientUI.RestartScripts
			{
				"GUICrosshair"
			}
		end
	end,

	parent = "reloadindicator"
}

--============================================
-- Misc Category
--============================================

AdvancedOptions["castermode"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_CASTER_MODE"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_CASTER_MODE_TOOLTIP"),
	category = "MISC",

	guiType = "checkbox",
	optionPath = "CHUD_CasterMode",
	optionType = "bool",
	default = false,

	immediateUpdate = function()

		for optionKey, option in pairs(AdvancedOptions) do

			if optionKey ~= "castermode" then

				if option.immediateUpdate then
					option.immediateUpdate()
				end
			end
		end
	end,
}

AdvancedOptions["alien_weaponslots"] =
{
	label = Locale.ResolveString("OPTION_ALIEN_WEAPONSLOTS"),
	tooltip = Locale.ResolveString("OPTION_ALIEN_WEAPONSLOTS_TOOLTIP"),
	category = "MISC",

	guiType = "dropdown",
	optionPath = "CHUD_AlienAbililitySelect",
	optionType = "int",
	default = 0,

	choices =
	{
		Locale.ResolveString("DEFAULT"),
		Locale.ResolveString("OPTION_ALIEN_WEAPONSLOTS_CHOICE_USEWEAPONSLOTS"),
	},

	immediateUpdate = function()

		if MainMenu_GetIsInGame() then

			Client.SendNetworkMessage("SetAlienWeaponUseHUDSlot",
			{
				slotMode = GetAdvancedOption("alien_weaponslots")
			}, true)

		end
	end,
}

AdvancedOptions["autopickup"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_WEAPON_AUTOPICKUP"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_WEAPON_AUTOPICKUP_TOOLTIP"),
	category = "MISC",

	guiType = "checkbox",
	optionPath = "CHUD_AutoPickup",
	optionType = "bool",
	default = true,

	hideValues = { false },

	immediateUpdate = function()

		if not kMainVM and Marine then

			Client.SendNetworkMessage("SetAutopickup",
			{
				autoPickup = GetAdvancedOption("autopickup"),
				autoPickupBetter = GetAdvancedOption("autopickupbetter")
			}, true)

		end
	end,
}

AdvancedOptions["autopickupbetter"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_WEAPON_AUTOPICKUP_BETTER"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_WEAPON_AUTOPICKUP_BETTER_TOOLTIP"),
	category = "MISC",

	guiType = "checkbox",
	optionPath = "CHUD_AutoPickupBetter",
	optionType = "bool",
	default = false,

	parent = "autopickup",

	immediateUpdate = function()

		if not kMainVM and Marine then

			Client.SendNetworkMessage("SetAutopickup",
			{
				autoPickup = GetAdvancedOption("autopickup"),
				autoPickupBetter = GetAdvancedOption("autopickupbetter")
			}, true)

		end
	end,
}

AdvancedOptions["marinecommselect"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_COMMANDER_MARINE_CLICK_SELECTION"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_COMMANDER_MARINE_CLICK_SELECTION_TOOLTIP"),
	category = "MISC",

	guiType = "checkbox",
	optionPath = "CHUD_MarineCommSelect",
	optionType = "bool",
	default = true,

	immediateUpdate = function()
		if not kMainVM and Commander then
			Commander.kMarineClickSelection = GetAdvancedOption("marinecommselect")
		end
	end,

	valueType = "bool",
}

AdvancedOptions["commqueue_playeronly"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_COMMANDER_PLAYERALERT_QUEUE") .. ": ",
	tooltip = Locale.ResolveString("ADVANCED_OPTION_COMMANDER_PLAYERALERT_QUEUE_TOOLTIP"),
	category = "MISC",

	guiType    = "dropdown",
	optionPath = "CHUD_CommQueuePlayerOnly",
	optionType = "bool",
	choices    =
	{
		Locale.ResolveString("ADVANCED_OPTION_COMMANDER_PLAYERALERT_QUEUE_CHOICE_ALLALERTS"),
		Locale.ResolveString("ADVANCED_OPTION_COMMANDER_PLAYERALERT_QUEUE_CHOICE_ONLYPLAYER"),
	},

	default = false,

	immediateUpdate = function()
		if not kMainVM and GUICommanderAlerts then
			GUICommanderAlerts.kOnlyPlayerAlerts = GetAdvancedOption("commqueue_playeronly")
		end
	end,
}

AdvancedOptions["researchtimetooltip"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_RESEARCH_TIME_TOOLTIP"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_RESEARCH_TIME_TOOLTIP_TOOLTIP"),
	category = "MISC",

	guiType = "checkbox",
	optionPath = "CHUD_ResearchTimeTooltip",
	optionType = "bool",
	default = false,

	immediateUpdate = function()
		if not kMainVM and GUIProduction then
			GUIProduction.kShowProgressTooltip = GetAdvancedOption("researchtimetooltip")
		end
	end,
}

AdvancedOptions["drawviewmodel"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_LABEL"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_LABEL_TOOLTIP"),
	category = "MISC",

	guiType = "dropdown",
	optionPath = "CHUD_DrawViewModel",
	optionType = "int",
	choices =
	{
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_DISPLAYALL"),
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_HIDEALL"),
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_CUSTOM")
	},

	default = 0,
	hideValues = { 0, 1 },

	immediateUpdate = function()
		if not kMainVM and ViewModelOption_Update and ClientUI then
			ViewModelOption_Update()
		end
	end,
}

AdvancedOptions["drawviewmodel_m"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_MARINE_LABEL"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_MARINE_TOOLTIP"),
	category = "MISC",

	guiType = "dropdown",
	optionPath = "CHUD_DrawViewModel_M",
	optionType = "bool",
	choices  =
	{
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_HIDE"),
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_DISPLAY"),
	},
	default = true,

	immediateUpdate = function()

		if not kMainVM and ViewModelOption_Update and ClientUI then
			ViewModelOption_Update()
		end

	end,

	parent = "drawviewmodel"
}

AdvancedOptions["drawviewmodel_exo"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_EXO_LABEL"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_EXO_TOOLTIP"),
	category = "MISC",

	guiType = "dropdown",
	optionPath = "CHUD_DrawViewModel_Exo",
	optionType = "bool",
	choices  =
	{
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_HIDE"),
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_DISPLAY"),
	},
	default = true,

	immediateUpdate = function()
		if not kMainVM and ViewModelOption_Update and ClientUI then
			ViewModelOption_Update()
		end
	end,

	parent = "drawviewmodel"
}

AdvancedOptions["drawviewmodel_a"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_ALIEN_LABEL"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_ALIEN_TOOLTIP"),
	category = "MISC",

	guiType = "dropdown",
	optionPath = "CHUD_DrawViewModel_A",
	optionType = "int",
	choices  =
	{
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_DISPLAYALL"),
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_HIDEALL"),
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_CUSTOM")
	},
	default = 0,
	hideValues = { 0, 1 },

	immediateUpdate = function()
		if not kMainVM and ViewModelOption_Update and ClientUI then
			ViewModelOption_Update()
		end
	end,

	parent = "drawviewmodel"
}

AdvancedOptions["drawviewmodel_skulk"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_SKULK_LABEL"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_SKULK_TOOLTIP"),
	category = "MISC",

	guiType = "dropdown",
	optionPath = "CHUD_DrawViewModel_Skulk",
	optionType = "bool",
	choices =
	{
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_HIDE"),
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_DISPLAY"),
	},
	default = true,

	immediateUpdate = function()
		if not kMainVM and ViewModelOption_Update and ClientUI then
			ViewModelOption_Update()
		end
	end,

	parent = "drawviewmodel_a"
}

AdvancedOptions["drawviewmodel_gorge"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_GORGE_LABEL"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_GORGE_TOOLTIP"),
	category = "MISC",

	guiType = "dropdown",
	optionPath = "CHUD_DrawViewModel_Gorge",
	optionType = "bool",
	choices =
	{
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_HIDE"),
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_DISPLAY"),
	},
	default = true,

	immediateUpdate = function()
		if not kMainVM and ViewModelOption_Update and ClientUI then
			ViewModelOption_Update()
		end
	end,

	parent = "drawviewmodel_a"
}

AdvancedOptions["drawviewmodel_lerk"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_LERK_LABEL"),
	tooltip =  Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_LERK_TOOLTIP"),
	category = "MISC",

	guiType = "dropdown",
	optionPath = "CHUD_DrawViewModel_Lerk",
	optionType = "bool",
	choices =
	{
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_HIDE"),
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_DISPLAY"),
	},
	default = true,

	immediateUpdate = function()
		if not kMainVM and ViewModelOption_Update and ClientUI then
			ViewModelOption_Update()
		end
	end,

	parent = "drawviewmodel_a"
}

AdvancedOptions["drawviewmodel_fade"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_FADE_LABEL"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_FADE_TOOLTIP"),
	category = "MISC",

	guiType = "dropdown",
	optionPath = "CHUD_DrawViewModel_Fade",
	optionType = "bool",
	choices =
	{
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_HIDE"),
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_DISPLAY"),
	},
	default = true,

	immediateUpdate = function()
		if not kMainVM and ViewModelOption_Update and ClientUI then
			ViewModelOption_Update()
		end
	end,

	parent = "drawviewmodel_a"
}

AdvancedOptions["drawviewmodel_onos"] =
{
	label = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_ONOS_LABEL"),
	tooltip = Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_ONOS_TOOLTIP"),
	category = "MISC",

	guiType = "dropdown",
	optionPath = "CHUD_DrawViewModel_Onos",
	optionType = "bool",
	choices =
	{
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_HIDE"),
		Locale.ResolveString("ADVANCED_OPTION_DRAW_VIEWMODEL_CHOICE_DISPLAY"),
	},
	default = true,

	immediateUpdate = function()
		if not kMainVM and ViewModelOption_Update and ClientUI then
			ViewModelOption_Update()
		end
	end,

	parent = "drawviewmodel_a"
}
