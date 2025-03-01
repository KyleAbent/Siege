-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIGorgeBuildMenuExtra.lua
--
-- Created by: (Your name here)
--
-- Advanced structure build menu for Gorge (Whip, Crag, Shift, Shade)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")

local kMouseOverSound = "sound/NS2.fev/alien/common/alien_menu/hover"
local kSelectSound = "sound/NS2.fev/alien/common/alien_menu/evolve"
local kCloseSound = "sound/NS2.fev/alien/common/alien_menu/sell_upgrade"
local kFontName = Fonts.kAgencyFB_Small
Client.PrecacheLocalSound(kMouseOverSound)
Client.PrecacheLocalSound(kSelectSound)
Client.PrecacheLocalSound(kCloseSound)

function GorgeBuildExtra_OnClose()
    StartSoundEffect(kCloseSound)
end

function GorgeBuildExtra_OnSelect()
    StartSoundEffect(kSelectSound)
end

function GorgeBuildExtra_OnMouseOver()
    StartSoundEffect(kMouseOverSound)
end

function GorgeBuildExtra_Close()

    local player = Client.GetLocalPlayer()
    local dropStructureAbility = player:GetWeapon(DropStructureAbilityExtra.kMapName)

    if dropStructureAbility then
        dropStructureAbility:DestroyBuildMenu()
    end

end

function GorgeBuildExtra_SendSelect(index)
    local player = Client.GetLocalPlayer()

    if player then
        local dropStructureAbility = player:GetWeapon(DropStructureAbilityExtra.kMapName)
        if dropStructureAbility then
            dropStructureAbility:SetActiveStructure(index)
        end
    end
end

function GorgeBuildExtra_GetIsAbilityAvailable(index)

    return DropStructureAbilityExtra.kSupportedStructures[index] and DropStructureAbilityExtra.kSupportedStructures[index]:IsAllowed(Client.GetLocalPlayer())

end

function GorgeBuildExtra_AllowConsumeDrop(techId)
    return LookupTechData(techId, kTechDataAllowConsumeDrop, false)
end

function GorgeBuildExtra_GetCanAffordAbility(techId)

    local player = Client.GetLocalPlayer()
    local abilityCost = LookupTechData(techId, kTechDataCostKey, 0)
    local exceededLimit = not GorgeBuildExtra_AllowConsumeDrop(techId) and GorgeBuildExtra_GetNumStructureBuilt(techId) >= GorgeBuildExtra_GetMaxNumStructure(techId)

    return player:GetResources() >= abilityCost and not exceededLimit

end

function GorgeBuildExtra_GetStructureCost(techId)
    return LookupTechData(techId, kTechDataCostKey, 0)
end

local function GorgeBuildExtra_GetKeybindForIndex(index)
    return "Weapon" .. ToString(index)
end

function GorgeBuildExtra_GetNumStructureBuilt(techId)

    local player = Client.GetLocalPlayer()
    local ability = player:GetActiveWeapon()

    if ability and ability:isa("DropStructureAbilityExtra") then
        return ability:GetNumStructuresBuilt(techId)
    end

    return -1

end

function GorgeBuildExtra_GetMaxNumStructure(techId)

    return LookupTechData(techId, kTechDataMaxAmount, -1)

end

class 'GUIGorgeBuildMenuExtra' (GUIAnimatedScript)

GUIGorgeBuildMenuExtra.kBaseYResolution = 1200

GUIGorgeBuildMenuExtra.kButtonWidth = 180
GUIGorgeBuildMenuExtra.kButtonHeight = 180

GUIGorgeBuildMenuExtra.kBackgroundYOffset = GUIGorgeBuildMenuExtra.kButtonHeight * 0.5

