Script.Load("lua/NS2Gamerules.lua")
Script.Load("lua/Gamerules.lua")

class 'SiegeGameRules' (NS2Gamerules)

SiegeGameRules.kMapName = "siege_gamerules"

-- Initialize game rules
function SiegeGameRules:OnCreate()
    NS2Gamerules.OnCreate(self)

    -- Default timers
    self.frontDoorTime = 60  -- Default, can be overridden by map
    self.siegeDoorTime = 180 -- Default, can be overridden by map
    self.timeElapsed = 0
    self.frontDoorOpened = false
    self.siegeDoorOpened = false

    Print("SiegeGameRules initialized.")
end

function SiegeGameRules:GetFrontDoorTime()
    return self.frontDoorTime
end

function SiegeGameRules:GetSiegeDoorTime()
    return self.siegeDoorTime
end

function SiegeGameRules:GetTimeElapsed()
    return self.timeElapsed
end

-- Called when map loads
function SiegeGameRules:OnMapPostLoad()
    NS2Gamerules.OnMapPostLoad(self)

    -- Load map-specific settings
    local mapName = Shared.GetMapName()
    if kSiegeMapSettings[mapName] then
        self.frontDoorTime = kSiegeMapSettings[mapName].frontDoorTime or self.frontDoorTime
        self.siegeDoorTime = kSiegeMapSettings[mapName].siegeDoorTime or self.siegeDoorTime
    end

    Print(string.format("Map loaded: Front door time = %d, Siege door time = %d",
        self.frontDoorTime, self.siegeDoorTime))
end

-- Override game start check to handle siege-specific conditions
function SiegeGameRules:CheckGameStart()
    -- Call parent implementation first
    NS2Gamerules.CheckGameStart(self)

    if self:GetGameState() == kGameState.Started then
        -- Reset siege timers when game actually starts
        self.timeElapsed = 0
        self.frontDoorOpened = false
        self.siegeDoorOpened = false
        -- Initial update to clients
        self:SendTimerUpdateToClients()
    end
end

-- Update game state

function SiegeGameRules:UpdateGame(deltaTime)
    -- Call parent implementation
    NS2Gamerules.UpdateGame(self, deltaTime)

    if self:GetGameStarted() then
        local previousTime = math.floor(self.timeElapsed)
        self.timeElapsed = self.timeElapsed + deltaTime

        -- Send updates when second changes or game just started
        if math.floor(self.timeElapsed) > previousTime or previousTime == 0 then
            self:SendTimerUpdateToClients()
        end

        -- Check door states
        if not self.frontDoorOpened and self.timeElapsed >= self.frontDoorTime then
            self:OpenDoor("Front")
        end

        if not self.siegeDoorOpened and self.timeElapsed >= self.siegeDoorTime then
            self:OpenDoor("Siege")
        end
    end
end

function SiegeGameRules:OpenDoor(doorType)
    if doorType == "Front" and not self.frontDoorOpened then
        self.frontDoorOpened = true
        Print("Front door opened!")
        Server.SendNetworkMessage("FrontDoorOpened", {}, true)
    elseif doorType == "Siege" and not self.siegeDoorOpened then
        self.siegeDoorOpened = true
        Print("Siege door opened!")
        Server.SendNetworkMessage("SiegeDoorOpened", {}, true)
    end
end


function SiegeGameRules:SendTimerUpdateToClients()
    if Server then
        Server.SendNetworkMessage("SiegeTimerUpdate", {
            frontDoorTime = self.frontDoorTime,
            siegeDoorTime = self.siegeDoorTime,
            timeElapsed = self.timeElapsed
        }, true)
    end
end


function SiegeGameRules:OnClientConnect(client)
    -- Call parent implementation
    NS2Gamerules.OnClientConnect(self, client)

    -- Send initial state to new client
    if Server then
        Server.SendNetworkMessage(client, "SiegeTimerUpdate", {
            frontDoorTime = self.frontDoorTime,
            siegeDoorTime = self.siegeDoorTime,
            timeElapsed = self.timeElapsed
        }, true)
        Print("SiegeGameRules: Sent initial state to new client")
    end
end














-- Register entity
Shared.LinkClassToMap("SiegeGameRules", SiegeGameRules.kMapName, {})