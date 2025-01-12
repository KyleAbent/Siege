-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDMapOverviewWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIText.lua")

local kMinimapIconsTexture = PrecacheAsset("ui/minimap_blip.dds")
local kMinimapIconWidth = 32
local kMinimapIconHeight = 32

local kMinimapObjectType = enum({'TechPoint', 'ResourceNode', 'PowerPoint', 'Location'})
local kMinimapObjectAtlasPositions = -- Only for textured blips. Location names are just text.
{
    [kMinimapObjectType.TechPoint]    = { x = 1, y = 1},
    [kMinimapObjectType.ResourceNode] = { x = 2, y = 1},
    [kMinimapObjectType.PowerPoint]   = { x = 8, y = 8},
}

local kLegendLabelPadding = 10
local kLegendLabelFont = "Agency"

local kDefaultLabelFontSize = 48
local kDefaultTitleLabelFontSize = 30
local kDefaultTitleFontSize = 50
local kDefaultMapLocationFontSize = 28

local kOverviewBackgroundWidth = 1045

class "GMTDMapOverviewWidget" (GUIObject)

GMTDMapOverviewWidget:AddClassProperty("LevelName", kThunderdomeMaps[kThunderdomeMaps.RANDOMIZE])
GMTDMapOverviewWidget:AddClassProperty("MapYAnchor", 0) -- Where in the vertical free space should the actual map be placed.
GMTDMapOverviewWidget:AddClassProperty("ShowOverviewBackground", false) -- Whether to show the map overview checkered background or not.

GMTDMapOverviewWidget.kOverviewBackgroundTexture      = PrecacheAsset("ui/thunderdome/td_overview_planning_background.dds")
GMTDMapOverviewWidget.kOverviewTechPointLegendIcon    = PrecacheAsset("ui/thunderdome/overview_techpoint_legendicon.dds")
GMTDMapOverviewWidget.kOverviewResourceNodeLegendIcon = PrecacheAsset("ui/thunderdome/overview_resourcenode_legendicon.dds")

GMTDMapOverviewWidget.kOverviewLegendLabelColor = ColorFrom255(147, 176, 183)
GMTDMapOverviewWidget.kOverviewBlipColor        = GetAdvancedOption("mapelementscolor")
GMTDMapOverviewWidget.kTechPointColor_AnyTeam   = ColorFrom255(204,   0, 255) -- purple
GMTDMapOverviewWidget.kTechPointColor_Marines   = ColorFrom255(  0, 216, 255) -- blue
GMTDMapOverviewWidget.kTechPointColor_Aliens    = ColorFrom255(255, 138,   0) -- orange
GMTDMapOverviewWidget.kTechPointColor_Neither   = GMTDMapOverviewWidget.kOverviewBlipColor

GMTDMapOverviewWidget.kOverviewGraphicalLayer = 1
GMTDMapOverviewWidget.kOverviewLocationLayer  = 2

function GMTDMapOverviewWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    -- Contains all the little blips like TechPoint icons, Resource Node icons, and location names that should show on the overview
    self.overviewResourceNodeObjects = {}
    self.overviewTechPointObjects = {}
    self.overviewPowernodeObjects = {}
    self.overviewLocationObjects = {}

    self.overview = CreateGUIObject("overview", GUIObject, self, params, errorDepth)
    self.overview:AlignTop()
    self.overview:SetColor(1, 1, 1, 0.6)
    self.overview:SetVisible(false)

    self.overviewBackground = CreateGUIObject("overviewBackground", GUIObject, self.overview, params, errorDepth)
    self.overviewBackground:SetTexture(self.kOverviewBackgroundTexture)
    self.overviewBackground:SetSizeFromTexture()
    self.overviewBackground:SetColor(1,1,1)
    self.overviewBackground:SetOpacity(0)
    self.overviewBackground:SetLayer(-1)
    self.overviewBackground:AlignCenter()

    self.overviewTitleLabel = CreateGUIObject("overviewTitleLabel", GUIText, self, params, errorDepth)
    self.overviewTitleLabel:SetPosition(37, 23)
    self.overviewTitleLabel:SetFont("Agency", kDefaultTitleLabelFontSize)
    self.overviewTitleLabel:SetText(string.format("%s%s", Locale.ResolveString("THUNDERDOME_OVERVIEW_MAP_LABEL"), ":"))

    self.overviewTitle = CreateGUIObject("overviewTitle", GUIText, self, params, errorDepth)
    self.overviewTitle:SetPosition(37, 46)
    self.overviewTitle:SetFont("AgencyBold", kDefaultTitleFontSize)
    self.overviewTitle:SetColor(ColorFrom255(219, 219, 219))

    self.overviewTechPointLegendIcon = CreateGUIObject("overviewTechPointLegendIcon", GUIObject, self)
    self.overviewTechPointLegendIcon:SetTexture(self.kOverviewTechPointLegendIcon)
    self.overviewTechPointLegendIcon:SetSizeFromTexture()
    self.overviewTechPointLegendIcon:AlignTopRight()
    self.overviewTechPointLegendIcon:SetColor(1,1,1)

    self.overviewTechPointLegendLabel = CreateGUIObject("overviewTechPointLegendLabel", GUIText, self.overviewTechPointLegendIcon)
    self.overviewTechPointLegendLabel:SetFont(kLegendLabelFont, kDefaultLabelFontSize)
    self.overviewTechPointLegendLabel:SetColor(self.kOverviewLegendLabelColor)
    self.overviewTechPointLegendLabel:SetText(Locale.ResolveString("THUNDERDOME_TECHPOINTLEGEND_LABEL"))
    self.overviewTechPointLegendLabel:AlignRight()
    self.overviewTechPointLegendLabel:SetX(-self.overviewTechPointLegendIcon:GetSize().x - kLegendLabelPadding)

    self.overviewResourceNodeLegendIcon = CreateGUIObject("overviewResourceNodeLegendIcon", GUIObject, self)
    self.overviewResourceNodeLegendIcon:SetTexture(self.kOverviewResourceNodeLegendIcon)
    self.overviewResourceNodeLegendIcon:SetSizeFromTexture()
    self.overviewResourceNodeLegendIcon:AlignTopRight()
    self.overviewResourceNodeLegendIcon:SetColor(1,1,1)

    self.overviewResourceNodeLegendLabel = CreateGUIObject("overviewResourceNodeLegendLabel", GUIText, self.overviewResourceNodeLegendIcon)
    self.overviewResourceNodeLegendLabel:SetFont(kLegendLabelFont, kDefaultLabelFontSize)
    self.overviewResourceNodeLegendLabel:SetColor(self.kOverviewLegendLabelColor)
    self.overviewResourceNodeLegendLabel:SetText(Locale.ResolveString("THUNDERDOME_RESOURCENODE_LEGEND_LABEL"))
    self.overviewResourceNodeLegendLabel:AlignRight()
    self.overviewResourceNodeLegendLabel:SetX(-self.overviewResourceNodeLegendIcon:GetSize().x - kLegendLabelPadding)

    self:HookEvent(self, "OnLevelNameChanged", self.OnLevelNameChanged)
    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)

    self:HookEvent(self, "OnMapYAnchorChanged", function()
        self:OnSizeChanged(self:GetSize())
    end)

    self:HookEvent(self, "OnShowOverviewBackgroundChanged",
    function()
        self.overviewBackground:SetOpacity(ConditionalValue(self:GetShowOverviewBackground(), 1, 0))
    end)

    self.TDOnLobbyJoined = function()
        self:UpdateBlipColors() -- Just so we can make sure we're using the right colors.
    end

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyJoined, self.TDOnLobbyJoined)

    self:OnSizeChanged(self:GetSize())

end

function GMTDMapOverviewWidget:Uninitialize()
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyJoined, self.TDOnLobbyJoined)
end

function GMTDMapOverviewWidget:UpdateBlipColors()

    self.kOverviewBlipColor = GetAdvancedOption("mapelementscolor")
    self.kTechPointColor_Neither = self.kOverviewBlipColor

    for i = 1, #self.overviewResourceNodeObjects do
        self.overviewResourceNodeObjects[i]:SetColor(self.kOverviewBlipColor)
    end

    for i = 1, #self.overviewPowernodeObjects do
        self.overviewPowernodeObjects[i]:SetColor(self.kOverviewBlipColor)
    end

    self:UpdateGraphicalBlipType(kMinimapObjectType.TechPoint, self:GetLevelName())

end

function GMTDMapOverviewWidget:Reset()
    self:SetLevelName(kThunderdomeMaps[kThunderdomeMaps.RANDOMIZE])
    self:UpdateBlipColors()
end

