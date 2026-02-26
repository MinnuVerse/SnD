--[=====[
[[SND Metadata]]
author: 'pot0to (https://ko-fi.com/pot0to) || Maintainer: Minnu (https://ko-fi.com/minnuverse)'
version: 2.1.2
description: Allied Societies Quests - Script for Dailies
plugin_dependencies:
- Questionable
- vnavmesh
- Lifestream
- TextAdvance
configs:
  ManualQuestPickup:
    default: false
    description: If selected, accept quests Manually from the quest giver; otherwise Questionable handles quest acceptance.
  FirstAlliedSociety:
    description: The first allied society from which to accept quests.
    is_choice: true
    choices:
        - "None"
        - "Yok Huy"
        - "Mamool Ja"
        - "Pelupelu"
        - "Omicrons"
        - "Loporrits"
        - "Arkasodara"
        - "Dwarves"
        - "Qitari"
        - "Pixies"
        - "Namazu"
        - "Ananta"
        - "Kojin"
        - "Moogles"
        - "Vath"
        - "Vanu Vanu"
        - "Ixal (Neutral)"
        - "Ixal (Recognized)"
        - "Ixal (Friendly)"
        - "Ixal (Trusted)"
        - "Ixal (Respected)"
        - "Ixal (Honored)"
        - "Sahagin (Neutral)"
        - "Sahagin (Recognized)"
        - "Sahagin (Friendly)"
        - "Kobolds (Neutral)"
        - "Kobolds (Recognized)"
        - "Kobolds (Friendly)"
        - "Sylphs (Neutral)"
        - "Sylphs (Recognized)"
        - "Sylphs (Friendly)"
        - "Amalj'aa (Neutral)"
        - "Amalj'aa (Recognized)"
        - "Amalj'aa (Friendly)"
  FirstClass:
    description: Class to assign for first allied society.
  SecondAlliedSociety:
    description: The second allied society from which to accept quests.
    is_choice: true
    choices:
        - "None"
        - "Yok Huy"
        - "Mamool Ja"
        - "Pelupelu"
        - "Omicrons"
        - "Loporrits"
        - "Arkasodara"
        - "Dwarves"
        - "Qitari"
        - "Pixies"
        - "Namazu"
        - "Ananta"
        - "Kojin"
        - "Moogles"
        - "Vath"
        - "Vanu Vanu"
        - "Ixal (Neutral)"
        - "Ixal (Recognized)"
        - "Ixal (Friendly)"
        - "Ixal (Trusted)"
        - "Ixal (Respected)"
        - "Ixal (Honored)"
        - "Sahagin (Neutral)"
        - "Sahagin (Recognized)"
        - "Sahagin (Friendly)"
        - "Kobolds (Neutral)"
        - "Kobolds (Recognized)"
        - "Kobolds (Friendly)"
        - "Sylphs (Neutral)"
        - "Sylphs (Recognized)"
        - "Sylphs (Friendly)"
        - "Amalj'aa (Neutral)"
        - "Amalj'aa (Recognized)"
        - "Amalj'aa (Friendly)"
  SecondClass:
    description: Class to assign for second allied society.
  ThirdAlliedSociety:
    description: The third allied society from which to accept quests.
    is_choice: true
    choices:
        - "None"
        - "Yok Huy"
        - "Mamool Ja"
        - "Pelupelu"
        - "Omicrons"
        - "Loporrits"
        - "Arkasodara"
        - "Dwarves"
        - "Qitari"
        - "Pixies"
        - "Namazu"
        - "Ananta"
        - "Kojin"
        - "Moogles"
        - "Vath"
        - "Vanu Vanu"
        - "Ixal (Neutral)"
        - "Ixal (Recognized)"
        - "Ixal (Friendly)"
        - "Ixal (Trusted)"
        - "Ixal (Respected)"
        - "Ixal (Honored)"
        - "Sahagin (Neutral)"
        - "Sahagin (Recognized)"
        - "Sahagin (Friendly)"
        - "Kobolds (Neutral)"
        - "Kobolds (Recognized)"
        - "Kobolds (Friendly)"
        - "Sylphs (Neutral)"
        - "Sylphs (Recognized)"
        - "Sylphs (Friendly)"
        - "Amalj'aa (Neutral)"
        - "Amalj'aa (Recognized)"
        - "Amalj'aa (Friendly)"
  ThirdClass:
    description: Class to assign for third allied society.
  FourthAlliedSociety:
    description: The fourth allied society from which to accept quests.
    is_choice: true
    choices:
        - "None"
        - "Yok Huy"
        - "Mamool Ja"
        - "Pelupelu"
        - "Omicrons"
        - "Loporrits"
        - "Arkasodara"
        - "Dwarves"
        - "Qitari"
        - "Pixies"
        - "Namazu"
        - "Ananta"
        - "Kojin"
        - "Moogles"
        - "Vath"
        - "Vanu Vanu"
        - "Ixal (Neutral)"
        - "Ixal (Recognized)"
        - "Ixal (Friendly)"
        - "Ixal (Trusted)"
        - "Ixal (Respected)"
        - "Ixal (Honored)"
        - "Sahagin (Neutral)"
        - "Sahagin (Recognized)"
        - "Sahagin (Friendly)"
        - "Kobolds (Neutral)"
        - "Kobolds (Recognized)"
        - "Kobolds (Friendly)"
        - "Sylphs (Neutral)"
        - "Sylphs (Recognized)"
        - "Sylphs (Friendly)"
        - "Amalj'aa (Neutral)"
        - "Amalj'aa (Recognized)"
        - "Amalj'aa (Friendly)"
  FourthClass:
    description: Class to assign for fourth allied society.

[[End Metadata]]
--]=====]

