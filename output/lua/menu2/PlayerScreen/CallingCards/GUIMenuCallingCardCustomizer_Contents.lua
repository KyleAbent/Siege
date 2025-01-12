-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/PlayerScreen/CallingCards/GUIMenuCallingCardCustomizer_Contents.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Window that holds and organizes all owned calling cards.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/menu2/GUIMenuBasicBox.lua")
Script.Load("lua/GUI/layouts/GUIColumnLayout.lua")
Script.Load("lua/menu2/widgets/GUIMenuScrollPane.lua")
Script.Load("lua/menu2/PlayerScreen/CallingCards/GUIMenuCallingCard.lua")

local kCallingCardHeight = 270
local kNumColumns = 4 -- Calling Cards per row
local kNumRows = 3
local kColumnSpacing = 10

local function UpdateDimmerSize(dimmer, newX, newY)
    dimmer:SetSize(newX, newY)
end

local baseClass = GUIMenuBasicBox
class "GUIMenuCallingCardCustomizer_Contents" (baseClass)

GUIMenuCallingCardCustomizer_Contents:AddClassProperty("_ShowAmount", 0.0) -- [0, 1]

function GUIMenuCallingCardCustomizer_Contents:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    assert(params.owner)

    self.owner = params.owner
    self.callingCards = {}

    self.scrollPane = CreateGUIObject("scrollPane", GUIMenuScrollPane, self, {
        verticalScrollBarEnabled = true,
        horizontalScrollBarEnabled = false,
    }, errorDepth)
    self.scrollPane:SetSyncToParentSize(true)

    self.dimmer = CreateGUIObject("dimmer", GUIObject, GetMainMenu())
    self.dimmer:SetColor(0, 0, 0, 0.5)
    self.dimmer:SetOpacity(0)
    self.dimmer:SetInheritsParentScaling(false)
    self.dimmer:SetInheritsParentPosition(false)
    self.dimmer:SetLayer(99999)
    self.dimmer:HookEvent(GetGlobalEventDispatcher(), "OnResolutionChanged", UpdateDimmerSize)
    UpdateDimmerSize(self.dimmer, Client.GetScreenWidth(), Client.GetScreenHeight())

    self.columnLayout = CreateGUIObject("columnLayout", GUIColumnLayout, self.scrollPane, {}, errorDepth)
    self.columnLayout:SetColumnSpacing(kColumnSpacing)
    self.columnLayout:SetSpacing(kColumnSpacing)
    self.columnLayout:SetLeftPadding(kColumnSpacing)
    self.columnLayout:SetRightPadding(kColumnSpacing)
    self.columnLayout:SetBackPadding(kColumnSpacing)
    self.columnLayout:SetFrontPadding(kColumnSpacing)
    self.columnLayout:SetNumColumns(kNumColumns)
    self.columnLayout:SetWidth((kNumColumns * kCallingCardHeight) + (kColumnSpacing * (kNumColumns - 1)))

    self:SetWidth(self.columnLayout:GetSize().x + self.scrollPane:GetScrollBarThickness())
    self:SetHeight((kNumRows * kCallingCardHeight) + (kColumnSpacing * (kNumRows - 1)))
    self:SetLayer(GetLayerConstant("CallingCardCustomizer", 99999))

    self.scrollPane:HookEvent(self.columnLayout, "OnSizeChanged", self.scrollPane.SetPaneSize)
    self:HookEvent(self, "On_ShowAmountChanged", self.On_ShowAmountChanged)
    self:HookEvent(self, "OnKey", self.OnKey)
    self:HookEvent(GetGlobalEventDispatcher(), "OnUserStatsAndItemsRefreshed", self.InitializeCallingCards)
    self:HookEvent(GetPlayerScreen(), "OnScreenDisplayedChanged", self.Hide)
    self:InitializeCallingCards()

    self:On_ShowAmountChanged(self:Get_ShowAmount())

end

function GUIMenuCallingCardCustomizer_Contents:OnKey(key, down)

    if key == InputKey.Escape and down then
        self:Hide()
        return true
    end

end

function GUIMenuCallingCardCustomizer_Contents:InitializeCallingCards()

    -- Clean up calling cards
    for i = 1, #self.callingCards do
        self:UnHookEventsBySender(self.callingCards[i])
        self.callingCards[i]:Destroy()
    end
    self.callingCards = {}

    for i = 1, #kCallingCards do
        local cardStr = kCallingCards[i]
        local cardId = kCallingCards[cardStr]

        local shoulderPatchCheck = true
        if GetIsCallingCardUnobtainable(cardId) then
            shoulderPatchCheck = GetIsCallingCardUnlocked(cardId)
        end

        if not GetIsCallingCardSystemOnly(cardId) and shoulderPatchCheck then

            local cardButton = CreateGUIObject(string.format("cardButton_%d", #self.callingCards), GUIMenuCallingCard, self.columnLayout)
            cardButton:SetCardID(cardId)
            self:ForwardEvent(cardButton, "OnCallingCardSelected")
            table.insert(self.callingCards, cardButton)

        end

    end

end

local contentsMargin = 10
function GUIMenuCallingCardCustomizer_Contents:Show()

    PlayMenuSound("BeginChoice")
    self:SetModal()
    self:ListenForKeyInteractions()
    self:AllowChildInteractions()
    --self:HookEvent(self, "OnKey", self.Hide)
    self:HookEvent(self, "OnOutsideClick", self.Hide)

    self.dimmer:AnimateProperty("Opacity", 1.0, MenuAnimations.FadeFast)

    -- Detach the "widgetProper" from the base object so it will render on top of all other objects.
    local ssPos = self.owner.button:GetScreenPosition()
    local absScale = self.owner.button:GetAbsoluteScale()
    self:SetParent(nil)
    self:SetScale(absScale)
    self:SetPosition(ssPos + Vector(self.owner.button:GetSize().x * absScale.x + (contentsMargin * absScale.x), 0, 0))

    self:ClearPropertyAnimations("_ShowAmount")
    self:AnimateProperty("_ShowAmount", 1, MenuAnimations.FlyIn)

end

function GUIMenuCallingCardCustomizer_Contents:Hide()
    
    PlayMenuSound("AcceptChoice")
    self:ClearModal()
    self:StopListeningForKeyInteractions()
    self:BlockChildInteractions()
    self:UnHookEvent(self, "OnKey", self.Hide)
    self:UnHookEvent(self, "OnOutsideClick", self.Hide)

    self.dimmer:AnimateProperty("Opacity", 0.0, MenuAnimations.FadeFast)

    -- Reattach the "widgetProper" to the base object.
    self:SetParent(self.owner)
    self:SetPosition(self.owner.button:GetPosition().x + self.owner.button:GetSize().x + contentsMargin, 0)

    self:ClearPropertyAnimations("_ShowAmount")
    self:Set_ShowAmount(0) -- closes instantly
end

function GUIMenuCallingCardCustomizer_Contents:On_ShowAmountChanged(newAmount)

    local absScale = self.owner.button:GetAbsoluteScale()

    if newAmount > 0.95 then
        self:SetScale(Vector(absScale.x, absScale.y, 0))
    elseif newAmount < 0.05 then
        self:SetScale(Vector(0, 0, 0))
    else
        self:SetScale(Vector(newAmount * absScale.x, newAmount * absScale.y, 0))
    end

end
