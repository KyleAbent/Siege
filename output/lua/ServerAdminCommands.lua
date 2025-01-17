-- ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
--
-- lua\ServerAdminCommands.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- Console commands to be used in ServerAdmin.lua system.
-- NOTE: Commands added here should also be added to web/js/rcon.js to the list of auto-complete commands
--
-- ========= For more information, visit us at http:\\www.unknownworlds.com =======================
Script.Load("lua/ConfigFileUtility.lua")

function GetReadableSteamId(steamIdNumber)
    return "STEAM_0:" .. (steamIdNumber % 2) .. ":" .. math.floor(steamIdNumber / 2)
end

local function GetPlayerList()

    local playerList = EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
    table.sort(playerList, function(p1, p2) return p1:GetName() < p2:GetName() end)
    return playerList
    
end

--[[
 * Iterates over all players sorted in alphabetically calling the passed in function.
]]
local function AllPlayers(doThis)

    return function(client)
    
        local playerList = GetPlayerList()
        for p = 1, #playerList do
        
            local player = playerList[p]
            doThis(player, client, p)
            
        end
        
    end
    
end

local function GetPlayerMatchingSteamId(steamId)

    local match
    
    local function Matches(player)
    
        local playerClient = Server.GetOwner(player)
        if playerClient and (playerClient:GetUserId() == tonumber(steamId) or GetReadableSteamId(playerClient:GetUserId()) == steamId) then
            match = player
        end
        
    end
    AllPlayers(Matches)()
    
    return match
    
end

local function GetPlayerMatchingName(name)

    local match
    
    local function Matches(player)
    
        if player:GetName() == name then
            match = player
        end
        
    end
    AllPlayers(Matches)()
    
    return match
    
end

local function GetPlayerMatching(id)
    return GetPlayerMatchingSteamId(id) or GetPlayerMatchingName(id)
end

--[[
local function TournamentMode(client, enabled)
    if enabled == "true" or enabled == "1" then        
        EnableTournamentMode(client)
    elseif enabled == "false" or enabled == "0" then
        DisableTournamentMode(client)
    end
end
CreateServerAdminCommand("Console_sv_tournament", TournamentMode, "<true/false>, Enables or disabled tournament mode.")
--]]

local function PrintStatus(player, client, index)

    local playerClient = Server.GetOwner(player)
    -- The player may not have an owner. Ragdoll player entities for example.
    if playerClient then
    
        local playerId = playerClient:GetUserId()
        ServerAdminPrint(client, player:GetName() .. " : Steam Id = " .. playerId .. " : " .. GetReadableSteamId(playerId))
        
    end
    
end
CreateServerAdminCommand("Console_sv_status", AllPlayers(PrintStatus), "Lists player Ids and names for use in sv commands", true)

local function PrintStatusIP(player, client, index)

    local playerClient = Server.GetOwner(player)
    -- The player may not have an owner. Ragdoll player entities for example.
    if playerClient then
    
        local playerAddressString = IPAddressToString(Server.GetClientAddress(playerClient))
        local playerId = playerClient:GetUserId()
        ServerAdminPrint(client, player:GetName() .. " : Steam Id = " .. playerId .. " : " .. GetReadableSteamId(playerId) .. " : Address = " .. playerAddressString)
        
    end
    
end
CreateServerAdminCommand("Console_sv_statusip", AllPlayers(PrintStatusIP), "Lists player Ids and names for use in sv commands")

CreateServerAdminCommand("Console_sv_changemap", function(_, mapName) MapCycle_ChangeMap( mapName ) end, "<map name>, Switches to the map specified")
CreateServerAdminCommand("Console_sv_reset", function() GetGamerules():ResetGame() end, "Resets the game round")

CreateServerAdminCommand("Console_sv_rrall", AllPlayers(function(player) GetGamerules():JoinTeam(player, kTeamReadyRoom) end), "Forces all players to go to the Ready Room")
CreateServerAdminCommand("Console_sv_randomall", AllPlayers(function(player) JoinRandomTeam(player) end), "Forces all players to join a random team")
CreateServerAdminCommand("Console_sv_forceeventeams", function() ForceEvenTeams() end, "Balances teams based on previous round and Hive skill")



