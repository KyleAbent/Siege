-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDChatWidgetMessage.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/layouts/GUIListLayout.lua")

local kChatMessageColor       = ColorFrom255(219, 219, 219)
local kSystemChatMessageColor = ColorFrom255(62,  178, 104)

local kChatSenderNameColors = -- Team-Specific Colors for the name of the sender.
{
    [kTeamReadyRoom]              = ColorFrom255(219, 219, 219),
    [kTeam1Index]                 = ColorFrom255(147, 233, 255),
    [kTeam2Index]                 = ColorFrom255(255, 191, 68),
    [kThunderdomeSystemUserId]    = kSystemChatMessageColor
}

local kSenderTextFontFamily = "AgencyBold" -- TODO(Salads): TD - Look into Arial Black for bold text
local kSenderTextFontSize = 34

local kMessageTextFontFamily = "Arial"
local kMessageTextFontSize = 22

local kSenderPostFix = ": "
local kMessageClipHeight = -1
local kMessageMaxClipWidth = 9999 -- Theres no negative for width, sooo
local commanderIconPadding = 10

local kPadding = 15

class "GMTDChatWidgetMessage" (GUIObject)

GMTDChatWidgetMessage.kCommanderIcon = PrecacheAsset("ui/badges/commander.dds")

GMTDChatWidgetMessage:AddClassProperty("MaxWidth"  , -1) -- Max width of both the sender name and the message contents
GMTDChatWidgetMessage:AddClassProperty("SenderTeam", kTeamInvalid)
GMTDChatWidgetMessage:AddClassProperty("SenderName", "")
GMTDChatWidgetMessage:AddClassProperty("IsExtension", false)
GMTDChatWidgetMessage:AddClassProperty("SenderMessage", "")
GMTDChatWidgetMessage:AddClassProperty("SenderSteamID64", "")
GMTDChatWidgetMessage:AddClassProperty("IsCommander", false)

function GMTDChatWidgetMessage:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.commanderIcon = CreateGUIObject("commanderIcon", GUIObject, self)
    self.commanderIcon:SetTexture(self.kCommanderIcon)
    self.commanderIcon:SetColor(1,1,1)
    self.commanderIcon:SetVisible(false)

    self.senderText = CreateGUIObject("senderText", GUIText, self)
    self.senderText:SetFont(kSenderTextFontFamily, kSenderTextFontSize)
    -- Color for sender name will be set when 'SenderTeam' property is changed.

    -- The message text thats on the same line as the author
    self.senderMessageText = CreateGUIObject("senderMessageText", GUIText, self,
    {
        font =
        {
            family = kMessageTextFontFamily,
            size = kMessageTextFontSize,
        },

        color = kChatMessageColor
    })

    -- The message text that comes after that first line.
    self.senderMessageText2 = CreateGUIObject("senderMessageText2", GUIParagraph, self,
    {
        font =
        {
            family = kMessageTextFontFamily,
            size = kMessageTextFontSize,
        },

        color = kChatMessageColor,
        justification = GUIItem.Align_Min
    })

    self:HookEvent(self, "OnMaxWidthChanged"           , self.UpdateTextFormatting)
    self:HookEvent(self, "OnSenderTeamChanged"         , self.UpdateMessageColors)
    self:HookEvent(self, "OnSenderNameChanged"         , self.OnSenderNameChanged)
    self:HookEvent(self, "OnSenderMessageChanged"      , self.UpdateTextFormatting)
    self:HookEvent(self, "OnIsExtensionChanged"        , self.UpdateTextFormatting)
    self:HookEvent(self, "OnSenderSteamID64Changed"    , self.UpdateMessageColors)
    self:HookEvent(self, "OnIsCommanderChanged"        , self.UpdateTextFormatting)

end

function GMTDChatWidgetMessage:OnSenderNameChanged(newSender)
    self.senderText:SetText(string.format("%s%s", newSender, kSenderPostFix))
    self:UpdateTextFormatting()
