-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDTeamMemberRoleDisplayWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/IterableDict.lua")
Script.Load("lua/menu2/GUIMenuText.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDPlayerPlaqueWidget.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDLifeformProfile.lua")

local DEBUG_NEVER_SHOW_COMMANDER = false

class "GMTDTeamMemberRoleDisplayWidget" (GUIObject)

GMTDTeamMemberRoleDisplayWidget:AddCompositeClassProperty("SteamID64", "plaque")
GMTDTeamMemberRoleDisplayWidget:AddCompositeClassProperty("NameOverride", "plaque")
GMTDTeamMemberRoleDisplayWidget:AddClassProperty("Interactable", false)

GMTDTeamMemberRoleDisplayWidget.kCommanderIcon = PrecacheAsset("ui/thunderdome/commander_icon.dds")
GMTDTeamMemberRoleDisplayWidget.kCommanderIconSize = Vector(96, 96, 0)
GMTDTeamMemberRoleDisplayWidget.kLifeformIconSize = Vector(96, 96, 0)

GMTDTeamMemberRoleDisplayWidget.kLifeformSelectCooldown = 1 -- Cooldown time _per_ lifeform button. Not "whole"

function GMTDTeamMemberRoleDisplayWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.lifeformChoices = {}
    self.lifeformsCooldowns = {}
    self.lifeformsWaitStates = {}
    self.lifeformsSelectedStates = {}

    self.isLocalPlayer = false
    self.isCommander = false

    local padding = 8

    self.plaque = CreateGUIObject("plaque", GMTDPlayerPlaqueWidget, self, {}, errorDepth)
    self.plaque:AlignLeft()
    self.plaque:SetPosition(padding, 0)
    self.plaque:SetFriendsIconEnabled(false)
    self.plaque:SetCommanderIconEnabled(false)
    self:ForwardEvent(self.plaque, "OnShowRightClickMenu")

    self.pickLifeformText = CreateGUIObject("pickLifeformText", GUIText, self)
    self.pickLifeformText:SetText("Choose your lifeform(s): ")
    self.pickLifeformText:AlignTopRight()
    self.pickLifeformText:SetColor(ColorFrom255(98, 101, 112))
    self.pickLifeformText:SetFont("Agency", 35)
    self.pickLifeformText:SetVisible(false)

    self.lifeformObjectsHolder = CreateGUIObject("lifeformObjectsHolder", GUIListLayout, self, {orientation = "horizontal"}, errorDepth)
    self.lifeformObjectsHolder:SetPosition(-padding, -padding)
    self.lifeformObjectsHolder:AlignBottomRight()
    self.lifeformObjectsHolder:SetVisible(false)

    self.lifeformObjects = IterableDict()
    for i = 1, #kLobbyLifeformTypes do

        local lifeformObj = CreateGUIObject(string.format("lifeformObj_%s", kLobbyLifeformTypes[i]), GMTDLifeformProfile, self.lifeformObjectsHolder, params, errorDepth)
        lifeformObj:SetLifeform(kLobbyLifeformTypes[i])
        self.lifeformObjects[kLobbyLifeformTypes[i]] = lifeformObj

        self:HookEvent(lifeformObj, "OnLifeformSelected", self.OnLifeformSelected)

    end

    self.commanderLabel = CreateGUIObject("commanderLabel", GUIText, self)
    self.commanderLabel:SetText(Locale.ResolveString("THUNDERDOME_COMMANDER"))
    self.commanderLabel:AlignRight()
    self.commanderLabel:SetColor(ColorFrom255(206, 229, 234))
    self.commanderLabel:SetVisible(false)

    self.commanderIcon = CreateGUIObject("commanderIcon", GUIObject, self.commanderLabel)
    self.commanderIcon:SetTexture(self.kCommanderIcon)
    self.commanderIcon:AlignLeft()
    self.commanderIcon:SetPosition(-self.commanderIcon:GetSize().x, 0)
    self.commanderIcon:SetColor(1,1,1)
    self.commanderIcon:SetVisible(false)

    self:HookEvent(self, "OnSteamID64Changed", self.OnSteamID64Changed)
    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)
    self:HookEvent(self, "OnInteractableChanged", self.OnSteamID64Changed)

    self.TDLobbyMemberDataChanged = function(clientModeObj, steamID64, lobbyId)
        if steamID64 == self:GetSteamID64() then
            self:UpdateLifeformChoices( lobbyId )
        end
    end

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange, self.TDLobbyMemberDataChanged)

    self:OnSizeChanged(self:GetSize())
    self:UpdateLifeformBlinking()

end

function GMTDTeamMemberRoleDisplayWidget:GetPlaque()
    return self.plaque
end

function GMTDTeamMemberRoleDisplayWidget:UpdateLifeformBlinking()

    if not self.isLocalPlayer then -- Your teammate's lifeforms shouldn't blink.
        return
    end

    local shouldBlink = #self.lifeformsSelectedStates <= 0
    for _, lifeformProfile in pairs(self.lifeformObjects) do
        lifeformProfile:SetBlinking(shouldBlink)
    end

end

