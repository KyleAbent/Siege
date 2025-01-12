-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDGroupSearchButton.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--  Events
--      OnMatchSearchPressed - When this object is clicked while not searching.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/menu2/widgets/GUIMenuCheckboxWidgetLabeled.lua")

Log("     GMTDGroupSearchButton File LOADED")

class "GMTDGroupSearchButton" (GUIObject)

GMTDGroupSearchButton.kFrameTexture         = PrecacheAsset("ui/thunderdome/lobby_vote_frame.dds")
GMTDGroupSearchButton.kCommanderIconTexture = PrecacheAsset("ui/thunderdome/commander_icon.dds")
GMTDGroupSearchButton.kCheckmarkTexture     = PrecacheAsset("ui/thunderdome/mapvote_checkmark.dds")

function GMTDGroupSearchButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.popup = nil

    self.background = CreateGUIObject("background", GUIButton, self, params, errorDepth)
    self.background:SetSize(642, 384)
    self.background:SetColor(0, 0, 0)
    self:ForwardEvent(self.background, "OnPressed", "OnMatchSearchPressed")

    self.commanderIcon = CreateGUIObject("commanderIcon", GUIObject, self.background, params, errorDepth)
    self.commanderIcon:SetTexture(self.kCommanderIconTexture)
    self.commanderIcon:SetSize(380, 380)
    self.commanderIcon:SetColor(1, 1, 1, 0.4)
    self.commanderIcon:AlignCenter()

    self.backgroundFrame = CreateGUIObject("backgroundFrame", GUIObject, self.background, params, errorDepth)
    self.backgroundFrame:SetTexture(self.kFrameTexture)
    self.backgroundFrame:SetSizeFromTexture()
    self.backgroundFrame:AlignCenter()
    self.backgroundFrame:SetColor(1, 1, 1)

    self.label = CreateGUIObject("label", GUIMenuText, self.background, params, errorDepth)
    self.label:SetText( Locale.ResolveString("THUNDERDOME_GROUP_FIND_MATCH") )
    self.label:AlignCenter()
    self.label:SetPosition(0, 0)
    self.label:SetFont("AgencyBold", 50)
    self.label:SetColor(1, 1, 1)

end

function GMTDGroupSearchButton:Reset()
    self.label:SetColor(1, 1, 1)
    self.label:SetText( Locale.ResolveString("THUNDERDOME_GROUP_FIND_MATCH") )

    if self.popup then
        self.popup:Close()
        self.popup = nil
    end
end

function GMTDGroupSearchButton:SetSearching()
    --FIXME(sturnclaw): better color for Cancel Searching text
    self.label:SetColor( 147/255, 176/255, 183/255 )
    self.label:SetText( Locale.ResolveString("THUNDERDOME_GROUP_CANCEL_SEARCH") )
end
