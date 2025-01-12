-- ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
--
-- lua\ServerConfig.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http:\\www.unknownworlds.com =====================

Script.Load("lua/Seasons.lua")
Script.Load("lua/ConfigFileUtility.lua")

-- How often to update key/value pairs on the server.
local kKeyValueUpdateRate = 5

-- The last time key value pairs were updated.
local lastKeyValueUpdateTime = 0

local configFileName = "ServerConfig.json"

local defaultConfig = {
                        settings =
                            {
                                rookie_only = false,
                                rookie_only_bots = 12,
                                filler_bots = 12,
                                force_even_teams_on_join = true,
                                auto_team_balance = {
                                    enabled = true,
                                    enabled_on_unbalance_amount = 2,
                                    enabled_after_seconds = 10
                                },
                                end_round_on_team_unbalance = 0.4,
                                end_round_on_team_unbalance_check_after_time = 300,
                                end_round_on_team_unbalance_after_warning_time = 30,
                                auto_kick_afk_time = 300,
                                voting = { 
                                    votekickplayer = true,
                                    votekick_bantime = 2,
                                    votechangemap = true, 
                                    voteresetgame = true, 
                                    voterandomizerr = true, 
                                    votingforceeventeams = true,
                                    voteaddcommanderbots = true
                                },
                                auto_vote_add_commander_bots = true,
                                alltalk = false,
                                pregamealltalk = false,
                                hiveranking = true,
                                use_own_consistency_config = false,
                                consistency_enabled = true,
                                jit_maxmcode=35000,
                                jit_maxtrace=20000,
                                mod_backup_servers = {},
                                mod_backup_before_steam = false,
                                dyndns = "",
                                enabledyndns = false,
                                quickplay_ready = true,
                                season = "",
                                season_month = 0,
                                max_http_requests = 8,
                            },
                        tags = { "" }
                      }

local config = LoadConfigFile(configFileName, defaultConfig, true)
Server.SetModBackupServers(config.settings.mod_backup_servers, config.settings.mod_backup_before_steam)

--Auto Seasons
do
    SetServerSeason(config.settings.season, config.season_month)

    if config.settings.quickplay_ready == false then
        Shared.Message("Tagged server as unavailable for quick play as set by the server config.")
        Server.DisableQuickPlay()
    end
    
    if not Server.SetMaxHttpRequestsLimit(config.settings.max_http_requests) then
        Log("Failed to set HTTP requests limit, using default value of 8. Verify value is in range of [0 - 20]")
    end
end


--[[
    The reserved slot system allows players marked as reserved players to join while
    all non-reserved slots are taken and the server is not full.

    Also we check if a player is banned here.
]]

local reservedSlotsConfigFileName = "ReservedSlotsConfig.json"
local reservedSlotsDefaultConfig = { 
    amount = 0, 
    ids = { } -- [name] = userid entries
}
local reservedSlotsConfig = LoadConfigFile(reservedSlotsConfigFileName, reservedSlotsDefaultConfig)

local reservedSlotIds = {}

local function LoadReservedSlotIds(config)
    reservedSlotIds = {}

    for _, id in pairs(reservedSlotsConfig.ids) do
        reservedSlotIds[id] = true
    end
end

do
    LoadReservedSlotIds(reservedSlotsConfig)
end

function GetHasReservedSlotAccess(userId)
    return reservedSlotIds[userId]
end

function Server.GetReservedSlotsConfig()
    return reservedSlotsConfig
end

function Server.SaveReservedSlotsConfig()
    LoadReservedSlotIds(reservedSlotsConfig)

    SaveConfigFile(reservedSlotsConfigFileName, reservedSlotsConfig)
end

function Server.GetConfigSetting(name)

    if config.settings then
        return config.settings[name]
    end

end

local kServerIp = IPAddressToString(Server.GetIpAddress())
--Returns the server's ip address or dns as string
function Server.GetIpAddress()
    return kServerIp
end

function Server.GetHasTag(tag)

    for i = 1, #config.tags do
        if config.tags[i] == tag then
            return true
        end
    end

    return false

end

function Server.GetIsRookieFriendly()
    return Server.GetHasTag("rookie")
end

--[[
 * This can be used to override a setting. This will
 * not be saved to the config setting.
]]
function Server.SetConfigSetting(name, setting)
    config.settings[name] = setting
end

function Server.SaveConfigSettings()
    SaveConfigFile(configFileName, config)
end

