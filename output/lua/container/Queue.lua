-- ======= Copyright (c) 2003-2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\container\Queue.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
-- Simple queue container implementation with increasing front and rear indexes.
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

local Queue = typedef()

function Queue:New()
    self.size = 0
    self.list = {}
    self.front = 1
    self.rear = 1

    return self
end

function Queue:GetCount()
    return self.size
end

function Queue:Enqueue(Value)
    if self.size == 0 then
        self.list[self.front] = Value
    else
        self.rear = self.rear + 1
        self.list[self.rear] = Value
    end

    self.size = self.size + 1
end

function Queue:Dequeue()
    if self.size == 0 then
        return nil
    end

    local Value = self.list[self.front]
    self.list[self.front] = nil

    self.front = self.front + 1
    self.size = self.size - 1

    -- resize indexes
    if self.size == 0 then
        self.front = 1
        self.rear = 1
    end

    return Value
end

function Queue:SetFront(Value)
    self.front = self.front - 1
    self.list[self.front] = Value

    self.size = self.size + 1
end

function Queue:GetFront()
    return self.list[self.front]
end

do
    local function Iterate( state )
        local i  = state.i + 1
        state.i = i
        return state.list[i]
    end

    function Queue:Iterate()
        return Iterate, { list = self.list, i = self.front - 1 }
    end

end

function Queue:Clear()
    self.size = 0
    self.front = 1
    self.rear = 1
    table.clear(self.list)
end

_G.queue = Queue

-- A queue with only unique elements
local UniqueQueue = typedef(Queue)
function UniqueQueue:New()
    Queue.New(self)

    self.map = {}

    return self
end

function UniqueQueue:Enqueue(Value)
    if self.map[Value] then return false end

    Queue.Enqueue(self, Value)
    self.map[Value] = self.rear

    return true
end

function UniqueQueue:SetFront(Value)
    if self.map[Value] then return false end

    Queue.SetFront(self, Value)
    self.map[Value] = self.front

    return true
end

function UniqueQueue:Dequeue()
    local Value = Queue.Dequeue(self)

    if Value then
        self.map[Value] = nil
    end

    return Value
end

function UniqueQueue:Contains(Value)
    return self.map[Value] ~= nil
end

function UniqueQueue:Clear()
    Queue.Clear(self)

    table.clear(self.map)
end
_G.unique_queue = UniqueQueue

