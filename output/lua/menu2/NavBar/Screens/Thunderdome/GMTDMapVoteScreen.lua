-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/NavBar/Screens/Thunderdome/GMTDMapVoteScreen.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu2/widgets/GMTDMapVoteButton.lua")
Script.Load("lua/menu2/widgets/GUIMenuScrollPane.lua")
Script.Load("lua/GUI/layouts/GUIColumnLayout.lua")
Script.Load("lua/IterableDict.lua")
Script.Load("lua/menu2/NavBar/Screens/Thunderdome/MinimapData.lua")
Script.Load("lua/menu2/widgets/Thunderdome/GMTDMapVoteDetailsWidget.lua")

local kStatusBarPaddingX = 25
local kStausBarPaddingY = 26

class "GMTDMapVoteScreen" (GUIObject)

function GMTDMapVoteScreen:Reset()

    self.numVotes = 0
    self.votedButtons = {}
    self.votedButtonsDict:Clear()

    self.overview:Reset()

    for i = 1, #self.voteButtons do
        self.voteButtons[i]:Reset()
    end

end

function GMTDMapVoteScreen:GetStatusBar()
    return self.statusBar
end

function GMTDMapVoteScreen:OnSizeChanged()

    local size = self:GetSize()

    self.statusBar:SetWidth(size.x - (kStatusBarPaddingX * 2))

    local buttonContainerWidth = 1290
    local buttonContainerHeight = 1375 - self.statusBar:GetSize().y - kStausBarPaddingY
    local padding = 30

    self.voteButtonsScrollPane:SetSize(buttonContainerWidth, buttonContainerHeight)
    self.voteButtonsLayout:SetSize(buttonContainerWidth - self.voteButtonsScrollPane:GetScrollBarThickness() - padding, self.voteButtonsLayout:GetSize().y)
    self.voteButtonsScrollPane:SetPaneSize(self.voteButtonsLayout:GetSize() + Vector(0, 10, 0))

    local overviewFrameStartX = self.voteButtonsScrollPane:GetPosition().x + self.voteButtonsScrollPane:GetSize().x + padding

    self.overview:SetPosition(overviewFrameStartX, 115)
    self.overview:SetSize(size.x - overviewFrameStartX - padding, buttonContainerHeight)

end

function GMTDMapVoteScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.numVotes = 0
    self.votedButtons = {} -- Sparse array of voted map buttons. Index is the vote rank.
    self.votedButtonsDict = IterableDict()

    self.description = CreateGUIObject("mapSelectText", GUIStyledText, self, params, errorDepth)
    self.description:SetStyle(MenuStyle.kThunderdomePlayerNameLabel)
    self.description:SetText(Locale.ResolveString("THUNDERDOME_MAPSELECTIONTITLE"))
    self.description:SetPosition(40, 8)
    self.description:SetFont("AgencyBold", 60)

    self.overview = CreateGUIObject("overview", GMTDMapVoteDetailsWidget, self)

    self.voteButtonsScrollPane = CreateGUIObject("mapButtonsScrollPane", GUIMenuScrollPane, self, { horizontalScrollBarEnabled = false }, errorDepth)
    self.voteButtonsScrollPane:SetPosition(25, 115)

    self.voteButtonsLayout = CreateGUIObject("mapButtonsLayout", GUIColumnLayout, self.voteButtonsScrollPane, params, errorDepth)
    self.voteButtonsLayout:SetColumnSpacing(17)
    self.voteButtonsLayout:SetSpacing(15)

    self.statusBar = CreateGUIObject("statusBar", GMTDScreenStatusWidget, self, params, errorDepth)
    self.statusBar:SetY(-kStausBarPaddingY)
    self.statusBar:AlignBottom()

    self.voteButtons = {}

    self:InitializeVoteButtons(errorDepth)

    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)
    self:HookEvent(self.overview, "OnMapVotesConfirmed", self.OnMapVotesConfirmed)

    self:OnSizeChanged()

end

function GMTDMapVoteScreen:RegisterEvents()

end

