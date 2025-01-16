-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Gamerules.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- Base gamerules class that dictates the flow of the game or mode. Extend off gamerules, link
-- to an entity and place entity in your map. Other script code can get the current gamerules
-- object with GetGamerules().
--
-- TODO: Should there be any concept of Teams here?
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Gamerules_Global.lua")
Script.Load("lua/Entity.lua")

-- Base Gamerules entity
class 'Gamerules' (Entity)

Gamerules.kMapName = "gamerules"

local networkVars = { }

function Gamerules:OnCreate()

    self:SetUpdates(true, kDefaultUpdateRate)
    
    if Server then
    
        self:SetIsVisible(false)
        
        self:SetPropagate(Entity.Propagate_Always)
        
        self.damageMultiplier = 1
        
        -- Set global gamerules whenever gamerules are built
        SetGamerules(self)
        
        self.mapLoaded = false
        
    end
    
end

function Gamerules:OnDestroy()

    if Server then
        SetGamerules(nil)
    end
    
end

------------
-- Server --
------------
if(Server) then

-- TODO: Remove?
function Gamerules:GetGameStarted()
    return true
end

-- TODO: Remove?
function Gamerules:GetTeam(teamNum)
    return nil
end

function Gamerules:CanEntityDoDamageTo(attacker, target)
    return true
end

-- Called whenever an entity is killed. Killer could be the same as targetEntity. Called before entity is destroyed.
function Gamerules:OnEntityKilled(target, attacker, doer, point, direction)   
end
 
function Gamerules:OnEntityChange(oldId, newId)
end

Gamerules.resetProtectedEntities = {
    "Bot"
}

--
-- Starts a new game by resetting the map and all of the players. Keep everyone on current teams (readyroom, playing teams, etc.) but
-- respawn playing players.
--
function Gamerules:ResetGame()


    -- Convert to a table as entities are destroyed here and the EntityList will automatically
    -- update when they are destroyed which is bad for iteration.
    local entityTable = EntityListToTable(Shared.GetEntitiesWithClassname("Entity"))
    Print("ResetGame - entity count: %s", #entityTable)
    Print("entityTable: %s", entityTable)
    for _, entity in ipairs(entityTable) do

        -- Don't reset/delete gamerules!
        if(entity ~= self) then
            
            if (entity:GetIsMapEntity() and entity:isa("ScriptActor")) or entity:isa("Player") or entity:isa("Location") then
            
                entity:Reset()
                
                -- called after the reset is done
                if entity.OnReset then
                    entity:OnReset()
                end    
                
            else
                local allowDestruction = true
                for i, name in pairs(self.resetProtectedEntities) do
                    allowDestruction = allowDestruction and not entity:isa(name)
                end

                if allowDestruction then
                    DestroyEntity(entity)
                end
            end

        end       
 
    end

    Server.SendNetworkMessage(nil, "ResetGame", {}, true)
   
end

function Gamerules:OnUpdate(deltaTime)
end

-- Function for allowing teams to hear each other's voice chat
function Gamerules:GetCanPlayerHearPlayer(listenerPlayer, speakerPlayer, channelType)
    return true    
end

function Gamerules:GetCanJoinPlayingTeam(player)
    if player:GetIsSpectator() then

        local numClients = Server.GetNumClientsTotal()
        local numSpecs = Server.GetNumSpectators()

        local numPlayer = numClients - numSpecs
        local maxPlayers = Server.GetMaxPlayers()
        local numRes = Server.GetReservedSlotLimit()

        --check for empty player slots excluding reserved slots
        if numPlayer >= maxPlayers then
            Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(3), true)
            return false
        end

        --check for empty player slots including reserved slots
        local userId = player:GetSteamId()
        local hasReservedSlot = GetHasReservedSlotAccess(userId)
        if numPlayer >= (maxPlayers - numRes) and not hasReservedSlot then
            Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(3), true)
            return false
        end
    end

    return true
end

function Gamerules:RespawnPlayer(player)

    -- Randomly choose unobstructed spawn points to respawn the player
    local success = false
    local spawnPoint
    local spawnPoints = Server.readyRoomSpawnList
    local numSpawnPoints = table.icount(spawnPoints)

    if(numSpawnPoints > 0) then
    
        local spawnPoint = GetRandomClearSpawnPoint(player, spawnPoints)
        if (spawnPoint ~= nil) then
        
            local origin = spawnPoint:GetOrigin()
            local angles = spawnPoint:GetAngles()
            
            SpawnPlayerAtPoint(player, origin, angles)
            
            player:ClearEffects()
            
            success = true
            
        end
        
    end
    
    if(not success) then
        Print("Gamerules:RespawnPlayer(player) - Couldn't find spawn point for player.")
    end
    
    return success
    
end

function Gamerules:GetPlayerConnectMapName(client)
    return ReadyRoomPlayer.kMapName
end

-- Called when a player first connects to the server. Passes client index.
function Gamerules:OnClientConnect(client)

    local mapName = self:GetPlayerConnectMapName(client)
    local player = CreateEntity(mapName, nil, kTeamReadyRoom)       --TD-FIXME This (ideally) needs to slam players to the team they were shuffled to (via lobby-TD)
    
    local steamid = tonumber(client:GetUserId())
    Shared.Message(string.format('Client Authed. Steam ID: %s', steamid))
    
    if player ~= nil then
        
        -- Tell engine that player is controlling this entity
        player:SetControllerClient(client, false)
        
        player:OnClientConnect(client)
        
        self:RespawnPlayer(player)
        
    else
        Print("Gamerules:OnClientConnect(): Couldn't create player entity of type \"%s\"", mapName)
    end
    
    Server.SendNetworkMessage(client, "SetClientIndex", { clientIndex = client:GetId() }, true)
    
    Server.SendNetworkMessage(client, "ServerHidden", { hidden = Server.GetServerHidden() }, true)
    
    local playerInfo = CreateEntity(PlayerInfoEntity.kMapName)
    player:SetPlayerInfo(playerInfo)
    
    return player
    
end

-- Called when player disconnects from server. Passes client index
-- and player entity. Player could be nil if it has been deleted.
function Gamerules:OnClientDisconnect(client)

    local clientIndex = client:GetId()

    -- Tell all other clients that the player has disconnected
    --Server.SendCommand( nil, string.format("clientdisconnect %d", clientIndex) )
    
    for _, playerInfo in ipairs( EntityListToTable(Shared.GetEntitiesWithClassname("PlayerInfoEntity")) ) do
    
        if playerInfo.clientIndex == clientIndex then
        
            DestroyEntity(playerInfo)
            break
            
        end    
    end
    
end

--
-- Called after map loads.
--
function Gamerules:OnMapPostLoad()
    self.mapLoaded = true
end

function Gamerules:GetMapLoaded()
    return self.mapLoaded
end

--
-- Cheats and modes.
--
function Gamerules:GetDamageMultiplier()
    return ConditionalValue(Shared.GetCheatsEnabled(), self.damageMultiplier, 1)
end

function Gamerules:SetDamageMultiplier(multiplier)
    self.damageMultiplier = multiplier   
end

-- Send simple trigger message from map entities
function Gamerules:SendTrigger(entity, triggerName)
    self:OnTrigger(entity, triggerName)
end

function Gamerules:OnTrigger(entity, triggerName)
end

----------------
-- End Server --
----------------

end

Shared.LinkClassToMap("Gamerules", Gamerules.kMapName, networkVars)