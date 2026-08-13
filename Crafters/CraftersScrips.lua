--[=====[
[[SND Metadata]]
author:  'pot0to (https://ko-fi.com/pot0to) || Maintainer: Minnu (https://ko-fi.com/minnuverse) || Contributor: Ice, Allison'
version: 2.1.0
description: Crafter Scrips - Script for Crafting & Turning In
plugin_dependencies:
- Artisan
- AutoRetainer
- Lifestream
- vnavmesh
configs:
  CrafterClass:
    description: Select the crafting class to use for turn-ins and crafting tasks.
    is_choice: true
    choices:
        - "Carpenter"
        - "Blacksmith"
        - "Armorer"
        - "Goldsmith"
        - "Leatherworker"
        - "Weaver"
        - "Alchemist"
        - "Culinarian"
  ScripColor:
    default: "Orange"
    description: Type of scrip to use for crafting / purchases (Orange, Purple).
    is_choice: true
    choices:
        - "Orange"
        - "Purple"
  ArtisanListId:
    default: 1
    description: Id of Artisan list for crafting all the intermediate materials (eg black star, claro walnut lumber, etc.).
  ItemToBuy:
    default: Crafter's Command Materia XII
    description: Name of the item to purchase using scrips.
  HomeCommand:
    default: Inn
    description: Inn - if you want to hide in an Inn. Home - if you want to use Lifestream Home. None to move to Solution Nine.
    is_choice: true
    choices:
        - "Inn"
        - "Home"
        - "None"
  HubCity:
    default: Solution Nine
    description: Main city to use as a hub for turn-ins and purchases.
    is_choice: true
    choices:
        - "Ul'dah"
        - "Limsa"
        - "Gridania"
        - "Solution Nine"
  Potion:
    default: false
    description: Use Potion (Supports only Superior Spiritbond Potion <hq>)
  Retainers:
    default: true
    description: Automatically interact with retainers for ventures.
  GrandCompanyTurnIn:
    default: false
    description: Do Grand Company TurnIns.
  MinInventoryFreeSlots:
    default: 5
    description: Minimum free inventory slots required to start crafting or turn-ins.
  SkystellToolsUnlocked:
    default: true
    description: Have you unlocked skysteel tools?

[[End Metadata]]
--]=====]

--========================== DEPENDENCIES ========================--

import("System.Numerics")

--=========================== VARIABLES ==========================--

-------------------
--    General    --
-------------------

CrafterClass            = Config.Get("CrafterClass")
ScripColor              = Config.Get("ScripColor")
ArtisanListId           = Config.Get("ArtisanListId")
ItemToBuy               = Config.Get("ItemToBuy")
HomeCommand             = Config.Get("HomeCommand")
HubCity                 = Config.Get("HubCity")
Potion                  = Config.Get("Potion")
Retainers               = Config.Get("Retainers")
GrandCompanyTurnIn      = Config.Get("GrandCompanyTurnIn")
MinInventoryFreeSlots   = Config.Get("MinInventoryFreeSlots")
SkystellToolsUnlocked   = Config.Get("SkystellToolsUnlocked")
LogPrefix               = "[CraftersScrips]"

--============================ CONSTANT ==========================--

------------------
--    Scrips    --
------------------

OrangeCrafterScripId = 41784
PurpleCrafterScripId = 33913

-----------------
--    Items    --
-----------------

