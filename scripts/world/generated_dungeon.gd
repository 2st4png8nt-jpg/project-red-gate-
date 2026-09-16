extends Node2D
# Runtime-built dungeon for any Gate combination that isn't a known or
# special destination (see GateResolver). Shape/size come from
# DungeonProfile.branch_tier (0-3 side branches), floor theme from
# DungeonProfile.floor_source_id, enemy level and loot tier from
# DungeonProfile.level — see ARCHITECTURE.md Section 7a. Unlike Town or
# Cinderfall Woods, this scene has no fixed layout of its own; every
# node below the Ground/Obstacles/TitleLabel is spawned in _ready().
#
# Depth pass (post-Phase-6): every tier's map, corridor length, and
# encounter/chest count grew substantially (.hack-scale, not a single
# corridor with 1-4 solo markers) — each encounter now spawns a pack
# (see GeneratedEncounterTrigger) instead of one enemy.

const PLAYER_SCENE := preload("res://scenes/world/Player.tscn")
const OBSTACLE_SCENE := preload("res://scenes/world/props/Obstacle.tscn")
const DOORWAY_SCENE := preload("res://scenes/world/props/DoorwayTrigger.tscn")
const ENCOUNTER_MARKER_SCENE := preload("res://scenes/world/props/GeneratedEncounterMarker.tscn")
const LOOT_CHEST_SCENE := preload("res://scenes/world/props/LootChest.tscn")

const TILE_SIZE := 32
const WALL_GROUND_SOURCE_ID := 1 # dirt, shared across every theme
const CHEST_LOOT_TABLE_ID := "generated_chest_loot"

# Indexed by branch_tier (0..3). Doorway sits at the vertical middle of
# the main corridor in every tier.
const TIER_MAP_SIZE: Array[Vector2i] = [
	Vector2i(22, 11), Vector2i(28, 13), Vector2i(34, 15), Vector2i(40, 17),
]
const TIER_DOORWAY_ROW := [5, 6, 7, 8]
const TIER_ENCOUNTER_TILES := [
	[Vector2i(6, 5), Vector2i(16, 5)],
	[Vector2i(5, 6), Vector2i(13, 6), Vector2i(21, 6), Vector2i(12, 2)],
	[Vector2i(5, 7), Vector2i(15, 7), Vector2i(25, 7), Vector2i(13, 2), Vector2i(13, 12)],
	[Vector2i(5, 8), Vector2i(14, 8), Vector2i(23, 8), Vector2i(32, 8), Vector2i(13, 2), Vector2i(13, 12), Vector2i(36, 4)],
]
const TIER_CHEST_TILES := [
	[],
	[Vector2i(11, 3)],
	[Vector2i(12, 13)],
	[Vector2i(14, 13), Vector2i(37, 5)],
]
const DEFAULT_ENEMY_POOL: Array[String] = ["ember_wisp", "bramble_husk"]
# Content-expansion pass: Verdant/Drowned dungeons get a themed enemy
# instead of the generic duo every origin used to share. Any origin not
# listed here (including the two new Frost/Storm themes) still falls
# back to DEFAULT_ENEMY_POOL — not every theme needs unique monster
# content yet, per the original Phase 5 scope decision; this only
# partially revises it where it was cheap to.
const ORIGIN_ENEMY_POOL := {
	"Verdant": ["bramble_husk", "thornling"],
	"Drowned": ["ember_wisp", "brinewisp"],
}

@onready var ground: TileMapLayer = $Ground
@onready var obstacles: Node2D = $Obstacles
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	var profile: DungeonProfile = GameState.pending_dungeon_profile
	if profile == null:
		push_error("GeneratedDungeon: no pending_dungeon_profile set.")
		return

	var tier: int = clampi(profile.branch_tier, 0, 3)
	var map_size: Vector2i = TIER_MAP_SIZE[tier]
	var doorway_row: int = TIER_DOORWAY_ROW[tier]
	var open_rects := _open_rects_for_tier(tier, map_size, doorway_row)

	RectMapBuilder.build(ground, obstacles, OBSTACLE_SCENE, map_size, open_rects, profile.floor_source_id, WALL_GROUND_SOURCE_ID)

	var player := PLAYER_SCENE.instantiate()
	player.position = _tile_center(Vector2i(2, doorway_row))
	add_child(player)
	player.set_camera_limits(Rect2i(Vector2i.ZERO, map_size * TILE_SIZE))
	DungeonAmbience.apply(self, player)

	var door := DOORWAY_SCENE.instantiate()
	door.position = _tile_center(Vector2i(0, doorway_row))
	door.target_map_id = "waymark"
	add_child(door)

	var enemy_pool: Array[String] = ORIGIN_ENEMY_POOL.get(profile.origin_word, DEFAULT_ENEMY_POOL)
	for tile in TIER_ENCOUNTER_TILES[tier]:
		var trigger := ENCOUNTER_MARKER_SCENE.instantiate()
		trigger.position = _tile_center(tile)
		trigger.enemy_pool = enemy_pool
		trigger.level = profile.level
		trigger.can_flee = true
		trigger.loot_table_id_override = profile.loot_table_id
		add_child(trigger)

	for tile in TIER_CHEST_TILES[tier]:
		var chest := LOOT_CHEST_SCENE.instantiate()
		chest.position = _tile_center(tile)
		chest.loot_table_id = CHEST_LOOT_TABLE_ID
		add_child(chest)

	title_label.text = "%s %s %s Reach — Level %d" % [
		profile.origin_word, profile.tone_word, profile.sign_word, profile.level
	]
	print("[GeneratedDungeon] %s (tier=%d theme_source=%d)" % [title_label.text, tier, profile.floor_source_id])

func _tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile) * TILE_SIZE + Vector2(TILE_SIZE, TILE_SIZE) * 0.5

## Doorway + a straight corridor always exist; each branch_tier above 0
## adds one more side branch touching (not necessarily overlapping) the
## corridor, guaranteeing every open rect is reachable by construction —
## see PROGRESS.md for the reachability self-test that checks this.
func _open_rects_for_tier(tier: int, map_size: Vector2i, doorway_row: int) -> Array[Rect2i]:
	var rects: Array[Rect2i] = [Rect2i(0, doorway_row, 1, 1)]
	rects.append(Rect2i(1, doorway_row - 1, map_size.x - 2, 3))
	match tier:
		1:
			rects.append(Rect2i(9, 1, 6, doorway_row - 1))
		2:
			rects.append(Rect2i(10, 1, 6, doorway_row - 1))
			rects.append(Rect2i(10, doorway_row + 1, 6, 7))
		3:
			rects.append(Rect2i(11, 1, 6, doorway_row - 1))
			rects.append(Rect2i(11, doorway_row + 1, 6, 7))
			rects.append(Rect2i(map_size.x - 6, 3, 5, 4))
	return rects
