-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\menu\GUIMainMenu_WelcomeProgress.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/menu/GUIMainMenu_ProgressEntry.lua")

class 'GUIWelcomeProgress' (MenuElement)

local entryData = {
	{
		title = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_1_TITLE"),
		achievement = "First_0_1",
		description = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_1_TEXT"),
		onClick = function()
			local guiMainMenu = GetGUIMainMenu()
			if not guiMainMenu.trainingWindow then
				guiMainMenu:CreateTrainingWindow()
			end
			guiMainMenu:TriggerOpenAnimation(guiMainMenu.trainingWindow)
			guiMainMenu:HideMenu()
		end
	},
	{
		title = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_2_TITLE"),
		achievement = "First_0_2",
		description = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_2_TEXT"),
		onClick = function()
			local guiMainMenu = GetGUIMainMenu()
			guiMainMenu:DoQuickJoin()
		end
	},
	{
		title = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_3_TITLE"),
		achievement = "First_0_3",
		description = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_3_TEXT"),
		onClick = function()
			local guiMainMenu = GetGUIMainMenu()
			guiMainMenu:DoQuickJoin()
		end
	},
	{
		title = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_4_TITLE"),
		achievement = "First_0_4",
		description = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_4_TEXT"),
		onClick = function()
			local guiMainMenu = GetGUIMainMenu()
			guiMainMenu:DoQuickJoin()
		end
	},
	{
		title = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_5_TITLE"),
		achievement = "First_0_5",
		description = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_5_TEXT"),
		onClick = function()
			local guiMainMenu = GetGUIMainMenu()
			guiMainMenu:DoQuickJoin()
		end
	},
	{
		title = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_6_TITLE"),
		description = Locale.ResolveString("WELCOME_PROGRESS_ENTRY_6_TEXT"),
		icon = "ui/progress/skulk.dds",
		static = true
	}
}

function GUIWelcomeProgress:Initialize()
	MenuElement.Initialize(self)

	self.mainFrame = CreateMenuElement(self, "Image");
	self.mainFrame:SetCSSClass("main_frame")

	self.welcomeHeader = CreateMenuElement(self.mainFrame, "Font")
	self.welcomeHeader:SetCSSClass("header")
	self.welcomeHeader:SetText(Locale.ResolveString("WELCOME_PROGRESS_HEAD"))

	self.welcomeText = CreateMenuElement(self.mainFrame, "Font")
	self.welcomeText:SetCSSClass("text")
	self.welcomeText:SetText(Locale.ResolveString("WELCOME_PROGRESS_TEXT"))

	self.entries = {}

	local finished = true
	for i, data in ipairs(entryData) do
		self.entries[i] = CreateMenuElement(self.mainFrame, "GUIProgressEntry")

		if not self.entries[i]:Setup(data) and finished then
			self.entries[i]:Highlight()
			finished = false
		end

		self.entries[i]:SetTopOffset(i * 110)
	end

	if finished and not Client.GetAchievement("First_1_0") and not GetOwnsItem(906) then
		Client.SetAchievement("First_1_0")
		Client.GrantPromoItems()
        InventoryNewItemNotifyPush( 906 )
	end
end

function GUIWelcomeProgress:Hide()
	self:SetIsVisible(false)

	MainMenu_OnHideProgress()

	self.hide = true
end

function GUIWelcomeProgress:Show()
	self.hide = false
	self:SetIsVisible(true)
end

function GUIWelcomeProgress:SetIsVisible(visible)
	if self.hide then return end

	MenuElement.SetIsVisible(self, visible)
end

function GUIWelcomeProgress:Update(deltaTime)
	for _, entry in ipairs(self.entries) do
		entry:Update(deltaTime)
	end
end

function GUIWelcomeProgress:GetTagName()
	return "progress"
end

local function OnCommandShowWelcomeProgress(enabled)

	local guiMainMenu = GetGUIMainMenu()

	if guiMainMenu and guiMainMenu.newsScript then
		if not guiMainMenu.progress then
			guiMainMenu.progress = CreateMenuElement(guiMainMenu.mainWindow, "GUIWelcomeProgress")
			guiMainMenu.progress:Hide()
		end

		enabled = enabled == nil and not guiMainMenu.progress:GetIsVisible() or string.ToBoolean(enabled)

		if enabled then
			guiMainMenu.newsScript:HideNews()
			guiMainMenu.progress:Show()
		else
			guiMainMenu.progress:Hide()
			guiMainMenu.newsScript:ShowNews()
		end

	end
end

Event.Hook("Console_showwelcomemenu", OnCommandShowWelcomeProgress)