-- ======= Copyright (c) 2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\SharedCommands_Client.lua
--
--    Created by: Thomas Fransham
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local function SetMaxDownloadAttemps(attemps)
    attemps = tonumber(attemps)
    assert(attemps, "Max attemps value must be provided")
    ModServices.SetMaxSteamDownloadAttemps(1)
end

local function SetDownloadTimeout(timeout)
    timeout = tonumber(timeout)
    assert(timeout, "Download timeout value must be provided")
    ModServices.SetSteamDownloadTimout(timeout)
end

local function SetRequestTimeout(timeout)
    timeout = tonumber(timeout)
    assert(timeout, "Request timeout value must be provided")
    ModServices.SetModRequestTimeout(timeout)
end

local function CreateServerConsoleCommand(name, func)
    local wrapper = function (client, ...)
        if client == nil then
            func(...)
        end
    end

    Event.Hook("Console_"..name, wrapper)
end

local consoleCommands = {
    mod_maxdownloadattemps = SetMaxDownloadAttemps,
    mod_downloadtimeout = SetDownloadTimeout,
    mod_requesttimeout = SetRequestTimeout,
}

if Server then
    for name, f in pairs(consoleCommands) do
        CreateServerConsoleCommand(name, f)
    end
else
    for name, f in pairs(consoleCommands) do
        Event.Hook("Console_"..name, f)
    end
end
