-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GUIMenuMissionScreen.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Screen that displays a list of "missions" for the player to complete, including the rookie
--    tasks.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/menu2/GUIMenuScreen.lua")

Script.Load("lua/menu2/MissionScreen/GUIMenuMission.lua")
Script.Load("lua/menu2/MissionScreen/GUIMenuMissionScreenPullout.lua")

Script.Load("lua/menu2/widgets/GUIMenuScrollPane.lua")
Script.Load("lua/menu2/MissionScreen/GMTDRewardsScreen.lua")
Script.Load("lua/menu2/MissionScreen/GMTDRewardsScreenPlay.lua")
Script.Load("lua/menu2/MissionScreen/GMTDRewardsDetailsScreen.lua")

---@class GUIMenuMissionScreen : GUIMenuScreen
local baseClass = GUIMenuScreen
class "GUIMenuMissionScreen" (baseClass)

local kPulloutWidth = 116
local kPulloutGap = 10

local kScreenEdgeXSpacing = kPulloutWidth * 2 + kPulloutGap*2 -- so it doesn't overlap the other menu's pullout.
local kTopEdgeY = 456
local kBottomEdgeYSpacing = 100
local kContentsSpacing = 24

local kMinWidth = 900

-- Until the user has viewed this screen at least this many times, make it do a little bounce
-- animation so they notice it.
local kScreenViewReminderThreshold = 1
local kBounceAnimationName = "heyLookAtMeAnimation"
local kViewCountOptionName = "missionScreenOpenCount"

-- Awesome bouncing ball formula(s).
-- https://twitter.com/desmos/status/522182031368024064
local HeyLookAtMeAnimation = ReadOnly
{
    gravity = 1600.0,
    startingForce = -400,
    restitution = 0.5,
    cycleTime = 3.0,
    
    func = function(obj, time, params, currentValue, startValue, endValue, startTime)
        
        local r = params.restitution
        
        -- Time to use for animation (cycles).
        local currentTime = time % params.cycleTime
        
        -- Time of first bounce.
        local t1 = (-2.0 * params.startingForce) / params.gravity
        
        local tEnd = t1 / (1-r)
        if currentTime >= tEnd then
            return currentValue, false
        end
        
        -- Total number of bounces so far.
        local bounceCount = math.floor( math.log(1 - ((currentTime*(1-r)) / t1), r) )
        
        local energyLossFactor = math.pow(r, bounceCount)
        
        -- Time since the last bounce
        local timeSinceLastBounce = currentTime - (t1 * (1 - energyLossFactor)) / (1 - r)
        
        local height = params.startingForce * energyLossFactor * timeSinceLastBounce +
        0.5 * params.gravity * timeSinceLastBounce * timeSinceLastBounce
        
        -- Bounce along the x axis.  This is specifically made for the player screen.
        return currentValue + Vector(height, 0, 0), false
    
    end
}

local function UpdateHeyLookAtMeAnimation(self)
    
    local shouldBePlaying = not self:GetScreenDisplayed() and
    Client.GetOptionInteger(kViewCountOptionName, 0) < kScreenViewReminderThreshold
    
    local isPlaying = self:GetIsAnimationPlaying("Position", kBounceAnimationName)
    if shouldBePlaying and not isPlaying then
        self:AnimateProperty("Position", nil, HeyLookAtMeAnimation, kBounceAnimationName)
    elseif not shouldBePlaying and isPlaying then
        self:ClearPropertyAnimations("Position", kBounceAnimationName)
    end

end
GUIMenuMissionScreen._UpdateHeyLookAtMeAnimation = UpdateHeyLookAtMeAnimation
GUIMenuMissionScreen.kBorderWidth = 11

-- Mission configs can be setup before the screen is initialized.
local pendingConfigs = {}

-- Maximum width the pullout can be, determined by the screen size.
GUIMenuMissionScreen:AddClassProperty("_MaxWidth", 100)

local missionScreen
function GetMissionScreen()
    return missionScreen
end

