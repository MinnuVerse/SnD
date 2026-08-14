--[=====[
[[SND Metadata]]
author: Minnu (https://ko-fi.com/minnuverse)
version: 2.1.0
description: Lord of Verminion - A barebones script for weekly challenge log
configs:
  RunsToPlay:
    description: Number of runs to play.
    default: 5
  RunsPlayed:
    description: Initial run count.
    default: 0
  Mode:
    description: Mode to play.
    is_choice: true
    choices:
        - "Normal"
        - "Hard"
        - "Extreme"

[[End Metadata]]
--]=====]

--=========================== VARIABLES ==========================--

-------------------
--    General    --
-------------------

RunsToPlay   = Config.Get("RunsToPlay")
RunsPlayed   = Config.Get("RunsPlayed")
Mode         = Config.Get("Mode")
LogPrefix    = "[LoV]"

--============================ CONSTANT ==========================--

---------------------
--    Condition    --
---------------------

CharacterCondition = {
    playingLordOfVerminion  = 14
}

----------------
--    Mode    --
----------------

ModeIDs = {
    Normal    = 576,
    Hard      = 577,
    Extreme   = 578
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

-----------------
--    Match    --
-----------------

function DutyFinder()
    local modeId = ModeIDs[Mode]

    if not modeId then
        Log(string.format("Invalid mode '%s'; defaulting to Normal (576).", tostring(Mode)))
        modeId = ModeIDs.Normal
    end

    Log(string.format("Starting new match. Currently at %s/%s runs.", RunsPlayed, RunsToPlay))
    Instances.DutyFinder.IsUnrestrictedParty = false
    Instances.DutyFinder.IsLevelSync = false
    Instances.DutyFinder:QueueDuty(modeId)

    while not Svc.Condition[CharacterCondition.playingLordOfVerminion] do
        Wait(0.1)
        if Addons.GetAddon("ContentsFinderConfirm").Ready then
            Wait(1)
            yield("/click ContentsFinderConfirm Commence")
        end
    end
end

function EndMatch()
    while not Addons.GetAddon("LovmResult").Ready do
        Wait(1)
    end

    yield("/callback LovmResult false -2")
    yield("/callback LovmResult true -1")

    while not Addons.GetAddon("NamePlate").Ready do
        Wait(1)
    end

    RunsPlayed = RunsPlayed + 1
    Log(string.format("Runs played: %s", RunsPlayed))

    repeat
        Wait(0.1)
    until Player.Available and not Player.IsBusy
end

--=========================== EXECUTION ==========================--

while RunsPlayed < RunsToPlay do
    DutyFinder()
    EndMatch()
end

Echo("Lord of Verminion script completed successfully..!!")
Log("Lord of Verminion script completed successfully..!!")

--============================== END =============================--
