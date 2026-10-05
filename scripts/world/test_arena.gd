extends Node2D
## Proving ground for early phases: spawns the player at PlayerSpawn
## and one Enemy per marker under DummySpawns. Replaced by a real
## dungeon in Phase 11.

const PLAYER_SCENE := preload("res://scenes/world/Player.tscn")
const ENEMY_SCENE := preload("res://scenes/world/Enemy.tscn")
const HUD_SCENE := preload("res://scenes/ui/Hud.tscn")

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var dummy_spawns: Node2D = $DummySpawns

func _ready() -> void:
	var player := PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = player_spawn.global_position

	for marker in dummy_spawns.get_children():
		var enemy := ENEMY_SCENE.instantiate()
		add_child(enemy)
		enemy.global_position = marker.global_position

	add_child(HUD_SCENE.instantiate())

	print("[TestArena] loaded.")
