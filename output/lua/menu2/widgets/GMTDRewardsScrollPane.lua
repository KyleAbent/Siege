-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/GMTDRewardsScrollPane.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    GUIMenuScrollPane with custom thickness for scroll bars.
--
--  Properties:
--      PaneSize    The size of the area where GUIItems and GUIObjects can be placed.  They can be
--                  placed outside of the pane bounds, but they won't be able to be scrolled-to.
--                  This just sets the size of the area that the scroll bars work with.
--      HorizontalScrollBarEnabled      Whether or not a horizontal scroll bar should be used.
--      VerticalScrollBarEnabled        Whether or not a vertical scroll bar should be used.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/widgets/GUIMenuScrollPane.lua")

---@class GMTDRewardsScrollPane : GUIMenuScrollPane
class "GMTDRewardsScrollPane" (GUIMenuScrollPane)

local kScrollBarThickness = 56

function GMTDRewardsScrollPane:GetScrollBarThickness()
    return kScrollBarThickness
end
