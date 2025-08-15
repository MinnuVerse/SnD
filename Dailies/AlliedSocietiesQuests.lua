--[=====[
[[SND Metadata]]
author: 'pot0to (https://ko-fi.com/pot0to) || Updated by: Minnu'
version: 2.0.0
description: Allied Societies Quests - Script for Dailies
plugin_dependencies:
- Questionable
- vnavmesh
- Lifestream
- TextAdvance
configs:
  FirstAlliedSociety:
    description: The first allied society from which to accept quests.
    type: string
    required: true
  FirstClass:
    description: Class to assign for first allied society.
    type: string
    required: true
  SecondAlliedSociety:
    description: The second allied society from which to accept quests.
    type: string
  SecondClass:
    description: Class to assign for second allied society.
    type: string
  ThirdAlliedSociety:
    description: The third allied society from which to accept quests.
    type: string
  ThirdClass:
    description: Class to assign for third allied society.
    type: string
  FourthAlliedSociety:
    description: The fourth allied society from which to accept quests.
    type: string
  FourthClass:
    description: Class to assign for fourth allied society.
    type: string

[[End Metadata]]
--]=====]

--[[
********************************************************************************
*                           Allied Society Quests                              *
*                               Version 0.2.0                                  *
********************************************************************************
Created by: pot0to (https://ko-fi.com/pot0to)
Updated by: Minnu

Goes around to the specified beast tribes, picks up 3 quests, does them, and
moves on to the next beast tribe.

********************************************************************************
*                                    Version                                   *
*                                     0.2.1                                    *
********************************************************************************

0.2.1   Fixed Mamool Ja name and removed main quests from presets
0.2.0   Added Mamool Jas for patch 7.25 (credit: Leonhart)
0.1.3   Fixed "Arkasodara" tribe name
        Added /qst stop after finishing one set of quests
        Updated Namazu aetheryte to Dhoro Iloh
        Added ability to change classes for different Allied Socieities
        First working version

********************************************************************************
*                               Required Plugins                               *
********************************************************************************
1. Vnavmesh
2. Questionable
3. Lifestream
4. TextAdvance

********************************************************************************
*            Code: Don't touch this unless you know what you're doing          *
********************************************************************************
--]]

import("System.Numerics")

ToDoList = {}

local societyConfigKeys = {
    { societyKey = "FirstAlliedSociety",  classKey = "FirstClass"  },
    { societyKey = "SecondAlliedSociety", classKey = "SecondClass" },
    { societyKey = "ThirdAlliedSociety",  classKey = "ThirdClass"  },
    { societyKey = "FourthAlliedSociety", classKey = "FourthClass" }
}

for _, entry in ipairs(societyConfigKeys) do
    local society = Config.Get(entry.societyKey)
    local class   = Config.Get(entry.classKey)

    if society and class and society ~= "" and class ~= "" then
        table.insert(ToDoList, { alliedSocietyName = society, class = class })
    end
end

AlliedSocietiesTable = {
    amaljaa = {
        alliedSocietyName = "Amalj'aa",
        mainQuests        = { first = 1217, last = 1221 },
        dailyQuests       = { first = 1222, last = 1251, blackList = { [1245] = true } },
        x                 = 103.12,
        y                 = 15.05,
        z                 = -359.51,
        zoneId            = 146,
        aetheryteName     = "Little Ala Mhigo",
        expac             = "A Realm Reborn"
    },
    sylphs = {
        alliedSocietyName = "Sylphs",
        mainQuests        = { first = 1252, last = 1256 },
        dailyQuests       = { first = 1257, last = 1286 },
        x                 = 46.41,
        y                 = 6.07,
        z                 = 252.91,
        zoneId            = 152,
        aetheryteName     = "The Hawthorne Hut",
        expac             = "A Realm Reborn"
    },
    kobolds = {
        alliedSocietyName = "Kobolds",
        mainQuests        = { first = 1320, last = 1324 },
        dailyQuests       = { first = 1325, last = 1373 },
        x                 = 12.857726,
        y                 = 16.164295,
        z                 = -178.77,
        zoneId            = 180,
        aetheryteName     = "Camp Overlook",
        expac             = "A Realm Reborn"
    },
    sahagin = {
        alliedSocietyName = "Sahagin",
        mainQuests        = { first = 1374, last = 1378 },
        dailyQuests       = { first = 1380, last = 1409 },
        x                 = -244.53,
        y                 = -41.46,
        z                 = 52.75,
        zoneId            = 138,
        aetheryteName     = "Aleport",
        expac             = "A Realm Reborn"
    },
    ixal = {
        alliedSocietyName = "Ixal",
        mainQuests        = { first = 1486, last = 1493 },
        dailyQuests       = { first = 1494, last = 1568 },
        x                 = 173.21,
        y                 = -5.37,
        z                 = 81.85,
        zoneId            = 154,
        aetheryteName     = "Fallgourd Float",
        expac             = "A Realm Reborn"
    },
    vanuvanu = {
        alliedSocietyName = "Vanu Vanu",
        mainQuests        = { first = 2164, last = 2225 },
        dailyQuests       = { first = 2171, last = 2200 },
        x                 = -796.3722,
        y                 = -133.27,
        z                 = -404.35,
        zoneId            = 401,
        aetheryteName     = "Ok' Zundu",
        expac             = "Heavensward"
    },
    vath = {
        alliedSocietyName = "Vath",
        mainQuests        = { first = 2164, last = 2225 },
        dailyQuests       = { first = 2171, last = 2200 },
        x                 = 58.80,
        y                 = -48.00,
        z                 = -171.64,
        zoneId            = 398,
        aetheryteName     = "Tailfeather",
        expac             = "Heavensward"
    },
    moogles = {
        alliedSocietyName = "Moogles",
        mainQuests        = { first = 2320, last = 2327 },
        dailyQuests       = { first = 2290, last = 2319 },
        x                 = -335.28,
        y                 = 58.94,
        z                 = 316.30,
        zoneId            = 400,
        aetheryteName     = "Zenith",
        expac             = "Heavensward"
    },
    kojin = {
        alliedSocietyName = "Kojin",
        mainQuests        = { first = 2973, last = 2978 },
        dailyQuests       = { first = 2979, last = 3002 },
        x                 = 391.22,
        y                 = -119.59,
        z                 = -234.92,
        zoneId            = 613,
        aetheryteName     = "Tamamizu",
        expac             = "Stormblood"
    },
    ananta = {
        alliedSocietyName = "Ananta",
        mainQuests        = { first = 3036, last = 3041 },
        dailyQuests       = { first = 3043, last = 3069 },
        x                 = -26.91,
        y                 = 56.12,
        z                 = 233.53,
        zoneId            = 612,
        aetheryteName     = "The Peering Stones",
        expac             = "Stormblood"
    },
    namazu = {
        alliedSocietyName = "Namazu",
        mainQuests        = { first = 3096, last = 3102 },
        dailyQuests       = { first = 3103, last = 3129 },
        x                 = -777.72,
        y                 = 127.81,
        z                 = 98.76,
        zoneId            = 622,
        aetheryteName     = "Dhoro Iloh",
        expac             = "Stormblood"
    },
    pixies = {
        alliedSocietyName = "Pixies",
        mainQuests        = { first = 3683, last = 3688 },
        dailyQuests       = { first = 3689, last = 3716 },
        x                 = -453.69,
        y                 = 71.21,
        z                 = 573.54,
        zoneId            = 816,
        aetheryteName     = "Lydha Lran",
        expac             = "Shadowbringers"
    },
    qitari = {
        alliedSocietyName = "Qitari",
        mainQuests        = { first = 3794, last = 3805 },
        dailyQuests       = { first = 3806, last = 3833 },
        x                 = 786.83,
        y                 = -45.82,
        z                 = -214.51,
        zoneId            = 817,
        aetheryteName     = "Fanow",
        expac             = "Shadowbringers"
    },
    dwarves = {
        alliedSocietyName = "Dwarves",
        mainQuests        = { first = 3896, last = 3901 },
        dailyQuests       = { first = 3902, last = 3929 },
        x                 = -615.48,
        y                 = 65.60,
        z                 = -423.82,
        zoneId            = 813,
        aetheryteName     = "The Ostall Imperative",
        expac             = "Shadowbringers"
    },
    arkosodara = {
        alliedSocietyName = "Arkasodara",
        mainQuests        = { first = 4545, last = 4550 },
        dailyQuests       = { first = 4551, last = 4578 },
        x                 = -68.21,
        y                 = 39.99,
        z                 = 323.31,
        zoneId            = 957,
        aetheryteName     = "Yedlihmad",
        expac             = "Endwalker"
    },
    loporrits = {
        alliedSocietyName = "Loporrits",
        mainQuests        = { first = 4681, last = 4686 },
        dailyQuests       = { first = 4687, last = 4714 },
        x                 = -201.27,
        y                 = -49.15,
        z                 = -273.8,
        zoneId            = 959,
        aetheryteName     = "Bestways Burrow",
        expac             = "Endwalker"
    },
    omicrons = {
        alliedSocietyName = "Omicrons",
        mainQuests        = { first = 4601, last = 4606 },
        dailyQuests       = { first = 4607, last = 4634 },
        x                 = 315.84,
        y                 = 481.99,
        z                 = 152.08,
        zoneId            = 960,
        aetheryteName     = "Base Omicron",
        expac             = "Endwalker"
    },
    pelupleu = {
        alliedSocietyName = "Pelupelu",
        mainQuests        = { first = 5193, last = 5198 },
        dailyQuests       = { first = 5199, last = 5226 },
        x                 = 770.89954,
        y                 = 12.846571,
        z                 = -261.0889,
        zoneId            = 1188,
        aetheryteName     = "Dock Poga",
        expac             = "Dawntrail"
    },
    mamoolja = {
        alliedSocietyName = "Mamool Ja",
        mainQuests        = { first = 5255, last = 5260 },
        dailyQuests       = { first = 5261, last = 5288 },
        x                 = 589.3,
        y                 = -142.9,
        z                 = 730.5,
        zoneId            = 1189,
        aetheryteName     = "Mamook",
        expac             = "Dawntrail"
    }
}

CharacterCondition = {
    mounted          =  4,
    casting          = 27,
    betweenAreas     = 45
}

function GetAlliedSocietyTable(alliedSocietyName)
    for _, alliedSociety in pairs(AlliedSocietiesTable) do
        if alliedSociety.alliedSocietyName == alliedSocietyName then
            return alliedSociety
        end
    end
end

function GetAcceptedAlliedSocietyQuests(alliedSocietyName)
    local accepted = {}
    local allAcceptedQuests = Quests.GetAcceptedQuests()
    local count = allAcceptedQuests.Count - 1

    for i = 1, count do
        local allAcceptedQuestId = allAcceptedQuests[i]
        local row = Excel.GetRow("Quest", allAcceptedQuestId)

        if row and row.BeastTribe and row.BeastTribe.Name:lower() == alliedSocietyName:lower() then
            table.insert(accepted, allAcceptedQuestId)
        end
    end

    return accepted
end

function HasPlugin(name)
    for plugin in luanet.each(Svc.PluginInterface.InstalledPlugins) do
        if plugin.InternalName == name and plugin.IsLoaded then
            Dalamud.Log(string.format("[AlliedQuests] Plugin '%s' found in InstalledPlugins.", name))
            return true
        end
    end

    Dalamud.Log(string.format("[AlliedQuests] Plugin '%s' not found in InstalledPlugins list.", name))
    return false
end

if HasPlugin("Lifestream") then
    TeleportCommand = "/li tp"
elseif HasPlugin("Teleporter") then
    TeleportCommand = "/tp"
else
    Dalamud.Log("[AlliedQuests] Please install either Teleporter or Lifestream")
    yield("/snd stop all")
end

function TeleportTo(aetheryteName)
    yield(TeleportCommand.." "..aetheryteName)
    yield("/wait 1") -- wait for casting to begin
    while Svc.Condition[CharacterCondition.casting] do
        Dalamud.Log("[AlliedQuests] Casting teleport...")
        yield("/wait 1")
    end
    yield("/wait 1") -- wait for that microsecond in between the cast finishing and the transition beginning
    while Svc.Condition[CharacterCondition.betweenAreas] do
        Dalamud.Log("[AlliedQuests] Teleporting...")
        yield("/wait 1")
    end
    yield("/wait 1")
end

yield("/at y")
for _, alliedSociety in ipairs(ToDoList) do
    local alliedSocietyTable = GetAlliedSocietyTable(alliedSociety.alliedSocietyName)
    if alliedSocietyTable ~= nil then
        repeat
            yield("/wait 1")
        until not Player.IsBusy

        if Svc.ClientState.TerritoryType ~= alliedSocietyTable.zoneId then
            TeleportTo(alliedSocietyTable.aetheryteName)
        end

        if not Svc.Condition[CharacterCondition.mounted] then
            yield('/gaction "mount roulette"')
        end

        repeat
            yield("/wait 1")
        until Svc.Condition[CharacterCondition.mounted]

        local destination = Vector3(alliedSocietyTable.x, alliedSocietyTable.y, alliedSocietyTable.z)
        IPC.vnavmesh.PathfindAndMoveTo(destination, true)

        repeat
            yield("/wait 1")
        until not IPC.vnavmesh.IsRunning() and not IPC.vnavmesh.PathfindInProgress()

        yield("/gs change "..alliedSociety.class)
        yield("/wait 3")

        -- pick up quests and add them to Questionables priority list
        local timeout = os.time()
        local quests = {}
        local blackList = alliedSocietyTable.dailyQuests.blackList or {}

        for questId = alliedSocietyTable.dailyQuests.first, alliedSocietyTable.dailyQuests.last do
            if not IPC.Questionable.IsQuestLocked(tostring(questId)) and not blackList[questId] then
                table.insert(quests, questId)
                IPC.Questionable.ClearQuestPriority()
                IPC.Questionable.AddQuestPriority(tostring(questId))

                repeat
                    if not IPC.Questionable.IsRunning() then
                        yield("/qst start")
                    elseif os.time() - timeout > 15 then
                        Dalamud.Log("[AlliedQuests] Took more than 15 seconds to pick up the quest. Questionable may be stuck. Reloading...")
                        yield("/qst reload")
                        timeout = os.time()
                    end
                    yield("/wait 1.1")
                until Quests.IsQuestAccepted(questId)

                timeout = os.time()
                yield("/qst stop")
            end
        end

        for _, questId in ipairs(quests) do
            IPC.Questionable.AddQuestPriority(tostring(questId))
        end

        repeat
            if not IPC.Questionable.IsRunning() then
                yield("/qst start")
            end
            yield("/wait 1.2")
        until #GetAcceptedAlliedSocietyQuests(alliedSociety.alliedSocietyName) == 0

        yield("/qst stop")
    else
        Dalamud.Log(string.format("[AlliedQuests] Allied society '%s' not found in data table.", alliedSociety.alliedSocietyName))
    end
end

Dalamud.Log("[AlliedQuests] Daily Allied Quests script completed successfully..!!")
