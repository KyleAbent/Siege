-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/AdvancedMenuData.lua
--
-- Ported by: Darrell Gentry (darrell@naturalselection2.com)
--
-- Port of the NS2+ options gui factories. Now known as "Advanced" options.
-- Originally Created By: Juanjo Alfaro "Mendasp"
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/AdvancedOptions.lua")
Script.Load("lua/menu2/widgets/GUIMenuColorPickerWidget.lua") -- doesn't get loaded by vanilla menu

local kExpandableCounterparts =
{
	[OP_TT_ColorPicker] = OP_TT_Expandable_ColorPicker,
	[OP_TT_Choice]      = OP_TT_Expandable_Choice,
	[OP_TT_Checkbox]    = OP_TT_Expandable_Checkbox,
	[OP_TT_Number]      = OP_TT_Expandable_Number,
}

local function CreateAdvancedOptionPostInit_HideValues(optionParentName, optionParentTable, optionKey)

	assert(optionParentName)
	assert(optionParentTable)
	assert(optionKey ~= nil)

	assert(optionParentTable.optionType ~= nil)
	assert(optionParentTable.optionPath ~= nil)
	assert(optionParentTable.hideValues ~= nil)

	local parentHideValues = set(optionParentTable.hideValues)

	return function(self)

		local parentWidget = GetOptionsMenu():GetOptionWidget(optionParentName)

		local function GetShouldExpand()

			local parentExpanded = true
			if parentWidget.GetExpanded then
				parentExpanded = parentWidget:GetExpanded()
			end

			local currentValue = parentWidget:GetValue()
			local parentWantsToShow = not parentHideValues[currentValue]
			return parentWantsToShow and parentExpanded
		end

		self:SetExpanded(GetShouldExpand())

		self:HookEvent(parentWidget, "OnValueChanged",
				function(child, _)
					child:SetExpanded(GetShouldExpand())
				end)

		self:HookEvent(parentWidget, "OnExpandedChanged",
				function(child, value)
					child:SetExpanded(GetShouldExpand())
				end)

	end

end

local function CreateColorPickerEntry(option, optionKey)

	local entry =
	{
		name = optionKey,
		class = OP_TT_ColorPicker,
		params =
		{
			useResetButton = true,
			optionPath = option.optionPath,
			optionType = option.optionType,
			default = option.default,

			tooltip = option.tooltip,
			tooltipIcon = option.tooltipIcon,
			immediateUpdate = option.immediateUpdate
		},

		properties =
		{
			{"Label", option.label},
		}
	}

	return entry

end

local function CreateDropdownEntry(option, optionKey)

	local choices = {}
	if option.optionType == "bool" then

		choices =
		{
			{ value = false, displayString = option.choices[1] },
			{ value = true,  displayString = option.choices[2] },
		}

	else

		for i, v in ipairs(option.choices) do
			table.insert(choices, {value = i - 1, displayString = v})
		end
	end

	local entry =
	{
		name = optionKey,
		class = OP_TT_Choice,
		params =
		{
			useResetButton = true,
			optionPath = option.optionPath,
			optionType = option.optionType,
			default = option.default,

			tooltip = option.tooltip,
			tooltipIcon = option.tooltipIcon,
			immediateUpdate = option.immediateUpdate
		},

		properties =
		{
			{"Label", option.label},
			{"Choices", choices }
		}
	}

	return entry

end

local function CreateCheckboxEntry(option, optionKey)

	local entry =
	{
		name = optionKey,
		class = OP_TT_Checkbox,
		params =
		{
			useResetButton = true,
			optionPath = option.optionPath,
			optionType = option.optionType,
			default = option.default,

			tooltip = option.tooltip,
			tooltipIcon = option.tooltipIcon,
			immediateUpdate = option.immediateUpdate
		},

		properties =
		{
			{"Label", option.label},
		}
	}

	return entry

end

