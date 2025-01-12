-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GMTDRewardProgressMarker.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Simple dot that shows the current thunderdome rewards progress (for either victories or hours played)
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/menu2/wrappers/Tooltip.lua")

local kHoursType = "hours"
local kVictoriesType = "victories"

local baseClass = GetTooltipWrappedClass(GUIButton)

class "GMTDRewardProgressMarker" (baseClass)

GMTDRewardProgressMarker:AddClassProperty("ProgressionType", "none")
GMTDRewardProgressMarker:AddClassProperty("IsCommander", false)

GMTDRewardProgressMarker.kHoursFieldTexture         = PrecacheAsset("ui/thunderdome_rewards/dot_hours_field.dds")
GMTDRewardProgressMarker.kHoursCommanderTexture     = PrecacheAsset("ui/thunderdome_rewards/dot_hours_commander.dds")

GMTDRewardProgressMarker.kVictoriesFieldTexture     = PrecacheAsset("ui/thunderdome_rewards/dot_victories_field.dds")
GMTDRewardProgressMarker.kVictoriesCommanderTexture = PrecacheAsset("ui/thunderdome_rewards/dot_victories_commander.dds")

function GMTDRewardProgressMarker:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    RequireType("string", params.rewardProgressionType, "params.rewardProgressionType", errorDepth)
    RequireType("boolean", params.commander, "params.commander", errorDepth)

    local isHours = params.rewardProgressionType == kHoursType
    local isVictories = params.rewardProgressionType == kVictoriesType
    assert(isHours or isVictories, "params.rewardProgressionType must be a valid type")

    local texture
    if isHours then
        texture = params.commander and self.kHoursCommanderTexture or self.kHoursFieldTexture
    else
        texture = params.commander and self.kVictoriesCommanderTexture or self.kVictoriesFieldTexture
    end

    self:SetTexture(texture)
    self:SetColor(1,1,1)
    self:SetSizeFromTexture()

    self:SetProgressionType(params.rewardProgressionType)
    self:SetIsCommander(params.commander)

    self:SetHotSpot(0.5, 0.5)

end
