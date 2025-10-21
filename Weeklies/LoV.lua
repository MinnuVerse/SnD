--[=====[
[[SND Metadata]]
author: Minnu (https://ko-fi.com/minnuverse)
version: 2.0.0
description: Lord of Verminion - A barebones script for weeklies
configs:
  RunsToPlay:
    description: Number of runs to play.
    default: 5
  RunsPlayed:
    description: Initial run count.
    default: 0

[[End Metadata]]
--]=====]

--=========================== VARIABLES ==========================--

-------------------
--    General    --
-------------------

RunsToPlay   = Config.Get("RunsToPlay")
RunsPlayed   = Config.Get("RunsPlayed")
LogPrefix    = "[LoV]"

--============================ CONSTANT ==========================--

---------------------
--    Condition    --
---------------------

CharacterCondition = {
    playingLordOfVerminion  = 14
}

--=========================== FUNCTIONS ==========================--

----------------
--    Main    --
----------------

function DutyFinder()
    Dalamud.Log(string.format("%s Starting new match. Currently at %s/%s runs.", LogPrefix, RunsPlayed, RunsToPlay))
    Instances.DutyFinder.IsUnrestrictedParty = false
    Instances.DutyFinder.IsLevelSync = false
    Instances.DutyFinder:QueueDuty(578)

    while not Svc.Condition[CharacterCondition.playingLordOfVerminion] do
        yield("/wait 1")
        if Addons.GetAddon("ContentsFinderConfirm").Ready then
            yield("/wait 1")
            yield("/click ContentsFinderConfirm Commence")
        end
    end
end

function EndMatch()
    while not Addons.GetAddon("LovmResult").Ready do
        yield("/wait 1")
    end

    yield("/callback LovmResult false -2")
    yield("/callback LovmResult true -1")

    while not Addons.GetAddon("NamePlate").Ready do
        yield("/wait 1")
    end

    RunsPlayed = RunsPlayed + 1
    Dalamud.Log(string.format("%s Runs played: %s", LogPrefix, RunsPlayed))

    repeat
        yield("/wait 0.1")
    until Player.Available and not Player.IsBusy
    yield("/wait 1")
end

--=========================== EXECUTION ==========================--

while RunsPlayed < RunsToPlay do
    DutyFinder()
    EndMatch()
end

yield(string.format("/echo %s Lord of Verminion script completed successfully..!!", LogPrefix))
Dalamud.Log(string.format("%s Lord of Verminion script completed successfully..!!", LogPrefix))

--============================== END =============================--