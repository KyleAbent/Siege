-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Skulk_Client.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Skulk.kCameraRollSpeedModifier = 0.5
Skulk.kCameraRollTiltModifier = 0.05

Skulk.kViewModelRollSpeedModifier = 7
Skulk.kViewModelRollTiltModifier = 0.15

function Skulk:GetHealthbarOffset()
    return 0.8
end

function Skulk:GetHeadAttachpointName()
    return "Bone_Tongue"
end

local function UpdateCameraTilt(self, deltaTime)

    if self.currentCameraRoll == nil then
        self.currentCameraRoll = 0
    end
    if self.goalCameraRoll == nil then
        self.goalCameraRoll = 0
    end
    if self.currentViewModelRoll == nil then
        self.currentViewModelRoll = 0
    end
    
    -- View rotation disabled
    self.goalCameraRoll = 0
    
    self.currentCameraRoll = LerpGeneric(self.currentCameraRoll, self.goalCameraRoll * Skulk.kCameraRollTiltModifier, math.min(1, deltaTime * Skulk.kCameraRollSpeedModifier))
    self.currentViewModelRoll = LerpGeneric(self.currentViewModelRoll, self.goalCameraRoll, math.min(1, deltaTime * Skulk.kViewModelRollSpeedModifier))

end

function Skulk:OnProcessIntermediate(input)

    Alien.OnProcessIntermediate(self, input)
    UpdateCameraTilt(self, input.time)

end

function Skulk:OnProcessSpectate(deltaTime)

    Alien.OnProcessSpectate(self, deltaTime)
    UpdateCameraTilt(self, deltaTime)

end


function Skulk:GetSpeedDebugSpecial()
    return 0
end

function Skulk:ModifyViewModelCoords(viewModelCoords)

    if self.currentViewModelRoll ~= 0 then

        local roll = self.currentViewModelRoll and self.currentViewModelRoll * Skulk.kViewModelRollTiltModifier or 0
        local rotationCoords = Angles(0, 0, roll):GetCoords()
        
        return viewModelCoords * rotationCoords
    
    end
    
    return viewModelCoords

end
