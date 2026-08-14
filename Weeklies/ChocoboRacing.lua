--[=====[
[[SND Metadata]]
author: Minnu (https://ko-fi.com/minnuverse)
version: 2.1.0
description: Chocobo Racing - A barebones script for weekly challenge log
configs:
  RunsToPlay:
    description: Number of runs to play.
    default: 20
  RunsPlayed:
    description: Initial run count.
    default: 0
  SuperSprint:
    description: Use Super Sprint ability during races.
    default: true

[[End Metadata]]
--]=====]

--=========================== VARIABLES ==========================--

-------------------
--    General    --
-------------------

RunsToPlay   = Config.Get("RunsToPlay")
RunsPlayed   = Config.Get("RunsPlayed")
SuperSprint  = Config.Get("SuperSprint")
LogPrefix    = "[ChocoboRacing]"

--============================ CONSTANT ==========================--

---------------------
--    Condition    --
---------------------

CharacterCondition = {
    occupiedInCutscene  = 35
}

-----------------
--    Duty    --
-----------------

ChocoboRaceDutyId = 22

-------------------
--    Actions    --
-------------------

ChocoboRaceAction = {
    superSprint = 58
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

----------------
--    Race    --
----------------

function DutyFinder()
    Log(string.format("Starting new race. Currently at %s/%s runs.", RunsPlayed, RunsToPlay))
    Instances.DutyFinder:QueueRoulette(ChocoboRaceDutyId)

    while not Svc.Condition[CharacterCondition.occupiedInCutscene] do
        Wait(0.1)
        if Addons.GetAddon("ContentsFinderConfirm").Ready then
            Wait(1)
            yield("/click ContentsFinderConfirm Commence")
        end
    end
end

function UseSuperSprint()
    if Svc.Condition[CharacterCondition.occupiedInCutscene] then
        repeat
            Wait(0.1)
        until not Svc.Condition[CharacterCondition.occupiedInCutscene]
    end

    Wait(6)

    if not SuperSprint then
        return
    end

    Actions.ExecuteAction(ChocoboRaceAction.superSprint, ActionType.ChocoboRaceAbility)
    Wait(3)
end

function KeySpam()
    yield("/hold A")
    Wait(5)
    yield("/release A")

    repeat
        yield("/send KEY_1")
        Wait(1)
        yield("/send KEY_2")
        Wait(10)
    until Addons.GetAddon("RaceChocoboResult").Ready
end

function EndRace()
    yield("/callback RaceChocoboResult true 1")
    RunsPlayed = RunsPlayed + 1
    Log(string.format("Runs played: %s", RunsPlayed))

    repeat
        Wait(0.1)
    until Player.Available and not Player.IsBusy
end

--=========================== EXECUTION ==========================--

while RunsPlayed < RunsToPlay do
    DutyFinder()
    UseSuperSprint()
    KeySpam()
    EndRace()
end

Echo("Chocobo Racing script completed successfully..!!")
Log("Chocobo Racing script completed successfully..!!")

--============================== END =============================--
