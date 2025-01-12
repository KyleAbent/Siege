
------------------------------------------
--  Base class for bot brains
------------------------------------------

Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/BotDebug.lua")
Script.Load("lua/UnorderedSet.lua")

gBotDebug:AddBoolean("debugall", true)

------------------------------------------
--  Globals
------------------------------------------

kPlayerObjectiveComplete = true
kPlayerBrainTickrate = 6
kPlayerBrainTickFrametime = 1 / kPlayerBrainTickrate
--TODO Define ObjectActions tick rate

class 'PlayerBrain'

PlayerBrain.kUseObjectiveActions = false
PlayerBrain.kObjectiveUpdateRate = 1

PlayerBrain.kActionDelay = 0

function PlayerBrain:Initialize()

    self.lastAction = nil

    -- For Bot routing. Cleared when controller is set (respawn)
    self.visitedLocations = IterableDict()

    self.exploreTarget = nil
    self.exploreTargetPos = nil
    self.isExploring = false

    self.timeOfJump = 0

    self.goalAction = nil
    self.lastObjectiveUpdateTime = 0
    self.lastGoalActionType = nil

    --Note: normally unused, but utilized for distance closure when attack-targets are out of LOS
    self.lastAttackApproachRange = -1

    --Interrupt current objective to respond to hostile threat
    self.lastThreatResponseCalcTime = 0.0
    self.timeNextAction = 0

end

function PlayerBrain:AddVisitedLocation(locationName)
    self.visitedLocations[locationName] = Shared.GetTime()
end

function PlayerBrain:GetIsExploring()
    return self.isExploring
end

function PlayerBrain:GetLocationVisited(locationName)
    return self.visitedLocations[locationName]
end

function PlayerBrain:ClearAllVisitedLocations()
    self.visitedLocations:Clear()
end

function PlayerBrain:ClearVisitedLocation(locationName)
    self.visitedLocations[locationName] = nil
end

function PlayerBrain:GetLastGoalActionType()    --!!Override in children!!
    return nil
end

-- Force the current goal action to be discarded and a new objective recalculated
function PlayerBrain:InterruptCurrentGoalAction()
    if self.goalAction then
        self.lastGoalActionType = self.goalAction.name
        self.goalAction = nil
        self.lastObjectiveUpdateTime = 0.0

        -- Log("    [%s]: previous Goal Action [%s] was interrupted", self.player, self.lastGoalActionType)
    end
end

function PlayerBrain:GetShouldDebug(bot)

    ------------------------------------------
    --  This code is for Player-types, commanders should override this
    ------------------------------------------
    -- If commander-selected, turn debug on
    local isSelected = bot:GetPlayer():GetIsSelected( kMarineTeamType ) or bot:GetPlayer():GetIsSelected( kAlienTeamType )

    if isSelected and gDebugSelectedBots then
        return true
    elseif self.targettedForDebug then
        return true
    else
        return false
    end

end

function PlayerBrain:OnLeaveCombat()
    --Log("PlayerBrain:OnLeaveCombat()")
    self.lastAttackApproachRange = -1
end

function PlayerBrain:OnDestroy()

    -- remove any assignment this bot player had stored in the team brain when it is removed from the team
    if IsValid(self.player) and self.teamBrain then

        self.teamBrain:UnassignPlayer(self.player)

    end

end