local function SwitchTeam(client, playerId, team)

    local player = GetPlayerMatching(playerId)
    local teamNumber = tonumber(team)
    
    if type(teamNumber) ~= "number" or teamNumber < 0 or teamNumber > 4 then
    
        ServerAdminPrint(client, "Invalid team number")
        return
        
    end
    
    if player and teamNumber ~= player:GetTeamNumber() then
        GetGamerules():JoinTeam(player, teamNumber)
    elseif not player then
        ServerAdminPrint(client, "No player matches Id: " .. playerId)
    end
    
end
CreateServerAdminCommand("Console_sv_switchteam", SwitchTeam, "<player id> <team number>, 0 is Ready Room, 1 is Marines, 2 is Aliens, 3 is Spectate")

local function Eject(client, playerId)

    local player = GetPlayerMatching(playerId)
    if player and player:isa("Commander") then
        player:Eject()
    else
        ServerAdminPrint(client, "Invalid player")
    end
    
end
CreateServerAdminCommand("Console_sv_eject", Eject, "<player id>, Ejects Commander from the Command Structure")

local function Kick(client, playerId, ...)

    local player = GetPlayerMatching(playerId)
    if player then
        local reason = StringTrim(StringConcatArgs(...) or "")
        Server.DisconnectClient(Server.GetOwner(player), reason )
    else
        ServerAdminPrint(client, "No matching player")
    end
    
end
CreateServerAdminCommand("Console_sv_kick", Kick, "<player id>, Kicks the player from the server")

local function GetChatMessage(...)

    local chatMessage = StringConcatArgs(...)
    if chatMessage then
        return string.UTF8Sub(chatMessage, 1, kMaxChatLength)
    end
    
    return ""
    
end

local function Say(client, ...)

    local chatMessage = GetChatMessage(...)
    if string.len(chatMessage) > 0 then
    
        Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
        Shared.Message("Chat All - Admin: " .. chatMessage)
        Server.AddChatToHistory(chatMessage, "Admin", 0, kTeamReadyRoom, false)
        
    end
    
end
CreateServerAdminCommand("Console_sv_say", Say, "<message>, Sends a message to every player on the server")

local function TeamSay(client, team, ...)

    local teamNumber = tonumber(team)
    if type(teamNumber) ~= "number" or teamNumber < 0 or teamNumber > 3 then
    
        ServerAdminPrint(client, "Invalid team number")
        return
        
    end
    
    local chatMessage = GetChatMessage(...)
    if string.len(chatMessage) > 0 then
    
        local players = GetEntitiesForTeam("Player", teamNumber)
        for index, player in ipairs(players) do
            Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "Team - Admin", -1, teamNumber, kNeutralTeamType, chatMessage), true)
        end
        
        Shared.Message("Chat Team - Admin: " .. chatMessage)
        Server.AddChatToHistory(chatMessage, "Admin", 0, teamNumber, true)
        
    end
    
end
CreateServerAdminCommand("Console_sv_tsay", TeamSay, "<team number> <message>, Sends a message to one team")

local function PlayerSay(client, playerId, ...)

    local chatMessage = GetChatMessage(...)
    local player = GetPlayerMatching(playerId)
    
    if player then
    
        chatMessage = string.UTF8Sub(chatMessage, 1, kMaxChatLength)
        if string.len(chatMessage) > 0 then
        
            Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "PM - Admin", -1, teamNumber, kNeutralTeamType, chatMessage), true)
            Shared.Message("Chat Player - Admin: " .. chatMessage)
            
        end
        
    else
        ServerAdminPrint(client, "No matching player")
    end
    
end
CreateServerAdminCommand("Console_sv_psay", PlayerSay, "<player id> <message>, Sends a message to a single player")

