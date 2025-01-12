-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GMTDRewardGroup.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    GUIObject that displays one or two thunderdome rewards with the same progression requirement
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/menu2/MissionScreen/GMTDRewardGroupButton.lua")

local kMaxNodes = 2
local kBackground_1x = PrecacheAsset("ui/thunderdome_rewards/rewardnode_1x.dds")
local kBackground_2x = PrecacheAsset("ui/thunderdome_rewards/rewardnode_2x.dds")

-- Locations of buttons that hold the reward images. Each index is how many rewards this object is representing.
local kButtonLocations =
{
    [1] = { Vector(25, 26, 0) },
    [2] = { Vector(25, 24, 0), Vector(333, 24, 0) },
}

local kGroupTextures =
{
    [1] = kBackground_1x,
    [2] = kBackground_2x,
}

local baseClass = GUIObject

---@class GMTDRewardGroup : GUIObject
class "GMTDRewardGroup" (baseClass)

GMTDRewardGroup:AddClassProperty("IsHoursReward", true)
GMTDRewardGroup:AddClassProperty("ProgressRequirement", 0)
GMTDRewardGroup:AddClassProperty("RewardInfoTable", {}, true)
GMTDRewardGroup:AddClassProperty("Completed", false)

function GMTDRewardGroup:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    RequireType("boolean", params.isHours,    "params.isHours",      errorDepth)
    RequireType("table",   params.infoTables, "params.infoTables",   errorDepth)

    self.numNodes = #params.infoTables
    assert(self.numNodes <= kMaxNodes)

    self.infoTables = params.infoTables
    self:SetProgressRequirement(params.infoTables[1].data.progressRequired)
    self:SetIsHoursReward(params.isHours)

    self:SetTexture(kGroupTextures[self.numNodes])
    self:SetColor(1, 1, 1)
    self:SetSizeFromTexture()

    self.buttons = {}
    for i = 1, #params.infoTables do
        local button = CreateGUIObject(string.format("button_%s", i), GMTDRewardGroupButton, self, {
            infoTable = params.infoTables[i],
            align = params.isHours and "topLeft" or "bottomLeft",
            isHours = params.isHours
        }, errorDepth)
        table.insert(self.buttons, button)
        self:ForwardEvent(button, "RewardButtonHoverChanged")
    end

    self.progressLabel = CreateGUIObject("progressLabel", GUIText, self, params, errorDepth)
    self.progressLabel:SetFont("Agency", 32)
    self.progressLabel:SetText(string.format("%d", params.infoTables[1].data.progressRequired))

    local shouldFlip = not params.isHours
    local buttonLocations = {}
    for i = 1, #kButtonLocations[self.numNodes] do
        table.insert(buttonLocations, Vector(kButtonLocations[self.numNodes][i]))
    end

    if shouldFlip then

        for i = 1, #buttonLocations do
            buttonLocations[i].y = buttonLocations[i].y * (-1)
            self.buttons[i]:SetPosition(buttonLocations[i])
        end

        self.progressLabel:AlignTop()
        self.progressLabel:SetY(-self.progressLabel:GetSize().y)

        local size = self:GetSize()
        self:SetTexturePixelCoordinates(0, size.y, size.x, 0)

    else

        for i = 1, #buttonLocations do
            self.buttons[i]:SetPosition(buttonLocations[i])
        end

        self.progressLabel:AlignBottom()
        self.progressLabel:SetY(self.progressLabel:GetSize().y)

    end

    self:HookEvent(self, "OnCompletedChanged", self.OnCompletedChanged)

end

function GMTDRewardGroup:GetButtons()
    return self.buttons
end

function GMTDRewardGroup:GetMidpoint()
    return self:GetPosition().x + (self:GetSize().x / 2)
end

function GMTDRewardGroup:OnCompletedChanged(newCompleted)
    for i = 1, #self.buttons do
        self.buttons[i]:SetCompleted(newCompleted)
    end
end
