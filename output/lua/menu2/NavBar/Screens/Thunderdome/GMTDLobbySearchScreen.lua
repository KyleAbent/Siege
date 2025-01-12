-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/NavBar/Screens/Thunderdome/GMTDLobbySearchScreen.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/widgets/Thunderdome/GMTDLoadingGraphic.lua")

---@class GMTDLobbySearchScreen : GUIObject
class "GMTDLobbySearchScreen" (GUIObject)

GMTDLobbySearchScreen.kLoadingGraphicTexture = PrecacheAsset("ui/thunderdome/search_loadingcircle.dds")

GMTDLobbySearchScreen.kLoadingGraphicStartHeight = 400

GMTDLobbySearchScreen.kStatusTextBackgroundStartHeight = 772
GMTDLobbySearchScreen.kStatusTextBackgroundColor = Color(0, 0, 0, 0.5)
GMTDLobbySearchScreen.kStatusTextBackgroundHeight = 140
GMTDLobbySearchScreen.kStatusTextBackgroundHorizontalPadding = 40

GMTDLobbySearchScreen.kResultTextOffset = 90
GMTDLobbySearchScreen.kResultTextColor = Color(0.8, 0.8, 0.8, 0.8)

function GMTDLobbySearchScreen:Reset()
    self.hiveDataFetched = false
    self.searching = false
    self.statusText:SetText(Locale.ResolveString("THUNDERDOME_FETCHING_HIVE_DATA"))
end

function GMTDLobbySearchScreen:OnSizeChanged(newSize)
    self.statusTextBackground:SetSize(self:GetSize().x - (self.kStatusTextBackgroundHorizontalPadding * 2), self.kStatusTextBackgroundHeight)
end

function GMTDLobbySearchScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.hiveDataFetched = false
    self.localTdDataLoaded = false
    self.searching = false

    self.loadingGraphic = CreateGUIObject("loadingGraphic", GMTDLoadingGraphic, self, {}, errorDepth)
    self.loadingGraphic:AlignTop()
    self.loadingGraphic:SetPosition(0, self.kLoadingGraphicStartHeight)

    self.statusTextBackground = CreateGUIObject("statusTextBackground", GUIObject, self, {}, errorDepth)
    self.statusTextBackground:SetColor(self.kStatusTextBackgroundColor)
    self.statusTextBackground:AlignTop()
    self.statusTextBackground:SetPosition(0, self.kStatusTextBackgroundStartHeight)
    self.statusTextBackground:SetSize(self:GetSize().x - (self.kStatusTextBackgroundHorizontalPadding * 2), self.kStatusTextBackgroundHeight)

    self.statusText = CreateGUIObject("statusText", GUIText, self.statusTextBackground, {}, errorDepth)
    self.statusText:AlignCenter()
    self.statusText:SetText(Locale.ResolveString("THUNDERDOME_LOADING_LOCAL_DATA"))
    GUIMakeFontScale(self.statusText, "kAgencyFB", 42)

    self.resultText = CreateGUIObject("resultText", GUIText, self.statusTextBackground, {
        font = ReadOnly{family = "Microgramma", size = 24}
    }, errorDepth)
    self.resultText:AlignCenter()
    self.resultText:SetPosition(0, self.kResultTextOffset)
    self.resultText:SetText("")
    self.resultText:SetColor(self.kResultTextColor)

    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)

    self.TD_HiveProfileFetchSuccess = function(clientModeObject)

        self.hiveDataFetched = true
        if self.searching and self.localTdDataLoaded then
            self:StartSearchingInternal()
        else
            self.statusText:SetText(Locale.ResolveString("THUNDERDOME_LOADING_LOCAL_DATA"))
        end

    end
    
    self.TD_LocalDataInitComplete = function(clientModeObject)

        self.localTdDataLoaded = true
        if self.searching and self.hiveDataFetched then
            self:StartSearchingInternal()
        else
            self.statusText:SetText(Locale.ResolveString("THUNDERDOME_FETCHING_HIVE_DATA"))
        end

    end

    self.TD_SearchResults = function(clientModeObject, numWaiting, numPlaying)

        if numWaiting == 0 and numPlaying == 0 then
            self.resultText:SetText("")
        else
            self.resultText:SetText(string.format(Locale.ResolveString("THUNDERDOME_LOBBY_RESULTS"), numWaiting, numPlaying))
        end

    end

    self:ListenForCursorInteractions()

end

function GMTDLobbySearchScreen:RegisterEvents()
    SLog("GMTDLobbySearchScreen:RegisterEvents()")
    Thunderdome_AddListener(kThunderdomeEvents.OnGUIHiveProfileFetchSuccess, self.TD_HiveProfileFetchSuccess)
    Thunderdome_AddListener(kThunderdomeEvents.OnGUISearchResults, self.TD_SearchResults)
    Thunderdome_AddListener(kThunderdomeEvents.OnLocalDataInitComplete, self.TD_LocalDataInitComplete)
end

function GMTDLobbySearchScreen:UnregisterEvents()
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUIHiveProfileFetchSuccess, self.TD_HiveProfileFetchSuccess)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnGUISearchResults, self.TD_SearchResults)
    Thunderdome_RemoveListener(kThunderdomeEvents.OnLocalDataInitComplete, self.TD_LocalDataInitComplete)
end

function GMTDLobbySearchScreen:StartSearchingInternal()

    self.statusText:SetText(Locale.ResolveString("THUNDERDOME_SEARCHING_FOR_LOBBY"))
    self.resultText:SetText("")

    local td = Thunderdome()
    if not td:GetIsSearching() and not td:GetIsConnectedToLobby() then
        local ok = Thunderdome():InitSearchMode()

        if not ok then
            -- Reset back to the selection screen
            GetThunderdomeMenu():Reset()
        end

        --TODO Trigger some text "animations" to UX-signal to user system is actively doing "stuff"
        --(simplest thing would be showing current number of attempts, and limiter thresholds, in addition to last search-run res list size)
    else
        SLog("[TD-UI] GMTDLobbySearchScreen - Could not start search. Searching: %s, Connected to Lobby: %s", td:GetIsSearching(), td:GetIsConnectedToLobby() )
    end

end

function GMTDLobbySearchScreen:StartSearching()

    self.searching = true
    self.hiveDataFetched = Thunderdome():HasValidHiveProfileData()
    self.localTdDataLoaded = Thunderdome():GetLocalDataInitialized()

    if self.hiveDataFetched and self.localTdDataLoaded then
        self:StartSearchingInternal()
    end

end

function GMTDLobbySearchScreen:Uninitialize()
    self:UnregisterEvents()
end