-- Use the same texture but consider having different sprite coordinates for advanced structures
GUIGorgeBuildMenuExtra.kButtonTexture = "ui/gorge_build_menu.dds"
GUIGorgeBuildMenuExtra.kBuyMenuTexture = "ui/alien_buymenu.dds"
GUIGorgeBuildMenuExtra.kSmokeSmallTextureCoordinates = { { 916, 4, 1020, 108 }, { 916, 15, 1020, 219 }, { 916, 227, 1020, 332 }, { 916, 332, 1020, 436 } }

GUIGorgeBuildMenuExtra.kPixelSize = 128

GUIGorgeBuildMenuExtra.kAvailableColor = kAlienTeamColorFloat
GUIGorgeBuildMenuExtra.kTooExpensiveColor = Color(1, 0, 0, 1)
GUIGorgeBuildMenuExtra.kUnavailableColor = Color(0.4, 0.4, 0.4, 0.7)

-- selection circle animation:
GUIGorgeBuildMenuExtra.kPulseInAnimationDuration = 0.6
GUIGorgeBuildMenuExtra.kPulseOutAnimationDuration = 0.3
GUIGorgeBuildMenuExtra.kLowColor = Color(1, 0.4, 0.4, 0.5)
GUIGorgeBuildMenuExtra.kHighColor = Color(1, 1, 1, 1)

GUIGorgeBuildMenuExtra.kPersonalResourceIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 144, Y1 = 363, X2 = 192, Y2 = 411} }
GUIGorgeBuildMenuExtra.kPersonalResourceIcon.Width = 32
GUIGorgeBuildMenuExtra.kPersonalResourceIcon.Height = 32
GUIGorgeBuildMenuExtra.kResourceTexture = "ui/alien_commander_textures.dds"
GUIGorgeBuildMenuExtra.kIconTextXOffset = 5

GUIGorgeBuildMenuExtra.kBackgroundNoiseTexture = "ui/alien_commander_bg_smoke.dds"
GUIGorgeBuildMenuExtra.kSmokeyBackgroundSize = Vector(220, 400, 0)

local kDefaultStructureCountPos = Vector(-48, -24, 0)
local kCenteredStructureCountPos = Vector(0, -24, 0)

--selection circle animation callbacks
function PulseOutAnimationExtra(script, item)
    item:SetColor(GUIGorgeBuildMenuExtra.kHighColor, GUIGorgeBuildMenuExtra.kPulseInAnimationDuration, "PULSE", AnimateLinear, PulseInAnimationExtra)
end

function PulseInAnimationExtra(script, item)
    item:SetColor(GUIGorgeBuildMenuExtra.kLowColor, GUIGorgeBuildMenuExtra.kPulseOutAnimationDuration, "PULSE", AnimateLinear, PulseOutAnimationExtra)
end

local rowTable
local function GetRowForTechId(techId)

    if not rowTable then

        rowTable = {}
        -- Advanced structures - define row positions
        rowTable[kTechId.Whip] = 1
        rowTable[kTechId.Crag] = 2
        rowTable[kTechId.Shift] = 3
        rowTable[kTechId.Shade] = 4

    end

    return rowTable[techId]

end

function GUIGorgeBuildMenuExtra:Initialize()

    GUIAnimatedScript.Initialize(self)

    self.kSmokeyBackgroundSize = GUIScale(Vector(220, 400, 0))

    self.scale = Client.GetScreenHeight() / GUIGorgeBuildMenuExtra.kBaseYResolution
    self.background = self:CreateAnimatedGraphicItem()
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.background:SetColor(Color(0,0,0,0))

    self.buttons = {}

    self:Reset()

end

function GUIGorgeBuildMenuExtra:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)

end

function GUIGorgeBuildMenuExtra:GetIsVisible()
    return self.background:GetIsVisible()
end

function GUIGorgeBuildMenuExtra:SetIsVisible(isVisible)
    self.background:SetIsVisible(isVisible == true)
end

function GUIGorgeBuildMenuExtra:_HandleMouseOver(onItem)

    if onItem ~= self.lastActiveItem then
        GorgeBuildExtra_OnMouseOver()
        self.lastActiveItem = onItem
    end