function PlayerBrain:Update(bot, move, player)  --allow child-class to pass player, to cut down on re-use and tail-calls
    PROFILE("PlayerBrain:Update")

    -- if gBotDebug:Get("spam") then
    --     Log("PlayerBrain:Update")
    -- end

    if player == nil then
        player = bot:GetPlayer()
    end

    self.teamBrain = GetTeamBrain( player:GetTeamNumber() )

    if not player:isa( self:GetExpectedPlayerClass() ) or player:GetTeamNumber() <= 0 then
        -- Log("WARNING: Bot isn't on the right team OR the correct player class. Deleting brain.")
        bot.brain = nil
        player.botBrain = nil
        self.teamBrain:UnassignPlayer(player)

        return false
    end

    if HasMixin(player, "Live") and not player:GetIsAlive() then
    --Why update when we're dead? Really, I mean...we could just waste some cycles...
        self.goalAction = nil
        self.lastGoalActionType = nil
        self.lastObjectiveUpdateTime = 0
        self.lastAttackApproachRange = -1
        self.teamBrain:UnassignPlayer(player)
        return false
    end

    if not player:GetCanControl() then
        -- no point in doing anything if we can't control ourselves
        return false
    end

    self.player = player

    local time = Shared.GetTime()
    local nextObjectiveUpdateTime = self.lastObjectiveUpdateTime + self.kObjectiveUpdateRate

    -- Skip update if the set delay has not passed yet.
    if time < self.timeNextAction then
        return false
    end

    if bot.lastcommands then

        local reuseMoveCmds = 
            self.lastAction and 
            self.nextMoveTime and 
            self.nextMoveTime > time and 
            self.lastAction.name ~= "attack" and    --FIXME This is not uniform across all Bot-types...need a IsAttackAction like thing
            time <= nextObjectiveUpdateTime and
            not self.lastAction.fastUpdate

        if reuseMoveCmds then
            move.commands = bit.bor(move.commands, bot.lastcommands)

            return false
        end

    end

    self.timeNextAction = time + self.kActionDelay

    self.debug = self:GetShouldDebug(bot)
    if self.debug then
        Log("-- BEGIN BRAIN UPDATE, player name = %s --", player:GetName())
    end

    local bestAction = nil

    -- Prepare senses before action-evals use it
    self:GetSenses():OnBeginFrame(bot)
    self.teamBrain:OnBeginFrame()
    
    --Immediate Actions - must be acted upon "right now"
    for _, actionEval in ipairs( self:GetActions() ) do     
    --FIXME We'll need a contextual-check (per Bot type) here, otherwise Marine building, will stop, to repair another player because 2% armor damage (dumb)
    --  Something akin to "are we in Combat", and perhaps a PriorityFlag property? In essence, these need an early-out option (by context of each action-def)

        if self.debug then
            self:GetSenses():ResetDebugTrace()
        end

        local action = actionEval(bot, self, player)
        assert( action.weight ~= nil )   --TODO Remove, only useful for dev

        if not bestAction or action.weight > bestAction.weight and action.weight > 0 then
            bestAction = action
        end

    end

    --If our immediate Actions yielded no Weight value, that's the same as NOT valid, reset selected action
    if bestAction.weight == 0 and self.kUseObjectiveActions then
        bestAction = nil
    end

    --!!!!FIXME!!!!  How can we have a "Target of Oppurtunity" type behaviors when a Marine is traveling
    --Currently, both Skulks and Marines have a BAD (all bots really) behavior of running right by something they shouldn't

    --Objective/Goal Actions - These are returned to when no Immediate Action is selected
    if bestAction == nil and self.kUseObjectiveActions then
    --An action did not "override" or objective, check the tick rate, and evaluate

        --Validate active goal action (ensure all of its preconditions are still valid and it can be executed)
        if self.goalAction ~= nil then

            if self.goalAction.validate and not self.goalAction.validate( bot, self, player, self.goalAction ) then
                --Current GoalAction is invalid (e.g. structure destroyed, or guard target killed), recalculate a new goal
                self.lastGoalActionType = self.goalAction.name
                self.goalAction = nil
                -- Log("    [%s]: previous Goal Action [%s] was invalidated", player, self.lastGoalActionType)
            end

        end

        if nextObjectiveUpdateTime < time then 

            if self.goalAction ~= nil then 
            --Note: as is, Explore action does NOT have (nor should) .validate

                if self.goalAction.name == "explore" then
                --stupid, but we HAVE to clear->select Explore, as it is implemented to be one-shot in its locgic, which
                --internally assumed it'll be called over and over.
                    self.lastGoalActionType = self.goalAction.name
                    self.goalAction = nil
                    -- Log("    ...forced-clear Goal Action [%s] was Explore", self.lastGoalActionType)

                elseif self.goalAction.validate == nil then
                --clear current goal action if it cannot be validated, prevents goals from accidentally deadlocking bot
                    -- Log("WARNING: [%s] Goal-Action did not have .validate(), forced clear...", self.goalAction.name)
                    self.lastGoalActionType = self.goalAction.name
                    self.goalAction = nil
                end

            end

            if self.goalAction == nil then
            --Active goal was invalidated/expired. Choose a new one
                
                local selGoalAction = nil
                local selGoalWeight = 0.0
                bot.brain.teamBrain:UnassignBot(bot)    --FIXME This is very likely causing multiple behaviors to "soft break" (e.g. multiple bots guarding, etc.)

                -- Log("  No active Goal Action, running all weights...")
                for _, objectiveEval in ipairs( self:GetObjectiveActions() ) do        --FIXME No reason this can't be a generic function (which handles both action types, just need to feed it the data)
                    if self.debug then
                        self:GetSenses():ResetDebugTrace()
                    end
                    
                    local objective = objectiveEval(bot, self, player)
                    assert( objective.weight ~= nil )   --TODO Remove, only useful for dev
                    
                    if objective.weight > selGoalWeight then --BLEH...this is basically a bubble sort, lame
                        selGoalAction = objective
                        selGoalWeight = objective.weight
                    end
                end

                self.goalAction = selGoalAction
                -- Log("  Goal-Action[%s] selected", self.goalAction.name)

            end

            self.lastObjectiveUpdateTime = time

        end

        if self.goalAction ~= nil then
            --GoalAction is assumed to still be valid, carry on!
            bestAction = self.goalAction
        end

    end

    if bestAction ~= nil then

        if self.debug then
            Log("weight(%s) = %0.2f. trace = %s", objective.name, objective.weight, self:GetSenses():GetDebugTrace())
        end

        -- (botId, sectionType, fieldName, fieldValue)
        GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Action Name", bestAction.name)
        GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Action Weight", bestAction.weight)
        GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Goal Name", (self.goalAction ~= nil and self.goalAction.name or ''))
        GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Goal Weight", (self.goalAction ~= nil and self.goalAction.weight or 0))
        GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "In Combat", HasMixin(player, "Combat") and player:GetIsInCombat())
        GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Is FastUpdate", bestAction.fastUpdate)

        local botClient = player:GetClient()
        if botClient then
            local encounterAcc = GetBotAccuracyTracker():GetAccuracySummaryString(botClient, false)
            local lifetimeAcc = GetBotAccuracyTracker():GetAccuracySummaryString(botClient, true)
            GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.BotAccuracy, "Encounter", encounterAcc)
            GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.BotAccuracy, "Lifetime", lifetimeAcc)
        end

        if self.debug then
            Log("-- chose action: " .. bestAction.name)
        end

        self.isExploring = bestAction.name == "explore"

        local complete = bestAction.perform(move, bot, self, player, bestAction)

        if self.debug and self.lastAction and self.lastAction.name ~= bestAction.name then
            Log("%s is switching from %s to %s", bot.botName, self.lastAction.name, bestAction.name)
        end

        self.lastAction = bestAction
        self.nextMoveTime = time + 1 / kPlayerBrainTickrate
        bot.lastcommands = move.commands

        if complete == kPlayerObjectiveComplete and bestAction == self.goalAction then
            -- clear the goal action and re-think immediately
            self.goalAction = nil
            self.lastObjectiveUpdateTime = 0.0
        end

        if self.debug or gBotDebug:Get("debugall") then
            Shared.DebugColor( 0, 1, 0, 1 )
            Shared.DebugText( bestAction.name, bot:GetPlayer():GetEyePos()+Vector(-1,0,0), 0.0 )
        end

        if gBotDebug:Get("com_m_actions") and bot:isa("CommanderBot") then
            Log("Marine Com Action: '%s'", bestAction.name)
        end

        GetBotDebuggingManager():SendDebugInfoForBot(bot:GetId())

    end

end

