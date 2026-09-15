extends Node
# Owns switching the active scene. Nothing outside this autoload should
# call get_tree().change_scene_to_* directly (see ARCHITECTURE.md
# Section 5).

const TOWN_SCENE := "res://scenes/world/Town.tscn"

# change_scene_to_file() is deferred everywhere in this autoload because
# a caller in _ready() of the scene currently being added to the tree
# (e.g. Boot.tscn) would otherwise hit "Parent node is busy adding/
# removing children" — the scene tree can't be told to swap its root
# while it's still finishing the previous swap.

func go_to_town() -> void:
	get_tree().change_scene_to_file.call_deferred(TOWN_SCENE)

func go_to_map(map_id: String) -> void:
	var map_data: MapData = DataLoader.load_resource("res://data/maps/%s.tres" % map_id)
	if map_data == null:
		push_warning("SceneManager: unknown map id '%s', staying put." % map_id)
		return
	GameState.current_map_id = map_data.id
	get_tree().change_scene_to_file.call_deferred(map_data.scene_path)
	EventBus.map_changed.emit(map_data.id)

func go_to_battle(encounter_id: String) -> void:
	# Implemented in Phase 2 (Combat). Kept as a stub now so World/Gate
	# work in Phase 1 has a stable call site to build against.
	push_warning("SceneManager.go_to_battle: not implemented until Phase 2 (encounter_id=%s)" % encounter_id)
