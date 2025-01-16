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

function GetIsInSiege(who)
    local locationName = GetLocationForPoint(who:GetOrigin())
    locationName = locationName and locationName.name or nil
    if locationName== nil then return false end
    if locationName and string.find(locationName, "siege") or string.find(locationName, "Siege") then
        --Print("%s Is in siege, location name is %s", who:GetMapName(), locationName)
        return true
    end
    return false
end