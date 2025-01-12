-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDChatWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/widgets/Thunderdome/GMTDChatWidgetMessage.lua")
Script.Load("lua/menu2/widgets/GUIMenuScrollPane.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")
Script.Load("lua/menu2/widgets/GUIMenuTextEntryWidget.lua")
Script.Load("lua/GUI/GUIParagraph.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDChatInputText.lua")

local kFakeChat = false -- Debug. If true, will just add the text in input bar to the chat window. (Skipping TD network send)

local kChatInputPadding = 14
local kAutoScrollLeniency = 50


---@class GMTDChatWidget : GUIObject
class "GMTDChatWidget" (GUIObject)

GMTDChatWidget.kBackgroundTexture = PrecacheAsset("ui/thunderdome/td_chat_background.dds")
GMTDChatWidget.kInputBarTexture = PrecacheAsset("ui/thunderdome/td_chat_inputbar.dds")

GMTDChatWidget.kChatInputSize = Vector(1680, 89, 0)

GMTDChatWidget:AddClassProperty("LastChatSendTime", 0)
GMTDChatWidget:AddClassProperty("ChatMessagesEnabled", false)
GMTDChatWidget:AddClassProperty("TeamColorsEnabled", true)
GMTDChatWidget:AddClassProperty("NameOverridesTable", {}, true)
GMTDChatWidget:AddClassProperty("LobbyUseType", {}, kLobbyUsageType.Match)
GMTDChatWidget:AddClassProperty("InputLabelColor", MenuStyle.kHighlight)
GMTDChatWidget:AddCompositeClassProperty("BackPadding", "layout")

function GMTDChatWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    RequireType({"nil", "boolean"}, params.disableTeamColors, "params.disableTeamColors", errorDepth)
    RequireType({"nil", "string"},  params.label, "params.label", errorDepth)
    RequireType({"number"},         params.lobbyUseType, "params.lobbyUseType", errorDepth)
    RequireType({"number"},         params.inputHeight, "params.inputHeight", errorDepth)
    RequireType({"number"},         params.entryYOffset, "params.entryYOffset", errorDepth)

    params.label = params.label or Locale.ResolveString("THUNDERDOME_CHAT_LABEL")

    self:SetLobbyUseType( params.lobbyUseType )

    self.autoScroll = false
    self.lastMessageObj = nil

    self:SetTexture(self.kBackgroundTexture)
    self:SetSizeFromTexture()
    self:SetColor(1,1,1)

    self.chatScrollPane = CreateGUIObject("chatScrollPane", GUIMenuScrollPane, self, { horizontalScrollBarEnabled = false }, errorDepth)

    -- Will resize in a controlled manner so we get a chat-like scroll behavior with the chat widget.
    self.layoutHolder = CreateGUIObject("layoutHolder", GUIObject, self.chatScrollPane, params,errorDepth)

    self.layout = CreateGUIObject("chatMessagesLayout", GUIListLayout, self.layoutHolder, { orientation = "vertical", fixedMinorSize = true }, errorDepth)
    self.layout:AlignBottomLeft()
    self:HookEvent(self.layout, "OnSizeChanged", self.OnLayoutSizeChanged)

    self.chatInput = CreateGUIObject("chatInput", GUIMenuTextEntryWidget, self,
    {
        labelFont = "AgencyBold",
        labelFontSize = 34,
        entryFont = "Arial",
        entryFontSize = 22,
        entryYOffset = params.entryYOffset or 0,
        displayClass = GMTDChatInputText,
    }, errorDepth)

    self.chatInput:SetSize(self:GetSize().x - kChatInputPadding, params.inputHeight)
    self.chatInput:SetLabel(params.label .. ": ")
    self.chatInput:SetPosition(0, -kChatInputPadding)
    self.chatInput:AlignBottom()
    self.chatInput:SetMaxCharacterCount(500)
    self:HookEvent(self.chatInput, "OnEditAccepted", self.OnChatInputAccepted)

    self:HookEvent(self, "OnNameOverridesTableChanged", self.OnNameOverridesTableChanged)
    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)

    self:HookEvent(self, "OnInputLabelColorChanged",
    function(_, newColor)
        self.chatInput:SetLabelHighlightColor(newColor)
        self.chatInput:SetLabelEditingColor(newColor)
    end)

    self.chatMessages = {}

    if params.disableTeamColors then
        self:SetTeamColorsEnabled(not params.disableTeamColors)
    end

    --Since we have multiple instances of this class, we need to ensure the chat message matches our config
    --In some cases local-client can be in multiple lobby-types at once (granted, not for long)
    self.TDOnChatMessage = function(clientModeObject, lobbyId, senderName, message, teamIndex, senderSteamID64)
        if self:GetChatMessagesEnabled() then
            local lobUsage = self:GetLobbyUseType()
            local td = Thunderdome()
            assert(td, "Error: No Thunderdome object found")

             -- Back-end will filter team numbers.
            local isLobbyGroup = td:GetIsGroupId( lobbyId )

            SLog("GMTDChatWidget.TDOnChatMessage")
            SLog("    isLobbyGroup: %s", isLobbyGroup)
            SLog("        lobUsage: %s", lobUsage)

            if isLobbyGroup and lobUsage == kLobbyUsageType.Group then
                self:AddNewChatMessage(lobbyId, senderName, teamIndex, message, senderSteamID64)
                
            elseif not isLobbyGroup and lobUsage == kLobbyUsageType.Match then
                self:AddNewChatMessage(lobbyId, senderName, teamIndex, message, senderSteamID64)
            else
                Log("[TD-UI] Error: No Lobby usage-type set for Chat window")
            end
        end
    end

    self:OnSizeChanged(self:GetSize())

