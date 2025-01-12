-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/NavBar/Screens/Thunderdome/GMTDPlanningSplashScreen.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIText.lua")

local baseClass = GUIObject
class "GMTDPlanningSplashScreen" (baseClass)

GMTDPlanningSplashScreen.kTopTextColor = HexToColor("e1f9fb")
GMTDPlanningSplashScreen.kBottomTextColor_Aliens = HexToColor("d39f3a")
GMTDPlanningSplashScreen.kBottomTextColor_Marine = HexToColor("40c6e8")

GMTDPlanningSplashScreen.kFirstRoundLocale = "THUNDERDOME_FIRST_ROUND"
GMTDPlanningSplashScreen.kMarinesLocale = "THUNDERDOME_TEAM_MARINES"
GMTDPlanningSplashScreen.kAliensLocale = "THUNDERDOME_TEAM_ALIENS"

GMTDPlanningSplashScreen.kBackgroundTexture = PrecacheAsset("ui/thunderdome/planning_splash_frame.dds")
GMTDPlanningSplashScreen.kAlienLogo = PrecacheAsset("ui/thunderdome/planning_splash_alien_logo.dds")
GMTDPlanningSplashScreen.kMarineLogo = PrecacheAsset("ui/thunderdome/planning_splash_marines_logo.dds")

GMTDPlanningSplashScreen:AddClassProperty("StartingRoundTeam", kTeamInvalid)

function GMTDPlanningSplashScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:SetTexture(self.kBackgroundTexture) -- TODO(Salads): Art has this as a complete background, need just the frame with transparency (that's why its invisible for now)

    self.teamLogo = CreateGUIObject("logo", GUIObject, self)
    self.teamLogo:AlignCenter()
    self.teamLogo:SetColor(1,1,1)

    self.firstRoundText = CreateGUIObject("topText", GUIText, self.teamLogo)
    self.firstRoundText:SetFont("Agency", 100)
    self.firstRoundText:SetText(Locale.ResolveString(self.kFirstRoundLocale))
    self.firstRoundText:SetColor(self.kTopTextColor)
    self.firstRoundText:AlignTop()

    self.bottomTeamText = CreateGUIObject("bottomText", GUIText, self.teamLogo)
    self.bottomTeamText:SetFont("Agency", 100)
    self.bottomTeamText:AlignBottom()


    self:HookEvent(self, "OnStartingRoundTeamChanged", self.OnStartingRoundTeamChanged)
end

function GMTDPlanningSplashScreen:RegisterEvents()
end

function GMTDPlanningSplashScreen:UnregisterEvents()
end

function GMTDPlanningSplashScreen:OnStartingRoundTeamChanged(newTeam)

    if newTeam == kTeam1Index then

        self.teamLogo:SetTexture(self.kMarineLogo)
        self.teamLogo:SetSizeFromTexture()
        self.bottomTeamText:SetText(Locale.ResolveString(self.kMarinesLocale))
        self.bottomTeamText:SetColor(self.kBottomTextColor_Marine)

    elseif newTeam == kTeam2Index then

        self.teamLogo:SetTexture(self.kAlienLogo)
        self.teamLogo:SetSizeFromTexture()
        self.bottomTeamText:SetText(Locale.ResolveString(self.kAliensLocale))
        self.bottomTeamText:SetColor(self.kBottomTextColor_Aliens)

    else
        SLog("[TD-UI] ERROR: GMTDPlanningSplashScreen:OnStartingRoundTeamChanged - Invalid team '%s'", newTeam)
        return
    end

end