function GMTDMapOverviewWidget:OnSizeChanged(newSize)

    local techPointIconPaddingPercentage = 0.02
    local techPointIconPositionX = newSize.x * -techPointIconPaddingPercentage
    local techPointIconPositionY = newSize.x * techPointIconPaddingPercentage -- Still use "x" to keep it square
    self.overviewTechPointLegendIcon:SetPosition(techPointIconPositionX, techPointIconPositionY)

    local interIconPaddingPercentage = 0.01
    local rtIconPositionY = self.overviewTechPointLegendIcon:GetPosition().y + self.overviewTechPointLegendIcon:GetSize().y + (newSize.y * interIconPaddingPercentage)
    self.overviewResourceNodeLegendIcon:SetPosition(techPointIconPositionX, rtIconPositionY)

    local labelFontHeightPercentage = 0.035
    local labelFontHeight = newSize.y * labelFontHeightPercentage
    self.overviewResourceNodeLegendLabel:SetFont(kLegendLabelFont, labelFontHeight)
    self.overviewTechPointLegendLabel:SetFont(kLegendLabelFont   , labelFontHeight)

    self.overviewTitleLabel:SetFont("Agency", newSize.y  * 0.03)
    self.overviewTitle:SetFont("AgencyBold", newSize.y * 0.05)
    self.overviewTitle:SetY(self.overviewTitleLabel:GetPosition().y + self.overviewTitleLabel:GetSize().y - 10)

    local overviewStartY = self.overviewResourceNodeLegendIcon:GetPosition().y + self.overviewResourceNodeLegendIcon:GetSize().y
    local freeVerticalSpaceForOverview = newSize.y - overviewStartY
    local overviewSize = math.min(newSize.x, freeVerticalSpaceForOverview)
    self.overview:SetSize(overviewSize, overviewSize)

    local normalizedOverviewYOffset = self:GetMapYAnchor()
    self.overview:SetY(overviewStartY + (normalizedOverviewYOffset * freeVerticalSpaceForOverview))

    local overviewBackgroundScaleMult = overviewSize/kOverviewBackgroundWidth
    self.overviewBackground:SetScale(overviewBackgroundScaleMult, overviewBackgroundScaleMult)

    self:OnLevelNameChanged(self:GetLevelName()) -- Blips need their positions/sizes updated after size changes.

end

function GMTDMapOverviewWidget:HideBlips()

    for i = 1, #self.overviewPowernodeObjects do
        self.overviewPowernodeObjects[i]:SetVisible(false)
    end

    for i = 1, #self.overviewLocationObjects do
        self.overviewLocationObjects[i]:SetVisible(false)
    end

    for i = 1, #self.overviewResourceNodeObjects do
        self.overviewResourceNodeObjects[i]:SetVisible(false)
    end

    for i = 1, #self.overviewTechPointObjects do
        self.overviewTechPointObjects[i]:SetVisible(false)
    end

end

function GMTDMapOverviewWidget:OnLevelNameChanged(newLevelName)

    self:HideBlips()
    self.overviewTitle:SetText(Locale.ResolveString(GetMapTitleLocale(kThunderdomeMaps[newLevelName])))

    local isRandomizeButton = newLevelName == kThunderdomeMaps[kThunderdomeMaps.RANDOMIZE]
    if isRandomizeButton then
        self.overview:SetVisible(false)
        self.overviewResourceNodeLegendLabel:SetVisible(false)
        self.overviewTechPointLegendLabel:SetVisible(false)
    else

        self.overview:SetTexture("maps/overviews/" .. newLevelName .. ".tga")
        self.overview:SetVisible(true)

        self.overviewResourceNodeLegendLabel:SetVisible(true)
        self.overviewTechPointLegendLabel:SetVisible(true)

        self:UpdateGraphicalBlipType(kMinimapObjectType.TechPoint   , newLevelName)
        self:UpdateGraphicalBlipType(kMinimapObjectType.ResourceNode, newLevelName)
        --self:UpdateGraphicalBlipType(kMinimapObjectType.PowerPoint  , newLevelName)
        self:UpdateGraphicalBlipType(kMinimapObjectType.Location    , newLevelName)

    end

end

local function GetBlipColor(self, blipType, blipData)

    if blipType ~= kMinimapObjectType.TechPoint then
        return self.kOverviewBlipColor
    end

    -- Techpoints have specific color due to having a teamNumber that specifies which team can start at that tech point.
    local team = blipData.team
    if team == 0 then -- Either team random start
        return self.kTechPointColor_AnyTeam
    elseif team == 1 then -- Marines
        return self.kTechPointColor_Marines
    elseif team == 2 then -- Aliens
        return self.kTechPointColor_Aliens
    elseif team == 3 then -- No team can start here
        return self.kTechPointColor_Neither
    end

end

