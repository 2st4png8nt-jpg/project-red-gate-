extends Node2D
# The Red Gate — the prototype's one hand-crafted special destination,
# reached only by finding the uncatalogued Hollow+Undying+Ember
# combination (see GateResolver / data/gates/combinations/red_gate.tres).
# Distinct palette, one guaranteed fight against the Ashen Warden, and
# the unique reward: Cindermourn. Not procedurally generated — see
# GAME_DESIGN.md Section 7 ("not a recolor of the normal maps") and
# ARCHITECTURE.md Section 7a for why this stays hand-built.

const PLAYER_SCENE := preload("res://scenes/world/Player.tscn")
const OBSTACLE_SCENE := preload("res://scenes/world/props/Obstacle.tscn")

const TILE_SIZE := 32
const MAP_SIZE := Vector2i(12, 9)
const REDGATE_FLOOR_SOURCE_ID := 6
const DIRT_SOURCE_ID := 1

static var OPEN_RECTS: Array[Rect2i] = [
	Rect2i(0, 4, 1, 1),
	Rect2i(1, 3, 10, 3),
]

@onready var ground: TileMapLayer = $Ground
@onready var obstacles: Node2D = $Obstacles
@onready var player_spawn: Marker2D = $PlayerSpawn

func _ready() -> void:
	RectMapBuilder.build(ground, obstacles, OBSTACLE_SCENE, MAP_SIZE, OPEN_RECTS, REDGATE_FLOOR_SOURCE_ID, DIRT_SOURCE_ID)
	var player := PLAYER_SCENE.instantiate()
	player.position = player_spawn.position
	add_child(player)
	player.set_camera_limits(Rect2i(Vector2i.ZERO, MAP_SIZE * TILE_SIZE))
	print("[RedGate] loaded. current_map_id=%s" % GameState.current_map_id)