--[[
 * This function should be called once per tick. It will update continuous data
]]
local function UpdateServerConfig()

    if Shared.GetSystemTime() - lastKeyValueUpdateTime >= kKeyValueUpdateRate then

        -- This isn't used by the server browser, but it is used by stats monitoring systems    
        Server.SetKeyValue("tickrate", ToString(math.floor(Server.GetFrameRate())))
        Server.SetKeyValue("ent_count", ToString(Shared.GetEntitiesWithClassname("Entity"):GetSize()))
        lastKeyValueUpdateTime = Shared.GetSystemTime()
             
    end
    
end


Event.Hook("UpdateServer", UpdateServerConfig)

DisabledClientOptions = {}

AdvancedServerOptions = IterableDict()

AdvancedServerOptions["allow_mapparticles"] =
{
    label   = "Map particles",
    tooltip = "Enables or disables the ability to disable the map particles for clients.",
    valueType = "bool",
    defaultValue = true,
}

AdvancedServerOptions["allow_deathstats"] =
{
    label   = "NS2+ personal stats",
    tooltip = "Enables or disables the display of stats when players die.",
    valueType = "bool",
    defaultValue = true,
}

-- TODO(Salads): This sounds like it should be a client option...
AdvancedServerOptions["autodisplayendstats"] =
{
    label   = "End game stats autodisplay",
    tooltip = "Enables or disables the end game stats displaying automatically upon game end.",
    valueType = "bool",
    defaultValue = true,
}

AdvancedServerOptions["endstatsteambreakdown"] =
{
    label   = "End game stats team breakdown",
    tooltip = "Enables or disables the end game stats displaying the full team breakdown.",
    valueType = "bool",
    defaultValue = true,
}

AdvancedServerOptions["savestats"] =
{
    label   = "Save round stats",
    tooltip = "Saves the last round stats in the NS2Plus\\Stats\\ folder in your config path in json format. Each round played will be saved in a separate file. The file name for each round is the epoch time at round end.",
    valueType = "bool",
    defaultValue = true,
}

local function SaveAdvancedServerConfig()
    local saveConfig = { }

    for index, option in pairs(AdvancedServerOptions) do
        saveConfig[index] = option.currentValue
    end

    SaveConfigFile(configFileName, saveConfig)
end

function SetAdvancedServerOption(key, value)
    local setValue

    if AdvancedServerOptions[key] ~= nil then

        local option = AdvancedServerOptions[key]
        local oldValue = option.currentValue

        if option.valueType == "bool" then
            if value == "true" or value == "1" or value == true then
                option.currentValue = true
                setValue = option.currentValue
            elseif value == "false" or value == "0" or value == false then
                option.currentValue = false
                setValue = option.currentValue
            end

        elseif option.valueType == "float" then
            local number = tonumber(value)
            if IsNumber(number) and number >= option.minValue and number <= option.maxValue then
                option.currentValue = number
                setValue = option.currentValue
            end
        end

        -- Don't waste time saving settings we already have set like that
        if oldValue ~= option.currentValue then
            SaveAdvancedServerConfig()
        end

    end

    return setValue
end

local configFileName = "NS2PlusServerConfig.json"
local defaultNS2PlusServerConfig = {}
for index, option in pairs(AdvancedServerOptions) do
    defaultNS2PlusServerConfig[index] = option.defaultValue
end

local config = LoadConfigFile(configFileName, defaultNS2PlusServerConfig, true)

-- Load all of the options into our ServerOptions table.
for option, value in pairs(config) do

    -- Make sure the option exists in our table
    if AdvancedServerOptions[option] then

        AdvancedServerOptions[option].currentValue = value
        local setValue = SetAdvancedServerOption(option, value)

        if setValue == nil and AdvancedServerOptions[option] then
            SetAdvancedServerOption(option, AdvancedServerOptions[option].defaultValue)
        end
    end
end

-- Add blocked options to a table so when clients connect we can send them a command to do so
for index, option in pairs(AdvancedServerOptions) do

    if option.currentValue == nil then
        SetAdvancedServerOption(index, AdvancedServerOptions[index].defaultValue)
    end

    local _, pos = string.find(index, "allow_")
    if pos and AdvancedServerOptions[index].currentValue == false then

        local optionName = string.sub(index, pos + 1)
        table.insert(DisabledClientOptions, optionName)

    end
end

local function SendDisabledSettings(client)

    if client and not client:GetIsVirtual() and #DisabledClientOptions > 0 then
        for _, option in ipairs(DisabledClientOptions) do

            Server.SendNetworkMessage(client, "DisabledOption",
            {
                disabledOption = option

            }, true)

        end
    end
end

Event.Hook("ClientConnect", SendDisabledSettings)

