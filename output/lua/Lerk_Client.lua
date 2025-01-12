-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Lerk_Client.lua
--
-- James Gu (twiliteblue), Yuuki (community contribution)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- Lerk camera tilt variables
local gEnableTilt = true
Lerk.kCameraRollTilt_YawModifier = 0.4
Lerk.kCameraRollTilt_StrafeModifier = 0.05
Lerk.kCameraRollSpeedModifier = 0.8

Lerk.kFlySoundSpeedMax = 5 -- Sound volume should max out at this speed

function Lerk:GetHealthbarOffset()
    return 0.7
end

function Lerk:UpdateMisc(input)

    Alien.UpdateMisc(self, input)

    local totalCameraRoll = 0

    if math.abs(self.currentCameraRoll) < 0.0001 then
        self.currentCameraRoll = 0
    end
    
    if math.abs(self.goalCameraRoll) < 0.0001 then
        self.goalCameraRoll = 0
    end

    if self:GetIsOnGround() then
        self.goalCameraRoll = 0
    else
        local strafeDirection = 0

        if input.move.x > 0 then
            strafeDirection = -1
        elseif input.move.x < 0 then
            strafeDirection = 1
        end            

        totalCameraRoll = self.goalCameraRoll + strafeDirection * Lerk.kCameraRollTilt_StrafeModifier
        
    end    
    self.currentCameraRoll = LerpGeneric(self.currentCameraRoll, totalCameraRoll, math.min(1, input.time * Lerk.kCameraRollSpeedModifier))
    
end

function Lerk:GetHeadAttachpointName()
    return "Head_Tongue_02"
end

function OnCommandLerkViewTilt(enableTilt)
    gEnableTilt = enableTilt ~= "false"    
end

local kMinSoundSpeed = kLerkMinSoundSpeed
local kMinGlideSpeed = kLerkMinGlideSpeed
local function UpdateFlySound(self)
    
    if self:GetIsAlive() then

        local flySound = Shared.GetEntity(self.flySoundId)
        if not flySound then
            return
        end

        if self:GetIsOnGround() then
            flySound:SetParameter("speed", 0, 20)
        else

            if self.lastOrigin == nil then
                self.lastOrigin = self:GetOrigin()
            end

            self.lastOrigin = self:GetOrigin() --update

            local velocityLen = self:GetVelocityLength()
            if velocityLen <= kMinGlideSpeed then
                flySound:SetParameter("speed", 0, 20)
            else
                local speedPercentage = velocityLen / self.kFlySoundSpeedMax
                speedPercentage = Clamp( speedPercentage, kMinSoundSpeed, 1)
                local speed = LerpNumber(kMinSoundSpeed, 1, speedPercentage)

                flySound:SetParameter("speed", speed, 10)
                self.lastFlySpeed = speed
            end

        end

    end

end

function Lerk:OnUpdate(deltaTime) --for all other players
    UpdateFlySound(self)
    Alien.OnUpdate(self, deltaTime)
end

function Lerk:OnProcessMove(input)  --for local player
    UpdateFlySound(self)
    Alien.OnProcessMove(self, input)
end

Event.Hook("Console_lerk_view_tilt",   OnCommandLerkViewTilt)