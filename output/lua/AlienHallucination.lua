-- ======= Copyright (c) 2003-2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\AlienHallucination.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/PlayerHallucinationMixin.lua")
Script.Load("lua/SoftTargetMixin.lua")
Script.Load("lua/OrdersMixin.lua")

-- This is just for convenience, so bot brain action code can just reference personality without worry of nil references
-- i.e. bot.helpAbility * weight wouldnt error
local function InitializePersonality(hallucination)

    hallucination.aimAbility = 0
    hallucination.helpAbility = 0
    hallucination.aggroAbility = 0
    hallucination.sneakyAbility = 0
    hallucination.personalityLabel = "Hallucination"

end

class "SkulkHallucination" (Skulk)
SkulkHallucination.kMapName = "skulkHallucination"

function SkulkHallucination:OnCreate()
    Skulk.OnCreate(self)
    self.isHallucination = true

    InitializePersonality(self)

    InitMixin(self, SoftTargetMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })

    if Server then
        InitMixin(self, PlayerHallucinationMixin)
    end
end

function SkulkHallucination:SetEmulation(player)
    self:SetName(player:GetName())
    self:SetHallucinatedClientIndex(player:GetClientIndex())

    if player:isa("Alien") and player.GetVariant then
        self:SetVariant(player:GetVariant())
        self:ForceUpdateModel()
    end
end

function SkulkHallucination:GetClassNameOverride()
    return "Skulk"
end

function SkulkHallucination:GetMapBlipType()
    return kMinimapBlipType.Skulk
end

Shared.LinkClassToMap("SkulkHallucination", SkulkHallucination.kMapName, {})

class "GorgeHallucination" (Gorge)
GorgeHallucination.kMapName = "GorgeHallucination"

function GorgeHallucination:OnCreate()
    Gorge.OnCreate(self)
    self.isHallucination = true

    InitializePersonality(self)

    InitMixin(self, SoftTargetMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })

    if Server then
        InitMixin(self, PlayerHallucinationMixin)
    end
end

function GorgeHallucination:SetEmulation(player)
    self:SetName(player:GetName())
    self:SetHallucinatedClientIndex(player:GetClientIndex())

    if player:isa("Alien") and player.GetVariant then
        self:SetVariant(player:GetVariant())
        self:ForceUpdateModel()
    end
end

function GorgeHallucination:GetClassNameOverride()
    return "Gorge"
end

function GorgeHallucination:GetMapBlipType()
    return kMinimapBlipType.Gorge
end

Shared.LinkClassToMap("GorgeHallucination", GorgeHallucination.kMapName, {})

class "LerkHallucination" (Lerk)
LerkHallucination.kMapName = "lerkHallucination"

function LerkHallucination:OnCreate()
    Lerk.OnCreate(self)
    self.isHallucination = true

    InitializePersonality(self)

    InitMixin(self, SoftTargetMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })

    if Server then
        InitMixin(self, PlayerHallucinationMixin)
    end
end

function LerkHallucination:SetEmulation(player)
    self:SetName(player:GetName())
    self:SetHallucinatedClientIndex(player:GetClientIndex())

    if player:isa("Alien") and player.GetVariant then
        self:SetVariant(player:GetVariant())
        self:ForceUpdateModel()
    end
end

function LerkHallucination:GetClassNameOverride()
    return "Lerk"
end

function LerkHallucination:GetMapBlipType()
    return kMinimapBlipType.Lerk
end

Shared.LinkClassToMap("LerkHallucination", LerkHallucination.kMapName, {})

class "FadeHallucination" (Fade)
FadeHallucination.kMapName = "fadeHallucination"

function FadeHallucination:OnCreate()
    Fade.OnCreate(self)
    self.isHallucination = true

    InitializePersonality(self)

    InitMixin(self, SoftTargetMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })

    if Server then
        InitMixin(self, PlayerHallucinationMixin)
    end
end

function FadeHallucination:SetEmulation(player)
    self:SetName(player:GetName())
    self:SetHallucinatedClientIndex(player:GetClientIndex())

    if player:isa("Alien") and player.GetVariant then
        self:SetVariant(player:GetVariant())
        self:ForceUpdateModel()
    end
end

function FadeHallucination:GetClassNameOverride()
    return "Fade"
end

function FadeHallucination:GetMapBlipType()
    return kMinimapBlipType.Fade
end

Shared.LinkClassToMap("FadeHallucination", FadeHallucination.kMapName, {})

class "OnosHallucination" (Onos)
OnosHallucination.kMapName = "onosHallucination"

function OnosHallucination:OnCreate()
    Onos.OnCreate(self)
    self.isHallucination = true

    InitializePersonality(self)

    InitMixin(self, SoftTargetMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })

    if Server then
        InitMixin(self, PlayerHallucinationMixin)
    end
end

function OnosHallucination:SetEmulation(player)
    self:SetName(player:GetName())
    self:SetHallucinatedClientIndex(player:GetClientIndex())

    if player:isa("Alien") and player.GetVariant then
        self:SetVariant(player:GetVariant())
        self:ForceUpdateModel()
    end
end

function OnosHallucination:GetClassNameOverride()
    return "Onos"
end

function OnosHallucination:GetMapBlipType()
    return kMinimapBlipType.Onos
end

Shared.LinkClassToMap("OnosHallucination", OnosHallucination.kMapName, {})