-- ======= Copyright (c) 2003-2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/GUIBoneShieldDisplay.lua
--
-- Created by: Darrell Gentry (darrell@naturalselection2.com)
--
-- Displays a bar for the onos BoneShield ability.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIText.lua")

local kMockupHeight = 1620

local kFlashTransitionRate = 2 -- 2hz, in end-to-end color transitions per second
local kNumFlashLoops = 1 -- Number of times to transition from kHurtColor1 -> kHurtColor2 - > kHurtColor1
local kTextLowAmount = 350 -- Text changes color when <= this amount

local baseClass = GUIObject
class "GUIBoneShieldDisplay" (baseClass)

GUIBoneShieldDisplay.kBackgroundTexture = PrecacheAsset("ui/boneshield/background.dds")
GUIBoneShieldDisplay.kBackgroundBrokenTexture = PrecacheAsset("ui/boneshield/background_broken.dds")
GUIBoneShieldDisplay.kBarTexture = PrecacheAsset("ui/boneshield/bar.dds")

GUIBoneShieldDisplay.kOriginalTextureCoordinates = { 0, 0, 589, 33 }

GUIBoneShieldDisplay.kNormalColor = ColorFrom255(255, 216, 74)
GUIBoneShieldDisplay.kHurtColor1 = ColorFrom255(255, 43, 36)
GUIBoneShieldDisplay.kHurtColor2 = ColorFrom255(255, 255, 255)

GUIBoneShieldDisplay.kNormalTextColor = HexToColor("F4BE50")
GUIBoneShieldDisplay.kLowTextColor = HexToColor("F53E2A")

GUIBoneShieldDisplay:AddClassProperty("CurrentHP", 0)
GUIBoneShieldDisplay:AddClassProperty("MaxHP", kBoneShieldHitpoints)
GUIBoneShieldDisplay:AddClassProperty("Broken", false) -- TODO(Salads): Broken bar look when no hitpoints left

function GUIBoneShieldDisplay:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self.flashing = false
    self.flashIntroProgress = 0
    self.flashLoopProgress = 0
    self.flashTimesLooped = 0
    self.flashLoopReturning = false
    self.flashExitProgress = 0

    self:SetTexture(self.kBackgroundTexture)
    self:SetSizeFromTexture()
    self:SetColor(1,1,1)
    self:AlignBottom()

    self.scale = Client.GetScreenHeight() / kMockupHeight
    self:SetScale(self.scale, self.scale)
    self:SetY(-(Client.GetScreenHeight() * 0.2))

    self.bar = CreateGUIObject("bar", GUIObject, self)
    self.bar:AlignCenter()
    self.bar:SetTexture(self.kBarTexture)
    self.bar:SetSizeFromTexture()
    self.bar:SetColor(self.kNormalColor)

    self.hpText2 = CreateGUIObject("hpText", GUIText, self.bar)
    self.hpText2:AlignBottom()
    self.hpText2:SetFont("Stamp", 41)
    self.hpText2:SetColor(self.kNormalTextColor)
    self.hpText2:SetText(string.format(" / %d", self:GetMaxHP()))
    self.hpText2:SetPosition(self.hpText2:GetSize().x / 2, self.hpText2:GetSize().y)

    self.hpText = CreateGUIObject("hpText", GUIText, self.hpText2)
    self.hpText:AlignLeft()
    self.hpText:SetFont("Stamp", 41)
    self.hpText:SetX(-self.hpText:GetSize().x)
    self.hpText:SetColor(self.kNormalTextColor)

    self:HookEvent(self, "OnCurrentHPChanged", self.OnCurrentHPChanged)
    self:OnCurrentHPChanged(self:GetCurrentHP())

    self:HookEvent(self, "OnBrokenChanged", self.OnBrokenChanged)
    self:OnBrokenChanged(self:GetBroken())

    self:HookEvent(GetGlobalEventDispatcher(), "OnResolutionChanged", self.OnResolutionChanged)

end

function GUIBoneShieldDisplay:OnResolutionChanged(newX, newY)

    self.scale = newY / kMockupHeight
    self:SetScale(self.scale, self.scale)
    self:SetY(-(Client.GetScreenHeight() * 0.2))

end

function GUIBoneShieldDisplay:OnBrokenChanged(newBroken)
    if newBroken then
        self:SetTexture(self.kBackgroundBrokenTexture)
    else
        self:SetTexture(self.kBackgroundTexture)
    end
    self:SetSizeFromTexture()
end

function GUIBoneShieldDisplay:OnCurrentHPChanged(newAmount)

    local currentHP = self:GetCurrentHP()
    local maxHP = self:GetMaxHP()
    local fullWidth = self.kOriginalTextureCoordinates[3]
    local newWidth = fullWidth * (newAmount / maxHP)
    local spentWidth = fullWidth - newWidth
    local sideX = spentWidth / 2

    local texCoordX1 = sideX
    local texCoordX2 = fullWidth - sideX

    self.bar:SetWidth(newWidth)
    self.bar:SetTexturePixelCoordinates(
            texCoordX1, 0,
            texCoordX2, self.kOriginalTextureCoordinates[4])

    self.hpText:SetText(string.format("%d", currentHP))
    self.hpText:SetX(-self.hpText:GetSize().x)
    self.hpText:SetColor(currentHP <= kTextLowAmount and self.kLowTextColor or self.kNormalTextColor)

end

function GUIBoneShieldDisplay:StartFlashing()
    self:SetUpdates(true)
    self.flashing = true
    self.flashTimesLooped = 0
    self.flashExitProgress = 0
end

function GUIBoneShieldDisplay:StopFlashing()
    self:SetUpdates(false)
    self.flashIntroProgress = 0
    self.flashLoopProgress = 0
    self.flashTimesLooped = 0
    self.flashLoopReturning = false
    self.flashExitProgress = 0
end

function GUIBoneShieldDisplay:GetIsFlashing()
    return self.flashing
end

function GUIBoneShieldDisplay:OnUpdate(deltaTime, now)

    if self.flashIntroProgress < 1 then -- Normal color to start of red->white flash
        self.flashIntroProgress = Clamp(self.flashIntroProgress + (kFlashTransitionRate * deltaTime), 0, 1)
        self.bar:SetColor(LerpColor(self.kNormalColor, self.kHurtColor1, self.flashIntroProgress))
    elseif self.flashTimesLooped < kNumFlashLoops then -- Looping from kHurtColor1 to kHurtColor2 and back
        if not self.flashLoopReturning then
            self.flashLoopProgress = Clamp(self.flashLoopProgress + (kFlashTransitionRate * deltaTime), 0, 1)
            self.bar:SetColor(LerpColor(self.kHurtColor1, self.kHurtColor2, self.flashLoopProgress))
            self.flashLoopReturning = self.flashLoopProgress == 1
        else
            self.flashLoopProgress = Clamp(self.flashLoopProgress - (kFlashTransitionRate * deltaTime), 0, 1)
            self.bar:SetColor(LerpColor(self.kHurtColor1, self.kHurtColor2, self.flashLoopProgress))
            if self.flashLoopProgress == 0 then
                self.flashTimesLooped = self.flashTimesLooped + 1
                self.flashLoopReturning = false
            end
        end
    elseif self.flashExitProgress < 1 then
        self.flashExitProgress = Clamp(self.flashExitProgress + (kFlashTransitionRate * deltaTime), 0, 1)
        self.bar:SetColor(LerpColor(self.kHurtColor1, self.kNormalColor, self.flashExitProgress))
    end

    if self.flashExitProgress == 1 then
        self:StopFlashing()
    end

end
