-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/Hud2/topBar/GUIHudTopBarTeamThemedObject.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    GUIHudTopBarObject that adds a "TeamNumber" property.
--
--  Properties
--      TeamNumber      Which team to source the data for this object from, and potentially changes
--                      the themeing of the object to suit the team.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/Hud2/topBar/GUIHudTopBarObject.lua")

local baseClass = GUIHudTopBarObject
class "GUIHudTopBarTeamThemedObject" (baseClass)

-- kThemeData example:
--[=[
GUIHudTopBarTeamThemedObject.kThemeData =
{
    -- can set icon texture here to set the texture for all themes, or as a fallback.
    icon = PrecacheAsset("ui/hud2/team_info_atlas.dds"),
    
    -- can set texture pixel coordinates here if they're the same for all themes, or to set a
    -- fallback.  If pxCoords is not specified, it will default to using the full-size texture
    -- coordinates.
    pxCoords = {50, 150, 100, 200},
    
    [kMarineTeamType] =
    {
        -- overrides icon defined above, but just for marine theme.
        icon = PrecacheAsset("some_other_texture"),
        
        -- overrides pxCoords defined above, but just for marine theme.
        pxCoords = {50, 150, 100, 200},
    },
    
    [kAlienTeamType] =
    {
        pxCoords = {0, 150, 50, 200},
    },
}
--]=]

GUIHudTopBarTeamThemedObject:AddClassProperty("TeamNumber", kTeam1Index)

function GUIHudTopBarTeamThemedObject:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    -- Each object should provide some theme data for the icon in the form of a table.
    RequireType("table", self.kThemeData, "self.kThemeData", errorDepth)
    
    baseClass.Initialize(self, params, errorDepth)

    self:UpdateIconTexture() -- ensure visuals match initial state.
    self:HookEvent(self, "OnTeamNumberChanged", self.UpdateIconTexture)
    
end

function GUIHudTopBarTeamThemedObject:UpdateIconTexture()

    local teamNumber = self:GetTeamNumber()
    local teamType = GetTeamTypeFromTeamIndex(teamNumber)
    local themeData = self.kThemeData
    assert(themeData) -- should have been caught during Initialize()
    
    -- First, read icon and pxCoords from the root level of the table (eg "for all themes...")
    local icon = themeData.icon
    local pxCoords = themeData.pxCoords
    
    -- See if we have specifics defined for just this theme.
    themeData = themeData[teamType]
    if themeData then
        
        -- Override icon and pxCoords with the more specific values (if given).
        icon = themeData.icon or icon
        pxCoords = themeData.pxCoords or pxCoords
        
    end
    
    if icon then
        self.icon:SetTexture(icon)
    end
    
    if pxCoords then
        self.icon:SetTexturePixelCoordinates(pxCoords)
        self.icon:SetSize(math.abs(pxCoords[3]-pxCoords[1]), math.abs(pxCoords[4]-pxCoords[2]))
    elseif icon then
        -- Default to full-texture coords, but only if the icon was provided... otherwise it's just
        -- an invalid theme.
        self.icon:SetTextureCoordinates(0, 0, 1, 1)
        self.icon:SetSizeFromTexture()
    end

end

-- Only show this top bar object if the team type is marine or alien.
function GUIHudTopBarTeamThemedObject.EvaluateVisibility(topBarObj)
    
    local topBarTeamNum = topBarObj:GetTeamNumber()
    local topBarTeamType = GetTeamTypeFromTeamIndex(topBarTeamNum)
    
    return topBarTeamType == kMarineTeamType or topBarTeamType == kAlienTeamType

end