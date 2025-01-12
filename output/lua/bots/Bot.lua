--=============================================================================
--
-- lua\bots\Bot.lua
--
-- Copyright (c) 2022, Unknown Worlds Entertainment, Inc.
--
--=============================================================================
local isReload = ...

class 'Bot' (Entity)
Bot.kMapName = "bot"
Bot.kUpdateBrainWhenDead = false

Bot.networkVars = {
    playerEntity = "entityid",
    team = "integer (0 to 3)",
    teamJoined = "boolean",
}


if Server then
    Script.Load("lua/bots/Bot_Server.lua", isReload)
elseif Client then
    local function DumpBots()
        for index, bot in ientitylist(Shared.GetEntitiesWithClassname("Bot")) do
            local botPlayer = Shared.GetEntity(bot.playerEntity)
            if botPlayer then
                Log("PlayerBot %s controling entity %s(%s) ", bot:GetId(), botPlayer:GetClassName(), botPlayer:GetId())
            else
                Log("PlayerBot %s controlled entity %s is not in relevantacy range", bot:GetId(), bot.playerEntity)
            end
        end
    end

    Event.Hook("Console_bots",  DumpBots)
end

Shared.LinkClassToMap("Bot", Bot.kMapName, Bot.networkVars)