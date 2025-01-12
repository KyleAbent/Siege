-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIEvent.lua
--
-- Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- Shows a list of events, for example: Flamethrower researched and commander notifications.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Hud/GUINotificationItem.lua")

class 'GUIEvent'

function CreateEventDisplay(scriptHandle, hudLayer, frame, useMarineStyle)

    local eventDisplay = GUIEvent()
    eventDisplay.script = scriptHandle
    eventDisplay.hudLayer = hudLayer
    eventDisplay.frame = frame
    eventDisplay.useMarineStyle = useMarineStyle
    eventDisplay:Initialize()
    return eventDisplay

end

-- 72 for before hive status gui, 430, for hive status gui, 10 for a bit of space
GUIEvent.kAlienFramepos = Vector(20, 72 + 430 + 10, 0)
GUIEvent.kMarineFramepos = Vector(20, 400, 0)

GUIEvent.kNotificationYOffset = 20

-- maximum number of displayed notifications at once
GUIEvent.kMaxDisplayedNotificationsMarine = 5
GUIEvent.kMaxDisplayedNotificationsAlien = 3

local kMaxMarineNotificationsNS1Hudbars = 3
local kMaxAlienNotificationsNS1Hudbars = 2

function GUIEvent:Initialize()

    self.scale = 1
    self.framePos = ConditionalValue(self.useMarineStyle, GUIEvent.kMarineFramepos, GUIEvent.kAlienFramepos)
    self.maxNotifications = ConditionalValue(self.useMarineStyle, GUIEvent.kMaxDisplayedNotificationsMarine, GUIEvent.kMaxDisplayedNotificationsAlien)

    -- List of notifications (gui items) that are being displayed.
    self.displayedNotifications = {}

    -- List of all sorted notifications (not gui items) that want to be displayed.
    self.notificationsData = {}

    self.notificationFrame = GetGUIManager():CreateGraphicItem()
    self.notificationFrame:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.notificationFrame:SetColor(Color(0,0,0,0))
    self.notificationFrame:SetLayer(0)
    self.frame:AddChild(self.notificationFrame)

    -- For some reason, people would sometimes get doubled research notifications. (Sanity check)
    PlayerUI_ClearResearchNotifications()

    -- Add all existing in-progress research.
    local player = Client.GetLocalPlayer()
    if player and HasMixin(player, "GUINotification") then

        local inProgress = {}
        GetTechTree():GetResearchInProgressTable(inProgress)

        for _, v in ipairs(inProgress) do
            player:AddNotification({ techId = v.techId, entityId = v.entityId, source = kResearchNotificationSource.CatchUpSync })
        end
    end

    local hudBars = ConditionalValue(self.useMarineStyle, GetAdvancedOption("hudbars_m"), GetAdvancedOption("hudbars_a"))
    if hudBars == 2 then

        self.maxNotifications = ConditionalValue(self.useMarineStyle, kMaxMarineNotificationsNS1Hudbars, kMaxAlienNotificationsNS1Hudbars)

    end

    self.notificationFrame:SetIsVisible(GetAdvancedOption("unlocks"))

end

function GUIEvent:SetIsVisible(isVisible)
    self.notificationFrame:SetIsVisible(isVisible)
end

function GUIEvent:ClearNotifications()

    for _, notification in ipairs (self.displayedNotifications) do
        DestroyNotificationItem(notification)
    end

    self.notificationsData = { }
    self.displayedNotifications = { }
    
end

function GUIEvent:Reset(scale)

    self.scale = scale
    
    self.notificationFrame:SetPosition(self.framePos * self.scale)
    
end

function GUIEvent:GetTimeLeftForResearch(techId, entityId)

    local techNode = GetTechNode(techId)
    local researchProgress = techNode:GetResearchProgress(entityId) or 1
    local timePassed = researchProgress * techNode.time
    local timeLeftSeconds = techNode.time - timePassed

    return timeLeftSeconds
end

function GUIEvent:InsertNotification(newNotificationTable)

    -- Insert the new research techid into our list, sorted by first to complete.
    local newData =
    {
        techId = newNotificationTable.techId,
        entityId = newNotificationTable.entityId,
        timeLeft = self:GetTimeLeftForResearch(newNotificationTable.techId, newNotificationTable.entityId)
    }

    local index = 1
    local found = false

    for i = 1, #self.notificationsData do

        index = i
        local current = self.notificationsData[i]

        -- Update the seconds left here so we only update time when inserting.
        current.timeLeft = self:GetTimeLeftForResearch(current.techId, current.entityId)

        if current.timeLeft > newData.timeLeft then

            found = true
            table.insert(self.notificationsData, i, newData)
            break
        end
    end

    if not found then

        index = #self.notificationsData + 1
        table.insert(self.notificationsData, newData)

    end

    return index
