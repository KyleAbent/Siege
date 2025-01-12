-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GMTDRewardsScreen.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Screen that shows current progress of matched play
--
--  Events
--    RewardButtonHoverChanged      A reward button has changed it's hover state.
--                                      p1: Button Object
--                                      p2: New Hover State
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

local kRewardScreen
function GetTDRewardsScreen()
    return kRewardScreen
end

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/menu2/widgets/GMTDRewardsScrollPane.lua")
Script.Load("lua/menu2/MissionScreen/GMTDRewardsScreenOverlay.lua")
Script.Load("lua/menu2/MissionScreen/GMTDRewardsScreenData.lua")
Script.Load("lua/menu2/MissionScreen/GMTDRewardGroup.lua")
Script.Load("lua/menu2/MissionScreen/GMTDRewardProgressMarker.lua")
Script.Load("lua/menu2/MissionScreen/GMTDRewardsScreenTester.lua")

local DEBUG_ALWAYSSHOWREWARDSSCREEN = false

local kRequiredMissionEmptyVal = "empty"

local function CreateRewardGroupObject(self, objectNamePrefix, nameIdx, isHours, rewardGroupInfo, groupAlign, rewardGroupList)
    local newGroup = CreateGUIObject(string.format("%s%s", objectNamePrefix, "Group_", nameIdx), GMTDRewardGroup, self.rewardsNodesHolder, {
        infoTables = rewardGroupInfo,
        isHours = isHours,
        align = groupAlign
    })
    table.insert(rewardGroupList, newGroup)
    self:ForwardEvent(newGroup, "RewardButtonHoverChanged")
end

