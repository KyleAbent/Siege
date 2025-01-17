Script.Load("lua/ReadyRoomPlayer.lua")

class 'ReadyRoomEmbryo' (ReadyRoomPlayer)

ReadyRoomEmbryo.kMapName = "ready_room_embryo"

local networkVars =
{
    prevGestationTechId = "private enum kTechId"
}

function ReadyRoomEmbryo:GetPreviousGestationTechId()
    return self.prevGestationTechId
end

if Server then

    function ReadyRoomEmbryo:GetGestationTechId()
        return self.prevGestationTechId
    end

    function ReadyRoomEmbryo:SetPreviousGestationTechId(techId)
        self.prevGestationTechId = techId
    end

    function ReadyRoomEmbryo:OnInitialized()
        ReadyRoomPlayer.OnInitialized(self)
        self:SetPreviousGestationTechId(kTechId.None)
    end

    function ReadyRoomEmbryo:CopyPlayerDataFrom( player )
        ReadyRoomPlayer.CopyPlayerDataFrom( self, player )
        Alien.CopyPlayerDataForReadyRoomFrom( self, player )
    end

    function ReadyRoomEmbryo:PerformEject()
        if self:GetIsOnGround() and not self:GetIsOnEntity() then
            
            self:TriggerEffects("player_end_gestate")
            
            local gestationClass = self.gestationClass or Skulk.kMapName
            local newPlayer = self:Replace( gestationClass )
            newPlayer:SetCameraDistance(0)

            local capsuleHeight, capsuleRadius = self:GetTraceCapsule()
            local newAlienExtents = LookupTechData(newPlayer:GetTechId(), kTechDataMaxExtents)

            if not GetHasRoomForCapsule(newAlienExtents, self:GetOrigin() + Vector(0, newAlienExtents.y + Embryo.kEvolveSpawnOffset, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, nil, EntityFilterTwo(self, newPlayer)) then

                local spawnPoint = GetRandomSpawnForCapsule(newAlienExtents.y, capsuleRadius, self:GetModelOrigin(), 0.5, 5, EntityFilterOne(self))

                if spawnPoint then
                    newPlayer:SetOrigin(spawnPoint)
                end

            end

            newPlayer:DropToFloor()
            newPlayer:SetHatched()

            newPlayer:TriggerEffects("egg_death")
            newPlayer:TriggerEffects("fireworks")

            return
        end
    end


    function ReadyRoomEmbryo:HandleButtons( input )
        ReadyRoomPlayer.HandleButtons( self, input )

        if bit.band(input.commands, Move.Drop) ~= 0 then
            self:PerformEject()
        end
    end
end


Shared.LinkClassToMap("ReadyRoomEmbryo", ReadyRoomEmbryo.kMapName, networkVars)