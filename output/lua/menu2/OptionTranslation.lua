-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/OptionTranslation.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Functions for handling option values being translated to their newer build counterparts.
--    Only upgrades, rollback of build version is not supported.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/UnorderedSet.lua")

local kDeleteObsoleteOptions = true
local kObsoleteVersionDiff = 2 -- How many versions past do we have to be to start deleting old options.

kOptionTranslations =
{
    {
        version = 339,
        translations =
        {
            -- Skin settings, changed because they were out of order in the UI
            { oldOptionPath = "skulkVariant",            type = "int", oldDefault = 1, values = { {2, 4}, {3, 2}, {4, 5}, {5, 3} } },
            { oldOptionPath = "gorgeVariant",            type = "int", oldDefault = 1, values = { {2, 4}, {3, 5}, {4, 6}, {5, 7}, {6, 3}, {7, 2} } },
            { oldOptionPath = "lerkVariant",             type = "int", oldDefault = 1, values = { {2, 4}, {3, 5}, {4, 6}, {5, 7}, {6, 3}, {7, 2} } },
            { oldOptionPath = "fadeVariant",             type = "int", oldDefault = 1, values = { {2, 5}, {3, 4}, {4, 6}, {5, 7}, {6, 2}, {7, 3} } },
            { oldOptionPath = "onosVariant",             type = "int", oldDefault = 1, values = { {2, 5}, {3, 6}, {5, 7}, {6, 3}, {7, 2} } },
            { oldOptionPath = "pistolVariant",           type = "int", oldDefault = 1, values = { {2, 4}, {3, 5}, {4, 3}, {5, 2} } },
            { oldOptionPath = "axeVariant",              type = "int", oldDefault = 1, values = { {2, 4}, {3, 5}, {4, 3}, {5, 2} } },
            { oldOptionPath = "shotgunVariant",          type = "int", oldDefault = 1, values = { {2, 3}, {3, 4}, {4, 5}, {5, 2} } },
            { oldOptionPath = "flamethrowerVariant",     type = "int", oldDefault = 1, values = { {2, 4}, {3, 5}, {4, 3}, {5, 2} } },
            { oldOptionPath = "grenadeLauncherVariant",  type = "int", oldDefault = 1, values = { {2, 5}, {5, 2} } },
            { oldOptionPath = "welderVariant",           type = "int", oldDefault = 1, values = { {2, 5}, {5, 2} } },
            { oldOptionPath = "hmgVariant",              type = "int", oldDefault = 1, values = { {2, 5}, {5, 2} } },
            { oldOptionPath = "marineStructuresVariant", type = "int", oldDefault = 1, values = { {2, 5}, {5, 2} } },
            { oldOptionPath = "alienStructuresVariant",  type = "int", oldDefault = 1, values = { {2, 7}, {3, 8}, {4, 2}, {5, 6}, {6, 5}, {7, 3}, {8, 4} } },
            { oldOptionPath = "alienTunnelsVariant",     type = "int", oldDefault = 1, values = { {2, 4}, {3, 7}, {4, 8}, {5, 2}, {7, 5}, {8, 3} } },

            --{ oldOptionPath = "CHUD_ReloadIndicator",    newOptionPath = "advanced/reload_indicator", type = "bool", oldDefault = false },
        }
    }
}

local function PrintOptionTranslated(translationVersion, oldPath, oldValue, translatedOptionPath, newValue, actionDesc)

    Print("\tv%s -> v%s+ : [%25s] = %15s -> [%25s] = %15s (%s)",
            translationVersion, translationVersion + 1,
            oldPath, string.format("'%s'", ToString(oldValue)), translatedOptionPath, string.format("'%s'", ToString(newValue)), actionDesc)

end

local function SortTranslationsByVerison(before, after)
    return before.version < after.version
end

table.sort(kOptionTranslations, SortTranslationsByVerison)

local kSettersByType
local kGettersByType

local kLastBuildVersion = GetLastBuildVersion()
local kCurrentBuildVersion = Shared.GetBuildNumber()

