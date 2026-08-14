--[=====[
[[SND Metadata]]
author: Minnu (https://ko-fi.com/minnuverse)
version: 2.1.0
description: Triple Triad Seller - Sells your accumulated Triple Triad cards
plugin_dependencies:
- Lifestream
- vnavmesh

[[End Metadata]]
--]=====]

--========================== DEPENDENCIES ========================--

import("System.Numerics")

--=========================== VARIABLES ==========================--

-------------------
--    General    --
-------------------

LogPrefix = "[TTSeller]"

--============================ CONSTANT ==========================--

---------------
--    NPC    --
---------------

Npc = {
    Name = "Triple Triad Trader",
    Position = {
        X = -52.42,
        Y = 1.6,
        Z = 15.77
    }
}

--=========================== FUNCTIONS ==========================--

-------------------
--    Utility    --
-------------------

function Wait(time)
    yield(string.format("/wait %g", time))
end

function Log(message)
    Dalamud.Log(string.format("%s %s", LogPrefix, message))
end

function Debug(message)
    Dalamud.LogDebug(string.format("%s %s", LogPrefix, message))
end

function Echo(message)
    yield(string.format("/echo %s %s", LogPrefix, message))
end

function WaitForPlayer()
    Debug("WaitForPlayer: Waiting for player to become available...")
    repeat
        Wait(0.1)
    until Player.Available and not Player.IsBusy
    Debug("WaitForPlayer: Player is now available.")
    Wait(0.1)
end

function WaitForTeleport()
    Debug("Waiting for teleport to begin...")

    repeat
        Wait(0.1)
    until not Svc.Condition[27]
    Wait(0.1)

    Debug("Teleport started, waiting for zoning to complete...")

    repeat
        Wait(0.1)
    until not Svc.Condition[45] and Player.Available and not Player.IsBusy
    Wait(0.1)

    Debug("Teleport complete.")
end

function WaitForPathRunning(timeout)
    timeout = timeout or 300
    Debug("Waiting for navmesh pathing to complete...")

    local startTime = os.clock()
    while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
        if (os.clock() - startTime) >= timeout then
            Log("WaitForPathRunning: Timeout reached waiting for pathing to complete.")
            return false
        end
        Wait(0.1)
    end

    Debug("Pathing complete.")
    return true
end

function WaitForAddon(name, timeout)
    timeout = timeout or 60
    local startTime = os.clock()

    Debug(string.format("Waiting for addon '%s' to become ready...", name))

    while not Addons.GetAddon(name).Ready do
        if os.clock() - startTime >= timeout then
            Log(string.format("WaitForAddon('%s') timed out after %.1f seconds", name, timeout))
            return false
        end
        Wait(0.1)
    end

    Debug(string.format("Addon '%s' is ready.", name))
    return true
end

----------------------
--    Navigation    --
----------------------

function GetDistanceToPoint(dX, dY, dZ)
    local player = Svc.Objects.LocalPlayer
    if not player or not player.Position then
        Debug("GetDistanceToPoint: Player position unavailable.")
        return math.huge
    end

    local px = player.Position.X
    local py = player.Position.Y
    local pz = player.Position.Z

    local dx = dX - px
    local dy = dY - py
    local dz = dZ - pz

    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    Debug(string.format("[Distance] From (%.2f, %.2f, %.2f) to (%.2f, %.2f, %.2f) = %.2f", px, py, pz, dX, dY, dZ, distance))
    return distance
end

function Teleport(location)
    Log(string.format("Initiating teleport to '%s'.", location))
    IPC.Lifestream.ExecuteCommand(location)
    Wait(0.1)
    WaitForTeleport()
end

-----------------------
--    Interaction    --
-----------------------

function Interact(name, maxRetries, sleepTime)
    maxRetries = maxRetries or 20
    sleepTime = sleepTime or 0.1

    yield('/target ' .. tostring(name))

    local retries = 0
    while (Entity == nil or Entity.Target == nil) and retries < maxRetries do
        Wait(sleepTime)
        retries = retries + 1
    end

    if Entity and Entity.Target and Entity.Target.Name then
        yield('/interact')
        Debug(string.format("Interacted with: %s", Entity.Target.Name))
        return true
    else
        Log("Interact() failed to acquire target.")
        return false
    end
end

-----------------------------
--    Seller Navigation    --
-----------------------------

function DistanceToSeller()
    if Svc.ClientState.TerritoryType == 144 then
        Distance_Test = GetDistanceToPoint(Npc.Position.X, Npc.Position.Y, Npc.Position.Z)
        Debug(string.format("Distance to seller: %.2f", Distance_Test))
    end
end

function GoToSeller()
    local destination = Vector3(Npc.Position.X, Npc.Position.Y, Npc.Position.Z)

    if Svc.ClientState.TerritoryType == 144 then
        DistanceToSeller()

        if Distance_Test > 0 and Distance_Test < 100 then
            IPC.vnavmesh.PathfindAndMoveTo(destination, false)
            WaitForPathRunning()
            return
        end
    end

    Teleport("The Gold Saucer")
    IPC.vnavmesh.PathfindAndMoveTo(destination, false)
    WaitForPathRunning()
end

-------------------
--    Selling    --
-------------------

function Main()
    Interact(Npc.Name)
    WaitForAddon("SelectIconString")
    yield("/callback SelectIconString true 1")
    Wait(1)

    while true do
        WaitForAddon("TripleTriadCoinExchange")

        if Addons.GetAddon("TripleTriadCoinExchange"):GetNode(1, 11).IsVisible then
            break
        end

        if Addons.GetAddon("TripleTriadCoinExchange"):GetNode(1, 10, 5).IsVisible then
            yield("/callback TripleTriadCoinExchange true 0")
            WaitForAddon("ShopCardDialog")
            Wait(1)
        end

        local Node = Addons.GetAddon("TripleTriadCoinExchange"):GetNode(1, 10, 5, 6).Text
        local a = tonumber(Node)

        if Addons.GetAddon("ShopCardDialog").Ready then
            yield(string.format("/callback ShopCardDialog true 0 %d", a))
            Wait(1)
        end
        Wait(1)
    end
    yield("/callback TripleTriadCoinExchange true -1")
    Wait(1)
    return false
end

--=========================== EXECUTION ==========================--

GoToSeller()
Main()

Echo("Triple Triad Seller script completed successfully..!!")
Log("Triple Triad Seller script completed successfully..!!")

--============================== END =============================--
