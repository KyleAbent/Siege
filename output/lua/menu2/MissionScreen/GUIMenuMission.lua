-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/MissionScreen/GUIMenuMission.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    A single mission to appear in the mission screen.  Missions consist of a series of steps to
--    complete, which are listed inside this object.
--
--  Parameters (* = required)
--     *missionName
--     *completionCheckTex      The texture to use for the checkbox in the completion object.
--     *completionDescription   The description text to use for the completion object.
--     *stepConfigs             List of configs for each individual step of the mission.
--      completedCallback       Function to fire when the mission is completed.  Does not perform
--                              any checks to ensure this is the first time the mission is
--                              completed, so this will also fire every time the mission GUI is
--                              loaded.
--
--  Properties
--      MissionName     The name of the mission to display at the top of the column.
--      Completed       Whether or not this mission has been completed.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")

Script.Load("lua/menu2/MissionScreen/GUIMenuMissionStep.lua")
Script.Load("lua/menu2/MissionScreen/GUIMenuMissionCompletion.lua")

Script.Load("lua/menu2/widgets/GUIMenuScrollPane.lua")

Script.Load("lua/menu2/GUIMenuCoolBox2.lua")
Script.Load("lua/menu2/GUIMenuBasicBox.lua")

---@class GUIMenuMission : GUIObject
local baseClass = GUIObject
class "GUIMenuMission" (baseClass)

GUIMenuMission.kBackgroundTexture = PrecacheAsset("ui/thunderdome_rewards/missions_background.dds")
GUIMenuMission.kBackgroundWidth = 905
GUIMenuMission.kBackgroundHeight = 1489
GUIMenuMission.kBorderWidth = 11

GUIMenuMission:AddCompositeClassProperty("Completed", "completionObj")

local kNameAreaHeight = 120
local kNameAreaHeight_DoubleLabels = 250
local kDoubleTitleOffsetY = 25

local kListInset = 16

local kNameFont = ReadOnly{ family = "Microgramma", size = 42 }
local kNameFont_Double = ReadOnly{ family = "Microgramma", size = 42 }
local kTitle2Font = ReadOnly{family = "MicrogrammaBold", size = 42}
local kNameColor = MenuStyle.kOptionHeadingColor
local kCompletedNameColor = MenuStyle.kHighlight
local kTitle2Color = ColorFrom255(208, 230, 235)

local function OnCompletedChanged(self)

    if not self.changeColorOnComplete then return end

    if self:GetCompleted() then
        self.nameText:SetColor(kCompletedNameColor)
    else
        self.nameText:SetColor(kNameColor)
    end
end

local function UpdateMiddleHeight(self)
    self.listArea:SetHeight(self:GetSize().y - self.titleAreaHeight - self.completionObj:GetSize().y)
end

local function UpdateCompleteness(self)
    
    local fullyComplete = true
    for i=1, #self.subStepObjs do
        if not self.subStepObjs[i]:GetCompleted() then
            fullyComplete = false
            break
        end
    end
    
    self:SetCompleted(fullyComplete)

end

local function OnStepCompleted(self, completed)
    
    if completed == false then
        self:SetCompleted(false)
        return -- couldn't possibly be all-complete if this one isn't.
    end
    
    UpdateCompleteness(self)
    
end

local function LoadListContents(self, configs, errorDepth)
    errorDepth = errorDepth + 1
    
    for i=1, #configs do
    
        local newStep = CreateGUIObjectFromConfig(configs[i], self.listLayout)
    
        if not newStep:GetPropertyExists("Completed") then
            error(string.format("Sub-step %d of mission didn't have a property named 'Completed'.", i), errorDepth)
        end
        
        table.insert(self.subStepObjs, newStep)
        self:HookEvent(newStep, "OnCompletedChanged", OnStepCompleted)
        newStep:HookEvent(self.listLayout, "OnSizeChanged", newStep.SetWidth)
        newStep:SetWidth(self.listLayout:GetSize().x)
    
    end
    
end

local function UpdateInnerListAreaSize(self)
    self.innerListArea:SetSize(self.listArea:GetSize().x - kListInset*2, self.listArea:GetSize().y - kListInset*2)
end

