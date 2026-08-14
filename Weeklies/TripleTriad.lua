--[=====[
[[SND Metadata]]
author: Minnu (https://ko-fi.com/minnuverse)
version: 2.1.0
description: Triple Triad - A barebones script for weekly challenge log
plugin_dependencies:
- Saucy
- TextAdvance
- vnavmesh
configs:
  RunsToPlay:
    description: Number of runs to play.
    default: 15

[[End Metadata]]
--]=====]

--========================== DEPENDENCIES ========================--

import("System.Numerics")

--=========================== VARIABLES ==========================--

-------------------
--    General    --
-------------------

RunsToPlay  = Config.Get("RunsToPlay")
LogPrefix   = "[TripleTriad]"

--============================ CONSTANT ==========================--

---------------------
--    Condition    --
---------------------

CharacterCondition = {
    playingMiniGame     = 13,
    boundByDuty         = 34
}

-----------------
--    Duty    --
-----------------

TripleTriadBattleHallDutyId = 195

----------------
--    NPC    --
----------------

TripleTriadNpcName = "Nell Half-full"

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

-----------------------
--    Battle Hall    --
-----------------------

function BattleHall()
    Log("Moving to Battle Hall.")
    Instances.DutyFinder:QueueDuty(TripleTriadBattleHallDutyId)

    while not Svc.Condition[CharacterCondition.boundByDuty] do
        Wait(0.1)
        if Addons.GetAddon("ContentsFinderConfirm").Ready then
            Wait(1)
            yield("/click ContentsFinderConfirm Commence")
        end
    end
end

-----------------
--    Triad    --
-----------------

function Play()
    if Svc.ClientState.TerritoryType == 579 then
        yield("/at y")
        Wait(2)
        local targetNPC = Entity.GetEntityByName(TripleTriadNpcName)

        if not targetNPC then
            Log(string.format("Unable to find %s.", TripleTriadNpcName))
            return
        end

        targetNPC:SetAsTarget()
        local pos = targetNPC.Position

        if pos then
            IPC.vnavmesh.PathfindAndMoveTo(Vector3(pos.X, pos.Y, pos.Z), false)
            Wait(1)

            repeat
                Wait(0.1)
            until not IPC.vnavmesh.PathfindInProgress() and not IPC.vnavmesh.IsRunning()
        end

        Wait(1)
        targetNPC:Interact()
        PlayTTUntilNeeded()
    else
        Log("Not in Battle Hall.")
    end
end

function PlayTTUntilNeeded()
    repeat
        Wait(0.1)
    until Svc.Condition[CharacterCondition.playingMiniGame]

    Log("Starting Triple Triad...")
    yield("/saucy tt play " .. RunsToPlay)
    yield("/saucy tt go")
    Wait(1)

    while Svc.Condition[CharacterCondition.playingMiniGame] do
        Wait(0.1)
    end

    InstancedContent.LeaveCurrentContent()

    repeat
        Wait(0.1)
    until not Svc.Condition[CharacterCondition.boundByDuty]

    repeat
        Wait(0.1)
    until Player.Available and not Player.IsBusy
end

--=========================== EXECUTION ==========================--

if Svc.ClientState.TerritoryType ~= 579 then
    BattleHall()
    Play()
else
    Play()
end

Echo("Triple Triad script completed successfully..!!")
Log("Triple Triad script completed successfully..!!")

--============================== END =============================--
