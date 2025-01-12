
Script.Load("lua/bots/PlayerBrain.lua")
Script.Load("lua/bots/FadeBrain_Data.lua")

------------------------------------------
--
------------------------------------------
class 'FadeBrain' (PlayerBrain)

FadeBrain.kUseObjectiveActions = true

function FadeBrain:Initialize()

    PlayerBrain.Initialize(self)
    self.senses = CreateFadeBrainSenses()

    self.timeOfBlink = 0

    self.timeOfMetab = 0

    --Triggered via GroundMovemixin when landing on ground
    self.onLandedTrigger = false
    self.blinkSequenceActive = false
    self.blinkJumpTick = 0

end

function FadeBrain:OnGroundLanded()
    self.onLandedTrigger = true
end

function FadeBrain:ResetBlinkSequence()
    self.onLandedTrigger = false
    self.blinkSequenceActive = false
    self.blinkJumpTick = 0
end

function FadeBrain:GetExpectedPlayerClass()
    return "Fade"
end

function FadeBrain:GetExpectedTeamNumber()
    return kAlienTeamType
end

function FadeBrain:GetObjectiveActions()
    return kFadeBrainObjectives
end

function FadeBrain:GetActions()
    return kFadeBrainActions
end

function FadeBrain:GetSenses()
    return self.senses
end
