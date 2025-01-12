--=============================================================================
--
-- lua\bots\Bot_Server.lua
--
-- Created by Max McGuire (max@unknownworlds.com)
-- Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
--
--=============================================================================
Script.Load("lua/bots/BotDebug.lua")

-- Stores all of the bots
gServerBots = {}


Script.Load("lua/TechMixin.lua")
Script.Load("lua/ExtentsMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")

--Note: this is unique to Skulk bots, and for testing/debugging only
gLifeformTypeLock = false
gLifeformTypeLockType = nil

local __allowedLifeformLocks = { "lerk", "gorge", "fade", "onos" }
Event.Hook("Console_bot_lockevolve", function(client, lifeform)
    if type(lifeform) == "string" and lifeform ~= "" and table.icontains(__allowedLifeformLocks, lifeform)  then
        gLifeformTypeLock = true
        if lifeform == "gorge" then
            gLifeformTypeLockType = kTechId.Gorge
        elseif lifeform == "lerk" then
            gLifeformTypeLockType = kTechId.Lerk
        elseif lifeform == "fade" then
            gLifeformTypeLockType = kTechId.Fade
        elseif lifeform == "onos" then
            gLifeformTypeLockType = kTechId.Onos
        end

        local chatMessage = "Alien evolution locked to " .. firstToUpper(lifeform)
        Server.SendNetworkMessage("Chat", BuildChatMessage(false, "BotDebug", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
    else
        local chatMessage = "Alien evolution unlocked"
        Server.SendNetworkMessage("Chat", BuildChatMessage(false, "BotDebug", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
        gLifeformTypeLock = false
        gLifeformTypeLockType = nil
    end
end)

function Bot:OnCreate()
    Entity.OnCreate(self)
    InitMixin(self, EntityChangeMixin)
end

function Bot:Initialize(forceTeam, active, tablePosition)
    PROFILE("Bot:Initialize")

    InitMixin(self, TechMixin)
    InitMixin(self, ExtentsMixin)
    InitMixin(self, PathingMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })

    -- Create a virtual client for the bot
    self.client = Server.AddVirtualClient()
    self.client.bot = self

    self.team = forceTeam and tonumber(forceTeam) or 0
    self.active = active
    self.teamJoined = false

    if self.team == kAlienTeamType then
        self.lifeformEvolution = nil
    end

    if tablePosition then
        table.insert(gServerBots, tablePosition, self)
    else
        gServerBots[#gServerBots + 1] = self
    end

    return true
end

function Bot:Reset()
    -- do nothing here
end

function Bot:GetClient()
    return self.client
end

function Bot:GetMapName()
    return "bot"
end

function Bot:GetIsFlying()
    return false
end

function Bot:UpdateTeam()
    PROFILE("Bot:UpdateTeam")

    local player = self:GetPlayer()

    if player and player:GetTeamNumber() == 0 then
    
        if not self.team or self.team == 0 then
            local nTeam1Players = GetGamerules():GetTeam1():GetNumPlayers()
            local nTeam2Players = GetGamerules():GetTeam2():GetNumPlayers()
            if nTeam1Players < nTeam2Players then
                self.team = 1
            else
                self.team = 2
            end
        end

        local gamerules = GetGamerules()
        if gamerules and gamerules:GetCanJoinTeamNumber(player, self.team) then
            if gamerules:JoinTeam(player, self.team) then
                self.teamJoined = true
            end
        end
        
    end

end

function Bot:GetTeamNumber()
    return self.team
end

function Bot:Disconnect()
    local client = self.client
    --self:OnDestroy()

    Server.DisconnectClient(client)
    DestroyEntity(self)
end

function Bot:GetPlayer()
    PROFILE("Bot:GetPlayer")

    if self.client and self.client:GetId() ~= Entity.invalidId then
        return self.client:GetControllingPlayer()
    else
        return nil
    end
end

------------------------------------------
--  NOTE: There is no real reason why this is different from GenerateMove - the C++ just calls one after another.
--  For now, just put higher-level book-keeping here I guess.
------------------------------------------
function Bot:OnThink()
    PROFILE("Bot:OnThink")

    self:UpdateTeam()

end

function Bot:OnDestroy()
    Entity.OnDestroy(self)

    for i = #gServerBots, 1, -1 do
        local bot = gServerBots[i]
        if bot == self then
            table.remove(gServerBots, i)
            break
        end
    end

    if self.brain and self.brain.OnDestroy then
        self.brain:OnDestroy()
    end

    if self.client then
        self.client.bot = nil
        self.client = nil
    end

end

------------------------------------------
--  Console commands for managing bots
------------------------------------------

local function GetIsClientAllowedToManage(client)

    return client == nil    -- console command from server
    or Shared.GetCheatsEnabled()
    or Shared.GetDevMode()
    or client:GetIsLocalClient()    -- the client that started the listen server

end

function OnConsoleAddPassiveBots(client, numBotsParam, forceTeam, className)
    OnConsoleAddBots(client, numBotsParam, forceTeam, className, true)  
end

function OnConsoleAddBots(client, numBotsParam, forceTeam, botType, passive)

    if GetIsClientAllowedToManage(client) then

        Log("OnConsoleAddBots(client=%s, numBotsParam=%s, forceTeam=%s, botType=%s, passive=%s)",
                                          client, numBotsParam, forceTeam, botType, passive)

        local kType2Class =
        {
            com = CommanderBot
        }

        if botType and not kType2Class[botType] then
            Log("\tBot type '%s' is not valid!", botType)
            return
        end

        local class = kType2Class[ botType ] or PlayerBot

        local numBots = 1
        if numBotsParam then
            local toNumBots = tonumber(numBotsParam)
            if toNumBots then
                numBots = math.max(toNumBots, 1)
            else
                Log("\tNumBots: %s is invalid!", numBotsParam)
                return
            end
        end

        local botTeam = forceTeam and tonumber(forceTeam)
        if forceTeam and botTeam ~= kTeam1Type and botTeam ~= kTeam2Type then
            Log("\tTeam %s is invalid!", forceTeam)
            return
        end

        for index = 1, numBots do
            local bot = Server.CreateEntity(class.kMapName)
            bot:Initialize(botTeam, not passive)
        end

    end
    
end

function OnConsoleRemoveBots(client, numBotsParam, teamNum)

    if GetIsClientAllowedToManage(client) then

        local numBots = 1
        if numBotsParam then
            numBots = math.max(tonumber(numBotsParam), 1)
        end

        teamNum = teamNum and tonumber(teamNum) or 0

        local numRemoved = 0
        for index = #gServerBots, 1, -1 do

            local bot = gServerBots[index]
            if teamNum == 0 or bot:GetTeamNumber() == teamNum then
                bot:Disconnect()
                numRemoved = numRemoved + 1
            end

            if numRemoved == numBots then
                break
            end

        end

    end
    
end

function OnConsoleRemoveUnselectedBots(client)

    if GetIsClientAllowedToManage(client) then

        for index = #gServerBots, 1, -1 do

            local bot = gServerBots[index]
            local botPlayer = bot:GetPlayer()
            local isBotSelected = botPlayer:GetIsSelected(kTeam1Type) or botPlayer:GetIsSelected(kTeam2Type)

            if not isBotSelected then
                bot:Disconnect()
            end

        end

    end

end

local gFreezeBots = false
function OnConsoleFreezeBots(client)
    if GetIsClientAllowedToManage(client) then
        gFreezeBots = not gFreezeBots
    end
end

function OnConsoleListBots(client)
    if not GetIsClientAllowedToManage(client) then return end

    Shared.Message("List of currently active bots:")
    for i = 1, #gServerBots do
        local bot = gServerBots[i]
        local player = bot and bot:GetPlayer()
        local name = player and player:GetName() or "No Name"
        local team = bot:GetTeamNumber()
        local cTeam = player and player:GetTeamNumber() or 0
        Shared.Message(string.format("%s: %s (%s)- Team: %s->%s", i, name, bot.classname, cTeam, team))
    end
end

function OnVirtualClientMove(client)

    if gFreezeBots then return Move() end

    -- If the client corresponds to one of our bots, generate a move for it.
    if client.bot then

        local botPlayer = client.bot:GetPlayer()
        local skipUpdate = not client.bot.kUpdateBrainWhenDead and
                (not botPlayer or not botPlayer:GetIsAlive())

        if skipUpdate then
        --bail immediately if player is dead
            return Move()
        end

        return client.bot:GenerateMove()
    end

    return Move()

end

function OnVirtualClientThink(client, deltaTime)

    if gFreezeBots then return true end
    
    -- If the client corresponds to one of our bots, allow it to think.
    if client.bot then
        client.bot:OnThink()
    end

    return true
    
end

Shared.LinkClassToMap("Bot", Bot.kMapName, Bot.networkVars)

-- Make sure to load these after Bot is defined
Script.Load("lua/bots/TestBot.lua")
Script.Load("lua/bots/PlayerBot.lua")
Script.Load("lua/bots/CommanderBot.lua")

-- Register the bot console commands
Event.Hook("Console_addpassivebot",  OnConsoleAddPassiveBots)
Event.Hook("Console_addbot",         OnConsoleAddBots)
Event.Hook("Console_removebot",      OnConsoleRemoveBots)
Event.Hook("Console_addbots",        OnConsoleAddBots)
Event.Hook("Console_removebots",     OnConsoleRemoveBots)
Event.Hook("Console_remove_unselected_bots",     OnConsoleRemoveUnselectedBots)
Event.Hook("Console_freezebots",     OnConsoleFreezeBots)
Event.Hook("Console_listbots",       OnConsoleListBots)

-- Register to handle when the server wants this bot to
-- process orders
Event.Hook("VirtualClientThink",    OnVirtualClientThink)

-- Register to handle when the server wants to generate a move
-- for one of the virtual clients
Event.Hook("VirtualClientMove",     OnVirtualClientMove)
