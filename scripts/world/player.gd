extends CharacterBody2D
# Basic 4-directional overworld movement (raw key checks — a formal,
# rebindable InputMap is deferred to a later polish phase). Owned by
# Agent 4 (World). See ARCHITECTURE.md for the collision layer
# convention (player = layer 2, world/obstacles = layer 1).

const SPEED := 140.0

@onready var camera: Camera2D = $Camera2D

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1
	velocity = input_dir.normalized() * SPEED
	move_and_slide()

func set_camera_limits(pixel_rect: Rect2i) -> void:
	camera.limit_left = pixel_rect.position.x
	camera.limit_top = pixel_rect.position.y
	camera.limit_right = pixel_rect.position.x + pixel_rect.size.x
	camera.limit_bottom = pixel_rect.position.y + pixel_rect.size.y
