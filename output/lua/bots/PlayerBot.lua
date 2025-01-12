--=============================================================================
--
-- lua\bots\PlayerBot.lua
-- Copyright (c) 2022, Unknown Worlds Entertainment, Inc.
--
--=============================================================================

Script.Load("lua/bots/Bot.lua")

class 'PlayerBot' (Bot)

PlayerBot.kMapName = "playerbot"
PlayerBot.networkVars =
{
    name = "string (128)"
}

if Server then
    Script.Load("lua/bots/PlayerBot_Server.lua")
end

Shared.LinkClassToMap("PlayerBot", PlayerBot.kMapName, PlayerBot.networkVars)
