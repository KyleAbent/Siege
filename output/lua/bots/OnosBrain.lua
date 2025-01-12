
Script.Load("lua/bots/PlayerBrain.lua")
Script.Load("lua/bots/OnosBrain_Data.lua")

------------------------------------------
--
------------------------------------------
class 'OnosBrain' (PlayerBrain)

OnosBrain.kUseObjectiveActions = true

function OnosBrain:Initialize()

    PlayerBrain.Initialize(self)
    self.senses = CreateOnosBrainSenses()

    self.timeLastStomp = 0
    self.wantsToStomp = false
    self.lastIsStomping = false

end

function OnosBrain:GetExpectedPlayerClass()
    return "Onos"
end

function OnosBrain:GetExpectedTeamNumber()
    return kAlienTeamType
end

function OnosBrain:GetObjectiveActions()
    return kOnosBrainObjectives
end

function OnosBrain:GetActions()
    return kOnosBrainActions
end

function OnosBrain:GetSenses()
    return self.senses
end
