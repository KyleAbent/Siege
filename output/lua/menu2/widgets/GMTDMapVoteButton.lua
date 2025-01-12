-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/GMTDMapVoteButton.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- Parameters (* = required)
--
--          levelName                   string. Must match an approved level name as defined in kThunderdomeMaps.
-- Events
--          OnMapVoteSelected           Happens when this button is clicked, and is not in a non-reactive state
--                                      as defined by GMTDMapVoteButton:GetShouldReactToMouseEvents()
--                                      Passes this button as the only parameter.
--
--          OnMapVoteUndo               Happens when this button is RIGHT clicked, and the button is in the
--                                      "selected" state. (not confirmed)
--                                      Passes this button as the only parameter.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/GUI/wrappers/FXState.lua")

local kLockedBackgroundKey = "LOCKED"

local kNotVotedRank = 0
local kButtonFrameState = enum ({ 'Default', 'Hovered', 'Selected', 'Voted', 'Locked' })

local kVoteRankToLocale =
{
    "THUNDERDOME_VOTEBUTTON_FIRSTCHOICE",
    "THUNDERDOME_VOTEBUTTON_SECONDCHOICE",
    "THUNDERDOME_VOTEBUTTON_THIRDCHOICE",
}

local function GetPixelCoordinatesForButtonFrame(frameState)

    local index = 0
    if frameState == kButtonFrameState.Hovered then
        index = 1
    elseif frameState == kButtonFrameState.Selected or frameState == kButtonFrameState.Voted then
        index = 2
    end

    local ySpaceBetweenFrames = 10 -- Prevents scaling showing part of other frame.

    local sizeX = GMTDMapVoteButton.kThumbnailFrameTextureSize.x
    local sizeY = GMTDMapVoteButton.kThumbnailFrameTextureSize.y

    local xStart = 0
    local yStart = ySpaceBetweenFrames + (sizeY * index) + (index * ySpaceBetweenFrames)

    return { xStart, yStart, sizeX, (yStart + sizeY) }

end

local buttonClass = GetFXStateWrappedClass(GUIButton)

class "GMTDMapVoteButton" (GUIObject)

GMTDMapVoteButton:AddClassProperty("VoteRank", kNotVotedRank)
GMTDMapVoteButton:AddClassProperty("LevelName", "")
GMTDMapVoteButton:AddClassProperty("ButtonState", kButtonFrameState.Default)
GMTDMapVoteButton:AddCompositeClassProperty("MouseOver", "button")

GMTDMapVoteButton.kThumbnailTexture      = PrecacheAsset("ui/thunderdome/mapvote_mapimages.dds")
GMTDMapVoteButton.kThumbnailFrameTexture = PrecacheAsset("ui/thunderdome/mapvote_buttonframes.dds")
GMTDMapVoteButton.kVotedCheckTexture     = PrecacheAsset("ui/thunderdome/mapvote_checkmark.dds")
GMTDMapVoteButton.kThumbnailSize = Vector(395, 236, 0)
GMTDMapVoteButton.kThumbnailFrameTextureSize = Vector(399, 242, 0)

-- Alphas for when the button is hovered/voted, and when it is not.
GMTDMapVoteButton.kThumbnailInactiveAlpha = 0.66
GMTDMapVoteButton.kThumbnailActiveAlpha = 1

function GMTDMapVoteButton:GetShouldReactToMouseEvents()

    local buttonState = self:GetButtonState()
    return (buttonState ~= kButtonFrameState.Locked and buttonState ~= kButtonFrameState.Selected and buttonState ~= kButtonFrameState.Voted)

end

function GMTDMapVoteButton:OnMouseClick(_)

    if self:GetShouldReactToMouseEvents() then
        PlayMenuSound("AcceptChoice")
        self:FireEvent("OnMapVoteSelected", self)
    elseif self:GetButtonState() == kButtonFrameState.Selected then
        PlayMenuSound("CancelChoice")
        self:FireEvent("OnMapVoteUndo", self)
    end

