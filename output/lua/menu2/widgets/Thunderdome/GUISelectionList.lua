-- ======= Copyright (c) 2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GUISelectionList.lua
--
--    Created by:   Brock Gillespie
--
-- Events
--        OnMapVoteButtonPressed - Just the "OnPressed" event from GUIButton. Fires when the map vote button is pressed.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


Script.Load("lua/GUI/layouts/GUIListLayout.lua")


local baseClass = GUIListLayout
class 'GUISelectionList' (baseClass)

local kSpacing = 100

function GUISelectionList:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    RequireType({"number", "nil"}, params.buttonSpacing, "params.buttonSpacing", errorDepth)
    
    PushParamChange(params, "spacing", params.buttonSpacing)
    baseClass.Initialize(self, params, errorDepth)
    PopParamChange(params, "spacing")

    --TODO Add size-changed, etc.

end
