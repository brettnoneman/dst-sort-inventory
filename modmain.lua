-- Sort Inventory Mod
-- Sorts player inventory by item category, then alphabetically within each category.

-- Category priority order (lower number = sorted first)
local CATEGORY_ORDER = {
    weapons   = 1,
    armour    = 2,
    tools     = 3,
    light     = 4,
    food      = 5,
    resources = 6,
    misc      = 7,
}

-- Classify an item into a category
local function GetItemCategory(item)
    if item == nil then return "misc" end

    local prefab = item.prefab or ""

    if item.components.weapon then
        return "weapons"
    end

    if item.components.armor then
        return "armour"
    end

    if item.components.tool then
        return "tools"
    end

    local lightprefabs = {
        torch = true, lantern = true, molehat = true, minerhat = true,
    }
    if lightprefabs[prefab] then
        return "light"
    end

    if item.components.edible then
        return "food"
    end

    local resourceprefabs = {
        log = true, rocks = true, flint = true, grass = true,
        twigs = true, petals = true, nitre = true, goldnugget = true,
        charcoal = true, ash = true, silk = true, spidergland = true,
        cutgrass = true, pinecone = true, acorn = true, seeds = true,
        berries = true, berries_cooked = true, ice = true, poop = true,
        mosquitosack = true, beefalowool = true, feather_crow = true,
        feather_robin = true, feather_robin_winter = true,
        livinglog = true, nightmarefuel = true, gears = true,
        transistor = true, thulecite = true, thulecite_pieces = true,
    }
    if resourceprefabs[prefab] then
        return "resources"
    end

    return "misc"
end

-- Get a sort value within a category
local function GetSortValue(item)
    if item == nil then return 0 end

    local category = GetItemCategory(item)

    if category == "weapons" and item.components.weapon then
        return -(item.components.weapon:GetDamage(item, nil) or 0)
    end

    if category == "tools" and item.components.finiteuses then
        return -(item.components.finiteuses:GetPercent() or 0)
    end

    if category == "food" and item.components.edible then
        return -(item.components.edible.hungervalue or 0)
    end

    return 0
end

-- Sort comparator
local function ItemSorter(a, b)
    local cat_a = GetItemCategory(a)
    local cat_b = GetItemCategory(b)
    local ord_a = CATEGORY_ORDER[cat_a] or 99
    local ord_b = CATEGORY_ORDER[cat_b] or 99

    if ord_a ~= ord_b then
        return ord_a < ord_b
    end

    local val_a = GetSortValue(a)
    local val_b = GetSortValue(b)
    if val_a ~= val_b then
        return val_a < val_b
    end

    return (a.prefab or "") < (b.prefab or "")
end

-- Main sort function
local function SortInventory(player)
    if player == nil or player:HasTag("playerghost") then
        return
    end

    local inventory = player.components.inventory
    if inventory == nil then return end

    -- Collect items from main inventory
    local items = {}
    for i = 1, inventory.maxslots do
        local item = inventory:GetItemInSlot(i)
        if item ~= nil then
            table.insert(items, item)
        end
    end

    -- Collect items from backpack
    local backpack = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local backpack_items = {}
    if backpack ~= nil and backpack.components.container then
        local bp = backpack.components.container
        for i = 1, bp.numslots do
            local item = bp:GetItemInSlot(i)
            if item ~= nil then
                table.insert(backpack_items, item)
            end
        end
    end

    -- Sort both lists
    table.sort(items, ItemSorter)
    if #backpack_items > 0 then
        table.sort(backpack_items, ItemSorter)
    end

    -- Clear and re-insert main inventory
    for i = 1, inventory.maxslots do
        inventory:RemoveItemBySlot(i)
    end
    for _, item in ipairs(items) do
        inventory:GiveItem(item)
    end

    -- Clear and re-insert backpack
    if backpack ~= nil and backpack.components.container then
        local bp = backpack.components.container
        for i = 1, bp.numslots do
            bp:RemoveItemBySlot(i)
        end
        for _, item in ipairs(backpack_items) do
            bp:GiveItem(item)
        end
    end
end

-- Register keybind after player exists
AddPlayerPostInit(function(player)
    player:ListenForEvent("becamehuman", function()
        local sort_key = GetModConfigData("keybind")

        TheInput:AddKeyUpHandler(sort_key, function()
            -- Don't sort if player is typing in chat
            local screen = TheFrontEnd:GetActiveScreen()
            if screen ~= nil and screen.name == "HUD" then
                SortInventory(player)
            end
        end)
    end)
end)