end

function GMTDMapVoteButton:OnMouseRightClick(_)

    if self:GetButtonState() == kButtonFrameState.Selected then
        PlayMenuSound("CancelChoice")
        self:FireEvent("OnMapVoteUndo", self)
    end

end

function GMTDMapVoteButton:OnHoverChanged()

    if self:GetShouldReactToMouseEvents() then

        local hovered = self.button:GetMouseOver()
        self:SetButtonState(ConditionalValue(hovered, kButtonFrameState.Hovered, kButtonFrameState.Default))
        self.button:SetColor(1, 1, 1, hovered and self.kThumbnailActiveAlpha or self.kThumbnailInactiveAlpha)
        self.thumbnailFrame:SetTexturePixelCoordinates(GUIUnpackCoords(GetPixelCoordinatesForButtonFrame(hovered and kButtonFrameState.Hovered or kButtonFrameState.Default)))

        -- Play sound
        if hovered then
            PlayMenuSound("ButtonHover")
        end

    end

    self:FireEvent("OnMapVoteButtonMouseOver", self)

end

function GMTDMapVoteButton:GetCanBeDoubleClicked()
    return false
end

-- Selected, but not confirmed.
function GMTDMapVoteButton:SetSelected(voteRank)

    assert(voteRank and voteRank > 0)
    self:SetVoteRank(voteRank)
    self:SetButtonState(kButtonFrameState.Selected)

    self.button:SetColor(1, 1, 1, self.kThumbnailActiveAlpha)
    self.button:SetEnabled(false)

    self.thumbnailFrame:SetTexturePixelCoordinates(GUIUnpackCoords(GetPixelCoordinatesForButtonFrame(kButtonFrameState.Selected)))

    local locale = kVoteRankToLocale[voteRank]
    if locale then
        self.votedDesc:SetText(Locale.ResolveString(locale))
    end

    self.votedCheck:SetVisible(true)
    self.votedTitle:SetVisible(false)
    self.votedDesc:SetVisible(true) -- "First Choice" etc.

end

function GMTDMapVoteButton:SetVoted()

    self:SetButtonState(kButtonFrameState.Voted)

    self.button:SetColor(1, 1, 1, self.kThumbnailActiveAlpha)
    self.button:SetEnabled(false)

    self.thumbnailFrame:SetTexturePixelCoordinates(GUIUnpackCoords(GetPixelCoordinatesForButtonFrame(kButtonFrameState.Voted)))

    local locale = kVoteRankToLocale[self:GetVoteRank()]
    if locale then
        self.votedDesc:SetText(Locale.ResolveString(locale))
    end

    self.votedCheck:SetVisible(true)
    self.votedTitle:SetVisible(true)
    self.votedDesc:SetVisible(true)

end

-- Button is locked due max votes being reached. ( But not voted on )
function GMTDMapVoteButton:SetLocked()

    self:SetVoteRank(kNotVotedRank)
    self:SetButtonState(kButtonFrameState.Locked)

    local pixelCoords = GetMapBackgroundPixelCoordinates(kLockedBackgroundKey)
    self.button:SetTexturePixelCoordinates(GUIUnpackCoords(pixelCoords))
    self.button:SetColor(1, 1, 1, self.kThumbnailInactiveAlpha)
    self.button:SetEnabled(false)

    self.thumbnailFrame:SetTexturePixelCoordinates(GUIUnpackCoords(GetPixelCoordinatesForButtonFrame(kButtonFrameState.Default)))

    self.votedCheck:SetVisible(false)
    self.votedTitle:SetVisible(false)
    self.votedDesc:SetVisible(false)

end

