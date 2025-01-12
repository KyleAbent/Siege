-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\WebsAbility.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'WebsAbility' (StructureAbility)

local kMapOrigin = Vector(0,0,0)

WebsAbility.kFirstDropRange = kGorgeCreateDistance
WebsAbility.kSecondDropRange = WebsAbility.kFirstDropRange * 3

WebsAbility.kGroundedMinDistance = 0.5
WebsAbility.kGroundedNormalThreshold = 0.5

function WebsAbility:GetEnergyCost()
    return kDropStructureEnergyCost
end

function WebsAbility:GetGhostModelName(ability)
    return Bomb.kModelName
end

function WebsAbility:GetDropStructureId()
    return kTechId.Web
end

function WebsAbility:AllowBackfacing()
    return true
end

function WebsAbility:GetSuffixName()
    return "web"
end

function WebsAbility:GetDropClassName()
    return "Web"
end

function WebsAbility:GetDropRange(lastClickedPosition)
    if not lastClickedPosition or lastClickedPosition == kMapOrigin then
        return WebsAbility.kFirstDropRange
    else
        return WebsAbility.kSecondDropRange
    end
end

function WebsAbility:OnStructureCreated(structure, lastClickedPosition)
    structure:SetEndPoint(lastClickedPosition)
end

function WebsAbility:GetIsPositionValid(displayOrigin, player, normal, lastClickedPosition, lastClickedPositionNormal, entity)

    local newPoint = displayOrigin + normal * 0.1
    local valid = lastClickedPosition == nil

    if lastClickedPosition and lastClickedPositionNormal and displayOrigin and newPoint ~= lastClickedPosition
       and (lastClickedPosition - newPoint):GetLength() < kMaxWebLength and (lastClickedPosition - newPoint):GetLength() > kMinWebLength then
    
        -- check if we can create a web between the 2 point
        local webTrace = Shared.TraceRay(lastClickedPosition, newPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAll())

        if webTrace.fraction >= 0.99 then

            local groundDistCheckMaxDistance = Vector(0, 1000, 0)

            local trace = Shared.TraceRay(newPoint, newPoint - groundDistCheckMaxDistance, CollisionRep.Move, PhysicsMask.Bullets, EntityFilterAll())
            local trace2 = Shared.TraceRay(lastClickedPosition, lastClickedPosition - groundDistCheckMaxDistance, CollisionRep.Move, PhysicsMask.Bullets, EntityFilterAll())
            local lastClickedGroundPos = trace2.endPoint
            local newGroundPos = trace.endPoint

            local isLastPointGrounded = (lastClickedPositionNormal.y > WebsAbility.kGroundedNormalThreshold)
            local isNewPointGrounded = (normal.y > WebsAbility.kGroundedNormalThreshold)

            if (isLastPointGrounded ~= isNewPointGrounded) or
               (not isLastPointGrounded and not isNewPointGrounded) then

                local lastPointGroundDistance = math.abs(lastClickedPosition.y - lastClickedGroundPos.y)
                local newPointGroundDistance = math.abs(newPoint.y - newGroundPos.y)

                valid = (lastPointGroundDistance > WebsAbility.kGroundedMinDistance or newPointGroundDistance > WebsAbility.kGroundedMinDistance)

            elseif isNewPointGrounded and isLastPointGrounded and
                math.abs(newPoint.y - lastClickedPosition.y) <= WebsAbility.kGroundedMinDistance then

                valid = false
            else
                valid = true
            end

        end

    end

    return valid and (not entity or entity:isa("Tunnel") or entity:isa("Infestation")) and lastClickedPosition ~= kMapOrigin
    
end

function WebsAbility:GetDropMapName()
    return Web.kMapName
end

local kWebOffset = 0.1
function WebsAbility:ModifyCoords(coords)
    coords.origin = coords.origin + coords.yAxis * kWebOffset
end
