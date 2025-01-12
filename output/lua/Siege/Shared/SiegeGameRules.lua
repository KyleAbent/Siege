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
    Print("Front door time = " .. self.frontTimer)
    Print("Side door time = " .. self.sideTimer)
    Print("Siege door time = " .. self.siegeTimer)
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




-- -- Called when map loads
-- function SiegeGameRules:OnMapPostLoad()
--     NS2Gamerules.OnMapPostLoad(self)
--
--     -- Load map-specific settings
--     local mapName = Shared.GetMapName()
--     if kSiegeMapSettings[mapName] then
--         self.frontDoorTime = kSiegeMapSettings[mapName].frontDoorTime or self.frontDoorTime
--         self.siegeDoorTime = kSiegeMapSettings[mapName].siegeDoorTime or self.siegeDoorTime
--     end
--
--     Print(string.format("Map loaded: Front door time = %d, Siege door time = %d",
--         self.frontDoorTime, self.siegeDoorTime))
-- end

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



if Server then

    --local origPostLoad = NS2Gamerules.OnMapPostLoad
    function SiegeGameRules:OnMapPostLoad()
        --origPostLoad(self)
        --Override to fix bugs?
        self:AddTimedCallback(function() GetLocationGraph() print("GetLocationgraph delay") end, 1)
        NS2Gamerules.OnMapPostLoad(self)
        Server.CreateEntity(Timer.kMapName)
        Print("Timer Created")
    end


end






-- Register entity
Shared.LinkClassToMap("SiegeGameRules", SiegeGameRules.kMapName, {})