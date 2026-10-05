extends CharacterBody2D
class_name Player
## Player-controlled character (spec Sections 6, 16). Real-time WASD
## movement; Camera2D follows as a child. Tab cycles the explicit
## target (nearest-first ordering); clicking an enemy selects it
## directly via Enemy._on_input_event -> set_target(). Basic attack
## (LMB) hits the current target if it's in range, else falls back to
## the nearest enemy in range so the player is never left unable to
## act just because nothing is targeted. Generates SP per hit (spec
## Section 11) — no cooldown resource, just a short swing cooldown so
## attacks can't be spammed every frame.

@export var character_data: CharacterData

@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

var _can_attack := true
var current_target: Node2D = null

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

	if current_target != null and not is_instance_valid(current_target):
		set_target(null)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_basic_attack()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_cycle_target()

func set_target(enemy: Node2D) -> void:
	current_target = enemy
	EventBus.target_changed.emit(enemy)

func _cycle_target() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		set_target(null)
		return
	enemies.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	if current_target == null or not enemies.has(current_target):
		set_target(enemies[0])
		return
	var idx := enemies.find(current_target)
	set_target(enemies[(idx + 1) % enemies.size()])

func _try_basic_attack() -> void:
	if character_data == null or not _can_attack:
		return
	var target := _resolve_attack_target()
	if target == null:
		return
	_can_attack = false
	attack_cooldown_timer.start()
	target.take_damage(character_data.attack)
	GameState.add_sp(character_data.sp_per_basic_attack)

func _resolve_attack_target() -> Node2D:
	if current_target != null and is_instance_valid(current_target):
		if global_position.distance_to(current_target.global_position) <= character_data.attack_range:
			return current_target
	return _find_nearest_enemy_in_range()

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
