extends Node
# SceneManager — Autoload. Owns switching the active scene via
# change_scene_to_file.call_deferred() — calling it synchronously from
# another node's _ready()/input handler throws "Parent node is busy
# adding/removing children".

func go_to_test_arena() -> void:
	GameState.current_map_id = "test_arena"
	get_tree().change_scene_to_file.call_deferred("res://scenes/world/TestArena.tscn")
