--[=====[
[[SND Metadata]]
author: Minnu (https://ko-fi.com/minnuverse)
version: 2.2.0
description: BigFish (DT) - Automates catching newly-tracked Dawntrail Big Fish.
plugin_dependencies:
- AutoHook
- Lifestream
- vnavmesh
configs:
  RetryCooldownSeconds:
    description: Seconds to wait before retrying the same fish after an unsuccessful attempt.
    default: 10
    min: 10
    max: 600
  CaughtCooldownSeconds:
    description: |
      Seconds to wait before retrying a fish you've already caught this window.
      Should comfortably outlast its time/weather window so it doesn't get
      reselected and refished while the window is still open.
    default: 3600
    min: 60
    max: 7200
  ForceQuitDelaySeconds:
    description: |
      Seconds to keep fishing/gathering after a fish's window closes before
      forcing a quit. Gives an active bite/catch time to finish instead of
      cutting it off the instant the window closes.
    default: 15
    min: 0
    max: 120
  SwimBaitPrepSeconds:
    description: |
      For fish with swimBait = true, how many seconds early to head to the
      spot once idle and begin fishing before the real window opens.
      This lets AutoHook work the prep period for swim bait automatically.
      Only kicks in when no other fish window is currently open.
    default: 600
    min: 0
    max: 1800
  SkipFishWithoutPreset:
    description: |
      When enabled, fish with no exported AutoHook preset are skipped instead
      of falling back to a named preset. Ignored when UseNamedAutoHookPreset
      is enabled. For fish missing exported presets in this script, ensure
      matching fish-name presets exist in AutoHook before disabling.
    default: true
  UseNamedAutoHookPreset:
    description: |
      When enabled, always select the named AutoHook preset matching the fish
      name, even if the fish has an exported anonymous autoHookPreset string.
      Ensure matching fish-name presets exist in AutoHook before enabling.
    default: false
  UseIdleTeleport:
    description: |
      When enabled, uses Teleport("auto") once when no fish window is
      available. Configure the auto destination in Lifestream.
    default: true
  EnabledFish:
    description: |
      A list of fish names to restrict the rotation to.
      Enter the exact fish name and press enter. One fish per line.
      When non-empty, this overrides DisabledFish and only these fish are attempted.
      Leave empty to run the full rotation.
    default: []
  DisabledFish:
    description: |
      A list of fish names to skip entirely.
      Enter the exact fish name and press enter. One fish per line.
      Use this to manually remove fish from rotation after you catch them.
    default: []

[[End Metadata]]
--]=====]

--========================== DEPENDENCIES ========================--

import("System")
import("System.Numerics")

--=========================== VARIABLES ==========================--

-------------------
--    General    --
-------------------

RetryCooldownSeconds      = Config.Get("RetryCooldownSeconds")
CaughtCooldownSeconds     = Config.Get("CaughtCooldownSeconds")
SkipFishWithoutPreset     = Config.Get("SkipFishWithoutPreset")
UseNamedAutoHookPreset    = Config.Get("UseNamedAutoHookPreset")
UseIdleTeleport           = Config.Get("UseIdleTeleport")
ForceQuitDelaySeconds     = Config.Get("ForceQuitDelaySeconds")
SwimBaitPrepSeconds       = Config.Get("SwimBaitPrepSeconds")
LogPrefix                 = "[BigFish]"

local idleHoldoff      = 60

local lastAttempt      = {}
local disabledFish     = {}
local enabledFish      = {}
local baitItemIds      = {}
local missingBaitLog   = {}
local unknownFishLog   = {}
local fishDataNames    = nil

local loggedIdle       = false
local idleTeleported   = false
local loggedIdleBusy   = false
local fishingStarted   = false
local catchDetected    = false
local catchMessage     = nil
local forcedQuit       = false
local windowClosedAt   = nil
local windowOpenedAt   = false
local baitChecksReady  = false

--============================ CONSTANT ===========================--

------------------
--    Action    --
------------------

CharacterAction = {
    Actions = {
        quitFishing        =    299,
    },
    GeneralActions = {
        mount              =      9,
        dismount           =     23,
    }
}

---------------------
--    Condition    --
---------------------

CharacterCondition = {
    mounted                 =  4,
    gathering               =  6,
    fishing                 = 43,
    betweenAreas            = 45,
}

-------------------
--    Weather    --
-------------------

WeatherName = {
    [1]   = "Clear Skies",
    [2]   = "Fair Skies",
    [3]   = "Clouds",
    [4]   = "Fog",
    [5]   = "Wind",
    [6]   = "Gales",
    [7]   = "Rain",
    [8]   = "Showers",
    [9]   = "Thunder",
    [10]  = "Thunderstorms",
    [11]  = "Dust Storms",
    [15]  = "Snow",
    [49]  = "Umbral Wind",
    [50]  = "Umbral Static",
    [149] = "Astromagnetic Storms",
}

EorzeaWeatherRates = {
    [1189] = {{1, 15}, {2, 55}, {3, 70}, {4, 85}, {7, 100}},                    -- Yak T'el
    [1188] = {{1, 25}, {2, 60}, {3, 75}, {4, 85}, {7, 95}, {8, 100}},           -- Kozama'uka
    [1192] = {{7, 10}, {4, 20}, {3, 40}, {2, 100}},                             -- Living Memory
    [1185] = {{1, 40}, {2, 80}, {3, 85}, {4, 95}, {7, 100}},                    -- Tuliyollal
    [1191] = {{2, 5}, {3, 25}, {4, 40}, {7, 45}, {10, 50}, {50, 100}},          -- Heritage Found
    [1190] = {{1, 5}, {2, 50}, {3, 70}, {11, 85}, {6, 100}},                    -- Shaaloani
    [1187] = {{1, 20}, {2, 50}, {3, 70}, {4, 80}, {5, 90}, {15, 100}},          -- Urqopacha
    [1186] = {{2, 100}},                                                        -- Solution Nine
}

----------------------------
--    State Management    --
----------------------------

CharacterState = {}

-----------------
--    Baits    --
-----------------

BaitItemIds = {
    ["Crimson Lugworm"]       = 43850,
    ["Golden Stonefly Nymph"] = 43849,
    ["Honeybee"]              = 43852,
    ["White Worm"]            = 43854,
    ["Popper Lure"]           = 43855,
    ["Dragonfly"]             = 43857,
    ["Red Maggots"]           = 43858,
    ["Ghost Nipper"]          = 43859,
}

--------------------
--    Big Fish    --
--------------------

FishData = {
    {
        name            = "Autarch's Supper",
        expansion       = "Dawntrail",
        zone            = "Yak T'el",
        zoneId          = 1189,
        aetheryte       = "Mamook",
        spotName        = "Sapsweet Cenote",
        time            = "16:00-18:00",
        weather         = "Fog",
        previousWeather = "Rain",
        bait            = "Red Maggots",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 35.0, y = 32.7, radius = 1000,
        worldX = 653.68, worldY = -179.30, worldZ = 652.96,
        fishX = 663.30, fishY = -181.52, fishZ = 654.16,
    },
    {
        name            = "Awaksbane Apoda",
        expansion       = "Dawntrail",
        zone            = "Yak T'el",
        zoneId          = 1189,
        aetheryte       = "Iq Br'aax",
        spotName        = "Yak Awak Tsoly",
        time            = "0:00-24:00",
        weather         = "Clouds, Fog",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 19.1, y = 8.8, radius = 800,
        worldX = -54.94, worldY = 7.92, worldZ = -545.20,
        fishX = -52.66, fishY = 8.06, fishZ = -558.52,
    },
    {
        name            = "Azure Diver",
        expansion       = "Dawntrail",
        zone            = "Shaaloani",
        zoneId          = 1190,
        aetheryte       = "Hhusatahwi",
        spotName        = "Eastbound Zorgor",
        time            = "18:00-24:00",
        weather         = "Gales",
        previousWeather = "Clear Skies, Fair Skies",
        bait            = "Dragonfly",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 33.1, y = 38.2, radius = 1000,
        worldX = 483.57, worldY = 16.83, worldZ = 648.66,
        fishX = 491.44, fishY = 13.32, fishZ = 663.55,
    },
    {
        name            = "Bitterbark Caiman",
        expansion       = "Dawntrail",
        zone            = "Yak T'el",
        zoneId          = 1189,
        aetheryte       = "Mamook",
        spotName        = "Bitterbark Cenote",
        time            = "16:00-18:00",
        weather         = "Clear Skies",
        previousWeather = "Fog",
        bait            = "Red Maggots",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 25.5, y = 39.0, radius = 800,
        worldX = 200.18, worldY = -149.74, worldZ = 823.89,
        fishX = 209.39, fishY = -151.05, fishZ = 842.45,
    },
    {
        name            = "Cabinkeep Permit",
        expansion       = "Dawntrail",
        zone            = "Tuliyollal",
        zoneId          = 1185,
        aetheryte       = "The For'ard Cabins",
        spotName        = "The For'ard Cabins",
        time            = "5:00-7:00",
        weather         = "",
        previousWeather = "",
        bait            = "Ghost Nipper",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 10.7, y = 15.3, radius = 1000,
        worldX = -157.30, worldY = -15.00, worldZ = 371.47,
        fishX = -152.05, fishY = -15.00, fishZ = 372.92,
    },
    {
        name            = "Cazuela Crab",
        expansion       = "Dawntrail",
        zone            = "Kozama'uka",
        zoneId          = 1188,
        aetheryte       = "Ok'hanu",
        spotName        = "Waters Hanu",
        time            = "16:00-20:00",
        weather         = "Clouds, Fog",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 22.9, y = 12.9, radius = 1200,
        worldX = 72.31, worldY = 0.47, worldZ = -428.35,
        fishX = 63.18, fishY = -0.40, fishZ = -428.09,
    },
    {
        name            = "Crenicichla Miyaka",
        expansion       = "Dawntrail",
        zone            = "Kozama'uka",
        zoneId          = 1188,
        aetheryte       = "Ok'Hanu",
        spotName        = "The Dewspun Bank",
        time            = "6:00-8:00",
        weather         = "Rain",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 37.9, y = 33.3, radius = 600,
        worldX = 793.78, worldY = 114.62, worldZ = 558.97,
        fishX = 802.58, fishY = 114.62, fishZ = 566.75,
    },
    {
        name            = "Datnioides Aeroplanos",
        expansion       = "Dawntrail",
        zone            = "Living Memory",
        zoneId          = 1192,
        aetheryte       = "Leynode Aero",
        spotName        = "Leynode Aero",
        time            = "2:00-4:00",
        weather         = "Rain",
        previousWeather = "Fog",
        bait            = "Red Maggots",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 16.2, y = 13.2, radius = 600,
        worldX = -182.92, worldY = 31.82, worldZ = -376.60,
        fishX = -190.89, fishY = 31.20, fishZ = -383.58,
    },
    {
        name            = "Deep Canopy",
        expansion       = "Dawntrail",
        zone            = "Yak T'el",
        zoneId          = 1189,
        aetheryte       = "Iq Br'aax",
        spotName        = "Iq Br'aax Reservoir",
        time            = "10:00-12:00",
        weather         = "",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 13.7, y = 12.7, radius = 500,
        worldX = -438.47, worldY = 18.05, worldZ = -391.69,
    },
    {
        name            = "Esperance Carp",
        expansion       = "Dawntrail",
        zone            = "Living Memory",
        zoneId          = 1192,
        aetheryte       = "Leynode Pyro",
        spotName        = "Proto Alexandria",
        time            = "22:00-24:00",
        weather         = "Clouds",
        previousWeather = "Rain",
        bait            = "Red Maggots",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 38.5, y = 31.6, radius = 500,
        worldX = 814.81, worldY = 8.57, worldZ = 487.09,
        fishX = 822.63, fishY = 7.68, fishZ = 495.99,
    },
    {
        name            = "Excavator Catfish",
        expansion       = "Dawntrail",
        zone            = "Kozama'uka",
        zoneId          = 1188,
        aetheryte       = "Many Fires",
        spotName        = "Marsh Ligaka",
        time            = "4:00-6:00",
        weather         = "Clouds",
        previousWeather = "Rain",
        bait            = "Popper Lure",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 25.8, y = 31.6, radius = 800,
        worldX = 150.32, worldY = 115.40, worldZ = 528.67,
        fishX = 169.07, fishY = 109.77, fishZ = 525.83,
    },
    {
        name            = "Gigagiant Snakehead",
        expansion       = "Dawntrail",
        zone            = "Living Memory",
        zoneId          = 1192,
        aetheryte       = "Leynode Aero",
        spotName        = "Mu Springs Eternal",
        time            = "4:00-6:00",
        weather         = "Rain",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 12.6, y = 11.5, radius = 300,
        worldX = -433.48, worldY = -5.00, worldZ = -524.62,
        fishX = -436.41, fishY = -5.27, fishZ = -514.38,
    },
    {
        name            = "Gondola Louvar",
        expansion       = "Dawntrail",
        zone            = "Living Memory",
        zoneId          = 1192,
        aetheryte       = "Leynode Mnemo",
        spotName        = "Canal Town South",
        time            = "8:00-12:00",
        weather         = "Fair Skies",
        previousWeather = "Rain",
        bait            = "Ghost Nipper",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 14.3, y = 34.8, radius = 1050,
        worldX = -354.26, worldY = 0.05, worldZ = 540.32,
        fishX = -368.37, fishY = 0.04, fishZ = 550.58,
    },
    {
        name            = "Harlequin Queen",
        expansion       = "Dawntrail",
        zone            = "Living Memory",
        zoneId          = 1192,
        aetheryte       = "Leynode Aero",
        spotName        = "The Knowable",
        time            = "16:00-18:00",
        weather         = "Fair Skies",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 7.2, y = 14.3, radius = 400,
        worldX = -728.20, worldY = -6.18, worldZ = -344.54,
        fishX = -718.79, fishY = -6.18, fishZ = -334.48,
    },
    {
        name            = "Heirloom Goldgrouper",
        expansion       = "Dawntrail",
        zone            = "Heritage Found",
        zoneId          = 1191,
        aetheryte       = "Electrope Strike",
        spotName        = "Alexandrian Ruins",
        time            = "12:00-16:00",
        weather         = "Fair Skies",
        previousWeather = "Fog",
        bait            = "Popper Lure",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 6.8, y = 34.0, radius = 1000,
        worldX = -674.07, worldY = -14.00, worldZ = 611.24,
        fishX = -678.18, fishY = -14.00, fishZ = 623.29,
    },
    {
        name            = "Hwittayoanaan Cichlid",
        expansion       = "Dawntrail",
        zone            = "Shaaloani",
        zoneId          = 1190,
        aetheryte       = "Mehwahhetsoan",
        spotName        = "Niikwerepi",
        time            = "4:00-8:00",
        weather         = "Clear Skies, Fair Skies",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "",
        x = 29.8, y = 7.4, radius = 600,
        worldX = 420.92, worldY = -17.70, worldZ = -708.28,
    },
    {
        name            = "Icuvlo's Barter",
        expansion       = "Dawntrail",
        zone            = "Tuliyollal",
        zoneId          = 1185,
        aetheryte       = "The Resplendent Quarter",
        spotName        = "Downripple",
        time            = "0:00-24:00",
        weather         = "Fog",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 9.7, y = 10.5, radius = 300,
        worldX = -201.72, worldY = 40.09, worldZ = -5.67,
        fishX = -207.17, fishY = 39.59, fishZ = -13.90,
    },
    {
        name            = "Ilyon Asoh Cichlid",
        expansion       = "Dawntrail",
        zone            = "Yak T'el",
        zoneId          = 1189,
        aetheryte       = "Iq Br'aax",
        spotName        = "Xd'aa Talat Tsoly",
        time            = "0:00-24:00",
        weather         = "Clear Skies",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 8.2, y = 11.9, radius = 600,
        worldX = -589.46, worldY = 1.47, worldZ = -399.71,
        fishX = -594.79, fishY = -0.17, fishZ = -411.32,
    },
    {
        name            = "Iron Oxydoras",
        expansion       = "Dawntrail",
        zone            = "Kozama'uka",
        zoneId          = 1188,
        aetheryte       = "Many Fires",
        spotName        = "Miyakabek'zoma",
        time            = "13:00-15:00",
        weather         = "Fog",
        previousWeather = "Clouds",
        bait            = "Golden Stonefly Nymph",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 14.5, y = 28.6, radius = 2000,
        worldX = -185.08, worldY = 110.73, worldZ = 236.09,
        fishX = -173.81, fishY = 109.20, fishZ = 224.51,
    },
    {
        name            = "Iron Shadowtongue",
        expansion       = "Dawntrail",
        zone            = "Yak T'el",
        zoneId          = 1189,
        aetheryte       = "Iq Br'aax",
        spotName        = "Iq Rrax Tsoly",
        time            = "16:00-18:00",
        weather         = "Rain",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 31.8, y = 6.8, radius = 1800,
        worldX = 500.56, worldY = 3.64, worldZ = -531.60,
        fishX = 501.90, fishY = 0.07, fishZ = -543.01,
    },
    {
        name            = "Lotl-in-waiting",
        expansion       = "Dawntrail",
        zone            = "Yak T'el",
        zoneId          = 1189,
        aetheryte       = "Mamook",
        spotName        = "Xobr'it Tsoly",
        time            = "0:00-4:00",
        weather         = "Clouds",
        previousWeather = "Fair Skies",
        bait            = "Golden Stonefly Nymph",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 33.3, y = 16.6, radius = 800,
        worldX = 638.16, worldY = 11.20, worldZ = -255.69,
        fishX = 651.56, fishY = 10.17, fishZ = -259.10,
    },
    {
        name            = "Moongripper",
        expansion       = "Dawntrail",
        zone            = "Urqopacha",
        zoneId          = 1187,
        aetheryte       = "Worlar's Echo",
        spotName        = "Sunken Stars",
        time            = "12:00-14:00",
        weather         = "",
        previousWeather = "",
        bait            = "White Worm",
        swimBait        = false,
        autoHookPreset  = "AH6_H4sIAAAAAAAACu1dW2/bOhL+K15igX2RCl1tyW+pezkB0qSIHRSLosDS1MjmRhZ1SMptNsh/X1AX25KlxEncxE71Zg0pijP8ODPkcOhbdJJKNsJCilE4Q8Nb9DHG0whOoggNJU9BQx9YLEc4JhB9YYzMS/IlECzkSUwXWFIW5zXKwknK4xGLIiDyIgzRMMSRAA2N5uli642irPrKNyrnLM2ar9VTfT2jMai+ns5ixqHSrbz7Qfl4GqCh5fka+pxM5hzEnEUBGhqtXH3llHEqb9DQ1NCp+PiLRGkAwZqcV9to7WTKllDSRywOqGJuDFJ1cJF9a4aG37PfpoZI9luiIRpLLFNxQiRdwugD0lCi3vinvElAld4ICYt3hUQoi8W7zxADp+TdB5oRML/5j/X9e1FxLDmNZ1qvePzK6RJLeDdiHM7o9IdW1ruY/heIbK33o60EaYgGAg2/m55h/9AQjZc503caKti/03LGJnQB32gcsJ9rtoTEXKLhwDI0BHGAhp5jbLz5Q0N4/RPQME6j6O4uH+1igG5R9sNagzRYgSIb5r5XG2bT2Gmg9zDSWXe15m75g6egz/gN8DNy+N0rbDVFKxJezyPHNJy6hN1nTKVCSI9gxtxm5vjnUvM00HZlctdZ+Tk5CsEscYSGtrGzcij63qYUHNMwnzD9rL2pBNXHcYxnMxrP7umk8YRO2nvt5IjxgCrh36LTeAm8JGzN19zorpX8qqBBZZhWv7+78b1YAic4eY4W25SPswe1syGgT1TMP96A2HI86uxXR9atse/upDL7++37F3wN4zkN5XtMM5kqgigJY4nJtUBDt8WC9b1tLnbgwd+X2n+sDfuKJYWYZC7iJYTqKx8xj24UZrMWWoaqX2eyv5N1s16NT07/ByMsc++obejqXFm7eUX2a3E1meOI4mvxCS8ZV21UCCVWba1KvwTClsALl6RNFnX/ZSdJ9F9LEu/p7DNWkL1FJ/EsAi5K7q1mFu2B4WwN9y4sentWN2kk6Zyx61aLZxnuUxZle/CKi25uLFIaPflfkuPKinhl1y5BgByxNJbAv3L1MP6JkxV7nxgnkGnVjJq/kxEDRc24tz3X0bKV9wUBHGeWpSalSuFJFI0lS0Rz6ThhWbNGja5YbKI/z75OOJ3NgCunc0s0u7X84CrRc8pVor+DI6ghJel8JFYCyh8nLB8EpKO8Vm7+ijrqoaxxm8FSNzV0lnL4AkLgmfKQkYbOsymIzlkMqHgp855t9WXJEuWQszibaJcgWLSEwidVohE1H6mhRoaNc7aqMlZCUOOUeYyr94KUgKJukBZsCfmiYPNlmYoJywszkZ8zScObi3icEgIic1/qYPtI5mw0x3LF92q/BssJ/FLDhTT0gYokwjdKJU0YFmtBrihbdTNq1gFKsk2f9XZPtf6nCIv5BIvrKeanZKPee7XiUB/4xDjMOEsVLMoygGSDr4x6p6BxFdO/0wz7yMRTFzvhQA+gb+qOTYiOHXD0vj8NDLCCvkf66E5DZ1TIi1CNbiOyVUEu/RwpxRRuA8u3OZXQ+8b4ogIZBeZzxhc4+qtQjpfwd0o5BOUwGhoqvZdvgLMqqqoAWetQ/liUbaqagpR/0DEHvoauBGQaOclfUEXifeYN8ZUsrwSse6Zq1CtUS7/QGA2Nd8YWHf8q6FcCvnIgVFAWt7W5VWHd7HZRpWX2E3iYtna2Xr7Rbr1ks9mxhCjCvK3VWvG60XrBqs3HKMRj3sNo3nlo09elnJ5niKrA27biDRhqrFQDRFOd2vg2egzltB1LzvKlfn3iVtaJD89cw+5mbjdzj2Hm5pPkQOfjGcwgDjC/eb4t7Wbk4dvSN4DcKwEfWFogciWwM8h3IAXBSVN5Tnq001i8XUG6pfZsO6exA/pvBnoO2XaHqQPtsa50cgwcHRSf5it0KvTA0fi2fYUJLzd2mn2FhvKctB9fYeBa3UK1g/rvh3oO2n15Cx1sD0lDH52/kINxj/5Ch8dDwuMb9hiUoFgqNzifp4st4pWAUSokW+RRiYr3kJ3ATnl+Ekr92DiTkUfvT6SERSLLOaDqTDCfqV6YjefE7IHr148YmS90IOApUZkHj29WD3MU4m0asg3pNw7XaSzTjNgWMXTVsecnxwybdFEXNDwkVXR0pvHhQNgj0dhtu3dofKUwUAfIQ9/bOTr12EV3uiNBRwzfLmbzVk+nHSkUu5hNh8ZDQGMXiekO+x61Ou3iK2/35PmRgrGLr3R4/AOjJuUpjo2wSUtOq4qbbN3J8fKJlE+MbWTZc6EEvk6p3NB4LCmS4MYSkixwNP5JF1NMZa6rlByV5iyIa0E3fqqotQqnPOrtA0uhK+5Y+l0ZdLnwmwZ0I6/OsV0TG4OB7uDQ0J2BY+oeeLZuEcC2h6d9bLhIhcHyxLoCht9XhDyZbjvRrpJk59gqE7SaZHfSSzDlPRb2kmJu9xIaE+Cil1DgBHpyDr2fWAL/l+iJlIeYwD/WqXlfGItnnCYJ8EpunvkAIE8DiCUlOFITuTWv2fXr+df2Tvc9eK+RYz7OhTOO8gzYFobcp90f4O4vpby7AOqFLoAaJ5iDspZY6Yjb1jsGtkP17ZBQE/o0mLDRHMi1yvz3Hb8/sBSsNu7bMV4D/0dwTcE+ctSLvPcGndaQJX8OS+DVi222TbFhqbt1sjtwnpvD2W5Yi6DcW7CrRXbdtlm9/+xJdlkDTmfzfNjWx0+yS7JMlcdXGMkdL0lQMGj0gFcXKDxg9cF3/cAPQt3xsac7hu3rPgn7+sD0MYSm7+HARurGsfusut0fDNoxrK4/EHFnn++xzxtX8r2qeX68wu1ucnyOMXgJ85xPzqO0zGZnmc3fb5bf4JUx7QvevRjNgT91bJuEOjaxoTuOb+meZ5g6AARTx+pPfderGs3yKqma1XTvsZqAeydRggl+Y4vaUvV1S9XuruIXXqqW28x7NYXllkZn4J629OwM3OEZuDDwie0atu5a/anuDAjWseFPdeJbDrFCx59i2MnAee0G7or/zSRnqezsW7cVe3x38b/cCq6zWge4YdpZrcOzWuAHDnGDQA9CK9QdyzR1L3Rs3QuwQbwwdEng7mS1/HZ8/Ztd9/5Kb3pjyWIgqZRvLujYrc/+iP+S6ezXHx3w6+zX4dkvv983PGL2ddMjtu54rq17xCO6a0w9azo1wik2sxM4p+JzxKYqZFhBQeN5mI32DZOEVuh6uj+YEt3x+4HuYzPU3YEfGnY/cAKw0d3/AVbjoZZBbgAA",
        x = 20.4, y = 27.6, radius = 400,
        worldX = -57.21, worldY = 7.75, worldZ = 304.67,
    },
    {
        name            = "Moonmarking Saucer",
        expansion       = "Dawntrail",
        zone            = "Yak T'el",
        zoneId          = 1189,
        aetheryte       = "Mamook",
        spotName        = "Cenote Jayunja",
        time            = "16:00-21:00",
        weather         = "Rain",
        previousWeather = "Clear Skies",
        bait            = "Red Maggots",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 19.7, y = 32.0, radius = 1800,
        worldX = -111.17, worldY = -215.02, worldZ = 516.58,
        fishX = -113.27, fishY = -215.02, fishZ = 518.04,
    },
    {
        name            = "Moxutural Greatgar",
        expansion       = "Dawntrail",
        zone            = "Yak T'el",
        zoneId          = 1189,
        aetheryte       = "Iq Br'aax",
        spotName        = "Cenote Moxutural",
        time            = "20:00-22:00",
        weather         = "Rain",
        previousWeather = "",
        bait            = "Honeybee",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 21.7, y = 20.3, radius = 800,
        worldX = 37.80, worldY = -185.69, worldZ = -113.19,
        fishX = 31.04, fishY = -190.70, fishZ = -100.08,
    },
    {
        name            = "Muttering Matamata",
        expansion       = "Dawntrail",
        zone            = "Kozama'uka",
        zoneId          = 1188,
        aetheryte       = "Earthenshire",
        spotName        = "Bopo'uihih",
        time            = "12:00-14:00",
        weather         = "Clear Skies",
        previousWeather = "",
        bait            = "Golden Stonefly Nymph",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 10.6, y = 12.4, radius = 1500,
        worldX = -543.71, worldY = 1.10, worldZ = -490.80,
        fishX = -524.67, fishY = -0.40, fishZ = -488.98,
    },
    {
        name            = "Ole Ole Ole",
        expansion       = "Dawntrail",
        zone            = "Urqopacha",
        zoneId          = 1187,
        aetheryte       = "Worlar's Echo",
        spotName        = "Chirwagur Lake",
        time            = "0:00-2:00",
        weather         = "Snow",
        previousWeather = "Clouds",
        bait            = "White Worm",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 20.0, y = 37.0, radius = 600,
        worldX = -75.05, worldY = 0.06, worldZ = 773.93,
        fishX = -78.47, fishY = -3.54, fishZ = 762.22,
    },
    {
        name            = "Pixel Loach",
        expansion       = "Dawntrail",
        zone            = "Solution Nine",
        zoneId          = 1186,
        aetheryte       = "Residential Sector",
        spotName        = "Residential Sector",
        time            = "0:00-4:00",
        weather         = "",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 6.5, y = 18.7, radius = 1800,
        worldX = -347.14, worldY = 14.03, worldZ = 154.19,
        fishX = -342.89, fishY = 13.73, fishZ = 161.06,
    },
    {
        name            = "Prime Adjudicator",
        expansion       = "Dawntrail",
        zone            = "Urqopacha",
        zoneId          = 1187,
        aetheryte       = "Wachunpelo",
        spotName        = "Karvarhur the First",
        time            = "12:00-16:00",
        weather         = "Fog",
        previousWeather = "Fair Skies",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 6.3, y = 20.3, radius = 1000,
        worldX = -674.72, worldY = 49.89, worldZ = 56.95,
        fishX = -683.81, fishY = 48.19, fishZ = 46.45,
    },
    {
        name            = "Punutiy Pain",
        expansion       = "Dawntrail",
        zone            = "Kozama'uka",
        zoneId          = 1188,
        aetheryte       = "Ok'Hanu",
        spotName        = "Peaks Poga",
        time            = "8:00-12:00",
        weather         = "Rain",
        previousWeather = "Clouds",
        bait            = "Golden Stonefly Nymph",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 40.0, y = 15.1, radius = 600,
        worldX = 925.54, worldY = 5.93, worldZ = -318.99,
        fishX = 931.25, fishY = 6.06, fishZ = -319.51,
    },
    {
        name            = "Purse of Riches",
        expansion       = "Dawntrail",
        zone            = "Tuliyollal",
        zoneId          = 1185,
        aetheryte       = "Bayside Bevy Marketplace",
        spotName        = "High Tide Harbor",
        time            = "16:00-18:00",
        weather         = "Rain",
        previousWeather = "Clouds",
        bait            = "Ghost Nipper",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 16.9, y = 15.2, radius = 1800,
        worldX = 145.86, worldY = -17.96, worldZ = 155.21,
        fishX = 160.38, fishY = -17.96, fishZ = 171.30,
    },
    {
        name            = "Riverlong Candiru",
        expansion       = "Dawntrail",
        zone            = "Kozama'uka",
        zoneId          = 1188,
        aetheryte       = "Dock Poga",
        spotName        = "Miyakabek'zu",
        time            = "0:00-4:00",
        weather         = "Clouds",
        previousWeather = "Fair Skies",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 29.2, y = 12.0, radius = 600,
        worldX = 366.41, worldY = 1.77, worldZ = -498.61,
        fishX = 367.97, fishY = -0.34, fishZ = -489.50,
    },
    {
        name            = "Shin Snuffler",
        expansion       = "Dawntrail",
        zone            = "Yak T'el",
        zoneId          = 1189,
        aetheryte       = "Iq Br'aax",
        spotName        = "Ankledeep",
        time            = "0:00-2:00",
        weather         = "Fog",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 8.0, y = 27.2, radius = 400,
        worldX = -669.03, worldY = -185.73, worldZ = 289.21,
    },
    {
        name            = "Shined Copper Shark",
        expansion       = "Dawntrail",
        zone            = "Living Memory",
        zoneId          = 1192,
        aetheryte       = "Leynode Mnemo",
        spotName        = "Canal Town North",
        time            = "8:00-13:00",
        weather         = "Fog",
        previousWeather = "Clouds",
        bait            = "Ghost Nipper",
        swimBait        = false,
        autoHookPreset  = "AH6_H4sIAAAAAAAACu1cXU/jvBL+K8g6lwlK06RpeseWhYPEwooU7QVCOk4yaX1I47yOU5aD+O9HdtI2n2yBLGzZ3LVjx50ZP/PhTsaP6CjldIoTnkyDOZo8oq8RdkM4CkM04SwFBR3TiE9x5EH4jVJvsSZfgYcTfhSRJeaERtmM9eAsZdGUhiF4/DII0CTAYQIKmi7SZe2JfKz8yA/CFzSVy1fmCV7PSQSC17N5RBmU2MrY99dfz3w00ce2gk7j2YJBsqChjyZaq1TfGaGM8Ac0GSjoLPn60wtTH/wtOZtWWO3IpStY06c08okQzgEuGFzK35qjyY38PFCQJz9zNEEOxzxNjjxOVjA9RgqKxRP/4g8xiNGHhMPyMNcIoVFyeAoRMOIdHhNJwOzhP/rNTT7R4YxEc+Ug//qdkRXmcDilDM6Je6us5126/wWPt867bRtBCiJ+giY3g7E2vFUQiVaZ0E8KysV/UjLBZmQJP0jk0/u9ECvhmHE0McaagiDy0cQaawWhbhWEtx8BTaI0DJ+eMiDm2HlE8oO+tR9/g1eJwNG4gsCBthMGOwChZFdpZsu2XmMY2m+wDC2zjGeVLbxHScNbEzcGmvE6DTfLkivpBcIM6sLsv5k3m4HSJqTDsXeX7IeQ7e7rNN4LCVY4RJOhtrOrynlvN6DBK3yB3pl/Eiw6EZ7PSVRIQ8r+ypA2/WImh50yOaXMJ0L3j+gsWgFbE2rOI0tOtsFwM9Cg/oE+Gu2epFyugHk4fotLLerH6MAHFhR0QpLF1wdIaglaVfzyzpoV8U1zl70ddcv7N3wHzoIE/AsmUqeCkKwJmX9DE7MlnI7GdSl2kMHuVobvmBOIPJkgX0Egnv2KWfggkChR0bIBoyrro50CqN4x94z8D6aYZ2lVm5qrvOq7Bftht7zOFjgk+C45wSvKBLslwhotQ6VMvwKProChyUAgvE3Cajqzk3wdW8MXMj/FAjSP6Ciah8DyCC/9fhPjQ0szaluzC+Pjjs04DTlZUHrXGkl0zXzNobCD1Ddns3BIakzXf3KGSyfyTby4ggT4lKYRB/adiS/OPY434p1Q5oH0VpKaPSOJvqBK6YdjIb04+V96gCPpsStaKg0ehaHDaZw0jzoxlctqFboQsYn+trg1Y2Q+ByZy1FsFXUfkn1T+CjI9d2TAyFX1wALVMIdDFY/HhmoZMAJL9+zAGKMnBZ2ThF8GQhdijZp6xYDgUoavrbLOUwbfIEnwXOSDSEEX0jLQ6YIm/OCCxDEwlD09kzmjSMwuKFvi8N85EK/gn5Qw8LNkWQq69tU/AMspYmoCvLoZ2fd8sLivOSn7RWNg2Qq6TkDCP84eEEPJF+n82Wa96wS2rIkZ1Qnl0W8kQhPtUKvR8c+cfp3AdwYeSQiN2tasTdguWx8qrUzvgQVpK7PV8cK61ZHisg6HMMSsbdXK8HbR6sBmzd1wvf+nwubTU5u9rvVUd3NVODXNqCGjcVJlm5vmVHat0emurdHhjGankKo9Fv9j/LU5asPeHHtz7M3xjeZ4DnOIfMweeov8GwLkJwgk1wkc0zSPERuFnUP230ji4bhpPCO1pYKtoSd/uhR7dPFvUp8J9kD/zUDPIPuKfKkHbe+dPxa0r8sqetz2uP3ArGLG1v/rNGcVDeMZqZuswjL1/kjbJ9C/H+oZaLvKK3rY9ue+d4Rth5lFj9weue+DXLIEmvLCfzWLdFkjXicwTRNOl1n5opRnyPdyU5a99yE+FOrfWU31iHNYxnybuaQMZpjNBRt642sxQ8u06+/1vU+d9sWvKObaatqBgjIbtX8W8VQS20qFpniB9FfFwhe5lr5Y+Cd5lgwmf0eprBmNfa2sR+Ob0dhd5tUDsnePfQGofxXo74zufVnns76VtqdQ7Is1PRr/BDT2JZj+Jd+9dqd9YeXzvnG+p2DsyyU9Hv8QPH5wEaSlHfAjqyBlzbymtiEax44CDmzbt1bweDQWL6+QaO5wiOUtCs49WbqY8MxXCT0Kz5kTt4pu/Kl81qac8qKnLygnwcNl5KSeB4ncwVoflreg0wXmm0awzb02mM/gp2jsQQo6Jkkc4gfROjmjONn+7IZSmyupkgHiyctxNhfplKefhDhZzHBy52J25olp+dJfRAOQWP+EMpgzmoqLTNZjAHFBLEnNN6ZpQwstdWABjIJxoA5cY6QaYIxV2zWwqmlDG9vDwDB0A4kyWNZTl8PwZkPI+ujqPXbF/jpT10Q7b1t/nbMgEfgHUyoa7A6cBWZ3pTa7wS8gduZDxImHQ2Gare2gpl1tWx3u1H7eRd/qiwuNTsoC7IETij+vWwUyX9cibXbXidtfjvNOlWcnxgxE/MPC6h9bW7PNF1yRI0z0zJ/R6QK8O9EwbRv2yNIFrArXf2gfgf896O6W/olm5aXMzamDdh93QSMoObWhDGY4FpQGn5Z1fa/XR6pYCVbAyvds1IOrpourPuSVHG9rxXkuVOZlts8QKfMO13qgfL63V/a443S+yLZtT9p7N5FYXiw02KGzd43QxnT7HscZTH+RYhgD3XD9IFA903VVwxtqKrZGYxXb3gi75iiwbB2Jq5meSSGMoSUS5DbzOqFsTjmH6OCyYmf7nzyst6IlJShc8LRrRrDxMZ2mBC938v3Nep8necjss88b9jRv+P1Jwwecr9ftMe9/wHa6iJvmSNN0zRqrhhtYqmF7muq6hqVaugmjINB1Xbfl0fwsOQ2pK2J6CQXPHq+L8XnsAQ5sTw0Grq0aEAxU27DGqj7wA9vVTN83bfT0f8Q9nXBHWAAA",
        x = 9.5, y = 28.1, radius = 1050,
        worldX = -643.74, worldY = 1.10, worldZ = 335.84,
        fishX = -637.27, fishY = 1.10, fishZ = 328.49,
    },
    {
        name            = "Shuckfin Dace",
        expansion       = "Dawntrail",
        zone            = "Kozama'uka",
        zoneId          = 1188,
        aetheryte       = "Many Fires",
        spotName        = "Ku'uxage",
        time            = "4:00-6:00",
        weather         = "Rain",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 22.7, y = 21.1, radius = 800,
        worldX = 22.59, worldY = 25.12, worldZ = -35.49,
        fishX = 23.89, fishY = 24.74, fishZ = -24.26,
    },
    {
        name            = "Sprouting Perch",
        expansion       = "Dawntrail",
        zone            = "Heritage Found",
        zoneId          = 1191,
        aetheryte       = "The Outskirts",
        spotName        = "Outskirts Shallows",
        time            = "20:00-24:00",
        weather         = "Thunderstorms",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = true,
        autoHookPreset  = "AH6_H4sIAAAAAAAACu1ca2/qPBL+K0fWfkyqJJCQoNVKLb1spd5UqM6HqtKaZAjehpjXdjinW/W/r2wnXELooZS20DffYDx2PONnLr4+o8NM0A7mgncGMWo/o5MU9xM4TBLUFiwDAx3TVHRwGkJySWk4LMi3EGIuDlMywoLQVHMUhb2MpR2aJBCK68GgoHaG2WitCj+JGNJMNV6wDXDCZROYiwuSguzpeZxSBgud0p2Pir/nEWo7fmCgs3FvyIAPaRKhtrVSphtGKCPiCbVtA53zk99hkkUQzciaba61wz6dwFQ+mkZEytYFITs4Ut+KUfte/bYNFKL2/YOBsK7x8mAgQO00S5KXFy1b3p1npH44swGJpipQQnl+SSjbWkusLcilumtUdytobaJr6wOUba2hbInHBQ3PUNO0rWZJlOZ6Gq6WJVfSG4Sxl4V5RgK1UVdgkfHDUJAJdI6RgcayBok4at/bvtV4eFGCKpkNXeVsPGOc4AS1G1IWOkZt9C80xz6nLWODDxuIpJOi/mt9+Id4GoNs8YkLGB3khk9oyg/OIAVGwoNjogiYPf3Hub/PGbuCkTQ2fuR/bxiZYAEHHcrggvQfjILvuv9fCMVKvodVJcjQ6gksq1orFRjSfV9lqE3bsjcwCWdrZir72E1xHJM0fqWT1gadbGy1kx3KIiKV/4zO0wmwgrBkQ9rt98gIfpI0or+mBRVmbDuet777v54AC/H4PZ5lXj/NbbmCt/q1U8KHJ0/Al4JkWVGLGHBLinLddVDgbUHKORhc4kfoDslAHGGi5JcEXhC6AoePHLXdFfHH85elWEOGYLsy3GBBIA1VknILA1n3BLPkSWJWjWB1wPHKPffWCjjOB8JsG45f19YjV67ttFr+g4FGJC1G1i4C0z9XBKZluN8w8j/oYKETp1W4KGvXWS+cN3ZVu6+qpDfECcGP/BRPKJPNLRAKXTeMRfothHQCDLVtaflVubTnL6VFa2nR+3otrpEVudbbwXdE4jMszfoZHaZxAixHuorhVVhstKzmEhbX0aG/ZUebJYIMKX1cmRU4lrvJ1GkL2XzezVmMr56B/BYML8xap2C9BQ6iQ7NUALth8k/3Fx5PxTulLAQVTxRV11HESFKV9A3f9Q01O74OAacqppa0tFB4mCRdQce8urQ7pqpZq0SXIlbR35eD9BiJY2AS+0uqeYtRzQ3A1FK4wEzIsLNGjmwgqWA9AFO96L89qnWPTKS5dLzPeeSfguNZodG0DXSRMbgEznEsJw/IQFfK8tAVTQHlldTEoiG/LOhYugOaKqFugdNkAnm6LjXCS+ljBYeCxBWdsnSl7HJ4VDJdQC3KQpDEuZZGdALaI83XFRnvUV1Y9AlUcx2cxcMCr9MaV1SQwdN12s3CELjK5soIPAmHtDPEYqqVYplkiEUPfssxRAY6Jnyc4Cfpp3oU85map5QlXkVVHSChWq6Z1inxnyaYD3uYP/YxOw/n+I7kVE1+4JQyiBnN0lm3jwDGc3Ip6ot0yx+H1TVSlPWCx24j3f4QpE/r1VDfdahbBgL5eW9/vLNTY3Yf3PODge5S8lem8hVk2VG/0QwjE3tOw2yG/dAMvAE2A7Bb0IggCN2BTKIvCBfXAzn4ldmILNCxUwMpT7tWYekWoh+XOI6p4AuQkmC/omyEk3/nGe0t/JURBlERhS0DFdPyn4AVi2TlIEo90n/zsvn8MCfpDzbtVmCgOw4qjR7rCrKIH6lp/iyK33GY9UxylBkWSy+JzFcOrCU6/p3T7zjcMAgJJzRd1eYSw6zZ5aKFlukvYINsZWfL5XPtlkvmm+0KSBLMVrVaKp41Wi6Ytvkdli80pKRcy9Ob8vBXcSyNZCVTaViqeEparpxsFcbTFYzqleT3mY/VqM1nn81nh7dwNlw620tzvIAY0gizp9oi/w4B7Rsg947DMc3yGDFV2IVeCDnhIR5XlWvSmzO3vPZC7HHkjmCdudVA/2Cga8hukC/VoK2989eCdrOsosZtjdsvzCp6rFiHqc4qKso1aTtZRct16iltnUB/PNQ1aLeVV9Sw3aV5n0bB3oFxi/lCjcddwuM3XoeQiqKZmJN8mI2WiHccOhkXdKRXQReyB3UXJWP6nK38MXeuTp+QOhQCRuPZhp5k6mEWy25Un7BrtNygfMLO/qRTV9s7YLfyxFyu36oxm1N/5XidpyJTxFU7fK68E7PxHl+VM6o3+XbJF+1dbHzHllk1Gus9sxqNX7RjVANy1xd39s491htB9RGePYZvvb3zXU+T7SkU602bGo27gMZ6K6Y+nLvX7rTeYPm+J8X3FIz1BkuNxx3B4w5tmyzcqv+6fZNFzWyyt6Fuww0EsNm99TmPR8f5RcyugLG64tn9RUZ9TIT2VVKP0nPmxJmiKz+Vc023U95Ue8euJOdvx33UlTet/KoBnbsIB1E0iKKWb3rYcs2m7YWm32r0TTcYRJbXCsACD8ltMH0TLofh/ZSgb78t34xbuBXn2RLdq27FdceMZoKk8Y8bYOFw4Wac/Qd4nUeQChLiRJrlyqcg3KD8ZEVjrceB/K94AqmbsQEOoZvo+6krBHI3ew/G/QqJ6lcB3+WZu2PMQMY+LC3+eeWzLO4b3lSU5nke9WhnCOGjfCwlaAZey5GwmnvGzfr4d29yv62sei+uZ+kHCKfXJOV9LdR2mkFgr3OCYA+erdnG9fj8yn2Fw664oH8FE2CLT7wtZw2WI9+jU6/Bve+Mz2s5QL5/+L1TgNcNsvSey16YJJnlGMo6/2yJM4hWTiSm70r8IXnyA7/vWpZjRrjZN5vBwDMxhAPTswKv5fot6PflKwKvJ0eNljz5s8q+eiQG9uMy44+QJFkaLxpbnR5VvUW4bnY0dUmfkh5tdh9/raBSv7r8Oa8uf0Ympt3BJyVhdZ6y7Tzl45OUv9NCRXcbUdr1mjjwITQjzw/NZuDaph96LdPznAH2wW1YUV8tcZzzs4T2ZQaxAIKVyxRz33D8PjgtLzRDgNBs2g3L9KPAMZ1Wo+HaTcdttSz08n+P7hSer2AAAA==",
        x = 19.8, y = 8.9, radius = 1400,
        worldX = -144.75, worldY = 22.30, worldZ = -770.15,
    },
    {
        name            = "Stardust Sleeper",
        expansion       = "Dawntrail",
        zone            = "Yak T'el",
        zoneId          = 1189,
        aetheryte       = "Mamook",
        spotName        = "Xty'iinbek Tsoly",
        time            = "20:00-24:00",
        weather         = "",
        previousWeather = "",
        bait            = "Crimson Lugworm",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 36.9, y = 25.9, radius = 800,
        worldX = 769.11, worldY = -81.86, worldZ = 200.56,
        fishX = 780.83, fishY = -84.30, fishZ = 197.59,
    },
    {
        name            = "Thunderous Flounder",
        expansion       = "Dawntrail",
        zone            = "Heritage Found",
        zoneId          = 1191,
        aetheryte       = "Electrope Strike",
        spotName        = "Crackling Canyons",
        time            = "0:00-24:00",
        weather         = "Rain",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 21.5, y = 32.3, radius = 1800,
        worldX = -12.44, worldY = 49.44, worldZ = 541.99,
        fishX = -9.01, fishY = 49.09, fishZ = 531.90,
    },
    {
        name            = "Thunderswift Trout",
        expansion       = "Dawntrail",
        zone            = "Heritage Found",
        zoneId          = 1191,
        aetheryte       = "Electrope Strike",
        spotName        = "The Driftdowns",
        time            = "9:00-11:00",
        weather         = "",
        previousWeather = "",
        bait            = "Red Maggots",
        swimBait        = false,
        autoHookPreset  = "AH6_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",
        x = 13.1, y = 17.4, radius = 1500,
        worldX = -468.89, worldY = 37.00, worldZ = -148.98,
        fishX = -472.96, fishY = 37.90, fishZ = -138.44,
    },
    {
        name            = "Ttokatoa",
        expansion       = "Dawntrail",
        zone            = "Shaaloani",
        zoneId          = 1190,
        aetheryte       = "Mehwahhetsoan",
        spotName        = "Lake Toari",
        time            = "20:00-24:00",
        weather         = "Dust Storms",
        previousWeather = "Fair Skies",
        bait            = "Popper Lure",
        swimBait        = true,
        autoHookPreset  = "AH6_H4sIAAAAAAAACu1d7W+jPBL/V1bWfYQVkBBIdPdI3Wx3r1K3rZpU+2FV6RwYEl8JzmNMur2q//vJNuSFQJu3bpPW3xJ7MJ7xz+Oxx8M8opOM0y5OedqNhqjziE4TPIjhJI5Rh7MMDPSVJryLkwDiH5QGo6L4GgKc8pOEjDEnNFEURWU/Y0mXxjEE/DKKitLuKBuv9cBPwkc0k40XZBGOU9EETvk5SUD09GyYUAZLnVKdD4u/ZyHqOH7bQN8n/RGDdETjEHWsWp6uGKGM8AfUsQ10lp7+DuIshHBerMgWWjsZ0CnM+KNJSARvPeCig2PZzhB1fhW/A9T5dWsgrJ54ujUQoE6SxfHTk+It784jkj+c+YCEMxFIplp+iSnbWoutPfAlu2tUd6vtbSNra0/CthaEba0hbIHHJQnPUdO0rWaJFW89CVfzkgtpN2YeEUcd1Cdj+EmSkN53vyIDTQR9yjHjqGM7lvUk2ZQcG+qB3j0ZDzDhXZolfP4MnaAO+gut0n+fzImmOEYdf6nV50Wq5nAdbpu2ZW+BEGdvqBV97CV4OCTJ8JlOWlt0srHXTnYpC4kQ/iM6S6bAioIVSCktOAfFrKIC1bbTaq2vDS+nwAI82WWirTGIe5kZz2LyG0lHpw+QrqwZZUEtY8AtCcp1d0DB63P5A99Bb0Qi/gUT2YYoSIuCHsfBXYo6bvUa2fJX2V2D2ea+mLV3V3bPCucKcwJJIM2Ga4hEr04xix9E8/KN1UtAqyyT1joQcF9RKs9zycj/oIu5siBq7IYVppy11rXWW+G6P8IxwXfpNzylTLSxVFDgumEsl19DQKfAUMcWs7ZOFOUlfh1BeG8liC9k+B0LuD6ik2QYA0sL5p1qDhue1VwZ7DU49PfA4cJK9iOLORlRele73jqWu42NvgezMe/mgpapNHV/c4aXtkczRXENKSjDCtgVE39693gyY+8bZQFI/StL1TOyMBSlkvuG77qG3IZdBoATuVqVpLRUeRLHPU4naXVtb0Jls1apXLBYVb7b6t5nZDgElkrykmj2Z9PaL6p5AwkBqwGYyUX97VMle2QiRaXWx5xG/CkoHiUaTdtA5xmDH5CmeAiog5CBLuTEQxc0AZQ/9DAB1GmIN3M6OQkEo5Kpa0hpPIXcEBYSSUuGWQWFhMQFnZH0BO9ieKSZWkAtzAIQhQstjekUehzzbA4H9bdPVWXRJ5DNdXE2HBV4nT1xQTmJHi6TXhYEkEo7qYzA02BEuyPMZ1Ip9uMjzPvwW4whMtBXkk5i/CDUVJ/idC7mWckKrSyVHSCBPBeYPVOi/xbjdNTH6d0As7Ngge4LI4nUjN8ogyGjWTLv9heAyQJfsvRJ7HNeDauWgUgyLTZU5a2V1GQnU0xi8frZ8xV7NjmISsHPX0NCMdMcz/NvDTQmSbEA2Ovv+ohUOZ5rG2pv16h7t4D0FMrv9l3r9mhmo/0qs3H2nJ6Ohz4dLQOBeH3LOhrMOhqzx7CE3BroJiF/Z9KmQk0HAtdyfdPzQzCbNnhmO2q0Td93fa9htW078MVB2zlJ+WUkBr/SYhIVan1XQMpNwzosXdHJBNgnUb0EKQH2C8rGOP53bnVfw98ZYRAWloJloGJH/BOwJBGkKfBSj9TfvG7Rhs2L1Aubttc20E0K0tSfqAdEVfpF7rDnlsZNCvOeCYoywXLtDyJsqs/WSjn+nZffpHDFICApoUldmysE82ZXq5ZapvfAoqy2s+X6hXbLNYvN9jjEMWZ1rZaq542WK2ZtbqIuNzUsDHVO/M+Kc+KtDKE67Vtwtdt+ZBkmq5u5ihGvJCoNXxVNaTQqN47FJOtxRtV5827TzGroaXbo0+xDAvwchpCEmD1UYXzpmF2D/D2sJR8K5DcpfKVZjt2ZaM/VicppGuBJVb0q2ti8yp9eUvyOcNpp8+o9TQmFvgMDuoLsFsaKBu2H0OMHDNpnDRCN2/e2l30HuL1Joc+Kw5Jqq6KiXhXtx6rwXEfvJzXUXx/qCrT7sis0bLWG/oOw3aNloZGrkftnkEvGQDMurSpHmVWjbLxYWthv3SzldKycAkuGhgy0yJi6NSt+LNy0U7eyTjiH8WTuoBNEfcyGoh/VNyobntsuX7mz/9BNr42v3OXS2s0eXRB75UCdJTyThXWeOlcEemztq6vSQtpZd0hKSM3pI9q27ODSqkaj9mlpNL6u/0kD8mjPf45OPWpfkb6Kc8Tw1R6g93or7EihqP06Go2HgEbtrdGXbI9anWofzPu98X2kYNSeFY3HA8Fj2TPyhu6SpQD+t/OXLEumSrAv+TZkVFvEgc1j5Bc0Hp3kAZU9DhMZqlkErCpdJeQoNGdeOBd05atyqpk7ZaOnDyz8Of8g2muFrinhVw3oQkCbB4OgGeHQbMLAN5thNDAHGIMZgRc2WrYNFjhIuLpURFsOw5cj2sy2Xx/PdhLHn2RLkK6ESO4cz7ZhEIIOaDsc8+YdXwJ82Zumg2eO1iz/ALjdzoTXsY0fArk67EtHIugzFu3K0x94+ODHfdqVpw+fDweN2pWnXXlHrU61K0+78g4MjNqVp115B4LHN3bl1X6L+9hDn9Zz+r1yQJP21Rz4yeHRGVP6E33amDo4MGq3yru8p6fdKjpCSh++HLe9oCOk9Fb3oKCoI6Tepa1wdIpRu1W0W+WoAazdKvok4MDAqN0q2q1yIHjUEVIHHyH1dqnk/8Fl2AzqPaQcxp/zXHqEJunn75AAI8Hnr0QWYPbwH+fXr5ywx0X0kvEp/3vFyBRz+NylDM7J4NYo6C4H/4WA19Ld1tWgPMmhnWcx+utfFWmMfgLmI2DlZEi2/XKiw+1Dzzb2yX2wBGtrRak5ju1ETgimZ4m0a2ErMH3Pcc1GYLm4HfhRIwoXotRUINpqkNpSyjWv3W7Uh6j1Ob3DnOKl+DT7hal8FkLCSYBj4VmuTYLstsu5mhtrJZzfR7bmjdHYy1iEA+jFKuthDUPuVpnGbfctOMo786h+OM8kUF/x4q/FlL23kNzKbrW9LRJo229xuaA3wQyERYKFDniszVzubiBnMYPPwj7tjiC4m03iOUOO9SaQOvzE5/tIXponRK1QfBXpUy9gCixnq9bSsZymgc6GCWU7RxTVL5r5HZP3ENidp1hcXTGft/5KCcHnBlBhM8lc0WIurZk9V8CgcoMxy6z7woIeOdCybG9gWpENZtMJLLONB7bZ9sBvtRzfigYBqsgXvJw0VSa3rsUwIXf3wGBCPvUZzbheyT/SSj7/FvkhLeQLvTq4dXzTjeLm6/7i9+F3W/bVzP9Dy/6xbojzdL75zriRa3khulfN8Kvtoe3todc3hj7UCUJvH6ZKCzvNRhvAdCM/MJvOoGn6vt0ym5bVtpuO1w49dfZwln6P6UDMtSWrePVAYfHzOzj0Qxz4pheF4vM72DKxBwPTcawmYNxuuJGNnv4P/aC9BbyVAAA=",
        x = 31.5, y = 13.8, radius = 1000,
        worldX = 363.59, worldY = -17.35, worldZ = -430.24,
        fishX = 374.19, fishY = -18.16, fishZ = -430.24,
    },
    {
        name            = "Vagrant Keeper",
        expansion       = "Dawntrail",
        zone            = "Shaaloani",
        zoneId          = 1190,
        aetheryte       = "Hhusatahwi",
        spotName        = "Westbound Zorgor",
        time            = "6:00-8:00",
        weather         = "Clouds",
        previousWeather = "Gales",
        bait            = "Dragonfly",
        swimBait        = true,
        autoHookPreset  = "AH6_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",
        x = 16.1, y = 38.2, radius = 1000,
        worldX = -164.92, worldY = -27.46, worldZ = 643.97,
        fishX = -168.57, fishY = -31.44, fishZ = 655.41,
    },
}

--=========================== FUNCTIONS ===========================--

-------------------
--    Helpers    --
-------------------

function Wait(time)
    yield(string.format("/wait %g", time))
end

function GetPlayerPosition()
    if Player and Player.Entity and Player.Entity.Position then
        return Player.Entity.Position
    end

    if Entity and Entity.Player and Entity.Player.Position then
        return Entity.Player.Position
    end

    return nil
end

function GetDistance(pos1, pos2)
    if not pos1 or not pos2 then
        Dalamud.LogDebug(string.format("%s [GetDistance] One or both positions are nil, returning math.huge", LogPrefix))
        return math.huge
    end

    local dx = pos1.X - pos2.X
    local dy = pos1.Y - pos2.Y
    local dz = pos1.Z - pos2.Z
    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    Dalamud.LogDebug(string.format("%s [GetDistance] Pos1: (%.2f, %.2f, %.2f), Pos2: (%.2f, %.2f, %.2f), Distance: %.2f", LogPrefix, pos1.X, pos1.Y, pos1.Z, pos2.X, pos2.Y, pos2.Z, distance))
    return distance
end

function MoveTo(x, y, z, stopDistance, fly)
    fly = fly or false
    stopDistance = stopDistance or 0.0
    local destination = Vector3(x, y, z)
    local arrivalTolerance = 1.0

    local playerPos = GetPlayerPosition()
    if not playerPos then
        Dalamud.LogDebug(string.format("%s MoveTo: Player position unavailable.", LogPrefix))
        return false
    end

    if GetDistance(playerPos, destination) <= math.max(stopDistance, arrivalTolerance) then
        Dalamud.LogDebug(string.format("%s MoveTo: Already at destination.", LogPrefix))
        return true
    end

    if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
        IPC.vnavmesh.Stop()
        Wait(0.5)
    end

    if not IPC.vnavmesh.PathfindAndMoveTo(destination, fly) then
        Dalamud.LogDebug(string.format("%s MoveTo: PathfindAndMoveTo failed to start pathing.", LogPrefix))
        return false
    end

    local startTime = os.time()
    local maxSeconds = 120

    while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
        Wait(0.1)

        if stopDistance > 0 then
            local currentPos = GetPlayerPosition()
            if currentPos and GetDistance(currentPos, destination) <= stopDistance then
                IPC.vnavmesh.Stop()
                break
            end
        end

        if (os.time() - startTime) > maxSeconds then
            IPC.vnavmesh.Stop()
            Dalamud.LogDebug(string.format("%s MoveTo: Timed out, stopping path.", LogPrefix))
            return false
        end
    end

    local finalPos = GetPlayerPosition()
    if not finalPos then
        Dalamud.LogDebug(string.format("%s MoveTo: Player position unavailable after pathing.", LogPrefix))
        return false
    end

    local okDist = (stopDistance > 0) and stopDistance or arrivalTolerance
    local finalDist = GetDistance(finalPos, destination)
    Dalamud.LogDebug(string.format("%s MoveTo: finished, dist=%.2f.", LogPrefix, finalDist))
    return finalDist <= okDist
end

function GetEorzeaTime(unixSeconds)
    unixSeconds = unixSeconds or os.time()
    local eorzeaTotalMinutes = math.floor(unixSeconds * 3600 / 175 / 60)
    local hour = math.floor(eorzeaTotalMinutes / 60) % 24
    local minute = eorzeaTotalMinutes % 60
    Dalamud.LogDebug(string.format("%s GetEorzeaTime(%d) -> %02d:%02d", LogPrefix, unixSeconds, hour, minute))
    return hour, minute
end

function GetWeatherForecastTarget(unixSeconds)
    local bell = unixSeconds // 175
    local increment = (bell + 8 - (bell % 8)) % 24
    local totalDays = unixSeconds // 4200

    local calcBase = (totalDays * 100 + increment) & 0xFFFFFFFF
    local step1 = ((calcBase << 11) & 0xFFFFFFFF) ~ calcBase
    local step2 = (step1 >> 8) ~ step1

    return step2 % 100
end

function GetCurrentWeatherId(territoryId, unixSeconds)
    unixSeconds = unixSeconds or os.time()
    local rates = EorzeaWeatherRates[territoryId]
    if not rates then
        Dalamud.LogDebug(string.format("%s GetCurrentWeatherId: no weather rates for territory %d", LogPrefix, territoryId))
        return nil
    end

    local target = GetWeatherForecastTarget(unixSeconds)
    for _, entry in ipairs(rates) do
        local weatherId, cumulativeChance = entry[1], entry[2]
        if target < cumulativeChance then
            return weatherId
        end
    end

    return nil
end

function GetCurrentWeatherName(territoryId, unixSeconds)
    local weatherId = GetCurrentWeatherId(territoryId, unixSeconds)
    return weatherId and WeatherName[weatherId] or nil
end

function GetPreviousWeatherName(territoryId, unixSeconds)
    unixSeconds = unixSeconds or os.time()
    return GetCurrentWeatherName(territoryId, unixSeconds - 1400) -- 8 Eorzea hours = 8 * 175s
end

-------------------
--    Utility    --
-------------------

function OnChatMessage()
    local message = TriggerData.message

    if not message or not SelectedFish or not fishingStarted then
        return
    end

    if message:find(SelectedFish.name, 1, true) then
        catchDetected = true
        catchMessage = message
        Dalamud.Log(string.format("%s Detected chat match for %s: %s", LogPrefix, SelectedFish.name, message))
    end
end

function ConfigListAt(list, index)
    if not list then return nil end
    if list[0] ~= nil then
        return list[index]
    end
    return list[index + 1]
end

function BuildFishNameSet(configKey)
    local set = {}
    local config = Config.Get(configKey)

    if config and config.Count then
        for i = 0, config.Count - 1 do
            local fishName = ConfigListAt(config, i)
            if fishName and fishName ~= "" then
                set[fishName] = true
            end
        end
    elseif type(config) == "table" then
        for _, fishName in ipairs(config) do
            if fishName and fishName ~= "" then
                set[fishName] = true
            end
        end
    elseif type(config) == "string" and config ~= "" then
        for fishName in config:gmatch("[^\r\n,]+") do
            local trimmed = fishName:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed ~= "" then
                set[trimmed] = true
            end
        end
    end

    return set
end

function BuildDisabledFishSet()
    disabledFish = BuildFishNameSet("DisabledFish")
    ValidateFishNameSet("DisabledFish", disabledFish)
end

function BuildEnabledFishSet()
    enabledFish = BuildFishNameSet("EnabledFish")
    ValidateFishNameSet("EnabledFish", enabledFish)
end

function BuildBaitItemIdMap()
    baitItemIds = BaitItemIds
    baitChecksReady = true
    Dalamud.Log(string.format("%s Loaded static bait item ID map.", LogPrefix))
end

function HasRequiredBait(fish)
    if not baitChecksReady then
        return true
    end

    if not fish.bait or fish.bait == "" then
        return true
    end

    local baitItemId = baitItemIds[fish.bait]
    if not baitItemId then
        if not missingBaitLog[fish.name] then
            Dalamud.Log(string.format("%s Skipping %s: could not resolve bait item ID for '%s'.", LogPrefix, fish.name, fish.bait))
            missingBaitLog[fish.name] = true
        end
        return false
    end

    local baitCount = Inventory.GetItemCount(baitItemId)
    if baitCount == 0 then
        baitCount = Inventory.GetHqItemCount(baitItemId)
        if baitCount == 0 then
            baitCount = Inventory.GetCollectableItemCount(baitItemId, 1)
        end
    end

    if baitCount <= 0 then
        if not missingBaitLog[fish.name] then
            Dalamud.Log(string.format("%s Skipping %s: no bait '%s' in inventory.", LogPrefix, fish.name, fish.bait))
            missingBaitLog[fish.name] = true
        end
        return false
    end

    missingBaitLog[fish.name] = nil
    return true
end

function GetFishDataNames()
    if not fishDataNames then
        fishDataNames = {}
        for _, fish in ipairs(FishData) do
            fishDataNames[fish.name] = true
        end
    end
    return fishDataNames
end

function ValidateFishNameSet(configKey, set)
    local validNames = GetFishDataNames()
    for fishName in pairs(set) do
        if not validNames[fishName] then
            local logKey = configKey .. ":" .. fishName
            if not unknownFishLog[logKey] then
                Dalamud.Log(string.format("%s WARNING: '%s' in %s does not match any DT Big Fish. Check spelling.", LogPrefix, fishName, configKey))
                unknownFishLog[logKey] = true
            end
        end
    end
end

function HasExportedAutoHookPreset(fish)
    return fish and fish.autoHookPreset and fish.autoHookPreset ~= ""
end

function FishCanUseAutoHookPreset(fish)
    return UseNamedAutoHookPreset or HasExportedAutoHookPreset(fish) or not SkipFishWithoutPreset
end

function UseAnonymousAutoHookPreset(fish)
    return fish and not UseNamedAutoHookPreset and HasExportedAutoHookPreset(fish)
end

function SelectAutoHookPreset(fish)
    if UseAnonymousAutoHookPreset(fish) then
        IPC.AutoHook.CreateAndSelectAnonymousPreset(fish.autoHookPreset)
        Dalamud.Log(string.format("%s Selected anonymous AutoHook preset for %s.", LogPrefix, fish.name))
    else
        IPC.AutoHook.DeleteAllAnonymousPresets()
        IPC.AutoHook.SetPreset(fish.name)
        Dalamud.Log(string.format("%s Selected named AutoHook preset for %s.", LogPrefix, fish.name))
    end
end

function CleanupAutoHookPreset(fish)
    if HasExportedAutoHookPreset(fish) then
        IPC.AutoHook.DeleteAllAnonymousPresets()
    end
end

function IsFishUp(fish, unixSeconds)
    unixSeconds = unixSeconds or os.time()

    if fish.time ~= "Always" then
        local hour, minute = GetEorzeaTime(unixSeconds)
        local hourDecimal = hour + minute / 60

        local startHour, endHour = fish.time:match("^(%d+):%d+%-(%d+):%d+$")
        startHour, endHour = tonumber(startHour), tonumber(endHour)

        if endHour > startHour then
            if hourDecimal < startHour or hourDecimal >= endHour then
                return false
            end
        else
            -- window wraps past midnight (e.g. 20:00-2:00)
            if hourDecimal < startHour and hourDecimal >= endHour then
                return false
            end
        end
    end

    if fish.weather and fish.weather ~= "" then
        local currentWeather = GetCurrentWeatherName(fish.zoneId, unixSeconds)
        if not currentWeather or not string.find(fish.weather, currentWeather, 1, true) then
            return false
        end
    end

    if fish.previousWeather and fish.previousWeather ~= "" then
        local priorWeather = GetPreviousWeatherName(fish.zoneId, unixSeconds)
        if not priorWeather or not string.find(fish.previousWeather, priorWeather, 1, true) then
            return false
        end
    end

    return true
end

function IsFishReady(fish, unixSeconds)
    unixSeconds = unixSeconds or os.time()
    if IsFishUp(fish, unixSeconds) then
        return true
    end
    if fish.swimBait then
        return IsFishUp(fish, unixSeconds + SwimBaitPrepSeconds)
    end
    return false
end

-------------------
--    Fishing    --
-------------------

function IsFishAllowed(fish)
    if next(enabledFish) ~= nil then
        return enabledFish[fish.name] == true
    end
    return not disabledFish[fish.name]
end

function IsFishSelectable(fish)
    if not fish.x or not fish.y then
        return false
    end

    local cooldownUntil = lastAttempt[fish.name]
    return IsFishAllowed(fish)
        and HasRequiredBait(fish)
        and FishCanUseAutoHookPreset(fish)
        and (not cooldownUntil or os.time() >= cooldownUntil)
end

function HasUpcomingSelectableFish(secondsAhead)
    if secondsAhead <= 0 then
        return false
    end

    local futureTime = os.time() + secondsAhead
    for _, fish in ipairs(FishData) do
        if IsFishSelectable(fish) and IsFishReady(fish, futureTime) then
            return true
        end
    end
    return false
end

function SelectNextFish()
    for _, fish in ipairs(FishData) do
        if IsFishSelectable(fish) and IsFishUp(fish) then
            return fish
        end
    end

    -- Idle fallback: nothing actually open - get a head start on swimBait
    -- fish so bait can be caught before the window opens.
    for _, fish in ipairs(FishData) do
        if fish.swimBait and IsFishSelectable(fish) and IsFishReady(fish) then
            return fish
        end
    end

    return nil
end

function TeleportToIdleOnce()
    if not UseIdleTeleport then
        return
    end

    if idleTeleported then
        return
    end

    if HasUpcomingSelectableFish(idleHoldoff) then
        if not loggedIdleBusy then
            Dalamud.Log(string.format("%s Idle teleport skipped: fish window or swim-bait prep is close.", LogPrefix))
            loggedIdleBusy = true
        end
        return
    end

    if not (Player and Player.Available and not Player.IsBusy)
        or Svc.Condition[CharacterCondition.fishing]
        or Svc.Condition[CharacterCondition.gathering]
        or IPC.Lifestream.IsBusy()
    then
        if not loggedIdleBusy then
            Dalamud.Log(string.format("%s Idle teleport postponed: player is busy or unavailable.", LogPrefix))
            loggedIdleBusy = true
        end
        return
    end

    idleTeleported = true
    loggedIdleBusy = false
    Dalamud.Log(string.format("%s Returning to Lifestream auto idle spot.", LogPrefix))
    IPC.Lifestream.ExecuteCommand("auto")
end

function CharacterState.selectFish()
    BuildDisabledFishSet()
    BuildEnabledFishSet()

    local fish = SelectNextFish()

    if not fish then
        if not loggedIdle then
            Dalamud.Log(string.format("%s No fish window currently open. Waiting...", LogPrefix))
            loggedIdle = true
        end
        TeleportToIdleOnce()
        return
    end

    loggedIdle = false
    idleTeleported = false
    loggedIdleBusy = false
    SelectedFish = fish
    Dalamud.Log(string.format("%s Selected fish: %s (%s, bait: %s)", LogPrefix, SelectedFish.name, SelectedFish.spotName, SelectedFish.bait))
    State = CharacterState.teleportToZone
    Dalamud.Log(string.format("%s State Changed -> TeleportToZone", LogPrefix))
    Wait(0.3)
end

function CharacterState.teleportToZone()
    if not IsFishReady(SelectedFish) then
        Dalamud.Log(string.format("%s %s's window closed before arrival.", LogPrefix, SelectedFish.name))
        State = CharacterState.selectFish
        Dalamud.Log(string.format("%s State Changed -> SelectFish", LogPrefix))
        return
    end

    if Svc.ClientState.TerritoryType ~= SelectedFish.zoneId then
        local aetheryteName = SelectedFish.aetheryte
        if not aetheryteName or aetheryteName == "" then
            local territoryData = Excel.GetRow("TerritoryType", SelectedFish.zoneId)
            aetheryteName = territoryData and territoryData.Aetheryte and territoryData.Aetheryte.PlaceName and tostring(territoryData.Aetheryte.PlaceName.Name) or nil
        end
        if aetheryteName then
            IPC.Lifestream.ExecuteCommand(aetheryteName)
            Wait(0.1)
            repeat
                Wait(0.1)
            until not IPC.Lifestream.IsBusy() and (Player and Player.Available and not Player.IsBusy)

            local teleportStart = os.time()
            repeat
                Wait(0.1)
            until not (Player.Entity and Player.Entity.IsCasting) or (os.time() - teleportStart) >= 300
            Wait(0.1)

            repeat
                Wait(0.1)
            until (not Svc.Condition[CharacterCondition.betweenAreas] and Player and Player.Available and not Player.IsBusy) or (os.time() - teleportStart) >= 300
            Wait(0.1)
            Wait(0.3)
        end
        return
    end

    if not (Player and Player.Available and not Player.IsBusy) then
        return
    end

    State = CharacterState.travelToSpot
    Dalamud.Log(string.format("%s State Changed -> TravelToSpot", LogPrefix))
    Wait(0.3)
end

function CharacterState.travelToSpot()
    if not IsFishReady(SelectedFish) then
        Dalamud.Log(string.format("%s %s's window closed before arrival.", LogPrefix, SelectedFish.name))
        State = CharacterState.selectFish
        Dalamud.Log(string.format("%s State Changed -> SelectFish", LogPrefix))
        return
    end

    if Svc.ClientState.TerritoryType ~= SelectedFish.zoneId then
        State = CharacterState.teleportToZone
        Dalamud.Log(string.format("%s State Changed -> TeleportToZone", LogPrefix))
        return
    end

    while not IPC.vnavmesh.IsReady() do
        Wait(0.1)
    end

    local arrived

    if not Player.CanMount then
        Dalamud.Log(string.format("%s Walking to %s (%.1f, %.1f)", LogPrefix, SelectedFish.spotName, SelectedFish.worldX, SelectedFish.worldZ))
        arrived = MoveTo(SelectedFish.worldX, SelectedFish.worldY, SelectedFish.worldZ)
        Wait(0.3)
    else
        if not Svc.Condition[CharacterCondition.mounted] then
            local mountStart = os.time()
            repeat
                Actions.ExecuteGeneralAction(CharacterAction.GeneralActions.mount)
                Wait(1)
            until Svc.Condition[CharacterCondition.mounted] or (os.time() - mountStart) > 10
        end
        Wait(0.3)
        local fly = Player.CanFly
        Dalamud.Log(string.format("%s %s to %s (%.1f, %.1f)", LogPrefix, fly and "Flying" or "Riding", SelectedFish.spotName, SelectedFish.worldX, SelectedFish.worldZ))
        MoveTo(SelectedFish.worldX, SelectedFish.worldY, SelectedFish.worldZ, 0, fly)

        while Svc.Condition[CharacterCondition.mounted] do
            Actions.ExecuteGeneralAction(CharacterAction.GeneralActions.dismount)
            Wait(1)
        end

        local landedPos = GetPlayerPosition()
        arrived = landedPos and GetDistance(landedPos, Vector3(SelectedFish.worldX, SelectedFish.worldY, SelectedFish.worldZ)) <= 1.0
        Wait(0.3)
    end

    if not arrived then
        Dalamud.Log(string.format("%s Failed to reach %s's spot. Cooling down and retrying later.", LogPrefix, SelectedFish.name))
        lastAttempt[SelectedFish.name] = os.time() + RetryCooldownSeconds
        State = CharacterState.selectFish
        Dalamud.Log(string.format("%s State Changed -> SelectFish", LogPrefix))
        return
    end

    local fishX = SelectedFish.fishX or SelectedFish.worldX
    local fishY = SelectedFish.fishY or SelectedFish.worldY
    local fishZ = SelectedFish.fishZ or SelectedFish.worldZ
    if fishX ~= SelectedFish.worldX or fishZ ~= SelectedFish.worldZ then
        Dalamud.Log(string.format("%s Walking to casting spot (%.1f, %.1f)", LogPrefix, fishX, fishZ))
        local fishArrived = MoveTo(fishX, fishY, fishZ)
        Wait(0.3)

        if not fishArrived then
            Dalamud.Log(string.format("%s Failed to reach %s's casting spot. Cooling down and retrying later.", LogPrefix, SelectedFish.name))
            lastAttempt[SelectedFish.name] = os.time() + RetryCooldownSeconds
            State = CharacterState.selectFish
            Dalamud.Log(string.format("%s State Changed -> SelectFish", LogPrefix))
            return
        end
    end

    State = CharacterState.fishing
    Dalamud.Log(string.format("%s State Changed -> Fishing", LogPrefix))
    Wait(0.3)
end

function CharacterState.fishing()
    if not fishingStarted then
        if not IsFishReady(SelectedFish) then
            Dalamud.Log(string.format("%s %s's window closed before fishing started.", LogPrefix, SelectedFish.name))
            CleanupAutoHookPreset(SelectedFish)
            State = CharacterState.selectFish
            Dalamud.Log(string.format("%s State Changed -> SelectFish", LogPrefix))
            return
        end

        if not (Player and Player.Available and not Player.IsBusy) then
            return
        end

        Dalamud.Log(string.format("%s Starting AutoHook preset: %s", LogPrefix, SelectedFish.name))
        catchDetected = false
        catchMessage = nil
        forcedQuit = false
        windowClosedAt = nil
        windowOpenedAt = IsFishUp(SelectedFish)
        SelectAutoHookPreset(SelectedFish)
        IPC.AutoHook.SetPluginState(true)
        Wait(1)
        local ahStartedAt = os.time()
        while not Svc.Condition[CharacterCondition.fishing] and (os.time() - ahStartedAt) < 10 do
            Engines.Run("/ahstart")
            Wait(4)
        end

        if Svc.Condition[CharacterCondition.fishing] then
            fishingStarted = true
        else
            Dalamud.Log(string.format("%s AutoHook failed to start fishing for %s. Forcing quit to recover.", LogPrefix, SelectedFish.name))
            CleanupAutoHookPreset(SelectedFish)
            Actions.ExecuteAction(CharacterAction.Actions.quitFishing, ActionType.Action)
            Wait(0.3)
        end
        return
    end

    if IsFishUp(SelectedFish) then
        windowOpenedAt = true
        windowClosedAt = nil
    elseif windowOpenedAt then
        if Svc.Condition[CharacterCondition.fishing] or Svc.Condition[CharacterCondition.gathering] then
            if not windowClosedAt then
                windowClosedAt = os.time()
                Dalamud.Log(string.format("%s %s's window closed while fishing. Forcing quit in %.0f seconds.", LogPrefix, SelectedFish.name, ForceQuitDelaySeconds))
            end

            if os.time() - windowClosedAt >= ForceQuitDelaySeconds then
                forcedQuit = true
                Actions.ExecuteAction(CharacterAction.Actions.quitFishing, ActionType.Action)
                Wait(0.3)
            end
            return
        end
    end

    if Svc.Condition[CharacterCondition.fishing] or Svc.Condition[CharacterCondition.gathering] then
        Wait(1)
        return
    end

    -- Gathering ended: either we saw a catch message, forced a quit when the
    -- window closed, or something external interrupted the attempt.
    if catchDetected then
        Dalamud.Log(string.format("%s Confirmed catch for %s.", LogPrefix, SelectedFish.name))
        if catchMessage then
            Dalamud.Log(string.format("%s Catch message: %s", LogPrefix, catchMessage))
        end
    elseif forcedQuit then
        Dalamud.Log(string.format("%s Ended attempt on %s after the window closed.", LogPrefix, SelectedFish.name))
    else
        Dalamud.Log(string.format("%s Finished attempt on %s without a confirmed catch.", LogPrefix, SelectedFish.name))
    end

    local cooldownSeconds = catchDetected and CaughtCooldownSeconds or RetryCooldownSeconds
    lastAttempt[SelectedFish.name] = os.time() + cooldownSeconds
    CleanupAutoHookPreset(SelectedFish)
    fishingStarted = false
    catchDetected = false
    catchMessage = nil
    forcedQuit = false
    windowClosedAt = nil
    windowOpenedAt = false
    State = CharacterState.selectFish
    Dalamud.Log(string.format("%s State Changed -> SelectFish", LogPrefix))
    Wait(0.3)
end

--=========================== EXECUTION ===========================--

for _, fish in ipairs(FishData) do
    if not fish.y then
        Dalamud.Log(string.format("%s WARNING: %s has no valid coordinates (source data error) - skipping until fixed.", LogPrefix, fish.name))
    end
end

BuildBaitItemIdMap()

if not (Player and Player.Job and Player.Job.Id == 18) then
    Dalamud.Log(string.format("%s Switching to Fisher.", LogPrefix))
    Engines.Run("/gs change Fisher")
    Wait(1)
end

State = CharacterState.selectFish
Dalamud.Log(string.format("%s State Changed -> SelectFish", LogPrefix))

while true do
    State()
    Wait(1)
end

--============================== END ==============================--
