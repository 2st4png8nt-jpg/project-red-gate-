extends Node
# EventBus — Autoload. Global signal bus; systems communicate through
# signals here instead of reaching into each other directly. No state,
# no logic beyond signal declarations and thin emit_*() helpers.

signal player_hp_changed(current: int, max: int)
signal player_sp_changed(current: int, max: int)
signal target_changed(target: Node)
signal skill_loadout_changed
signal item_identified(item: Resource)
signal party_command_changed(command: String)
