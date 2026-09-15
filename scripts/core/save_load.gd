extends Node
# Serializes GameState to/from a local JSON save file. Single slot only
# for the prototype (see ARCHITECTURE.md Section 8 for the save shape).

const SAVE_PATH := "user://save_slot_0.json"

func save_game() -> void:
	var data := {
		"player": {
			"level": GameState.player.level,
			"xp": GameState.player.xp,
			"hp": GameState.player.hp,
			"max_hp": GameState.player.max_hp,
			"mp": GameState.player.mp,
			"max_mp": GameState.player.max_mp,
			"gold": GameState.player.gold,
		},
		"known_gate_clues": GameState.known_gate_clues,
		"unlocked_maps": GameState.unlocked_maps,
		"current_map": GameState.current_map_id,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveLoad: could not open save file for writing.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveLoad: could not open save file for reading.")
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveLoad: save file is corrupt.")
		return false
	var data: Dictionary = parsed
	var p: Dictionary = data.get("player", {})
	GameState.player.level = p.get("level", 1)
	GameState.player.xp = p.get("xp", 0)
	GameState.player.max_hp = p.get("max_hp", GameState.player.max_hp)
	GameState.player.hp = p.get("hp", GameState.player.max_hp)
	GameState.player.max_mp = p.get("max_mp", GameState.player.max_mp)
	GameState.player.mp = p.get("mp", GameState.player.max_mp)
	GameState.player.gold = p.get("gold", 0)
	GameState.known_gate_clues.assign(data.get("known_gate_clues", []))
	GameState.unlocked_maps.assign(data.get("unlocked_maps", ["waymark"]))
	GameState.current_map_id = data.get("current_map", "waymark")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
