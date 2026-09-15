extends Node
# Owns switching the active scene. Nothing outside this autoload should
# call get_tree().change_scene_to_* directly (see ARCHITECTURE.md
# Section 5).

const TOWN_SCENE := "res://scenes/world/Town.tscn"
const BATTLE_SCENE := "res://scenes/combat/Battle.tscn"
const GENERATED_DUNGEON_SCENE := "res://scenes/world/GeneratedDungeon.tscn"

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
	# current_map_id is deliberately left untouched: a battle happens
	# "on top of" the map the player was exploring, and BattleUI sends
	# the player back to that same map_id when the battle ends.
	GameState.pending_encounter_id = encounter_id
	get_tree().change_scene_to_file.call_deferred(BATTLE_SCENE)

func go_to_generated_battle(encounter: EncounterData) -> void:
	# Same as go_to_battle(), but for an in-memory EncounterData built by
	# a GeneratedEncounterTrigger rather than a data/encounters/*.tres row.
	GameState.pending_generated_encounter = encounter
	get_tree().change_scene_to_file.call_deferred(BATTLE_SCENE)

func go_to_generated_dungeon(profile: DungeonProfile) -> void:
	# GateResolver produced a GENERATED result: there is no MapData row
	# to look up (a fixed scene serves every possible Gate combination),
	# so this bypasses go_to_map()'s data/maps/ lookup entirely.
	# pending_dungeon_profile is deliberately NOT cleared after the scene
	# reads it (unlike pending_encounter_id/pending_generated_encounter)
	# — go_to_current_map() below needs to be able to rebuild the same
	# dungeon again after a battle fought inside it.
	GameState.current_map_id = "generated"
	GameState.pending_dungeon_profile = profile
	get_tree().change_scene_to_file.call_deferred(GENERATED_DUNGEON_SCENE)
	EventBus.map_changed.emit("generated")

## What BattleUI calls to return to "wherever the player was exploring"
## after a battle — go_to_map(current_map_id) alone can't handle a
## generated dungeon, since "generated" isn't a real data/maps/ row.
func go_to_current_map() -> void:
	if GameState.current_map_id == "generated":
		go_to_generated_dungeon(GameState.pending_dungeon_profile)
	else:
		go_to_map(GameState.current_map_id)
