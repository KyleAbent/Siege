-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/Hud2/topBar/GUIHudTres.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Displays the amount of Tres the team has.
--
--  Properties
--      Tres            How much tres this icon should display.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/Hud2/topBar/GUIHudTopBarTeamThemedObject.lua")

local baseClass = GUIHudTopBarTeamThemedObject
class "GUIHudTres" (baseClass)

GUIHudTres.kLayoutSortPriority = 128

GUIHudTres.kThemeData =
{
    icon = PrecacheAsset("ui/hud2/team_info_atlas.dds"),
    
    [kMarineTeamType] =
    {
        pxCoords = {50, 0, 100, 50}, -- optional, otherwise full texture is used.
    },
    
    [kAlienTeamType] =
    {
        pxCoords = {0, 0, 50, 50},
    },
}

GUIHudTres:AddClassProperty("Tres", 0)

function GUIHudTres:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    baseClass.Initialize(self, params, errorDepth)
    
    self:HookEvent(self, "OnTresChanged", self.UpdateTresText)
    self:UpdateTresText()
    
    -- We hook special global "OnTeam___ResourcesChanged" events from the global dispatcher to get
    -- team resource updates.  If the team changes for this widget (which it very well could if the
    -- user switches teams), then we need to update which "OnTeam___ResourcesChanged" event we've
    -- hooked, so we won't be listening for the other teams resource updates (which we won't get!).
    self:HookEvent(self, "OnTeamNumberChanged", self.UpdateTresHook)
    self:HookEvent(self, "OnTeamInfoInitialized", self.UpdateTresHook)
    self:UpdateTresHook()
    
end

function GUIHudTres:UpdateTresText()
    local tres = self:GetTres()
    -- TODO Maybe make the text red when tres is 0?
    self:GetTextObj():SetText(tostring(tres))
end

function GUIHudTres:UpdateTresHook()
    
    -- Clear old hook
    if self.tresHook then
        self:UnHookEventsByCallback(self.tresHook)
    end
    
    -- Hook into the correct event name for this team number.
    local eventName = string.format("OnTeam%dResourcesChanged", self:GetTeamNumber())
    
    self.tresHook = self:HookEvent(GetGlobalEventDispatcher(), eventName, self.SetTres)
    
    -- Update the Tres amount immediately if we can, since we're probably not starting at the correct value.
    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())
    if teamInfo then
        self:SetTres(teamInfo.teamResources)
    end
    
end

GUIHudTopBar.AddTopBarClass("GUIHudTres")
