class 'SiegeTimers'

function SiegeTimers:__init()
    self.timers = {}
end

function SiegeTimers:SetTimer(name, duration)
    self.timers[name] = { remaining = duration }
end

function SiegeTimers:Update(deltaTime)
    for name, timer in pairs(self.timers) do
        if timer.remaining > 0 then
            timer.remaining = math.max(0, timer.remaining - deltaTime)
        end
    end
end

function SiegeTimers:IsTimerDone(name)
    return self.timers[name] and self.timers[name].remaining <= 0
end
