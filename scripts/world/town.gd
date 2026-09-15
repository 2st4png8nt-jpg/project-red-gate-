extends Node2D
# Waymark (town hub). Phase 1: real movement, camera, tilemap and
# collision. Phase 3: the shop, a currency sink. Phase 5: the Gate
# interface, replacing the old walk-up doorway to Cinderfall Woods —
# see GAME_DESIGN.md Section 7 and ARCHITECTURE.md Section 5a.

const PLAYER_SCENE := preload("res://scenes/world/Player.tscn")
const OBSTACLE_SCENE := preload("res://scenes/world/props/Obstacle.tscn")
const SHOP_UI_SCENE := preload("res://scenes/ui/ShopUI.tscn")
const GATE_UI_SCENE := preload("res://scenes/ui/GateUI.tscn")

const TILE_SIZE := 32
const MAP_SIZE := Vector2i(18, 11)
const GRASS_SOURCE_ID := 0
const DIRT_SOURCE_ID := 1

const SHOP_ITEM_IDS: Array[String] = [
	"rusted_shortsword", "travelers_vest", "lucky_charm", "ember_draught",
]

# Open (walkable) tile rectangles: the plaza, plus the doorway threshold
# on the east wall leading to Cinderfall Woods.
static var OPEN_RECTS: Array[Rect2i] = [
	Rect2i(1, 1, 16, 9),
	Rect2i(17, 5, 1, 1),
]

@onready var ground: TileMapLayer = $Ground
@onready var obstacles: Node2D = $Obstacles
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var shop_trigger: Area2D = $ShopTrigger
@onready var gate_trigger: Area2D = $GateCluster

var player: CharacterBody2D
var shop_ui: CanvasLayer
var gate_ui: CanvasLayer

func _ready() -> void:
	RectMapBuilder.build(ground, obstacles, OBSTACLE_SCENE, MAP_SIZE, OPEN_RECTS, GRASS_SOURCE_ID, DIRT_SOURCE_ID)
	player = PLAYER_SCENE.instantiate()
	player.position = player_spawn.position
	add_child(player)
	player.set_camera_limits(Rect2i(Vector2i.ZERO, MAP_SIZE * TILE_SIZE))

	shop_ui = SHOP_UI_SCENE.instantiate()
	shop_ui.item_ids = SHOP_ITEM_IDS
	add_child(shop_ui)
	shop_ui.visibility_changed.connect(_update_player_movement)
	shop_trigger.shop_opened.connect(func(): shop_ui.show())

	gate_ui = GATE_UI_SCENE.instantiate()
	add_child(gate_ui)
	gate_ui.visibility_changed.connect(_update_player_movement)
	gate_trigger.gate_opened.connect(func(): gate_ui.show())

	print("[Town] Waymark loaded. current_map_id=%s player_level=%d" % [
		GameState.current_map_id, GameState.player.level
	])

func _update_player_movement() -> void:
	player.set_physics_process(not shop_ui.visible and not gate_ui.visible)
