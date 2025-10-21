--[=====[
[[SND Metadata]]
author: Minnu (https://ko-fi.com/minnuverse)
version: 2.0.0
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

--=========================== VARIABLES ==========================--

import("System.Numerics")

-------------------
--    General    --
-------------------

RunsToPlay  = Config.Get("RunsToPlay")
LogPrefix   = "[TripleTriad]"

---------------------
--    Condition    --
---------------------

CharacterCondition = {
    playingMiniGame     = 13,
    boundByDuty         = 34
}

--=========================== FUNCTIONS ==========================--

----------------
--    Duty    --
----------------

function BattleHall()
    Dalamud.Log(string.format("%s Moving to Battle Hall.", LogPrefix))
    Instances.DutyFinder:QueueDuty(195) -- The Triple Triad Battlehall

    while not Svc.Condition[CharacterCondition.boundByDuty] do
        yield("/wait 0.1")
        if Addons.GetAddon("ContentsFinderConfirm").Ready then
            yield("/wait 1")
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
        yield("/wait 2")
        local targetNPC = Entity.GetEntityByName("Nell Half-full")

        if not targetNPC then
            Dalamud.Log(string.format("%s Unable to find Nell Half-full NPC..!!", LogPrefix))
            return
        end

        targetNPC:SetAsTarget()
        local pos = targetNPC.Position

        if pos then
            IPC.vnavmesh.PathfindAndMoveTo(Vector3(pos.X, pos.Y, pos.Z), false)
            yield("/wait 1")

            repeat
                yield("/wait 0.1")
            until not IPC.vnavmesh.PathfindInProgress() and not IPC.vnavmesh.IsRunning()
        end

        yield("/wait 1")
        targetNPC:Interact()
        PlayTTUntilNeeded()
    else
        Dalamud.Log(string.format("%s Not in BattleHall..!!", LogPrefix))
    end
end

function PlayTTUntilNeeded()
    repeat
        yield("/wait 0.1")
    until Svc.Condition[CharacterCondition.playingMiniGame]

    Dalamud.Log(string.format("%s Starting Triple Triad...", LogPrefix))
    yield("/saucy tt play " ..RunsToPlay)
    yield("/saucy tt go")
    yield("/wait 1")

    while Svc.Condition[CharacterCondition.playingMiniGame] do
        yield("/wait 0.1")
    end

    InstancedContent.LeaveCurrentContent()

    repeat
        yield("/wait 0.1")
    until not Svc.Condition[CharacterCondition.boundByDuty]

    repeat
        yield("/wait 0.1")
    until Player.Available and not Player.IsBusy
end

--=========================== EXECUTION ==========================--

if Svc.ClientState.TerritoryType ~= 579 then
    BattleHall()
    Play()
else
    Play()
end

yield(string.format("/echo %s Triple Triad script completed successfully..!!", LogPrefix))
Dalamud.Log(string.format("%s Triple Triad script completed successfully..!!", LogPrefix))

--============================== END =============================--