end

function GMTDChatWidgetMessage:UpdateMessageColors()

    local newTeam = self:GetSenderTeam()
    local newSenderColor = kChatSenderNameColors[newTeam]

    if newSenderColor then
        self.senderText:SetColor(newSenderColor)
    else
        SLog("[TD-UI] ERROR: GMTDChatWidgetMessage - Sender Team '%s' does not exist in kChatSenderNameColors!", newTeam)
    end

    local messageColor = ConditionalValue(newTeam == kThunderdomeSystemUserId, kSystemChatMessageColor, kChatMessageColor)
    self.senderMessageText:SetColor(messageColor)
    self.senderMessageText2:SetColor(messageColor)

end

function GMTDChatWidgetMessage:UpdateTextFormatting()

    local isExtension = self:GetIsExtension()
    local fullMessage = self:GetSenderMessage()
    local isCommander = self:GetIsCommander() and not isExtension -- Only show commander icon next to sender name

    if fullMessage == "" or ( self:GetSenderName() == "" and self:GetSenderSteamID64() ~= kThunderdomeSystemUserId) then
        return
    end

    local topPadding
    local senderWidth
    local senderHeight
    local commanderPadding

    if isExtension then
        topPadding = 0
        senderWidth  = 0
        senderHeight = 0
        commanderPadding = 0
    else
        topPadding = kPadding
        senderWidth  = self.senderText:GetSize().x
        senderHeight = self.senderText:GetSize().y
        commanderPadding = isCommander and commanderIconPadding or 0
    end

    -- Update visibility and split full message into fitting parts.
    local maxWidth = self:GetMaxWidth()
    self.senderText:SetVisible(not isExtension)

    local commanderIconSizeScalar = 0
    if isCommander then
        commanderIconSizeScalar = senderHeight
        self.commanderIcon:SetSize(commanderIconSizeScalar, commanderIconSizeScalar)
        self.commanderIcon:SetPosition(0, topPadding)
    end

    self.senderText:SetPosition(commanderIconSizeScalar + commanderPadding, topPadding)

    local messageTop, messageBottom = TextWrap(self.senderMessageText:GetTextObject(), fullMessage, 0, maxWidth - senderWidth - commanderIconSizeScalar - commanderPadding)
    messageTop = messageTop or ""
    messageBottom = messageBottom or ""

    self.senderMessageText:SetText(messageTop)
    self.senderMessageText2:SetText(messageBottom)

    -- Set position of the top message
    local topMessageHeight = self.senderMessageText:GetSize().y
    local topMessagePositionX = senderWidth + commanderIconSizeScalar + commanderPadding
    local topMessagePositionY = ConditionalValue(isExtension, 0, topPadding + (senderHeight - topMessageHeight))
    self.senderMessageText:SetPosition(topMessagePositionX, topMessagePositionY)

    -- Update bottom message position and paragraph size
    local widthForBottomMessage = maxWidth
    local bottomMessageTopPadding = 0
    local bottomMessageClipWidth = ConditionalValue(maxWidth < 0, kMessageMaxClipWidth, widthForBottomMessage)
    self.senderMessageText2:SetParagraphSize(bottomMessageClipWidth, kMessageClipHeight)
    self.senderMessageText2:SetPosition(0, topMessagePositionY + topMessageHeight + bottomMessageTopPadding)

    local bottomMessageHeight = ConditionalValue(messageBottom == "", 0, self.senderMessageText2:GetSize().y)

    local totalHeight = math.max(topPadding + senderHeight, topMessagePositionY + topMessageHeight) + bottomMessageTopPadding + bottomMessageHeight

    self:SetSize(maxWidth, totalHeight)

    self.senderMessageText:SetVisible(true)
    self.senderMessageText2:SetVisible(bottomMessageHeight > 0)
    self.commanderIcon:SetVisible(isCommander)

end
