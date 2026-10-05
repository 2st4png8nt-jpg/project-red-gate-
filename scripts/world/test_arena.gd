extends Node2D
## Phase 1 proving ground: spawns the player at PlayerSpawn and one
## TestDummy per marker under DummySpawns. Replaced by a real dungeon
## in Phase 11.

const PLAYER_SCENE := preload("res://scenes/world/Player.tscn")
const TEST_DUMMY_SCENE := preload("res://scenes/world/TestDummy.tscn")

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var dummy_spawns: Node2D = $DummySpawns

func _ready() -> void:
	var player := PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = player_spawn.global_position

	for marker in dummy_spawns.get_children():
		var dummy := TEST_DUMMY_SCENE.instantiate()
		add_child(dummy)
		dummy.global_position = marker.global_position

	print("[TestArena] loaded.")
