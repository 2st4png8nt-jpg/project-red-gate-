extends RefCounted
class_name DungeonAmbience
## Lightweight atmosphere for dungeon maps (Phase 6 polish pass): a dim
## CanvasModulate over the whole map plus a soft light that follows the
## player, so dungeons read as darker/tenser than the Waymark hub
## without needing any real lighting art — the light's texture is
## generated at runtime. See ARCHITECTURE.md Section 7b. Not applied to
## Town, which stays the fully-lit safe hub.

const DIM_COLOR := Color(0.5, 0.48, 0.62)
const LIGHT_TEXTURE_SIZE := 256
const LIGHT_RADIUS_PX := 160.0

static func apply(map_root: Node2D, player: Node2D) -> void:
	var dim := CanvasModulate.new()
	dim.color = DIM_COLOR
	map_root.add_child(dim)

	var light := PointLight2D.new()
	light.texture = _build_light_texture()
	light.texture_scale = LIGHT_RADIUS_PX / (LIGHT_TEXTURE_SIZE * 0.5)
	light.energy = 1.4
	player.add_child(light)

static func _build_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = LIGHT_TEXTURE_SIZE
	tex.height = LIGHT_TEXTURE_SIZE
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex
