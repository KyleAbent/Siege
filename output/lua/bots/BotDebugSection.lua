-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/BotDebugSection.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
-- Base class for a bot debugging section.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/OrderedIterableDict.lua")

local kFieldDefaults =
{
    ["number"] = 0,
    ["string"] = "",
    ["boolean"] = false
}

---@class BotDebugSection
class "BotDebugSection"

function BotDebugSection:Initialize(sectionType)
    assert(sectionType)

    self.fieldChanged = false

    self.sectionType = sectionType
    self.fields = OrderedIterableDict()
    --self.fieldTypes = OrderedIterableDict()
    self.displayString = ""

    --self:LoadFieldSettings(fieldSettings)

end

-- Sets the fields and their types
--function BotDebugSection:LoadFieldSettings(fieldSettings)
--    assert(fieldSettings)
--
--    for i, field in ipairs(fieldSettings.fields) do
--
--        local fieldName = field.name
--        local fieldType = field.type
--
--        local fieldDefaultValue = kFieldDefaults[fieldType]
--        assert(fieldDefaultValue)
--
--        self.fields[fieldName] = fieldDefaultValue
--        self.fieldTypes[fieldName] = fieldType
--
--    end
--
--    self:UpdateString()
--
--end

function BotDebugSection:SetField(fieldName, newValue)
    --assert(self.fields[fieldName] ~= nil, "Field does not exist!")
    --assert(type(newValue) == self.fieldTypes[fieldName], "New value does not match required type!")

    local oldValue = self.fields[fieldName]
    local valueChanged = oldValue ~= newValue
    self.fields[fieldName] = newValue

    if valueChanged then
        self:UpdateString()
    end

    self.fieldChanged = self.fieldChanged or valueChanged

end

function BotDebugSection:ResetChangedFlag()
    self.fieldChanged = false
end

function BotDebugSection:GetType()
    return self.sectionType
end

function BotDebugSection:GetDisplayString()
    return self.displayString
end

function BotDebugSection:GetHasChanged()
    return self.fieldChanged
end

function BotDebugSection:UpdateString()

    local numFields = #self.fields
    local formatString = string.rep("%s: %s\n", numFields)
    local formatArgs = {}
    for fieldName, fieldValue in pairs(self.fields) do
        table.insert(formatArgs, fieldName)
        table.insert(formatArgs, fieldValue)
    end

    self.displayString = string.format(formatString, unpack(formatArgs))

end
