-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/Hud2/topBar/GUIHudTopBarGroupForSpecs.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Group of both teams' hud bars, to display both teams information to spectators.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/Hud2/topBar/GUIHudTopBar.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")

local baseClass = GUIListLayout
class "GUIHudTopBarGroupForSpecs" (baseClass)

local kSpacing = 0 -- images have plenty of padding built-in to them.
local kTopOffset = 16

function GUIHudTopBarGroupForSpecs:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    PushParamChange(params, "spacing", kSpacing)
    PushParamChange(params, "frontPadding", kTopOffset)
    PushParamChange(params, "orientation", "vertical")
    baseClass.Initialize(self, params, errorDepth)
    PopParamChange(params, "orientation")
    PopParamChange(params, "frontPadding")
    PopParamChange(params, "spacing")
    
    self.team1TopBar = CreateGUIObject("team1TopBar", GUIHudTopBar, self)
    self.team1TopBar:SetTeamNumber(1)
    self.team1TopBar:AlignTop()
    
    self.team2TopBar = CreateGUIObject("team2TopBar", GUIHudTopBar, self)
    self.team2TopBar:SetTeamNumber(2)
    self.team2TopBar:AlignTop()
    
    self:SetLayer(GetLayerConstant("Hud_TopBar", 500))
    self:AlignTop()
    
end
