extends Node
# Holds current-session authoritative state: player data, current map,
# and Gate progress flags. The only autoload allowed to hold mutable
# gameplay state. Everything else reads/writes through here.

var player: PlayerData = PlayerData.new()
var current_map_id: String = "waymark"
var unlocked_maps: Array[String] = ["waymark"]
var known_gate_clues: Array[String] = []

# Set by SceneManager.go_to_battle() just before switching to Battle.tscn;
# read once by BattleManager._ready(). Not part of the save data — a
# battle never persists across a save/load.
var pending_encounter_id: String = ""

func discover_clue(clue_id: String) -> void:
	if not known_gate_clues.has(clue_id):
		known_gate_clues.append(clue_id)
		EventBus.gate_clue_discovered.emit(clue_id)

func unlock_map(map_id: String) -> void:
	if not unlocked_maps.has(map_id):
		unlocked_maps.append(map_id)

func reset_new_game() -> void:
	player = PlayerData.new()
	current_map_id = "waymark"
	unlocked_maps = ["waymark"]
	known_gate_clues = []