local function CreateRewardGroups(self, rewardsData, objectNamePrefix, isHours)

    local rewardGroupList = isHours and self.hoursLineRewardGroups or self.victoriesLineRewardGroups
    local groupAlign = isHours and "topLeft" or "bottomLeft"

    local lastProgressRequirement = -1
    local rewardGroupInfo = {}
    for i = 1, #rewardsData do

        -- Keep going until the progress requirement changes, then that will be a group. (Its already sorted LtG)
        -- Keep in mind this means we're assuming that the max group number is never exceeded
        local rewardTable = rewardsData[i].data
        if lastProgressRequirement ~= rewardTable.progressRequired then

            if #rewardGroupInfo > 0 then
                CreateRewardGroupObject(self, objectNamePrefix, i, isHours, rewardGroupInfo, groupAlign, rewardGroupList)
            end

            rewardGroupInfo = {}
            lastProgressRequirement = rewardTable.progressRequired

        end

        table.insert(rewardGroupInfo, rewardsData[i])

    end

    -- Last one
    if #rewardGroupInfo > 0 then
        CreateRewardGroupObject(self, objectNamePrefix, #rewardGroupList + 1, isHours, rewardGroupInfo, groupAlign, rewardGroupList)
    end

end

local baseClass = GUIObject

---@class GMTDRewardsScreen : GUIObject
class "GMTDRewardsScreen" (baseClass)

GMTDRewardsScreen:AddClassProperty("RequiredMission", kRequiredMissionEmptyVal)
GMTDRewardsScreen:AddClassProperty("IsLocked", false)

GMTDRewardsScreen:AddClassProperty("CurrentFieldHours", 0)
GMTDRewardsScreen:AddClassProperty("CurrentFieldVictories", 0)
GMTDRewardsScreen:AddClassProperty("CurrentCommanderHours", 0)
GMTDRewardsScreen:AddClassProperty("CurrentCommanderVictories", 0)

GMTDRewardsScreen.kBackgroundTexture = PrecacheAsset("ui/thunderdome_rewards/background.dds")
GMTDRewardsScreen.kBorderSize = 11

GMTDRewardsScreen.kScrollBarSize = 56

GMTDRewardsScreen.kHoursLineTexture = PrecacheAsset("ui/thunderdome_rewards/line_hours.dds")
GMTDRewardsScreen.kVictoriesLineTexture = PrecacheAsset("ui/thunderdome_rewards/line_victories.dds")

function GMTDRewardsScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    kRewardScreen = self

    self.hoursLineRewardGroups = {}
    self.victoriesLineRewardGroups = {}
    self.initialized = false

    self:SetTexture(self.kBackgroundTexture)
    self:SetSizeFromTexture()
    self:SetColor(1,1,1)

    self.contents = CreateGUIObject("contents", GUIObject, self)
    self.contents:AlignCenter()
    self.contents:SetSize(self:GetSize() - Vector(self.kBorderSize*2 - 2, self.kBorderSize*2, 0))

    self:InitializeHoursLine()
    self:InitializeVictoriesLine()

    self.scrollPane = CreateGUIObject("scrollPane", GMTDRewardsScrollPane, self.contents,
    {
        verticalScrollBarEnabled = false,
        horizontalScrollBarEnabled = true,
        scrollSpeedMult = 3
    }, errorDepth)
    self.scrollPane:SetSize(self.contents:GetSize() - Vector(75, 0, 0))
    self.scrollPane:AlignRight()

    self.rewardsNodesHolder = CreateGUIObject("rewardsNodesHolder", GUIObject, self.scrollPane)
    self.scrollPane:HookEvent(self.rewardsNodesHolder, "OnSizeChanged", self.scrollPane.SetPaneSize)
    self.rewardsNodesHolder:SetSize(self.contents:GetSize().x * 2, self.contents:GetSize().y - self.kScrollBarSize)
    self:InitializeRewardsElements()
    self:UpdateRewardGroupsPositioning()

    self.lockedOverlay = CreateGUIObject("lockedOverlay", GMTDRewardsScreenOverlay, self.contents)

    self:HookEvent(self, "OnRequiredMissionChanged", self.OnRequiredMissionChanged)
    self:HookEvent(self, "OnIsLockedChanged", self.OnIsLockedChanged)
    self:HookEvent(GetGlobalEventDispatcher(), "OnUserStatsAndItemsRefreshed", self.FullUpdate)

    self.initialized = true

    self:FullUpdate()

end

function GMTDRewardsScreen:FullUpdate()

    local timePlayed = Client.GetUserStat_Int(kThunderdomeStatFields_TimePlayed) or 0
    local timePlayedComm = Client.GetUserStat_Int(kThunderdomeStatFields_TimePlayedCommander) or 0
    local victories = Client.GetUserStat_Int(kThunderdomeStatFields_Victories) or 0
    local victoriesComm = Client.GetUserStat_Int(kThunderdomeStatFields_CommanderVictories) or 0

    self:SetCurrentFieldHours(timePlayed)
    self:SetCurrentCommanderHours(timePlayedComm)
    self:SetCurrentFieldVictories(victories)
    self:SetCurrentCommanderVictories(victoriesComm)

    self:UpdateMarkerPositions()
    self:UpdateRewardsCompletion()

end

local function UpdateMarkerPosition(self, marker, markerRewardsList, markerProgress, markerY)

    -- Keep track of closest groups
    -- Either of these could be nil, but not both (which would imply no rewards)
    local minGroup = nil
    local maxGroup = nil
    local maxGroupIsLast = nil

    -- Loop through our marker rewards list and find which groups our marker should be between.
    for i = 1, #markerRewardsList do

        maxGroup  = markerRewardsList[i]
        minGroup  = markerRewardsList[i - 1]
        maxGroupIsLast = not markerRewardsList[i + 1]

        -- Domain: [last reward-group, next reward-group]
        if ((not minGroup or minGroup:GetProgressRequirement() <= markerProgress) and maxGroup:GetProgressRequirement() >= markerProgress) then
            break
        end

    end

    local defaultMarkerStartX = 75 -- Give dots some extra space from the left so they don't get clipped at 0.
    local startX = minGroup and minGroup:GetMidpoint() or defaultMarkerStartX
    local endX = maxGroup:GetMidpoint()

    -- Treat this range as it's own progress range, and interpolate
    local startProgress = minGroup and minGroup:GetProgressRequirement() or 0
    local endProgress   = maxGroup:GetProgressRequirement()

    -- Clamp progress down to very end if we're past the max
    markerProgress = ConditionalValue(maxGroupIsLast and markerProgress > endProgress, endProgress, markerProgress)

    local localProgress = (markerProgress - startProgress) / (endProgress - startProgress)
    local markerX = LerpNumber(startX, endX, localProgress)

    marker:SetPosition(math.max(markerX, defaultMarkerStartX), markerY)

end

local kLastFHoursOptionKey = "menu/rewards/last_hours"
local kLastFVicsOptionKey  = "menu/rewards/last_victories"
local kLastCHoursOptionKey = "menu/rewards/last_com_hours"
local kLastCVicsOptionKey  = "menu/rewards/last_com_victories"

local function GetShouldButtonCauseBounce(self, button)

    if not self.initialized then return false end

    local optionName
    local currentProgress
    if button:GetIsHours() then
        optionName = button:GetIsCommander() and kLastCHoursOptionKey or kLastFHoursOptionKey
        currentProgress = button:GetIsCommander() and self:GetCurrentCommanderHours() or self:GetCurrentFieldHours()
    else
        optionName = button:GetIsCommander() and kLastCVicsOptionKey or kLastFVicsOptionKey
        currentProgress = button:GetIsCommander() and self:GetCurrentCommanderVictories() or self:GetCurrentFieldVictories()
    end

    local hasReward = GetIsThunderdomeRewardUnlocked(button:GetRewardId())
    if hasReward then
        local lastProgress = tonumber(Client.GetOptionInteger(optionName, 0))
        if lastProgress < currentProgress and currentProgress >= button:GetProgressRequirement() then
            return true
        end

    end

    -- If they don't have it, don't show the bounce.
    return false

end

local kLastFieldHoursUnlockIdOptKey = "menu/rewards/last_field_hours_unlock_id"
local kLastCommHoursUnlockIdOptKey = "menu/rewards/last_comm_hours_unlock_id"
local kLastFieldWinsUnlockIdOptKey = "menu/rewards/last_field_wins_unlock_id"
local kLastCommWinsUnlockIdOptKey = "menu/rewards/last_comm_wins_unlock_id"

function GMTDRewardsScreen:UpdateRewardsCompletion()

    local needsBounce = false -- The ball bounce anim for the tab

    local lastFeildHoursUnlockId = Client.GetOptionInteger(kLastFieldHoursUnlockIdOptKey, 0)
    local lastCommHoursUnlockId = Client.GetOptionInteger(kLastCommHoursUnlockIdOptKey, 0)
    
    for i = 1, #self.hoursLineRewardGroups do

        local buttons = self.hoursLineRewardGroups[i]:GetButtons()
        for j = 1, #buttons do
            local button = buttons[j]
            
            local rewardId = button:GetRewardId()
            local hasUnlockedReward = GetIsThunderdomeRewardUnlocked(rewardId)
            local isRewardUnlockNotified = 
                hasUnlockedReward and ( rewardId ~= lastFeildHoursUnlockId and rewardId ~= lastCommHoursUnlockId)

            needsBounce = needsBounce or ( GetShouldButtonCauseBounce(self, button) and not isRewardUnlockNotified )
            button:SetCompleted(hasUnlockedReward)

            if not isRewardUnlockNotified then
                if button:GetIsHours() then
                    Client.SetOptionInteger( kLastFieldHoursUnlockIdOptKey, rewardId )
                elseif button:GetIsCommander() then
                    Client.SetOptionInteger( kLastCommHoursUnlockIdOptKey, rewardId )
                end
            end
        end

    end
    
    local lastFeildWinsUnlockId = Client.GetOptionInteger(kLastFieldWinsUnlockIdOptKey, 0)
    local lastCommWinsUnlockId = Client.GetOptionInteger(kLastCommWinsUnlockIdOptKey, 0)

    for i = 1, #self.victoriesLineRewardGroups do

        local buttons = self.victoriesLineRewardGroups[i]:GetButtons()
        for j = 1, #buttons do
            local button = buttons[j]
            
            local rewardId = button:GetRewardId()
            local hasUnlockedReward = GetIsThunderdomeRewardUnlocked(rewardId)
            local isRewardUnlockNotified = 
                hasUnlockedReward and ( rewardId ~= lastFeildWinsUnlockId and rewardId ~= lastCommWinsUnlockId )

            needsBounce = needsBounce or ( GetShouldButtonCauseBounce(self, button) and not isRewardUnlockNotified )
            button:SetCompleted(hasUnlockedReward)
            
            if not isRewardUnlockNotified then
                if button:GetIsHours() then
                    Client.SetOptionInteger( kLastFieldWinsUnlockIdOptKey, rewardId )
                elseif button:GetIsCommander() then
                    Client.SetOptionInteger( kLastCommWinsUnlockIdOptKey, rewardId )
                end
            end
        end

    end

    if needsBounce then
        GetMissionScreen():SetUnread()

        -- After deciding to bounce the tab, update the option keys.
        Client.SetOptionInteger(kLastFHoursOptionKey, self:GetCurrentFieldHours())
        Client.SetOptionInteger(kLastFVicsOptionKey , self:GetCurrentFieldVictories())
        Client.SetOptionInteger(kLastCHoursOptionKey, self:GetCurrentCommanderHours())
        Client.SetOptionInteger(kLastCVicsOptionKey , self:GetCurrentCommanderVictories())
    end

end

function GMTDRewardsScreen:UpdateMarkerPositions()

    -- Dots y positioning to get them onto the actual line
    local hoursLineYOffset = 633
    local victoriesLineYOffset = 775

    -- Stats are in seconds, we want hours
    --McG: yes...this is nasty. Sue me
    local timePlayed = tonumber(string.format("%.2f", (self:GetCurrentFieldHours() / 60 / 60)))
    local timePlayedComm = tonumber(string.format("%.2f", (self:GetCurrentCommanderHours() / 60 / 60)))

    UpdateMarkerPosition(self, self.fieldHoursDot,         self.hoursLineRewardGroups,     timePlayed,                          hoursLineYOffset)
    UpdateMarkerPosition(self, self.commanderHoursDot,     self.hoursLineRewardGroups,     timePlayedComm,                      hoursLineYOffset)

    UpdateMarkerPosition(self, self.fieldVictoriesDot,     self.victoriesLineRewardGroups, self:GetCurrentFieldVictories(),     victoriesLineYOffset)
    UpdateMarkerPosition(self, self.commanderVictoriesDot, self.victoriesLineRewardGroups, self:GetCurrentCommanderVictories(), victoriesLineYOffset)

    -- Make sure that the dots don't overlap each other.
    local markerSize = 105
    local markerOverlapOffsetY = markerSize / 3

    if math.abs(self.fieldHoursDot:GetPosition().x - self.commanderHoursDot:GetPosition().x) < markerSize then
        self.fieldHoursDot:SetY(hoursLineYOffset - markerOverlapOffsetY)
        self.commanderHoursDot:SetY(hoursLineYOffset + markerOverlapOffsetY)
    end

    if math.abs(self.fieldVictoriesDot:GetPosition().x - self.commanderVictoriesDot:GetPosition().x) < markerSize then
        self.fieldVictoriesDot:SetY(victoriesLineYOffset - markerOverlapOffsetY)
        self.commanderVictoriesDot:SetY(victoriesLineYOffset + markerOverlapOffsetY)
    end

    -- Automatically scroll to the lowest progress dot.
    local lowestDotX = math.min(self.fieldHoursDot:GetPosition().x, self.commanderHoursDot:GetPosition().x, self.fieldVictoriesDot:GetPosition().x, self.commanderVictoriesDot:GetPosition().x)
    local minSizeXLeftOfDot = math.floor(self.contents:GetSize().x / 4)
    local desiredScrollValue = lowestDotX - minSizeXLeftOfDot
    local horizontalScroller = self.scrollPane:GetHorizontalBar()
    horizontalScroller:SetValue(Clamp(desiredScrollValue, 0, horizontalScroller:GetTotalRange()))

    --Update marker numbers in tooltip to reflect new values
    self.fieldHoursDot:SetTooltip( timePlayed .. " " .. Locale.ResolveString("THUNDERDOME_REWARDS_MARKER_FIELDHOURS_TOOLTIP") )
    self.commanderHoursDot:SetTooltip( timePlayedComm .. " " .. Locale.ResolveString("THUNDERDOME_REWARDS_MARKER_COMMHOURS_TOOLTIP") )
    self.fieldVictoriesDot:SetTooltip( self:GetCurrentFieldVictories() .. " " .. Locale.ResolveString("THUNDERDOME_REWARDS_MARKER_FIELDVICTORIES_TOOLTIP") )
    self.commanderVictoriesDot:SetTooltip( self:GetCurrentCommanderVictories() .. " " .. Locale.ResolveString("THUNDERDOME_REWARDS_MARKER_COMMVICTORIES_TOOLTIP") )

end

function GMTDRewardsScreen:UpdateRewardGroupsPositioning()

    local nodeStartX = 250
    local nodeMinPadding = 50
    local nodeLineOffsetY = 50

    local minHoursSize = 0
    for i = 1, #self.hoursLineRewardGroups do
        minHoursSize = minHoursSize + self.hoursLineRewardGroups[i]:GetSize().x
    end

    local minVictoriesSize = 0
    for i = 1, #self.victoriesLineRewardGroups do
        minVictoriesSize = minVictoriesSize + self.victoriesLineRewardGroups[i]:GetSize().x
    end

    local minHoursSizeWithPadding = minHoursSize + ((#self.hoursLineRewardGroups - 1) * nodeMinPadding)
    local minVictoriesSizeWithPadding = minVictoriesSize + ((#self.victoriesLineRewardGroups - 1) * nodeMinPadding)
    local desiredWidth = math.max(minHoursSizeWithPadding, minVictoriesSizeWithPadding)
    local hoursPadding = (desiredWidth - minHoursSize) / (#self.hoursLineRewardGroups - 1)
    local victoriesPadding = (desiredWidth - minVictoriesSize) / (#self.victoriesLineRewardGroups - 1)

    local lastTimeNodeEndX = nodeStartX
    for i = 1, #self.hoursLineRewardGroups do
        local node = self.hoursLineRewardGroups[i]
        node:SetPosition(lastTimeNodeEndX + (hoursPadding * (i == 1 and 0 or 1)), nodeLineOffsetY)
        lastTimeNodeEndX = node:GetPosition().x + node:GetSize().x
    end

    local lastVictoryNodeEndX = nodeStartX
    for i = 1, #self.victoriesLineRewardGroups do
        local node = self.victoriesLineRewardGroups[i]
        node:SetPosition(lastVictoryNodeEndX + (victoriesPadding * (i == 1 and 0 or 1)), -nodeLineOffsetY)
        lastVictoryNodeEndX = node:GetPosition().x + node:GetSize().x
    end

    self.rewardsNodesHolder:SetWidth(math.max(lastTimeNodeEndX, lastVictoryNodeEndX))

end

function GMTDRewardsScreen:InitializeRewardsElements()

    local sortedTimeRewards, sortedVictoryRewards = GetSortedThunderdomeRewards()
    CreateRewardGroups(self, sortedTimeRewards,    "timeReward",    true)
    CreateRewardGroups(self, sortedVictoryRewards, "victoryReward", false)

    self.fieldHoursDot = CreateGUIObject("fieldHoursDot", GMTDRewardProgressMarker, self.rewardsNodesHolder, {
        rewardProgressionType = "hours",
        commander = false,
        tooltip = Locale.ResolveString("THUNDERDOME_REWARDS_MARKER_FIELDHOURS_TOOLTIP")
    })

    self.commanderHoursDot = CreateGUIObject("commanderHoursDot", GMTDRewardProgressMarker, self.rewardsNodesHolder, {
        rewardProgressionType = "hours",
        commander = true,
        tooltip = Locale.ResolveString("THUNDERDOME_REWARDS_MARKER_COMMHOURS_TOOLTIP")
    })

    self.fieldVictoriesDot = CreateGUIObject("fieldVictoriesDot", GMTDRewardProgressMarker, self.rewardsNodesHolder, {
        rewardProgressionType = "victories",
        commander = false,
        tooltip = Locale.ResolveString("THUNDERDOME_REWARDS_MARKER_FIELDVICTORIES_TOOLTIP")
    })

    self.commanderVictoriesDot = CreateGUIObject("commanderVictoriesDot", GMTDRewardProgressMarker, self.rewardsNodesHolder, {
        rewardProgressionType = "victories",
        commander = true,
        tooltip = Locale.ResolveString("THUNDERDOME_REWARDS_MARKER_COMMVICTORIES_TOOLTIP")
    })

end

function GMTDRewardsScreen:InitializeVictoriesLine()

    self.victoriesLine = CreateGUIObject("victoriesLine", GUIObject, self.contents)
    self.victoriesLine:SetTexture(self.kVictoriesLineTexture)
    self.victoriesLine:SetSizeFromTexture()
    self.victoriesLine:SetColor(1,1,1)
    self.victoriesLine:AlignBottomLeft()
    self.victoriesLine:SetY(-self.kScrollBarSize)

    self.victoriesLabel = CreateGUIObject("victoriesLabel", GUIText, self.victoriesLine)
    self.victoriesLabel:AlignLeft()
    self.victoriesLabel:SetRotationOffset(0.5, 0.5)
    self.victoriesLabel:SetAngle(math.pi / 2)
    self.victoriesLabel:SetText(Locale.ResolveString("THUNDERDOME_REWARDS_VICTORIESLINE_LABEL"))
    self.victoriesLabel:SetFont(MenuStyle.kRewardsLineFlagLabelFont)
    self.victoriesLabel:SetY(80)

    --local flagStartY = 117
    local flagStartY = 75
    local flagWidth = 73
    local flagHeight = 553

    -- Center text manually, since i've combined the line and flag parts into one texture. (Plus theres that angled shape that shouldn't be included anyway)
    local textPosX = ( flagWidth  - self.victoriesLabel:GetSize().x ) / 2
    local textPosY = ( flagHeight - self.victoriesLabel:GetSize().y ) / 2

    self.victoriesLabel:SetPosition(textPosX, -flagStartY + textPosY)

end

function GMTDRewardsScreen:InitializeHoursLine()

    self.hoursLine = CreateGUIObject("hoursLine", GUIObject, self.contents)
    self.hoursLine:SetTexture(self.kHoursLineTexture)
    self.hoursLine:SetSizeFromTexture()
    self.hoursLine:SetColor(1,1,1)

    self.hoursLabel = CreateGUIObject("hoursLabel", GUIText, self.hoursLine)
    self.hoursLabel:AlignLeft()
    self.hoursLabel:SetRotationOffset(0.5, 0.5)
    self.hoursLabel:SetAngle(math.pi / 2)
    self.hoursLabel:SetText(Locale.ResolveString("THUNDERDOME_REWARDS_HOURSLINE_LABEL"))
    self.hoursLabel:SetFont(MenuStyle.kRewardsLineFlagLabelFont)
    self.hoursLabel:SetY(-80)

    local flagStartY = 170
    local flagWidth = 74
    local flagHeight = 552

    -- Center text manually, since i've combined the line and flag parts into one texture. (Plus theres that angled shape that shouldn't be included anyway)
    local textPosX = ( flagWidth  - self.hoursLabel:GetSize().x ) / 2
    local textPosY = ( flagHeight - self.hoursLabel:GetSize().y ) / 2

    self.hoursLabel:SetPosition(textPosX, -flagStartY + textPosY)

end

function GMTDRewardsScreen:OnIsLockedChanged()
    local isLocked = self:GetIsLocked()
    self.lockedOverlay:SetVisible(isLocked)
end

function GMTDRewardsScreen:OnRequiredMissionChanged(newMission, oldMission)

    if oldMission ~= kRequiredMissionEmptyVal then
        self:UnHookEvent(oldMission, "OnCompletedChanged", self.OnRequiredMissionCompletedChanged)
    end

    if newMission then
        self:HookEvent(newMission, "OnCompletedChanged", self.OnRequiredMissionCompletedChanged)
        self:OnRequiredMissionCompletedChanged()
    end

end

function GMTDRewardsScreen:OnRequiredMissionCompletedChanged()
    local shouldLockScreen = not self:GetRequiredMission():GetCompleted()
    self:SetIsLocked(shouldLockScreen and not DEBUG_ALWAYSSHOWREWARDSSCREEN)
end

Event.Hook("Console_tdrewards_tester", function()
    if not GetTDRewardsScreenTester() then
        CreateGUIObject("rewardsTester", GMTDRewardsScreenTester, GetMainMenu())
        Log("DEBUG: Created TD Rewards Testing Window")
    else
        Log("DEBUG: TD Rewards Testing Window already exists...")
    end
end)
