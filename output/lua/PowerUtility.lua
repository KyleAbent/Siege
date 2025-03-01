-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\PowerUtility.lua
--
--    Created by: Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

if Server then

    -- sort always by distance first (increases the chance that we find a suitable source faster)

    function FindNewPowerConsumers(powerSource)
    
        -- allow passing of nil (to handle map change or unexpected destruction of some ojects)
        if not powerSource then
            return nil
        end
    
        local consumers = GetEntitiesWithMixin("PowerConsumer")
        Shared.SortEntitiesByDistance(powerSource:GetOrigin(), consumers)

        for _, consumer in ipairs(consumers) do

            local canPower, stopSearch = powerSource:GetCanPower(consumer)
        
            if canPower then
                powerSource:AddConsumer(consumer)
                consumer:SetPowerOn()
                consumer.powerSourceId = powerSource:GetId()
            end
            
            if stopSearch then
                break
            end
            
        end

    end

    function FindNewPowerSource(powerConsumer)
        -- allow passing of nil (to handle map change or unexpected destruction of some ojects)
        if not powerConsumer then
            return nil
        end
    
        local powerSources = GetEntitiesWithMixin("PowerSource")
        Shared.SortEntitiesByDistance(powerConsumer:GetOrigin(), powerSources)
        
        local newPowerSource = nil
        for _, powerSource in ipairs(powerSources) do
            -- Skip batteries in this loop - we'll handle them separately
            if not powerSource:isa("BackupBattery") and powerSource:GetCanPower(powerConsumer) and powerSource:GetIsBuilt() and powerSource:GetIsPowering() then
                newPowerSource = powerSource
--                 Print("Found new power source: %s", powerSource:GetClassName())
                break
            end
        end

        -- Only check for batteries if we didn't find a regular power source
        if not newPowerSource or not newPowerSource:GetIsPowering() then
            local teamNumber = powerConsumer.GetTeamNumber and powerConsumer:GetTeamNumber() or kTeamReadyRoom
            local batteriesInRange = GetEntitiesForTeamWithinRange("BackupBattery",
                                      teamNumber,
                                      powerConsumer:GetOrigin(),
                                      BackupBattery.kRange)
            for _, battery in ipairs(batteriesInRange) do
                if battery:GetIsBuilt() and battery:GetIsPowering() and battery:GetCanPower(powerConsumer) then
                    newPowerSource = battery
--                     Print("Found new power source: %s", battery:GetClassName())
                    break
                end
            end
        end

        return newPowerSource
    end
    
end