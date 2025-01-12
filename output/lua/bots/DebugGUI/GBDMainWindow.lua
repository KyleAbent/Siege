-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/DebugGUI/GBDMainWindow.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
--  Main window for the Bot Debugging tools.
--  Shows a list of all the bots currently on the Server.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/menu2/GUIMenuBasicBox.lua")
Script.Load("lua/menu2/widgets/GUIMenuScrollPane.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")
Script.Load("lua/menu2/widgets/GUIMenuButton.lua")
Script.Load("lua/UnorderedSet.lua")
Script.Load("lua/IterableDict.lua")
Script.Load("lua/bots/DebugGUI/GBDBotButton.lua")
Script.Load("lua/bots/DebugGUI/GBDDetailsWindow.lua")
Script.Load("lua/menu2/GUIMenuText.lua")
Script.Load("lua/GUI/style/GUIStyledText.lua")

local kRefreshRate = 0.5
local kDefaultWidthPercent = 0.15
local kLayoutStartY = 20
local kTitleFont = ReadOnly({family = "AgencyBold", size = 45})
local kFollowingLabelFont = ReadOnly({family = "AgencyBold", size = 30})

---@class GBDMainWindow : GUIMenuBasicBox
local baseClass = GUIMenuBasicBox
class "GBDMainWindow" (baseClass)

GBDMainWindow:AddClassProperty("TargetedBotId", Entity.invalidId)
GBDMainWindow:AddClassProperty("IsFollowingBot", false)

function GBDMainWindow:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:ListenForKeyInteractions()

    self.botIdsToButton = IterableDict()
    self.selectedButton = nil

    self.detailsWindow = CreateGUIObject("detailsWindow", GBDDetailsWindow, nil)
    self.detailsWindow:SetVisible(false)

    self.followingLabel = CreateGUIObject("followingLabel", GUIText)
    self.followingLabel:SetFont(kFollowingLabelFont)
    self.followingLabel:AlignTop()
    self.followingLabel:SetText("FOLLOWING - [SPACE] TO STOP")
    self.followingLabel:SetVisible(false)
    self.followingLabel:HookEvent(self, "OnIsFollowingBotChanged",
    function(label, newIsFollowing)
        label:SetVisible(newIsFollowing)
    end)

    self.listLayout = CreateGUIObject("listLayout", GUIListLayout, self,
    {
        orientation = "vertical",
        spacing = 20,
        align = "top",
    }, errorDepth)
    self.listLayout:SetY(kLayoutStartY)

    self.titleText = CreateGUIObject("titleText", GUIStyledText, self.listLayout,
    {
        align = "top",
        font = kTitleFont,
        style = MenuStyle.kMainBarButtonGlow
    })
    self.titleText:SetText("BOT SELECTION WINDOW")

    self.scrollPane = CreateGUIObject("scrollPane", GUIMenuScrollPane, self.listLayout,
    {
        horizontalScrollBarEnabled = false,
        verticalScrollBarEnabled = true,
    }, errorDepth)

    self.botButtonsLayout = CreateGUIObject("botButtonsLayout", GUIListLayout, self.scrollPane,
    {
        orientation = "vertical",
        spacing = 10,
    }, errorDepth)
    self.botButtonsLayout:AlignTop()

    self:HookEvent(GetGlobalEventDispatcher(), "OnResolutionChanged", self.OnResolutionChanged)
    self.scrollPane:HookEvent(self.botButtonsLayout, "OnSizeChanged", self.scrollPane.SetPaneSize)
    self:SetLayer(kGUILayerDebugUI)

    self:HookEvent(self.detailsWindow, "OnRefreshPressed", self.OnRefreshPressed)

    self:OnResolutionChanged(Client.GetScreenWidth(), Client.GetScreenHeight()) -- Initialize Sizing
    self:SetColor(0, 0, 0, 0.7)

    self:AddTimedCallback(self.RefreshBots, kRefreshRate, true)

end

function GBDMainWindow:OnRefreshPressed()
    Client.SendNetworkMessage("ClientBotDebugTarget", {targetId = self:GetTargetedBotId()}, true)
    Client.SendNetworkMessage("BotDebugSetFollowMode", {follow = self:GetIsFollowingBot()}, true)
end

function GBDMainWindow:SetFollowingMode(isFollowing)
    Client.SendNetworkMessage("BotDebugSetFollowMode", {follow = isFollowing}, true)
    self:SetIsFollowingBot(isFollowing)
end

function GBDMainWindow:SetBotDebuggingTargetId(botId)
    Client.SendNetworkMessage("ClientBotDebugTarget", {targetId = botId}, true)
end

function GBDMainWindow:OnKey(key, down)
    if self:GetIsFollowingBot() and key == InputKey.Space then
        self:SetFollowingMode(false)
        self.detailsWindow:ClearFollowModeCheckbox()
    end

    return false
end