end

local function UpdateButton(button, index)

    local col = 1
    local color = GUIGorgeBuildMenuExtra.kAvailableColor

    if not GorgeBuildExtra_GetCanAffordAbility(button.techId) then
        col = 2
        color = GUIGorgeBuildMenuExtra.kTooExpensiveColor
    end

    if not GorgeBuildExtra_GetIsAbilityAvailable(index) then
        col = 3
        color = GUIGorgeBuildMenuExtra.kUnavailableColor
    end

    local row = GetRowForTechId(button.techId)

    button.smokeyBackground:SetIsVisible(Client.GetHudDetail() ~= kHUDMode.Minimal)
    button.graphicItem:SetTexturePixelCoordinates(GUIGetSprite(col, row, GUIGorgeBuildMenuExtra.kPixelSize, GUIGorgeBuildMenuExtra.kPixelSize))
    button.description:SetColor(color)
    button.costIcon:SetColor(color)
    button.costText:SetColor(color)

    local numLeft = GorgeBuildExtra_GetNumStructureBuilt(button.techId)
    if numLeft == -1 then
        button.structuresLeft:SetIsVisible(false)
    else
        button.structuresLeft:SetIsVisible(true)
        local amountString = ToString(numLeft)
        local maxNum = GorgeBuildExtra_GetMaxNumStructure(button.techId)

        if maxNum > 0 then
            amountString = amountString .. "/" .. ToString(maxNum)
        end

        if numLeft >= maxNum then
            color = GUIGorgeBuildMenuExtra.kTooExpensiveColor
        end

        button.structuresLeft:SetColor(color)
        button.structuresLeft:SetText(amountString)

    end

    local cost = GorgeBuildExtra_GetStructureCost(button.techId)
    if cost == 0 then

        button.costIcon:SetIsVisible(false)
        button.structuresLeft:SetPosition(kCenteredStructureCountPos)

    else

        button.costIcon:SetIsVisible(true)
        button.costText:SetText(ToString(cost))
        button.structuresLeft:SetPosition(kDefaultStructureCountPos)

    end

end

function GUIGorgeBuildMenuExtra:Update(deltaTime)

    PROFILE("GUIGorgeBuildMenuExtra:Update")

    GUIAnimatedScript.Update(self, deltaTime)

    for index, button in ipairs(self.buttons) do

        UpdateButton(button, index)

    end

end

