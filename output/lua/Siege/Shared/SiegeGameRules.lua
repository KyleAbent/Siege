Script.Load("lua/NS2Gamerules.lua")
Script.Load("lua/Gamerules.lua")

class 'SiegeGameRules' (NS2Gamerules)

SiegeGameRules.kMapName = "siege_gamerules"

local networkVars =
{
    frontTimer = "integer",
    sideTimer = "integer",
    siegeTimer = "integer",
    dynamicAdjustment = "integer",
    countofpowerwhensetup = "integer",
    countofpowercurrently = "integer",
}

-- Initialize game rules
function SiegeGameRules:OnCreate()
    NS2Gamerules.OnCreate(self)

    -- Default timers
    self.frontTimer = kFrontTime
    self.sideTimer = kSideTime
    self.siegeTimer = kSiegeTime
    Print("SiegeGameRules initialized.")
end

function GameInfo:GetFrontTime()
   return self.frontTimer
end

function GameInfo:SetFrontTime(time)
    self.frontTimer = time
end

function GameInfo:GetSideTime()
   return self.sideTimer
end

function GameInfo:SetSideTime(time)
    self.sideTimer = time
end

function GameInfo:GetSiegeTime()
   return self.siegeTimer
end

function GameInfo:SetSiegeTime(time)
    self.siegeTimer = time
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
    end
end

-- Update game state


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