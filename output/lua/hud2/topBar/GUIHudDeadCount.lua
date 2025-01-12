-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/Hud2/topBar/GUIHudDeadCount.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Displays the number of dead players on the team.
--
--  Properties
--      DeadCount   The number of dead players on the team.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/Hud2/topBar/GUIHudTopBarTeamThemedObject.lua")

local baseClass = GUIHudTopBarTeamThemedObject
class "GUIHudDeadCount" (baseClass)

GUIHudDeadCount.kLayoutSortPriority = 512

GUIHudDeadCount.kThemeData =
{
    icon = PrecacheAsset("ui/hud2/team_info_atlas.dds"),

    [kMarineTeamType] =
    {
        pxCoords = {50, 150, 100, 200}, -- optional, otherwise full texture is used.
    },

    [kAlienTeamType] =
    {
        pxCoords = {0, 150, 50, 200},
    },
}

GUIHudDeadCount:AddClassProperty("DeadCount", 0)

function GUIHudDeadCount:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    baseClass.Initialize(self, params, errorDepth)
    
    self:HookEvent(self, "OnDeadCountChanged", self.UpdateDeadCountText)
    self:UpdateDeadCountText()
    
    -- We hook special global "OnTeam___SpawnQueueTotalChanged" events from the global dispatcher to
    -- get team spawn queue updates.  If the team changes for this widget (which it very well could
    -- if the user switches teams), then we need to update which "OnTeam___SpawnQueueTotalChanged"
    -- event we've hooked so we get updates for the correct team.
    self:HookEvent(self, "OnTeamNumberChanged", self.UpdateSpawnQueueHook)
    self:HookEvent(self, "OnTeamInfoInitialized", self.UpdateSpawnQueueHook)
    self:UpdateSpawnQueueHook()

end

function GUIHudDeadCount:UpdateDeadCountText()
    local deadCount = self:GetDeadCount()
    -- TODO maybe make the text color reflect the number of RTs?
    self:GetTextObj():SetText(tostring(deadCount))
end

function GUIHudDeadCount:GetMaxWidthText()
    return "00"
end

function GUIHudDeadCount:UpdateSpawnQueueHook()
    
    -- Clear old hook
    if self.spawnQueueHook then
        self:UnHookEventsByCallback(self.spawnQueueHook)
    end
    
    -- Hook into the correct event name for this team number.
    local eventName = string.format("OnTeam%dSpawnQueueTotalChanged", self:GetTeamNumber())
    
    self.spawnQueueHook = self:HookEvent(GetGlobalEventDispatcher(), eventName, self.SetDeadCount)
    
    -- Update the DeadCount immediately if we can, since we're probably not starting at the correct
    -- value.
    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())
    if teamInfo then
        self:SetDeadCount(teamInfo.spawnQueueTotal)
    end

end

GUIHudTopBar.AddTopBarClass("GUIHudDeadCount")