function GUIGorgeBuildMenuExtra:Reset()

    self.background:SetUniformScale(self.scale)

    for index, structureAbility in ipairs(DropStructureAbilityExtra.kSupportedStructures) do

        table.insert( self.buttons, self:CreateButton(structureAbility.GetDropStructureId(), self.scale, self.background, GorgeBuildExtra_GetKeybindForIndex(index), index - 1) )

    end

    local backgroundXOffset = (#self.buttons * GUIGorgeBuildMenuExtra.kButtonWidth) * -.5
    self.background:SetPosition(Vector(backgroundXOffset, GUIGorgeBuildMenuExtra.kBackgroundYOffset, 0))

end

function GUIGorgeBuildMenuExtra:OnResolutionChanged(oldX, oldY, newX, newY)

    self:Uninitialize()
    self:Initialize()

end

function GUIGorgeBuildMenuExtra:CreateButton(techId, scale, frame, keybind, position)

    local button =
    {
        frame = self:CreateAnimatedGraphicItem(),
        background = self:CreateAnimatedGraphicItem(),
        graphicItem = self:CreateAnimatedGraphicItem(),
        description = self:CreateAnimatedTextItem(),
        keyIcon = GUICreateButtonIcon(keybind, true),
        keybind = keybind,
        techId = techId,
        structuresLeft = self:CreateAnimatedTextItem(),
        costIcon = self:CreateAnimatedGraphicItem(),
        costText = self:CreateAnimatedTextItem(),
    }

    local minimal = Client.GetHudDetail() == kHUDMode.Minimal
    local backgroundSize = ConditionalValue(minimal, Vector(0,0,0), self.kSmokeyBackgroundSize)
    local backgroundTexCoords = ConditionalValue(minimal, {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}}, self.kSmokeSmallTextureCoordinates)

    local smokeyBackground = GetGUIManager():CreateGraphicItem()
    smokeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    smokeyBackground:SetSize(self.kSmokeyBackgroundSize)
    smokeyBackground:SetPosition(self.kSmokeyBackgroundSize * -.5)
    smokeyBackground:SetShader("shaders/GUISmokeHUD.surface_shader")
    smokeyBackground:SetTexture("ui/alien_logout_smkmask.dds")
    smokeyBackground:SetAdditionalTexture("noise", self.kBackgroundNoiseTexture)
    smokeyBackground:SetFloatParameter("correctionX", 0.6)
    smokeyBackground:SetFloatParameter("correctionY", 1)
    smokeyBackground:SetIsVisible(not minimal)

    button.frame:SetUniformScale(scale)
    button.frame:SetSize(Vector(GUIGorgeBuildMenuExtra.kButtonWidth, GUIGorgeBuildMenuExtra.kButtonHeight, 0))
    button.frame:SetColor(Color(1,1,1,0))
    button.frame:SetPosition(Vector(position * GUIGorgeBuildMenuExtra.kButtonWidth, 0, 0))
    frame:AddChild(button.frame)

    button.background:SetUniformScale(scale)
    button.graphicItem:SetUniformScale(scale)
    button.frame:AddChild(button.background)

    button.description:SetUniformScale(scale)

    button.background:SetSize(Vector(GUIGorgeBuildMenuExtra.kButtonWidth, GUIGorgeBuildMenuExtra.kButtonHeight * 1.5, 0))
    button.background:SetColor(Color(0,0,0,0))

    button.graphicItem:SetSize(Vector(GUIGorgeBuildMenuExtra.kButtonWidth, GUIGorgeBuildMenuExtra.kButtonHeight, 0))
    button.graphicItem:SetTexture(GUIGorgeBuildMenuExtra.kButtonTexture)
    button.graphicItem:SetShader("shaders/GUIWavyNoMask.surface_shader")

    button.description:SetText(Locale.ResolveString(LookupTechData(techId, kTechDataDisplayName, "")))
    button.description:SetAnchor(GUIItem.Middle, GUIItem.Top)
    button.description:SetTextAlignmentX(GUIItem.Align_Center)
    button.description:SetTextAlignmentY(GUIItem.Align_Center)
    button.description:SetScale(GetScaledVector())
    button.description:SetFontName(kFontName)
    GUIMakeFontScale(button.description)
    button.description:SetPosition(Vector(0, 0, 0))
    button.description:SetFontIsBold(true)

    button.keyIcon:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    button.keyIcon:SetFontName(kFontName)
    GUIMakeFontScale(button.keyIcon)
    local pos = Vector(-button.keyIcon:GetSize().x/2, 0.5*button.keyIcon:GetSize().y, 0)
    button.keyIcon:SetPosition(pos)

    button.structuresLeft:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    button.structuresLeft:SetTextAlignmentX(GUIItem.Align_Center)
    button.structuresLeft:SetTextAlignmentY(GUIItem.Align_Center)
    button.structuresLeft:SetScale(GetScaledVector())
    button.structuresLeft:SetFontName(kFontName)
    GUIMakeFontScale(button.structuresLeft)
    button.structuresLeft:SetPosition(kDefaultStructureCountPos)
    button.structuresLeft:SetFontIsBold(true)
    button.structuresLeft:SetColor(GUIGorgeBuildMenuExtra.kAvailableColor)

    -- Personal display.
    button.costIcon:SetSize(Vector(GUIGorgeBuildMenuExtra.kPersonalResourceIcon.Width, GUIGorgeBuildMenuExtra.kPersonalResourceIcon.Height, 0))
    button.costIcon:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    button.costIcon:SetTexture(GUIGorgeBuildMenuExtra.kResourceTexture)
    button.costIcon:SetPosition(Vector(0, -GUIGorgeBuildMenuExtra.kPersonalResourceIcon.Height * .5 - 24, 0))
    button.costIcon:SetUniformScale(scale)
    GUISetTextureCoordinatesTable(button.costIcon, GUIGorgeBuildMenuExtra.kPersonalResourceIcon.Coords)

    button.costText:SetUniformScale(scale)
    button.costText:SetAnchor(GUIItem.Right, GUIItem.Center)
    button.costText:SetTextAlignmentX(GUIItem.Align_Min)
    button.costText:SetTextAlignmentY(GUIItem.Align_Center)
    button.costText:SetPosition(Vector(GUIGorgeBuildMenuExtra.kIconTextXOffset, 0, 0))
    button.costText:SetColor(Color(1, 1, 1, 1))
    button.costText:SetFontIsBold(true)
    button.costText:SetScale(GetScaledVector())
    button.costText:SetFontName(kFontName)
    GUIMakeFontScale(button.costText)
    button.costText:SetColor(GUIGorgeBuildMenuExtra.kAvailableColor)
    button.costIcon:AddChild(button.costText)

    button.smokeyBackground = smokeyBackground
    button.background:AddChild(smokeyBackground)
    button.background:AddChild(button.graphicItem)
    button.graphicItem:AddChild(button.description)
    button.graphicItem:AddChild(button.structuresLeft)
    button.graphicItem:AddChild(button.keyIcon)
    button.graphicItem:AddChild(button.costIcon)

    return button