end

local kDebugNotifications = false
local function OnDebugNotifications(client)

    kDebugNotifications = not kDebugNotifications
    Log("Debug Notifications: %s", kDebugNotifications)

end
Event.Hook("Console_debugresearch", OnDebugNotifications)

function GUIEvent:Update(_, newNotification)

    local remainingNotifications = {}
    local remainingNotificationData = {}
    local newTechIdInsertIndex = 0

    if newNotification ~= nil then
        newTechIdInsertIndex = self:InsertNotification(newNotification)
    end

    -- A new research that has a time-to-complete that places it in our displayed notification items list.
    if newNotification ~= nil and newTechIdInsertIndex <= #self.displayedNotifications then

        local insertedNotificationItem = CreateNotificationItem(self.script, newNotification.techId, self.scale, self.notificationFrame, self.useMarineStyle, newNotification.entityId)
        insertedNotificationItem.lastSecondsLeft = self:GetTimeLeftForResearch(insertedNotificationItem.techId, insertedNotificationItem.entityId)

        table.insert(self.displayedNotifications, newTechIdInsertIndex, insertedNotificationItem)
        insertedNotificationItem:SetPositionInstant(newTechIdInsertIndex - 1)
        insertedNotificationItem:FadeIn(0.5)

        -- Shift down all the following displayed notifications.
        for i = newTechIdInsertIndex + 1, #self.displayedNotifications do
            self.displayedNotifications[i]:ShiftDown()
        end

    else

        -- Add more notifications if we haven't reached our max and have more research waiting. Since data is already sorted, we can simply add to the end.
        local numDisplayedNotifications = #self.displayedNotifications
        if numDisplayedNotifications < self.maxNotifications and #self.notificationsData > numDisplayedNotifications then

            local newNotificationPosition = numDisplayedNotifications + 1
            local data = self.notificationsData[newNotificationPosition]
            local newNotification = CreateNotificationItem(self.script, data.techId, self.scale, self.notificationFrame, self.useMarineStyle, data.entityId)

            newNotification:SetPositionInstant(newNotificationPosition - 1)
            newNotification:FadeIn(0.5)
            table.insert(self.displayedNotifications, newNotification)

        end
    end

    local techTree = GetTechTree()
    -- Move canceled research to the top if it's out of view so players know about it.
    if techTree:GetAndClearTechTreeResearchCancelled() then

        for i = 1, #self.notificationsData do

            local data = self.notificationsData[i]
            local inProgress = techTree:GetResearchInProgress(data.techId, data.entityId)

            -- Only need to pop it in if its not already on the top.
            if not inProgress and i > 1 then

                local insertedNotificationItem
                local cancelledOutOfView = false
                if i > #self.displayedNotifications then

                    cancelledOutOfView = true
                    insertedNotificationItem = CreateNotificationItem(self.script, data.techId, self.scale, self.notificationFrame, self.useMarineStyle, data.entityId)
                    table.insert(self.displayedNotifications, 1, insertedNotificationItem)

                else

                    insertedNotificationItem = self.displayedNotifications[i]
                    table.remove(self.displayedNotifications, i)
                    table.insert(self.displayedNotifications, 1, insertedNotificationItem)

                end

                table.remove(self.notificationsData, i)
                table.insert(self.notificationsData, 1, data)

                insertedNotificationItem:SetPositionInstant(0)
                insertedNotificationItem:FadeIn(0.5)

                -- Shift down all the following displayed notifications, up to wherever the notification was.
                local stopIndexInclusive = ConditionalValue(cancelledOutOfView, #self.displayedNotifications, i)
                for j = 2, stopIndexInclusive do

                    self.displayedNotifications[j]:ShiftDown()

                end

            end

        end
    end

    -- Update displayed notifications
    local shiftUpTimes = 0
    for index, displayedNotification in ipairs(self.displayedNotifications) do

        displayedNotification:UpdateItem()

        if kDebugNotifications then
            displayedNotification.techTitle:SetText(tostring(displayedNotification.position))
        end

        local completedThisUpdate = false
        local cancelledThisUpdate = false
        local techNode = techTree:GetTechNode(displayedNotification.techId)

        local researchProgress = techNode:GetResearchProgress(displayedNotification.entityId) or displayedNotification.lastProgress
        local researched = researchProgress == 1
        local researching = techTree:GetResearchInProgress(displayedNotification.techId, displayedNotification.entityId)

        -- First time we're processing a complete state.
        if researched and not displayedNotification:GetCompleted() then

            completedThisUpdate = true

        -- Fade out the item if the "stay time" has passed.
        elseif displayedNotification:GetShouldStartFading() then

            displayedNotification:FadeOut(1)

        elseif not displayedNotification:GetCancelled() and not displayedNotification:GetCompleted()
                and not researched and not researching then

            cancelledThisUpdate = true
        end
        
        if displayedNotification:GetIsReadyToBeDestroyed() then

            displayedNotification:Destroy()
            shiftUpTimes = shiftUpTimes + 1

        elseif index > self.maxNotifications then

            displayedNotification:FadeOut(0.5)
            table.insert(remainingNotifications, displayedNotification)
            table.insert(remainingNotificationData, self.notificationsData[index])

        else

            table.insert(remainingNotifications, displayedNotification)
            table.insert(remainingNotificationData, self.notificationsData[index])

            -- Update research status of the notification
            if not displayedNotification:GetCompleted() and not displayedNotification:GetCancelled() then

                -- Update the timer.
                local timePassed = researchProgress * techNode.time
                local timeLeftSeconds = techNode.time - timePassed
                displayedNotification.lastSecondsLeft = timeLeftSeconds

                local minutes = math.floor( timeLeftSeconds / 60 )
                local seconds = math.floor( timeLeftSeconds - minutes * 60 )

                local timeText = string.format( "%02d:%02d", minutes, seconds)
                displayedNotification.bottomText:SetText(timeText)

                -- Update the bar.
                local progressBarWidth = displayedNotification.progressBarSize.x
                local fullProgressBarHeight = displayedNotification.progressBarSize.y

                local fullNoGlowHeight = fullProgressBarHeight - (displayedNotification.guiOffsets.ProgressBarGlowRadius * 2)
                local noGlowHeight = Clamp(math.floor((fullNoGlowHeight * researchProgress)), 0, fullNoGlowHeight)

                -- Glow is part of the asset, so only add the glow part of the texture when we reach enough progress.
                local progressBarHeight = noGlowHeight

                if progressBarHeight > 0 then

                    progressBarHeight = progressBarHeight + displayedNotification.guiOffsets.ProgressBarGlowRadius

                    if progressBarHeight >= (fullProgressBarHeight - displayedNotification.guiOffsets.ProgressBarGlowRadius) then
                        progressBarHeight = fullProgressBarHeight
                    end
                end

                local barTexCoords = displayedNotification.progressBarTextureCoords
                barTexCoords[2] = barTexCoords[4] - progressBarHeight
                displayedNotification.progressBar:SetSize(Vector(progressBarWidth, progressBarHeight, 0))
                displayedNotification.progressBar:SetTexturePixelCoordinates(GUIUnpackCoords(barTexCoords))

                local newYPos = fullProgressBarHeight - progressBarHeight
                displayedNotification.progressBar:SetPosition( displayedNotification.guiOffsets.ProgressBarPos + Vector(0, newYPos, 0))

                if completedThisUpdate then

                    displayedNotification:SetCompleted()
                    Client.GetLocalPlayer():TriggerEffects("upgrade_complete")

                elseif cancelledThisUpdate then

                    displayedNotification:SetCancelled()

                end
            end

            -- Shift up lower notifications if one has been destroyed.
            if shiftUpTimes > 0 then
                displayedNotification:ShiftUp(shiftUpTimes)
            end

        end

        -- Clean up the tech node's instance since we don't need it anymore.
        -- TODO(Salads): I don't want this here it smells
        if techNode.instances and (cancelledThisUpdate or completedThisUpdate) then

            techNode.instances[displayedNotification.entityId] = nil

        end

    end

    local lastDisplayIndex = #self.displayedNotifications
    self.displayedNotifications = remainingNotifications

    -- Add the leftover data after the last displayed notification index.
    for i = lastDisplayIndex + 1, #self.notificationsData do

        table.insert(remainingNotificationData, self.notificationsData[i])
    end

    self.notificationsData = remainingNotificationData
end

function GUIEvent:Destroy()

    if self.notificationFrame then
        GUI.DestroyItem(self.notificationFrame)
        self.notificationFrame = nil
    end    

end
