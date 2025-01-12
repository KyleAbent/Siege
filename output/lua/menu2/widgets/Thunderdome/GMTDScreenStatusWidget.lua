-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDScreenStatusWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIText.lua")

local kComponentType = enum(
{
    'Title',
    'Count', 
    'Timer',
    'TitleRandomization'
})

class "GMTDScreenStatusWidget" (GUIObject)

GMTDScreenStatusWidget.kBackgroundTexture        = PrecacheAsset("ui/thunderdome/statusbar.dds")
GMTDScreenStatusWidget.kDefaultStatusTextColor   = ColorFrom255(170, 185, 190)
GMTDScreenStatusWidget.kFlavorTextColor          = ColorFrom255(38,  156, 219)
GMTDScreenStatusWidget.kDefaultSize              = Vector(800, 70, 0)
GMTDScreenStatusWidget.kMaxEllipseDots           = 3
GMTDScreenStatusWidget.kEllipseInterval          = 1
GMTDScreenStatusWidget.kEllipseMin               = 1
GMTDScreenStatusWidget.kRandomizedTextPadding    = 40

function GMTDScreenStatusWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self:SetTexture(self.kBackgroundTexture)
    self:SetSize(self.kDefaultSize)
    self:SetColor(1,1,1)

    self.statusText          = nil
    self.statusTextColor     = nil
    self.currentCount        = nil
    self.currentCountMax     = nil
    self.timerDuration       = nil
    self.statusChangeTime    = 0

    -- Keeps track of whether we should use/show said parts.
    self.componentAvailability =
    {
        [kComponentType.Title] = true,
        [kComponentType.Count] = false,
        [kComponentType.Timer] = false,
        [kComponentType.TitleRandomization] = false,
    }

    self.statusText = CreateGUIObject("statusText", GUIText, self, params, errorDepth)
    self.statusText:AlignLeft()
    self.statusText:SetFont("AgencyBold", 50)
    self.statusText:SetColor(self.kDefaultStatusTextColor)

    self.flavorText = CreateGUIObject("flavorText", GUIText, self, params, errorDepth)
    self.flavorText:AlignLeft()
    self.flavorText:SetFont("AgencyBold", 50)
    self.flavorText:SetColor(self.kFlavorTextColor)
    self.flavorText:SetVisible(false)

end

-- We only update the text position once, so that we avoid text jitter since we're using one text object.
function GMTDScreenStatusWidget:UpdateTextPosition()

    if self.componentAvailability[kComponentType.TitleRandomization] then
        return
    end

    local textWidth = self.statusText:GetSize().x
    local backgroundWidth = self:GetSize().x

    local widthDiff = backgroundWidth - textWidth
    self.statusText:SetX(math.floor(widthDiff / 2))

end

--[[
    newTitleRandomizationSettings table format
        titles    : array of strings (un-localized), the pool of titles we will use when we start randomizing
        startDelay: number, how many seconds to wait (using the base title) until we should start randomizing titles.
        interval  : number, how many seconds between each title randomization
--]]
function GMTDScreenStatusWidget:StartNewStatus(newStatusText, newStatusTextColor, newCount, newCountMaximum, newTimerDuration, newTitleRandomizationSettings)

    self:SetUpdates(false)
    self.statusText:AlignLeft()
    self.statusText:SetPosition(0, 0)
    self.flavorText:SetVisible(false)
    self.flavorText:SetPosition(0, 0)

    if self.titleRandomizationCallback then
        self:RemoveTimedCallback(self.titleRandomizationCallback)
        self.titleRandomizationCallback = nil
    end

    if self.ellipseCallback then
        self:RemoveTimedCallback(self.ellipseCallback)
        self.ellipseCallback = nil
    end

    RequireType({"string"       }, newStatusText, "newStatusText")
    RequireType({"Color" , "nil"}, newStatusTextColor, "newStatusTextColor")
    RequireType({"number", "nil"}, newCount, "newCount")
    RequireType({"number", "nil"}, newCountMaximum, "newCountMaximum")
    RequireType({"number", "nil"}, newTimerDuration, "newTimerDuration")
    RequireType({"table" , "nil"}, newTitleRandomizationSettings, "newTitleRandomizationSettings")

    self.statusTextTitle            = newStatusText -- Expects the string to already be localized.
    self.statusTextTitleColor       = newStatusTextColor or self.kDefaultStatusTextColor
    self.currentCount               = newCount
    self.currentCountMax            = newCountMaximum
    self.timerDuration              = newTimerDuration
    self.titleRandomizationSettings = newTitleRandomizationSettings
    self.numDotsForEllipse          = self.kEllipseMin
    self.currentFlavorText          = nil

    self.statusChangeTime = Shared.GetSystemTimeReal()

    if self.titleRandomizationSettings then

        assert(type(self.titleRandomizationSettings.titles) == "table")
        for i = 1, #self.titleRandomizationSettings.titles do
            assert(type(self.titleRandomizationSettings.titles[i]) == "string")
        end

        assert(type(self.titleRandomizationSettings.startDelay) == "number")
        assert(self.titleRandomizationSettings.startDelay >= 0)

        assert(type(self.titleRandomizationSettings.interval) == "number")
        assert(self.titleRandomizationSettings.interval >= 0)

    end

    -- Title always available.
    self.componentAvailability[kComponentType.Count] = (type(self.currentCount) == "number" and type(self.currentCountMax) == "number")
    self.componentAvailability[kComponentType.TitleRandomization] = self.titleRandomizationSettings ~= nil
    self.componentAvailability[kComponentType.Timer] = (type(self.timerDuration) == "number" and not self.componentAvailability[kComponentType.TitleRandomization])
    self:SetUpdates(self.componentAvailability[kComponentType.Timer])

    -- Setup title randomization
    if self.componentAvailability[kComponentType.TitleRandomization] then

        local actualStartDelay = math.max(0, self.titleRandomizationSettings.startDelay - self.titleRandomizationSettings.interval)
        self:AddTimedCallback(self.TitleRandomizeStartDelayCallback, actualStartDelay, false)
        self.titleRandomizationSettings.titles = table.shuffle(self.titleRandomizationSettings.titles)
        self.currentRandomizedTitleIndex = 1
        self.statusText:AlignRight()

        self.ellipseCallback = self:AddTimedCallback(self.EllipseUpdateCallback, self.kEllipseInterval, true)
        self.flavorText:SetVisible(true)
        self:TitleRandomizeCallback() -- Start Immediately

        self.flavorText:SetPosition(self.kRandomizedTextPadding, 0)
        self.statusText:SetPosition(-self.kRandomizedTextPadding, 0)
        self:EllipseUpdateCallback()

        self.flavorText:ClearPropertyAnimations("Opacity")
        self.flavorText:AnimateProperty("Opacity", nil, MenuAnimations.TDStatusBarActiveStage)

    end

    self:UpdateStatusText()
    self:UpdateTextPosition()

    self.statusText:ClearPropertyAnimations("Opacity")
    self.statusText:AnimateProperty("Opacity", nil, MenuAnimations.TDStatusBarActiveStage)

