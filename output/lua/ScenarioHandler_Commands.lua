--
-- Console commands for ScenarioHandler
--
Script.Load("lua/ScenarioHandler.lua")

function HandleData(data)
    ScenarioHandler.instance:Load(data)
end

function OnCommandScenSave(client, name)
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() or Shared.GetTestsEnabled() then
        ScenarioHandler.instance:Save(name)
    else
        Log("Scene Load requires Cheats, Dev, or Tests enabled")
    end
end

function OnCommandScenLoad(client, name)
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() or Shared.GetTestsEnabled() then
        ScenarioHandler.instance:LoadScenario(name)
    else
        Log("Scene Load requires Cheats, Dev, or Tests enabled")
    end
end

Event.Hook("Console_scenesave",      OnCommandScenSave)
Event.Hook("Console_sceneload",      OnCommandScenLoad)