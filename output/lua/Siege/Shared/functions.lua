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

function GetIsOriginInHiveRoom(point)
    local location = GetLocationForPoint(point)
    local hivelocation = nil
    local hives = GetEntitiesWithinRange("Hive", point, 999)
    if not hives then return false end

    for i = 1, #hives do  --better way to do this i know
        local hive = hives[i]
        hivelocation = GetLocationForPoint(hive:GetOrigin())
        break
    end

    if location == hivelocation then
        return true
    end

    return false

end



function GetWhereIsSiege(where)
    local location = GetLocationForPoint(where)
    if string.find(location.name, "siege") or string.find(location.name, "Siege") then
        return true
    end
    return false
end


function GetSetupConcluded()
     local gameInfo = GetGameInfoEntity()
     if gameInfo then
        return gameInfo:GetSetupConcluded()
     end
    return false
end

function FindFreeSpace(where, mindistance, maxdistance, infestreq)
     if not mindistance then mindistance = .5 end
     if not maxdistance then maxdistance = 24 end
        for index = 1, math.random(4,8) do
           local extents = LookupTechData(kTechId.Skulk, kTechDataMaxExtents, nil)
           local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
           local spawnPoint = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, where, mindistance, maxdistance, EntityFilterAll())

           if spawnPoint ~= nil then
             spawnPoint = GetGroundAtPosition(spawnPoint, nil, PhysicsMask.AllButPCs, extents)
           end

           local location = spawnPoint and GetLocationForPoint(spawnPoint)
           local locationName = location and location:GetName() or ""
           local wherelocation = GetLocationForPoint(where)
           wherelocation = wherelocation and wherelocation.name or nil
           local sameLocation = spawnPoint ~= nil and locationName == wherelocation

           if infestreq then
             sameLocation = sameLocation and GetIsPointOnInfestation(spawnPoint)
           end

           if spawnPoint ~= nil and sameLocation   then
              return spawnPoint
           end
       end
--           Print("No valid spot found for FindFreeSpace")
          if infestreq and not GetIsPointOnInfestation(where) then
             if Server then CreateEntity(Cyst.kMapName, FindFreeSpace(where,1, 6),  2) end
             --For now anyway, bite me. Remove later? :X or tres spend. Who knows right now. I wanna see this in action.
          end

           return where
end