ScripExchangeItems = {
    {
        itemName        = "Mason's Abrasive",
        categoryMenu    = 1,
        subcategoryMenu = 9 + (SkystellToolsUnlocked and 1 or 0),
        listIndex       = 0,
        price           = 500
    },
    {
        itemName        = "Condensed Solution",
        categoryMenu    = 1,
        subcategoryMenu = 10 + (SkystellToolsUnlocked and 1 or 0),
        listIndex       = 10,
        price           = 125
    },
    {
        itemName        = "Crafter's Competence Materia XII",
        categoryMenu    = 2,
        subcategoryMenu = 2,
        listIndex       = 0,
        price           = 500
    },
    {
        itemName        = "Crafter's Cunning Materia XII",
        categoryMenu    = 2,
        subcategoryMenu = 2,
        listIndex       = 1,
        price           = 500
    },
    {
        itemName        = "Crafter's Command Materia XII",
        categoryMenu    = 2,
        subcategoryMenu = 2,
        listIndex       = 2,
        price           = 500
    },
    {
        itemName        = "Crafter's Competence Materia XI",
        categoryMenu    = 2,
        subcategoryMenu = 1,
        listIndex       = 0,
        price           = 250
    },
    {
        itemName        = "Crafter's Cunning Materia XI",
        categoryMenu    = 2,
        subcategoryMenu = 1,
        listIndex       = 1,
        price           = 250
    },
    {
        itemName        = "Crafter's Command Materia XI",
        categoryMenu    = 2,
        subcategoryMenu = 1,
        listIndex       = 2,
        price           = 250
    },
    {
        itemName        = "Artful Afflatus Ring",
        categoryMenu    = 0,
        subcategoryMenu = 10,
        listIndex       = 24,
        price           = 75,
        oneAtATime      = true
    }
}

------------------------
--    Collectables    --
------------------------

OrangeScripRecipes = {
    {
        className  = "Carpenter",
        classId    = 8,
        itemName   = "Rarefied Claro Walnut Fishing Rod",
        itemId     = 44190,
        recipeId   = 35787
    },
    {
        className  = "Blacksmith",
        classId    = 9,
        itemName   = "Rarefied Ra'Kaznar Round Knife",
        itemId     = 44196,
        recipeId   = 35793
    },
    {
        className  = "Armorer",
        classId    = 10,
        itemName   = "Rarefied Ra'Kaznar Ring",
        itemId     = 44202,
        recipeId   = 35799
    },
    {
        className  = "Goldsmith",
        classId    = 11,
        itemName   = "Rarefied Black Star Earrings",
        itemId     = 44208,
        recipeId   = 35805
    },
    {
        className  = "Leatherworker",
        classId    = 12,
        itemName   = "Rarefied Gargantuaskin Hat",
        itemId     = 44214,
        recipeId   = 35817
    },
    {
        className  = "Weaver",
        classId    = 13,
        itemName   = "Rarefied Thunderyard Silk Culottes",
        itemId     = 44220,
        recipeId   = 35817
    },
    {
        className  = "Alchemist",
        classId    = 14,
        itemName   = "Rarefied Claro Walnut Flat Brush",
        itemId     = 44226,
        recipeId   = 35823
    },
    {
        className  = "Culinarian",
        classId    = 15,
        itemName   = "Rarefied Tacos de Carne Asada",
        itemId     = 44232,
        recipeId   = 35829
    }
}

