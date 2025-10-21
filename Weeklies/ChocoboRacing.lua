--[=====[
[[SND Metadata]]
author: Minnu (https://ko-fi.com/minnuverse)
version: 2.0.0
description: Chocobo Racing - A barebones script for weeklies
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

--=========================== FUNCTIONS ==========================--

----------------
--    Main    --
----------------

function DutyFinder()
    Dalamud.Log(string.format("%s Starting new race. Currently at %s/%s runs.", LogPrefix, RunsPlayed, RunsToPlay))
    Instances.DutyFinder:QueueRoulette(22) -- Chocobo Race: Sagolii Road (No Rewards)

    while not Svc.Condition[CharacterCondition.occupiedInCutscene] do
        yield("/wait 1")
        if Addons.GetAddon("ContentsFinderConfirm").Ready then
            yield("/wait 1")
            yield("/click ContentsFinderConfirm Commence")
        end
    end
end

function UseSuperSprint()
    if Svc.Condition[CharacterCondition.occupiedInCutscene] then
        repeat
            yield("/wait 0.1")
        until not Svc.Condition[CharacterCondition.occupiedInCutscene]
    end

    yield("/wait 6")

    if not SuperSprint then
        return
    end

    Actions.ExecuteAction(58, ActionType.ChocoboRaceAbility) -- Super Sprint
    yield("/wait 3")
end

function KeySpam()
    yield("/hold A")
    yield("/wait 5")
    yield("/release A")

    repeat
        yield("/send KEY_1")
        yield("/wait 1")
        yield("/send KEY_2")
        yield("/wait 10")
    until Addons.GetAddon("RaceChocoboResult").Ready
end

function EndRace()
    RunsPlayed = RunsPlayed + 1
    yield("/callback RaceChocoboResult true 1")
    Dalamud.Log(string.format("%s Runs played: %s", LogPrefix, RunsPlayed))

    repeat
        yield("/wait 0.1")
    until Player.Available and not Player.IsBusy
    yield("/wait 1")
end

--=========================== EXECUTION ==========================--

while RunsPlayed < RunsToPlay do
    DutyFinder()
    UseSuperSprint()
    KeySpam()
    EndRace()
end

yield(string.format("/echo %s Chocobo Racing script completed successfully..!!", LogPrefix))
Dalamud.Log(string.format("%s Chocobo Racing script completed successfully..!!", LogPrefix))

--============================== END =============================--