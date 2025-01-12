-- Register network messages
Shared.RegisterNetworkMessage("SiegeTimerUpdate", {
    frontDoorTime = "float",
    siegeDoorTime = "float",
    timeElapsed = "float"
})

Shared.RegisterNetworkMessage("FrontDoorOpened", {})
Shared.RegisterNetworkMessage("SiegeDoorOpened", {})
