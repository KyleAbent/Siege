--=============================================================================
--
-- lua/CreateServer.lua
--
-- Created by Henry Kropf
-- Copyright 2011, Unknown Worlds Entertainment
--
--=============================================================================

local kDefaultGameMod = "ns2"

local kServerNameKey    = "serverName"
local kMapNameKey       = "mapName"
local kGameModKey       = "gameMod"
local kPlayerLimitKey   = "playerLimit"
local kServerPasswordKey    = "serverPassword"

--
-- Get server name
--
function CreateServerUI_GetServerName()
    return Client.GetOptionString( kServerNameKey, "NS2 Server" )
end

--
-- Get server password
--
function CreateServerUI_GetServerPassword()
    return Client.GetOptionString( kServerPasswordKey, "" )
end

--
-- Get linear array of map names (strings)
--
function CreateServerUI_GetMapName()

    -- Convert to a simple table
    
    local mapNames = { }
    
    for index, mapEntry in ipairs(maps) do
        mapNames[index] = mapEntry.name
    end    

    return mapNames
    
end

--
-- Get current index for map choice (assuming lua indexing for script convenience)
--
function CreateServerUI_GetMapNameIndex()

    -- Get saved map name and return index
    local mapName = Client.GetOptionString( kMapNameKey, "" )
    
    if (mapName ~= "") then
        
        for i = 1, #maps do
            if (maps[i].fileName == mapName) then
                return i
            end
        end
    
    end    
    
    return 1
    
end

--
-- Get linear array of game mods (strings)
--
function CreateServerUI_GetGameModes()
    return mods
end

--
-- Get current index for game mods (assuming lua indexing for script convenience)
--
function CreateServerUI_GetGameModesIndex()

    -- Get saved map name and return index
    local modName = Client.GetOptionString( kGameModKey, kDefaultGameMod )
    
    for i = 1, #mods do
        if (mods[i] == modName) then
            return i
        end
    end
    
    return 1

end

--
-- Get player limit
--
function CreateServerUI_GetPlayerLimit()
    return Client.GetOptionInteger(kPlayerLimitKey, 16)
end

--
-- Get all the values from the form
-- serverName - string for server
-- mapIdx - 1 - ? index of choice
-- gameModIdx - 1 - ? index of choice
-- playerLimit - 2 - 32
-- passwordText - String (can be blank)
--
function CreateServerUI_SetValues(serverName, mapIdx, gameModIdx, playerLimit, password)
    
    if (password == nil) then
        password = ""
    end
    
    -- Set options
    Client.SetOptionString( kServerNameKey, serverName )
    Client.SetOptionString( kMapNameKey, maps[mapIdx].fileName )
    Client.SetOptionString( kGameModKey, mods[gameModIdx] )
    Client.SetOptionInteger(kPlayerLimitKey, playerLimit)
    Client.SetOptionString( kServerPasswordKey, password )
    
end

--
-- Called when player presses the Create Game button with the set values.
--
function CreateServerUI_CreateServer()
   
    local mapName       = Client.GetOptionString( kMapNameKey, "" )
    local password      = Client.GetOptionString( kServerPasswordKey, "" )
    local port          = 27015
    local maxPlayers    = Client.GetOptionInteger( kPlayerLimitKey, 16 )
    local serverName    = "Listen Server"
    
    if(mapName ~= "" and Client.StartServer( mapName, serverName, password, port, maxPlayers )) then
        LeaveMenu()
    end

end