local function Slay(client, playerId)

    local player = GetPlayerMatching(playerId)
    
    if player then
         player:Kill(nil, nil, player:GetOrigin())
    else
        ServerAdminPrint(client, "No matching player")
    end
    
end
CreateServerAdminCommand("Console_sv_slay", Slay, "<player id>, Kills player")

local function SetMaxBots(client, newMax, com)

    newMax = tonumber(newMax)
    com = com and string.ToBoolean(com)

    if newMax < 0 then
        ServerAdminPrint(client, "The max value has to be greater or equal to 0!")
        return
    end

    local gamerules = GetGamerules()
    if not gamerules then return end

    if not gamerules.SetMaxBots then
        ServerAdminPrint(client, "The current gamemode does not support dynamically bots!")
        return
    end

    gamerules:SetMaxBots(newMax,com)
end
CreateServerAdminCommand("Console_sv_maxbots", SetMaxBots, "<max>, The server will add the max amount of bots dynamically to the teams")

local function SetPassword(client, newPassword)
    Server.SetPassword(newPassword or "")
end
CreateServerAdminCommand("Console_sv_password", SetPassword, "<string>, Changes the password on the server")

local function SetCheats(client, enabled)
    Shared.ConsoleCommand("cheats " .. ((enabled == "true" or enabled == "1") and "1" or "0"))
end
CreateServerAdminCommand("Console_sv_cheats", SetCheats, "<boolean>, Turns cheats on and off")

local function SetTests(client, enabled)
    Shared.ConsoleCommand("tests " .. ((enabled == "true" or enabled == "1") and "1" or "0"))
end
CreateServerAdminCommand("Console_sv_tests", SetTests, "<boolean>, Turns tests mode on and off. Grants access to commands such as nav_debug, and collision.")

local bannedPlayersFileName = "BannedPlayers.json"
local bannedPlayers = LoadConfigFile(bannedPlayersFileName) or { }

local bannedPlayersMap = {}
local function GenerateBannedPlayersMap()
    for i, ban in ipairs(bannedPlayers) do
        local id = ban.id
        ban.index = i
        bannedPlayersMap[id] = ban
    end
end

local function RemoveExpiredBans()
    local now = Shared.GetSystemTime()
    for i = #bannedPlayers, 1, -1 do
        local ban = bannedPlayers[i]
        if ban.time > 0 and now >= ban.time then
            table.remove(bannedPlayers, i)
        end
    end
end

do
    RemoveExpiredBans()
    GenerateBannedPlayersMap()
end

local function SaveBannedPlayers()
    RemoveExpiredBans()
    GenerateBannedPlayersMap()

    SaveConfigFile(bannedPlayersFileName, bannedPlayers)
end

function UnbanUser(userId)
    local ban = bannedPlayersMap[userId]
    if not ban then return false end

    table.remove(bannedPlayers, ban.index)
    SaveBannedPlayers()

    return true
end

--[[
    Returns if the user with the given userId is banned
]]
function GetIsUserBanned(userId)
    local ban = bannedPlayersMap[userId]
    if not ban then return false end

    local now = Shared.GetSystemTime()
    if ban.time == 0 or now < ban.time then
        return true
    end

    return false -- ban expired, will be removed next time the banned players config gets loaded or saved
end

--[[
    Returns if the user with the given userId is banned permanently
]]
function GetIsUserBannedPermanently(userId)
    local ban = bannedPlayersMap[userId]
    if not ban then return false end

    return ban.time == 0
end

-- Flag clients as spectators during thec connection allowe check
local spectorIds = {}

