extends RefCounted
class_name RectMapBuilder
## Builds a rectangular map's ground tiles and obstacle colliders from a
## bounding size plus a list of open-area rectangles (tile coordinates).
## Any tile not covered by an open rect is solid ground with a matching
## obstacle collider spawned on top of it.
##
## This is deliberately rect-list-driven rather than ASCII-art or raw
## tile_map_data: it is trivial to read/verify (see AGENT_CONTRACTS.md)
## and there is no binary tilemap blob to hand-author correctly.

const TILE_SIZE := 32

static func build(
	ground_layer: TileMapLayer,
	obstacle_container: Node2D,
	obstacle_scene: PackedScene,
	map_size: Vector2i,
	open_rects: Array[Rect2i],
	floor_source_id: int,
	wall_ground_source_id: int
) -> void:
	for y in map_size.y:
		for x in map_size.x:
			var coord := Vector2i(x, y)
			if _is_open(coord, open_rects):
				ground_layer.set_cell(coord, floor_source_id, Vector2i.ZERO)
			else:
				ground_layer.set_cell(coord, wall_ground_source_id, Vector2i.ZERO)
				var obstacle: Node2D = obstacle_scene.instantiate()
				obstacle.position = Vector2(coord) * TILE_SIZE + Vector2(TILE_SIZE, TILE_SIZE) * 0.5
				obstacle_container.add_child(obstacle)

static func is_open_at(coord: Vector2i, map_size: Vector2i, open_rects: Array[Rect2i]) -> bool:
	if coord.x < 0 or coord.y < 0 or coord.x >= map_size.x or coord.y >= map_size.y:
		return false
	return _is_open(coord, open_rects)

static func _is_open(coord: Vector2i, open_rects: Array[Rect2i]) -> bool:
	for r in open_rects:
		if r.has_point(coord):
			return true
	return false