function GMTDMapVoteScreen:UnregisterEvents()

end

function GMTDMapVoteScreen:Uninitialize()
    self:UnregisterEvents()
end

function GMTDMapVoteScreen:OnMapVotesConfirmed()

    -- Should no longer be sparse here.
    assert(self.numVotes == #self.votedButtons)

    -- Should have at least one vote.
    if #self.votedButtons <= 0 then
        return
    end

    -- Lock all of the buttons that were not voted for.
    for i = 1, #self.voteButtons do

        local button = self.voteButtons[i]
        if self.votedButtonsDict[button:GetLevelName()] then
            button:SetVoted()
        else
            button:SetLocked()
        end

    end

    -- Prepare map votes for sending to thunderdome manager.
    local votedMapNames = {}
    for i = 1, #self.votedButtons do
        table.insert(votedMapNames, self.votedButtons[i]:GetLevelName())
    end

    Thunderdome():SetLocalMapVotes(votedMapNames)
    self.overview:Lock()

    PlayMenuSound("ButtonClick")

    self:FireEvent("OnMapVotesConfirmed", votedMapNames)

end

function GMTDMapVoteScreen:OnMapVoteSelected(button)

    local buttonLevelName = button:GetLevelName()
    local mapVoteIndex = self.votedButtonsDict[buttonLevelName]

    -- Ignore duplicate map vote selections.
    if mapVoteIndex then
        return
    end

    -- Ignore map vote selection if already at max votes allowed.
    if self.numVotes >= kMaxMapVoteCount then
        return
    end

    -- Go ahead and throw it in.
    self.numVotes = self.numVotes + 1
    button:SetSelected(self.numVotes)
    self.votedButtons[self.numVotes] = button
    self.votedButtonsDict[button:GetLevelName()] = self.numVotes

end

function GMTDMapVoteScreen:OnMapVoteUndo(button)

    local buttonVoteRank = button:GetVoteRank()
    button:Reset()

    self.votedButtons[buttonVoteRank] = nil
    self.numVotes = self.numVotes - 1

    -- Make sure our votes are not sparse.
    self.votedButtonsDict:Clear()

    local contiguousVoteRank = 1
    for i = 1, kMaxMapVoteCount do

        local voteButton = self.votedButtons[i]
        if voteButton then

            voteButton:SetSelected(contiguousVoteRank)
            self.votedButtonsDict[voteButton:GetLevelName()] = contiguousVoteRank

            if i ~= contiguousVoteRank then
                self.votedButtons[contiguousVoteRank] = voteButton
                self.votedButtons[i] = nil
            end

            contiguousVoteRank = contiguousVoteRank + 1

        end

    end

end

function GMTDMapVoteScreen:OnMapVoteButtonMouseOver(button)

    local levelName = button:GetLevelName()
    if button:GetMouseOver() then
        self.overview:SetLevelName(levelName)
    end

end

function GMTDMapVoteScreen:InitializeVoteButtons(errorDepth)

    local thunderDomeMaps = {}
    table.copy(kThunderdomeMaps, thunderDomeMaps, false)

    -- We want the randomize button to be first.
    table.removevalue(thunderDomeMaps, kThunderdomeMaps[kThunderdomeMaps.RANDOMIZE])
    local randomizedLevelNames = table.shuffle(thunderDomeMaps)
    table.insert(randomizedLevelNames, 1, kThunderdomeMaps[kThunderdomeMaps.RANDOMIZE])

    for i = 1, #randomizedLevelNames do

        local button = CreateGUIObject(string.format("mapVoteButton_%s", randomizedLevelNames[i]), GMTDMapVoteButton, self.voteButtonsLayout, { levelName = randomizedLevelNames[i] }, errorDepth)
        self:HookEvent(button, "OnMapVoteSelected", self.OnMapVoteSelected)
        self:HookEvent(button, "OnMapVoteUndo", self.OnMapVoteUndo)
        self:HookEvent(button, "OnMapVoteButtonMouseOver", self.OnMapVoteButtonMouseOver)

        table.insert(self.voteButtons, button)

    end

end
