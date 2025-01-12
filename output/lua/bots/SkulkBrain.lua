
Script.Load("lua/bots/PlayerBrain.lua")
Script.Load("lua/bots/SkulkBrain_Data.lua")


class 'SkulkBrain' (PlayerBrain)

SkulkBrain.kUseObjectiveActions = true

function SkulkBrain:Initialize()

    PlayerBrain.Initialize(self)
    self.senses = CreateSkulkBrainSenses()

    --Used, per Skulk bot, to check if it is stuck in number of ways
    self.lastStuckCheckPos = nil
    self.lastStuckCheckTime = 0
    self.isJammedUp = false
    self.lastStuckFallTime = 0
end

function SkulkBrain:GetExpectedPlayerClass()
    return "Skulk"
end

function SkulkBrain:GetExpectedTeamNumber()
    return kAlienTeamType
end

function SkulkBrain:GetObjectiveActions()
    return kSkulkBrainObjectives
end

function SkulkBrain:GetActions()
    return kSkulkBrainActions
end

function SkulkBrain:GetSenses()
    return self.senses
end


SkulkBrain.kSkulkStuckIntervalTime = 0.25
SkulkBrain.kSkulkBotStuckRadius = 1.05
SkulkBrain.kSkulkStuckFallTime = 0.6

function SkulkBrain:Update(bot, move)
    PROFILE("SkulkBrain:Update()")

    if gBotDebug:Get("spam") then
        Print("SkulkBrain:Update")
    end

    local skulk = bot:GetPlayer()

    if PlayerBrain.Update( self, bot, move, skulk ) == false then
        return false
    end

    --[[
        McG: Removed for now, as this might be where the dead-lock state comes from
    if skulk ~= nil and skulk:GetIsAlive() then 

        local time = Shared.GetTime() 

        if self.lastStuckCheckTime == 0 then
            self.lastStuckCheckTime = time
            self.lastStuckCheckPos = skulk:GetOrigin() 
        else

            if self.lastStuckCheckTime + self.kSkulkStuckIntervalTime < time then   --FIXME This puts Bot into loop after actually being stuck in ceiling, unsticking, then plants on ground and stays
                self.isJammedUp = (skulk:GetOrigin() - self.lastStuckCheckPos):GetLength() <= self.kSkulkBotStuckRadius and not skulk:GetIsOnGround() --and not skulk:GetIsInCombat()
                
                self.lastStuckFallTime = self.isJammedUp and time or 0
                self.lastStuckCheckTime = time
                self.lastStuckCheckPos = skulk:GetOrigin()
            end

        end

    end
    --]]

end