--[[
********************************************************************************
*                           Allied Society Quests                              *
*                               Version 2.1.2                                  *
********************************************************************************
Created by: pot0to (https://ko-fi.com/pot0to)
Updated by: Minnu

Goes around to the specified beast tribes, picks up 3 quests, does them, and
moves on to the next beast tribe.

    -> 2.1.2    Added rank-specific quest giver support for ARR beast tribes
    -> 2.1.1    Fix for grabbing quests when ManualQuestPickup is off
    -> 2.1.0    Multi Language Support (credit: Valgrifer)
    -> 2.0.3    Added Yok Huy for patch 7.35
    -> 2.0.2    Added option for Manual Quest Handling
                Added dropdowns for AlliedSociety
    -> 2.0.1    Updated for Patch 7.3
    -> 2.0.0    Updated to SND v2
    -> 0.2.1    Fixed Mamool Ja name and removed main quests from presets
    -> 0.2.0    Added Mamool Jas for patch 7.25 (credit: Leonhart)
    -> 0.1.3    Fixed "Arkasodara" tribe name
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
ManualQuestPickup = Config.Get("ManualQuestPickup")

local societyConfigKeys = {
    { societyKey = "FirstAlliedSociety",  classKey = "FirstClass"  },
    { societyKey = "SecondAlliedSociety", classKey = "SecondClass" },
    { societyKey = "ThirdAlliedSociety",  classKey = "ThirdClass"  },
    { societyKey = "FourthAlliedSociety", classKey = "FourthClass" }
}

for _, entry in ipairs(societyConfigKeys) do
    local society = Config.Get(entry.societyKey)
    local class   = Config.Get(entry.classKey)

    if type(society) == "string" then
        society = society:gsub("^%s+", ""):gsub("%s+$", "")
    end
    if type(class) == "string" then
        class = class:gsub("^%s+", ""):gsub("%s+$", "")
    end

    if society and class and society ~= "" and society ~= "None" and class ~= "" then
        table.insert(ToDoList, { alliedSocietyName = society, class = class })
    end
end

function GetAttribute(sheetName, id, property)
    local sheet = Excel.GetSheet(sheetName)
    if not sheet then
        return nil
    end

    local row = sheet:GetRow(id)
    if not row then
        return nil
    end

    return row:GetProperty(property) or nil
end

function GetNPCName(id)
    return GetAttribute("ENpcResident", id, "Singular")
end

function GetPlaceName(id)
    return GetAttribute("PlaceName", id, "Name")
end

AlliedSocietiesTable = {
    amaljaa_neutral = {
        alliedSocietyName = "Amalj'aa",
        configName        = "Amalj'aa (Neutral)",
        questGiver        = GetNPCName(1005550), -- "Fibubb Gah"
        mainQuests        = { first = 1217, last = 1221 },
        dailyQuests       = { first = 1222, last = 1231 },
        x                 = 103.12,
        y                 = 15.05,
        z                 = -359.51,
        zoneId            = 146,
        aetheryteName     = GetPlaceName(313), -- "Little Ala Mhigo"
        expac             = "A Realm Reborn"
    },
    amaljaa_recognized = {
        alliedSocietyName = "Amalj'aa",
        configName        = "Amalj'aa (Recognized)",
        questGiver        = GetNPCName(1005551), -- "Narujj Boh"
        mainQuests        = { first = 1217, last = 1221 },
        dailyQuests       = { first = 1232, last = 1241 },
        x                 = 96.38,
        y                 = 15.29,
        z                 = -353.32,
        zoneId            = 146,
        aetheryteName     = GetPlaceName(313), -- "Little Ala Mhigo"
        expac             = "A Realm Reborn"
    },
    amaljaa_friendly = {
        alliedSocietyName = "Amalj'aa",
        configName        = "Amalj'aa (Friendly)",
        questGiver        = GetNPCName(1005552), -- "Yadovv Gah"
        mainQuests        = { first = 1217, last = 1221 },
        dailyQuests       = { first = 1242, last = 1251, blackList = { [1245] = true, [1250] = true } },
        x                 = 89.26,
        y                 = 15.23,
        z                 = -355.76,
        zoneId            = 146,
        aetheryteName     = GetPlaceName(313), -- "Little Ala Mhigo"
        expac             = "A Realm Reborn"
    },
    sylphs_neutral = {
        alliedSocietyName = "Sylphs",
        configName        = "Sylphs (Neutral)",
        questGiver        = GetNPCName(1005561), -- "Tonaxia"
        mainQuests        = { first = 1252, last = 1256 },
        dailyQuests       = { first = 1257, last = 1266, blackList = { [1264] = true } },
        x                 = 46.41,
        y                 = 6.07,
        z                 = 252.91,
        zoneId            = 152,
        aetheryteName     = GetPlaceName(107), -- "The Hawthorne Hut"
        expac             = "A Realm Reborn"
    },
    sylphs_recognized = {
        alliedSocietyName = "Sylphs",
        configName        = "Sylphs (Recognized)",
        questGiver        = GetNPCName(1005562), -- "Ponnixia"
        mainQuests        = { first = 1252, last = 1256 },
        dailyQuests       = { first = 1267, last = 1276 },
        x                 = 35.69,
        y                 = -5.11,
        z                 = 249.86,
        zoneId            = 152,
        aetheryteName     = GetPlaceName(107), -- "The Hawthorne Hut"
        expac             = "A Realm Reborn"
    },
    sylphs_friendly = {
        alliedSocietyName = "Sylphs",
        configName        = "Sylphs (Friendly)",
        questGiver        = GetNPCName(1005563), -- "Moxia"
        mainQuests        = { first = 1252, last = 1256 },
        dailyQuests       = { first = 1277, last = 1286, blackList = { [1284] = true } },
        x                 = 47.18,
        y                 = 6.07,
        z                 = 250.81,
        zoneId            = 152,
        aetheryteName     = GetPlaceName(107), -- "The Hawthorne Hut"
        expac             = "A Realm Reborn"
    },
    kobolds_neutral = {
        alliedSocietyName = "Kobolds",
        configName        = "Kobolds (Neutral)",
        questGiver        = GetNPCName(1005928), -- "789th Order Dustman Bo Zu"
        mainQuests        = { first = 1320, last = 1324 },
        dailyQuests       = { first = 1325, last = 1334 },
        x                 = 11.13,
        y                 = 16.16,
        z                 = -187.70,
        zoneId            = 180,
        aetheryteName     = GetPlaceName(237), -- "Camp Overlook"
        expac             = "A Realm Reborn"
    },
    kobolds_recognized = {
        alliedSocietyName = "Kobolds",
        configName        = "Kobolds (Recognized)",
        questGiver        = GetNPCName(1005929), -- "789th Order Craftsman Bo Gu"
        mainQuests        = { first = 1320, last = 1324 },
        dailyQuests       = { first = 1335, last = 1344, blackList = { [1336] = true } },
        x                 = 18.71,
        y                 = 16.16,
        z                 = -184.34,
        zoneId            = 180,
        aetheryteName     = GetPlaceName(237), -- "Camp Overlook"
        expac             = "A Realm Reborn"
    },
    kobolds_friendly = {
        alliedSocietyName = "Kobolds",
        configName        = "Kobolds (Friendly)",
        questGiver        = GetNPCName(1005930), -- "789th Order Dustman Bo Bu"
        mainQuests        = { first = 1320, last = 1324 },
        dailyQuests       = { first = 1364, last = 1373, blackList = { [1364] = true, [1372] = true } },
        x                 = 12.24,
        y                 = 16.16,
        z                 = -179.64,
        zoneId            = 180,
        aetheryteName     = GetPlaceName(237), -- "Camp Overlook"
        expac             = "A Realm Reborn"
    },
    sahagin_neutral = {
        alliedSocietyName = "Sahagin",
        configName        = "Sahagin (Neutral)",
        questGiver        = GetNPCName(1005938), -- "Fyuu"
        mainQuests        = { first = 1374, last = 1378 },
        dailyQuests       = { first = 1379, last = 1388, blackList = { [1379] = true } },
        x                 = -221.98,
        y                 = -40.86,
        z                 = 35.61,
        zoneId            = 138,
        aetheryteName     = GetPlaceName(223), -- "Aleport"
        expac             = "A Realm Reborn"
    },
    sahagin_recognized = {
        alliedSocietyName = "Sahagin",
        configName        = "Sahagin (Recognized)",
        questGiver        = GetNPCName(1005939), -- "Houu"
        mainQuests        = { first = 1374, last = 1378 },
        dailyQuests       = { first = 1390, last = 1399, blackList = { [1396] = true } },
        x                 = -244.53,
        y                 = -41.46,
        z                 = 52.75,
        zoneId            = 138,
        aetheryteName     = GetPlaceName(223), -- "Aleport"
        expac             = "A Realm Reborn"
    },
    sahagin_friendly = {
        alliedSocietyName = "Sahagin",
        configName        = "Sahagin (Friendly)",
        questGiver        = GetNPCName(1005940), -- "Seww"
        mainQuests        = { first = 1374, last = 1378 },
        dailyQuests       = { first = 1400, last = 1409, blackList = { [1409] = true } },
        x                 = -229.13,
        y                 = -40.48,
        z                 = 55.17,
        zoneId            = 138,
        aetheryteName     = GetPlaceName(223), -- "Aleport"
        expac             = "A Realm Reborn"
    },
    ixal_neutral = {
        alliedSocietyName = "Ixal",
        configName        = "Ixal (Neutral)",
        questGiver        = GetNPCName(1009211), -- "Yazel Ahuatan the Able"
        mainQuests        = { first = 1486, last = 1493 },
        dailyQuests       = { first = 1494, last = 1497 },
        x                 = 155.02,
        y                 = -9.35,
        z                 = 79.24,
        zoneId            = 154,
        aetheryteName     = GetPlaceName(140), -- "Fallgourd Float"
        expac             = "A Realm Reborn"
    },
    ixal_recognized = {
        alliedSocietyName = "Ixal",
        configName        = "Ixal (Recognized)",
        questGiver        = GetNPCName(1009212), -- "Methuli Cattlan the Hard"
        mainQuests        = { first = 1486, last = 1493 },
        dailyQuests       = { first = 1504, last = 1508 },
        x                 = 153.60,
        y                 = -9.94,
        z                 = 80.95,
        zoneId            = 154,
        aetheryteName     = GetPlaceName(140), -- "Fallgourd Float"
        expac             = "A Realm Reborn"
    },
    ixal_friendly = {
        alliedSocietyName = "Ixal",
        configName        = "Ixal (Friendly)",
        questGiver        = GetNPCName(1009213), -- "Rozol Cattlan the Prudent"
        mainQuests        = { first = 1486, last = 1493 },
        dailyQuests       = { first = 1514, last = 1518 },
        x                 = 162.86,
        y                 = -4.69,
        z                 = 63.50,
        zoneId            = 154,
        aetheryteName     = GetPlaceName(140), -- "Fallgourd Float"
        expac             = "A Realm Reborn"
    },
    ixal_trusted = {
        alliedSocietyName = "Ixal",
        configName        = "Ixal (Trusted)",
        questGiver        = GetNPCName(1009216), -- "Jezul Ahuatan the Second"
        mainQuests        = { first = 1486, last = 1493 },
        dailyQuests       = { first = 1498, last = 1503 },
        x                 = 161.42,
        y                 = -22.79,
        z                 = 115.27,
        zoneId            = 154,
        aetheryteName     = GetPlaceName(140), -- "Fallgourd Float"
        expac             = "A Realm Reborn"
    },
    ixal_respected = {
        alliedSocietyName = "Ixal",
        configName        = "Ixal (Respected)",
        questGiver        = GetNPCName(1009215), -- "Duzal Meyean the Steady"
        mainQuests        = { first = 1486, last = 1493 },
        dailyQuests       = { first = 1509, last = 1513 },
        x                 = 166.90,
        y                 = -13.60,
        z                 = 106.83,
        zoneId            = 154,
        aetheryteName     = GetPlaceName(140), -- "Fallgourd Float"
        expac             = "A Realm Reborn"
    },
    ixal_honored = {
        alliedSocietyName = "Ixal",
        configName        = "Ixal (Honored)",
        questGiver        = GetNPCName(1009216), -- "Jezul Ahuatan the Second"
        mainQuests        = { first = 1486, last = 1493 },
        dailyQuests       = { first = 1519, last = 1523 },
        x                 = 161.42,
        y                 = -22.79,
        z                 = 115.27,
        zoneId            = 154,
        aetheryteName     = GetPlaceName(140), -- "Fallgourd Float"
        expac             = "A Realm Reborn"
    },
    vanuvanu = {
        alliedSocietyName = "Vanu Vanu",
        questGiver        = GetNPCName(1016089), -- "Muna Vanu"
        mainQuests        = { first = 2164, last = 2225 },
        dailyQuests       = { first = 2171, last = 2200 },
        x                 = -796.3722,
        y                 = -133.27,
        z                 = -404.35,
        zoneId            = 401,
        aetheryteName     = GetPlaceName(2123), -- "Ok' Zundu"
        expac             = "Heavensward"
    },
    vath = {
        alliedSocietyName = "Vath",
        questGiver        = GetNPCName(1016803), -- "Vath Keeneye"
        mainQuests        = { first = 2255, last = 2260 },
        dailyQuests       = { first = 2261, last = 2280 },
        x                 = 58.80,
        y                 = -48.00,
        z                 = -171.64,
        zoneId            = 398,
        aetheryteName     = GetPlaceName(2018), -- "Tailfeather"
        expac             = "Heavensward"
    },
    moogles = {
        alliedSocietyName = "Moogles",
        questGiver        = GetNPCName(1017171), -- "Mogek the Marvelous"
        mainQuests        = { first = 2320, last = 2327 },
        dailyQuests       = { first = 2290, last = 2319 },
        x                 = -335.28,
        y                 = 58.94,
        z                 = 316.30,
        zoneId            = 400,
        aetheryteName     = GetPlaceName(2046), -- "Zenith"
        expac             = "Heavensward"
    },
    kojin = {
        alliedSocietyName = "Kojin",
        questGiver        = GetNPCName(1024217), -- "Zukin"
        mainQuests        = { first = 2973, last = 2978 },
        dailyQuests       = { first = 2979, last = 3002 },
        x                 = 391.22,
        y                 = -119.59,
        z                 = -234.92,
        zoneId            = 613,
        aetheryteName     = GetPlaceName(2512), -- "Tamamizu"
        expac             = "Stormblood"
    },
    ananta = {
        alliedSocietyName = "Ananta",
        questGiver        = GetNPCName(1024773), -- "Eshana"
        mainQuests        = { first = 3036, last = 3041 },
        dailyQuests       = { first = 3043, last = 3069 },
        x                 = -26.91,
        y                 = 56.12,
        z                 = 233.53,
        zoneId            = 612,
        aetheryteName     = GetPlaceName(2634), -- "The Peering Stones"
        expac             = "Stormblood"
    },
    namazu = {
        alliedSocietyName = "Namazu",
        questGiver        = GetNPCName(1025602), -- "Seigetsu the Enlightened"
        mainQuests        = { first = 3096, last = 3102 },
        dailyQuests       = { first = 3103, last = 3129 },
        x                 = -777.72,
        y                 = 127.81,
        z                 = 98.76,
        zoneId            = 622,
        aetheryteName     = GetPlaceName(2850), -- "Dhoro Iloh"
        expac             = "Stormblood"
    },
    pixies = {
        alliedSocietyName = "Pixies",
        questGiver        = GetNPCName(1031809), -- "Uin Nee"
        mainQuests        = { first = 3683, last = 3688 },
        dailyQuests       = { first = 3689, last = 3716 },
        x                 = -453.69,
        y                 = 71.21,
        z                 = 573.54,
        zoneId            = 816,
        aetheryteName     = GetPlaceName(3147), -- "Lydha Lran"
        expac             = "Shadowbringers"
    },
    qitari = {
        alliedSocietyName = "Qitari",
        questGiver        = GetNPCName(1032643), -- "Qhoterl Pasol"
        mainQuests        = { first = 3794, last = 3805 },
        dailyQuests       = { first = 3806, last = 3833 },
        x                 = 786.83,
        y                 = -45.82,
        z                 = -214.51,
        zoneId            = 817,
        aetheryteName     = GetPlaceName(3179), -- "Fanow"
        expac             = "Shadowbringers"
    },
    dwarves = {
        alliedSocietyName = "Dwarves",
        questGiver        = GetNPCName(1033712), -- "Regitt"
        mainQuests        = { first = 3896, last = 3901 },
        dailyQuests       = { first = 3902, last = 3929 },
        x                 = -615.48,
        y                 = 65.60,
        z                 = -423.82,
        zoneId            = 813,
        aetheryteName     = GetPlaceName(3057), -- "The Ostall Imperative"
        expac             = "Shadowbringers"
    },
    arkosodara = {
        alliedSocietyName = "Arkasodara",
        questGiver        = GetNPCName(1042257), -- "Maru"
        mainQuests        = { first = 4545, last = 4550 },
        dailyQuests       = { first = 4551, last = 4578 },
        x                 = -68.21,
        y                 = 39.99,
        z                 = 323.31,
        zoneId            = 957,
        aetheryteName     = GetPlaceName(3880), -- "Yedlihmad"
        expac             = "Endwalker"
    },
    loporrits = {
        alliedSocietyName = "Loporrits",
        questGiver        = GetNPCName(1044403), -- "Managingway"
        mainQuests        = { first = 4681, last = 4686 },
        dailyQuests       = { first = 4687, last = 4714 },
        x                 = -201.27,
        y                 = -49.15,
        z                 = -273.8,
        zoneId            = 959,
        aetheryteName     = GetPlaceName(3966), -- "Bestways Burrow"
        expac             = "Endwalker"
    },
    omicrons = {
        alliedSocietyName = "Omicrons",
        questGiver        = GetNPCName(1041898), -- "Stigma-4"
        mainQuests        = { first = 4601, last = 4606 },
        dailyQuests       = { first = 4607, last = 4634 },
        x                 = 315.84,
        y                 = 481.99,
        z                 = 152.08,
        zoneId            = 960,
        aetheryteName     = GetPlaceName(3983), -- "Base Omicron"
        expac             = "Endwalker"
    },
    pelupelu = {
        alliedSocietyName = "Pelupelu",
        questGiver        = GetNPCName(1051643), -- "Yubli"
        mainQuests        = { first = 5193, last = 5198 },
        dailyQuests       = { first = 5199, last = 5226 },
        x                 = 770.89954,
        y                 = 12.846571,
        z                 = -261.0889,
        zoneId            = 1188,
        aetheryteName     = GetPlaceName(4595), -- "Dock Poga"
        expac             = "Dawntrail"
    },
    mamoolja = {
        alliedSocietyName = "Mamool Ja",
        questGiver        = GetNPCName(1052560), -- "Kageel Ja"
        mainQuests        = { first = 5255, last = 5260 },
        dailyQuests       = { first = 5261, last = 5288 },
        x                 = 589.3,
        y                 = -142.9,
        z                 = 730.5,
        zoneId            = 1189,
        aetheryteName     = GetPlaceName(4625), -- "Mamook"
        expac             = "Dawntrail"
    },
    yokhuy = {
        alliedSocietyName = "Yok Huy",
        questGiver        = GetNPCName(1054635), -- "Vuyargur"
        mainQuests        = { first = 5330, last = 5335 },
        dailyQuests       = { first = 5336, last = 5363 },
        x                 = 495.40,
        y                 = 142.24,
        z                 = 784.53,
        zoneId            = 1187,
        aetheryteName     = GetPlaceName(4562), -- "Worlar's Echo"
        expac             = "Dawntrail"
    }
}

CharacterCondition = {
    mounted          =  4,
    casting          = 27,
    betweenAreas     = 45
}

function GetAlliedSocietyTable(selectedName)
    for _, alliedSociety in pairs(AlliedSocietiesTable) do
        if alliedSociety.configName and alliedSociety.configName == selectedName then
            return alliedSociety
        end
        if alliedSociety.alliedSocietyName == selectedName then
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

        if row and row.BeastTribe and row.BeastTribe.Name and row.BeastTribe.Name:lower() == alliedSocietyName:lower() then
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
    yield("/wait 1")
    while Svc.Condition[CharacterCondition.casting] do
        Dalamud.Log("[AlliedQuests] Casting teleport...")
        yield("/wait 1")
    end
    yield("/wait 1")
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
            Actions.ExecuteGeneralAction(9) -- '/gaction "mount roulette"'
        end

        repeat
            yield("/wait 1")
        until Svc.Condition[CharacterCondition.mounted]

        local destination = Vector3(alliedSocietyTable.x, alliedSocietyTable.y, alliedSocietyTable.z)
        IPC.vnavmesh.PathfindAndMoveTo(destination, true)

        repeat
            yield("/wait 1")
        until not IPC.vnavmesh.IsRunning() and not IPC.vnavmesh.PathfindInProgress()

        yield("/gs change " .. alliedSociety.class)
        yield("/wait 3")

        if ManualQuestPickup then
            for i = 1, 3 do
                yield("/target " .. alliedSocietyTable.questGiver)
                yield("/interact")

                repeat
                    yield("/wait 1")
                until Addons.GetAddon("SelectIconString").Ready
                yield("/callback SelectIconString true 0")
                repeat
                    yield("/wait 1")
                until not Player.IsBusy
                Dalamud.Log(string.format("[AlliedQuests] Accepted %d/3 quest(s) via quest giver.", i))
            end
        else
            local timeout = os.time()
            local quests = {}
            local blackList = alliedSocietyTable.dailyQuests.blackList or {}
            local acceptedCount = 0

            for questId = alliedSocietyTable.dailyQuests.first, alliedSocietyTable.dailyQuests.last do
                if not IPC.Questionable.IsQuestLocked(tostring(questId)) and not blackList[questId] then
                    table.insert(quests, questId)
                    IPC.Questionable.ClearQuestPriority()
                    IPC.Questionable.AddQuestPriority(tostring(questId))

                    repeat
                        if not IPC.Questionable.IsRunning() then
                            yield("/qst start")
                        elseif Svc.Condition[CharacterCondition.casting] then
                            yield("/vnav movedir 0 0 0.5")  -- Small movement to cancel any active cast
                        elseif IPC.vnavmesh.IsRunning() then
                            IPC.vnavmesh.Stop()
                        elseif os.time() - timeout > 15 then
                            Dalamud.Log("[AlliedQuests] Took more than 15 seconds to pick up the quest. Questionable may be stuck. Reloading...")
                            yield("/qst reload")
                            timeout = os.time()
                        end
                        yield("/wait 0.1")
                    until Quests.IsQuestAccepted(questId)

                    acceptedCount = acceptedCount + 1
                    Dalamud.Log(string.format("[AlliedQuests] Accepted %d/3 quest(s) via Questionable.", acceptedCount))

                    timeout = os.time()
                    yield("/qst stop")
                end
            end

            for _, questId in ipairs(quests) do
                IPC.Questionable.AddQuestPriority(tostring(questId))
            end
        end

        repeat
            if not IPC.Questionable.IsRunning() then
                yield("/qst start")
            end
            yield("/wait 1.2")
        until #GetAcceptedAlliedSocietyQuests(alliedSocietyTable.alliedSocietyName) == 0

        yield("/qst stop")
    else
        Dalamud.Log(string.format("[AlliedQuests] Allied society '%s' not found in data table.", alliedSociety.alliedSocietyName))
    end
end

yield("/echo [AlliedQuests] Daily Allied Quests script completed successfully..!!")
Dalamud.Log("[AlliedQuests] Daily Allied Quests script completed successfully..!!")