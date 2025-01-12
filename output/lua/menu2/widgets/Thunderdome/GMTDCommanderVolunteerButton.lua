-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDCommanderVolunteerButton.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--  Events
--      OnCommandSelected - When this object is clicked.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/menu2/widgets/GUIMenuCheckboxWidgetLabeled.lua")

class "GMTDCommanderVolunteerButton" (GUIObject)

GMTDCommanderVolunteerButton.kFrameTexture         = PrecacheAsset("ui/thunderdome/lobby_vote_frame.dds")
GMTDCommanderVolunteerButton.kCommanderIconTexture = PrecacheAsset("ui/thunderdome/commander_icon.dds")
GMTDCommanderVolunteerButton.kCheckmarkTexture     = PrecacheAsset("ui/thunderdome/mapvote_checkmark.dds")

function GMTDCommanderVolunteerButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.popup = nil

    self.background = CreateGUIObject("background", GUIButton, self, params, errorDepth)
    self.background:SetSize(642, 384)
    self.background:SetColor(0, 0, 0)
    self:HookEvent(self.background, "OnPressed", self.OnButtonPressed)

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
    self.label:SetText(Locale.ResolveString("THUNDERDOME_VOLUNTEER_TO_COMMAND"))
    self.label:SetDropShadowEnabled(true)
    self.label:AlignCenter()
    self.label:SetPosition(0, 0)
    self.label:SetFont("AgencyBold", 50)
    self.label:SetColor(1, 1, 1)

    self.checkmark = CreateGUIObject("checkmark", GUIObject, self.background, params, errorDepth)
    self.checkmark:SetTexture(self.kCheckmarkTexture)
    self.checkmark:SetSizeFromTexture()
    self.checkmark:AlignBottomRight()
    self.checkmark:SetColor(1,1,1)
    self.checkmark:SetVisible(false)

end

function GMTDCommanderVolunteerButton:Reset()
    self.background:SetEnabled(true)
    self.label:SetColor(1, 1, 1)
    self.checkmark:SetVisible(false)

    if self.popup then
        self.popup:Close()
        self.popup = nil
    end
end

function GMTDCommanderVolunteerButton:OnButtonPressed()
    self:ShowConfirmationPopup()
end

function GMTDCommanderVolunteerButton:ShowConfirmationPopup()
    if not self.popup then
        self.popup = CreateGUIObject("commanderConfirmPopup", GUIMenuPopupSimpleMessage, nil,
        {
            title = Locale.ResolveString("THUNDERDOME_COMMANDER_VOLUNTEER_TITLE"),
            message = Locale.ResolveString("THUNDERDOME_COMMANDER_VOLUNTEER_MESSAGE"),
            buttonConfig =
            {
                GUIPopupDialog.OkayButton,
                GUIPopupDialog.CancelButton
            },
        })

        self:HookEvent(self.popup, "OnConfirmed", self.OnVolunteerConfirmed)
        self:HookEvent(self.popup, "OnClosed", self.OnPopupClosed)
    end
end

function GMTDCommanderVolunteerButton:OnVolunteerConfirmed()

    self.background:SetEnabled(false)
    self.checkmark:SetVisible(true)
    self.label:SetColor(0.5, 0.5, 0.5)

    self:FireEvent("OnCommandSelected")
end

function GMTDCommanderVolunteerButton:ClosePopup()
    if self.popup then
        self.popup:Close()
    end
end

function GMTDCommanderVolunteerButton:OnPopupClosed()
    if self.popup then
        self:UnHookEvent(self.popup, "OnConfirmed", self.OnVolunteerConfirmed)
        self:UnHookEvent(self.popup, "OnClosed", self.OnPopupClosed)
        self.popup = nil
    end
end