end

function GMTDChatWidget:OnNameOverridesTableChanged()
    local steamIdsToNames = self:GetNameOverridesTable()

    for i = 1, #self.chatMessages do

        local chatMessage = self.chatMessages[i]
        local overrideName = steamIdsToNames[chatMessage:GetSenderSteamID64()]
        if overrideName then
            chatMessage:SetSenderName(overrideName)
        end

    end
end

function GMTDChatWidget:AddNewChatMessage(lobbyId, senderName, senderTeam, message, senderSteamID64)

    local team1Commander, team2Commander = Thunderdome():GetLobbyCommanderIds()

    local showTeams = self:GetTeamColorsEnabled()
    if not showTeams then
        if senderTeam ~= kThunderdomeSystemUserId then
            senderTeam = kTeamReadyRoom
        end

        team1Commander = ""
        team2Commander = ""
    end

    -- Determine if we should auto-scroll before actually adding the chat message.
    local chatScrollBar = self.chatScrollPane:GetVerticalBar()
    self.autoScroll = (chatScrollBar:GetValue() + kAutoScrollLeniency >= chatScrollBar:GetScrollRange())

    local scrollbarWidth = 32 -- Scroller width is calculated, so here's a cheap shot

    local nameOverrides = self:GetNameOverridesTable()
    local realSenderName = nameOverrides[senderSteamID64] or senderName

    local newChatMessage = CreateGUIObject(string.format("chatMessage_%s", #self.chatMessages + 1), GMTDChatWidgetMessage, self.layout)
    newChatMessage:SetSenderName( ( senderSteamID64 == kThunderdomeSystemUserId and "" or realSenderName ) )
    newChatMessage:SetSenderMessage(message)
    newChatMessage:SetSenderTeam(senderTeam)
    newChatMessage:SetSenderSteamID64(senderSteamID64)
    newChatMessage:SetMaxWidth(self.chatScrollPane:GetSize().x - scrollbarWidth)
    newChatMessage:SetIsCommander(senderSteamID64 == team1Commander or senderSteamID64 == team2Commander)
    newChatMessage:SetLayer(#self.chatMessages)
    table.insert(self.chatMessages, newChatMessage)

    -- Hide sender name if the last sender name is the same.
    if self.lastMessageObj then
        newChatMessage:SetIsExtension(self.lastMessageObj:GetSenderSteamID64() == newChatMessage:GetSenderSteamID64())
    end

    self.lastMessageObj = newChatMessage

    if self.autoScroll then
        chatScrollBar:SetValue(chatScrollBar:GetScrollRange())
    end

end

function GMTDChatWidget:Clear()
    self.autoScroll = false
    self.lastMessageObj = nil

    for i = 1, #self.chatMessages do
        self.chatMessages[i]:Destroy()
    end

    self.chatMessages = {}
end

function GMTDChatWidget:OnSizeChanged(newSize)

    local chatWidthPadding = 25
    local chatHeightPadding = 10

    self.chatInput:SetWidth(self:GetSize().x - kChatInputPadding)

    self.chatScrollPane:SetPosition(chatWidthPadding, chatHeightPadding)
    self.chatScrollPane:SetSize(newSize.x - (chatWidthPadding * 2), newSize.y - self.chatInput:GetSize().y - kChatInputPadding - (chatHeightPadding * 2))
    self:OnLayoutSizeChanged() -- Update pane size etc

end

function GMTDChatWidget:OnChatInputAccepted()

    if not kFakeChat then

        local td = Thunderdome()
        assert(td, "Error: No valid Thunderdome object found!")

        local lobbyId = nil
        if td:GetIsGroupQueueEnabled() then
            lobbyId = td:GetGroupLobbyId()
        else
            lobbyId = td:GetActiveLobbyId()
        end
        assert(lobbyId, "Error: No valid LobbyModel found for any lobby-type")
        
        local lastSendTime = self:GetLastChatSendTime()
        local now = Shared.GetSystemTime()

        if (lastSendTime + kLobbyChatSendRate) < now then

            local message = self.chatInput:GetValue()
            message = message:gsub("%s+", " ") -- Trim all space characters to be just 1 space.
            td:SendChatMessage( message, lobbyId )

            self.chatInput:SetValue("")
            self:SetLastChatSendTime(now)

        end

    else
        self:AddNewChatMessage("Fake Name", kTeamReadyRoom, self.chatInput:GetValue())
    end

    self.chatInput:SetEditing(true) -- never leave focus of text entry when sending a message.

end

function GMTDChatWidget:OnLayoutSizeChanged()

    local scrollPaneSize = self.chatScrollPane:GetSize()
    local layoutSize = self.layout:GetSize()
    local minHolderWidth = scrollPaneSize.x
    local minHolderHeight = scrollPaneSize.y

    local newHolderSizeX = math.max(minHolderWidth, layoutSize.x)
    local newHolderSizeY = math.max(minHolderHeight, layoutSize.y)

    self.layoutHolder:SetSize(newHolderSizeX, newHolderSizeY)
    self.chatScrollPane:SetPaneSize(self.layoutHolder:GetSize())

end