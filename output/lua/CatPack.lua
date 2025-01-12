-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\CatPack.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
 
Script.Load("lua/DropPack.lua")

class 'CatPack' (DropPack)
CatPack.kMapName = "catpack"

CatPack.kModelName = PrecacheAsset("models/marine/catpack/catpack.model")
CatPack.kPickupSound = PrecacheAsset("sound/NS2.fev/marine/common/catalyst")

function CatPack:OnInitialized()

    DropPack.OnInitialized(self)
    
    self:SetModel(CatPack.kModelName)
    	
end

function CatPack:OnTouch(recipient)

    recipient:ApplyCatPack()
    self:TriggerEffects("catpack_pickup", { effecthostcoords = self:GetCoords() })

    -- Handle Stats
    if Server then

        local commanderStat = StatsUI_GetStatForCommander(StatsUI_GetMarineCommmaderSteamID())
        if not commanderStat then
            return
        end

        commanderStat["catpack"].misses = commanderStat["catpack"].misses - 1
        commanderStat["catpack"].picks  = commanderStat["catpack"].picks + 1
    end
    
end

--
--Any Marine is a valid recipient.
--
function CatPack:GetIsValidRecipient(recipient)
    return recipient.GetCanUseCatPack and recipient:GetCanUseCatPack()
end

Shared.LinkClassToMap("CatPack", CatPack.kMapName)