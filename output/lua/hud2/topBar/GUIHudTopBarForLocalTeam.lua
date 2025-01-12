-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/Hud2/topBar/GUIHudTopBarForLocalTeam.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Hud top bar that automatically changes team number based on the local player's current team.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/Hud2/topBar/GUIHudTopBar.lua")

---@class GUIHudTopBarForLocalTeam : GUIHudTopBar
local baseClass = GUIHudTopBar
class "GUIHudTopBarForLocalTeam" (baseClass)

GUIHudTopBarForLocalTeam:AddClassProperty("IsCommander", false)

local kTopOffset = 16

local function UpdateLocalPlayerTeam(self, player)
    
    if player then
        local teamNumber = player:GetTeamNumber()
        self:SetTeamNumber(teamNumber)
        self:SetIsCommander(player:isa("Commander"))
    end
    
end

local function UpdateVisibility(self)

    local advOption = ""
    local teamNumber = self:GetTeamNumber()
    if teamNumber == kTeam1Index then
        advOption = "topbar_m"
    elseif teamNumber == kTeam2Index then
        advOption = "topbar_a"
    end
    
    local optionVal = GetAdvancedOption(advOption)
    if optionVal == 0 then
        self.shouldBeVisible = true
    elseif optionVal == 1 then
        self.shouldBeVisible = not self:GetIsCommander()
    elseif optionVal == 2 then
        self.shouldBeVisible = self:GetIsCommander()
    elseif optionVal == 3 then
        self.shouldBeVisible = false
    else
        error(string.format("AdvOption for top-bar is not valid. Name: %s, Value: %s", advOption, optionVal))
    end
    
    self:SetVisible(Client.GetIsControllingPlayer() and self.shouldBeVisible and self.visHideOverride ~= true)
    --Note: visHide is inverted as it's meant to force all other state to true (hide) / false (show)
    
end

function GUIHudTopBarForLocalTeam:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    baseClass.Initialize(self, params, errorDepth)
    
    self.visHideOverride = false
    
    self:AlignTop()
    self:SetY(kTopOffset)
    
    self:SetLayer(GetLayerConstant("Hud_TopBar", 500))
    self:OnLocalPlayerChanged(Client.GetLocalPlayer())
    
end

function GUIHudTopBarForLocalTeam:OnLocalPlayerChanged(forPlayer)
    UpdateLocalPlayerTeam(self, forPlayer)
    UpdateVisibility(self)
end

function GUIHudTopBarForLocalTeam:SetIsHiddenOverride(hidden)
    local changed = hidden ~= self.visHideOverride
    self.visHideOverride = hidden
    
    if changed then 
        UpdateVisibility(self) 
    end
end
