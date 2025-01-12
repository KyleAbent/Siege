-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/DebugGUI/GBDBotButton.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
--  For the main window. Shows Bot's name, and current class.
--
--  Events
--      OnSelected     Fires when the button is "selected". Passes button as arg
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/menu2/GUIMenuTruncatedText.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")

local kDefaultBotPlayerName = "[John Doe]" -- Different then actual default, for less confusion
local kDefaultBotPlayerClassName = "None"
local kDeadClassName = "Dead"
local kAlienTeamColor = kAlienFontColor
local kMarineTeamColor = kMarineFontColor
local kDeadColor = Color(1,0,0)
local kNeutralTeamColor = Color(0.2, 0.2, 0.2)
local kSelectedMarkWidthPercent = 0.05

---@class GBDBotButton : GUIButton
local baseClass = GUIButton
class "GBDBotButton" (baseClass)

GBDBotButton.kBotNameFont = ReadOnly{family = "Agency", size = 35}
GBDBotButton.kBotClassNameFont = ReadOnly{family = "Agency", size = 29}

-- These properties both require a valid player entity on the bot.
GBDBotButton:AddClassProperty("BotName", kDefaultBotPlayerName)
GBDBotButton:AddClassProperty("BotPlayerClassName", kDefaultBotPlayerClassName)
GBDBotButton:AddClassProperty("BotEntityId", Entity.invalidId)
GBDBotButton:AddClassProperty("MaxWidth", 150)
GBDBotButton:AddClassProperty("IsSelected", false)

function GBDBotButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self.listLayout = CreateGUIObject("listLayout", GUIListLayout, self,
    {
        orientation = "vertical",
    })

    self.selectedMark = CreateGUIObject("selectedMark", GUIObject, self)
    self.selectedMark:SetColor(0, 1, 0)
    self.selectedMark:SetVisible(false)
    self.selectedMark:AlignRight()

    self.botName = CreateGUIObject("botName", GUIMenuTruncatedText, self.listLayout,
    {
        font = self.kBotNameFont,
        text = kDefaultBotPlayerName,
    })

    self.botPlayerClassName = CreateGUIObject("botPlayerClassName", GUIMenuTruncatedText, self.listLayout,
    {
        font = self.kBotClassNameFont,
        text = kDefaultBotPlayerClassName,
    })

    self.doubleClickEnabled = true
    self.pendingCameraBotSnap = false

    self:HookEvent(self, "OnMouseClick",
        function(button, double)
            if gBotDebugWindow:GetIsFollowingBot() then return end
            button:SetIsSelected(true)
            button:FireEvent("OnSelected", button)
            if double then
                self.pendingCameraBotSnap = true
            end
        end)
    self:HookEvent(self, "OnIsSelectedChanged", self.OnIsSelectedChanged)
    self:HookEvent(self.listLayout, "OnSizeChanged", self.SetSize)
    self:UpdateSize()
    self:SetColor(0.1, 0.1, 0.1)
end

function GBDBotButton:OnIsSelectedChanged(newIsSelected)
    self.selectedMark:SetVisible(newIsSelected)
end

function GBDBotButton:UpdateSize()

    local maxWidth = self:GetMaxWidth()
    self.botName:SetWidth(maxWidth)
    self.botPlayerClassName:SetWidth(maxWidth)
    self.botName:SetHeight(self.botName:GetTextSize().y)
    self.botPlayerClassName:SetHeight(self.botPlayerClassName:GetTextSize().y)

    -- Update root object size
    self:SetSize(maxWidth, self.listLayout:GetSize().y)

    -- Update selected mark size
    self.selectedMark:SetSize(maxWidth * kSelectedMarkWidthPercent, self.listLayout:GetSize().y)

end

function GBDBotButton:UpdateFromBot(bot)
    assert(bot, "GBDBotButton:UpdateFromBot - No bot was passed in!")

    self:SetBotEntityId(bot:GetId())
    local botName = bot.name or kDefaultBotPlayerName
    local botClassName = kDefaultBotPlayerClassName
    local isAlive = false
    local botTeam = -1

    if bot.teamJoined then
        botTeam = bot.team
    end


    local botPlayer = Shared.GetEntity(bot.playerEntity)
    if botPlayer then
        -- We are within relevancy range of the player entity.
        -- EZ Mode :)

        isAlive = botPlayer.GetIsAlive and botPlayer:GetIsAlive() or false

        if isAlive then
            botClassName = string.format("%s", botPlayer:GetClassName())
        else
            botClassName = kDeadClassName
        end

        if self.pendingCameraBotSnap then
        --Pending view-snap, move Camera to Blip position
            if botPlayer and isAlive then
                local botOrg = botPlayer:GetOrigin()
                local player = Client.GetLocalPlayer()
                player.followId = botPlayer:GetId()
                Client.SendNetworkMessage("SpectatePlayer", {entityId = player.followId}, true)
            end
            self.pendingCameraBotSnap = false
        end

    else
        -- We are not within relevancy distance,
        -- OR
        -- player is dead (blips get destroyed when player is dead)
        local mapBlips = GetEntities("MapBlip")
        local matchingBlip
        for _, blip in ipairs(mapBlips) do
            if blip.ownerEntityId == bot.playerEntity then
                matchingBlip = blip
                break
            end
        end

        if matchingBlip then -- Just not in range
            isAlive = matchingBlip:GetIsActive()
            if isAlive then
                botClassName = string.format("%s", EnumToString(kMinimapBlipType, matchingBlip:GetType()))
            else
                botClassName = kDeadClassName
            end
        else
            -- Dead
            botClassName = kDeadClassName
        end

        if self.pendingCameraBotSnap then
        --Pending view-snap, move Camera to Blip position
            if matchingBlip then
                local player = Client.GetLocalPlayer()
                player.followId = matchingBlip.ownerEntityId
                Client.SendNetworkMessage("SpectatePlayer", {entityId = player.followId}, true)
            end
            self.pendingCameraBotSnap = false
        end

    end

    self.botName:SetText(botName)
    self.botPlayerClassName:SetText(botClassName)

    local color = kNeutralTeamColor
    if botTeam == -1 then -- bot has not joined a team yet.
        color = kNeutralTeamColor
    elseif not isAlive then
        color = kDeadColor
    elseif botTeam == kMarineTeamType then
        color = kMarineTeamColor
    elseif botTeam == kAlienTeamType then
        color = kAlienTeamColor
    end

    self.botName:SetColor(color)
    self.botPlayerClassName:SetColor(color)

    self:UpdateSize()

end