kHiveInfestationRadius = 10
kInfestationRadius = 7.5

class 'FlameThrower'
FlameThrower.kMapName = Flamethrower.kMapName

function LogicTimer:CheckGUI()

        local showGUI = (self.enabled and self.unlockTime ~= nil and self.showGUI)

	if showGUI then
	        if not g_GUITimer then
	            g_GUITimer = GetGUIManager():CreateGUIScript(LogicTimer.kGUIScript)	
			--Script.Load("lua/DockingSiegeGUITimerMod.lua")
	        end
	        
	        if g_GUITimer then
	            g_GUITimer:SetIsVisible(showGUI)
	            
	            if showGUI then
	        
	                local unlockTimeChanged = (self.unlockTime ~= self.unlockTimeClient)
	                if unlockTimeChanged then
	                    self.unlockTimeClient = self.unlockTime
	                    g_GUITimer:SetEndTime(self:GetId(), self.unlockTime)
	                end
	                
	            end
	        end
	end
    end

-- Disable small Doors blocking nav mesh (the block is permanent and it breaks this map)
function FuncDoor:OnUpdate(deltaTime) 
end