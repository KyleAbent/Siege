-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/GUI/Debug/GUIBuildTimes.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- Displays timing information for the last/current build session. (Marines only)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")

local baseClass = GUIObject
class "GUIBuildTimes" (baseClass)

function GUIBuildTimes:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    baseClass.Initialize(self, params, errorDepth)
    
    self.layout = CreateGUIObject("layout", GUIListLayout, self, {
        orientation = "vertical",
    })
    
    self.classNameText = CreateGUIObject("classname", GUIText, self.layout, {
        font = MenuStyle.kTooltipFont
    }, errorDepth)

    self.buildTimeText = CreateGUIObject("buildtime", GUIText, self.layout, {
        font = MenuStyle.kTooltipFont
    }, errorDepth)

    self.expectedTimeText = CreateGUIObject("expectedTime", GUIText, self.layout, {
        font = MenuStyle.kTooltipFont
    }, errorDepth)
    
    self:AlignTop()
    self:SetY(Client.GetScreenHeight() * 0.20)
    self:SetColor(0,0,0)
    self:SetSize(350, 200)

    self.classNameText:SetText("Target: None")
    self.buildTimeText:SetText("Total Time: 0s")
    self.expectedTimeText:SetText("Expected Time: ?s")
    
end

function GUIBuildTimes:InitSession(className, expectedTime)
    self.classNameText:SetText(string.format("Target: %s", className))
    self.expectedTimeText:SetText(string.format("Expected Time: %.2fs", expectedTime))
end

function GUIBuildTimes:UpdateInfo(totalTime)
    self.buildTimeText:SetText(string.format("Total Time: %.2fs", totalTime))
end 