function GMTDMapOverviewWidget:UpdateGraphicalBlipType(blipType, tdMap)

    local objects
    local minimapData
    local tdMapIndex = kThunderdomeMaps[tdMap]

    if blipType == kMinimapObjectType.TechPoint then
        objects = self.overviewTechPointObjects
        minimapData = GetTDMinimapData_TechPoints(tdMapIndex)
    elseif blipType == kMinimapObjectType.ResourceNode then
        objects = self.overviewResourceNodeObjects
        minimapData = GetTDMinimapData_ResourcePoints(tdMapIndex)
    --[[
    elseif blipType == kMinimapObjectType.PowerPoint then
        objects = self.overviewPowernodeObjects
        minimapData = GetTDMinimapData_PowerPoints(tdMapIndex)
    --]]
    elseif blipType == kMinimapObjectType.Location then
        objects = self.overviewLocationObjects
        minimapData = GetTDMinimapData_Locations(tdMapIndex)
    end

    if not objects then
        SLog("[TD-UI] ERROR: Could not get object container from overview blip type!")
        return
    end

    if not minimapData then
        if tdMapIndex ~= kThunderdomeMaps.RANDOMIZE then
            SLog("[TD-UI] ERROR: Could not get minimap data for tdMapIndex: '%s'", tdMapIndex)
        end
        return -- Randomize doesnt have techpoints, etc, or the level is invalid.
    end

    local numMinimapData = #minimapData

    if blipType == kMinimapObjectType.ResourceNode then
        self.overviewResourceNodeLegendLabel:SetText(string.format("%s %s", numMinimapData, Locale.ResolveString("THUNDERDOME_RESOURCENODE_LEGEND_LABEL")))
    elseif blipType == kMinimapObjectType.TechPoint then
        self.overviewTechPointLegendLabel:SetText(string.format("%s %s", numMinimapData, Locale.ResolveString("THUNDERDOME_TECHPOINTLEGEND_LABEL")))
    end

    if blipType ~= kMinimapObjectType.Location then -- Graphical type minimap blips. (Textured)

        local blipAtlasPos = kMinimapObjectAtlasPositions[blipType]
        if not blipAtlasPos then
            SLog("[TD-UI] ERROR: Could not get atlas position of graphical blip type!")
            return
        end

        for i = 1, numMinimapData do

            local blipData = minimapData[i]

            -- Make sure we have a free object available
            local obj = objects[i]
            if not obj then
                obj = CreateGUIObject(string.format("%s_%s", kMinimapObjectType[blipType], i), GUIObject, self.overview)
                obj:SetTexture(kMinimapIconsTexture)
                obj:SetSize(kMinimapIconWidth, kMinimapIconHeight) -- Main menu is scaled at 4k, but original GUI is 1080...
                obj:SetTexturePixelCoordinates(GUIGetSprite(blipAtlasPos.x, blipAtlasPos.y, kMinimapIconWidth, kMinimapIconHeight)) -- GUIGetSprite Expects 1-based.
                obj:SetRotationOffset(0.5, 0.5)
                obj:AlignCenter()
                obj:SetLayer(self.kOverviewGraphicalLayer)
                table.insert(objects, obj)
            end

            local blipPosition = {}
            blipPosition.x = blipData.x * self.overview:GetSize().x
            blipPosition.y = blipData.y * self.overview:GetSize().y

            obj:SetColor(GetBlipColor(self, blipType, blipData))
            obj:SetPosition(blipPosition.x, blipPosition.y)
            obj:SetAngle(Math.Radians(blipData.angle))
            obj:SetVisible(true)

        end

    else -- Just Text Objects

        for i = 1, numMinimapData do

            local blipData = minimapData[i]

            -- Make sure we have a free object available
            local obj = objects[i]
            if not obj then
                obj = CreateGUIObject(string.format("%s_%s", kMinimapObjectType[blipType], i), GUIText, self.overview)
                obj:SetColor(1,1,1)
                obj:AlignCenter()
                obj:SetDropShadowEnabled(true)
                obj:SetLayer(self.kOverviewLocationLayer)
                table.insert(objects, obj)
            end

            local blipPosition = {}
            blipPosition.x = blipData.x * self.overview:GetSize().x
            blipPosition.y = blipData.y * self.overview:GetSize().y

            obj:SetFont("Agency", math.min(self.overview:GetSize().y * 0.04, kDefaultMapLocationFontSize))
            obj:SetPosition(blipPosition.x, blipPosition.y)
            obj:SetText(blipData.name)
            obj:SetVisible(true)

        end

    end

end
