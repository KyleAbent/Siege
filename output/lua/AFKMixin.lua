-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\AFKMixin.lua
--
-- ==============================================================================================

AFKMixin = CreateMixin(AFKMixin)
AFKMixin.type = "AFKMixin"


if Server then

    local kMinAFKTime = 30
    local kAFKWarnPercent = 0.75

    --Init the server setting at file load-time, saves reading this at run-time
    local glAFKSettingTime = 0
    local glAFKKickEnabled = true
    local InitAfkTimeSetting = function()
        glAFKSettingTime = Server.GetConfigSetting("auto_kick_afk_time")

        if glAFKSettingTime == false or glAFKSettingTime == 0 then
            glAFKKickEnabled = false
            Log("Server-Setting: AFK Auto-Kick is disabled")
            return
        end

        if glAFKSettingTime < kMinAFKTime then
            Log("Warning: 'auto_kick_afk_time' has value below allowed minimum, using default value(%ss).", kMinAFKTime)
            glAFKSettingTime = kMinAFKTime
        end
        Log("Server-Setting: AFK auto-kick time:  %s", glAFKSettingTime)
    end
    InitAfkTimeSetting()

    function AFKMixin:__initmixin()

        PROFILE("AFKMixin:__initmixin")
        assert(Server)

        self.timeLastNotAFK = -1
        self.warnedAtTime = false

        self.lastAFKInputPitch = 0
        self.lastAFKInputYaw = 0

        --McG: In an ideal works, ALL server-config settings would be accessible at _file_ load-time (for ServerVM)
        self._serverAfkTime = glAFKSettingTime
        self._serverAfkEnabled = glAFKKickEnabled

        if not self.isVirtual then
            self:AddTimedCallback( self.CheckAFKStatus, 0.5 )
        end

    end

    function AFKMixin:GetAFKTime()
        return (Shared.GetTime() - self.timeLastNotAFK) or 0
    end

    function AFKMixin:Reset()
        self.timeLastNotAFK = -1
        self.warnedAtTime = false
    end
    
    function AFKMixin:CopyPlayerDataFrom(player)
        self.timeLastNotAFK = player.timeLastNotAFK
        self.lastAFKInputPitch = player.lastAFKInputPitch
        self.lastAFKInputYaw = player.lastAFKInputYaw
    end

    function AFKMixin:CheckAFKStatus()

        if Shared.GetCheatsEnabled() then
            return true
        end

        local client = self:GetClient()
        
        if client and ( client:GetIsLocalClient() or client:GetIsVirtual() ) then
        --Disable for localhost clients (e.g. Tutorial, etc.) or Bots, destroys timedcallback
            return false
        end

        --Only apply AFK testing if its enabled and we're not a Bot
        if self._serverAfkEnabled then

            local time = Shared.GetTime()

            --Handle case of TeamSpectator or normal Spec is hands-off watching
            local isFollowing = false
            if self:isa("Spectator") then
                local modeType = self:GetSpectatorModeType()
                isFollowing = 
                    modeType == kSpectatorMode.Following or 
                    modeType == kSpectatorMode.FirstPerson or
                    modeType == kSpectatorMode.KillCam
            end

            local shouldSkip = false
            if Shared.GetThunderdomeEnabled() then
            --Make sure a Round is actually active/running...don't want to kick people waiting during Intermission
                local tdRules = GetThunderdomeRules()
                if tdRules then
                    shouldSkip = ( tdRules:GetMatchState() ~= tdRules.kMatchStates.RoundOne and tdRules:GetMatchState() ~= tdRules.kMatchStates.RoundTwo )
                end
            end
            
            --ignore AFK state if Round has not actually started
            local gameRules = GetGamerules()
            if gameRules then
                local gameState = gameRules:GetGameState()
                local isSkipGameState = gameState <= kGameState.Countdown
                shouldSkip = shouldSkip or isSkipGameState
            end
            
            if shouldSkip and self:isa("ReadyRoomPlayer") then
                self.timeLastNotAFK = time
            end

            if shouldSkip or self.timeLastNotAFK == -1 or isFollowing then
                return true --keep timed-callback alive
            end

            local lastAfkTime = time - (self.timeLastNotAFK or 0)

            if lastAfkTime >= self._serverAfkTime then

                Server.AfkDisconnectClient(client, "")
                Shared.Message("Player " .. self:GetName() .. " kicked for being AFK for " .. self._serverAfkTime .. " seconds")

            elseif lastAfkTime >= self._serverAfkTime * kAFKWarnPercent then

                if not self.warnedAtTime or (time - self.warnedAtTime) > (self._serverAfkTime * kAFKWarnPercent) then

                    Server.SendNetworkMessage(client, "AFKWarning", { timeAFK = lastAfkTime, maxAFKTime = self._serverAfkTime }, true)

                    self.warnedAtTime = time

                end

            end

        end

        return true

    end


    function AFKMixin:OnProcessMove(input)

        PROFILE("AFKMixin:OnProcessMove")

        if self.isVirtual then
            return
        end

        local inputMove = input.move

        local isAfk = 
        (
            inputMove.x == 0 and inputMove.y == 0 and inputMove.z == 0 and
            input.commands == 0 and 
            self.lastAFKInputYaw == input.yaw and
            self.lastAFKInputPitch == input.pitch
        )

        local isFollowing = false
        if self:isa("Spectator") then
            local modeType = self:GetSpectatorModeType()
            isFollowing = 
                modeType == kSpectatorMode.Following or 
                modeType == kSpectatorMode.FirstPerson or
                modeType == kSpectatorMode.KillCam
        end

        if not isAfk or isFollowing then
        --Player is not AFK, update their lastNOT timestamp
            self.timeLastNotAFK = Shared.GetTime()
            self.lastAFKInputYaw = input.yaw
            self.lastAFKInputPitch = input.pitch
        end

    end

end --End-IFserver

-------------------------------------------------------------------------------

local kAFKWarning =
{
    timeAFK = "float",
    maxAFKTime = "float"
}
Shared.RegisterNetworkMessage("AFKWarning", kAFKWarning)


if Client then

    local function OnMessageAFKWarning(message)
    
        PROFILE("AFKMixin:OnMessageAFKWarning")
        
        local warningText = StringReformat(Locale.ResolveString("AFK_WARNING"), { timeAFK = message.timeAFK, maxAFKTime = message.maxAFKTime })
        ChatUI_AddSystemMessage(warningText)    --TODO Add Message display...something more "LOOK AT ME!", etc.
        Client.WindowNeedsAttention()
        
    end
    Client.HookNetworkMessage("AFKWarning", OnMessageAFKWarning)
    
end