local function OnCheckConnectionAllowed(userId)

    --check if the user is banned
    if GetIsUserBanned(userId) then
        Shared.Message("Rejected connection to banned client %s", userId)
        return false, GetIsUserBannedPermanently(userId) and "You are permanently banned." or "You are temporarily banned."
    end

    local numClients = Server.GetNumClientsTotal() - 1 -- NumTotal includes the player we are just checking right now
    local maxPlayers = Server.GetMaxPlayers()
    local maxSpectators = Server.GetMaxSpectators()
    local maxClients = maxPlayers + maxSpectators

    if numClients >= maxClients then
        Shared.Message("Rejected connection to client %s as there is no client slot available.", userId)
        return false, "Server is currently full."
    end

    local numSpectator = Server.GetNumSpectators()
    local numPlayers = numClients - numSpectator

    -- Check for spectator count overflow issue
    if numPlayers < 0 then
        Shared.Message("Warning: Spectator count overflow detected!")
        numPlayers = numClients
    end

    local numRes = Server.GetReservedSlotLimit()
    -- Check for free player slots
    if numPlayers < (maxPlayers - numRes) then
        return true
    end

    -- Check for free reserved slots
    if GetHasReservedSlotAccess(userId) and numPlayers < maxPlayers then
        return true
    end

    -- Check for free spectator slots
    if numSpectator < maxSpectators then
        spectorIds[userId] = true
        return true
    end

    Shared.Message("Rejected connection to client %s as there is no free slot available.", userId)
    return false, "Server is currently full."

end
Event.Hook("CheckConnectionAllowed", OnCheckConnectionAllowed)

local function OnCheckConnectionIsSpectator(userId)
    if not spectorIds[userId] then return false end

    spectorIds[userId] = nil
    return true
end
Event.Hook("CheckConnectionIsSpectator", OnCheckConnectionIsSpectator)

--[[
 * Duration is specified in minutes. Pass in 0 or nil to ban forever.
 * A reason string may optionally be provided.
]]
local function Ban(client, playerId, duration, ...)

    local player = GetPlayerMatching(playerId)
    local bannedUntilTime = Shared.GetSystemTime()
    duration = tonumber(duration)
    if duration == nil or duration <= 0 then
        bannedUntilTime = 0
    else
        bannedUntilTime = bannedUntilTime + (duration * 60)
    end
    
    local playerIdNum = tonumber(playerId)
    if player then
        
        local reason = StringTrim(StringConcatArgs(...))
        
        table.insert(bannedPlayers, { name = player:GetName(), id = Server.GetOwner(player):GetUserId(), reason = reason, time = bannedUntilTime })
        SaveBannedPlayers()
        ServerAdminPrint(client, player:GetName() .. " has been banned")
        
        if reason ~= "" then
            Server.DisconnectClient(Server.GetOwner(player), reason)
        elseif bannedUntilTime ~= 0 then
            Server.DisconnectClient(Server.GetOwner(player), "You have been temporarily banned from this server.")
        else
            Server.DisconnectClient(Server.GetOwner(player), "You have been banned from this server.") 
        end
        
        
    elseif playerIdNum and playerIdNum > 0 then
    
        table.insert(bannedPlayers, { name = "Unknown", id = playerIdNum, reason = StringConcatArgs(...) or "None provided", time = bannedUntilTime })
        SaveBannedPlayers()
        ServerAdminPrint(client, "Player with SteamId " .. playerIdNum .. " has been banned")
        
    else
        ServerAdminPrint(client, "No matching player")
    end
    
end
CreateServerAdminCommand("Console_sv_ban", Ban, "<player id> <duration in minutes> <reason text>, Bans the player from the server, pass in 0 for duration to ban forever")

local function UnBan(client, steamId)
    if not steamId then
    
        ServerAdminPrint(client, "No Id passed into sv_unban")
        return
        
    end
    
    local unbanned = UnbanUser(steamId)
    
    if not unbanned then
        ServerAdminPrint(client, "No matching Steam Id in ban list: " .. steamId)
    end
    
end
CreateServerAdminCommand("Console_sv_unban", UnBan, "<steam id>, Removes the player matching the passed in Steam Id from the ban list")

function GetBannedPlayersList()

    local returnList = { }
    
    for p = 1, #bannedPlayers do
    
        local ban = bannedPlayers[p]
        table.insert(returnList, { name = ban.name, id = ban.id, reason = ban.reason, time = ban.time })
        
    end
    
    return returnList
    
end

