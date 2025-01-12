-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDGoToMapVoteScreenButton.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIParagraph.lua")
Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/menu2/MenuStyles.lua")

class "GMTDGoToMapVoteScreenButton" (GUIObject)

GMTDGoToMapVoteScreenButton.kMapButtonTexture       = PrecacheAsset("ui/thunderdome/lobby_vote_background.dds")
GMTDGoToMapVoteScreenButton.kMapButtonFrameTexture  = PrecacheAsset("ui/thunderdome/lobby_vote_frame.dds")
GMTDGoToMapVoteScreenButton.kVotedCheckTexture      = PrecacheAsset("ui/thunderdome/mapvote_checkmark.dds")

GMTDGoToMapVoteScreenButton.kLabelFontColor_UnVoted = ColorFrom255(139, 144, 146)
GMTDGoToMapVoteScreenButton.kLabelFontColor_Voted   = ColorFrom255(219, 219, 219)

GMTDGoToMapVoteScreenButton.kMapAtlasTexture        = PrecacheAsset("ui/thunderdome/mapvote_mapimages.dds")
GMTDGoToMapVoteScreenButton.kMapShader_2            = PrecacheAsset("shaders/GUI/menu/tdGoToVoteScreenButton_2.surface_shader")
GMTDGoToMapVoteScreenButton.kMapShader_3            = PrecacheAsset("shaders/GUI/menu/tdGoToVoteScreenButton_3.surface_shader")

function GMTDGoToMapVoteScreenButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.voteForMapButton = CreateGUIObject("mapVoteButton", GUIButton, self, params, errorDepth)
    self.voteForMapButton:SetTexture(self.kMapButtonTexture)
    self.voteForMapButton:SetColor(1,1,1)
    self.voteForMapButton:SetSizeFromTexture()

    self.voteButtonFrame = CreateGUIObject("voteButtonFrame", GUIObject, self.voteForMapButton, params, errorDepth)
    self.voteButtonFrame:SetTexture(self.kMapButtonFrameTexture)
    self.voteButtonFrame:SetSizeFromTexture()
    self.voteButtonFrame:SetColor(1,1,1)
    self.voteButtonFrame:AlignCenter()

    self.voteButtonText = CreateGUIObject("mapVoteButtonText", GUIParagraph, self.voteForMapButton, params, errorDepth)
    self.voteButtonText:AlignCenter()
    self.voteButtonText:SetFont("AgencyBold", 40)
    self.voteButtonText:SetColor(self.kLabelFontColor_UnVoted)
    self.voteButtonText:SetText(Locale.ResolveString("THUNDERDOME_VOTEFORMAP"))
    self.voteButtonText:SetDropShadowEnabled(true)
    self.voteButtonText:SetJustification(GUIItem.Align_Center)
    self.voteButtonText:SetParagraphSize(self.voteForMapButton:GetSize().x * 0.5, self.voteForMapButton:GetSize().y * 0.8)

    self.votedCheck = CreateGUIObject("votedCheck", GUIObject, self.voteButtonText)
    self.votedCheck:SetTexture(self.kVotedCheckTexture)
    self.votedCheck:SetSizeFromTexture()
    self.votedCheck:AlignLeft()
    self.votedCheck:SetX(-self.votedCheck:GetSize().x)
    self.votedCheck:SetColor(1,1,1)
    self.votedCheck:SetVisible(false)

    self:SetSize(self.voteButtonFrame:GetSize())

    self:ForwardEvent(self.voteForMapButton, "OnPressed", "OnShowMapVoteScreen")

    self.TDOnLobbyJoined = function(clientModeObj)
        self.voteButtonText:AnimateProperty("Opacity", nil, MenuAnimations.TDPulseOpacity)
        self.voteButtonText:SetText(Locale.ResolveString("THUNDERDOME_VOTEFORMAP"))
        self.votedCheck:SetVisible(false)
    end

    Thunderdome_AddListener(kThunderdomeEvents.OnGUILobbyJoined, self.TDOnLobbyJoined)

end

function GMTDGoToMapVoteScreenButton:Reset()

    self.voteForMapButton:SetShader("shaders/GUIBasic.surface_shader")
    self.voteForMapButton:SetTexture(self.kMapButtonTexture)
    self.voteForMapButton:SetTextureCoordinates(0, 0, 1, 1)

    self.voteButtonText:ClearPropertyAnimations("Opacity")
    self.voteButtonText:SetColor(self.kLabelFontColor_UnVoted)
    self.voteButtonText:SetText(Locale.ResolveString("THUNDERDOME_VOTEFORMAP"))
    self.votedCheck:SetVisible(false)

end
-- shaders/GUIBasic.surface_shader
function GMTDGoToMapVoteScreenButton:OnMapVotesConfirmed(votedMapNames)

    self.voteForMapButton:SetTexture(self.kMapAtlasTexture)
    local slope = math.tan(1.48353)

    local numVotedMaps = #votedMapNames
    if numVotedMaps == 1 then

        self.voteForMapButton:SetShader("shaders/GUIBasic.surface_shader")
        self.voteForMapButton:SetTexturePixelCoordinates(GetMapBackgroundPixelCoordinates(kThunderdomeMaps[votedMapNames[1]]))

    elseif numVotedMaps == 2 then

        self.voteForMapButton:SetShader(self.kMapShader_2)

        local leftIndexTable = GetMapBackgroundTextureAtlas(kThunderdomeMaps[votedMapNames[1]])
        local leftIndexVec = Vector(leftIndexTable[1], leftIndexTable[2], 0)
        self.voteForMapButton:SetFloat2Parameter("leftTextureIndex",   leftIndexVec)

        local middleIndexTable = GetMapBackgroundTextureAtlas(kThunderdomeMaps[votedMapNames[2]])
        local middleIndexVec = Vector(middleIndexTable[1], middleIndexTable[2], 0)
        self.voteForMapButton:SetFloat2Parameter("middleTextureIndex", middleIndexVec)

        self.voteForMapButton:SetFloatParameter("slope", slope)

    elseif numVotedMaps == 3 then

        self.voteForMapButton:SetShader(self.kMapShader_3)

        local leftIndexTable = GetMapBackgroundTextureAtlas(kThunderdomeMaps[votedMapNames[1]])
        local leftIndexVec = Vector(leftIndexTable[1], leftIndexTable[2], 0)
        self.voteForMapButton:SetFloat2Parameter("leftTextureIndex",   leftIndexVec)

        local middleIndexTable = GetMapBackgroundTextureAtlas(kThunderdomeMaps[votedMapNames[2]])
        local middleIndexVec = Vector(middleIndexTable[1], middleIndexTable[2], 0)
        self.voteForMapButton:SetFloat2Parameter("middleTextureIndex", middleIndexVec)

        local rightIndexTable = GetMapBackgroundTextureAtlas(kThunderdomeMaps[votedMapNames[3]])
        local rightIndexVec = Vector(rightIndexTable[1], rightIndexTable[2], 0)
        self.voteForMapButton:SetFloat2Parameter("rightTextureIndex",  rightIndexVec)

        self.voteForMapButton:SetFloatParameter("slope", slope)

    end

    self.voteButtonText:ClearPropertyAnimations("Opacity")
    self.voteButtonText:SetColor(self.kLabelFontColor_Voted)
    self.voteButtonText:SetText(Locale.ResolveString("THUNDERDOME_MAPSELECTION_CONFIRM_BUTTON_LOCKED"))
    self.votedCheck:SetVisible(true)
end

function GMTDGoToMapVoteScreenButton:Uninitialize()
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUILobbyJoined, self.TDOnLobbyJoined)
end