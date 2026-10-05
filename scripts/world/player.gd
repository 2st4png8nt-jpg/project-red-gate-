extends CharacterBody2D
class_name Player
## Player-controlled character (spec Sections 6, 16). Real-time WASD
## movement; Camera2D follows as a child. Basic attack (LMB) damages
## the nearest enemy within character_data.attack_range and generates
## SP (spec Section 11) — no cooldown resource, just a short swing
## cooldown so attacks can't be spammed every frame.

@export var character_data: CharacterData

@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

var _can_attack := true

func _ready() -> void:
	if character_data == null:
		character_data = GameState.player_character
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	velocity = input_dir.normalized() * character_data.move_speed
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_basic_attack()

func _try_basic_attack() -> void:
	if character_data == null or not _can_attack:
		return
	var target := _find_nearest_enemy_in_range()
	if target == null:
		return
	_can_attack = false
	attack_cooldown_timer.start()
	target.take_damage(character_data.attack)
	GameState.add_sp(character_data.sp_per_basic_attack)

func _find_nearest_enemy_in_range() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = character_data.attack_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_method("take_damage"):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist <= nearest_dist:
			nearest = enemy
			nearest_dist = dist
	return nearest

func _on_attack_cooldown_timer_timeout() -> void:
	_can_attack = true
