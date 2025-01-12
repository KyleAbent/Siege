-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDVoteStatusWidget.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIText.lua")

class "GMTDVoteStatusWidget" (GUIObject)

GMTDVoteStatusWidget.kBackgroundTexture        = PrecacheAsset("ui/thunderdome/statusbar.dds")
GMTDVoteStatusWidget.kDefaultStatusTextColor   = ColorFrom255(170, 185, 190)
GMTDVoteStatusWidget.kDefaultVoteYesColor      = ColorFrom255( 72, 215,  43)
GMTDVoteStatusWidget.kDefaultVoteNoColor       = ColorFrom255(215,  52,  43)
GMTDVoteStatusWidget.kDefaultSize              = Vector(800, 70, 0)

local kPadding = 36
local kButtonFont = ReadOnly{ family="MicrogrammaBold", size=32 }

function GMTDVoteStatusWidget:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self:SetTexture(self.kBackgroundTexture)
    self:SetSize(self.kDefaultSize)
    self:SetColor(1,1,1)

    self.statusText = CreateGUIObject("statusText", GUIText, self, params, errorDepth)
    self.statusText:AlignLeft()
    self.statusText:SetFont(kButtonFont)
    self.statusText:SetColor(self.kDefaultStatusTextColor)
	self.statusText:SetX(kPadding)

	self.layout = CreateGUIObject("layout", GUIListLayout, self,
    {
        orientation = "horizontal",
        spacing = kPadding,
        align = "right",
    })
	self.layout:SetX(-kPadding)

	self.voteTimer = CreateGUIObject("voteTimer", GUIText, self.layout, params, errorDepth)
	self.voteTimer:SetFont("Microgramma", 32)
	self.voteTimer:SetColor(self.kDefaultStatusTextColor)

	self.voteYesButton = CreateGUIObject("voteYesText", GUIMenuSimpleTextButton, self.layout, {
		font = kButtonFont,
		text = Locale.ResolveString("YES"),
		defaultColor = self.kDefaultVoteYesColor
	})

	self.voteNoButton = CreateGUIObject("voteNoText", GUIMenuSimpleTextButton, self.layout, {
		font = kButtonFont,
		text = Locale.ResolveString("NO"),
		defaultColor = self.kDefaultVoteNoColor
	})

	self.castVoteText = CreateGUIObject("castVoteText", GUIText, self.layout, params, errorDepth)
	self.castVoteText:SetFont(kButtonFont)
	self.castVoteText:SetColor(self.kDefaultStatusTextColor)
	self.castVoteText:SetVisible(false)

	self:HookEvent(self.voteYesButton, "OnPressed", self.OnVoteYes)
	self:HookEvent(self.voteNoButton, "OnPressed", self.OnVoteNo)

	self.cachedVote = nil
end

-- Setup the UI for a vote kick
function GMTDVoteStatusWidget:StartNewVote(newVoteText)
	RequireType({"string"       }, newVoteText, "newVoteText")
	self.statusText:SetText(newVoteText)

	self:Reset()
	self:SetUpdates(true)
end

function GMTDVoteStatusWidget:EndVote()
	self.statusText:SetText("")

	self:Reset()
	self:SetUpdates(false)
end

function GMTDVoteStatusWidget:OnVoteYes()
	SLog("GMTDVoteStatusWidget:OnVoteYes()")

	if self.cachedVote == nil then
		self.cachedVote = true

		self.voteYesButton:SetVisible(false)
		self.voteNoButton:SetVisible(false)

		self.castVoteText:SetText(Locale.ResolveString("YES"))
		self.castVoteText:SetColor(self.kDefaultVoteYesColor)
		self.castVoteText:SetVisible(true)

		self:FireEvent("OnVoteCast", true)
	end
end

function GMTDVoteStatusWidget:OnVoteNo()
	SLog("GMTDVoteStatusWidget:OnVoteNo()")

	if self.cachedVote == nil then
		self.cachedVote = false

		self.voteYesButton:SetVisible(false)
		self.voteNoButton:SetVisible(false)

		self.castVoteText:SetText(Locale.ResolveString("NO"))
		self.castVoteText:SetColor(self.kDefaultVoteNoColor)
		self.castVoteText:SetVisible(true)

		self:FireEvent("OnVoteCast", false)
	end
end

function GMTDVoteStatusWidget:Reset()

	self.cachedVote = nil
	self.voteNoButton:SetVisible(true)
	self.voteYesButton:SetVisible(true)
	self.castVoteText:SetVisible(false)

end

function GMTDVoteStatusWidget:OnUpdate(deltaTime, time)
	local timestamp = Thunderdome():GetActiveKickVoteTimestamp()
	local remain = timestamp + kVoteKickDuration - Client.GetTdTimestamp()

	self.voteTimer:SetText(string.format("%ds", math.max(remain, 0)))
end
