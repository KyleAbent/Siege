-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/PlayerScreen/CallingCards/GUIMenuCallingCardCustomizer.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Widget that displays the currently selected calling card, and when clicked shows an interface
--    with witch players can selection a desired one from their owned calling cards.
--
--    Calling cards are shown to players that you kill.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/menu2/GUIMenuBasicBox.lua")
Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/GUI/wrappers/FXState.lua")
Script.Load("lua/menu2/wrappers/Tooltip.lua")
Script.Load("lua/menu2/PlayerScreen/CallingCards/GUIMenuCallingCardData.lua")
Script.Load("lua/menu2/PlayerScreen/CallingCards/GUIMenuCallingCardCustomizer_Contents.lua")
Script.Load("lua/menu2/GUIMenuText.lua")
Script.Load("lua/GUI/GUIParagraph.lua")

local kHeight = 270
local kCallingCardDisplaySize = Vector(kHeight, kHeight, 0)
local kTextPadding = 25

local kLockedTexture = PrecacheAsset("ui/callingcards/locked_overlay.dds")

local function OnFXStateChanged(self, state, prevState)

    if state == "pressed" then
        self:ClearPropertyAnimations("StrokeWidth")
        self:SetStrokeWidth(MenuStyle.kStrokeWidth)
        self:ClearPropertyAnimations("StrokeColor")
        self:SetStrokeColor((MenuStyle.kHighlight + MenuStyle.kBasicStrokeColor)*0.5)
    elseif state == "hover" then
        if prevState == "pressed" then
            self:AnimateProperty("StrokeWidth", 3, MenuAnimations.Fade)
            self:AnimateProperty("StrokeColor", MenuStyle.kHighlight, MenuAnimations.Fade)
        else
            PlayMenuSound("ButtonHover")
            DoColorFlashEffect(self, "StrokeColor")
            self:ClearPropertyAnimations("StrokeWidth")
            self:SetStrokeWidth(3)
        end
    else -- default or disabled (which isn't used).
        self:AnimateProperty("StrokeWidth", MenuStyle.kStrokeWidth, MenuAnimations.Fade)
        self:AnimateProperty("StrokeColor", MenuStyle.kBasicStrokeColor, MenuAnimations.Fade)
    end

end

local buttonClass = GUIButton
buttonClass = GetFXStateWrappedClass(buttonClass)
buttonClass = GetTooltipWrappedClass(buttonClass)

--local baseClass = GUIMenuBasicBox
local baseClass = GUIObject
class "GUIMenuCallingCardCustomizer" (baseClass)

GUIMenuCallingCardCustomizer:AddClassProperty("Locked", false)
GUIMenuCallingCardCustomizer:AddClassProperty("CardId", kDefaultPlayerCallingCard)

function GUIMenuCallingCardCustomizer:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    local callingCard = Client.GetOptionInteger(kCallingCardOptionKey, kDefaultPlayerCallingCard)
    if not GetIsCallingCardUnlocked(callingCard) then
        callingCard = kDefaultPlayerCallingCard
        Client.SetOptionInteger(kCallingCardOptionKey, kDefaultPlayerCallingCard) -- Make sure players don't try to bypass via options file.
    end

    self:SetSize(kCallingCardDisplaySize)
    self:SetCardId(callingCard)

    self.buttonBackground = CreateGUIObject("buttonBackground", GUIMenuBasicBox, self, {}, errorDepth)
    self.buttonBackground:SetSize(kCallingCardDisplaySize)

    self.button = CreateGUIObject("button", buttonClass, self.buttonBackground, {}, errorDepth)
    self.button:AlignCenter()
    self.button:SetSize(kCallingCardDisplaySize)
    self.button:SetColor(1,1,1)
    self.button:SetTooltip(Locale.ResolveString("CALLINGCARD_CUSTOMIZER_TOOLTIP"))

    self.text = CreateGUIObject("text", GUIParagraph, self, {}, errorDepth)
    self.text:AlignLeft()
    self.text:SetFont("Microgramma", 32)
    self.text:SetColor(MenuStyle.kTooltipText)
    self.text:SetX(self.buttonBackground:GetPosition().x + self.buttonBackground:GetSize().x + kTextPadding)

    self.contents = CreateGUIObject("contents", GUIMenuCallingCardCustomizer_Contents, self, { owner = self })
    self.contents:SetX(self.button:GetPosition().x + self.button:GetSize().x)
    self.contents:Hide()

    self.buttonBackground:HookEvent(self.button, "OnFXStateChanged", OnFXStateChanged)
    self:HookEvent(self.contents, "OnCallingCardSelected", self.OnCallingCardSelected)
    self:HookEvent(self.button, "OnPressed", self.OnPressed)
    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)
    self:HookEvent(self, "OnCardIdChanged", self.UpdateAppearance)
    self:HookEvent(GetGlobalEventDispatcher(), "OnUserStatsAndItemsRefreshed", self.UpdateAppearance)
    self:UpdateAppearance()

end

function GUIMenuCallingCardCustomizer:UpdateAppearance()

    local cardId = self:GetCardId()
    local shouldBeLocked = not GetIsCallingCardUnlocked(kCallingCardFeatureUnlockCard)

    if shouldBeLocked then

        self.button:SetTexture(kLockedTexture)
        self.button:SetTextureCoordinates(0, 0, 1, 1)
        self.button:SetColor(1,1,1)

        self.text:SetText(Locale.ResolveString("CALLINGCARD_CUSTOMIZER_LOCKED"))

    else

        local callingCardData = GetCallingCardTextureDetails(cardId)
        assert(callingCardData, "Missing Calling Card Data!")

        self.button:SetTexture(callingCardData.texture)
        self.button:SetTexturePixelCoordinates(callingCardData.texCoords)
        self.button:SetColor(1,1,1)

        self.text:SetText(Locale.ResolveString("CALLINGCARD_CUSTOMIZER_UNLOCKED"))

    end

    self:SetLocked(shouldBeLocked)

end

function GUIMenuCallingCardCustomizer:OnSizeChanged()
    local newSize = self:GetSize()
    self.text:SetParagraphSize(newSize.x - self.buttonBackground:GetSize().x - (kTextPadding * 2), kHeight)
end

function GUIMenuCallingCardCustomizer:OnCallingCardSelected(callingCardObj)

    local cardId = callingCardObj:GetCardID()
    self:SetCardId(cardId)
    self.contents:Hide()

    Client.SetOptionInteger(kCallingCardOptionKey, cardId)
    SendPlayerCallingCardUpdate()

end

function GUIMenuCallingCardCustomizer:OnPressed()

    local isLocked = self:GetLocked()

    if isLocked then
        PlayMenuSound("InvalidSound")
        GetScreenManager():DisplayScreen("MissionScreen")
    else
        PlayMenuSound("ButtonClick")
        self.contents:Show()
    end

end
