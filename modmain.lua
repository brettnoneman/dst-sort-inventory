-- Sort Inventory Mod
-- Sorts player inventory by item category, then alphabetically within each category.

local SORT_KEY = GetModConfigData("keybind")

-- Category priority order (lower number = sorted first)
local CATEGORY_ORDER = {
    weapons  = 1,
    armour   = 2,
    tools    = 3,
    light    = 4,
    food     = 5,
    resources= 6,
    misc     = 7,
}

-- Classify an item prefab into a category
local function GetItemCategory(item)
    if item == nil then return "misc" end

    local prefab = item.prefab or ""

    -- Weapons
    if item.components and item.components.weapon then
        return "weapons"
    end

    -- Armour
    if item.components and item.components.armor then
        return "armour"
    end

    -- Tools (axe, pickaxe, shovel, etc.)
    if item.components and item.components.tool then
        return "tools"
    end

    -- Lights (torch, lantern, etc.)
    if item.components and item.components.fueled then
        local lightprefabs = {
            torch = true, lantern = true, molehat = true,
            minerhat = true,
        }
        if lightprefabs[prefab] then
            return "light"
        end
    end

    -- Food
    if item.components and item.components.edible then
        return "food"
    end

    -- Resources (stackable raw materials)
    local resourceprefabs = {
        log = true, rocks = true, flint = true, grass = true,
        twigs = true, petals = true, nitre = true, goldnugget = true,
        charcoal = true, ash = true, silk = true, spidergland = true,
        cutgrass = true, pinecone = true, acorn = true, seeds = true,
        berries = true, berries_cooked = true, ice = true, poop = true,
        mosquitosack = true, beefalowool = true, feather_crow = true,
        feather_robin = true, feather_robin_winter = true, feather_canary = true,
        livinglog = true, nightmarefuel = true, gears = true, transistor = true,
        thulecite = true, thulecite_pieces = true, yellowamulet = true,
    }
    if resourceprefabs[prefab] then
        return "resources"
    end

    return "misc"
end

-- Get a sort value within a category (lower = sorted first)
local function GetSortValue(item)
    if item == nil then return 0 end

    local category = GetItemCategory(item)

    if category == "weapons" and item.components.weapon then
        -- Sort weapons by damage descending (higher damage first)
        return -(item.components.weapon:GetDamage(item, nil) or 0)
    end

    if category == "tools" and item.components.finiteuses then
        -- Sort tools by remaining uses descending (more durability first)
        return -(item.components.finiteuses:GetPercent() or 0)
    end

    if category == "food" and item.components.edible then
        -- Sort food by hunger value descending
        return -(item.components.edible.hungervalue or 0)
    end

    -- Default: sort alphabetically by prefab name
    return 0
end

-- Main sort function
local function SortInventory(player)
    if player == nil or player:HasTag("playerghost") then
        return
    end

    local inventory = player.replica and player.replica.inventory
    if inventory == nil then return end

    -- Collect all items from inventory slots
    local items = {}
    local num_slots = inventory:GetNumSlots()

    for i = 1, num_slots do
        local item = inventory:GetItemInSlot(i)
        if item ~= nil then
            table.insert(items, item)
        end
    end

    -- Also collect from backpack if equipped
    local backpack = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local backpack_items = {}
    if backpack ~= nil and backpack.components and backpack.components.container then
        local bp_container = backpack.components.container
        for i = 1, bp_container.numslots do
            local item = bp_container:GetItemInSlot(i)
            if item ~= nil then
                table.insert(backpack_items, item)
            end
        end
    end

    -- Sort function: by category first, then by sort value, then alphabetically
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

        -- Alphabetical fallback
        return (a.prefab or "") < (b.prefab or "")
    end

    table.sort(items, ItemSorter)
    if #backpack_items > 0 then
        table.sort(backpack_items, ItemSorter)
    end

    -- Clear inventory slots then re-insert in sorted order
    -- We use GiveItem on a temporary basis by removing and re-adding
    -- DST's inventory handles stacking automatically when items are re-inserted

    -- Remove all items from inventory
    for i = 1, num_slots do
        local item = inventory:GetItemInSlot(i)
        if item ~= nil then
            inventory:RemoveItemBySlot(i)
        end
    end

    -- Re-insert in sorted order (DST will stack automatically)
    for _, item in ipairs(items) do
        inventory:GiveItem(item)
    end

    -- Handle backpack
    if backpack ~= nil and backpack.components and backpack.components.container then
        local bp_container = backpack.components.container
        for i = 1, bp_container.numslots do
            local item = bp_container:GetItemInSlot(i)
            if item ~= nil then
                bp_container:RemoveItemBySlot(i)
            end
        end
        for _, item in ipairs(backpack_items) do
            bp_container:GiveItem(item)
        end
    end
end

-- Hook into player initialization
AddPlayerPostInit(function(player)
    -- Only run on the local player
    if not ThePlayer or player ~= ThePlayer then return end

    -- Register keybind handler
    TheInput:AddKeyUpHandler(SORT_KEY, function()
        -- Don't sort if typing in chat
        if ThePlayer ~= nil and not TheFrontEnd:GetActiveScreen().name == "HUD" then
            return
        end
        SortInventory(ThePlayer)
    end)
end)