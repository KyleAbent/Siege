--[[
    lua/EvolutionChamber.lua
    
    Handles the life-form researches for the Hive.
]]
class 'EvolutionChamber' (ScriptActor)

EvolutionChamber.kMapName = "evolutionchamber"

local networkVars = { }

AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function EvolutionChamber:OnCreate()
    ScriptActor.OnCreate(self)
    
    InitMixin(self, TeamMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, ResearchMixin)

end

function EvolutionChamber:OnOwnerChanged(currentOwner, newOwner)
    
    -- Update hive's relevancy mask to trigger an update to ours.
    if newOwner then
        newOwner:UpdateIncludeRelevancyMask()
    end
    
end

function EvolutionChamber:SetIncludeRelevancyMask(includeMask)

    includeMask = bit.bor(includeMask, kRelevantToTeam2Commander)
    ScriptActor.SetIncludeRelevancyMask(self, includeMask)

end

EvolutionChamber.kUpgradeButtons ={                            
    [kTechId.SkulkMenu] = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                                kTechId.None, kTechId.None, kTechId.None, kTechId.None },
                             
    [kTechId.GorgeMenu] = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                                 kTechId.None, kTechId.None, kTechId.None, kTechId.None },
                                 
    [kTechId.LerkMenu] = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                                 kTechId.None, kTechId.None, kTechId.None, kTechId.None },
                                 
    [kTechId.FadeMenu] = { kTechId.None, kTechId.MetabolizeHealth, kTechId.None, kTechId.None,
                           kTechId.None, kTechId.None, kTechId.None, kTechId.None },

    [kTechId.OnosMenu] = { kTechId.None, kTechId.None, kTechId.None,
                           kTechId.None, kTechId.None, kTechId.None, kTechId.None }
}

function EvolutionChamber:GetTechButtons(techId)

    local techButtons = { kTechId.SkulkMenu, kTechId.GorgeMenu, kTechId.LerkMenu, kTechId.FadeMenu,
                                kTechId.OnosMenu, kTechId.None, kTechId.None, kTechId.None }
    
    local returnButton = kTechId.Return
    if self.kUpgradeButtons[techId] then
        techButtons = self.kUpgradeButtons[techId]
        returnButton = kTechId.RootMenu
    end
    
	techButtons[8] = returnButton
	
    if self:GetIsResearching() then
        techButtons[7] = kTechId.Cancel
    else
        techButtons[7] = kTechId.None
    end
    
    return techButtons
    
end

Shared.LinkClassToMap("EvolutionChamber", EvolutionChamber.kMapName, networkVars)