end

function GMTDScreenStatusWidget:EllipseUpdateCallback()

    if not self.currentFlavorText then
        return
    end

    local ellipseText = string.format("%s%s", self.currentFlavorText, string.rep(".", self.numDotsForEllipse))
    self.flavorText:SetText(ellipseText)

    self.numDotsForEllipse = self.numDotsForEllipse + 1
    if self.numDotsForEllipse > self.kMaxEllipseDots then
        self.numDotsForEllipse = self.kEllipseMin
    end
end

function GMTDScreenStatusWidget:TitleRandomizeStartDelayCallback()
    self.titleRandomizationCallback = self:AddTimedCallback(self.TitleRandomizeCallback, self.titleRandomizationSettings.interval, true)
end

function GMTDScreenStatusWidget:TitleRandomizeCallback()

    if self.currentRandomizedTitleIndex > #self.titleRandomizationSettings.titles then
        self.currentRandomizedTitleIndex = 1
        self.titleRandomizationSettings.titles = table.shuffle(self.titleRandomizationSettings.titles)
    end

    self.currentFlavorText = string.UTF8Upper(Locale.ResolveString(self.titleRandomizationSettings.titles[self.currentRandomizedTitleIndex]))
    self.flavorText:SetText(self.currentFlavorText)
    self.numDotsForEllipse = self.kEllipseMin

    self:EllipseUpdateCallback()

    self.currentRandomizedTitleIndex = self.currentRandomizedTitleIndex + 1

end

function GMTDScreenStatusWidget:UpdateCount(newCurrentCount)

    assert(type(newCurrentCount) == "number")
    assert(type(self.currentCountMax) == "number")
    
    self.currentCount = newCurrentCount
    self:UpdateStatusText()

end

function GMTDScreenStatusWidget:UpdateStatusTitle(newStatusText) -- For static updating

    assert(type(newStatusText) == "string")

    self.statusTextTitle = Locale.ResolveString(newStatusText)
    self:UpdateStatusText()
    self:UpdateTextPosition()

end

function GMTDScreenStatusWidget:UpdateStatusText() -- For static updating

    self.countText = self.componentAvailability[kComponentType.Count] and string.format("( %s/%s )", self.currentCount, self.currentCountMax) or ""
    self.timerText = self.componentAvailability[kComponentType.Timer] and string.format("%.01f", math.max(0, self.timerDuration - (Shared.GetSystemTimeReal() - self.statusChangeTime))) or ""

    self.statusText:SetText(string.format("%s %s %s", self.statusTextTitle, self.countText, self.timerText))
    self.statusText:SetColor(self.statusTextTitleColor)

end

function GMTDScreenStatusWidget:OnUpdate(deltaTime, now)

    if self.componentAvailability[kComponentType.Timer] then

        local timeLeft = self.timerDuration - (Shared.GetSystemTimeReal() - self.statusChangeTime)
        timeLeft = math.max(0, timeLeft)

        if timeLeft <= 0 then
            self:SetUpdates(false)
        end

        self.timerText = string.format("%.01f", math.max(0, timeLeft))
        self.statusText:SetText(string.format("%s %s %s", self.statusTextTitle, self.countText, self.timerText))

    end

end

function GMTDScreenStatusWidget:Reset()

    if self.titleRandomizationCallback then
        self:RemoveTimedCallback(self.titleRandomizationCallback)
        self.titleRandomizationCallback = nil
    end

    if self.ellipseCallback then
        self:RemoveTimedCallback(self.ellipseCallback)
        self.ellipseCallback = nil
    end

    self.statusText:ClearPropertyAnimations("Opacity")
    self.flavorText:ClearPropertyAnimations("Opacity")
    self:SetUpdates(false)
    self.componentAvailability[kComponentType.Count] = false
    self.componentAvailability[kComponentType.Timer] = false
end
