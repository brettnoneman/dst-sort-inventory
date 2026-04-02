name = "Sort Inventory"
description = "Sorts your inventory by item type with a keybind."
author = "brett.noneman"
version = "1.0.0"
api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
forumthread = ""

client_only_mod = false
all_clients_require_mod = false
server_only_mod = false


configuration_options = {
    {
        name    = "keybind",
        label   = "Sort key:",
        default = KEY_G,
        options = {
            { description = "G", data = KEY_G },
            { description = "H", data = KEY_H },
            { description = "J", data = KEY_J },
            { description = "K", data = KEY_K },
            { description = "Z", data = KEY_Z },
        },
    },
}