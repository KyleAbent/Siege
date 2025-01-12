-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/PlayerScreen/Customize/CustomizeSceneCameras.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
--    TODO Add doc/descriptor
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


local kUpVec = Vector(0,1,0)


---@class CameraTransition
class "CameraTransition"

 
function CameraTransition:Init( targetView, fromView, curOrg, curTarget, curFov, isTeamViewChange, clientAspect )
    --[[
    Log("CameraTransition:Init()")
    Log("       targetView: %s", targetView)
    Log("         fromView: %s", fromView)
    Log("           curOrg: %s", curOrg)
    Log("        curTarget: %s", curTarget)
    Log("           curFov: %s", curFov)
    Log(" isTeamViewChange: %s", isTeamViewChange)
    Log("     clientAspect: %s", clientAspect)
    --]]
    assert( gCustomizeSceneData.kCameraViewPositions[targetView] )

    local targetViewData = gCustomizeSceneData.kCameraViewPositions[targetView]
    self.destOrigin = targetViewData.origin --Targeted Camera position
    self.destTarget = targetViewData.target --Targeted "LookAt" point
    self.destFov = GetCustomizeCameraViewTargetFov( targetViewData.fov, clientAspect )

    self.animTime = targetViewData.animTime

    --Time to only change lookat-target, and not actually move the camera position
    --movement delay is to allow for Camera rotation first
    self.camMoveDelayTime = targetViewData.startMoveDelay and targetViewData.startMoveDelay or 0
    self.startTime = Shared.GetTime()

    self.interruptTransition = false

    if fromView then
        local fromViewData = gCustomizeSceneData.kCameraViewPositions[fromView]
        self.origin = fromViewData.origin
        self.originTarget = fromViewData.target
        self.originFov = GetCustomizeCameraViewTargetFov( fromViewData.fov, clientAspect )
    else
        self.origin = curOrg
        self.originTarget = curTarget
        self.originFov = curFov

        --denotes this has no fromView label, it was mid-transition when new view
        --transition was triggered. Thus, derived from active camrea data "mid-flight"
        self.interruptTransition = true
    end

    self.totalDist = self.origin:GetDistance( self.destOrigin )

    self.activeOrigin = nil
    self.activeTarget = nil

    --Cache the requested target-view for cases when transitioning from one team to another's views
    self.requestedTargetView = targetView

    self.isTeamViewChange = isTeamViewChange

    self.targetView = isTeamViewChange and gCustomizeSceneData.kTeamViews.TeamTransition or targetView
    self.originView = fromView

    self.callbackActivationDist = targetViewData.activationDist and targetViewData.activationDist or 0

    --Must init Coords to origin, otherwise interruptTransition would cause huge jitter
    self.coords = Coords.GetLookAt( self.origin, self.originTarget, kUpVec )
    self.fov = self.originFov

    self.complete = false

    self.isTargetDefault = targetView == gCustomizeSceneData.KDefaultViewLabel

    self.distanceActivatedCallback = nil
    self.triggeredCallback = false

end

function CameraTransition:SetDistanceActivationCallback( callback )
    self.distanceActivatedCallback = callback
end

function CameraTransition:GetTargetView()
    return self.targetView
end

function CameraTransition:GetIsInterrupt()
    return self.interruptTransition
end

function CameraTransition:GetOriginView()
    return self.originView
end

function CameraTransition:GetTargetData()
    return { origin = self.destOrigin, target = self.destTarget, fov = self.destFov }
end

function CameraTransition:GetOriginData()
    return { origin = self.origin, target = self.originTarget, fov = self.originFov }
end

function CameraTransition:TriggerCallback()
    if self.distanceActivatedCallback then
        self:distanceActivatedCallback( self.targetView )
    end
end

function CameraTransition:GetCoords()
    return self.coords
end

function CameraTransition:GetFov()
    return self.fov
end

--Special-case handler for when moving from one Team-view to another.
--effectively "resets" this transition to eliminate need to make a new one
function CameraTransition:HandleTeamViewTransition(scene)
    local coords = self:GetCoords()
    local fov = self:GetFov()
    local targ = self:GetTargetData()

    self:Init( self.requestedTargetView, nil, coords.origin, targ.target, targ.fov, false, scene.screenAspect )
end

--FIXME This needs to handle camera YAW separate, because things will get fucky otherwise (no smooth turning/panning, etc)
--FIXME Camera YAW _MUST_ be controled, otherwise it may rotate towards "empty" parts of the customize level!
function CameraTransition:Update(deltaTime, scene)

    --local accel = self.destTarget:GetDistance(self.prevLookAt) <= 1 and 0.095 or 0.034
    local accel = 0.105
    if self.isTeamViewChange then
        accel = 0.075
    end
    --TODO Lerp this slightly increasing nearer to target

    local preDist = self.coords.origin:GetDistance( self.destOrigin )
    local positionUpdateAllowed = self.startTime + self.camMoveDelayTime < Shared.GetTime()
    positionUpdateAllowed = true

    local distPerct = preDist / self.totalDist
    local targDistPerct = self.prevLookAt and ( self.destTarget:GetDistance(self.prevLookAt) ) or 1 --self.destTarget:GetDistance(self.originTarget)
    --FIXME compute self.prevLookAt value
    ----TODO for above, ensure lookat-rotation is ALWAYS positive ( to force camera to always look "into" the scene)

    local lookTarget = deltaTime * distPerct * GetNormalizedVector( self.coords.zAxis ) + self.destTarget

    local newOrigin
    if positionUpdateAllowed then
        newOrigin = self.coords.origin + ( self.destOrigin - self.coords.origin ) * (deltaTime + accel) 
    else
        newOrigin = self.origin
    end

    if positionUpdateAllowed then
        self.fov = Lerp( self.fov, self.destFov, deltaTime + accel )
    end

    local targetDist = self.coords.origin:GetDistance( self.destOrigin )

    if self.distanceActivatedCallback ~= nil then

        if targetDist <= self.callbackActivationDist and not self.triggeredCallback then

            self:TriggerCallback()
            self.triggeredCallback = true

            --Special case for team-transition view(s). Only applies when targetview doesn't match desired team-view
            if self.isTeamViewChange then --FIXME This is not ALWAYS true/false
                self:HandleTeamViewTransition(scene)
                return --exit out immediately and refresh on next update
            end

        end

    end

    self.coords = Coords.GetLookAt( newOrigin, lookTarget, kUpVec )

    if distPerct < 0.00075 then     --FIXME We're hitting this before FOV is finished transitioning
    --Cheesy, but it works. Only causes slight "snap" when very close to visible focused object (e.g. shoulder patches view)
        self.coords = Coords.GetLookAt( self.destOrigin, self.destTarget, kUpVec )
        --self.fov = self.destFov
        self.complete = true
    end

    scene:SetCameraPerspective( self.coords, self.fov )

    return self.complete

end

