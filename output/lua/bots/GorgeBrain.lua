
Script.Load("lua/bots/PlayerBrain.lua")
Script.Load("lua/bots/GorgeBrain_Data.lua")

------------------------------------------
--
------------------------------------------
class 'GorgeBrain' (PlayerBrain)

function GorgeBrain:Initialize()

    PlayerBrain.Initialize(self)
    self.senses = CreateGorgeBrainSenses()

    --managed in PerformMove action
    self.isSliding = false

end

function GorgeBrain:GetExpectedPlayerClass()
    return "Gorge"
end

function GorgeBrain:GetExpectedTeamNumber()
    return kAlienTeamType
end

function GorgeBrain:GetActions()
    return kGorgeBrainActions
end

function GorgeBrain:GetSenses()
    return self.senses
end

function GorgeBrain:Update( bot, move )
    PROFILE("GorgeBrain:Update()")

    if gBotDebug:Get("spam") then
        Print("GorgeBrain:Update")
    end

    local gorge = bot:GetPlayer()
    
    if PlayerBrain.Update( self, bot, move, gorge ) == false then
        return false
    end
    
    if gorge ~= nil and gorge:GetIsAlive() then 

        --Need to filter on
        local engPerct = gorge:GetEnergy() / 100
        local eHP = gorge:GetHealthScalar()
        local shouldHealSelf = 
            ( 
                --We don't want to burn energy on healing _all_ the time. Save some for slide
                ( eHP < 0.9 and engPerct > 0.3 ) or
                ( eHP < 0.25 )  --halp!
            ) and 
            ( 
                not gorge:GetIsInCombat() or 
                self.lastAction.name == "retreat" 
            )

        if shouldHealSelf then
            --Don't change view or move targets, just heal
            move.commands = AddMoveCommand( move.commands, Move.SecondaryAttack )
        end

    end

end