local function CreateSliderEntry(option, optionKey)

	local entry =
	{
		name = optionKey,
		class = OP_TT_Number,
		params =
		{
			useResetButton = true,
			optionPath = option.optionPath,
			optionType = option.optionType,
			default = option.default,

			minValue = option.minValue,
			maxValue = option.maxValue,
			decimalPlaces = option.decimalPlaces or 2,

			tooltip = option.tooltip,
			tooltipIcon = option.tooltipIcon,
			immediateUpdate = option.immediateUpdate
		},

		properties =
		{
			{"Label", option.label},
		}
	}

	return entry

end

local factories =
{
	dropdown = CreateDropdownEntry,
	checkbox = CreateCheckboxEntry,
	slider = CreateSliderEntry,
	colorPicker = CreateColorPickerEntry
}

-- Config is a GUIObject config.  postInit is either a function, or a list of functions.
-- config.postInit can be either nil, function, or list of functions.
-- Returns a copy of the config with the new postInit function(s) added.
local function AddPostInits(config, postInit)

	RequireType({"function", "table"}, postInit, "postInit", 2)

	if type(postInit) == "table" then
		assert(#postInit > 0)
	end

	-- Input table doesn't have postInit field, simple assignment.
	if config.postInit == nil then
		config.postInit = postInit
		return config
	end

	local newPostInit = {}
	-- Ensure result.postInit is a table, so we can hold multiple postInit functions.
	if type(config.postInit) == "function" then
		table.insert(newPostInit, config.postInit)
	else
		newPostInit = config.postInit
	end

	if type(postInit) == "function" then
		table.insert(newPostInit, postInit)
	else
		-- Append the postInit list to the result.postInit list.
		for i = 1, #postInit do
			table.insert(newPostInit, postInit[i])
		end
	end

	config.postInit = newPostInit

	return config

end

local function ResetOptionValue(option)

	local default = option.default

	if option:isa("GUIMenuColorPickerWidget") then
		default = ColorIntToColor(default)
	end

	option:SetValue(default)

end

local GUIListLayout_Expandable = GetMultiWrappedClass(GUIListLayout, {"Expandable"})

local function AddAdvancedOptionSharedPostInits(config, optionParentName, optionKey)

	local parentOptionTbl
	local result = config

	if optionParentName then

		parentOptionTbl = AdvancedOptions[optionParentName]
		assert(parentOptionTbl) -- option.parent must be the name of an advanced option.

	end

	-- If the option has a parent set, then we need to wrap it in an expandable list so
	-- we can handle the hiding/showing of child options.
	if parentOptionTbl then

		assert(kExpandableCounterparts[config.class])

		result = config
		config.class = kExpandableCounterparts[config.class]

		AddPostInits(result, CreateAdvancedOptionPostInit_HideValues(optionParentName, parentOptionTbl, optionKey))
		result.params.expansionMargin = 4.0
	end

	return result
end

local function ResetAllOptions()

	local optionMenu = GetOptionsMenu()
	assert(optionMenu)

	for optionName, _ in pairs(AdvancedOptions) do

		local widget = optionMenu:GetOptionWidget(optionName)
		assert(widget)

		ResetOptionValue(widget)
	end

end

local function ResetPopup()

	local popupConfig =
	{
		title = Locale.ResolveString("ADVANCED_OPTION_RESET_POPUP_TITLE"),
		message = Locale.ResolveString("ADVANCED_OPTION_RESET_POPUP_MESSAGE"),
		buttonConfig =
		{
			-- Confirm.
			{
				name = "CHUD_confirmReset",
				params =
				{
					label = Locale.ResolveString("ADVANCED_OPTION_RESET_POPUP_BUTTON_RESET"),
				},

				callback = function(popup)

					popup:Close()
					ResetAllOptions()

				end,
			},

			-- Cancel Button.
			GUIPopupDialog.CancelButton,
		},
	}

	-- GUIMenuPopupSimpleMessage destroys itself when closed (from GUIPopupDialog).
	CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil, popupConfig)

