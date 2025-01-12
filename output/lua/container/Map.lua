-- ======= Copyright (c) 2003-2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Map.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
-- Simple map container implementations.
-- This implementation allows to iterate over the keys and values of the map numerically
-- enabling LuaJit to compile traces using it.
-- While still allowing to check and add members in constant time.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- sets up metatables for datatypes
local function typedef(parent)
    local mt = {}
    mt.__index = mt

    return setmetatable( mt, {
        __call = function( self )
            return setmetatable( {}, self ):New()
        end,
        __index = parent
    } )
end

local Map = typedef()
function Map:New()
    self.keys = {}
    self.values = {}

    self.numKeys = 0
    self.position = 0

    return self
end

function Map:Clear()
    table.clear(self.keys)
    table.clear(self.values)

    self.numKeys = 0
    self.position = 0
end

function Map:GetCount()
    return self.numKeys
end
Map.GetSize = Map.GetCount

function Map:GetValue(Key)
    return self.values[Key]
end
Map.Find = Map.GetValue
Map.Get = Map.GetValue

function Map:GetKeys()
    return self.keys
end

function Map:Insert(Key, Value)
    if self.values[Key] ~= nil then return false end

    local numKeys = self.numKeys + 1
    self.numKeys = numKeys
    self.keys[numKeys] = Key
    self.values[Key] = Value

end
Map.Add = Map.Insert

function Map:RemoveAtPosition(Position)
    Position = Position or self.position

    local key = self.keys[Position]
    if key == nil then return nil end

    local value = self.values[key]
    self.values[key] = nil

    for i = Position, self.numKeys do
        self.keys[i] = self.keys[i + 1]
    end

    self.numKeys = self.numKeys - 1

    if self.position >= Position then
        self.position = self.position - 1
    end

    return key, value
end
Map.EraseAtPosition = Map.RemoveAtPosition

function Map:Remove(Key)
    if self.values[Key] == nil then return nil end

    if self.keys[self.position] == Key then
        local _, value = self:RemoveAtPosition()
        return value
    end

    for i = 1, self.numKeys do
        local cKey = self.keys[i]
        if cKey == Key then
            local _, value = self:RemoveAtPosition(i)
            return value
        end
    end
end
Map.Erase = Map.Remove

function Map:HasNext()
    return self.keys[self.position + 1] ~= nil
end

function Map:HasPrevious()
    return self.position > 1 and self.numKeys > 0
end

function Map:GetNext()
    local next = self.position + 1
    if next > self.numKeys then
        return nil
    end

    self.position = next

    local key = self.keys[next]
    return key, self.values[key]
end

function Map:PeekNext()
    local next = self.position + 1
    if next > self.numKeys then
        return nil
    end

    local key = self.keys[next]
    return key, self.values[key]
end

function Map:GetPrevious()
    local previous = self.position - 1
    if previous <= 0 then
        return nil
    end

    self.position = previous

    local key = self.keys[previous]
    return key, self.values[key]
end

function Map:PeekPrevious()
    local previous = self.position - 1
    if previous <= 0 then
        return nil
    end

    local key = self.keys[previous]
    return key, self.values[key]
end

function Map:ResetPosition()
    self.position = 0
end

--[[
	Sets the iteration position.
	Input: New iteration position to jump to.
]]
function Map:SetPosition(Position)
    self.position = math.clamp(Position, 1, self.numKeys)
end

do
    local GetNext = Map.GetNext
    function Map:Iterate()
        self.position = 0

        return GetNext, self
    end
end

do
    local GetPrevious = Map.GetPrevious
    function Map:IterateBackwards()
        self.position = self.numKeys + 1

        return GetPrevious, self
    end
end

function Map:AsTable()
    local table = {}
    for key, value in self:Iterate() do
        table[key] = value
    end
    return table
end
_G.unique_map = Map

local Multimap = typedef(Map)
function Multimap:New()
    Map.New(self)

    self.numValues = 0 -- multimap can have more values than keys

    return self
end

function Multimap:Clear()
    Map.Clear(self)
    self.numValues = 0
end

function Multimap:GetCount()
    return self.numValues
end
Multimap.GetSize = Multimap.GetCount

function Multimap:GetKeyCount()
    return self.numKeys
end

function Multimap:GetValues(Key)
    local values = Map.GetValue(self, Key)
    if not values then return nil end

    return values:GetKeys()
end
Multimap.Find = Multimap.GetValues
Multimap.Get = Multimap.GetValues
Multimap.GetValue = Multimap.GetValues

function Multimap:Insert(Key, Value)
    local values = Map.GetValue(Key)
    if not values then
        values = Map()
        Map.Insert(self, Key, values)
        self.Count = self.Count + 1
    elseif values:GetValue(Value) == nil then
        self.numValues = self.numValues + 1
    end

    values:Insert(Key, Value)
end
Multimap.Add = Multimap.Insert

function Multimap:Remove(Key, Value)
    local values = Map.GetValues(self, Key)
    if not values then return nil end

    local removed = values:Remove(Value) ~= nil
    if removed then
        self.numValues = self.numValues - 1

        if values:GetCount() == 0 then
            Map.Remove(self, Key)
        end
    end

    return removed
end
Multimap.Erase = Multimap.Remove
Multimap.RemoveKeyValue = Multimap.Remove

function Multimap:GetNext()
    local key, values = Map.GetNext(self )
    if key ~= nil then
        return key, values.keys
    end

    return nil
end

function Multimap:GetPrevious()
    local key, values = Map.GetPrevious(self )
    if key ~= nil then
        return key, values.keys
    end

    return nil
end

do
    local GetNext = Multimap.GetNext
    function Multimap:Iterate()
        self.position = 0

        return GetNext, self
    end
end

do
    local GetPrevious = Multimap.GetPrevious
    function Multimap:IterateBackwards()
        self.position = self.numValues + 1

        return GetPrevious, self
    end
end
_G.unique_multimap = Multimap
