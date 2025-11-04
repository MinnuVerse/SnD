--[=====[
[[SND Metadata]]
author: Minnu
version: 2.0.0
description: Macro Chainer - Run multiple macros in sequence
configs:
  Macros:
    description: Macros to run, separated by commas, no spaces. Each entry
        should be MacroName:EchoTrigger. EchoTrigger is usually whatever is in
        the brackets whenever a script echoes something to the chat log, like
        "[AlliedQuests] Daily Allied Quests script completed successfully..!!"
    default: TTSeller:TTSeller,MiniCactpot:MiniCactpot,AlliedSocietiesQuests:AlliedQuests

[[End Metadata]]
--]=====]

--=========================== VARIABLES ==========================--

MacroDone   = false

--=========================== HELPERS ============================--



function GetSelectedMacros()
    local macrosList = {
        -- TTSeller              = "TTSeller",
        -- MiniCactpot           = "MiniCactpot",
        -- AlliedSocietiesQuests = "AlliedQuests",
    }

    local macros = Config.Get("Macros")
    local i = 1
    if macros ~= nil then
        for macro in string.gmatch(macros, '([^,]+)') do
            local macroName, trigger = macro:match("^(.-):(.*)$")
            if macroName ~= "" and trigger ~= "" then
                macrosList[i] = { macroName = macroName, echoTrigger = trigger }
                i = i + 1
            end
        end
    end
    return macrosList
end

--=========================== CALLBACKS ==========================--

function OnChatMessage()
    local message = TriggerData and TriggerData.message

    if EchoTrigger and message and message:find("%[" .. EchoTrigger .. "%]") and message:find("completed successfully") then
        MacroDone = true
    end
end

--=========================== EXECUTION ==========================--

local macrosList = GetSelectedMacros()
for _, mNames in ipairs(macrosList) do
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