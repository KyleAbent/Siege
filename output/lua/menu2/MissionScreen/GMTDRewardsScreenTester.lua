-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GMTDRewardsScreenTester.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Control that can set the values of the rewards screen for testing purposes. Does not actually
--    grant items, only changes look of UI.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

local kTesterWindow
function GetTDRewardsScreenTester()
    return kTesterWindow
end

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/menu2/widgets/GUIMenuTextEntryWidget.lua")
Script.Load("lua/menu2/widgets/GUIMenuScrollPane.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")
Script.Load("lua/menu2/widgets/GUIMenuCheckboxWidgetLabeled.lua")

local kCloseTextHoverColor = Color(0,0,0)
local kCloseTextNonHoverColor = Color(1,1,1)

local baseClass = GUIObject
class "GMTDRewardsScreenTester" (baseClass)

function GMTDRewardsScreenTester:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    kTesterWindow = self

    self:SetPosition(200, 2)
    self:SetColor(0,0,0)
    self:SetSize(450, 225)
    self:SetLayer(500)
    self:ListenForCursorInteractions()

    self.headerBar = CreateGUIObject("headerBar", GUIObject, self)
    self.headerBar:SetSize(450, 30)
    self.headerBar:SetColor(0,0.5,0.5)

    self.headerBarTitle = CreateGUIObject("headerBarTitle", GUIText, self.headerBar)
    self.headerBarTitle:AlignLeft()
    self.headerBarTitle:SetFont("AgencyBold", 23)
    self.headerBarTitle:SetText("TD Rewards Tester")
    self.headerBarTitle:SetColor(1,1,1)
    self.headerBarTitle:SetX(15)

    self.closeButton = CreateGUIObject("closeButton", GUIButton, self.headerBar)
    self.closeButton:AlignRight()
    self.closeButton:SetColor(1,0,0)
    self.closeButton:SetSize(30, 30)

    self:HookEvent(self.closeButton, "OnPressed", function()
        -- TODO(Salads): TDREWARDS - Debug Window, reset values to "real" progress when we hook up backend
        self:Destroy()
    end)

    self.closeButtonLabel = CreateGUIObject("closeButtonLabel", GUIText, self.closeButton)
    self.closeButtonLabel:AlignCenter()
    self.closeButtonLabel:SetFont("AgencyBold", 23)
    self.closeButtonLabel:SetText("X")
    self.closeButtonLabel:SetColor(kCloseTextNonHoverColor)

    self:HookEvent(self.closeButton, "OnMouseOverChanged", function()
        local newHover = self.closeButton:GetMouseOver()
        local textColor = newHover and kCloseTextHoverColor or kCloseTextNonHoverColor
        self.closeButtonLabel:SetColor(textColor)
    end)

    self.scrollPane = CreateGUIObject("scrollPane", GUIMenuScrollPane, self, {
        horizontalScrollBarEnabled = false,
        verticalScrollBarEnabled = true
    })
    self.scrollPane:SetSize(self:GetSize().x, self:GetSize().y - self.headerBar:GetSize().y)
    self.scrollPane:SetY(self.headerBar:GetSize().y)

    self.layout = CreateGUIObject("layout", GUIListLayout, self.scrollPane, {
        orientation = "vertical"
    })

    self.scrollPane:HookEvent(self.layout, "OnSizeChanged", self.scrollPane.SetPaneSize)

    local controlHeight = 40

    self.fieldHoursTester = CreateGUIObject("fieldHoursTester", GUIMenuNumberEntryWidget, self.layout, {
        minValue = 0,
        maxValue = 9001,
        decimalPlaces = 1,
        label = "Field Hours: ",
        entryFontSize = 20,
        labelFontSize = 20
    })
    self.fieldHoursTester:SetHeight(controlHeight)

    self:HookEvent(self.fieldHoursTester, "OnValueChanged", function()
        GetTDRewardsScreen():SetCurrentFieldHours(self.fieldHoursTester:GetValue())
    end)

    self.commanderHoursTester = CreateGUIObject("commanderHoursTester", GUIMenuNumberEntryWidget, self.layout, {
        minValue = 0,
        maxValue = 9001,
        decimalPlaces = 1,
        label = "Commander Hours: ",
        entryFontSize = 20,
        labelFontSize = 20
    })
    self.commanderHoursTester:SetHeight(controlHeight)

    self:HookEvent(self.commanderHoursTester, "OnValueChanged", function()
        GetTDRewardsScreen():SetCurrentCommanderHours(self.commanderHoursTester:GetValue())
    end)

    self.fieldVictoriesTester = CreateGUIObject("fieldVictoriesTester", GUIMenuNumberEntryWidget, self.layout, {
        minValue = 0,
        maxValue = 9001,
        decimalPlaces = 1,
        label = "Field Victories: ",
        entryFontSize = 20,
        labelFontSize = 20
    })
    self.fieldVictoriesTester:SetHeight(controlHeight)

    self:HookEvent(self.fieldVictoriesTester, "OnValueChanged", function()
        GetTDRewardsScreen():SetCurrentFieldVictories(self.fieldVictoriesTester:GetValue())
    end)

    self.commanderVictoriesTester = CreateGUIObject("fieldHoursTester", GUIMenuNumberEntryWidget, self.layout, {
        minValue = 0,
        maxValue = 9001,
        decimalPlaces = 1,
        label = "Commander Victories: ",
        entryFontSize = 20,
        labelFontSize = 20
    })
    self.commanderVictoriesTester:SetHeight(controlHeight)

    self:HookEvent(self.commanderVictoriesTester, "OnValueChanged", function()
        GetTDRewardsScreen():SetCurrentCommanderVictories(self.commanderVictoriesTester:GetValue())
    end)

    self.lockedModeTester = CreateGUIObject("fieldHoursTester", GUIMenuCheckboxWidgetLabeled, self.layout, {
        label = "Show Locked: ",
    })
    self.lockedModeTester:SetScale(GetScaledVector() * 0.5)

    self:HookEvent(self.lockedModeTester, "OnValueChanged", function()
        GetTDRewardsScreen():SetIsLocked(self.lockedModeTester:GetValue())
    end)

end

function GMTDRewardsScreenTester:Uninitialize()
    kTesterWindow = nil
end
