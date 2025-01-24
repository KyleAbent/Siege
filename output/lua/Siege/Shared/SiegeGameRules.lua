Script.Load("lua/NS2Gamerules.lua")
Script.Load("lua/Gamerules.lua")

class 'SiegeGameRules' (NS2Gamerules)

SiegeGameRules.kMapName = "siege_gamerules"

local networkVars =
{
    -- Store the configured timer values
    frontDoorTime = "float",
    siegeDoorTime = "float",
    sideDoorTime = "float",

    -- Store the current state
    timeGameStarted = "time",
    frontDoorOpened = "boolean",
    siegeDoorOpened = "boolean",
    sideDoorOpened = "boolean"
}

-- Initialize game rules
function SiegeGameRules:OnCreate()
     NS2Gamerules.OnCreate(self)
     -- Initialize default values
    self.frontDoorTime = 300  -- 5 minutes default
    self.siegeDoorTime = 900  -- 15 minutes default
    self.sideDoorTime = 420   -- 7 minutes default
end

function SiegeGameRules:OnInitialized()
    NS2Gamerules.OnInitialized(self)

    -- Initialize gameinfo if we're the server
    if Server then
        self:SetTimer() -- Set initial timer values
    end
end



-- Called when game state changes or round resets
function SiegeGameRules:SetTimer()
    if not Server then return end

    -- Get GameInfo instance
    local gameInfo = GetGameInfoEntity()
    if not gameInfo then return end

    -- Set timer values in GameInfo
    gameInfo:SetFrontTime(math.floor(self.frontDoorTime))
    gameInfo:SetSiegeTime(math.floor(self.siegeDoorTime))
    gameInfo:SetSideTime(math.floor(self.sideDoorTime))

end

function SiegeGameRules:GetFrontDoorTime()
    return self.frontDoorTime
end

function SiegeGameRules:GetSiegeDoorTime()
    return self.siegeDoorTime
end

function SiegeGameRules:GetSideDoorTime()
    return self.sideDoorTime
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
        self.sideDoorOpened = false
        self:SetTimer()
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
       -- Reset all doors
        for _, door in ientitylist(Shared.GetEntitiesWithClassname("SiegeDoor")) do
            door:OnReset()
            Print("Resetting Door")
        end

        -- Reset timer
        for _, timer in ientitylist(Shared.GetEntitiesWithClassname("Timer")) do
            timer:OnReset()
            Print("Resetting Timer")
        end

        -- Reset door states
        self.frontDoorOpened = false
        self.siegeDoorOpened = false
        self.sideDoorOpened = false
        self:SetTimer()
    end

end






-- Register entity
Shared.LinkClassToMap("SiegeGameRules", SiegeGameRules.kMapName, {})