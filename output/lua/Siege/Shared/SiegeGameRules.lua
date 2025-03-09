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
    sideDoorOpened = "boolean",
    fogDensity = "float"
}

-- Initialize game rules
function SiegeGameRules:OnCreate()
     NS2Gamerules.OnCreate(self)
     self.timeCheckedForFog = 0
     self.fogDensity = 1  -- Default fog density
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



    -- Public function to control fog density from gameplay events
    function SetSiegeFogDensity(density)
        self.fogDensity = density
        Server.SendNetworkMessage("SiegeFogUpdate", {density = density}, true)
        gLastFogUpdate = Shared.GetTime()  -- Reset timer
    end

    function SiegeGameRules:UpdateSiegeFog(deltaTime)
        -- Configuration
        local kFogUpdateInterval = 5  -- 60 seconds between random updates
        local gLastFogUpdate = 0

        -- Update fog randomly every minute
--         Print("Server: UpdateSiegeFog")
         if self.timeCheckedForFog + kFogUpdateInterval < Shared.GetTime() then
                self.timeCheckedForFog = Shared.GetTime()
            local newDensity = math.random(0, 500) / 100

            -- Update global setting
            self.fogDensity = newDensity

            -- Send to all clients
            Server.SendNetworkMessage("SiegeFogUpdate", {density = newDensity}, true)

            -- Debug print
            Print("Server: Fog density updated to " .. tostring(newDensity))

            -- Update timestamp
            gLastFogUpdate = Shared.GetTime()
        end
    end

    function SiegeGameRules:OnUpdate(timePassed)
        NS2Gamerules.OnUpdate(self, timePassed)
        --self:UpdateSiegeFog(timePassed) this is just fun debugging
    end

end






-- Register entity
Shared.LinkClassToMap("SiegeGameRules", SiegeGameRules.kMapName, {})


function OnCommandSetFogDensity(client, densityStr)
    if not Shared.GetCheatsEnabled() then return end
    local density = tonumber(densityStr) or 1
    local gameRules = GetGamerules()
    if gameRules and gameRules:isa("SiegeGameRules") then
        gameRules.fogDensity = density
        Server.SendNetworkMessage("SiegeFogUpdate", {density = density}, true)
        Print("Server: Manually set fog density to " .. tostring(density))
    end
end

Event.Hook("Console_setfogdensity", OnCommandSetFogDensity)