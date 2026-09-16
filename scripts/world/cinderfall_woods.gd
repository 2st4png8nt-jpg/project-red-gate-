extends Node2D
# Cinderfall Woods — the prototype's first real dungeon (GAME_DESIGN.md
# Section 7). Enlarged in the depth pass (post-Phase-6): a longer main
# corridor with a north branch (the Cinder Wraith mini-boss) and a new
# south branch (a loot chest), populated with monster packs instead of
# solo trash mobs. Reached via a Phase 1 test doorway in Waymark; the
# real Gate-driven entry point is Phase 5.

const PLAYER_SCENE := preload("res://scenes/world/Player.tscn")
const OBSTACLE_SCENE := preload("res://scenes/world/props/Obstacle.tscn")

const TILE_SIZE := 32
const MAP_SIZE := Vector2i(30, 16)
const FOREST_FLOOR_SOURCE_ID := 2
const DIRT_SOURCE_ID := 1

# Open (walkable) tile rectangles:
#  - the west doorway threshold, back to Waymark
#  - the main east-west corridor
#  - the north branch alcove (the Cinder Wraith mini-boss)
#  - the south branch alcove (a loot chest — new in the depth pass)
static var OPEN_RECTS: Array[Rect2i] = [
	Rect2i(0, 8, 1, 1),
	Rect2i(1, 7, 28, 3),
	Rect2i(10, 1, 6, 7),
	Rect2i(18, 9, 6, 6),
]

@onready var ground: TileMapLayer = $Ground
@onready var obstacles: Node2D = $Obstacles
@onready var player_spawn: Marker2D = $PlayerSpawn

func _ready() -> void:
	RectMapBuilder.build(ground, obstacles, OBSTACLE_SCENE, MAP_SIZE, OPEN_RECTS, FOREST_FLOOR_SOURCE_ID, DIRT_SOURCE_ID)
	var player := PLAYER_SCENE.instantiate()
	player.position = player_spawn.position
	add_child(player)
	player.set_camera_limits(Rect2i(Vector2i.ZERO, MAP_SIZE * TILE_SIZE))
	DungeonAmbience.apply(self, player)
	print("[CinderfallWoods] loaded. current_map_id=%s" % GameState.current_map_id)