function GMTDMapVoteButton:Reset()

    self:SetVoteRank(kNotVotedRank)
    self:SetButtonState(kButtonFrameState.Default)

    local pixelCoords = GetMapBackgroundPixelCoordinates(kThunderdomeMaps[self:GetLevelName()])
    self.button:SetTexturePixelCoordinates(GUIUnpackCoords(pixelCoords))
    self.button:SetColor(1, 1, 1, self.kThumbnailInactiveAlpha)
    self.button:SetEnabled(true)

    self.thumbnailFrame:SetTexturePixelCoordinates(GUIUnpackCoords(GetPixelCoordinatesForButtonFrame(kButtonFrameState.Default)))

    self.votedCheck:SetVisible(false)
    self.votedTitle:SetVisible(false)
    self.votedDesc:SetVisible(false)

end

function GMTDMapVoteButton:GetLevelLocaleText()
    return self.levelTitle:GetText()
end

function GMTDMapVoteButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    -- Levelname absolutely required.
    RequireType({"string"}, params.levelName, "params.levelName", errorDepth)
    assert(GetIsValidMap(params.levelName))

    self:SetLevelName(params.levelName)

    self:SetSize(self.kThumbnailFrameTextureSize)

    self.button = CreateGUIObject(string.format("button_%s", self:GetLevelName()), buttonClass, self, {}, errorDepth)
    self.button:SetTexture(self.kThumbnailTexture)
    self.button:SetSize(self.kThumbnailSize)
    self.button:AlignCenter()
    self:ListenForKeyInteractions(self.button:GetRootItem()) -- Right Mouse Button.

    self.thumbnailFrame = CreateGUIObject("thumbnailFrame", GUIObject, self, params, errorDepth)
    self.thumbnailFrame:SetTexture(self.kThumbnailFrameTexture)
    self.thumbnailFrame:SetSize(self.kThumbnailFrameTextureSize)
    self.thumbnailFrame:AlignCenter()
    self.thumbnailFrame:SetColor(1,1,1)

    local titlePositionOffset = Vector(18, -13, 0)
    self.levelTitle = CreateGUIObject("levelTitle", GUIText, self, params, errorDepth)
    self.levelTitle:SetText(Locale.ResolveString(GetMapTitleLocale(kThunderdomeMaps[self:GetLevelName()])))
    self.levelTitle:SetFont("AgencyBold", 48)
    self.levelTitle:SetColor(147/255, 176/255, 183/255)
    self.levelTitle:AlignBottomLeft()
    self.levelTitle:SetPosition(titlePositionOffset)

    self.votedCheck = CreateGUIObject("votedCheck", GUIObject, self, params, errorDepth)
    self.votedCheck:SetTexture(self.kVotedCheckTexture)
    self.votedCheck:SetSizeFromTexture()
    self.votedCheck:SetColor(1, 1, 1)
    self.votedCheck:SetPosition(15, 60)

    local titlePosX = self.votedCheck:GetPosition().x + self.votedCheck:GetSize().x
    local titlePosY = self.votedCheck:GetPosition().y - 5

    self.votedTitle = CreateGUIObject("votedTitle", GUIText, self, params, errorDepth)
    self.votedTitle:SetFont("MicrogrammaBold", 32)
    self.votedTitle:SetText(Locale.ResolveString("THUNDERDOME_VOTEBUTTON_VOTED"))
    self.votedTitle:SetPosition(titlePosX, titlePosY)

    titlePosX = titlePosX + 15
    titlePosY = titlePosY + self.votedTitle:GetSize().y - 15

    self.votedDesc = CreateGUIObject("votedDesc", GUIText, self, params, errorDepth)
    self.votedDesc:SetFont("AgencyBold", 31)
    self.votedDesc:SetPosition(titlePosX, titlePosY)

    self:HookEvent(self.button, "OnMouseClick", self.OnMouseClick)
    self:HookEvent(self.button, "OnMouseRightClick", self.OnMouseRightClick)
    self:HookEvent(self.button, "OnMouseOverChanged", self.OnHoverChanged)

    self:Reset()

end