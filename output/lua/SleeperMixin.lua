-- Todo: Remove/Rework
-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\SleeperMixin.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
--    Reduces amount of updates for unimportant entities
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

SleeperMixin = CreateMixin( SleeperMixin )
SleeperMixin.type = "Sleeper"

SleeperMixin.expectedCallbacks = {
    GetCanSleep = "Defines if an entity is in a state were it can go to sleep.",
}

SleeperMixin.optionalCallbacks = {
    GetMinimumAwakeTime = "Return a custom time the entity has to remain awake until it is allowed to sleep."
}

SleeperMixin.timeLastSleeperUpdate = {}
SleeperMixin.sleepers = unique_set()
SleeperMixin.sleepersDirty = unique_set()

SleeperMixin.timeLastCheckAll = 0
SleeperMixin.currentIndex = 1

-- a deltatime value that is experienced as "playable"
SleeperMixin.kDeltaTimeToleranz = 1 / 30

SleeperMixin.averageDeltaTime = 0.05
SleeperMixin.lastDeltaTimes = {}
SleeperMixin.currentDeltaTimeIndex = 1
SleeperMixin.kNumDeltaTimes = 12 -- store the last 10 deltaTimes and get average out of those

-- update this amount of sleepers at high tick rate. it would be better to save the actual computation time required and translate that to an entity amount
SleeperMixin.kNumUpdates = 30

SleeperMixin.kMinimumAwakeTime = 3

local function ComputerAverageDeltaTime(currentDeltaTime)

    if currentDeltaTime then

        if table.icount(SleeperMixin.lastDeltaTimes) < SleeperMixin.kNumDeltaTimes then
            table.insert(SleeperMixin.lastDeltaTimes, currentDeltaTime)
        else
            SleeperMixin.lastDeltaTimes[SleeperMixin.currentDeltaTimeIndex] = currentDeltaTime

            -- reset to 1 and overwrite old times if limit has been reached
            SleeperMixin.currentDeltaTimeIndex = ConditionalValue(SleeperMixin.currentDeltaTimeIndex + 1 <= 10, SleeperMixin.currentDeltaTimeIndex + 1, 1)
        end

        SleeperMixin.averageDeltaTime = 0

        for _, deltaTime in ipairs(SleeperMixin.lastDeltaTimes) do
            SleeperMixin.averageDeltaTime = SleeperMixin.averageDeltaTime + deltaTime
        end

        SleeperMixin.averageDeltaTime = SleeperMixin.averageDeltaTime / table.icount(SleeperMixin.lastDeltaTimes)

    end

end

local function InternalSleep(self)

    --Print("sleep %s", self:GetClassName())
    self:SetUpdates(false)
    self.sleeping = true

    SleeperMixin.sleepers:Insert(self:GetId())

    -- Todo make class instance var
    SleeperMixin.timeLastSleeperUpdate[self:GetId()] = Shared.GetTime()

end

local function InternalWakeUp(self)

    --Print("wakeup %s", self:GetClassName())
    self:SetUpdates(true, kRealTimeUpdateRate)
    self.sleeping = false
    self.timeLastWakeUp = Shared.GetTime()

    SleeperMixin.sleepers:Remove(self:GetId())
    SleeperMixin.timeLastSleeperUpdate[self:GetId()] = nil

end

local sleepingEnabled = true

local function InternalGetCanSleep(self)

    local canSleep = sleepingEnabled and self.GetCanSleep

    if canSleep then
        canSleep = self:GetCanSleep()
        local awakeTime = SleeperMixin.kMinimumAwakeTime

        if canSleep then
            if self.GetMinimumAwakeTime then
                awakeTime = self:GetMinimumAwakeTime()
            end

            canSleep = canSleep and (self.timeLastWakeUp + awakeTime < Shared.GetTime())
        end
    end

    return canSleep

end

