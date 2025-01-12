-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/DebugGUI/GBDDetailsSectionContents.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
--  The contents part of a bot debugging details section.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kContentsFont = ReadOnly({family = "Agency", size = 30})

Script.Load("lua/menu2/wrappers/Expandable.lua")
Script.Load("lua/menu2/GUIMenuBasicBox.lua")
Script.Load("lua/IterableDict.lua")
Script.Load("lua/GUI/GUIParagraph.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")
Script.Load("lua/GUI/GUIText.lua")

-- Limit of a string before it should split off (gui system errors out otherwise)
-- Its a bit lower to try and split it at a space
local kMaxTextLength = 400

---@class GBDDetailsSectionContents : GUIMenuBasicBox
local baseClass = GetExpandableWrappedClass(GUIMenuBasicBox)
class "GBDDetailsSectionContents" (baseClass)

GBDDetailsSectionContents:AddClassProperty("SectionString", "")

function GBDDetailsSectionContents:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self.textObjs = {}

    self.listLayout = CreateGUIObject("listLayout", GUIListLayout, self,
    {
        orientation = "vertical",
    }, errorDepth)

    self:HookEvent(self, "OnSectionStringChanged", self.OnSectionStringChanged)
    self:HookEvent(self, "OnSizeChanged", self.OnSizeChanged)
    self:HookEvent(self.listLayout, "OnSizeChanged", self.OnLayoutSizeChanged)

    if params.sectionString then
        self:SetSectionString(params.sectionString)
    end

end

function GBDDetailsSectionContents:OnLayoutSizeChanged(newSize)
    self:SetHeight(newSize.y)
end

function GBDDetailsSectionContents:OnSizeChanged(newSize)

    for i = 1, #self.textObjs do
        self.textObjs[i]:SetParagraphSize(newSize.x, -1)
    end

end

local kStringLimit = 450 -- Actual limit is actually ~500, but i get anxiety when its too close so ech
local function SplitString(bigString)

    local splitStrings = {}

    local numChars = string.len(bigString)
    local charIndex = 0
    local finished = false
    while not finished do

        local newIndex = charIndex + kStringLimit
        if newIndex < numChars then
            local subString = string.sub(bigString, charIndex + 1, newIndex)
            table.insert(splitStrings, subString)
            charIndex = newIndex
        else -- newIndex >= numChars
            local subString = string.sub(bigString, charIndex + 1)
            table.insert(splitStrings, subString)
            finished = true
        end

    end

    return splitStrings

end

function GBDDetailsSectionContents:OnSectionStringChanged(newString)

    local paragraphStrings = SplitString(newString)

    -- Make sure we have enough paragraph objects
    local numRequiredParagraphs = #paragraphStrings
    local numCurrentParagraphs = #self.textObjs

    while numCurrentParagraphs < numRequiredParagraphs do
        local newObj = CreateGUIObject("paragraphObj", GUIParagraph, self.listLayout)
        newObj:SetParagraphSize(self:GetSize().x, -1)
        newObj:SetFont(kContentsFont)
        table.insert(self.textObjs, newObj)
        numCurrentParagraphs = numCurrentParagraphs + 1
    end

    while numCurrentParagraphs > numRequiredParagraphs do
        local removeObj = self.textObjs[#self.textObjs]
        table.remove(self.textObjs, #self.textObjs)
        removeObj:Destroy()
        numCurrentParagraphs = numCurrentParagraphs - 1
    end

    assert(#paragraphStrings == #self.textObjs, "#GUIParagraph ~= #Paragraph Strings!")

    for i = 1, #paragraphStrings do
        local paragraphObj = self.textObjs[i]
        paragraphObj:SetText(paragraphStrings[i])
    end

    self:SetHeight(self.listLayout:GetSize().y)

end