local function ListBans(client)

    if #bannedPlayers == 0 then
        ServerAdminPrint(client, "No players are currently banned")
    end

    local now = Shared.GetSystemTime()
    for p = 1, #bannedPlayers do
    
        local ban = bannedPlayers[p]
        local timeLeft = ban.time == 0 and "Forever" or (ban.time - now) / 60 .. " minutes"
        ServerAdminPrint(client, "Name: " .. ban.name .. " Id: " .. ban.id .. " Time Remaining: " .. timeLeft .. " Reason: " .. (ban.reason or "Not provided"))
        
    end
    
end
CreateServerAdminCommand("Console_sv_listbans", ListBans, "Lists the banned players")

local function ChangeRookieOnly(client, value)

    local currentstate = Server.GetConfigSetting("rookie_only") or false
    local newState = value and string.ToBoolean(value) or not currentstate
    local Gamerules = GetGamerules()

    if not Gamerules then
        ServerAdminPrint(client, "Couldn't find NS2Gamerules, aborting command!")
        return
    end

    --Set rookie mode based on the config values
    Gamerules:SetRookieMode(newState)
    if Gamerules.gameInfo:GetRookieMode() then
        Gamerules:SetMaxBots(Server.GetConfigSetting("rookie_only_bots"), true)
    else
        Gamerules:SetMaxBots(Server.GetConfigSetting("filler_bots"), false)
    end

    Server.SaveConfigSettings()
    Server.SetConfigSetting("rookie_only", newState)

    ServerAdminPrint(client, string.format("Rookie Only is now %s", newState and "enabled" or "disabled"))
    
end
CreateServerAdminCommand("Console_sv_rookieonly", ChangeRookieOnly, "[<true/false>] Toggles rookie_only and changes the server setting")

local function ChangePregameAlltalk(client, value)

    local currentstate = Server.GetConfigSetting("pregamealltalk") or false
    local newState = value and string.ToBoolean(value) or not currentstate

    Server.SetConfigSetting("pregamealltalk", newState)
    Server.SaveConfigSettings()
    ServerAdminPrint(client, string.format("Pregamealltalk is now %s", newState and "enabled" or "disabled"))

end
CreateServerAdminCommand("Console_sv_pregamealltalk", ChangePregameAlltalk, "[<true/false>] Toggles pregamealltalk and changes the server setting")

local function ChangeAlltalk(client, value)
    local currentstate = Server.GetConfigSetting("alltalk") or false
    local newState = value and string.ToBoolean(value) or not currentstate
    
    Server.SetConfigSetting("alltalk", newState)
    Server.SaveConfigSettings()
    ServerAdminPrint(client, string.format("Alltalk is now %s", newState and "enabled" or "disabled"))
    
end
CreateServerAdminCommand("Console_sv_alltalk", ChangeAlltalk, "[<true/false>] Toggles alltalk and changes the server setting")

function SetDynDNS(client, address)
    if address and address ~= "" then
        Server.SetKeyValue("sv_dyndns", address)
        Server.SetConfigSetting("enabledyndns", true)
        Server.SetConfigSetting("dyndns", address)

        Shared.Message(string.format("Server's dynamic dns set to %s", address))
        Server.SaveConfigSettings()
    else
        Server.SetKeyValue("sv_dyndns", "")
        Server.SetConfigSetting("enabledyndns", false)
        Shared.Message(string.format("Disabled the server's dynamic dns", address))
        Server.SaveConfigSettings()
    end
end
CreateServerAdminCommand("Console_sv_dyndns", SetDynDNS,
    "<adrress>. Set a dynamic dns for the server. Use \"\" to disable the usage of the dyndns.")

function GetReservedSlotData()

    local returnData = { }
    
    local reservedSlots = Server.GetReservedSlotsConfig()
    if reservedSlots and reservedSlots.amount and reservedSlots.ids then
    
        returnData.amount = reservedSlots.amount
        returnData.ids = { }
        for name, id in pairs(reservedSlots.ids) do
            table.insert(returnData.ids, { name = name, id = id })
        end
        
    end
    
    return returnData
    
