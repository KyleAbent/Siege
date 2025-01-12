-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GMTDRewardsScreenPlay.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Screen that is the same size and location as the new player mission, but instead serves as a shortcut to start matched
--    play.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIParagraph.lua")
Script.Load("lua/menu2/widgets/GMTDRewardsPlayQueueButton.lua")

local baseClass = GUIObject

---@class GMTDRewardsScreenPlay : GUIObject
class "GMTDRewardsScreenPlay" (baseClass)

GMTDRewardsScreenPlay.kBackgroundTexture = PrecacheAsset("ui/thunderdome_rewards/missions_background.dds")
GMTDRewardsScreenPlay.kBorderWidth = 11

GMTDRewardsScreenPlay.kTitleColor = HexToColor("63bed6")
GMTDRewardsScreenPlay.kDescColor = HexToColor("c4dce0")

function GMTDRewardsScreenPlay:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:SetTexture(self.kBackgroundTexture)
    self:SetSizeFromTexture()
    self:SetColor(1,1,1)

    local borderSizeDim = self.kBorderWidth * 2
    local size = self:GetSize()
    local contentsSize = Vector(size.x - borderSizeDim, size.y - borderSizeDim, 0)

    self.contents = CreateGUIObject("contents", GUIObject, self)
    self.contents:AlignCenter()
    self.contents:SetSize(contentsSize)

    self.title = CreateGUIObject("title", GUIParagraph, self.contents,
    {
        paragraphSize = Vector(contentsSize.x * 0.9, contentsSize.y * 0.3, 0),
        justification = GUIItem.Align_Center,
        color = self.kTitleColor,
        font = MenuStyle.kRewardsPlayScreenTitleFont,
        text = Locale.ResolveString("THUNDERDOME_REWARDS_PLAY_TITLE"),
        align = "top"
    })

    local y = 270
    self.title:SetY(y)
    y = y + self.title:GetSize().y

    self.queueButton = CreateGUIObject("queueButton", GMTDRewardsPlayQueueButton, self)
    self.queueButton:SetY(y)
    y = y + self.queueButton:GetSize().y

    self.descText = CreateGUIObject("descText", GUIParagraph, self,
    {
        align = "top",
        paragraphSize = Vector(contentsSize.x * 0.7, -1, 0),
        justification = GUIItem.Align_Center,
        font = MenuStyle.kRewardsPlayScreenDescFont,
        color = self.kDescColor,
        text = self.queueButton:GetTDEnabled() and Locale.ResolveString("THUNDERDOME_REWARDS_PLAY_DESC_DISABLED") or Locale.ResolveString("THUNDERDOME_REWARDS_PLAY_DESC")
    }, errorDepth)
    self.descText:SetY(y)

    self:HookEvent(self.queueButton:GetButton(), "OnPressed", self.OnQueueButtonPressed)
    self:HookEvent(self, "OnVisibleChanged", self.OnVisibleChanged)
    self:OnVisibleChanged()

end

function GMTDRewardsScreenPlay:OnQueueButtonPressed()
    PlayMenuSound("ButtonClick")
    if Client.GetIsConnected() then
        GetMainMenu():DisplayPopupMessage( Locale.ResolveString("THUNDERDOME_REWARDS_QUEUE_BTN_INVALID_MSG"), Locale.ResolveString("THUNDERDOME_REWARDS_QUEUE_BTN_INVALID_TITLE") )
    else
        GetScreenManager():DisplayScreen("MatchMaking")
    end
end

function GMTDRewardsScreenPlay:OnVisibleChanged()

    self.queueButton:UpdateEnabledState()
    
    if not self.queueButton:GetTDEnabled() then
        self.queueButton:StartOrStopArrowAnimation(self:GetVisible())
    end
end
