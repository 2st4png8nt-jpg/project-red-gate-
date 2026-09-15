extends Node
# Global signal bus. Systems communicate through these signals instead
# of holding direct references to one another. No state, no logic.

signal player_stats_changed
signal gate_combination_resolved(result: Dictionary)
signal gate_clue_discovered(clue_id: String)
signal item_acquired(item_id: String)
signal map_changed(map_id: String)
signal battle_won(encounter_id: String)
signal battle_lost(encounter_id: String)