end

function SetReservedSlotAmount(client, amount)

    amount = tonumber(amount)
    local reservedSlots = Server.GetReservedSlotsConfig()
    if reservedSlots and amount and amount >= 0 and amount <= Server.GetMaxPlayers() then
    
        reservedSlots.amount = amount

        Server.SetReservedSlotLimit(reservedSlots.amount)
        
        Shared.Message("Reserved slot amount set to " .. reservedSlots.amount)
        Server.SaveReservedSlotsConfig()
        
    end
    
end
CreateServerAdminCommand("Console_sv_reserved_slots", SetReservedSlotAmount, "<amount>. Set the amount of reserved slots available on the server.")

local function AddReservedSlot(client, name, id)

    name = name or "None"
    id = tonumber(id)
    
    if not id then
    
        ServerAdminPrint(client, "Invalid arguments. Pass in a name and Steam Id for the new reserved slot.")
        return
        
    end
    
    local reservedSlots = Server.GetReservedSlotsConfig()
    if reservedSlots and reservedSlots.ids then
    
        reservedSlots.ids[name] = id
        ServerAdminPrint(client, "Added reserved slot for " .. name .. " with Id " .. id)
        Server.SaveReservedSlotsConfig()
        
    end
    
end
CreateServerAdminCommand("Console_sv_add_reserved_slot", AddReservedSlot, "<name> <steamid>. Adds a new reserved slot for the SteamID specified.")

local function RemoveReservedSlot(client, id)

    id = tonumber(id)
    
    if not id then
    
        ServerAdminPrint(client, "Invalid argument. Pass in the Steam Id for the existing reserved slot.")
        return
        
    end
    
    local reservedSlots = Server.GetReservedSlotsConfig()
    if reservedSlots and reservedSlots.ids then
    
        for name, steamId in pairs(reservedSlots.ids) do
        
            if id == steamId then
            
                reservedSlots.ids[name] = nil
                ServerAdminPrint(client, "Removed reserved slot for " .. name)
                Server.SaveConfigSettings()
                break
                
            end
            
        end
        
    end
    
end
CreateServerAdminCommand("Console_sv_remove_reserved_slot", RemoveReservedSlot, "<steamid>. Removes the reserved slot for the SteamID specified.")

local function PLogAll(client)

    Shared.ConsoleCommand("p_logall")
    ServerAdminPrint(client, "Performance logging enabled")
    
end
CreateServerAdminCommand("Console_sv_p_logall", PLogAll, "Starts performance logging")

local function PEndLog(client)

    Shared.ConsoleCommand("p_endlog")
    ServerAdminPrint(client, "Performance logging disabled")
    
end
CreateServerAdminCommand("Console_sv_p_endlog", PEndLog, "Ends performance logging")

local function AutoBalance(client, enabled, playerCount, seconds)

    if enabled == "true" then
    
        playerCount = playerCount and tonumber(playerCount) or 2
        seconds = seconds and tonumber(seconds) or 10
        Server.SetConfigSetting("auto_team_balance", { enabled = true, enabled_on_unbalance_amount = playerCount, enabled_after_seconds = seconds })
        ServerAdminPrint(client, "Auto Team Balance is now Enabled. Player unbalance amount: " .. playerCount .. " Activate delay: " .. seconds)
        
    else
    
        Server.SetConfigSetting("auto_team_balance", { enabled = false, enabled_on_unbalance_amount = playerCount, enabled_after_seconds = seconds })
        ServerAdminPrint(client, "Auto Team Balance is now Disabled")
        
    end
    
end
CreateServerAdminCommand("Console_sv_autobalance", AutoBalance, "<true/false> <player count> <seconds>, Toggles auto team balance. The player count and seconds are optional. Count defaults to 2 over balance to enable. Defaults to 10 second wait to enable.")