function GBDMainWindow:OnBotSelected(selectedButton)

    local botId = selectedButton:GetBotEntityId()
    self:SetBotDebuggingTargetId(botId)

    -- Return if same button, as it's already flipped is Selected property
    if self.selectedButton == selectedButton then
        return
    end

    if self.selectedButton then
        self.selectedButton:SetIsSelected(false)
    end

    self.selectedButton = selectedButton

    local player = Client.GetLocalPlayer()
    assert(player, "Player does not exist when selecting bot to debug!")

    self:SetTargetedBotId(botId)
    self.detailsWindow:SetBotEntityId(botId)
    self.detailsWindow:SetVisible(true)

end

function GBDMainWindow:UnselectBot()
    if self.selectedButton then
        self.selectedButton:SetIsSelected(false)
        self:SetTargetedBotId(Entity.invalidId)
        self.detailsWindow:SetBotEntityId(Entity.invalidId)
        self.detailsWindow:SetVisible(false)
        self.detailsWindow:ClearDebugSections()
    end
end

function GBDMainWindow:SelectWithPlayerEntityId(entityId)
    for botId, button in pairs(self.botIdsToButton) do
        local botEnt = Shared.GetEntity(botId)
        if botEnt then
            if botEnt.playerEntity == entityId then
                button:FireEvent("OnMouseClick")
                return
            end
        end
    end
end

function GBDMainWindow:GetIsPlayerEntIdABot(playerEntId)
    for botId, button in pairs(self.botIdsToButton) do
        local botEnt = Shared.GetEntity(botId)
        if botEnt then
            if botEnt.playerEntity == playerEntId then
                return true
            end
        end
    end
    return false
end

function GBDMainWindow:RefreshBots()

    local keepBotIds = UnorderedSet()
    local bots = GetEntities("PlayerBot")
    for _, bot in ipairs(bots) do

        local botId = bot:GetId()
        if not self.botIdsToButton[botId] then
            local newBotButton = CreateGUIObject("botButton", GBDBotButton, self.botButtonsLayout)
            newBotButton:UpdateFromBot(bot)
            newBotButton:SetMaxWidth(self.scrollPane:GetSize().x - self.scrollPane:GetScrollBarThickness())
            self:HookEvent(newBotButton, "OnSelected", self.OnBotSelected)
            self.botIdsToButton[botId] = newBotButton
        else
            -- Update existing button
            local button = self.botIdsToButton[botId]
            assert(button, "Button does not exist, but bot id has been added!")
            button:UpdateFromBot(bot)

        end

        keepBotIds:Add(botId)
    end

    -- Remove old ids/buttons
    for id, button in pairs(self.botIdsToButton) do
        if not keepBotIds:Contains(id) then
            self.botIdsToButton[id] = nil

            if button == self.selectedButton then
                self.selectedButton = nil
            end

            button:Destroy()

        end
    end

end

function GBDMainWindow:AddOrUpdateDebugSection(sectionName, sectionContents)
    self.detailsWindow:AddOrUpdateDebugSection(sectionName, sectionContents)
end

function GBDMainWindow:OnResolutionChanged(newX, newY)

    local mockupRes = Vector(3840, 2160, 0)
    local res = Vector(newX, newY, 0)
    local scale = res / mockupRes
    scale = math.min(scale.x, scale.y)

    self:SetScale(scale, scale)
    self.detailsWindow:SetScale(scale, scale) -- Not a child of GBDMainWindow
    self:SetSize(3840 * kDefaultWidthPercent, 2160)
    self.detailsWindow:SetSize(self:GetSize())

    self.scrollPane:SetSize(
            3840 * kDefaultWidthPercent,
            2160 - self.scrollPane:GetPosition().y - self.listLayout:GetPosition().y - 250)

    self.followingLabel:SetY(newY * 0.15)
end

function GBDMainWindow:Uninitialize()
    if self.detailsWindow then
        self.detailsWindow:Destroy()
    end

    if self.followingLabel then
        self.followingLabel:Destroy()
    end
end


--McG: Because I'm lazy
Event.Hook("Console_bot_test", function()

    Shared.ConsoleCommand("tests 1")
    Shared.ConsoleCommand("spectate")
    Shared.ConsoleCommand("addbots 12")
    Shared.ConsoleCommand("addbot 1 1 com")
    Shared.ConsoleCommand("addbot 1 2 com")

end)

--Axtel: Because I'm lazier
Event.Hook("Console_bot_test_comm", function(team)

    Shared.ConsoleCommand("tests 1")
    Shared.ConsoleCommand("cheats 1")
    Shared.ConsoleCommand("spectate")
    Shared.ConsoleCommand("addbot 1 "..team.." com")

end)

--Axtel: Because I'm lazier
Event.Hook("Console_bot_test_lf", function(lifeform)

    Shared.ConsoleCommand("bot_lockevolve " .. (lifeform or ""))
    Shared.ConsoleCommand("cheats 1")
    Shared.ConsoleCommand("allfree")
    Shared.ConsoleCommand("fastevolve")

end)
