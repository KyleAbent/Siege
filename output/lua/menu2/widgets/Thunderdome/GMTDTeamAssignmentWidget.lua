-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDTeamAssignmentWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIText.lua")

local kTeamAppearanceSettings =
{
    [kTeam1Index] =
    {
        Background = PrecacheAsset("ui/thunderdome/team_icon_background_marines.dds"),
        Icon       = PrecacheAsset("ui/thunderdome/team_icon_marines.dds"),
        TextColor  = ColorFrom255(64, 198, 232),
        TeamName   = "MARINE"
    },

    [kTeam2Index] =
    {
        Background  = PrecacheAsset("ui/thunderdome/team_icon_background_aliens.dds"),
        Icon        = PrecacheAsset("ui/thunderdome/team_icon_aliens.dds"),
        TextColor   = ColorFrom255(211, 159, 58),
        TeamName   = "ALIEN"
    }
}

local kFontName = "Agency"
local kFontSize = 53
local kPadding = -90

class "GMTDTeamAssignmentWidget" (GUIObject)

GMTDTeamAssignmentWidget:AddClassProperty("TeamIndex", kTeamInvalid)
GMTDTeamAssignmentWidget:AddClassProperty("TeamOrder", 0)

function GMTDTeamAssignmentWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.topText = CreateGUIObject("topText", GUIText, self)
    self.topText:SetFont(kFontName, kFontSize)
    self.topText:AlignTop()
    self.topText:SetLayer(2)

    self.backgroundBloom = CreateGUIObject("backgroundBloom", GUIObject, self)
    self.backgroundBloom:SetColor(1,1,1)
    self.backgroundBloom:AlignTop()
    self.backgroundBloom:SetLayer(0)

    self.teamIcon = CreateGUIObject("teamIcon", GUIObject, self.backgroundBloom)
    self.teamIcon:SetColor(1,1,1)
    self.teamIcon:AlignCenter()
    self.teamIcon:SetLayer(1)

    self.bottomText = CreateGUIObject("bottomText", GUIText, self)
    self.bottomText:SetFont(kFontName, kFontSize)
    self.bottomText:AlignTop()
    self.bottomText:SetLayer(2)

    self:HookEvent(self, "OnTeamIndexChanged", self.UpdateAppearance)
    self:HookEvent(self, "OnTeamOrderChanged", self.UpdateAppearance)

end

function GMTDTeamAssignmentWidget:SetTeamAndOrder(teamIndex, teamOrder)
    self:SetTeamIndex(teamIndex)
    self:SetTeamOrder(teamOrder)
end

function GMTDTeamAssignmentWidget:UpdateAppearance()

    local teamOrder = self:GetTeamOrder()
    local teamIndex = self:GetTeamIndex()
    local settings = kTeamAppearanceSettings[teamIndex]

    if not settings then
        return
    end

    if teamOrder ~= 1 and teamOrder ~= 2 then
        return
    end

    local yPos = 0

    local topText = ConditionalValue(teamOrder == 1, "THUNDERDOME_FIRST_ROUND", "THUNDERDOME_SECOND_ROUND")
    self.topText:SetText(string.format("%s%s", Locale.ResolveString(topText), ":"))
    self.topText:SetColor(settings.TextColor)
    self.topText:SetY(yPos)

    yPos = yPos + kPadding + self.topText:GetSize().y
    self.backgroundBloom:SetTexture(settings.Background)
    self.backgroundBloom:SetSizeFromTexture()
    self.backgroundBloom:SetY(yPos)

    self.teamIcon:SetTexture(settings.Icon)
    self.teamIcon:SetSizeFromTexture()

    yPos = yPos + kPadding + self.backgroundBloom:GetSize().y
    self.bottomText:SetText(Locale.ResolveString(settings.TeamName))
    self.bottomText:SetColor(settings.TextColor)
    self.bottomText:SetY(yPos)

    self:SetSize(math.max(self.topText:GetSize().x, self.backgroundBloom:GetSize().x, self.teamIcon:GetSize().x, self.bottomText:GetSize().x), yPos + self.bottomText:GetSize().y)

end
