function GetTimer() --it washed away
    local entityList = Shared.GetEntitiesWithClassname("Timer")
    if entityList:GetSize() > 0 then
                 local timer = entityList:GetEntityAtIndex(0) 
                 return timer
    end    
    return nil
end

function CloseAllBreakableDoors()
      for _, door in ientitylist(Shared.GetEntitiesWithClassname("BreakableDoor")) do 
               door.open = false
               door:SetHealth(door:GetHealth() + 10)
      end
end



-- Load shared configurations and game rules
Script.Load("lua/Siege/Shared/SiegeConfig.lua")
Script.Load("lua/Siege/Shared/SiegeGameRules.lua")
Script.Load("lua/Siege/Shared/timer.lua")
Script.Load("lua/Siege/Shared/SiegeMessages.lua")
Script.Load("lua/Siege/Shared/Doors.lua")
Script.Load("lua/Siege/Shared/BreakableDoor.lua")