function GMTDTeamMemberRoleDisplayWidget:OnLifeformSelected(lifeformObj)

    local lifeformName = lifeformObj:GetLifeform()

    local lifeformWaitingForUpdate = self.lifeformsWaitStates[lifeformName] or false
    local lifeformLastSelectTime   = self.lifeformsCooldowns[lifeformName] or 0

    if self:GetInteractable() and not self.isCommander then

        if not lifeformWaitingForUpdate and Shared.GetSystemTime() - lifeformLastSelectTime >= self.kLifeformSelectCooldown then

            if not lifeformObj:GetSelected() then
                table.insertunique(self.lifeformChoices, lifeformName)
                table.insertunique(self.lifeformsSelectedStates, lifeformName)
                PlayMenuSound("AcceptChoice")
            else
                table.removevalue(self.lifeformChoices, lifeformName)
                table.removevalue(self.lifeformsSelectedStates, lifeformName)
                PlayMenuSound("CancelChoice")
            end

            Thunderdome():SetLocalLifeformsChoices(self.lifeformChoices)
            self.lifeformsWaitStates[lifeformName] = true
            self.lifeformsCooldowns[lifeformName] = Shared.GetSystemTime()

        else
            PlayMenuSound("InvalidSound")
        end

    end
end

function GMTDTeamMemberRoleDisplayWidget:OnSizeChanged(newSize)

    local newElementSize = newSize.y * 0.8

    self.commanderLabel:SetFont("Agency", newElementSize/2)
    self.commanderIcon:SetSize(newElementSize, newElementSize)
    self.commanderIcon:SetPosition(-self.commanderIcon:GetSize().x, 0)

    local newLifeformIconSize = math.min(self.kLifeformIconSize.y, newElementSize)
    for _, v in pairs(self.lifeformObjects) do
        v:SetSize(newLifeformIconSize, newLifeformIconSize)
    end

    self.plaque:SetSize(newSize.x - self.lifeformObjectsHolder:GetSize().x, newElementSize)

end

function GMTDTeamMemberRoleDisplayWidget:Reset()

    self.lifeformChoices = {}
    self.lifeformsCooldowns = {}
    self.lifeformsWaitStates = {}
    self.lifeformsSelectedStates = {}

    self:SetSteamID64("")
    self:GetInteractable(false)

    for _, obj in pairs(self.lifeformObjects) do
        obj:SetSelected(false)
        obj:SetBlinking(false)
    end

    self.commanderIcon:SetVisible(false)
    self.commanderLabel:SetVisible(false)

end

function GMTDTeamMemberRoleDisplayWidget:UpdateLifeformChoices( lobbyId )

    local steamID64 = self:GetSteamID64()
    if steamID64 == "" then
        return
    end

    local memberModel = Thunderdome():GetMemberLocalData( lobbyId, steamID64 )
    if memberModel then

        local lifeforms = memberModel.lifeforms

        for i = 1, #kLobbyLifeformTypes do

            local profile = self.lifeformObjects[kLobbyLifeformTypes[i]]
            if not profile then
                return
            end

            local lifeformName = profile:GetLifeform()
            local lifeformSelected = table.icontains(lifeforms, lifeformName)
            profile:SetSelected(lifeformSelected)

            if self.isLocalPlayer then
                self.lifeformsWaitStates[lifeformName] = false
            end

            self:UpdateLifeformBlinking()

        end
    end

end

function GMTDTeamMemberRoleDisplayWidget:OnSteamID64Changed()

    local steamID64 = self:GetSteamID64()

    if steamID64 == "" then
        self.lifeformChoices = {}
        self.lifeformsCooldowns = {}
        self.lifeformsWaitStates = {}
        self.lifeformsSelectedStates = {}
        self.isLocalPlayer = false
        self.isCommander = false
        self.plaque:SetVisible(false)
        self.lifeformObjectsHolder:SetVisible(false)
        self.commanderLabel:SetVisible(false)
        self.commanderIcon:SetVisible(false)
        self.pickLifeformText:SetVisible(false)
        return
    end

    -- Update commander status
    if Thunderdome():GetActiveLobbyId() then

        local team1Commander, team2Commander = Thunderdome():GetLobbyCommanderIds()

        self.isLocalPlayer = steamID64 == GetLocalSteamID64()

        self.isCommander = (steamID64 == team1Commander or steamID64 == team2Commander) and not DEBUG_NEVER_SHOW_COMMANDER

        if self.isCommander then
            self.plaque:SetVisible(true)
            self.lifeformObjectsHolder:SetVisible(false)
            self.commanderLabel:SetVisible(true)
            self.commanderIcon:SetVisible(true)
            self.pickLifeformText:SetVisible(false)
        else
            self.plaque:SetVisible(true)
            self.lifeformObjectsHolder:SetVisible(true)
            self.commanderLabel:SetVisible(false)
            self.commanderIcon:SetVisible(false)
            self.pickLifeformText:SetVisible(self.isLocalPlayer and self:GetInteractable()) -- Interactable check is for solo testing.
        end

    else
        SLog("[TD-UI] ERROR: GMTDTeamMemberRoleDisplayWidget - Could not get lobby model when trying to read commanders!")
    end

    self:UpdateLifeformChoices()

end

function GMTDTeamMemberRoleDisplayWidget:Uninitialize()
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyMemberMetaDataChange, self.TDLobbyMemberDataChanged)
end
