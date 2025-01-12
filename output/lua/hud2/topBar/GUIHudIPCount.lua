-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/Hud2/topBar/GUIHudIPCount.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Displays the number of infantry portals the marine team possesses.
--
--  Properties
--      InfantryPortalCount     The number of active IP entities the marine team owns.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/Hud2/topBar/GUIHudTopBarObject.lua")

local baseClass = GUIHudTopBarObject
class "GUIHudIPCount" (baseClass)

GUIHudIPCount.kLayoutSortPriority = 640

local kLowCountTextColor = HexToColor("f44848")
local kIcon = PrecacheAsset("ui/hud2/team_info_atlas.dds")
local kPxCoords = {50, 200, 100, 250}

GUIHudIPCount:AddClassProperty("InfantryPortalCount", 0)

function GUIHudIPCount:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    baseClass.Initialize(self, params, errorDepth)
    
    self.icon:SetTexture(kIcon)
    self.icon:SetTexturePixelCoordinates(kPxCoords)
    self.icon:SetSize(math.abs(kPxCoords[3]-kPxCoords[1]), math.abs(kPxCoords[4]-kPxCoords[2]))
    
    self:HookEvent(self, "OnInfantryPortalCountChanged", self.UpdateInfantryPortalCountText)
    self:UpdateInfantryPortalCountText()
    self:HookEvent(GetGlobalEventDispatcher(), "OnInfantryPortalCountChanged", self.SetInfantryPortalCount)
    local teamInfo = GetTeamInfoEntity(kTeam1Index)
    if teamInfo then
        self:SetInfantryPortalCount(teamInfo.numInfantryPortals)
    end

end

function GUIHudIPCount:UpdateInfantryPortalCountText()
    local ipCount = self:GetInfantryPortalCount()
    
    if ipCount == 0 then
        self:GetTextObj():SetColor(kLowCountTextColor)
    else
        self:GetTextObj():SetColor(1, 1, 1, 1)
    end
    
    if ipCount >= kMarineTeamInfoMaxInfantryPortalCount then
        self:GetTextObj():SetText(string.format("%d+", kMarineTeamInfoMaxInfantryPortalCount-1))
    else
        self:GetTextObj():SetText(string.format("%d", ipCount))
    end
end

function GUIHudIPCount:GetMaxWidthText()
    return "0"
end

-- Only show this top bar object if it is displaying for the marine team.
function GUIHudIPCount.EvaluateVisibility(topBarObj)
    
    local topBarTeamNum = topBarObj:GetTeamNumber()
    local topBarTeamType = GetTeamTypeFromTeamIndex(topBarTeamNum)
    
    return topBarTeamType == kMarineTeamType

end

GUIHudTopBar.AddTopBarClass("GUIHudIPCount")