end

function CreateAdvancedOptionMenuEntry(option, optionKey)

	local factory = factories[option.guiType]
	if not factory then
		Print("Advanced option entry %s has unsupported gui type! (%s)", optionKey, option.guiType)
		return
	end

	local result = factory(option, optionKey)
	result = AddAdvancedOptionSharedPostInits(result, option.parent, optionKey)
	return result

end

local function GetAdvancedOptionCategory(categoryName, label, contentsTable)

	local category =
	{
		categoryName = categoryName,
		entryConfig =
		{
			name = string.format("%sAdvancedOptionsEntry", categoryName),
			class = GUIMenuCategoryDisplayBoxEntry,
			params =
			{
				label = label,
				height = 101
			},
		},

		contentsConfig = ModsMenuUtils.CreateBasicModsMenuContents
		{
			layoutName = "advancedOptions",
			contents = contentsTable,
		}
	}

	return category

end

local advancedOptionsCategoryLocale =
{
	UI = "ADVANCED_CATEGORY_UI",
	HUD = "ADVANCED_CATEGORY_HUD",
	DAMAGE = "ADVANCED_CATEGORY_DAMAGE",
	MAP = "ADVANCED_CATEGORY_MAP",
	STATS = "ADVANCED_CATEGORY_STATS",
	GRAPHICS = "ADVANCED_CATEGORY_GRAPHICS",
	CROSSHAIR = "ADVANCED_CATEGORY_CROSSHAIR",
	MISC = "ADVANCED_CATEGORY_MISC",
}

function CreateAdvancedOptionsMenu()

	-- This guarantees that categories will show up in a pre-determined order.
	local optionsByCategory = OrderedIterableDict()
	optionsByCategory["UI"] = {}
	optionsByCategory["HUD"] = {}
	optionsByCategory["DAMAGE"] = {}
	optionsByCategory["MAP"] = {}
	optionsByCategory["STATS"] = {}
	optionsByCategory["GRAPHICS"] = {}
	optionsByCategory["CROSSHAIR"] = {}
	optionsByCategory["MISC"] = {}

	-- Go through each option in AdvancedOptions and create a GUIObject config from it, then throw it in it's own category table.
	for optionKey, optionTable in pairs(AdvancedOptions) do

		local category = optionTable.category
		local entry = CreateAdvancedOptionMenuEntry(optionTable, optionKey)

		if entry then

			if not optionsByCategory[category] then
				Print("Warning: Adding new category, locale is unlikely. %s", category)
				optionsByCategory[category] = {}
			end

			table.insert(optionsByCategory[category], entry)
		end

	end

	-- Add in a button to reset all advanced options in the MISC category.
	local resetAllButtonConfig =
	{
		name = "resetAllAdvancedOptionsButton",
		class = GUIMenuButton,

		properties =
		{
			{"Label", Locale.ResolveString("ADVANCED_OPTION_RESET_ADVANCED_OPTIONS")}
		},

		postInit =
		{
			function(self)
				self:HookEvent(self, "OnPressed", ResetPopup)
			end
		}
	}
	table.insert(optionsByCategory["MISC"], resetAllButtonConfig)

	-- Now that we have all our options categorized, create the GUIObject configs for each category and throw them in a table.
	for k, v in pairs(optionsByCategory) do

		local optionCategory = k
		local categoryOptions = v

		if #categoryOptions > 0 then

			local categoryLocaleName = Locale.ResolveString(advancedOptionsCategoryLocale[optionCategory] or optionCategory)

			local entry = GetAdvancedOptionCategory(optionCategory, categoryLocaleName, categoryOptions)
			table.insert(gAdvancedSettingsCategories, entry)

		else

			Print("Warning: Skipping empty category. (%s)", optionCategory)

		end


	end

end

do
	CreateAdvancedOptionsMenu()
end