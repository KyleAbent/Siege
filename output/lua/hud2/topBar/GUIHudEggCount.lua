-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/Hud2/topBar/GUIHudEggCount.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Displays the number of eggs available for the aliens to respawn from.
--
--  Properties
--      EggCount        The number of available eggs.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/Hud2/topBar/GUIHudTopBarObject.lua")

local baseClass = GUIHudTopBarObject
class "GUIHudEggCount" (baseClass)

GUIHudEggCount.kLayoutSortPriority = 640

local kLowCountTextColor = HexToColor("f44848")
local kIcon = PrecacheAsset("ui/hud2/team_info_atlas.dds")
local kPxCoords = {0, 200, 50, 250}

GUIHudEggCount:AddClassProperty("EggCount", 0)

function GUIHudEggCount:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    baseClass.Initialize(self, params, errorDepth)
    
    self.icon:SetTexture(kIcon)
    self.icon:SetTexturePixelCoordinates(kPxCoords)
    self.icon:SetSize(math.abs(kPxCoords[3]-kPxCoords[1]), math.abs(kPxCoords[4]-kPxCoords[2]))
    
    self:HookEvent(self, "OnEggCountChanged", self.UpdateEggCountText)
    self:UpdateEggCountText()
    self:HookEvent(GetGlobalEventDispatcher(), "OnEggCountChanged", self.SetEggCount)
    local teamInfo = GetTeamInfoEntity(kTeam2Index)
    if teamInfo then
        self:SetEggCount(teamInfo.eggCount)
    end
    
end

function GUIHudEggCount:UpdateEggCountText()
    local eggCount = self:GetEggCount()
    
    if eggCount == 0 then
        self:GetTextObj():SetColor(kLowCountTextColor)
    else
        self:GetTextObj():SetColor(1, 1, 1, 1)
    end
    
    self:GetTextObj():SetText(tostring(eggCount))
end

function GUIHudEggCount:GetMaxWidthText()
    return "00"
end

-- Only show this top bar object if it is displaying for the alien team.
function GUIHudEggCount.EvaluateVisibility(topBarObj)
    
    local topBarTeamNum = topBarObj:GetTeamNumber()
    local topBarTeamType = GetTeamTypeFromTeamIndex(topBarTeamNum)
    
    return topBarTeamType == kAlienTeamType

end

GUIHudTopBar.AddTopBarClass("GUIHudEggCount")
