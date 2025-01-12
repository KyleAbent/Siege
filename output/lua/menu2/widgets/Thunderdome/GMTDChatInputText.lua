-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDChatInputText.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- Simple class that is just a GUIMenuText but it doesn't react to the "editing" FXState
-- Originally meant for use in the Thunderdome chat input bar, the message part.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/GUIMenuText.lua")

--- @class GMTDText : GUIMenuText
class "GMTDChatInputText" (GUIMenuText)

GMTDChatInputText.kChatInputColor = ColorFrom255(219, 219, 219)

function GMTDChatInputText:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    GUIMenuText.Initialize(self, params, errorDepth)

    self.colorSet = false

end

function GMTDChatInputText:OnFXStateChangedOverride()
    if not self.colorSet then
        self:SetColor(self.kChatInputColor)
        self.colorSet = true
    end

    return true
end