local function AutoKickAFK(client, time, capacity)

    time = tonumber(time) or 300
    capacity = tonumber(capacity) or 0.5
    Server.SetConfigSetting("auto_kick_afk_time", time)
    Server.SetConfigSetting("auto_kick_afk_capacity", capacity)
    ServerAdminPrint(client, "Auto-kick AFK players is " .. (time <= 0 and "disabled" or "enabled") .. ". Kick after: " .. math.floor(time) .. " seconds when server is at: " .. math.floor(capacity * 100) .. "% capacity")
    
end
CreateServerAdminCommand("Console_sv_auto_kick_afk", AutoKickAFK, "<seconds> <number>, Auto-kick is disabled when the first argument is 0. A player will be kicked only when the server is at the defined capacity (0-1).")

local function SetTeamSpawns(client, ...)

    local arguements = StringConcatArgs(...)
    if arguements then
        local spawns = StringSplit(arguements, ",")
        local team1Spawn = spawns[1]
        local team2Spawn = spawns[2]
            
        if string.find(ToString(spawns), ",") then
            team2Spawn = StringTrim(team2Spawn)
        end
        
        Server.teamSpawnOverride = {}
        if spawns and team1Spawn and team1Spawn ~= "" and team2Spawn and team2Spawn ~= "" and team1Spawn ~= team2Spawn and not GetGamerules():GetGameStarted() then
            table.insert(Server.teamSpawnOverride, { marineSpawn = string.lower(team1Spawn), alienSpawn = string.lower(team2Spawn) })   
            GetGamerules():ResetGame()
        else
            ServerAdminPrint(client, "Invalid usage. Usage: <marine spawn location>, <alien spawn location>. Game can not be started.")
        end
    else
        ServerAdminPrint(client, "Invalid usage. Usage: <marine spawn location>, <alien spawn location>")
    end
end
CreateServerAdminCommand("Console_sv_spawnteams", SetTeamSpawns, "marinespawnname, alienspawnname, Spawns teams at specified locations. Locations must be exact")

local function InstallMod(client, modid)
	if not modid then return end

	Server.InstallMod(string.upper(modid))
end
CreateServerAdminCommand("Console_sv_installmod", InstallMod, "<modid (in hex)> downloads the given mod to the server")

local function ChangeSeason(client, value)
    if value then
        for season, _ in pairs(Seasons.kSeasonKeys) do
            value = value:lower() == season:lower() and season or value
        end

        value = value:lower() == "default" and "Default" or value
    end
    
    if value ~= "Default" and not Seasons.kSeasonKeys[value] then
        ServerAdminPrint(client, "Error: sv_setseason [<Fall, Winter, None, Default>] Sets what season is loaded. Requires map change")
        return
    end

    local cvalue = value == "Default" and "" or value
    Server.SetConfigSetting("season", cvalue)
    Server.SaveConfigSettings()
    ServerAdminPrint(client, string.format("Season is now %s", value))

end
CreateServerAdminCommand("Console_sv_setseason", ChangeSeason, "[<None, Fall, Winter, Default>] Sets what season is loaded. Requires map change")


local function ChangeSeasonMonth(client, value)

    Server.SetConfigSetting("season_month", tonumber(value))
    Server.SaveConfigSettings()
    ServerAdminPrint(client, string.format("Season month is now %d", value))

end
CreateServerAdminCommand("Console_sv_setseasonmonth", ChangeSeasonMonth, "Overrides the month used for the ByDate season")

CreateServerAdminCommand(
    "Console_sv_endgamehive2", 
    function(_, teamIdx)
        if not teamIdx then
            return
        else
            teamIdx = tonumber(teamIdx)
        end
        
        DebugPrint("sv_endgamehive2 %s", teamIdx)
        if teamIdx == kTeam1Index or teamIdx == kTeam2Index then
            Log("  sv_endgamehive2 %s", teamIdx)
            local team = ConditionalValue(
                GetGamerules().team1:GetTeamNumber() == teamIdx,
                GetGamerules().team1, GetGamerules().team2
            )
            GetGamerules():EndGame( team , false ) 
        end
    end, 
    "<TeamNumber 1 or 2> - Ends the game round"
)
