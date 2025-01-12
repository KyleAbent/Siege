-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\MedPack.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/DropPack.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/TeamMixin.lua")

class 'MedPack' (DropPack)

MedPack.kMapName = "medpack"

MedPack.kModelNameWinter = PrecacheAsset("seasonal/holiday2012/models/gift_medkit_01.model")
MedPack.kModelName = PrecacheAsset("models/marine/medpack/medpack.model")

local function GetModelName()
    return GetSeason() == Seasons.kWinter and MedPack.kModelNameWinter or MedPack.kModelName
end

MedPack.kHealth = kMedpackHeal

MedPack.kPickupDelay = kMedpackPickupDelay

local networkVars =
{
}

function MedPack:OnInitialized()

    DropPack.OnInitialized(self)
    
    self:SetModel(GetModelName())
    
end

function MedPack:OnTouch(recipient)

    if not recipient.timeLastMedpack or recipient.timeLastMedpack + self.kPickupDelay <= Shared.GetTime() then

        local oldHealth = recipient:GetHealth()
        recipient:AddHealth(MedPack.kHealth, false, true)
        recipient:AddRegeneration()
        recipient.timeLastMedpack = Shared.GetTime()

        self:TriggerEffects("medpack_pickup", { effecthostcoords = self:GetCoords() })

        -- Handle Stats
        if Server then

            local commanderStats = StatsUI_GetStatForCommander(StatsUI_GetMarineCommmaderSteamID())

            -- If the medpack hits immediatly expireTime is 0
            if ConditionalValue(self.expireTime == 0, Shared.GetTime(), self.expireTime - kItemStayTime) + 0.025 > Shared.GetTime() then
                commanderStats["medpack"].hitsAcc = commanderStats["medpack"].hitsAcc + 1
            end

            commanderStats["medpack"].misses = commanderStats["medpack"].misses - 1
            commanderStats["medpack"].picks = commanderStats["medpack"].picks + 1
            commanderStats["medpack"].refilled = commanderStats["medpack"].refilled + recipient:GetHealth() - oldHealth

        end

    end
    
end

function MedPack:GetIsValidRecipient(recipient)
	
	if not recipient:isa("Marine") then
		return false
	end
		
    return recipient:GetIsAlive() and recipient:GetHealth() < recipient:GetMaxHealth() and (not recipient.timeLastMedpack or recipient.timeLastMedpack + self.kPickupDelay <= Shared.GetTime())
	
end


Shared.LinkClassToMap("MedPack", MedPack.kMapName, networkVars, false)