function GUIMenuMission:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    RequireType({"string", "nil"},   params.missionName,           "params.missionName",           errorDepth) -- if missionName is specified, title1 and title2 are ignored.
    RequireType({"string", "nil"},   params.title1,                "params.title1",                errorDepth) -- top of top label
    RequireType({"string", "nil"},   params.title2,                "params.title2",                errorDepth) -- bottom of top label
    RequireType("string",            params.completionCheckTex,    "params.completionCheckTex",    errorDepth)
    RequireType("string",            params.completionDescription, "params.completionDescription", errorDepth)
    RequireType("table",             params.stepConfigs,           "params.stepConfigs",           errorDepth)
    RequireType({"function", "nil"}, params.completedCallback,     "params.completedCallback",     errorDepth)
    RequireType({"boolean", "nil"},  params.changeColorOnComplete, "params.changeColorOnComplete",     errorDepth)

    if not params.missionName and not (params.title1 and params.title2) then
        error("If not using params.missionName, MUST use both params.title1 and params.title2", errorDepth)
    end
    
    baseClass.Initialize(self, params, errorDepth)

    self:SetTexture(self.kBackgroundTexture)
    self:SetSize(self.kBackgroundWidth, self.kBackgroundHeight)
    self:SetColor(1,1,1)

    local doubleLabelStyle = not params.missionName and (params.title1 and params.title2)
    self.titleAreaHeight = doubleLabelStyle and kNameAreaHeight_DoubleLabels or kNameAreaHeight
    local labelOffsetY = doubleLabelStyle and -kDoubleTitleOffsetY or 0

    self.nameArea = CreateGUIObject("nameArea", GUIObject, self)
    self.nameArea:SetSize(self.kBackgroundWidth - self.kBorderWidth * 2, self.titleAreaHeight)
    self.nameArea:AlignTop()

    -- nameText becomes title1 if using double style
    self.nameText = CreateGUIObject("nameText", GUIText, self.nameArea,
    {
        align = "center",
        font = doubleLabelStyle and kNameFont_Double or kNameFont,
        color = doubleLabelStyle and kCompletedNameColor or kNameColor,
    })

    self.changeColorOnComplete = params.changeColorOnComplete
    self:HookEvent(self, "OnCompletedChanged", OnCompletedChanged)

    self.nameText:SetText(doubleLabelStyle and params.missionName or params.title1)
    self.nameText:SetY(labelOffsetY)

    if doubleLabelStyle then
        self.title2 = CreateGUIObject("title2", GUIText, self.nameArea,
        {
            align = "center",
            font = kTitle2Font,
            color = kTitle2Color,
        })
        self.title2:SetText(params.title2)
        self.title2:SetY(self.nameText:GetPosition().y + self.nameText:GetSize().y)
    end
    
    self.listArea = CreateGUIObject("listArea", GUIObject, self)
    self.listArea:SetWidth(self.kBackgroundWidth - self.kBorderWidth * 2)
    self.listArea:SetY(self.titleAreaHeight)
    self.listArea:AlignTop()
    
    self.innerListArea = CreateGUIObject("innerListArea", GUIObject, self.listArea)
    self.innerListArea:AlignCenter()
    self.innerListArea:SetLayer(-1)
    self:HookEvent(self.listArea, "OnSizeChanged", UpdateInnerListAreaSize)
    UpdateInnerListAreaSize(self)
    
    self.listScrollPane = CreateGUIObject("listScrollPane", GUIMenuScrollPane, self.innerListArea,
    {
        horizontalScrollBarEnabled = false,
    })
    self.listScrollPane:HookEvent(self.innerListArea, "OnSizeChanged", self.listScrollPane.SetSize)
    
    self.listLayout = CreateGUIObject("listLayout", GUIListLayout, self.listScrollPane,
    {
        orientation = "vertical",
        fixedMinorSize = true,
    })
    self.listScrollPane:HookEvent(self.innerListArea, "OnSizeChanged", self.listScrollPane.SetPaneWidth)
    self.listScrollPane:SetPaneWidth(self.innerListArea:GetSize().x)
    
    self.listLayout:HookEvent(self.listScrollPane, "OnContentsSizeChanged", self.listLayout.SetWidth)
    self.listLayout:SetWidth(self.listScrollPane:GetContentsSize())
    
    self.listScrollPane:HookEvent(self.listLayout, "OnSizeChanged", self.listScrollPane.SetPaneHeight)
    self.listScrollPane:SetHeight(self.listLayout:GetSize())
    
    self.subStepObjs = {} -- list of objects that hold the substep data.
    LoadListContents(self, params.stepConfigs, errorDepth)
    
    self.completionObj = CreateGUIObject("completionObj", GUIMenuMissionCompletion, self,
    {
        checkTex = params.completionCheckTex,
        description = params.completionDescription,
        align = "top"
    })
    self.completionObj:SetWidth(self.kBackgroundWidth - self.kBorderWidth * 2)

    local heightLeft = self:GetSize().y - self.nameArea:GetSize().y - self.listLayout:GetSize().y
    local completeHeight = self.completionObj:GetSize().y
    self.completionObj:SetHeight(heightLeft - (heightLeft / 4))
    self.completionObj:SetY(self.nameArea:GetSize().y + self.listLayout:GetSize().y + (heightLeft - completeHeight) / 2)

    self:HookEvent(self.completionObj, "OnSizeChanged", UpdateMiddleHeight)
    self:HookEvent(self, "OnSizeChanged", UpdateMiddleHeight)
    UpdateMiddleHeight(self)
    
    if params.completedCallback then
        self:HookEvent(self, "OnCompletedChanged",
        function(self2, completed)
            if completed then
                params.completedCallback()
            end
        end)
    end
    
    UpdateCompleteness(self)
    
end
