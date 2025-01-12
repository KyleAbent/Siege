-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GMTDRewardsDetailsScreen.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Shows details about a selected reward.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIText.lua")
Script.Load("lua/GUI/GUIParagraph.lua")

local kBorderSize = 11
local kMaxImageSize = 800
local kDescriptionMaxHeight = 325

local baseClass = GUIObject

---@class GMTDRewardsDetailsScreen : GUIObject
class "GMTDRewardsDetailsScreen" (baseClass)

GMTDRewardsDetailsScreen:AddClassProperty("RewardId", kThunderdomeRewards.None)
GMTDRewardsDetailsScreen:AddClassProperty("DetailsTable", { empty = true }, true)
GMTDRewardsDetailsScreen:AddClassProperty("IsHours", true)
GMTDRewardsDetailsScreen:AddClassProperty("CurrentProgress", 0)

GMTDRewardsDetailsScreen.kBackgroundTexture = PrecacheAsset("ui/thunderdome_rewards/missions_background.dds")
GMTDRewardsDetailsScreen.kDescriptionTextColor = HexToColor("c4dce0")
GMTDRewardsDetailsScreen.kTitleTextColor = HexToColor("63bed6")
GMTDRewardsDetailsScreen.kProgressLabelColor = HexToColor("6a6a6b")
GMTDRewardsDetailsScreen.kProgressColor = HexToColor("63bed6")

function GMTDRewardsDetailsScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:SetTexture(self.kBackgroundTexture)
    self:SetColor(1,1,1)
    self:SetSizeFromTexture()

    self.contents = CreateGUIObject("contents", GUIObject, self)
    self.contents:AlignCenter()
    self.contents:SetSize(self:GetSize() - Vector(kBorderSize, kBorderSize, 0))

    self.image = CreateGUIObject("image", GUIObject, self.contents)
    self.image:AlignTop()
    self.image:SetColor(1,1,1)

    local imageSize = math.min(kMaxImageSize, self.contents:GetSize().x)
    self.image:SetSize(imageSize, imageSize)

    self.title = CreateGUIObject("title", GUIParagraph, self.contents, {
        justification = GUIItem.Align_Center,
        paragraphSize = Vector(self.contents:GetSize().x * 0.9, -1, 0),
    })
    self.title:SetFont(MenuStyle.kRewardsDetailsTitleFont)
    self.title:AlignTop()
    self.title:SetColor(self.kTitleTextColor)
    self.title:SetY(kMaxImageSize)

    self.description = CreateGUIObject("description", GUIParagraph, self.contents, {
        justification = GUIItem.Align_Center,
        paragraphSize = Vector(self.contents:GetSize().x * 0.9, kDescriptionMaxHeight, 0),
        font = MenuStyle.kRewardsDetailsDescriptionFont,
        color = self.kDescriptionTextColor
    })
    self.description:AlignTop()
    self.description:SetY(self.title:GetSize().y + self.title:GetPosition().y)

    self.progressLabel = CreateGUIObject("progressLabel", GUIText, self.contents)
    self.progressLabel:AlignTop()
    self.progressLabel:SetText(Locale.ResolveString("THUNDERDOME_REWARDS_DETAILS_PROGRESSLABEL"))
    self.progressLabel:SetColor(self.kProgressLabelColor)
    self.progressLabel:SetFont(MenuStyle.kRewardsDetailsProgressLabelFont)
    self.progressLabel:SetY(self.description:GetSize().y + self.description:GetPosition().y + kDescriptionMaxHeight)

    self.progressRequirementLabel = CreateGUIObject("progressRequirementLabel", GUIText, self.contents)
    self.progressRequirementLabel:AlignTop()
    self.progressRequirementLabel:SetColor(self.kProgressColor)
    self.progressRequirementLabel:SetFont(MenuStyle.kRewardsDetailsProgressFont)
    self.progressRequirementLabel:SetY(self.progressLabel:GetSize().y + self.progressLabel:GetPosition().y + 15)

end

function GMTDRewardsDetailsScreen:SetDetails(rewardId, detailsTable, currentProgress, isHours)

    self:SetRewardId(rewardId)
    self:SetDetailsTable(detailsTable)
    self:SetCurrentProgress(currentProgress)
    self:SetIsHours(isHours)

    local rewardId = self:GetRewardId()

    if detailsTable.empty or rewardId == kThunderdomeRewards.None then return end

    local callingCardId = GetThunderdomeRewardCallingCardId(rewardId)
    if callingCardId then -- So we can reuse the calling card texture
        local callingCardDetails = GetCallingCardTextureDetails(callingCardId)
        self.image:SetTexture(callingCardDetails.texture)
        self.image:SetTexturePixelCoordinates(callingCardDetails.texCoords)
        self.title:SetText(string.UTF8Upper(Locale.ResolveString(GetCallingCardUnlockedTooltipIdentifier(callingCardId))))
    else
        self.image:SetTexture(GetThunderdomeRewardIconPath(detailsTable.iconPath, false))
        self.image:SetTextureCoordinates(0, 0, 1, 1) --Normalized
        self.title:SetText(Locale.ResolveString(GetThunderdomeRewardLocale(detailsTable.locale, false)))
    end

    self.description:SetText(Locale.ResolveString(GetThunderdomeRewardLocale(detailsTable.locale, true)))
    self.description:SetY(self.title:GetPosition().y + self.title:GetSize().y)

    local descriptionMaxHeight = (self.progressRequirementLabel:GetPosition().y - self.description:GetPosition().y)
    self.description:SetParagraphSize(self.description:GetParagraphSize().x, descriptionMaxHeight)

    local progressReq = detailsTable.progressRequired
    local progressLeft = Clamp( progressReq - currentProgress, 0, progressReq)

    local isHours = self:GetIsHours()
    local isRewardCommander = GetIsThunderdomeRewardCommander(rewardId)

    if isHours then
        if isRewardCommander then
            self.progressRequirementLabel:SetText(string.format("%.1f %s %s", progressLeft,
                    Locale.ResolveString("THUNDERDOME_REWARDS_DETAILS_COMMANDER"),
                    Locale.ResolveString("THUNDERDOME_REWARDS_DETAILS_PROGRESSPOSTFIX_HOURS")))
        else
            self.progressRequirementLabel:SetText(string.format("%.1f %s", progressLeft,
                    Locale.ResolveString("THUNDERDOME_REWARDS_DETAILS_PROGRESSPOSTFIX_HOURS")))
        end

    else
        if isRewardCommander then
            self.progressRequirementLabel:SetText(string.format("%d %s %s", progressLeft,
                    Locale.ResolveString("THUNDERDOME_REWARDS_DETAILS_COMMANDER"),
                    Locale.ResolveString("THUNDERDOME_REWARDS_DETAILS_PROGRESSPOSTFIX_VICTORIES")))
        else
            self.progressRequirementLabel:SetText(string.format("%d %s", progressLeft,
                    Locale.ResolveString("THUNDERDOME_REWARDS_DETAILS_PROGRESSPOSTFIX_VICTORIES")))
        end
    end

    local rewardCompleted = GetIsThunderdomeRewardUnlocked(rewardId)
    local showProgressElements = not rewardCompleted

    self.progressLabel:SetVisible(showProgressElements)
    self.progressRequirementLabel:SetVisible(showProgressElements)


end
