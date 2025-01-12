-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDPlayerRoleDisplayWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/UnorderedSet.lua")
Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/menu2/PlayerScreen/FriendsList/GUIMenuAvatar.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDLifeformPreferenceWidget.lua")
Script.Load("lua/menu2/widgets/GUIMenuTruncatedDisplayWidget.lua")

local kPlayerNamePaddingFraction = 0.2 -- How much space relative to background should we give to the player name.

local function SendLifeformChoices(self)

    if not Thunderdome():GetIsConnectedToLobby() then
        return
    end

    local lifeforms = {}
    for i = 1, #self.lifeformChoices do
        table.insert(lifeforms, self.lifeformChoices[i])
    end

    Thunderdome():SetLocalLifeformsChoices(lifeforms)

end

local function OnLifeformSelectionChanged(self, lifeform, selected)

    if selected then
        self.lifeformChoices:Add(lifeform)
    else
        self.lifeformChoices:RemoveElement(lifeform)
    end

    SendLifeformChoices(self)

end

class "GMTDPlayerRoleDisplayWidget" (GUIObject)

GMTDPlayerRoleDisplayWidget:AddClassProperty("IsCommander", false)

GMTDPlayerRoleDisplayWidget.kBackgroundTexture  = PrecacheAsset("ui/thunderdome/planning_player_background.dds")
GMTDPlayerRoleDisplayWidget.kAvatarFrameTexture = PrecacheAsset("ui/thunderdome/roledisplay_avatar_frame.dds")
GMTDPlayerRoleDisplayWidget.kCommanderIcon      = PrecacheAsset("ui/thunderdome/commander_icon.dds")

function GMTDPlayerRoleDisplayWidget:Reset()

    for i = 1, #self.lifeformWidgets do
        self.lifeformWidgets[i]:SetValue(false)
    end

    self:SetIsCommander(false)

end

function GMTDPlayerRoleDisplayWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.lifeformWidgets = {}
    self.lifeformChoices = UnorderedSet()

    self:SetTexture(self.kBackgroundTexture)
    self:SetSizeFromTexture()
    self:SetColor(1, 1, 1)

    self.avatar = CreateGUIObject("avatar", GUIMenuAvatar, self)
    self.avatar:SetPosition(0, 80)
    self.avatar:SetColor(1, 1, 1)
    self.avatar:SetSize(229, 229)
    self.avatar:AlignTop()

    self.avatarFrame = CreateGUIObject("avatarFrame", GUIObject, self.avatar)
    self.avatarFrame:SetTexture(self.kAvatarFrameTexture)
    self.avatarFrame:SetSize(self.avatar:GetSize())
    self.avatarFrame:SetColor(1, 1, 1)
    self.avatarFrame:AlignCenter()

    local playerNameFontSize = 50
    local currentWidth = self:GetSize().x
    self.playerName = CreateGUIObject("playerNameTruncator", GUIMenuTruncatedText, self)
    self.playerName:SetPosition(0, self.avatar:GetPosition().y + self.avatar:GetSize().y + 25)
    self.playerName:AlignTop()
    self.playerName:SetSize(currentWidth - (currentWidth * kPlayerNamePaddingFraction), playerNameFontSize)
    self.playerName:SetFont("AgencyBold", playerNameFontSize)
    self.playerName:SetAutoScroll(true)
    self.playerName:SetColor(ColorFrom255(206, 229, 234))

    self.pickLifeformsHelpText = CreateGUIObject("lifeformsHelpText", GUIText, self, {}, errorDepth)
    self.pickLifeformsHelpText:SetFont("Agency", 40)
    self.pickLifeformsHelpText:SetPosition(0, 470)
    self.pickLifeformsHelpText:SetColor(211/255, 159/255, 58/255)
    self.pickLifeformsHelpText:AlignTop()
    self.pickLifeformsHelpText:SetText(Locale.ResolveString("THUNDERDOME_PLANNING_PICKLIFEFORMS"))

    self.lifeformsLayout = CreateGUIObject("lifeformsLayout", GUIListLayout, self, { orientation = "vertical" }, errorDepth)
    self.lifeformsLayout:SetPosition(0, 550)
    self.lifeformsLayout:AlignTop()

    self.commanderIcon = CreateGUIObject("commanderIcon", GUIObject, self)
    self.commanderIcon:SetTexture(self.kCommanderIcon)
    self.commanderIcon:SetSizeFromTexture()
    self.commanderIcon:SetPosition(0, 480)
    self.commanderIcon:AlignTop()
    self.commanderIcon:SetColor(1,1,1)
    self.commanderIcon:SetVisible(false)

    self.commanderLabel = CreateGUIObject("commanderLabel", GUIText, self.commanderIcon)
    self.commanderLabel:AlignBottom()
    self.commanderLabel:SetText(Locale.ResolveString("THUNDERDOME_COMMANDER"))
    self.commanderLabel:SetFont("AgencyBold", 60)
    self.commanderLabel:SetPosition(0, 60)
    self.commanderLabel:SetColor(ColorFrom255(206, 229, 234))
    self.commanderLabel:SetVisible(false)

    for i = 1, #kLobbyLifeformTypes do

        local lifeformWidget = CreateGUIObject("lifeformWidget", GMTDLifeformPreferenceWidget, self.lifeformsLayout, params, errorDepth)
        lifeformWidget:SetLifeform(kLobbyLifeformTypes[i])
        lifeformWidget:SetLifeformIconSize(125, 125)

        self:HookEvent(lifeformWidget, "OnLifeformSelectionChanged", OnLifeformSelectionChanged)
        table.insert(self.lifeformWidgets, lifeformWidget)

    end

    self:HookEvent(self, "OnIsCommanderChanged", self.OnIsCommanderChanged)

    self.TDOnLobbyJoined = function(clientModeObj)
        self.playerName:SetText(string.UTF8Upper(Thunderdome():GetLocalPlayerProfile().name))
        self.avatar:SetSteamID64(GetLocalSteamID64())
    end

    self.TDOnPlayerDataChanged = function(clientModeObj, steamID64, lobbyId)

        local td = Thunderdome()
        assert(td, "Error: No Thunderdome object found")

        local localMemberSteamID64 = td:GetLocalSteam64Id()
        if not localMemberSteamID64 then
            return
        end

        if localMemberSteamID64 == steamID64 then

            local memberModel = Thunderdome():GetMemberLocalData(lobbyId, steamID64)

            if not memberModel then
                SLog("[TD-UI] ERROR: GMTDPlayerRoleDisplayWidget - Could not get member model for local client on 'OnGUILobbyMemberMetaDataChange' event!")
                return
            end

            local memberName = memberModel.name
            if not memberName then
                SLog("[TD-UI] ERROR: GMTDPlayerRoleDisplayWidget - Could not get member name for local client on 'OnGUILobbyMemberMetaDataChange' event!")
                return
            end

            self.playerName:SetText(string.UTF8Upper(memberName))
        end
    end

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyJoined, self.TDOnLobbyJoined)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange, self.TDOnPlayerDataChanged)

    self:OnIsCommanderChanged(self:GetIsCommander())

end

function GMTDPlayerRoleDisplayWidget:OnIsCommanderChanged(newIsCommander)

    if newIsCommander then
        self.pickLifeformsHelpText:SetVisible(false)
        self.lifeformsLayout:SetVisible(false)
        self.commanderIcon:SetVisible(true)
        self.commanderLabel:SetVisible(true)
    else
        self.pickLifeformsHelpText:SetVisible(true)
        self.lifeformsLayout:SetVisible(true)
        self.commanderIcon:SetVisible(false)
        self.commanderLabel:SetVisible(false)
    end

end

function GMTDPlayerRoleDisplayWidget:Uninitialize()
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyJoined, self.TDOnLobbyJoined)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange, self.TDOnPlayerDataChanged)
end