local function OnPulloutPressed(self)
    
    if self:GetScreenDisplayed() then
        
        PlayMenuSound("CancelChoice")
        
        -- Clear the history by going back to the nav bar.
        GetScreenManager():DisplayScreen("NavBar")
        GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)
    
        -- Start the "look at me" animation, if necessary.
        UpdateHeyLookAtMeAnimation(self)
        
    else
        
        PlayMenuSound("ButtonClick")
        GetScreenManager():DisplayScreen("MissionScreen")

        -- Make a note that the player actually clicked the button to view this screen.
        local viewCount = Client.GetOptionInteger(kViewCountOptionName, 0)
        if viewCount < kScreenViewReminderThreshold then
            viewCount = viewCount + 1
            Client.SetOptionInteger(kViewCountOptionName, viewCount)
        end
    
        -- Stop the "look at me" animation, if it's playing.
        UpdateHeyLookAtMeAnimation(self)
        
    end

end

local function UpdateResolutionScaling(self, newX, newY)
    
    local mockupRes = Vector(3840, 2160, 0)
    local res = Vector(newX, newY, 0)
    local scale = res / mockupRes
    scale = math.min(scale.x, scale.y)
    
    self:SetScale(scale, scale)
    
    -- Compute width of player screen.
    local screenWidth = res.x / scale -- in "mockup" pixels...
    local width = screenWidth - kScreenEdgeXSpacing
    self:Set_MaxWidth(width)
    
    -- Compute height of player screen.
    local screenHeight = res.y / scale -- in "mockup" pixels...
    local screenBottomEdgeY = screenHeight - kBottomEdgeYSpacing
    self:SetHeight(screenBottomEdgeY - kTopEdgeY)
    
    -- Compute Y position of player screen (top edge Y coordinate in screen space, not mockup space).
    self:SetY(kTopEdgeY * scale)

end

local function UpdateContentsSize(self)
    local size = self:GetSize()
    self.contents:SetSize(size.x - kContentsSpacing*2, size.y - kContentsSpacing*2)
end

local function UpdateWidth(self)
    local maxWidth = self:Get_MaxWidth()
    local desiredWidth = self.listLayout:GetSize().x + self.rewardsScreen:GetSize().x - self.kBorderWidth + kContentsSpacing*2
    self:SetWidth(math.max(math.min(maxWidth, desiredWidth), kMinWidth))
end

local function AddMission(self, config)
    
    local newMission = CreateGUIObjectFromConfig(config, self.listLayout)
    
    newMission:HookEvent(self.listLayout, "OnSizeChanged", newMission.SetHeight)
    newMission:SetHeight(self.listLayout:GetSize().y)

    if not self.newPlayerMission and config.name == "mission_newPlayer" then
        self.newPlayerMission = newMission
    end
    
    return newMission

end

local function AddPendingMissions(self)
    for i=1, #pendingConfigs do
        AddMission(self, pendingConfigs[i])
    end
    pendingConfigs = nil
end

function GUIMenuMissionScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    missionScreen = self
    
    PushParamChange(params, "screenName", "MissionScreen")
    baseClass.Initialize(self, params, errorDepth)
    PopParamChange(params, "screenName")
    
    self:HookEvent(GetGlobalEventDispatcher(), "OnResolutionChanged", UpdateResolutionScaling)
    UpdateResolutionScaling(self, Client.GetScreenWidth(), Client.GetScreenHeight())

    self.newPlayerMission = nil
    
    self.back = CreateGUIObject("back", GUIMenuCoolGlowBox, self)
    self.back:SetLayer(-1)
    self.back:HookEvent(self, "OnSizeChanged", self.back.SetSize)
    self.back:SetSize(self:GetSize())

    self.title = CreateGUIObject("title", GUIText, self)
    self.title:AlignTopLeft()
    self.title:SetText(Locale.ResolveString("THUNDERDOME_MISSION_TITLE"))
    self.title:SetColor(ColorFrom255(196, 220, 224))

    self.pullout = CreateGUIObject("pullout", GUIMenuMissionScreenPullout, self,
    {
        hotSpot = Vector(1, 0, 0),
        position = Vector(-kPulloutGap, 0, 0),
        size = Vector(kPulloutWidth, 32, 0),
    })
    self.pullout:HookEvent(self, "OnSizeChanged", self.pullout.SetHeight)
    self.pullout:SetHeight(self:GetSize().y)
    self:HookEvent(self.pullout, "OnPressed", OnPulloutPressed)
    
    self.contents = CreateGUIObject("contents", GUIObject, self)
    self.contents:AlignBottom()
    self:HookEvent(self, "OnSizeChanged", UpdateContentsSize)
    UpdateContentsSize(self)

    self.playScreen = CreateGUIObject("playScreen", GMTDRewardsScreenPlay, self.contents)
    self.playScreen:AlignLeft()

    self.rewardDetailsScreen = CreateGUIObject("rewardDetailsScreen", GMTDRewardsDetailsScreen, self.contents)
    self.rewardDetailsScreen:AlignLeft()
    
    self.scrollPane = CreateGUIObject("scrollPane", GUIMenuScrollPane, self.contents,
    {
        verticalScrollBarEnabled = false,
    })
    self.scrollPane:AlignLeft()
    self.scrollPane:SetSize(GUIMenuMission.kBackgroundWidth, GUIMenuMission.kBackgroundHeight)

    self.listLayout = CreateGUIObject("layout", GUIListLayout, self.scrollPane,
    {
        orientation = "horizontal",
        fixedMinorSize = true,
    })
    
    -- Scroll pane's pane-width is sync'd to width of list layout.
    self.scrollPane:HookEvent(self.listLayout, "OnSizeChanged", self.scrollPane.SetPaneWidth)
    self.scrollPane:SetPaneWidth(self.listLayout:GetSize().x)
    
    -- List layout's height is sync'd to the height of the scroll pane's contents area.
    self.listLayout:HookEvent(self.scrollPane, "OnContentsSizeChanged", self.listLayout.SetHeight)
    self.listLayout:SetHeight(self.scrollPane:GetContentsSize().y)

    self.rewardsScreen = CreateGUIObject("rewardsScreen", GMTDRewardsScreen, self.contents)
    self.rewardsScreen:AlignLeft()
    self:HookEvent(self.rewardsScreen, "OnIsLockedChanged", self.OnRewardsScreenLockedChanged)
    self:OnRewardsScreenLockedChanged()

    self.scrollPane:SetX(self.rewardsScreen:GetSize().x - self.kBorderWidth)
    self.playScreen:SetX(self.rewardsScreen:GetSize().x - self.kBorderWidth)
    self.rewardDetailsScreen:SetX(self.rewardsScreen:GetSize().x - self.kBorderWidth)

    self:HookEvent(self, "OnSizeChanged", UpdateWidth)
    self:HookEvent(self, "On_MaxWidthChanged", UpdateWidth)
    self:HookEvent(self.listLayout, "OnSizeChanged", UpdateWidth)
    UpdateWidth(self)

    local spaceForTitle = self:GetSize().y - self.contents:GetSize().y
    self.title:SetY(spaceForTitle / 4)
    self.title:SetFont("MicrogrammaBold", 40)

    local contentWidth = self.contents:GetSize().x
    local rewardsWidth = self.rewardsScreen:GetSize().x
    local realContentX = self:GetSize().x - contentWidth
    self.title:SetX(realContentX + (rewardsWidth / 2) - (self.title:GetSize().x / 2))

    -- Initial state is closed.
    self:SetAnchor(1, 0) -- Anchored to right side of screen.
    self:SetX(kPulloutGap * self:GetScale().x)
    
    -- Add any missions that have been preconfigured.
    AddPendingMissions(self)
    
    -- If the player hasn't used the mission screen ever, or if there's been an update to one of the
    -- missions, make it do a little bounce animation when closed so they notice it.
    UpdateHeyLookAtMeAnimation(self)

    -- Do this after missions are added so we can hook up rewards screen with the new player mission.
    self.rewardsScreen:SetRequiredMission(self.newPlayerMission)
    self:HookEvent(self.rewardsScreen, "RewardButtonHoverChanged", self.OnRewardButtonHoverChanged)

end

