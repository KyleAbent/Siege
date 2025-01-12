-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/DebugGUI/GBDDetailsWindow.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
--  Details window for bot debugging interface. Shows all information about the bot
--  Current Action, Aim Vector, Known Ents, etc.
--  Can also "follow" the bot to view it in "Follow" spectator mode.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/GUIMenuBasicBox.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")
Script.Load("lua/menu2/widgets/GUIMenuCheckboxWidgetLabeled.lua")
Script.Load("lua/GUI/style/GUIStyledText.lua")
Script.Load("lua/menu2/widgets/GUIMenuScrollPane.lua")
Script.Load("lua/IterableDict.lua")
Script.Load("lua/bots/DebugGUI/GBDDetailsSection.lua")

local kBotTargetUpdateRate = 0.15
local kLayoutStartY = 20
local kTitleFont = ReadOnly({family = "AgencyBold", size = 45})
local kBotNameFont = ReadOnly({family = "Agency", size = 37})

local baseClass = GUIMenuBasicBox
---@class GBDDetailsWindow : GUIMenuBasicBox
class "GBDDetailsWindow" (baseClass)

GBDDetailsWindow:AddClassProperty("BotEntityId", Entity.invalidId)

function GBDDetailsWindow:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:SetLayer(kGUILayerDebugUI)
    self:SetColor(0, 0, 0, 0.7)

    self.debugSectionObjs = IterableDict() -- Section Name -> Obj

    self.listLayout = CreateGUIObject("listLayout", GUIListLayout, self,
    {
        orientation = "vertical",
        align = "top",
        spacing = 20,
    }, errorDepth)
    self.listLayout:SetY(kLayoutStartY)

    self.title = CreateGUIObject("title", GUIStyledText, self.listLayout,
    {
        font = kTitleFont,
        align = "top",
        style = MenuStyle.kMainBarButtonGlow
    }, errorDepth)
    self.title:SetText("BOT DETAILS")

    self.followModeCheckbox = CreateGUIObject("followModeOption", GUIMenuCheckboxWidgetLabeled, self.listLayout,
    {
        label = "FOLLOW MODE",
        align = "center",
    }, errorDepth)

    self.botName = CreateGUIObject("botName", GUIText, self.listLayout,
    {
        text = "No Name",
        font = kBotNameFont,
        align = "center",
    }, errorDepth)

    self.refreshButton = CreateGUIObject("refreshButton", GUIMenuButton, self.listLayout,
    {
        label = "Refresh",
        font = MenuStyle.kButtonFont,
        align = "center"
    }, errorDepth)

    self.scrollPane = CreateGUIObject("detailsScrollPane", GUIMenuScrollPane, self.listLayout)
    self.debugSectionsLayout = CreateGUIObject("debugSectionsLayout", GUIListLayout, self.scrollPane,
    {
        orientation = "vertical",
        spacing = 20
    })
    self.scrollPane:HookEvent(self.debugSectionsLayout, "OnSizeChanged", self.scrollPane.SetPaneSize)

    self:HookEvent(self, "OnBotEntityIdChanged", self.OnBotTargetChanged)
    self:HookEvent(self.followModeCheckbox, "OnValueChanged", self.OnFollowModeChanged)
    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)
    self:HookEvent(self.refreshButton, "OnPressed", self.OnRefreshPressed)
    self:AlignTopRight()

end

function GBDDetailsWindow:OnRefreshPressed()
    self:ClearDebugSections()
    self:FireEvent("OnRefreshPressed")
end


function GBDDetailsWindow:AddOrUpdateDebugSection(sectionName, sectionContents)

    if self.debugSectionObjs[sectionName] then -- Update
        local obj = self.debugSectionObjs[sectionName]
        obj:SetSectionString(sectionContents)
    else -- Add new
        local newObj = CreateGUIObject("debugSection", GBDDetailsSection, self.debugSectionsLayout,
        {
            headerText = sectionName
        })
        self.debugSectionObjs[sectionName] = newObj
        newObj:SetWidth(self.scrollPane:GetSize().x - self.scrollPane:GetScrollBarThickness())
        newObj:SetSectionString(sectionContents)
    end

end

function GBDDetailsWindow:ClearDebugSections()
    for sectionName, obj in pairs(self.debugSectionObjs) do
        obj:Destroy()
    end
    self.debugSectionObjs:Clear()
end


function GBDDetailsWindow:OnBotTargetChanged(newTargetId)
    if self.callback_BotTargetUpdate then
        self:RemoveTimedCallback(self.callback_BotTargetUpdate)
        self.callback_BotTargetUpdate = nil
    end

    if newTargetId ~= Entity.invalidId then
        self.callback_BotTargetUpdate = self:AddTimedCallback(self.UpdateBotTarget, kBotTargetUpdateRate, true)
    end

end

function GBDDetailsWindow:UpdateBotTarget()

    local botEnt = Shared.GetEntity(self:GetBotEntityId())
    if not botEnt then
        self:SetBotEntityId(Entity.invalidId)
        return
    end

    local color = kNeutralTeamColor
    local teamName = "Ready Room" -- i know, manual /shrug
    if botEnt.teamJoined then
        if botEnt.team == kMarineTeamType then
            color = kMarineTeamColor
            teamName = "Marines"
        elseif botEnt.team == kAlienTeamType then
            color = kAlienTeamColor
            teamName = "Aliens"
        end
    end

    self.botName:SetColor(ColorIntToColor(color))
    self.botName:SetText(string.format("%s (%s)", botEnt.name, teamName))

end

function GBDDetailsWindow:OnFollowModeChanged(newValue)
    gBotDebugWindow:SetFollowingMode(newValue)
end

function GBDDetailsWindow:ClearFollowModeCheckbox()
    self.followModeCheckbox:SetValue(false)
end

function GBDDetailsWindow:OnSizeChanged(newSize)
    self.scrollPane:SetSize(newSize.x, newSize.y - self.scrollPane:GetPosition().y - 250)

    local sectionWidth = self.scrollPane:GetSize().x - self.scrollPane:GetScrollBarThickness()
    for i = 1, #self.debugSectionObjs do
        self.debugSectionObjs[i]:SetWidth(sectionWidth)
    end

end