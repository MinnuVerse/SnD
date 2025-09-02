--[=====[
[[SND Metadata]]
author: Minnu (https://ko-fi.com/minnuverse)
version: 2.0.0
description: Triple Triad Seller - Sells your acumulated Triple Triad cards
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

Npc         = { Name = "Triple Triad Trader", Position = { X = -52.42, Y = 1.6, Z = 15.77 } }
LogPrefix   = "[TTSeller]"

--=========================== FUNCTIONS ==========================--

--------------------
--    Wrappers    --
--------------------

function Wait(time)
    yield("/wait " .. time)
end

function WaitForPlayer()
    Dalamud.Log(string.format("%s WaitForPlayer: Waiting for player to become available...", LogPrefix))
    repeat
        Wait(0.1)
    until Player.Available and not Player.IsBusy
    Dalamud.Log(string.format("%s WaitForPlayer: Player is now available.", LogPrefix))
    Wait(0.1)
end

function WaitForTeleport()
    Dalamud.Log(string.format("%s Waiting for teleport to begin...", LogPrefix))

    repeat
        Wait(0.1)
    until not Svc.Condition[27]
    Wait(0.1)

    Dalamud.Log(string.format("%s Teleport started, waiting for zoning to complete...", LogPrefix))

    repeat
        Wait(0.1)
    until not Svc.Condition[45] and Player.Available and not Player.IsBusy
    Wait(0.1)

    Dalamud.Log(string.format("%s Teleport complete.", LogPrefix))
end

function WaitForPathRunning(timeout)
    timeout = timeout or 300  -- Default timeout to 5 minutes (300 seconds)
    Dalamud.Log(string.format("%s Waiting for navmesh pathing to complete...", LogPrefix))

    local startTime = os.clock()
    while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
        if (os.clock() - startTime) >= timeout then
            Dalamud.Log(string.format("%s WaitForPathRunning: Timeout reached waiting for pathing to complete.", LogPrefix))
            return false
        end
        Wait(0.1)
    end

    Dalamud.Log(string.format("%s Pathing complete.", LogPrefix))
    return true
end

function WaitForAddon(name, timeout)
    timeout = timeout or 60
    local startTime = os.clock()

    Dalamud.Log(string.format("%s Waiting for addon '%s' to become ready...", LogPrefix, name))

    while not Addons.GetAddon(name).Ready do
        if os.clock() - startTime >= timeout then
            Dalamud.Log(string.format("%s WaitForAddon('%s') timed out after %.1f seconds", LogPrefix, name, timeout))
            return false
        end
        Wait(0.1)
    end

    Dalamud.Log(string.format("%s Addon '%s' is ready.", LogPrefix, name))
    return true
end

function GetDistanceToPoint(dX, dY, dZ)
    local player = Svc.ClientState.LocalPlayer
    if not player or not player.Position then
        Dalamud.Log(string.format("%s GetDistanceToPoint: Player position unavailable.", LogPrefix))
        return math.huge
    end

    local px = player.Position.X
    local py = player.Position.Y
    local pz = player.Position.Z

    local dx = dX - px
    local dy = dY - py
    local dz = dZ - pz

    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    Dalamud.Log(string.format("%s [Distance] From (%.2f, %.2f, %.2f) to (%.2f, %.2f, %.2f) = %.2f", LogPrefix, px, py, pz, dX, dY, dZ, distance))
    return distance
end

function Teleport(location)
    Dalamud.Log(string.format("%s Initiating teleport to '%s'.", LogPrefix, location))
    IPC.Lifestream.ExecuteCommand(location)
    Wait(0.1)
    WaitForTeleport()
end

function Interact(name, maxRetries, sleepTime)
    maxRetries = maxRetries or 20 -- Default retries if not provided
    sleepTime = sleepTime or 0.1 -- Default sleep interval if not provided

    yield('/target ' .. tostring(name))

    local retries = 0
    while (Entity == nil or Entity.Target == nil) and retries < maxRetries do
        Wait(sleepTime)
        retries = retries + 1
    end

    if Entity and Entity.Target and Entity.Target.Name then
        yield('/interact')
        Dalamud.Log(string.format("%s Interacted with: %s", LogPrefix, Entity.Target.Name))
        return true
    else
        Dalamud.Log(string.format("%s Interact() failed to acquire target.", LogPrefix))
        return false
    end
end

----------------
--    Misc    --
----------------

function DistanceToSeller()
    if Svc.ClientState.TerritoryType == 144 then
        Distance_Test = GetDistanceToPoint(Npc.Position.X, Npc.Position.Y, Npc.Position.Z)
        Dalamud.Log(string.format("%s Distance to seller: %.2f", LogPrefix, Distance_Test))
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

----------------
--    Main    --
----------------

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

Dalamud.Log(string.format("%s Triple Triad Seller script completed successfully..!!", LogPrefix))

--============================== END =============================--
