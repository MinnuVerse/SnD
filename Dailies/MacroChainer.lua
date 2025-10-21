--[=====[
[[SND Metadata]]
author: Minnu
version: 2.0.0
description: Macro Chainer - Run multiple macros in sequence
configs:
  FirstMacro:
    description: Select the macro to run first
    is_choice: true
    choices:
        - "None"
        - "TTSeller"
        - "MiniCactpot"
        - "AlliedSocietiesQuests"
  SecondMacro:
    description: Select the macro to run second
    is_choice: true
    choices:
        - "None"
        - "TTSeller"
        - "MiniCactpot"
        - "AlliedSocietiesQuests"
  ThirdMacro:
    description: Select the macro to run third
    is_choice: true
    choices:
        - "None"
        - "TTSeller"
        - "MiniCactpot"
        - "AlliedSocietiesQuests"

[[End Metadata]]
--]=====]

--=========================== VARIABLES ==========================--

EchoTrigger = nil
MacroDone   = false

--=========================== HELPERS ============================--

function GetSelectedMacros()
    local orderKeys = { "FirstMacro", "SecondMacro", "ThirdMacro" }
    local names = {}

    for _, key in ipairs(orderKeys) do
        local macro = Config.Get(key)
        if macro and macro ~= "" and macro ~= "None" then
            names[#names + 1] = macro
        end
    end
    return names
end

--=========================== CALLBACKS ==========================--

function OnChatMessage()
    local message = TriggerData and TriggerData.message

    if EchoTrigger and message and message:find(EchoTrigger) then
        MacroDone = true
    end
end

--=========================== EXECUTION ==========================--

local selected = GetSelectedMacros()
if #selected == 0 then
    Dalamud.Log("[MacroChainer] No macros configured. Aborting.")
    return
end

local EchoAlias = {
    TTSeller              = "TTSeller",
    MiniCactpot           = "MiniCactpot",
    AlliedSocietiesQuests = "AlliedQuests",
}

local MacrosToRun = {}
for _, name in ipairs(selected) do
    MacrosToRun[#MacrosToRun + 1] = {
        macroName   = name,
        echoTrigger = EchoAlias[name] or name,
    }
end

for _, mNames in ipairs(MacrosToRun) do
    EchoTrigger = mNames.echoTrigger
    MacroDone   = false

    Dalamud.Log(string.format("[MacroChainer] Starting → %s", mNames.macroName))
    yield(string.format("/snd run %s", mNames.macroName))

    while not MacroDone do
        yield("/wait 1")
    end

    Dalamud.Log(string.format("[MacroChainer] Completed → %s", mNames.macroName))
    yield("/wait 1")
end

Dalamud.Log("[MacroChainer] All macros completed. Stopping any remaining..!!")
yield("/snd stop all")

--============================== END =============================--