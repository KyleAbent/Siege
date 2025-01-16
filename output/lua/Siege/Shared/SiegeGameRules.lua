Script.Load("lua/NS2Gamerules.lua")
Script.Load("lua/Gamerules.lua")

class 'SiegeGameRules' (NS2Gamerules)

SiegeGameRules.kMapName = "siege_gamerules"

local networkVars =
{
}

-- Initialize game rules
function SiegeGameRules:OnCreate()
     NS2Gamerules.OnCreate(self)
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

    function SiegeGameRules:OnMapPostLoad()
        self:AddTimedCallback(function() GetLocationGraph() print("GetLocationgraph delay") end, 1)
        NS2Gamerules.OnMapPostLoad(self)
        Server.CreateEntity(Timer.kMapName)
        Print("Timer Created")
    end

    function SiegeGameRules:ResetGame()
        NS2Gamerules.ResetGame(self)
       for _, door in ientitylist(Shared.GetEntitiesWithClassname("SiegeDoor")) do
            door:OnReset()
            Print("Resetting Door")
       end
       for _, timer in ientitylist(Shared.GetEntitiesWithClassname("Timer")) do
            timer:OnReset()
            Print("Resetting Timer")
       end
   end


end






-- Register entity
Shared.LinkClassToMap("SiegeGameRules", SiegeGameRules.kMapName, {})