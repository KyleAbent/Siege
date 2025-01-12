-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/widgets/GMTDRewardsPlayQueueButton.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Button for searching for a matched play game from the rewards screen.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/GUI/style/GUIStyledText.lua")

local DEBUG_FakeThunderdomeCase = false

local baseClass = GUIObject

---@class GMTDRewardsPlayQueueButton : GUIObject
class "GMTDRewardsPlayQueueButton" (baseClass)

GMTDRewardsPlayQueueButton:AddClassProperty("TDEnabled", false)

GMTDRewardsPlayQueueButton.kBackgroundTexture = PrecacheAsset("ui/thunderdome_rewards/play_queuebutton.dds")
GMTDRewardsPlayQueueButton.kButtonArrowsTexture = PrecacheAsset("ui/thunderdome_rewards/play_queuebutton_arrows.dds")

GMTDRewardsPlayQueueButton.kButtonArrowsShader = PrecacheAsset("shaders/GUI/menu/tdRewardsPlayButtonArrows.surface_shader")
GMTDRewardsPlayQueueButton.kArrowStageDuration = 0.3

GMTDRewardsPlayQueueButton.kTopTextColor = HexToColor("63bed6")
GMTDRewardsPlayQueueButton.kButtonSize = Vector(582, 227, 0) -- Art had glow in it, hit-box too big if including glow for button. :(

GMTDRewardsPlayQueueButton.kDisabledColor = Color(0.3, 0.3, 0.3)
GMTDRewardsPlayQueueButton.kEnabledColor = Color(1, 1, 1)

function GMTDRewardsPlayQueueButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:SetTexture(self.kBackgroundTexture)
    self:SetSizeFromTexture()
    self:SetColor(1,1,1)

    self.arrowStage = 0
    self.arrowCallback = nil

    self.button = CreateGUIObject("button", GUIButton, self,
    {
        align = "center",
        size = self.kButtonSize
    }, errorDepth)

    self.arrows = CreateGUIObject("arrows", GUIObject, self.button, -- TODO(Salads): TDREWARDS - Arrows should animated with shader.
    {
        align = "center",
    }, errorDepth)
    self.arrows:SetTexture(self.kButtonArrowsTexture)
    self.arrows:SetColor(1,1,1)
    self.arrows:SetSizeFromTexture()
    self.arrows:SetShader(self.kButtonArrowsShader)

    local y = 30

    self.topText = CreateGUIObject("topText", GUIText, self.button,
    {
        align = "top",
        color = self.kTopTextColor,
        font = MenuStyle.kRewardsPlayScreenButtonTopTextFont,
        text = Locale.ResolveString("THUNDERDOME_REWARDS_PLAY_QUEUEBUTTON_TOPTEXT"),
    }, errorDepth)
    self.topText:SetY(y)
    y = y + self.topText:GetSize().y - 35

    local bottomText = Locale.ResolveString("THUNDERDOME_REWARDS_PLAY_QUEUEBUTTON_BOTTEXT")

    self.bottomTextNonHover = CreateGUIObject("bottomTextNonHover", GUIStyledText, self.button,
    {
        style = MenuStyle.kThunderdomeRewardsPlayButtonOff,
        font  = MenuStyle.kRewardsPlayScreenButtonBottomTextFont,
        align = "top",
    }, errorDepth)
    self.bottomTextNonHover:SetText(bottomText)
    self.bottomTextNonHover:SetY(y)

    self.bottomTextHover = CreateGUIObject("bottomTextHover", GUIStyledText, self.button,
    {
        style = MenuStyle.kThunderdomeRewardsPlayButtonOn,
        font  = MenuStyle.kRewardsPlayScreenButtonBottomTextFont,
        align = "top",
    }, errorDepth)
    self.bottomTextHover:SetText(bottomText)
    self.bottomTextHover:SetY(y)

    self:HookEvent(self.button, "OnMouseOverChanged", self.OnMouseOverChanged)
    self:UpdateEnabledState()
    self:OnMouseOverChanged()

end

function GMTDRewardsPlayQueueButton:UpdateEnabledState()

    --Exclude all modes except Main Menu context
    local isDisabled = 
        Shared.GetThunderdomeEnabled() or Client.GetIsConnected() or
        not Thunderdome():GetIsIdle() or
        DEBUG_FakeThunderdomeCase

    self:SetTDEnabled(isDisabled)

    if isDisabled then

        self:SetColor(self.kDisabledColor)
        self.button:SetEnabled(false)
        self.arrows:SetVisible(false)

        self.topText:SetColor(self.kDisabledColor)
        self.bottomTextHover:SetColor(self.kDisabledColor)
        self.bottomTextNonHover:SetColor(self.kDisabledColor)

    else

        self:SetColor(self.kEnabledColor)
        self.button:SetEnabled(true)
        self.arrows:SetVisible(true)

        self.topText:SetColor(self.kEnabledColor)
        self.bottomTextHover:SetColor(self.kEnabledColor)
        self.bottomTextNonHover:SetColor(self.kEnabledColor)

    end


end

function GMTDRewardsPlayQueueButton:GetButton()
    return self.button
end

function GMTDRewardsPlayQueueButton:OnMouseOverChanged()

    local isMouseOver = self.button:GetMouseOver() and not self:GetTDEnabled()
    if isMouseOver then
        PlayMenuSound("ButtonHover")
        self.bottomTextNonHover:SetVisible(false)
        self.bottomTextHover:SetVisible(true)
    else
        self.bottomTextNonHover:SetVisible(true)
        self.bottomTextHover:SetVisible(false)
    end

end

function GMTDRewardsPlayQueueButton:ArrowAnimationCallback()

    self.arrows:SetFloatParameter("stage", self.arrowStage)

    self.arrowStage = self.arrowStage + 1
    if self.arrowStage >= 4 then
        self.arrowStage = 0
    end

    return true

end

function GMTDRewardsPlayQueueButton:CleanupArrowAnimation()
    self.arrowStage = 0
    if self.arrowCallback then
        self:RemoveTimedCallback(self.arrowCallback)
        self.arrowCallback = nil
    end
end

function GMTDRewardsPlayQueueButton:StartOrStopArrowAnimation(start)
    self:CleanupArrowAnimation()
    if start then
        self.arrowCallback = self:AddTimedCallback(self.ArrowAnimationCallback, self.kArrowStageDuration, true)
    end
end
