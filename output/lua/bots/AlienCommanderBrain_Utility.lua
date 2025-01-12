-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/AlienCommanderBrain_Utility.lua
--
-- Created by: Darrell Gentry (darrell@unkownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function GetIsTunnelEntranceValidForTravel(entrance)
    return entrance:GetIsBuilt() and entrance:GetIsConnected() and not entrance.killWithoutCollapse and entrance:GetOtherEntrance() ~= nil
end

function GetLocationHasTunnelEntrance(tunnelEntrances, locationId)

    if not locationId or locationId == 0 then return false end

    for _, tunnelEntrance in ipairs(tunnelEntrances) do
        if tunnelEntrance:GetLocationId() == locationId then
            return true
        end
    end

    return false

end

function GetCystForPoint(senses, point)

    local cystForPoint
    local cysts = senses:Get("cysts")
    for _, entity in ipairs(cysts) do
        if WouldCystInfestPoint(entity, point) then
            cystForPoint = entity
            break
        end
    end

    return cystForPoint

end

function WouldCystInfestPoint(cyst, point)

    local radius = point:GetDistanceTo(cyst:GetOrigin())
    local coords = cyst:GetCoords()

    return radius <= kInfestationRadius and
        math.abs( coords.yAxis:DotProduct( point - coords.origin ) ) < 1

end

function GetCystBuildPos(aroundPos)

    local extents = GetExtents(kTechId.Cyst)
    local cystPos = GetRandomSpawnForCapsule(
            extents.y, extents.x,
            aroundPos + Vector(0,0.5,0),
            1, 4,
            EntityFilterAll(), GetIsPointOffInfestation, 1)

    return cystPos

end

function NearestFriendlyHiveTo(point, teamNumber)

    local hives = GetEntitiesAliveForTeam( "Hive", teamNumber)

    local dist, hive = GetMinTableEntry( hives,
            function(hive)
                if hive:GetIsBuilt() then
                    return point:GetDistance( hive:GetOrigin() )
                end
            end)

    return { entity = hive, distance = dist }
end

function CooldownPassedForTunnelDropInLocation(brain, locationName)

    local timeLastTunnelDeathForLocation = brain:GetLastTunnelDeathTime(locationName)
    local timeSinceLastTunnelDeathForLocation = Shared.GetTime() - timeLastTunnelDeathForLocation
    return timeSinceLastTunnelDeathForLocation >= brain.kTunnelDeathRedropDelay

end
