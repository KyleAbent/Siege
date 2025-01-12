-- ======= Copyright (c) 2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/NavBar/Screens/Thunderdome/GMTDSelectionScreen.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- Events
--        OnMapVoteButtonPressed - Just the "OnPressed" event from GUIButton. Fires when the map vote button is pressed.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/UnorderedSet.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GUISelectionList.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GUISelectionScreenButton.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDLoadingGraphic.lua")


local kPadding = 36
local kListPadding = 110 + kPadding

local kBgPaddingX = 2
local kBgPaddingY = 3

local kInngerBgSize = Vector( 1680, 1000, 0 )
local kInnerBgPadding = 50

local kOuterBg = PrecacheAsset("ui/thunderdome/selectscreen_outer_bg.dds")
local kInnerBg = PrecacheAsset("ui/thunderdome/selectscreen_inner_bg.dds")

local kSearchBtnIcon = PrecacheAsset("ui/thunderdome/selectscreen_search_icon.dds")
local kSearchBtnIconActive = PrecacheAsset("ui/thunderdome/selectscreen_search_icon_active.dds")

local kGroupBtnIcon = PrecacheAsset("ui/thunderdome/selectscreen_group_icon.dds")
local kGroupBtnIconActive = PrecacheAsset("ui/thunderdome/selectscreen_group_icon_active.dds")

local kPrivateBtnIcon = PrecacheAsset("ui/thunderdome/selectscreen_private_icon.dds")
local kPrivateBtnIconActive = PrecacheAsset("ui/thunderdome/selectscreen_private_icon_active.dds")

local kButtonsIconSize = Vector( 200, 200, 0 )
local kButtonSize = Vector( 235, 420, 0 )
local kButtonListSpacing = 150

local kLoadingGraphicStartHeight = 440

class "GMTDSelectionScreen" (GUIObject)


function GMTDSelectionScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.outerBg = CreateGUIObject("outerBg", GUIGraphic, self)
    self.outerBg:AlignTopLeft()
    self.outerBg:SetSize( self:GetSize() )    --Vector( 2520, 1332, 0 )
    self.outerBg:SetTexture( kOuterBg )
    self.outerBg:SetColor( Color(1,1,1,0.4) )

    self.innerBg = CreateGUIObject("outerBg", GUIGraphic, self)   --TODO Need (re)size update
    self.innerBg:AlignCenter()
    self.innerBg:SetTexture( kInnerBg )
    self.innerBg:SetSize( kInngerBgSize )
    self.innerBg:SetPosition( 0, -110 )
    self.innerBg:SetColor( Color(1,1,1,0.365) )

    self.titleText = CreateGUIObject("titleText", GUIText, self, nil, errorDepth)
    self.titleText:SetFont("AgencyBold", 80)
    self.titleText:AlignCenter()
    self.titleText:SetPosition(0, -390)
    self.titleText:SetText("MATCHED PLAY")

    self.modeTipText = CreateGUIObject("modeTipText", GUIText, self, nil, errorDepth)
    self.modeTipText:SetFont("Agency", 44)
    self.modeTipText:AlignBottom()
    self.modeTipText:SetPosition(0, -150)
    self.modeTipText:SetText("")    --meant to be blank

    self.loadingGraphic = CreateGUIObject("loadingGraphic", GMTDLoadingGraphic, self, {}, errorDepth)
    self.loadingGraphic:AlignTop()
    self.loadingGraphic:SetPosition(0, kLoadingGraphicStartHeight)

    self.loadingText = CreateGUIObject("loadingText", GUIText, self.innerBg, {}, errorDepth)
    self.loadingText:AlignBottom()
    self.loadingText:SetPosition(0, -170)
    self.loadingText:SetText(Locale.ResolveString("THUNDERDOME_LOADING_LOCAL_DATA"))
    GUIMakeFontScale(self.loadingText, "kAgencyFB", 42)
    
    self.actionsList = CreateGUIObject("actionsList", GUISelectionList, self, 
        {
            orientation = "horizontal",
            buttonSpacing = kButtonListSpacing
        }, errorDepth)
    self.actionsList:AlignCenter()
    self.actionsList:SetPosition( 0, -90 )
    self.actionsList:SetSize( kInngerBgSize - kInngerBgSize*0.285 )
    self.actionsList:SetVisible(false)
    
    self.searchBtn = CreateGUIObject("searchButton", GUISelectionScreenButton, self.actionsList, 
        { 
            label = Locale.ResolveString("THUNDERDOME_SELECT_SEARCH"),
            icon = kSearchBtnIcon,
            activeIcon = kSearchBtnIconActive,
            iconSize = kButtonsIconSize,
            buttonSize = kButtonSize,
            modeFlag = GUISelectionScreenButton.kButtonTypes.Search
        },     
        errorDepth)
    self.searchBtn:AlignCenter()
    self.searchBtn:SetPressedCallback( 
        function(_self)
            if Client.GetIsThunderdomePenalized() then
                Thunderdome():TriggerEvent( kThunderdomeEvents.OnGUIPenaltyIsActive )
            else
                GetThunderdomeMenu():ShowSearchScreen()
            end
        end
    )

    self.groupBtn = CreateGUIObject("groupButton", GUISelectionScreenButton, self.actionsList, 
        { 
            label = Locale.ResolveString("THUNDERDOME_SELECT_GROUP"),
            icon = kGroupBtnIcon,
            activeIcon = kGroupBtnIconActive,
            iconSize = kButtonsIconSize,
            buttonSize = kButtonSize,
            modeFlag = GUISelectionScreenButton.kButtonTypes.Group
         }, errorDepth)
    self.groupBtn:AlignCenter()
    self.groupBtn:SetPressedCallback( 
        function(_self)
            if Thunderdome():CreateGroup() then
                GetThunderdomeMenu():ShowScreen(kThunderdomeScreen.Group)
            end
        end
    )
    
    self.privateBtn = CreateGUIObject("privateButton", GUISelectionScreenButton, self.actionsList, 
        { 
            label = Locale.ResolveString("THUNDERDOME_SELECT_PRIVATE"),
            icon = kPrivateBtnIcon,
            activeIcon = kPrivateBtnIconActive,
            iconSize = kButtonsIconSize,
            buttonSize = kButtonSize,
            modeFlag = GUISelectionScreenButton.kButtonTypes.Private
        }, errorDepth)
    self.privateBtn:AlignCenter()
    self.privateBtn:SetPressedCallback( 
        function(_self)
            if Thunderdome():CreatePrivateLobby() then
                GetThunderdomeMenu():ShowScreen(kThunderdomeScreen.Lobby)
            end
        end
    )

    self:ListenForCursorInteractions()

    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)
    self:HookEvent(self, "OnShow", self.Reset)
    self:SetUpdates(true)

end

function GMTDSelectionScreen:RegisterEvents()
end

function GMTDSelectionScreen:UnregisterEvents()
end

function GMTDSelectionScreen:GetStatusBar()
    return self.statusBar
end

function GMTDSelectionScreen:OnSizeChanged(newSize)    
    local outerSize = self:GetSize()
    self.outerBg:SetSize( Vector( outerSize.x - kBgPaddingX*2, outerSize.y - kBgPaddingY*2, 0 ) )
    self.outerBg:SetPosition( kBgPaddingX, kBgPaddingY )

    local innerSize = self.innerBg:GetSize()
    self.actionsList:SetSize( innerSize - kInnerBgPadding*2 )
    self.actionsList:ArrangeNow()
end

function GMTDSelectionScreen:Uninitialize()

end

function GMTDSelectionScreen:ToggleLoadingMode(enabled)
    self.loadingGraphic:SetVisible(enabled)
    self.loadingText:SetVisible(enabled)
    self.actionsList:SetVisible(not enabled)
    self.modeTipText:SetVisible(not enabled)
end

function GMTDSelectionScreen:Reset()
    Log("GMTDSelectionScreen:Reset()")

    self.searchBtn:SetDisabled(Client.GetIsThunderdomePenalized())
    self.groupBtn:SetDisabled(Client.GetIsThunderdomePenalized())
    self:ToggleLoadingMode(not Thunderdome():HasValidHiveProfileData())
end

function GMTDSelectionScreen:OnUpdate(dT, now)
    if Thunderdome():HasValidHiveProfileData() then
        self:ToggleLoadingMode(false)
        self:SetUpdates(false)
    end
end
