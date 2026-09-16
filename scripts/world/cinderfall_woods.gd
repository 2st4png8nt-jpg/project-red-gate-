extends Node2D
# Cinderfall Woods — the prototype's first real dungeon (GAME_DESIGN.md
# Section 7). A main corridor plus one branching alcove (the "bonus
# loot area" exploration pillar). Reached via a Phase 1 test doorway in
# Waymark; the real Gate-driven entry point is Phase 5.

const PLAYER_SCENE := preload("res://scenes/world/Player.tscn")
const OBSTACLE_SCENE := preload("res://scenes/world/props/Obstacle.tscn")

const TILE_SIZE := 32
const MAP_SIZE := Vector2i(20, 11)
const FOREST_FLOOR_SOURCE_ID := 2
const DIRT_SOURCE_ID := 1

# Open (walkable) tile rectangles:
#  - the west doorway threshold, back to Waymark
#  - the main east-west corridor/clearing
#  - the north branch alcove (the bonus/side-exploration area)
static var OPEN_RECTS: Array[Rect2i] = [
	Rect2i(0, 5, 1, 1),
	Rect2i(1, 4, 18, 3),
	Rect2i(7, 1, 5, 3),
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