--- Processes the translation table to convert all old option key/values to their newest/current counterparts
function TranslateOptions()

    -- "color" type is saved as integers
    if not kSettersByType then
        kSettersByType =
        {
            int    = Client.SetOptionInteger,
            bool   = Client.SetOptionBoolean,
            float  = Client.SetOptionFloat,
            string = Client.SetOptionString,
        }
    end

    if not kGettersByType then
        kGettersByType =
        {
            int    = Client.GetOptionInteger,
            bool   = Client.GetOptionBoolean,
            float  = Client.GetOptionFloat,
            string = Client.GetOptionString,
        }
    end

    if kLastBuildVersion == kCurrentBuildVersion then
        return -- Same version, so no processing needed.
    end

    if kLastBuildVersion < kCurrentBuildVersion then -- Check for updates

        local startTime = Shared.GetSystemTimeReal()

        Print("== Translating Options ==")
        Print("\tLast Version: '%s', Current Version: '%s'", kLastBuildVersion, kCurrentBuildVersion)

        local translations = {}
        local obsoleteTranslations = {} -- Translations that are no longer used, to delete unused option paths for option file cleanup

        -- Get translations (in order) from old ver to current version
        for i = 1, #kOptionTranslations do
            local translationVer = kOptionTranslations[i].version
            if translationVer < kCurrentBuildVersion then

                if translationVer >= kLastBuildVersion then
                    table.insert(translations, kOptionTranslations[i])
                end

                if (kCurrentBuildVersion - translationVer) >= kObsoleteVersionDiff then
                    table.insert(obsoleteTranslations, kOptionTranslations[i])
                end

            end
        end

        -- Work through all related translations and apply them one by one.
        for i = 1, #translations do

            local translation   = translations[i]
            local translationVersion = translation.version
            local data = translation.translations

            if data then

                for iOption = 1, #data do

                    local option = data[iOption]
                    local isUpdatingKey = option.newOptionPath ~= nil
                    local isUpdatingValues = option.values ~= nil

                    local oldPath = SanitizePathStringForOptionName(option.oldOptionPath)

                    local setter = kSettersByType[option.type]
                    local getter = kGettersByType[option.type]

                    if isUpdatingKey or isUpdatingValues then

                        if isUpdatingValues then

                            local translatedOptionPath = isUpdatingKey and SanitizePathStringForOptionName(option.newOptionPath) or oldPath
                            local oldValue = getter(oldPath, option.oldDefault)
                            for i = 1, #option.values do

                                local values = option.values[i]
                                if oldValue == values[1] then -- Found a matching translation

                                    local actionDesc = isUpdatingKey and "Value & Key" or "Value"
                                    PrintOptionTranslated(translationVersion, oldPath, oldValue, translatedOptionPath, values[2], actionDesc)

                                    setter(translatedOptionPath, values[2])
                                    break -- Only one translation per option
                                end

                            end

                        else -- only updating key

                            local unchangedValue = getter(oldPath, option.oldDefault)

                            PrintOptionTranslated(translationVersion, oldPath, unchangedValue, option.newOptionPath, unchangedValue, "Key")

                            setter(option.newOptionPath, unchangedValue)
                        end

                    end -- sub data check

                end -- translation data loop (per option)

            end -- translation data check

        end -- translation iteration

        if kDeleteObsoleteOptions then

            -- Check obsolete translations for obsolete options for deletion
            for i = 1, #obsoleteTranslations do

                local translation = obsoleteTranslations[i]
                local options = translation.translations

                if options then

                    for j = 1, #options do

                        local option = options[j]
                        if option.newOptionPath then
                            Log("\tRemoving Old Option Path: '%s', New: '%s'", option.oldOptionPath, option.newOptionPath)
                            Client.RemoveOption(option.oldOptionPath)
                        end

                    end

                end

            end

        end -- Option deletion cleanup

        Client.SaveOptions() -- Save options right away

        Print("Option Translation took %s seconds", Shared.GetSystemTimeReal() - startTime)
        Print("=========================")

    end -- updating check

end

