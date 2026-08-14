--[=====[
[[SND Metadata]]
author: Minnu (https://ko-fi.com/minnuverse)
version: 3.2.0
description: Macro Chainer - Run multiple macros in sequence for repetitive tasks
configs:
  MacrosToRun:
    description: |
      The macros to run, one after another, in the order listed.
      Enter the exact macro name as it appears in SND and press enter. One macro per line.
    default: []
  StartTimeout:
    description: |
      Seconds to wait for a macro to appear as running before skipping it.
      This only applies when a macro cannot start, such as from a misspelled name.
    default: 10
    min: 1
    max: 120
  RunTimeout:
    description: |
      Maximum seconds a macro may run before it is stopped and skipped.
      Set to 0 for no limit.
    default: 0
    min: 0
    max: 14400

[[End Metadata]]
--]=====]

--=========================== VARIABLES ==========================--

-------------------
--    General    --
-------------------

MacrosToRun   = Config.Get("MacrosToRun")
StartTimeout  = Config.Get("StartTimeout")
RunTimeout    = Config.Get("RunTimeout")
LogPrefix     = "[MacroChainer]"

---------------------------
--    Scheduler State    --
---------------------------

local MacroScheduler        = nil
local MacroSchedulerFailed  = false
local SndConfig             = nil

--=========================== FUNCTIONS ===========================--

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

---------------------
--    Scheduler    --
---------------------

function GetMacroScheduler()
    if MacroScheduler or MacroSchedulerFailed then
        return MacroScheduler
    end

    MacroSchedulerFailed = true
    luanet.load_assembly("SomethingNeedDoing")

    local enumProxy         = luanet.import_type("System.Enum")
    local pluginProxy       = luanet.import_type("SomethingNeedDoing.Plugin")
    local schedulerProxy    = luanet.import_type("SomethingNeedDoing.Core.Interfaces.IMacroScheduler")
    local bindingFlagsProxy = luanet.import_type("System.Reflection.BindingFlags")

    if not pluginProxy or not schedulerProxy or not bindingFlagsProxy then
        return nil
    end

    local pluginType        = luanet.ctype(pluginProxy)
    local schedulerType     = luanet.ctype(schedulerProxy)
    local bindingFlagsType  = luanet.ctype(bindingFlagsProxy)
    local staticNonPublic   = enumProxy.Parse(bindingFlagsType, "Static,NonPublic")
    local instanceNonPublic = enumProxy.Parse(bindingFlagsType, "Instance,NonPublic")

    local pluginField = pluginType:GetField("<P>k__BackingField", staticNonPublic)
    if not pluginField then
        return nil
    end

    local plugin = pluginField:GetValue(nil)
    if not plugin then
        return nil
    end

    local configField = pluginType:GetField("<C>k__BackingField", staticNonPublic)
    if configField then
        SndConfig = configField:GetValue(nil)
    end

    local providerField = pluginType:GetField("_serviceProvider", instanceNonPublic)
    if not providerField then
        return nil
    end

    local serviceProvider = providerField:GetValue(plugin)
    if not serviceProvider then
        return nil
    end

    local scheduler = serviceProvider:GetService(schedulerType)
    if not scheduler then
        return nil
    end

    MacroScheduler = scheduler
    MacroSchedulerFailed = false
    return MacroScheduler
end

function GetKnownMacroNames()
    local names = {}
    if not GetMacroScheduler() or not SndConfig then
        return names
    end

    local configType = SndConfig:GetType()
    local macrosProperty = configType:GetProperty("Macros")
    local macros = macrosProperty and macrosProperty:GetValue(SndConfig) or nil
    if not macros then
        local macrosField = configType:GetField("Macros")
        macros = macrosField and macrosField:GetValue(SndConfig) or nil
    end

    if not macros then
        return names
    end

    local enumerator = macros:GetEnumerator()
    while enumerator:MoveNext() do
        local name = enumerator.Current.Name
        if name then
            names[tostring(name)] = true
        end
    end
    return names
end

-----------------
--    Macro    --
-----------------

function IsMacroRunning(macroName)
    local scheduler = GetMacroScheduler()
    if not scheduler then
        return false
    end

    local finishedStates = { "Completed", "Failed", "Error", "Cancel", "Stopped" }
    local enumerator = scheduler:GetMacros():GetEnumerator()
    while enumerator:MoveNext() do
        local macro = enumerator.Current
        if tostring(macro.Name) == macroName then
            local state = tostring(macro.State)
            local finished = false
            for _, finishedState in ipairs(finishedStates) do
                if state:find(finishedState, 1, true) then
                    finished = true
                    break
                end
            end

            if not finished then
                return true
            end
        end
    end
    return false
end

function StopRunningMacros(macroName)
    if macroName and macroName ~= "" then
        yield(string.format("/snd stop %s", macroName))
    else
        yield("/snd stop all")
    end
end

function RunMacroAndWait(macroName)
    yield(string.format("/snd run %s", macroName))

    local startTime = os.time()
    while not IsMacroRunning(macroName) do
        if os.time() - startTime >= StartTimeout then
            Log(string.format("Skipped macro; it did not start within %ds -> %s", StartTimeout, macroName))
            return false
        end
        Wait(0.1)
    end

    local runStart = os.time()
    while IsMacroRunning(macroName) do
        if RunTimeout > 0 and os.time() - runStart >= RunTimeout then
            Log(string.format("Stopping macro after %ds timeout -> %s", RunTimeout, macroName))
            StopRunningMacros(macroName)
            return false
        end
        Wait(1)
    end
    return true
end

--=========================== EXECUTION ==========================--

if not GetMacroScheduler() then
    Log("Aborting.")
    return
end

if not MacrosToRun or MacrosToRun.Count == 0 then
    Log("No macros configured; add them in the script settings.")
    return
end

local KnownMacros = GetKnownMacroNames()
local Macros = MacrosToRun:GetEnumerator()

while Macros:MoveNext() do
    local macroName = tostring(Macros.Current)
    if next(KnownMacros) and not KnownMacros[macroName] then
        Log(string.format("Skipping macro; name not found in SND -> %s", macroName))
    else
        Log(string.format("Starting macro -> %s", macroName))

        if RunMacroAndWait(macroName) then
            Log(string.format("Completed macro -> %s", macroName))
        else
            Log(string.format("Skipped macro; it never ran to completion -> %s", macroName))
        end
    end

    Wait(1)
end

Echo("All macros completed. Stopping any remaining..!!")
Log("All macros completed. Stopping any remaining..!!")
StopRunningMacros()

--============================== END =============================--
