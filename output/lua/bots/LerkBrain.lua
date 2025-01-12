
Script.Load("lua/bots/PlayerBrain.lua")
Script.Load("lua/bots/LerkBrain_Data.lua")



class 'LerkBrain' (PlayerBrain)

LerkBrain.kUseObjectiveActions = true

function LerkBrain:Initialize()

    PlayerBrain.Initialize(self)
    self.senses = CreateLerkBrainSenses()

    self.lastStuckCheckTime = 0
    self.lastStuckCheckPos = nil
    self.isPancaking = false
    self.lastPancakeTime = 0
    self.timeLastSpore = 0
    self.timeLastUmbra = 0
    self.isRetreatingForEnergy = false

    self.savedPathPoints = nil
    self.savedPathPointsIt = nil
    self.lastAttackEntityId = Entity.invalidId
end

function LerkBrain:GetExpectedPlayerClass()
    return "Lerk"
end

function LerkBrain:GetExpectedTeamNumber()
    return kAlienTeamType
end

function LerkBrain:GetObjectiveActions()
    return kLerkBrainObjectives
end

function LerkBrain:GetActions()
    return kLerkBrainActions
end

function LerkBrain:GetSenses()
    return self.senses
end

LerkBrain.kLerkBotStuckRadius = 1.15
LerkBrain.kLerkStuckIntervalTime = 0.25
LerkBrain.kLerkPancakeTime = 0.6

function LerkBrain:Update(bot, move)
    PROFILE("LerkBrain:Update()")

    if gBotDebug:Get("spam") then
        Print("LerkBrain:Update")
    end

    local lerk = bot:GetPlayer()

    if PlayerBrain.Update( self, bot, move, lerk ) == false then
        return false
    end

    --[[
        McG: removed for now, as this might be why lerks glide/flap into the ground too often
    if lerk ~= nil and lerk:GetIsAlive() then 

        local time = Shared.GetTime() 

        if self.lastStuckCheckTime == 0 then
            self.lastStuckCheckTime = time
            self.lastStuckCheckPos = lerk:GetOrigin() 
        else

            if self.lastStuckCheckTime + self.kLerkStuckIntervalTime < time then 
                self.isPancaking = (lerk:GetOrigin() - self.lastStuckCheckPos):GetLength() <= self.kLerkBotStuckRadius and not lerk:GetIsOnGround() -- and not lerk:GetIsInCombat()
                
                self.lastPancakeTime = self.isPancaking and time or 0
                self.lastStuckCheckTime = time
                self.lastStuckCheckPos = lerk:GetOrigin()
            end

        end

    end
    --]]

end