function GUIMenuMissionScreen:OnRewardButtonHoverChanged(button, newHover)

    if not self.rewardsScreen:GetIsLocked() then

        if newHover then

            local isHours = button:GetIsHours()
            local detailsTable = button:GetDetailsTable()
            local isCommander = GetIsThunderdomeRewardCommander(button:GetRewardId())
            self.scrollPane:SetVisible(false)
            self.playScreen:SetVisible(false)

            local progressGetterName = string.format("GetCurrent%s%s", isCommander and "Commander" or "Field", isHours and "Hours" or "Victories")
            local getter = self.rewardsScreen[progressGetterName]
            local progress = getter(self.rewardsScreen)
            if isHours then
                progress = tonumber(string.format("%.2f", (progress / 60 / 60)))
            end

            self.rewardDetailsScreen:SetDetails(button:GetRewardId(), detailsTable, progress, isHours)
            self.rewardDetailsScreen:SetVisible(true)
        else
            self.scrollPane:SetVisible(false)
            self.playScreen:SetVisible(true)
            self.rewardDetailsScreen:SetVisible(false)
        end

    end
end

function GUIMenuMissionScreen:OnRewardsScreenLockedChanged()

    if self.rewardsScreen:GetIsLocked() then
        self.scrollPane:SetVisible(true)
        self.playScreen:SetVisible(false)
        self.rewardDetailsScreen:SetVisible(false)
    else
        self.scrollPane:SetVisible(false)
        self.playScreen:SetVisible(true)
        self.rewardDetailsScreen:SetVisible(false)
    end
end

-- Adds a mission to the mission screen.  Received in the form of an object config.  If the mission
-- screen is not yet initialized, the mission config is added to a list to be added automatically
-- later.
function GUIMenuMissionScreen.AddMissionConfig(config)

    RequireType("table", config, "config", 2)
    
    local missionScreen = GetMissionScreen()
    if missionScreen then
        AddMission(self, config)
        return
    end
    
    table.insert(pendingConfigs, config)

end

function GUIMenuMissionScreen:Display(immediate)
    
    if not GUIMenuScreen.Display(self, immediate) then
        return -- already being displayed!
    end
    
    self.pullout:PointRight()

    self.playScreen:OnVisibleChanged()
    
    if immediate then
        self:ClearPropertyAnimations("HotSpot")
        self:ClearPropertyAnimations("Position")
        self:SetHotSpot(1, self:GetHotSpot().y)
        self:SetPosition(0, self:GetPosition().y)
    else
        self:AnimateProperty("HotSpot", Vector(1, self:GetHotSpot().y, 0), MenuAnimations.FlyIn)
        self:AnimateProperty("Position", Vector(0, self:GetPosition().y, 0), MenuAnimations.FlyIn)
    end
    
end

function GUIMenuMissionScreen:Hide(immediate)
    
    if not GUIMenuScreen.Hide(self, immediate) then
        return -- already hidden!
    end
    
    self.pullout:PointLeft()
    
    if immediate then
        self:ClearPropertyAnimations("HotSpot")
        self:ClearPropertyAnimations("Position")
        self:SetHotSpot(0, self:GetHotSpot().y)
        self:SetPosition(kPulloutGap * self:GetScale().x, self:GetPosition().y)
    else
        self:AnimateProperty("HotSpot", Vector(0, self:GetHotSpot().y, 0), MenuAnimations.FlyIn)
        self:AnimateProperty("Position", Vector(kPulloutGap * self:GetScale().x, self:GetPosition().y, 0), MenuAnimations.FlyIn)
    end
    
end

function GUIMenuMissionScreen:OnBack()
    
    -- Clear the history by going back to the nav bar.
    GetScreenManager():DisplayScreen("NavBar")
    GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)

end

-- Make the mission screen ask for the user's attention (makes it bounce).  Call when something on
-- it has changed that you want the user to know about (eg completed mission step).
function GUIMenuMissionScreen:SetUnread()
    Client.SetOptionInteger(kViewCountOptionName, 0)
    self:_UpdateHeyLookAtMeAnimation()
end

-- Load a list of mission configs.  These will populate a table that will be read in when the
-- MissionScreen is initialized.
Script.Load("lua/menu2/MissionScreen/MissionUtils.lua")
Script.Load("lua/menu2/MissionScreen/MissionLoad.lua")

Event.Hook("Console_reset_mission_screen_view_count", function()
    Log("Reset the view count of the mission screen to zero.  It should start to crave attention now.")
    Client.SetOptionInteger(kViewCountOptionName, 0)
    GetMissionScreen():_UpdateHeyLookAtMeAnimation()
end)