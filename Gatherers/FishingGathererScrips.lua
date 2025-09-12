--[=====[
[[SND Metadata]]
author:  'pot0to (https://ko-fi.com/pot0to) || Maintainer: Minnu (https://ko-fi.com/minnuverse)'
version: 2.0.3
description: Fishing Gatherer Scrips - Script for Fishing & Turning In
plugin_dependencies:
- AutoHook
- AutoRetainer
- Lifestream
- vnavmesh
- YesAlready
configs:
  ScripColorToFarm:
    description: Type of scrip to farm (Orange, Purple).
    is_choice: true
    choices:
        - "Orange"
        - "Purple"
  ItemToExchange:
    description: Name of the item to purchase using scrips.
    is_choice: true
    choices:
        - "Mount Token"
        - "Hi-Cordial"
        - "Gatherer's Guerdon Materia XII"
        - "Gatherer's Guile Materia XII"
        - "Gatherer's Grasp Materia XII"
        - "Gatherer's Guerdon Materia XI"
        - "Gatherer's Guile Materia XI"
        - "Gatherer's Grasp Materia XI"
  Food:
    description: Leave blank if you don't want to use any food. If its HQ include <hq> next to the name "Baked Eggplant <hq>".
  Potion:
    description: Leave blank if you don't want to use any potions. If its HQ include <hq> next to the name "Superior Spiritbond Potion <hq>".
  HubCity:
    description: Main city to use as a hub for turn-ins and purchases (Ul'dah, Limsa, Gridania, or Solution Nine).
    is_choice: true
    choices:
        - "Limsa"
        - "Gridania"
        - "Ul'dah"
        - "Solution Nine"
  MinInventoryFreeSlots:
    description: Minimum free inventory slots required to start turn-ins.
    default: 5
    min: 0
    max: 140
  DoAutoRetainers:
    description: Automatically interact with retainers for ventures.
    default: true
  GrandCompanyTurnIn:
    description: Automatically turn in eligible items to your Grand Company for seals.
    default: false
  SelfRepair:
    description: Automatically repair your own gear when durability is low.
    default: true
  BuyDarkMatter:
    description: Buy Dark Matter for self repair.
    default: true
  RepairThreshold:
    description: Durability percentage at which tools should be repaired.
    default: 20
    min: 0
    max: 100
  ExtractMateria:
    description: Automatically extract materia from fully spiritbonded gear.
    default: true
  MoveSpotsAfter:
    description: Number of minutes to fish one spot before moving to the next.
    default: 30
  ResetHardAmissAfter:
    description: Number of minutes to farm in current instance before teleporting away and back.
    default: 120

[[End Metadata]]
--]=====]

--[[
********************************************************************************
*                            Fishing Gatherer Scrips                           *
*                                Version 2.0.3                                 *
********************************************************************************

Created by:     pot0to (https://ko-fi.com/pot0to)
Maintained by:  Minnu  (https://ko-fi.com/minnuverse)

    -> 2.0.3    Fixed index for mount tokens
    -> 2.0.2    Fixed stuck while using mount
    -> 2.0.1    Bug Fixes
                Added config for BuyDarkMatter
                Removed config for unused ReduceEphemerals
    -> 2.0.0    Updated for SnD 2.0
    -> 1.4.9    Remove the whole "false if none" part
                Abort old attempts at amiss checks, just set a timer for how
                    long you want to stay in current instance
                Added another /wait 1 to scrip exchange
                Updating amiss to _FlyText instead of _TextError
                Updating hard amiss again
                Update hard amiss check
                Separate IsAddonReady and Addons.GetAddon
                Fix typo
                Added more logging statements
                Added soft and hard amiss checks

********************************************************************************
*                               Required Plugins                               *
********************************************************************************

1. AutoHook
2. VnavMesh
3. Lifestream
4. Teleporter
5. YesAlready: YesNo > ... (the 3 dots) > Auto Collectables https://github.com/PunishXIV/AutoHook/blob/main/AcceptCollectable.md

]]

--=========================== VARIABLES ==========================--

import("System")
import("System.Numerics")

-------------------
--    General    --
-------------------

ScripColorToFarm       = Config.Get("ScripColorToFarm")
ItemToExchange         = Config.Get("ItemToExchange")
Food                   = Config.Get("Food")
Potion                 = Config.Get("Potion")
HubCity                = Config.Get("HubCity")
MinInventoryFreeSlots  = Config.Get("MinInventoryFreeSlots")
DoAutoRetainers        = Config.Get("DoAutoRetainers")
GrandCompanyTurnIn     = Config.Get("GrandCompanyTurnIn")
SelfRepair             = Config.Get("SelfRepair")
BuyDarkMatter          = Config.Get("BuyDarkMatter")
RepairThreshold        = Config.Get("RepairThreshold")
ExtractMateria         = Config.Get("ExtractMateria")
MoveSpotsAfter         = Config.Get("MoveSpotsAfter")
ResetHardAmissAfter    = Config.Get("ResetHardAmissAfter")

------------------
--    Scrips    --
------------------

OrangeGathererScripId = 41785
PurpleGathererScripId = 33914

--============================ CONSTANT ==========================--

----------------------------
--    State Management    --
----------------------------

CharacterState = {}

CharacterCondition = {
    mounted                            = 4,
    gathering                          = 6,
    casting                            = 27,
    occupiedInQuestEvent               = 32,
    occupiedMateriaExtractionAndRepair = 39,
    fishing                            = 43,
    betweenAreas                       = 45,
    occupiedSummoningBell              = 50
}

-----------------
--    Items    --
-----------------

ScripExchangeItems = {
    {
        itemName        = "Mount Token",
        categoryMenu    = 4,
        subcategoryMenu = 8,
        listIndex       = 7,
        price           = 1000
    },
    {
        itemName        = "Hi-Cordial",
        categoryMenu    = 4,
        subcategoryMenu = 1,
        listIndex       = 0,
        price           = 20
    },
    {
        itemName        = "Gatherer's Guerdon Materia XI",
        categoryMenu    = 5,
        subcategoryMenu = 1,
        listIndex       = 0,
        price           = 250
    },
    {
        itemName        = "Gatherer's Guile Materia XI",
        categoryMenu    = 5,
        subcategoryMenu = 1,
        listIndex       = 1,
        price           = 250
    },
    {
        itemName        = "Gatherer's Grasp Materia XI",
        categoryMenu    = 5,
        subcategoryMenu = 1,
        listIndex       = 2,
        price           = 250
    },
    {
        itemName        = "Gatherer's Guerdon Materia XII",
        categoryMenu    = 5,
        subcategoryMenu = 2,
        listIndex       = 0,
        price           = 500
    },
    {
        itemName        = "Gatherer's Guile Materia XII",
        categoryMenu    = 5,
        subcategoryMenu = 2,
        listIndex       = 1,
        price           = 500
    },
    {
        itemName        = "Gatherer's Grasp Materia XII",
        categoryMenu    = 5,
        subcategoryMenu = 2,
        listIndex       = 2,
        price           = 500
    },
}

--------------------
--    Merchant    --
--------------------

FishingBaitMerchant = {
    npcName   = "Merchant & Mender",
    x         = -398,
    y         = 3,
    z         = 80,
    zoneId    = 129,
    aetheryte = "Limsa Lominsa",
    aethernet = { name = "Arcanists' Guild", x = -336, y = 12, z = 56 }
}

Mender = {
    npcName   = "Alistair",
    x         = -246.87,
    y         = 16.19,
    z         = 49.83
}

DarkMatterVendor = {
    npcName   = "Unsynrael",
    x         = -257.71,
    y         = 16.19,
    z         = 50.11,
    wait      = 0.08
}

------------------------
--    Collectables    --
------------------------

FishTable = {
    {
        fishName                    = "Zorgor Condor",
        fishId                      = 43761,
        baitName                    = "Versatile Lure",
        zoneId                      = 1190,
        zoneName                    = "Shaaloani",
        autoHookPreset              = "AH4_H4sIAAAAAAAACu1YS3PbNhD+KxqciQ5JgC/dFMVJ3bGdTOS2M/XksAKXEsYUoYBgEjej/94BHxIpiXaT8SHt+EYuFt8+uPiwy29kVhk1h9KU82xFpt/IRQHLHGd5TqZGV+iQDyigNLNCbsBIVcyhELhfnK+rzdgSlOZKFmhB3xX5Q/0OeoWdQmMp7V4vUzL148Qh77VUWpoHMvUccllefBV5lWJ6EFv9XWPgWimxthbqB98+1Thh7JC329u1xnKt8pRMPdcdID8OXWMk0WCH+6QzNhmdB9xz+RMudLtUnqMwh9wPMsI91+vv8p/2QulUQj6C5/lhOMgxb7e9keX64gHLXgDBUQBBMAgg7L4B3ONiLTPzCmQdhhWUnWBhQNyXZBq0WQ3jU9w+atKivgcjsRDY8yc83hcOE+p3W7X8G+dgmso4V2ZhfALmH30d1oLdriGXcF++gc9KW7yBoIuOOUP5BxTqM2oy9WzORlzgA4NdOl/J1VvY1HHPilWOuuyM2G+fkimLXH7i/QAq3u0ccvHVaGgPtf0Qt2rxBbaXhamkPaxvQRZdbqnnkKtK4zWWJdgDSohDbmonyI0qkDgNwsMWydQm5gzelSrND+O911jieQ8JJSPrjcV6/eDPYovCaMjnldZYmGeK8gj12WI96+1JxGet11pvlBZYn7IvsO3KqxamVtrSmBc5bSktjNragy6L1cLgtmbYQ5Rtuc308wTXh6u9/b2Qnyq0uIQlIg3SOKTBkiPlbJnQOAoEFcvU9WMfA4/FZOeQK1mad5m1UZLpXVPINoA90TfRjfn4B+oSjMxxYjUs4I3SG8h/VereQnQk8ydC/W7lJZr9ec0gL/c3VbvYT3UrauLnXmTJq8NcGK2K3pU6sv1WblAfEcS1LPZLZOolv7gnplzWM3WFKyxS0A/PEEMN/FpVy/w4K42GHyZ7hUOIoyrnXOtr3Wq5HbMUBT7bq4zZGig9Yq3VsydglhnUc6hWa3MlN/bO8pqF46NRtyyVbi5F+9Cj+6bZmRmDm63pcml1bm2P02D+27aHRUFy2i08ctPbFqWjwa6WP+CnSmpMFwZMZS9c2wONFPgTBfu9tfZSO99XO89UAj0+jX0esYy5NOFiSXmcuRQCH6iL6AUuC9Io5GTnnBIoZ3HAxgl0DsJUoCe/ydV/mj2v4WtPxvgLo/58p+KFUV8Y9Udr5xkoNEJMIiEymgSJR7nLU7oMGVA3hSCKGHgiTMnuY9eTtn8e7vaChlXvvpEhvUZBMk6vfym9UnqyEEpvpSoG7bT3WH4uUyyMFJDbpFhjjcJso6pioEamPEiOp0U2HORja6nSGQhc5JbGWt+DJHhiSA52DvlpfsEcBpkfHl/sZiuZ2zTWGewPNO0YYx8b8UHtXL32r2eWeZjyJUWIXMp5CjRhbkj9CCMv8zI3S6P6ej6qHfuDY3S2gZWGwkzmUApIh7G81M7/p3YCFwH9hNEoCQTlLMloHPmMiihZehnHjGVezUsNbuvi3eLm9cdJyy9zVaRKT+jknYZihZOF0HJbDidy3+eQcR8piwSjPGKcxhinNGNLz4U4YVnokd0/8SCndDAWAAA=",
        fishingSpots = {
            maxHeight               = 1024,
            waypoints = {
                { x =  -4.47, y = -6.85, z =  747.47 },
                { x =  59.27, y = -2.00, z =  735.09 },
                { x = 135.71, y =  6.12, z =  715.00 },
                { x = 212.50, y = 12.20, z =  739.26 }
            },
            pointToFace             = { x = 134.07, y = 6.07, z = 10000 }
        },
        scripColor                  = "Orange",
        scripId                     = 39,
        collectiblesTurnInListIndex = 6
    },
    {
        fishName                    = "Fleeting Brand",
        fishId                      = 36473,
        baitName                    = "Versatile Lure",
        zoneId                      = 959,
        zoneName                    = "Mare Lamentorum",
        autoHookPreset              = "AH4_H4sIAAAAAAAACu1YTVPjOBD9K5TP8ZS/bXELGWCpCgxFwu5hag+K3U5UOFZGllnYKf77tGwrsROHTE0RigM3py29/tBT+3V+GsNS8hEtZDFK58bpT+M8p7MMhllmnEpRwsBQL8csh83LRL+6wicnIgPjVjAumHw2Tm20FudPcVYmkGzMav1LjXXNebxQYNWDo54qnCAaGJer6UJAseAZWmzL6iC/Dl1hkLCzwzoYzGhRLnUEnm15B0LQu3iWQSz3VARx7PYu53AUXCSMZlUg+SMIbeguHvQ5s50gIFtRe92ou0kNZ/wRzzKlWaHdX7Bicf4MRasQ/hak73cgA32W9AEmC5bKM8qqcihDoQ0TSeMHREWw5oR3cduopEG9pZJBHu9jHIYXbMME3XNyNJJg/8OIyppwOojt3c7WKbvN7umCZow+FBf0kQsF0DHo7NxB134HMVYY19uqZn03BkPYJprbCUCX94zNL+myqsMwn2cgCu1UcUptCy1vJ5sOVPSCWOdPUtDmfquDmfLJf3R1lcuSScbzS8pyXR8TqTsuBVxDUdA5ujaMgXFTBWHccOwCgxrheYUWVagevDEv5B/j3WIi0B+hYRp73tceq/ebeCYrvKOCZqNSCMjlG2W5hfpmufZGu5Nxr/dq1QUXMVS3DpdpulXGRFmb9mhjg6ypNJF8pS4+y+cTCbjDbmfZ0G0o3ia5NlwV7X3OfpSgcA3iOjQEyzMdElumF6SOSfzANS3iOb6b2mmUOAbijVkhv6XKB/L/e01klcD6ZtfZ7Yvxb/SPfSWDE7VCAd5wsaTZX5w/KAjddP4BWv1Wdox/fX+rhqnvc/OyXWplmrIliK0bf83y9Sv1EfuCMV7Tp7aNfMFG0UDW9fPsUDVDHdNECp63vs7Hd2+5LfdjmEOeUPH8AepSBfaVlwh14KTe1LETkLXfzWkczcXvVPwIzqeCrd65rqHvuGvPx6psx8n711a7xxW8RM30pCSHWqZ68DCVIEa0nC9QZS+VisJG29ecKx2OrauSaeqhJUBqLeCTXf3aFQOvKFElofXnVPfEO/hRMgEJepKlEnJKo/c1yuM3vnftb5/96rNfffarD9ad2pLRjokTOLHpzMBByQixSSIvMiPHBuLOXC+CmfHyr9aMzT8O39eGWjaihmzrRzfwQne/frzIACRmfHImaJ501K69t1hqArxKUKizGDU7lkg5+5Znz/cF3OcJiM2oq/9sUbuHS17mrYL3DcE+2R78XOXtK8/liCJi1mTdfNE29YxUtKVIKbbXTOm0Zuj3iX9gLvZx54f592Yzq/zxhKI2K8tIVbsqdHtmaSYV9VibN8t2L4DV4SekLtA4Sk0IrdT0EhxuZkCQpJAEbhTQgEYRTiC7/PP3Z3AHcy45K+A3qWf3MK+fXa/R6VXa9NOyl0WHafnJrv3s6pAr9KiTBkFiztw4ML04IiaxPcukgQWJ68dBQurmV7O2t32dmCe3pUAxfDKJURQX3Ync9jybBHFo2mGM7ZXYIbbXNDEpsZyZP6OEhIHx8gtuKGkNOxYAAA==",
        fishingSpots = {
            maxHeight               = 35,
            waypoints = {
                { x = 10.05, y = 26.89, z = 448.99 },
                { x = 37.71, y = 22.36, z = 481.05 },
                { x = 58.87, y = 22.22, z = 487.95 },
                { x = 71.79, y = 22.39, z = 477.65 }
            },
            pointToFace             = { x = 37.71, y = 22.36, z = 1000 }
        },
        scripColor                  = "Purple",
        scripId                     = 38,
        collectiblesTurnInListIndex = 28
    }
}

-------------------
--    HubCity    --
-------------------

HubCities = {
    {
        zoneName = "Limsa",
        zoneId = 129,
        aethernet = {
            aethernetZoneId = 129,
            aethernetName   = "Hawkers' Alley",
            x = -213.61108, y = 16.739136, z = 51.80432
        },
        retainerBell  = { x = -124.703, y = 18, z = 19.887, requiresAethernet = false },
        scripExchange = { x = -258.52585, y = 16.2, z = 40.65883, requiresAethernet = true }
    },
    {
        zoneName = "Gridania",
        zoneId = 132,
        aethernet = {
            aethernetZoneId = 133,
            aethernetName   = "Leatherworkers' Guild & Shaded Bower",
            x = 131.9447, y = 4.714966, z = -29.800903
        },
        retainerBell  = { x = 168.72, y = 15.5, z = -100.06, requiresAethernet = true },
        scripExchange = { x = 142.15, y = 13.74, z = -105.39, requiresAethernet = true }
    },
    {
        zoneName = "Ul'dah",
        zoneId = 130,
        aethernet = {
            aethernetZoneId = 131,
            aethernetName   = "Sapphire Avenue Exchange",
            x = 101, y = 9, z = -112
        },
        retainerBell  = { x = 146.760, y = 4, z = -42.992, requiresAethernet = true },
        scripExchange = { x = 147.73, y = 4, z = -18.19, requiresAethernet = true }
    },
    {
        zoneName = "Solution Nine",
        zoneId = 1186,
        aethernet = {
            aethernetZoneId = 1186,
            aethernetName   = "Nexus Arcade",
            x = -161, y = -1, z = 21
        },
        retainerBell  = { x = -152.465, y = 0.660, z = -13.557, requiresAethernet = true },
        scripExchange = { x = -158.019, y = 0.922, z = -37.884, requiresAethernet = true }
    }
}

--=========================== FUNCTIONS ==========================--

-------------------
--    Actions    --
-------------------

function Mount()
    local mountActionId = 9
    Dalamud.Log("[FishingScrips] Using Mount Roulette...")
    repeat
        Actions.ExecuteGeneralAction(mountActionId)
        yield("/wait 1")
    until Svc.Condition[CharacterCondition.mounted]
end

function Dismount()
    local dismountActionId = 23
    repeat
        Actions.ExecuteGeneralAction(dismountActionId)
        yield("/wait 1")
    until not Svc.Condition[CharacterCondition.mounted]
end

function CastFishing()
    local castFishingActionId = 289
    Actions.ExecuteAction(castFishingActionId, ActionType.Action)
end

function QuitFishing()
    local quitFishingActionId = 299
    Actions.ExecuteAction(quitFishingActionId, ActionType.Action)
end

-------------------
--    Utility    --
-------------------

function WaitForPlayer()
    Dalamud.Log("[FishingScrips] Waiting for player...")
    repeat
        yield("/wait 0.1")
    until Player.Available and not Player.IsBusy
    yield("/wait 0.1")
end

function GetAetheryteName(zoneId)
    local territoryData = Excel.GetRow("TerritoryType", zoneId)

    if territoryData and territoryData.Aetheryte and territoryData.Aetheryte.PlaceName then
        return tostring(territoryData.Aetheryte.PlaceName.Name)
    else
        return nil
    end
end

function TeleportTo(aetheryteName)
    IPC.Lifestream.ExecuteCommand(aetheryteName)
    yield("/wait 1")
    while Svc.Condition[CharacterCondition.casting] do
        yield("/wait 1")
    end
    yield("/wait 1")
    while Svc.Condition[CharacterCondition.betweenAreas] do
        yield("/wait 1")
    end
    yield("/wait 1")
end

function OnChatMessage()
    local message = TriggerData.message
    local patternToMatch = "The fish sense something amiss. Perhaps it is time to try another location."

    if message and message:find(patternToMatch) then
        Dalamud.Log("[FishingScrips] OnChatMessage triggered for Fish sense..!!")
        State = CharacterState.gsFishSense
        Dalamud.Log("[FishingScrips] State Changed → FishSense")
    end
end

function NeedsRepair(repairThreshold)
    local repairList = Inventory.GetItemsInNeedOfRepairs(repairThreshold)
    local needsRepair = repairList.Count > 0
    Dalamud.Log(string.format("[FishingScrips] Items below %d%% durability: %s", repairThreshold, needsRepair and repairList.Count or "None"))
    return needsRepair
end

function CanExtractMateria()
    local bondedItems = Inventory.GetSpiritbondedItems()
    local count = (bondedItems and bondedItems.Count) or 0
    Dalamud.Log(string.format("[FishingScrips] Found %d spiritbonded items.", count))
    return count
end

function HasStatusId(statusId)
    local statusList = Player.Status

    if not statusList then
        return false
    end

    for i = 0, statusList.Count - 1 do
        local status = statusList:get_Item(i)
        if status and status.StatusId == statusId then
            return true
        end
    end

    return false
end

-------------------
--    Fishing    --
-------------------

function InterpolateCoordinates(startCoords, endCoords, n)
    local x = startCoords.x + n * (endCoords.x - startCoords.x)
    local y = startCoords.y + n * (endCoords.y - startCoords.y)
    local z = startCoords.z + n * (endCoords.z - startCoords.z)
    return { waypointX = x, waypointY = y, waypointZ = z }
end

function GetWaypoint(coords, n)
    local total_distance = 0
    local distances = {}

    for i = 1, #coords - 1 do
        local dx = coords[i + 1].x - coords[i].x
        local dy = coords[i + 1].y - coords[i].y
        local dz = coords[i + 1].z - coords[i].z
        local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
        table.insert(distances, distance)
        total_distance = total_distance + distance
    end

    local target_distance = n * total_distance

    local accumulated_distance = 0
    for i = 1, #coords - 1 do
        if accumulated_distance + distances[i] >= target_distance then
            local remaining_distance = target_distance - accumulated_distance
            local t = remaining_distance / distances[i]
            return InterpolateCoordinates(coords[i], coords[i + 1], t)
        end
        accumulated_distance = accumulated_distance + distances[i]
    end

    return { waypointX = coords[#coords].x, waypointY = coords[#coords].y, waypointZ = coords[#coords].z }
end

local logged = false
function SelectNewFishingHole()
    logged = false
    SelectedFishingSpot = GetWaypoint(SelectedFish.fishingSpots.waypoints, math.random())
    local point = IPC.vnavmesh.PointOnFloor(Vector3(SelectedFishingSpot.waypointX, SelectedFish.fishingSpots.maxHeight, SelectedFishingSpot.waypointZ), false, 50)
    SelectedFishingSpot.waypointY = (point and point.Y) or SelectedFishingSpot.waypointY or 0

    SelectedFishingSpot.x = SelectedFish.fishingSpots.pointToFace.x
    SelectedFishingSpot.y = SelectedFish.fishingSpots.pointToFace.y
    SelectedFishingSpot.z = SelectedFish.fishingSpots.pointToFace.z

    SelectedFishingSpot.startTime = os.clock()
    SelectedFishingSpot.lastStuckCheckPosition = { x = Player.Entity.Position.X, y = Player.Entity.Position.Y, z = Player.Entity.Position.Z }
end

function RandomAdjustCoordinates(x, y, z, maxDistance)
    local angle = math.random() * 2 * math.pi
    local distance = maxDistance * math.random()

    local randomX = x + distance * math.cos(angle)
    local randomY = y + maxDistance
    local randomZ = z + distance * math.sin(angle)

    return randomX, randomY, randomZ
end

function CharacterState.gsFishSense()
    if Svc.Condition[CharacterCondition.gathering] or Svc.Condition[CharacterCondition.fishing] then
        QuitFishing()
    end

    WaitForPlayer()
    State = CharacterState.gsTeleportFishingZone
    Dalamud.Log("[FishingScrips] State Changed → TeleportFishingZone")
end

function CharacterState.gsTeleportFishingZone()
    if Svc.ClientState.TerritoryType ~= SelectedFish.zoneId then
        local aetheryteName = GetAetheryteName(SelectedFish.zoneId)
        if aetheryteName then
            TeleportTo(aetheryteName)
        end
    elseif Player.Available and not Player.IsBusy then
        yield("/wait 1")
        SelectNewFishingHole()
        ResetHardAmissTime = os.clock()
        State = CharacterState.gsGoToFishingHole
        Dalamud.Log("[FishingScrips] State Changed → GoToFishingHole")
    end
end

function CharacterState.gsGoToFishingHole()
    if Svc.ClientState.TerritoryType ~= SelectedFish.zoneId then
        State = CharacterState.gsTeleportFishingZone
        Dalamud.Log("[FishingScrips] State Changed → TeleportFishingZone")
        return
    end

    local now = os.clock()
    if now - SelectedFishingSpot.startTime > 10 then
        SelectedFishingSpot.startTime = now
        local x = Player.Entity.Position.X
        local y = Player.Entity.Position.Y
        local z = Player.Entity.Position.Z

        local lastStuckCheckPosition = SelectedFishingSpot.lastStuckCheckPosition

        if lastStuckCheckPosition and lastStuckCheckPosition.x and lastStuckCheckPosition.y and lastStuckCheckPosition.z then
            if GetDistanceToPoint(lastStuckCheckPosition.x, lastStuckCheckPosition.y, lastStuckCheckPosition.z) < 2 then
                Dalamud.Log("[FishingScrips] Stuck in same spot for over 10 seconds.")
                if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
                    IPC.vnavmesh.Stop()
                end
                local rX, rY, rZ = RandomAdjustCoordinates(x, y, z, 20)
                if rX and rY and rZ then
                    IPC.vnavmesh.PathfindAndMoveTo(Vector3(rX, rY, rZ), true)
                    while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                        yield("/wait 1")
                    end
                end
                return
            end
        end

        SelectedFishingSpot.lastStuckCheckPosition = { x = x, y = y, z = z }
    end

    local distanceToWaypoint = GetDistanceToPoint(SelectedFishingSpot.waypointX, Player.Entity.Position.Y, SelectedFishingSpot.waypointZ)
    if distanceToWaypoint > 10 then
        if not Svc.Condition[CharacterCondition.mounted] then
            Mount()
            State = CharacterState.gsGoToFishingHole
            Dalamud.Log("[FishingScrips] State Changed → GoToFishingHole")
        elseif not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
            Dalamud.Log(string.format("[FishingScrips] Moving to waypoint: (%.2f, %.2f, %.2f)", SelectedFishingSpot.waypointX, SelectedFishingSpot.waypointY, SelectedFishingSpot.waypointZ))
            IPC.vnavmesh.PathfindAndMoveTo(Vector3(SelectedFishingSpot.waypointX, SelectedFishingSpot.waypointY, SelectedFishingSpot.waypointZ), true)
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                yield("/wait 1")
            end
        end
        yield("/wait 1")
        return
    end

    if Svc.Condition[CharacterCondition.mounted] then
        Dismount()
    end

    State = CharacterState.gsFishing
    Dalamud.Log("[FishingScrips] State Changed → Fishing")
end

ResetHardAmissTime = os.clock()
function CharacterState.gsFishing()
    if Inventory.GetItemCount(29717) == 0 then
        State = CharacterState.gsBuyFishingBait
        Dalamud.Log("[FishingScrips] State Changed → BuyFishingBait")
        return
    end

    if Inventory.GetFreeInventorySlots() <= MinInventoryFreeSlots then
        Dalamud.Log("[FishingScrips] Not enough inventory space")
        if Svc.Condition[CharacterCondition.gathering] then
            QuitFishing()
            yield("/wait 1")
        else
            State = CharacterState.gsTurnIn
            Dalamud.Log("[FishingScrips] State Changed → TurnIn")
        end
        return
    end

    if os.clock() - ResetHardAmissTime > (ResetHardAmissAfter * 60) then
        if Svc.Condition[CharacterCondition.gathering] then
            if not Svc.Condition[CharacterCondition.fishing] then
                QuitFishing()
                yield("/wait 1")
            end
        else
            State = CharacterState.gsTurnIn
            Dalamud.Log("[FishingScrips] State Changed → Forced TurnIn to avoid hard amiss")
        end
        return
    elseif os.clock() - SelectedFishingSpot.startTime > (MoveSpotsAfter * 60) then
        if not logged then
            Dalamud.Log("[FishingScrips] Switching fishing spots")
            logged = true
        end
        if Svc.Condition[CharacterCondition.gathering] then
            if not Svc.Condition[CharacterCondition.fishing] then
                QuitFishing()
                yield("/wait 1")
            end
        else
            SelectNewFishingHole()
            State = CharacterState.gsReady
            Dalamud.Log("[FishingScrips] State Changed → Timeout Ready")
        end
        return
    elseif Svc.Condition[CharacterCondition.gathering] then
        if (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
            IPC.vnavmesh.Stop()
        end
        yield("/wait 1")
        return
    end

    local now = os.clock()
    if now - SelectedFishingSpot.startTime > 10 then
        local x = Player.Entity.Position.X
        local y = Player.Entity.Position.Y
        local z = Player.Entity.Position.Z

        local lastStuckCheckPosition = SelectedFishingSpot.lastStuckCheckPosition

        if GetDistanceToPoint(lastStuckCheckPosition.x, lastStuckCheckPosition.y, lastStuckCheckPosition.z) < 2 then
            Dalamud.Log("[FishingScrips] Stuck in same spot for over 10 seconds.")
            if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
                IPC.vnavmesh.Stop()
            end
            SelectNewFishingHole()
            State = CharacterState.gsReady
            Dalamud.Log("[FishingScrips] State Changed → Stuck Ready")
            return
        else
            SelectedFishingSpot.lastStuckCheckPosition = { x = x, y = y, z = z }
        end
    end

    if not IPC.vnavmesh.PathfindInProgress() and not IPC.vnavmesh.IsRunning() then
        local genericListType = Type.GetType("System.Collections.Generic.List`1[System.Numerics.Vector3]")
        local vectorList = Activator.CreateInstance(genericListType)
        local vector = Vector3(SelectedFishingSpot.x, SelectedFishingSpot.y, SelectedFishingSpot.z)
        vectorList:Add(vector)
        IPC.vnavmesh.MoveTo(vectorList, false)
        return
    end

    if IPC.vnavmesh.PathfindInProgress() and IPC.vnavmesh.IsRunning() then
        yield("/wait 0.5")
    end

    CastFishing()
    yield("/wait 0.5")
end

function CharacterState.gsBuyFishingBait()
    if Inventory.GetItemCount(29717) >= 1 then
        if Addons.GetAddon("Shop").Ready then
            yield("/callback Shop true -1")
        else
            State = CharacterState.gsGoToFishingHole
            Dalamud.Log("[FishingScrips] State Changed → GoToFishingHole")
        end
        return
    end

    if Svc.ClientState.TerritoryType ~= FishingBaitMerchant.zoneId then
        TeleportTo(FishingBaitMerchant.aetheryte)
        return
    end

    local distanceToMerchant = GetDistanceToPoint(FishingBaitMerchant.x, FishingBaitMerchant.y, FishingBaitMerchant.z)
    local distanceViaAethernet = DistanceBetween(FishingBaitMerchant.aethernet.x, FishingBaitMerchant.aethernet.y, FishingBaitMerchant.aethernet.z, FishingBaitMerchant.x, FishingBaitMerchant.y, FishingBaitMerchant.z)

    if distanceToMerchant > distanceViaAethernet + 20 then
        if not IPC.Lifestream.IsBusy() then
            TeleportTo(FishingBaitMerchant.aethernet.name)
        end
        return
    end

    if Addons.GetAddon("TeleportTown").Ready then
        yield("/callback TeleportTown false -1")
        return
    end

    if distanceToMerchant > 5 then
        if not IPC.vnavmesh.PathfindInProgress() and not IPC.vnavmesh.IsRunning() then
            IPC.vnavmesh.PathfindAndMoveTo(Vector3(FishingBaitMerchant.x, FishingBaitMerchant.y, FishingBaitMerchant.z), false)
        end
        return
    end

    if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
        IPC.vnavmesh.Stop()
        return
    end

    local baitMerchant = Entity.GetEntityByName(FishingBaitMerchant.npcName)
    if not Entity.Player.Target or Entity.Player.Target.Name ~= FishingBaitMerchant.npcName then
        if baitMerchant then
            baitMerchant:SetAsTarget()
        end
        return
    end

    if Addons.GetAddon("SelectIconString").Ready then
        yield("/callback SelectIconString true 0")
    elseif Addons.GetAddon("SelectYesno").Ready then
        yield("/callback SelectYesno true 0")
    elseif Addons.GetAddon("Shop").Ready then
        yield("/callback Shop true 0 3 99 0")
    elseif baitMerchant then
        baitMerchant:Interact()
    end
end

--------------------
--    Movement    --
--------------------

function GetDistanceToPoint(dX, dY, dZ)
    local player = Svc.ClientState.LocalPlayer
    if not player or not player.Position then
        Dalamud.Log("[FishingScrips] GetDistanceToPoint: Player position unavailable.")
        return math.huge
    end

    local px = player.Position.X
    local py = player.Position.Y
    local pz = player.Position.Z

    local dx = dX - px
    local dy = dY - py
    local dz = dZ - pz

    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    return distance
end

function DistanceBetween(px1, py1, pz1, px2, py2, pz2)
    local dx = px2 - px1
    local dy = py2 - py1
    local dz = pz2 - pz1

    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    return distance
end

function CharacterState.gsGoToHubCity()
    if not Player.Available then
        yield("/wait 1")
    elseif Svc.ClientState.TerritoryType ~= SelectedHubCity.zoneId then
        TeleportTo(SelectedHubCity.aetheryte)
    else
        State = CharacterState.gsReady
        Dalamud.Log("[FishingScrips] State Changed → Ready")
    end
end

------------------
--    TurnIn    --
------------------

function CharacterState.gsTurnIn()
    if Inventory.GetCollectableItemCount(SelectedFish.fishId, 1) == 0 then
        if Addons.GetAddon("CollectablesShop").Ready then
            yield("/callback CollectablesShop true -1")
        elseif Inventory.GetItemCount(GathererScripId) >= ScripExchangeItem.price then
            State = CharacterState.gsScripExchange
            Dalamud.Log("[FishingScrips] State Changed → ScripExchange")
        else
            State = CharacterState.gsReady
            Dalamud.Log("[FishingScrips] State Changed → Ready")
        end

    elseif Svc.ClientState.TerritoryType ~= SelectedHubCity.zoneId then
        State = CharacterState.gsGoToHubCity
        Dalamud.Log("[FishingScrips] State Changed → GoToHubCity")

    elseif SelectedHubCity.scripExchange.requiresAethernet and (Svc.ClientState.TerritoryType ~= SelectedHubCity.aethernet.aethernetZoneId or
        GetDistanceToPoint(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) > DistanceBetween(SelectedHubCity.aethernet.x, SelectedHubCity.aethernet.y, SelectedHubCity.aethernet.z, SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) + 10) then
        if not IPC.Lifestream.IsBusy() then
            TeleportTo(SelectedHubCity.aethernet.aethernetName)
        end
        yield("/wait 1")
    elseif Addons.GetAddon("TeleportTown").Ready then
        yield("/callback TeleportTown false -1")

    elseif GetDistanceToPoint(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) > 1 then
        if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
            IPC.vnavmesh.PathfindAndMoveTo(Vector3(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z), false)
            repeat
                yield("/wait 1")
            until not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning())
        end

    elseif Inventory.GetItemCount(GathererScripId) >= 3800 then
        if Addons.GetAddon("CollectablesShop").Ready then
            yield("/callback CollectablesShop true -1")
        else
            State = CharacterState.gsScripExchange
            Dalamud.Log("[FishingScrips] State Changed → ScripExchange")
        end
    else
        if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
            IPC.vnavmesh.Stop()
        end

        if not Addons.GetAddon("CollectablesShop").Ready then
            local appraiser = Entity.GetEntityByName("Collectable Appraiser")
            if appraiser then
                appraiser:SetAsTarget()
                appraiser:Interact()
            end
        else
            yield("/callback CollectablesShop true 12 " .. SelectedFish.collectiblesTurnInListIndex)
            yield("/wait 0.1")
            yield("/callback CollectablesShop true 15 0")
            yield("/wait 1")
        end
    end
end

---------------------------
--    Scrips Exchange    --
---------------------------

function CharacterState.gsScripExchange()
    if Inventory.GetItemCount(GathererScripId) < ScripExchangeItem.price then
        if Addons.GetAddon("InclusionShop").Ready then
            yield("/callback InclusionShop true -1")
        elseif Inventory.GetCollectableItemCount(SelectedFish.fishId, 1) > 0 then
            State = CharacterState.gsTurnIn
            Dalamud.Log("[FishingScrips] State Changed → TurnIn")
        else
            State = CharacterState.gsReady
            Dalamud.Log("[FishingScrips] State Changed → Ready")
        end

    elseif Svc.ClientState.TerritoryType ~= SelectedHubCity.zoneId then
        State = CharacterState.gsGoToHubCity
        Dalamud.Log("[FishingScrips] State Changed → GoToHubCity")

    elseif SelectedHubCity.scripExchange.requiresAethernet and (Svc.ClientState.TerritoryType ~= SelectedHubCity.aethernet.aethernetZoneId or
        GetDistanceToPoint(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) > DistanceBetween(SelectedHubCity.aethernet.x, SelectedHubCity.aethernet.y, SelectedHubCity.aethernet.z, SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) + 10) then
        if not IPC.Lifestream.IsBusy() then
            TeleportTo(SelectedHubCity.aethernet.aethernetName)
        end
        yield("/wait 1")

    elseif Addons.GetAddon("TeleportTown").Ready then
        yield("/callback TeleportTown false -1")

    elseif GetDistanceToPoint(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) > 1 then
        if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
            IPC.vnavmesh.PathfindAndMoveTo(Vector3(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z), false)
        end

    elseif Addons.GetAddon("ShopExchangeItemDialog").Ready then
        yield("/callback ShopExchangeItemDialog true 0")

    elseif Addons.GetAddon("SelectIconString").Ready then
        yield("/callback SelectIconString true 0")

    elseif Addons.GetAddon("InclusionShop").Ready then
        yield("/callback InclusionShop true 12 " .. ScripExchangeItem.categoryMenu)
        yield("/wait 1")
        yield("/callback InclusionShop true 13 " .. ScripExchangeItem.subcategoryMenu)
        yield("/wait 1")
        yield("/callback InclusionShop true 14 " .. ScripExchangeItem.listIndex .. " " .. math.min(99, Inventory.GetItemCount(GathererScripId) // ScripExchangeItem.price))
        yield("/wait 1")

    else
        yield("/wait 1")
        local exchange = Entity.GetEntityByName("Scrip Exchange")
        if exchange then
            exchange:SetAsTarget()
            exchange:Interact()
        end
    end
end

----------------
--    Misc    --
----------------

function CharacterState.gsAutoRetainers()
    local bell = Entity.GetEntityByName("Summoning Bell")

    if (not IPC.AutoRetainer.AreAnyRetainersAvailableForCurrentChara() or Inventory.GetFreeInventorySlots() <= 1) then
        if Addons.GetAddon("RetainerList").Ready then
            yield("/callback RetainerList true -1")
        elseif not Svc.Condition[CharacterCondition.occupiedSummoningBell] then
            State = CharacterState.gsReady
            Dalamud.Log("[FishingScrips] State Changed → Ready")
        end

    elseif not (Svc.ClientState.TerritoryType == SelectedHubCity.zoneId or Svc.ClientState.TerritoryType == SelectedHubCity.aethernet.aethernetZoneId) then
        Dalamud.Log("[FishingScrips] Teleporting to hub city.")
        TeleportTo(SelectedHubCity.aetheryte)

    elseif SelectedHubCity.retainerBell.requiresAethernet and (Svc.ClientState.TerritoryType ~= SelectedHubCity.aethernet.aethernetZoneId or
        (GetDistanceToPoint(SelectedHubCity.retainerBell.x, SelectedHubCity.retainerBell.y, SelectedHubCity.retainerBell.z) > (DistanceBetween(SelectedHubCity.aethernet.x, SelectedHubCity.aethernet.y, SelectedHubCity.aethernet.z, SelectedHubCity.retainerBell.x, SelectedHubCity.retainerBell.y, SelectedHubCity.retainerBell.z) + 10))) then
        if not IPC.Lifestream.IsBusy() then
            TeleportTo(SelectedHubCity.aethernet.aethernetName)
        end
        yield("/wait 1")

    elseif Addons.GetAddon("TeleportTown").Ready then
        yield("/callback TeleportTown false -1")

    elseif GetDistanceToPoint(SelectedHubCity.retainerBell.x, SelectedHubCity.retainerBell.y, SelectedHubCity.retainerBell.z) > 1 then
        if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
            IPC.vnavmesh.PathfindAndMoveTo(Vector3(SelectedHubCity.retainerBell.x, SelectedHubCity.retainerBell.y, SelectedHubCity.retainerBell.z), false)
        end

    elseif IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
        return

    elseif not Entity.Player.Target or Entity.Player.Target.Name ~= "Summoning Bell" then
        if bell then
            bell:SetAsTarget()
        end
        return

    elseif not Svc.Condition[CharacterCondition.occupiedSummoningBell] then
        if bell then
            bell:Interact()
        end

    elseif Addons.GetAddon("RetainerList").Ready then
        yield("/ays e")
        yield("/wait 1")
    end
end

local deliver = false
function CharacterState.gsGCTurnIn()
    if Inventory.GetFreeInventorySlots() <= MinInventoryFreeSlots and not deliver then
        Dalamud.Log("[FishingScrips] Starting GC turn-in.")
        yield("/ays deliver")
        yield("/wait 1")
        deliver = true
        return

    elseif IPC.AutoRetainer.IsBusy() then
        return

    else
        State = CharacterState.gsReady
        Dalamud.Log("[FishingScrips] State Changed → Ready")
        deliver = false
    end
end

function CharacterState.gsRepair()
    if Addons.GetAddon("SelectYesno").Ready then
        yield("/callback SelectYesno true 0")
        return
    end

    if Addons.GetAddon("Repair").Ready then
        if not NeedsRepair(RepairThreshold) then
            yield("/callback Repair true -1")
        else
            yield("/callback Repair true 0")
        end
        return
    end

    if Svc.Condition[CharacterCondition.occupiedMateriaExtractionAndRepair] then
        Dalamud.Log("[FishingScrips] Repairing...")
        yield("/wait 1")
        return
    end

    local hawkersAlleyAethernetShard = { x = -213.95, y = 15.99, z = 49.35 }

    if SelfRepair then
        if Inventory.GetItemCount(33916) > 0 then
            if NeedsRepair(RepairThreshold) then
                if not Addons.GetAddon("Repair").Ready then
                    local repairActionId = 6
                    Actions.ExecuteGeneralAction(repairActionId)
                end
            else
                State = CharacterState.gsReady
                Dalamud.Log("[FishingScrips] State Changed → Ready")
            end

        elseif BuyDarkMatter then
            if Svc.ClientState.TerritoryType ~= 129 then
                Dalamud.Log("[FishingScrips] Teleporting to Limsa to buy Dark Matter.")
                TeleportTo("Limsa Lominsa Lower Decks")
                return
            end

            local npcVendor = Entity.GetEntityByName(DarkMatterVendor.npcName)
            if GetDistanceToPoint(DarkMatterVendor.x, DarkMatterVendor.y, DarkMatterVendor.z) > (DistanceBetween(hawkersAlleyAethernetShard.x, hawkersAlleyAethernetShard.y, hawkersAlleyAethernetShard.z,DarkMatterVendor.x, DarkMatterVendor.y, DarkMatterVendor.z) + 10) then
                TeleportTo("Hawkers' Alley")
                yield("/wait 1")
            elseif Addons.GetAddon("TeleportTown").Ready then
                yield("/callback TeleportTown false -1")
            elseif GetDistanceToPoint(DarkMatterVendor.x, DarkMatterVendor.y, DarkMatterVendor.z) > 5 then
                if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
                    IPC.vnavmesh.PathfindAndMoveTo(Vector3(DarkMatterVendor.x, DarkMatterVendor.y, DarkMatterVendor.z), false)
                end
            else
                if not Entity.Player.Target or Entity.Player.Target.Name ~= DarkMatterVendor.npcName then
                    if npcVendor then
                        npcVendor:SetAsTarget()
                    end
                elseif not Svc.Condition[CharacterCondition.occupiedInQuestEvent] then
                    if npcVendor then
                        npcVendor:Interact()
                    end
                elseif Addons.GetAddon("SelectYesno").Ready then
                    yield("/callback SelectYesno true 0")
                elseif Addons.GetAddon("Shop").Ready then
                    yield("/callback Shop true 0 40 99")
                end
            end

        else
            Dalamud.Log("[FishingScrips] SelfRepair disabled. Using Limsa Mender instead.")
            SelfRepair = false
        end

    else
        if NeedsRepair(RepairThreshold) then
            if Svc.ClientState.TerritoryType ~= 129 then
                Dalamud.Log("[FishingScrips] Teleporting to Limsa for Mender.")
                TeleportTo("Limsa Lominsa Lower Decks")
                return
            end

            local npcMender = Entity.GetEntityByName(Mender.npcName)
            if GetDistanceToPoint(Mender.x, Mender.y, Mender.z) > (DistanceBetween(hawkersAlleyAethernetShard.x, hawkersAlleyAethernetShard.y, hawkersAlleyAethernetShard.z, Mender.x, Mender.y, Mender.z) + 10) then
                TeleportTo("Hawkers' Alley")
                yield("/wait 1")
            elseif Addons.GetAddon("TeleportTown").Ready then
                yield("/callback TeleportTown false -1")
            elseif GetDistanceToPoint(Mender.x, Mender.y, Mender.z) > 5 then
                if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
                    IPC.vnavmesh.PathfindAndMoveTo(Vector3(Mender.x, Mender.y, Mender.z), false)
                end
            else
                if not Entity.Player.Target or Entity.Player.Target.Name ~= Mender.npcName then
                    if npcMender then
                        npcMender:SetAsTarget()
                    end
                elseif not Svc.Condition[CharacterCondition.occupiedInQuestEvent] then
                    if npcMender then
                        npcMender:Interact()
                    end
                end
            end
        else
            State = CharacterState.gsReady
            Dalamud.Log("[FishingScrips] State Changed → Ready")
        end
    end
end

function CharacterState.gsExtractMateria()
    if Svc.Condition[CharacterCondition.mounted] then
        Dismount()
        return
    end

    if Svc.Condition[CharacterCondition.occupiedMateriaExtractionAndRepair] then
        return
    end

    if CanExtractMateria() > 0 and Inventory.GetFreeInventorySlots() > 1 then
        if not Addons.GetAddon("Materialize").Ready then
            local extractionActionId = 14
            Actions.ExecuteGeneralAction(extractionActionId)
            yield("/wait 1")
            return
        end

        if Addons.GetAddon("MaterializeDialog").Ready then
            yield("/callback MaterializeDialog true 0")
        else
            yield("/callback Materialize true 2 0")
        end
    else
        if Addons.GetAddon("Materialize").Ready then
            yield("/callback Materialize true -1")
        else
            State = CharacterState.gsReady
            Dalamud.Log("[FishingScrips] State Changed → Ready")
        end
    end
end

function FoodCheck()
    if not HasStatusId(48) and Food ~= "" then
        yield("/item " .. Food)
    end
end

function PotionCheck()
    if not HasStatusId(49) and Potion ~= "" then
        yield("/item " .. Potion)
    end
end

function SelectFishTable()
    for _, fishTable in ipairs(FishTable) do
        if ScripColorToFarm == fishTable.scripColor then
            return fishTable
        end
    end

    Dalamud.Log(string.format("[FishingScrips] No matching fish table found for scrip color: %s", ScripColorToFarm))
    return nil
end

function CharacterState.gsReady()
    FoodCheck()
    PotionCheck()

    if not Player.Available then
        return

    elseif RepairThreshold > 0 and NeedsRepair(RepairThreshold) and (SelfRepair and Inventory.GetItemCount(33916) > 0) then
        State = CharacterState.gsRepair
        Dalamud.Log("[FishingScrips] State Changed → Repair")

    elseif ExtractMateria and CanExtractMateria() > 0 and Inventory.GetFreeInventorySlots() > 1 then
        State = CharacterState.gsExtractMateria
        Dalamud.Log("[FishingScrips] State Changed → ExtractMateria")

    elseif DoAutoRetainers and IPC.AutoRetainer.AreAnyRetainersAvailableForCurrentChara() and Inventory.GetFreeInventorySlots() > 1 then
        State = CharacterState.gsAutoRetainers
        Dalamud.Log("[FishingScrips] State Changed → ProcessingRetainers")

    elseif Inventory.GetFreeInventorySlots() <= MinInventoryFreeSlots and Inventory.GetCollectableItemCount(SelectedFish.fishId, 1) > 0 then
        State = CharacterState.gsTurnIn
        Dalamud.Log("[FishingScrips] State Changed → TurnIn")

    elseif GrandCompanyTurnIn and Inventory.GetFreeInventorySlots() <= MinInventoryFreeSlots then
        State = CharacterState.gsGCTurnIn
        Dalamud.Log("[FishingScrips] State Changed → GCTurnIn")

    elseif Inventory.GetItemCount(29717) == 0 then
        State = CharacterState.gsBuyFishingBait
        Dalamud.Log("[FishingScrips] State Changed → BuyFishingBait")

    else
        State = CharacterState.gsGoToFishingHole
        Dalamud.Log("[FishingScrips] State Changed → GoToFishingHole")
    end
end

--=========================== EXECUTION ==========================--

LastStuckCheckTime = os.clock()
LastStuckCheckPosition = {
    x = Player.Entity.Position.X,
    y = Player.Entity.Position.Y,
    z = Player.Entity.Position.Z
}

if ScripColorToFarm == "Orange" then
    GathererScripId = OrangeGathererScripId
else
    GathererScripId = PurpleGathererScripId
end

for _, item in ipairs(ScripExchangeItems) do
    if item.itemName == ItemToExchange then
        ScripExchangeItem = item
    end
end

if ScripExchangeItem == nil then
    yield(string.format("/echo [FishingScrips] Cannot recognize item: %s. Stopping script.", ItemToExchange))
    Dalamud.Log(string.format("[FishingScrips] Cannot recognize item: %s. Stopping script.", ItemToExchange))
    yield("/snd stop all")
end

SelectedFish = SelectFishTable()

if not SelectedFish then
    yield(string.format("/echo [FishingScrips] No fish table for %s. Stopping.", ScripColorToFarm))
    Dalamud.Log(string.format("[FishingScrips] No fish table for %s. Stopping.", ScripColorToFarm))
    yield("/snd stop all")
end

if Svc.ClientState.TerritoryType == SelectedFish.zoneId then
    Dalamud.Log("[FishingScrips] In fishing zone already. Selecting new fishing hole.")
    SelectNewFishingHole()
end

IPC.AutoHook.SetPluginState(true)
IPC.AutoHook.DeleteAllAnonymousPresets()
IPC.AutoHook.CreateAndSelectAnonymousPreset(SelectedFish.autoHookPreset)

for _, city in ipairs(HubCities) do
    if city.zoneName == HubCity then
        SelectedHubCity = city
        local aetheryteName = GetAetheryteName(city.zoneId)
        if aetheryteName then
            SelectedHubCity.aetheryte = aetheryteName
        end
        break
    end
end

if SelectedHubCity == nil then
    yield(string.format("/echo [FishingScrips] Could not find hub city: %s. Stopping script.", HubCity))
    Dalamud.Log(string.format("[FishingScrips] Could not find hub city: %s. Stopping script.", HubCity))
    yield("/snd stop all")
end

if Player.Job.Id ~= 18 then
    Dalamud.Log("[FishingScrips] Switching to Fisher.")
    yield("/gs change Fisher")
    yield("/wait 1")
end

State = CharacterState.gsReady
Dalamud.Log("[FishingScrips] State Changed → Ready")

while true do
    State()
    yield("/wait 0.1")
end

--============================== END =============================--