function SleeperOnUpdateServer(deltaTime)

    PROFILE("SleeperMixin:OnUpdateServer")

    SleeperMixin.CheckDirtyTable()
    ComputerAverageDeltaTime(deltaTime)
    --Print("average deltaTime: %s", tostring(SleeperMixin.averageDeltaTime))

    if SleeperMixin.timeLastCheckAll + 2 < Shared.GetTime() then
        SleeperMixin.CheckAll()
        SleeperMixin.timeLastCheckAll = Shared.GetTime()
    end


    -- Change time slot to be based on total frame time
    local numMaxUpdates = math.ceil((SleeperMixin.kDeltaTimeToleranz / SleeperMixin.averageDeltaTime) * SleeperMixin.kNumUpdates)
    local numSleepers = SleeperMixin.sleepers:GetCount()
    local lastIndex = math.min(SleeperMixin.currentIndex + numMaxUpdates, numSleepers)

    --Print("num sleepers updated: %s", tostring(lastIndex - SleeperMixin.currentIndex))

    -- update sleepers from list
    for index = SleeperMixin.currentIndex, lastIndex do
    
        local entityId = SleeperMixin.sleepers:GetValueAtIndex(index)
        local entity = Shared.GetEntity(entityId)

        if entity then

            entity:OnUpdate(Shared.GetTime() - SleeperMixin.timeLastSleeperUpdate[entityId])
            SleeperMixin.timeLastSleeperUpdate[entityId] = Shared.GetTime()

            if not InternalGetCanSleep(entity) then
                entity:WakeUp()
            end

        else
            SleeperMixin.sleepersDirty:Insert(entityId)
        end

    end

    if lastIndex >= numSleepers then
        SleeperMixin.timeLastUpdateCompleted = Shared.GetTime()
        SleeperMixin.currentIndex = 1
    else
        SleeperMixin.currentIndex = lastIndex + 1
    end

end

function SleeperMixin.CheckDirtyTable()

    for _, entityId in ipairs(SleeperMixin.sleepersDirty:GetList()) do
    
        local entity = Shared.GetEntity(entityId)

        if entity and entity.GetIsSleeping then
            if InternalGetCanSleep(entity) and entity:GetIsSleeping() then
                InternalSleep(entity)
            else

                if not entity:GetIsSleeping() then
                    InternalWakeUp(entity)
                end

            end
        else
            SleeperMixin.timeLastSleeperUpdate[entityId] = nil
            SleeperMixin.sleepers:Remove(entityId)
        end

    end
    
    SleeperMixin.sleepersDirty:Clear()

end

-- remove awake entities from list and add sleeping entities
function SleeperMixin.CheckAll()

    for _, entity in ipairs(GetEntitiesWithMixin("Sleeper")) do
    
        if InternalGetCanSleep(entity) then

            if not entity:GetIsSleeping() then
                InternalSleep(entity)
            end

        else

            if entity:GetIsSleeping() then
                InternalWakeUp(entity)
            end

        end

    end

end

function SleeperMixin:__initmixin()

    PROFILE("SleeperMixin:__initmixin")

    self.sleeping = false
    self.timeLastWakeUp = Shared.GetTime()

end

-- always wake up on damage
function SleeperMixin:OnTakeDamage()
    self:WakeUp()
end

-- wake up on destroy, so we get removed from the sleepers table
function SleeperMixin:OnDestroy()
    self:WakeUp()
end

function SleeperMixin:GetIsSleeping()
    return self.sleeping
end

function SleeperMixin:SetIsSleeping(sleeping)
    self.sleeping = sleeping
end

function SleeperMixin:WakeUp()

    -- store that even if we already are awake (refreshes the timer)
    self.timeLastWakeUp = Shared.GetTime()

    if self:GetIsSleeping() then
        self:SetIsSleeping(false)
        SleeperMixin.sleepersDirty:Insert(self:GetId())
    end

end

function SleeperMixin:Sleep(time)

    if not self:GetIsSleeping() then
        self:SetIsSleeping(true)
        SleeperMixin.sleepersDirty:Insert(self:GetId())
    end

    if time then
        self:AddTimedCallback(self.WakeUp, time)
    end
end

function OnCommandToggleSleeping(client)
    if (Shared.GetCheatsEnabled()) then
        sleepingEnabled = not sleepingEnabled
        Log("sleeping %s", sleepingEnabled and "enabled" or "disabled")
    end
end


Event.Hook("UpdateServer", SleeperOnUpdateServer)
Event.Hook("Console_sleeping", OnCommandToggleSleeping)