PurpleScripRecipes = {
    {
        className  = "Carpenter",
        classId    = 8,
        itemName   = "Rarefied Claro Walnut Grinding Wheel",
        itemId     = 44189,
        recipeId   = 35786
    },
    {
        className  = "Blacksmith",
        classId    = 9,
        itemName   = "Rarefied Ra'Kaznar War Scythe",
        itemId     = 44195,
        recipeId   = 35792
    },
    {
        className  = "Armorer",
        classId    = 10,
        itemName   = "Rarefied Ra'Kaznar Greaves",
        itemId     = 44201,
        recipeId   = 35798
    },
    {
        className  = "Goldsmith",
        classId    = 11,
        itemName   = "Rarefied Ra'Kaznar Orrery",
        itemId     = 44207,
        recipeId   = 35804
    },
    {
        className  = "Leatherworker",
        classId    = 12,
        itemName   = "Rarefied Gargantuaskin Trouser",
        itemId     = 44213,
        recipeId   = 35816
    },
    {
        className  = "Weaver",
        classId    = 13,
        itemName   = "Rarefied Thunderyards Silk Gloves",
        itemId     = 44219,
        recipeId   = 35816
    },
    {
        className  = "Alchemist",
        classId    = 14,
        itemName   = "Rarefied Gemdraught of Vitality",
        itemId     = 44225,
        recipeId   = 35822
    },
    {
        className  = "Culinarian",
        classId    = 15,
        itemName   = "Rarefied Stuffed Peppers",
        itemId     = 44231,
        recipeId   = 35828
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

-----------------
--    Class    --
-----------------

ClassList = {
    crp = { classId =  8, className = "Carpenter"      },
    bsm = { classId =  9, className = "Blacksmith"     },
    arm = { classId = 10, className = "Armorer"        },
    gsm = { classId = 11, className = "Goldsmith"      },
    ltw = { classId = 12, className = "Leatherworker"  },
    wvr = { classId = 13, className = "Weaver"         },
    alc = { classId = 14, className = "Alchemist"      },
    cul = { classId = 15, className = "Culinarian"     }
}

---------------------
--    Condition    --
---------------------

CharacterCondition = {
    craftingMode                        =  5,
    casting                             = 27,
    occupiedInQuestEvent                = 32,
    occupiedMateriaExtractionAndRepair  = 39,
    executingCraftingSkill              = 40,
    craftingModeIdle                    = 41,
    betweenAreas                        = 45,
    occupiedSummoningBell               = 50,
    beingMoved                          = 70
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

function Echo(message)
    yield(string.format("/echo %s %s", LogPrefix, message))
end

----------------------
--    Navigation    --
----------------------

function TeleportTo(aetheryteName)
    yield("/li tp " .. aetheryteName)
    Wait(1)
    while Svc.Condition[CharacterCondition.casting] do
        Log("Casting teleport...")
        Wait(1)
    end
    Wait(1)
    while Svc.Condition[CharacterCondition.betweenAreas] do
        Log("Teleporting...")
        Wait(1)
    end
    Wait(1)
end

function GetDistanceToPoint(dX, dY, dZ)
    local player = Svc.Objects.LocalPlayer
    if not player or not player.Position then
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

function GetDistanceToTarget()
    if not Entity or not Entity.Player then
        return nil
    end

    if not Entity.Target then
        return nil
    end

    local playerPos = Entity.Player.Position
    local targetPos = Entity.Target.Position

    local dx = playerPos.X - targetPos.X
    local dy = playerPos.Y - targetPos.Y
    local dz = playerPos.Z - targetPos.Z

    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    return distance
end

function DistanceBetween(px1, py1, pz1, px2, py2, pz2)
    local dx = px2 - px1
    local dy = py2 - py1
    local dz = pz2 - pz1

    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function GoToHubCity()
    if not Player.Available then
        Wait(1)
    elseif not Svc.ClientState.TerritoryType == SelectedHubCity.zoneId then
        TeleportTo(SelectedHubCity.aetheryte)
    else
        State = CharacterState.ready
        Log("State Change: Ready")
    end
end

------------------
--    Checks    --
------------------

function HasStatusId(targetId)
    local statusList = Player.Status

    if not statusList then
        return false
    end

    for i = 0, statusList.Count - 1 do
        local status = statusList:get_Item(i)

        if status and status.StatusId == targetId then
            return true
        end
    end

    return false
end

function OutOfCrystals()
    local crystalsRequired1 = tonumber(Addons.GetAddon("RecipeNote"):GetNode(1, 57, 83, 2).Text)
    local crystalsInInventory1 = tonumber(Addons.GetAddon("RecipeNote"):GetNode(1, 57, 83, 3).Text)
    if crystalsRequired1 ~= nil and crystalsInInventory1 ~= nil and crystalsRequired1 > crystalsInInventory1 then
        return true
    end

    local crystalsRequired2 = tonumber(Addons.GetAddon("RecipeNote"):GetNode(1, 57, 82, 2).Text)
    local crystalsInInventory2 = tonumber(Addons.GetAddon("RecipeNote"):GetNode(1, 57, 82, 3).Text)
    if crystalsRequired2 ~= nil and crystalsInInventory2 ~= nil and crystalsRequired2> crystalsInInventory2 then
        return true
    end

    return false
end

function OutOfMaterials()
    while not Addons.GetAddon("RecipeNote").Ready do
        Wait(0.1)
    end

    for i = 0, 5 do
        local materialCountNQ = Addons.GetAddon("RecipeNote"):GetNode(1, 57, 88, 89 + i, 10, 12).Text
        local materialCountHQ = Addons.GetAddon("RecipeNote"):GetNode(1, 57, 88, 89 + i, 13, 15).Text
        local materialRequirement = Addons.GetAddon("RecipeNote"):GetNode(1, 57, 88, 89 + i, 4).Text
        if materialCountNQ ~= "" and materialCountHQ ~= "" and materialRequirement ~= "" and
            materialCountNQ ~= nil and materialCountHQ ~= nil and materialRequirement ~= nil
        then
            Log("materialCountNQ: " .. materialCountNQ .. ", materialCountHQ: " .. materialCountHQ .. ", materialRequirement: " .. materialRequirement)
            if tonumber(materialCountNQ) + tonumber(materialCountHQ) < tonumber(materialRequirement) then
                return true
            end
        end
    end

    Log("Regular mats available. Checking crystals.")

    if OutOfCrystals() then
        Echo("Out of crystals. Stopping script.")
        StopFlag = true
        return true
    end

    Log("All mats and crystals available.")
    return false
end

function EnsureCrafterJob()
    local player = Svc.Objects.LocalPlayer
    if not player then
        return false
    end

    for _, class in pairs(ClassList) do
        if CrafterClass == class.className then
            if player.ClassJob.RowId ~= class.classId then
                yield("/gs change " .. class.classId)
                return true
            end
            return false
        end
    end

    Echo("Could not find crafter class: " .. tostring(CrafterClass))
    return false
end

--------------------
--    Crafting    --
--------------------

function Crafting()
    if IPC.Lifestream.IsBusy() or Svc.Condition[CharacterCondition.occupiedInQuestEvent] then
        Wait(1)
        return
    elseif not AtInn and HomeCommand == "Inn" then
        IPC.Lifestream.ExecuteCommand(HomeCommand)
        while IPC.Lifestream.IsBusy() do
            Wait(1)
        end
        AtInn = true
        return
    elseif not AtHome and HomeCommand == "Home" then
        IPC.Lifestream.ExecuteCommand(HomeCommand)
        while IPC.Lifestream.IsBusy() do
            Wait(1)
        end
        AtHome = true
        return
    end

    local slots = Inventory.GetFreeInventorySlots()
    if IPC.Artisan.GetEnduranceStatus() then
        return
    elseif slots == nil then
        Echo("GetFreeInventorySlots() is nil. WHYYY???")
    elseif not Log("Check Artisan running") and (IPC.Artisan.IsListRunning() and not IPC.Artisan.IsListPaused()) or Addons.GetAddon("Synthesis").Ready then
        Wait(1)
    elseif not Log("Check slots count") and slots <= MinInventoryFreeSlots then
        Log("Out of inventory space")
        if Addons.GetAddon("RecipeNote").Ready then
            yield("/callback RecipeNote true -1")
        elseif not Svc.Condition[CharacterCondition.craftingMode] then
            State = CharacterState.turnIn
            Log("State Change: TurnIn")
        end
    elseif not Log("Check out of materials") and Addons.GetAddon("RecipeNote").Ready and OutOfMaterials() then
        Log("Out of materials")
        if not StopFlag then
            if slots > MinInventoryFreeSlots and (ArtisanTimeoutStartTime == 0) then
                Log("Attempting to craft intermediate materials")
                yield("/artisan lists " .. ArtisanListId .. " start")
                ArtisanTimeoutStartTime = os.clock()
            elseif Inventory.GetCollectableItemCount(ItemId, 1) > 0 then
                Log("Turning In")
                yield("/callback RecipeNote true -1")
                State = CharacterState.turnIn
                Log("State Change: TurnIn")
            elseif os.clock() - ArtisanTimeoutStartTime > 5 then
                Log("Artisan not starting, StopFlag = true")
                Echo("Artisan took too long to start. Are you out of intermediate mat materials?")
                StopFlag = true
            end
        end
    elseif not Log("Check new Artisan craft") and not Addons.GetAddon("Synthesis").Ready then
        Log("Attempting to craft " .. (slots - MinInventoryFreeSlots) .. " of recipe #" .. RecipeId)
        ArtisanTimeoutStartTime = 0
        IPC.Artisan.CraftItem(RecipeId, slots - MinInventoryFreeSlots)
        Wait(5)
    else
        Log("Else condition hit")
    end
end

-------------------
--    Turn In    --
-------------------

function TurnIn()
    AtInn = false
    AtHome = false

    if EnsureCrafterJob() then
        Wait(1)
        return
    end

    if Inventory.GetCollectableItemCount(ItemId, 1) == 0 or Inventory.GetItemCount(CrafterScripId) >= 3800 then
        if Addons.GetAddon("CollectablesShop").Ready then
            yield("/callback CollectablesShop true -1")
        else
            State = CharacterState.ready
            Log("State Change: Ready")
        end
    elseif not Svc.ClientState.TerritoryType == SelectedHubCity.zoneId and
        (not SelectedHubCity.scripExchange.requiresAethernet or (SelectedHubCity.scripExchange.requiresAethernet and not Svc.ClientState.TerritoryType == SelectedHubCity.aethernet.aethernetZoneId))
    then
        State = CharacterState.goToHubCity
        Log("State Change: GoToHubCity")
    elseif SelectedHubCity.scripExchange.requiresAethernet and (not Svc.ClientState.TerritoryType == SelectedHubCity.aethernet.aethernetZoneId or
        GetDistanceToPoint(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) > DistanceBetween(SelectedHubCity.aethernet.x, SelectedHubCity.aethernet.y, SelectedHubCity.aethernet.z, SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) + 10) then
        if not IPC.Lifestream.IsBusy() and not Player.IsBusy then
            Log("/li " .. SelectedHubCity.aethernet.aethernetName)
            IPC.Lifestream.ExecuteCommand(SelectedHubCity.aethernet.aethernetName)
            Wait(1)
        end
        Wait(3)
    elseif Addons.GetAddon("TeleportTown").Ready then
        Log("TeleportTown open")
        yield("/callback TeleportTown false -1")
    elseif GetDistanceToPoint(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) > 1 then
        if not IPC.vnavmesh.PathfindInProgress() and not IPC.vnavmesh.IsRunning() then
            Log("Path not running")
            IPC.vnavmesh.PathfindAndMoveTo(Vector3(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z), false)
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
            if ScripColor == "Purple" then
                Log("Selecting purple scrip item")
                yield("/callback CollectablesShop true 12 1")
                Wait(0.5)
            else
                Log("Selecting orange scrip item")
            end

            yield("/callback CollectablesShop true 15 0")
            Wait(1)
        end
    end
end

--------------------------
--    Scrip Exchange    --
--------------------------

SelectTurnInPage = false
function ScripExchange()
    if Inventory.GetItemCount(CrafterScripId) < SelectedItemToBuy.price or Inventory.GetFreeInventorySlots() <= MinInventoryFreeSlots then
        if Addons.GetAddon("InclusionShop").Ready then
            yield("/callback InclusionShop true -1")
        elseif Inventory.GetCollectableItemCount(ItemId, 1) > 0 and Inventory.GetItemCount(CrafterScripId) < 3800 then
            SelectTurnInPage = false
            State = CharacterState.turnIn
            Log("State Change: TurnIn")
        elseif Inventory.GetFreeInventorySlots() <= MinInventoryFreeSlots then
            SelectTurnInPage = false
            State = CharacterState.gcTurnIn
            Log("State Change: GCTurnIn")
        else
            SelectTurnInPage = false
            State = CharacterState.ready
            Log("State Change: Ready")
        end
    elseif not Svc.ClientState.TerritoryType == SelectedHubCity.zoneId and
        (not SelectedHubCity.scripExchange.requiresAethernet or (SelectedHubCity.scripExchange.requiresAethernet and not Svc.ClientState.TerritoryType == SelectedHubCity.aethernet.aethernetZoneId))
    then
        SelectTurnInPage = false
        State = CharacterState.goToHubCity
        Log("State Change: GoToHubCity")
    elseif SelectedHubCity.scripExchange.requiresAethernet and (not Svc.ClientState.TerritoryType == SelectedHubCity.aethernet.aethernetZoneId or
        GetDistanceToPoint(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) > DistanceBetween(SelectedHubCity.aethernet.x, SelectedHubCity.aethernet.y, SelectedHubCity.aethernet.z, SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) + 10) then
        if not IPC.Lifestream.IsBusy() then
            IPC.Lifestream.ExecuteCommand(SelectedHubCity.aethernet.aethernetName)
        end
        Wait(3)
    elseif Addons.GetAddon("TeleportTown").Ready then
        yield("/callback TeleportTown true -1")
    elseif GetDistanceToPoint(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z) > 1 then
        if not IPC.vnavmesh.PathfindInProgress() and not IPC.vnavmesh.IsRunning() then
            Wait(3)
            Log("Path not running")
            IPC.vnavmesh.PathfindAndMoveTo(Vector3(SelectedHubCity.scripExchange.x, SelectedHubCity.scripExchange.y, SelectedHubCity.scripExchange.z), false)
        end
    elseif Addons.GetAddon("ShopExchangeItemDialog").Ready then
        yield("/callback ShopExchangeItemDialog true 0")
        Wait(1)
    elseif Addons.GetAddon("SelectIconString").Ready then
        yield("/callback SelectIconString true 0")
    elseif Addons.GetAddon("InclusionShop").Ready then
        Log("Free inventory slots: " .. Inventory.GetFreeInventorySlots())

        if not SelectTurnInPage then
            yield("/callback InclusionShop true 12 " .. SelectedItemToBuy.categoryMenu)
            Wait(1)
            yield("/callback InclusionShop true 13 " .. SelectedItemToBuy.subcategoryMenu)
            Wait(1)
            SelectTurnInPage = true
        end
        local qty = 1
        if not SelectedItemToBuy.oneAtATime then
            qty = math.min(Inventory.GetItemCount(CrafterScripId)//SelectedItemToBuy.price, 99)
        end
        yield("/callback InclusionShop true 14 " .. SelectedItemToBuy.listIndex .. " " .. qty)
        Wait(1)
    else
        local scripExchange = Entity.GetEntityByName("Scrip Exchange")
        if scripExchange then
            scripExchange:SetAsTarget()
            scripExchange:Interact()
        end
    end
end

---------------------
--    Retainers    --
---------------------

function ProcessRetainers()
    CurrentRetainer = nil

    Log("Handling retainers...")
    if not Log("check retainers ready") and not IPC.AutoRetainer.AreAnyRetainersAvailableForCurrentChara() or Inventory.GetFreeInventorySlots() <= 1 then
        if Addons.GetAddon("RetainerList").Ready then
            yield("/callback RetainerList true -1")
        elseif not Svc.Condition[CharacterCondition.occupiedSummoningBell] then
            State = CharacterState.ready
            Log("State Change: Ready")
        end
    else
        local summoningBell = Entity.GetEntityByName("Summoning Bell")
        if summoningBell then
            summoningBell:SetAsTarget()
        end
        Wait(1)

        if summoningBell then
            if GetDistanceToTarget() > 5 then
                if not IPC.vnavmesh.IsRunning() and not IPC.vnavmesh.PathfindInProgress() then
                    IPC.vnavmesh.PathfindAndMoveTo(Vector3(Entity.Target.Position.X, Entity.Target.Position.Y, Entity.Target.Position.Z), false)
                end
            else
                if IPC.vnavmesh.IsRunning() or IPC.vnavmesh.PathfindInProgress() then
                    IPC.vnavmesh.Stop()
                end
                if not Svc.Condition[CharacterCondition.occupiedSummoningBell] then
                    summoningBell:Interact()
                elseif Addons.GetAddon("RetainerList").Ready then
                    yield("/ays e")
                    Wait(1)
                end
            end
        elseif not Log("is in hub city zone?") and not Svc.ClientState.TerritoryType == SelectedHubCity.zoneId and
            (not SelectedHubCity.scripExchange.requiresAethernet or (SelectedHubCity.scripExchange.requiresAethernet and not Svc.ClientState.TerritoryType == SelectedHubCity.aethernet.aethernetZoneId))
        then
            TeleportTo(SelectedHubCity.aetheryte)
        elseif not Log("use aethernet?") and
            SelectedHubCity.retainerBell.requiresAethernet and (not Svc.ClientState.TerritoryType == SelectedHubCity.aethernet.aethernetZoneId or
            (GetDistanceToPoint(SelectedHubCity.retainerBell.x, SelectedHubCity.retainerBell.y, SelectedHubCity.retainerBell.z) > (DistanceBetween(SelectedHubCity.aethernet.x, SelectedHubCity.aethernet.y, SelectedHubCity.aethernet.z, SelectedHubCity.retainerBell.x, SelectedHubCity.retainerBell.y, SelectedHubCity.retainerBell.z) + 10)))
        then
            if not IPC.Lifestream.IsBusy() then
                IPC.Lifestream.ExecuteCommand(SelectedHubCity.aethernet.aethernetName)
            end
            Wait(3)
        elseif not Log("Close teleport town") and Addons.GetAddon("TeleportTown").Ready then
            Log("TeleportTown open")
            yield("/callback TeleportTown false -1")
        elseif not Log("Move to summoning bell") and GetDistanceToPoint(SelectedHubCity.retainerBell.x, SelectedHubCity.retainerBell.y, SelectedHubCity.retainerBell.z) > 1 then
            if not IPC.vnavmesh.PathfindInProgress() and not  IPC.vnavmesh.IsRunning() then
                Log("Path not running")
                IPC.vnavmesh.PathfindAndMoveTo(Vector3(SelectedHubCity.retainerBell.x, SelectedHubCity.retainerBell.y, SelectedHubCity.retainerBell.z), false)
            end
        elseif IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
            return
        elseif not Entity.Target or Entity.Target.Name ~= "Summoning Bell" then
            if summoningBell then
                summoningBell:SetAsTarget()
            end
            return
        elseif not Svc.Condition[CharacterCondition.occupiedSummoningBell] then
            if summoningBell then
                summoningBell:Interact()
            end
        elseif Addons.GetAddon("RetainerList").Ready then
            IPC.AutoRetainer.EnqueueInitiation()
            Wait(1)
        end
    end
end

------------------------
--    GrandCompany    --
------------------------

local deliveroo = false
function ExecuteGrandCompanyTurnIn()
    if IPC.Deliveroo.IsTurnInRunning() then
        return
    elseif Inventory.GetFreeInventorySlots() <= MinInventoryFreeSlots and not deliveroo then
        IPC.Lifestream.ExecuteCommand("gc")
        repeat
            Wait(1)
        until not IPC.Lifestream.IsBusy()
        Wait(1)
        yield("/ays deliver")
        Wait(1)
        deliveroo = true
    else
        State = CharacterState.ready
        Log("State Change: Ready")
        deliveroo = false
    end
end

-----------------------
--    Consumables    --
-----------------------

function PotionCheck()
    if not HasStatusId(49) and Potion then
        local potion = Inventory.GetHqItemCount(27960)

        if potion > 0 then
            Inventory.GetInventoryItem(27960):Use()
        else
            Log("[PotionCheck] HQ Potion not found in inventory.")
        end
    end
end

----------------------------
--    State Management    --
----------------------------

function Ready()
    PotionCheck()

    if not Player.Available then
        return
    elseif Retainers and IPC.AutoRetainer.AreAnyRetainersAvailableForCurrentChara() and Inventory.GetFreeInventorySlots() > 1 then
        State = CharacterState.processRetainers
        Log("State Change: ProcessingRetainers")
    elseif Inventory.GetItemCount(CrafterScripId) >= 3800 then
        State = CharacterState.scripExchange
        Log("State Change: ScripExchange")
    elseif Inventory.GetFreeInventorySlots() <= MinInventoryFreeSlots and Inventory.GetCollectableItemCount(ItemId, 1) > 0 then
        State = CharacterState.turnIn
        Log("State Change: TurnIn")
    elseif GrandCompanyTurnIn and Inventory.GetFreeInventorySlots() <= MinInventoryFreeSlots then
        State = CharacterState.gcTurnIn
        Log("State Change: GCTurnIn")
    else
        State = CharacterState.crafting
        Log("State Change: Crafting")
    end
end

CharacterState =
{
    ready            = Ready,
    crafting         = Crafting,
    goToHubCity      = GoToHubCity,
    turnIn           = TurnIn,
    scripExchange    = ScripExchange,
    processRetainers = ProcessRetainers,
    gcTurnIn         = ExecuteGrandCompanyTurnIn
}

--=========================== EXECUTION ==========================--

StopFlag = false

local classId = 0
for _, class in pairs(ClassList) do
    if CrafterClass == class.className then
        classId = class.classId
    end
end

if classId == 0 then
    Echo("Could not find crafter class: " .. CrafterClass)
    StopFlag = true
end

if ScripColor == "Orange" then
    CrafterScripId = OrangeCrafterScripId
    ScripRecipes = OrangeScripRecipes
elseif ScripColor == "Purple" then
    CrafterScripId = PurpleCrafterScripId
    ScripRecipes = PurpleScripRecipes
else
    Echo("Cannot recognize crafter scrip color: " .. ScripColor)
    StopFlag = true
end

ItemId = 0
RecipeId = 0
for _, data in ipairs(ScripRecipes) do
    if data.classId == classId then
        ItemId = data.itemId
        RecipeId = data.recipeId
    end
end

for _, item in ipairs(ScripExchangeItems) do
    if item.itemName == ItemToBuy then
        SelectedItemToBuy = item
    end
end

if SelectedItemToBuy == nil then
    Echo("Could not find " .. ItemToBuy .. " on the list of scrip exchange items.")
    StopFlag = true
end

for _, city in ipairs(HubCities) do
    if city.zoneName == HubCity then
        SelectedHubCity = city
        SelectedHubCity.aetheryte = Excel.GetRow("TerritoryType", city.zoneId).Aetheryte.PlaceName.Name
    end
end

if SelectedHubCity == nil then
    Echo("Could not find hub city: " .. HubCity)
    StopFlag = true
end

local Inn = Svc.ClientState.TerritoryType
if Inn == 177 or Inn == 178 or Inn == 179 or Inn == 1205 then
    AtInn = true
else
    AtInn = false
end

if not AtInn and HomeCommand == "Inn" then
    IPC.Lifestream.ExecuteCommand(HomeCommand)
    Log("Moving to Inn")
    AtInn = true
elseif not AtHome and HomeCommand == "Home" then
    IPC.Lifestream.ExecuteCommand(HomeCommand)
    Log("Moving Home")
    AtHome = true
elseif not AtInn and Svc.ClientState.TerritoryType ~= 1186 then
    IPC.Lifestream.ExecuteCommand("Nexus Arcade")
    Log("Moving to Solution Nine")
end

Wait(1)
while IPC.Lifestream.IsBusy() or Player.IsBusy or Svc.Condition[CharacterCondition.casting] do
    Wait(1)
end

ArtisanTimeoutStartTime = 0
Log("Start")

State = CharacterState.ready

while not StopFlag do
    if not (
        Svc.Condition[CharacterCondition.casting] or
        Svc.Condition[CharacterCondition.betweenAreas] or
        Svc.Condition[CharacterCondition.beingMoved] or
        Svc.Condition[CharacterCondition.occupiedMateriaExtractionAndRepair] or
        IPC.Lifestream.IsBusy())
    then
        State()
    end
    Wait(0.1)
end

--============================== END =============================--
