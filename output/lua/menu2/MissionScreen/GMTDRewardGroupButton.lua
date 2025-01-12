-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GMTDRewardGroupButton.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Rewards button that is shown on a reward group.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/menu2/MissionScreen/GMTDRewardButtonCommanderTab.lua")

local baseClass = GUIButton

---@class GMTDRewardGroupButton : GUIButton
class "GMTDRewardGroupButton" (baseClass)

GMTDRewardGroupButton:AddClassProperty("IsSelected", false)
GMTDRewardGroupButton:AddClassProperty("DetailsTable", { empty = true }, true) -- table copy uses ipairs
GMTDRewardGroupButton:AddClassProperty("RewardId", kThunderdomeRewards.None)
GMTDRewardGroupButton:AddClassProperty("IsHours", true)
GMTDRewardGroupButton:AddClassProperty("IsCommander", false)
GMTDRewardGroupButton:AddClassProperty("Completed", false)
GMTDRewardGroupButton:AddClassProperty("ProgressRequirement", 0)

GMTDRewardGroupButton.kSelectionBoxTexture = PrecacheAsset("ui/thunderdome_rewards/rewardnode_selectbox.dds")
GMTDRewardGroupButton.kCompletedCheckmark  = PrecacheAsset("ui/thunderdome_rewards/rewardnode_checkmark.dds")
GMTDRewardGroupButton.kDefaultSize = Vector(294, 294, 0)

function GMTDRewardGroupButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:SetSize(self.kDefaultSize)
    self:SetColor(1,1,1)

    RequireType("boolean",          params.isHours,                         "params.isHours",                         errorDepth)
    RequireType("table",            params.infoTable,                       "params.infoTable",                       errorDepth)
    RequireType("number",           params.infoTable.id,                    "params.infoTable.id",                    errorDepth)
    RequireType("number",           params.infoTable.data.progressRequired, "params.infoTable.data.progressRequired", errorDepth)
    RequireType("string",           params.infoTable.data.locale,           "params.infoTable.data.locale",           errorDepth)
    RequireType({"string", "nil"},  params.infoTable.data.iconPath,         "params.infoTable.data.iconPath",         errorDepth)

    self:SetIsHours(params.isHours)
    self:SetDetailsTable(params.infoTable.data)
    self:SetRewardId(params.infoTable.id)
    self:SetProgressRequirement(params.infoTable.data.progressRequired)
    self:SetIsCommander( GetIsThunderdomeRewardCommander(self:GetRewardId()) )

    local callingCardId = GetThunderdomeRewardCallingCardId(self:GetRewardId())
    if callingCardId then -- So we can reuse the calling card texture
        local callingCardDetails = GetCallingCardTextureDetails(callingCardId)
        self:SetTexture(callingCardDetails.texture)
        self:SetTexturePixelCoordinates(callingCardDetails.texCoords)
    else
        self:SetTexture(GetThunderdomeRewardIconPath(params.infoTable.data.iconPath, true))
    end

    local unlocksCallingCardFeature = callingCardId == kCallingCardFeatureUnlockCard
    self.commanderTag = CreateGUIObject("commanderTag", GMTDRewardButtonCommanderTab, self, {
        isHours = params.isHours,
        isCallingCardFeatureUnlock = unlocksCallingCardFeature,
        align = "top",
    })
    self.commanderTag:SetY(-self.commanderTag:GetSize().y + 9)
    self.commanderTag:SetVisible(self:GetIsCommander() or unlocksCallingCardFeature)

    if not params.isHours then -- commander tag should be on the bottom if this is a "victories" reward

        local tagSize = self.commanderTag:GetSize()
        self.commanderTag:AlignBottom()

        if unlocksCallingCardFeature then
            self.commanderTag:SetY(tagSize.y - 7)
        else
            self.commanderTag:SetY(tagSize.y - 10)
        end

    end

    self.commanderTag:UpdateElementPositioning()

    self.completedCheckmark = CreateGUIObject("completedCheckmark", GUIObject, self)
    self.completedCheckmark:AlignCenter()
    self.completedCheckmark:SetVisible(false)
    self.completedCheckmark:SetColor(1,1,1)
    self.completedCheckmark:SetTexture(self.kCompletedCheckmark)
    self.completedCheckmark:SetSizeFromTexture()
    self.completedCheckmark:SetY(-20)
    self:HookEvent(self, "OnCompletedChanged", self.OnCompletedChanged)

    self.selectedBox = CreateGUIObject("selectionBox", GUIObject, self)
    self.selectedBox:SetTexture(self.kSelectionBoxTexture)
    self.selectedBox:AlignCenter()
    self.selectedBox:SetColor(1,1,1)
    self.selectedBox:SetSizeFromTexture()

    self:HookEvent(self, "OnMouseOverChanged", self.OnMouseOverChanged)
    self:OnMouseOverChanged(self:GetMouseOver())

end

function GMTDRewardGroupButton:OnMouseOverChanged(newHover)
    PlayMenuSound("ButtonHover")
    self.selectedBox:SetVisible(newHover)
    self:FireEvent("RewardButtonHoverChanged", self, newHover)
end

function GMTDRewardGroupButton:OnCompletedChanged(newCompleted)
    self.completedCheckmark:SetVisible(newCompleted)
end
