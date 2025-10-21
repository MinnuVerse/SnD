--[=====[
[[SND Metadata]]
author: Minnu (https://ko-fi.com/minnuverse)
version: 2.0.0
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

----------------
--    Main    --
----------------

function DutyFinder()
    local modeId = ModeIDs[Mode]

    if not modeId then
        Dalamud.Log(string.format("%s Invalid mode '%s' — defaulting to Normal (576).", LogPrefix, tostring(Mode)))
        modeId = ModeIDs.Normal
    end

    Dalamud.Log(string.format("%s Starting new match. Currently at %s/%s runs.", LogPrefix, RunsPlayed, RunsToPlay))
    Instances.DutyFinder.IsUnrestrictedParty = false
    Instances.DutyFinder.IsLevelSync = false
    Instances.DutyFinder:QueueDuty(modeId)

    while not Svc.Condition[CharacterCondition.playingLordOfVerminion] do
        yield("/wait 0.1")
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
end

--=========================== EXECUTION ==========================--

while RunsPlayed < RunsToPlay do
    DutyFinder()
    EndMatch()
end

yield(string.format("/echo %s Lord of Verminion script completed successfully..!!", LogPrefix))
Dalamud.Log(string.format("%s Lord of Verminion script completed successfully..!!", LogPrefix))

--============================== END =============================--