end

function GUIGorgeBuildMenuExtra:OverrideInput(input)

    -- Assume the user wants to switch the top-level weapons
    if HasMoveCommand( input.commands, Move.SelectNextWeapon )
    or HasMoveCommand( input.commands, Move.SelectPrevWeapon ) then

        GorgeBuildExtra_OnClose()
        GorgeBuildExtra_Close()
        return input

    end

    local weaponSwitchCommands = { Move.Weapon1, Move.Weapon2, Move.Weapon3, Move.Weapon4, Move.Weapon5 }

    local selectPressed = false

    for index, weaponSwitchCommand in ipairs(weaponSwitchCommands) do

        if HasMoveCommand( input.commands, weaponSwitchCommand ) then

            if GorgeBuildExtra_GetIsAbilityAvailable(index) and GorgeBuildExtra_GetCanAffordAbility(self.buttons[index].techId)  then

                GorgeBuildExtra_SendSelect(index)
                input.commands = RemoveMoveCommand( input.commands, weaponSwitchCommand )

            end

            selectPressed = true
            break

        end

    end

    if selectPressed then

        GorgeBuildExtra_OnClose()
        GorgeBuildExtra_Close()

    elseif HasMoveCommand( input.commands, Move.SecondaryAttack )
        or HasMoveCommand( input.commands, Move.PrimaryAttack ) then

        -- close menu
        GorgeBuildExtra_OnClose()
        GorgeBuildExtra_Close()

        -- leave the secondary attack command so the drop-ability can handle it
        input.commands = AddMoveCommand( input.commands, Move.SecondaryAttack )
        input.commands = RemoveMoveCommand( input.commands, Move.PrimaryAttack )

    end

    return input, selectPressed

end

function GUIGorgeBuildMenuExtra:_GetIsMouseOver(overItem)

    return GUIItemContainsPoint(overItem, Client.GetCursorPosScreen())

end

function GUIGorgeBuildMenuExtra:OnAnimationCompleted(animatedItem, animationName, itemHandle)
end

-- called when the last animation remaining has completed this frame
function GUIGorgeBuildMenuExtra:OnAnimationsEnd(item)
end