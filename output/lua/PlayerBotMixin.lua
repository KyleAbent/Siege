-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua/PlayerBotMixin.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com ================

PlayerBotMixin = CreateMixin(PlayerBotMixin)
PlayerBotMixin.type = "BotDebug"

PlayerBotMixin.expectedMixins =
{
}

PlayerBotMixin.networkVars =
{
    botEntityId = "entityid",
    moveTargetPos = "vector",
    nextMoveTargetPos = "vector", -- Next Path Point
    viewTargetPos = "vector",
}

if Server then

    function PlayerBotMixin:UpdateBotEntityId()

        if self.client and self.client.bot then
            self.botEntityId = self.client.bot:GetId()
        else
            self.botEntityId = Entity.invalidId
        end

    end

    function PlayerBotMixin:UpdateMoveTargetPos()

        local isDebugTarget = self.client and self.client.bot and GetBotDebuggingManager():GetIsBotTargetted(self.client.bot:GetId())
        if not isDebugTarget then return end

        local botMotion = self.client.bot:GetMotion()
        if not botMotion then return end

        if botMotion.desiredMoveDirection then -- Desired move direction overrides the move position
            self.moveTargetPos = self:GetOrigin() + botMotion.desiredMoveDirection
        elseif botMotion.desiredMoveTarget then
            self.moveTargetPos = botMotion.desiredMoveTarget
        else
            self.moveTargetPos = Vector(0,0,0)
        end

        -- Update path point
        if botMotion.currPathPoints then

            for i = botMotion.currPathPointsIt, #botMotion.currPathPoints do
                local pathPoint = botMotion.currPathPoints[i]
                self.nextMoveTargetPos = pathPoint
                break
            end
        else
            self.nextMoveTargetPos = Vector(0,0,0)
        end

        -- Update move target pos
        if botMotion.desiredViewTarget then
            self.viewTargetPos = botMotion.desiredViewTarget
        else
            self.viewTargetPos = Vector(0,0,0)
        end

    end

    function PlayerBotMixin:OnProcessMove(input)
        self:UpdateBotEntityId()
        self:UpdateMoveTargetPos()
    end

end

-- Constants for drawing debug primitives
local kAimVectorDistance = 1
local kAimVectorLifetime = 0.0
local kMoveTargetLifetime = 0.0


if Client then

    function PlayerBotMixin:OnUpdateRender()

        if gBotDebugWindow ~= nil and
                gBotDebugWindow:GetTargetedBotId() ~= Entity.invalidId and
                gBotDebugWindow:GetTargetedBotId() == self.botEntityId then

            -- Draw box where bot wants to move to
            if self.moveTargetPos ~= Vector(0,0,0) then
                local minPoint = self.moveTargetPos
                local maxPoint = minPoint + Vector(0, 5, 0)
                local extents = Vector(0.5, 1, 0.5)
                DebugBox(minPoint, maxPoint, extents, kMoveTargetLifetime, 1, 1, 1, 1)
                DebugLine(self:GetOrigin(), maxPoint, kMoveTargetLifetime, 1, 1, 1, 1)
            end

            -- Draw points inbetween current position and target position
            if self.nextMoveTargetPos ~= Vector(0,0,0) then
                DebugPoint(self.nextMoveTargetPos, 0.2, kMoveTargetLifetime,1, 1, 1, 1)
            end

            -- Draw view target line
            if self.viewTargetPos ~= Vector(0,0,0) then
                DebugLine(self:GetEyePos(), self.viewTargetPos, kMoveTargetLifetime, 0, 1, 0, 1)
            else -- If we dont have one, just show current view angle (short)
                local viewVec = self:GetViewAngles():GetCoords().zAxis

                local lineStart = self:GetEyePos()
                local lineEnd = lineStart + (viewVec * kAimVectorDistance)

                DebugLine(lineStart, lineEnd, kAimVectorLifetime, 1, 1, 1, 1)
            end

        end

    end

end
