-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDMapVoteDetailsWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDMapOverviewWidget.lua")

local kConfirmButtonPadding = 10

class "GMTDMapVoteDetailsWidget" (GUIObject)

GMTDMapVoteDetailsWidget:AddCompositeClassProperty("LevelName", "overview")

GMTDMapVoteDetailsWidget.kOverviewFrameTexture = PrecacheAsset("ui/thunderdome/mapvote_overviewframe.dds")
GMTDMapVoteDetailsWidget.kConfirmButtonTexture = PrecacheAsset("ui/thunderdome/mapvote_confirmbutton.dds")
GMTDMapVoteDetailsWidget.kVotedCheckTexture    = PrecacheAsset("ui/thunderdome/mapvote_checkmark.dds")

GMTDMapVoteDetailsWidget.kConfirmButtonSize = Vector(785, 140, 0)

function GMTDMapVoteDetailsWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self:SetTexture(self.kOverviewFrameTexture)
    self:SetSizeFromTexture()
    self:SetColor(1, 1, 1)

    self.overview = CreateGUIObject("overview", GMTDMapOverviewWidget, self)
    self.overview:AlignTop()

    self.confirmVotesButton = CreateGUIObject("confirmVotesButton", GUIButton, self, params, errorDepth)
    self.confirmVotesButton:SetTexture(self.kConfirmButtonTexture)
    self.confirmVotesButton:SetSizeFromTexture()
    self.confirmVotesButton:AlignBottom()
    self.confirmVotesButton:SetColor(1, 1, 1)
    self.confirmVotesButton:SetPosition(0, -kConfirmButtonPadding)

    self.confirmVotesButtonLabel = CreateGUIObject("confirmVotesButtonLabel", GUIText, self.confirmVotesButton, params, errorDepth)
    self.confirmVotesButtonLabel:SetFont("MicrogrammaBold", 27)
    self.confirmVotesButtonLabel:SetText(Locale.ResolveString("THUNDERDOME_MAPSELECTION_CONFIRM_BUTTON"))
    self.confirmVotesButtonLabel:AlignCenter()

    self.confirmVotesButtonCheck = CreateGUIObject("confirmVotesButtonCheck", GUIObject, self.confirmVotesButtonLabel)
    self.confirmVotesButtonCheck:SetTexture(self.kVotedCheckTexture)
    self.confirmVotesButtonCheck:SetColor(1,1,1)
    self.confirmVotesButtonCheck:SetSize(92, 66)
    self.confirmVotesButtonCheck:AlignRight()
    self.confirmVotesButtonCheck:SetPosition(self.confirmVotesButtonCheck:GetSize().x, 0)
    self.confirmVotesButtonCheck:SetVisible(false)

    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)
    self:ForwardEvent(self.confirmVotesButton, "OnPressed", "OnMapVotesConfirmed")

    self:OnSizeChanged(self:GetSize())

end

function GMTDMapVoteDetailsWidget:OnSizeChanged(newSize)

    local heightForButton = (kConfirmButtonPadding * 2) + self.confirmVotesButton:GetSize().y
    self.overview:SetSize(newSize.x, newSize.y - heightForButton)

end

function GMTDMapVoteDetailsWidget:Reset()

    self.overview:Reset()
    self.confirmVotesButton:SetEnabled(true)
    self.confirmVotesButton:SetColor(1,1,1)
    self.confirmVotesButtonLabel:SetText(Locale.ResolveString("THUNDERDOME_MAPSELECTION_CONFIRM_BUTTON"))
    self.confirmVotesButtonCheck:SetVisible(false)

end

function GMTDMapVoteDetailsWidget:Lock()

    self.confirmVotesButton:SetEnabled(false)
    self.confirmVotesButton:SetColor(0.4, 0.4, 0.4)
    self.confirmVotesButtonLabel:SetText(Locale.ResolveString("THUNDERDOME_MAPSELECTION_CONFIRM_BUTTON_LOCKED"))
    self.confirmVotesButtonCheck:SetVisible(true)

end
