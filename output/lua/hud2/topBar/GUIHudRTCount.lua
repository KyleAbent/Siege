-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/Hud2/topBar/GUIHudRTCount.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Displays the amount of RTs (resource towers) the team owns.
--
--  Properties
--      RTCount     The resource tower count to display.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/Hud2/topBar/GUIHudTopBarTeamThemedObject.lua")

local baseClass = GUIHudTopBarTeamThemedObject
class "GUIHudRTCount" (baseClass)

GUIHudRTCount.kLayoutSortPriority = 256

GUIHudRTCount.kThemeData =
{
    icon = PrecacheAsset("ui/hud2/team_info_atlas.dds"),

    [kMarineTeamType] =
    {
        pxCoords = {50, 50, 100, 100}, -- optional, otherwise full texture is used.
    },

    [kAlienTeamType] =
    {
        pxCoords = {0, 50, 50, 100},
    },
}

GUIHudRTCount:AddClassProperty("RTCount", 0)

function GUIHudRTCount:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    baseClass.Initialize(self, params, errorDepth)
    
    self:HookEvent(self, "OnRTCountChanged", self.UpdateRTCountText)
    self:UpdateRTCountText()
    
    -- We hook special global "OnTeam___ResourceTowerCountChanged" events from the global dispatcher
    -- to get rt count updates.  If the team changes for this widget, then we need to update which
    -- "OnTeam___ResourceTowerCountChanged" event we've hooked.
    self:HookEvent(self, "OnTeamNumberChanged", self.UpdateRTCountHook)
    self:HookEvent(self, "OnTeamInfoInitialized", self.UpdateRTCountHook)
    self:UpdateRTCountHook()
    
end

function GUIHudRTCount:UpdateRTCountText()
    local rtCount = self:GetRTCount()
    -- TODO maybe make the text color reflect the number of RTs?
    self:GetTextObj():SetText(tostring(rtCount))
end

function GUIHudRTCount:GetMaxWidthText()
    return "00"
end

function GUIHudRTCount:UpdateRTCountHook()
    
    -- Clear old hook
    if self.rtCountHook then
        self:UnHookEventsByCallback(self.rtCountHook)
    end
    
    -- Hook into the correct event name for this team number.
    local eventName = string.format("OnTeam%dResourceTowerCountChanged", self:GetTeamNumber())
    
    self.rtCountHook = self:HookEvent(GetGlobalEventDispatcher(), eventName, self.SetRTCount)
    
    -- Update the RTCount immediately if we can, since we're probably not starting at the correct value.
    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())
    if teamInfo then
        self:SetRTCount(teamInfo.numResourceTowers)
    end

end

GUIHudTopBar.AddTopBarClass("GUIHudRTCount")
