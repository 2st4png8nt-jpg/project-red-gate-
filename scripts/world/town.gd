extends Node2D
# Waymark (town hub). Phase 1 deliverable: real movement, camera,
# tilemap and collision. The Gate interface and shop NPC are later
# phases (Agent 5 / Agent 4) — see GAME_DESIGN.md Section 7.

const PLAYER_SCENE := preload("res://scenes/world/Player.tscn")
const OBSTACLE_SCENE := preload("res://scenes/world/props/Obstacle.tscn")

const TILE_SIZE := 32
const MAP_SIZE := Vector2i(18, 11)
const GRASS_SOURCE_ID := 0
const DIRT_SOURCE_ID := 1

# Open (walkable) tile rectangles: the plaza, plus the doorway threshold
# on the east wall leading to Cinderfall Woods.
static var OPEN_RECTS: Array[Rect2i] = [
	Rect2i(1, 1, 16, 9),
	Rect2i(17, 5, 1, 1),
]

@onready var ground: TileMapLayer = $Ground
@onready var obstacles: Node2D = $Obstacles
@onready var player_spawn: Marker2D = $PlayerSpawn

func _ready() -> void:
	RectMapBuilder.build(ground, obstacles, OBSTACLE_SCENE, MAP_SIZE, OPEN_RECTS, GRASS_SOURCE_ID, DIRT_SOURCE_ID)
	var player := PLAYER_SCENE.instantiate()
	player.position = player_spawn.position
	add_child(player)
	player.set_camera_limits(Rect2i(Vector2i.ZERO, MAP_SIZE * TILE_SIZE))
	print("[Town] Waymark loaded. current_map_id=%s player_level=%d" % [
		GameState.current_map_id, GameState.player.level
	])
