-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GMTDRewardButtonCommanderTab.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Rewards button that is shown on a reward group.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIText.lua")

local kTextStartX = 120
local kTextStartY = 0
local kTextStartYFlipped = 2
local kTextPaddingOffsetY = 10

local kCommanderTagFontColor = Color(1,1,1)
local kBlankTagFontColor = HexToColor("FF9629")

local baseClass = GUIObject

class "GMTDRewardButtonCommanderTab" (baseClass)

GMTDRewardButtonCommanderTab:AddClassProperty("Flipped", false)

GMTDRewardButtonCommanderTab.kBlankTagBottomTexture = PrecacheAsset("ui/thunderdome_rewards/rewardnode_blanktag_bottom.dds")
GMTDRewardButtonCommanderTab.kBackground = PrecacheAsset("ui/thunderdome_rewards/rewardnode_commandertag.dds")
GMTDRewardButtonCommanderTab.kBackgroundFlipped = PrecacheAsset("ui/thunderdome_rewards/rewardnode_commandertag_flipped.dds")
GMTDRewardButtonCommanderTab.kLabelColor = HexToColor("c4dce0")

function GMTDRewardButtonCommanderTab:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    RequireType("boolean", params.isHours, "params.isHours", errorDepth )
    RequireType("boolean", params.isCallingCardFeatureUnlock, "params.isCallingCardFeatureUnlock", errorDepth )

    self.unlocksCallingCardFeature = params.isCallingCardFeatureUnlock
    self.isHours = params.isHours

    self:SetTexture(self.kBackground)
    self:SetColor(1,1,1)
    self:SetSizeFromTexture()

    self.label = CreateGUIObject("label", GUIText, self)
    self.label:SetColor(self.kLabelColor)

    self.label2 = CreateGUIObject("label2", GUIText, self)
    self.label2:SetColor(self.kLabelColor)

    self:SetFlipped(not self.isHours)

    self:HookEvent(self, "OnFlippedChanged", self.UpdateElementPositioning)
    self:UpdateElementPositioning()

end

function GMTDRewardButtonCommanderTab:UpdateElementPositioning()

    if self.unlocksCallingCardFeature then

        self:SetTexture(self.kBlankTagBottomTexture)
        self:SetSizeFromTexture()

        self.label:AlignCenter()
        self.label:SetText(Locale.ResolveString("THUNDERDOME_REWARDS_UNLOCKS_CALLING_CARDS"))
        self.label:SetPosition(0, 0)
        self.label:SetFont(MenuStyle.kRewardsNodeBlankTagFont)
        self.label:SetColor(kBlankTagFontColor)

        self.label2:SetVisible(false)

    else

        local isFlipped = self:GetFlipped()
        self:SetTexture(isFlipped and self.kBackgroundFlipped or self.kBackground)
        self:SetSizeFromTexture()

        local topTextStartY = isFlipped and kTextStartYFlipped or kTextStartY


        self.label:SetText(Locale.ResolveString("THUNDERDOME_REWARDS_NODE_COMMANDERTAG_TOPLABEL"))
        self.label2:SetText(Locale.ResolveString(self.isHours and "THUNDERDOME_REWARDS_NODE_COMMANDERTAG_BOTTOMLABEL_HOURS" or "THUNDERDOME_REWARDS_NODE_COMMANDERTAG_BOTTOMLABEL_VICTORIES"))

        self.label:AlignTopLeft()
        self.label:SetFont(MenuStyle.kRewardsNodeCommanderTagFont)
        self.label:SetPosition(kTextStartX, topTextStartY)
        self.label:SetColor(kCommanderTagFontColor)

        self.label2:SetFont(MenuStyle.kRewardsNodeCommanderTagFont)
        self.label2:SetColor(kCommanderTagFontColor)
        self.label2:SetPosition(kTextStartX, topTextStartY + self.label:GetSize().y - kTextPaddingOffsetY)
        self.label2:SetVisible(true)

    end

end
