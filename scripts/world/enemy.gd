extends CharacterBody2D
class_name Enemy
## Autonomous enemy (spec Phase 2). Simple state machine: IDLE (player
## outside aggro range) -> CHASE (move toward player) -> ATTACK (player
## in attack range, hits on a cooldown). Content is data-driven via
## EnemyData — new enemy types are new .tres instances, not new code.

enum State { IDLE, CHASE, ATTACK }

@export var enemy_data: EnemyData

var hp: int
var state: State = State.IDLE
var _can_attack := true
var _player: Node2D = null

@onready var hp_label: Label = $HPLabel
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	add_to_group("enemies")
	hp = enemy_data.max_hp
	attack_timer.wait_time = enemy_data.attack_cooldown
	_refresh_label()
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]

func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist := global_position.distance_to(_player.global_position)
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if dist <= enemy_data.aggro_range:
				state = State.CHASE
		State.CHASE:
			if dist <= enemy_data.attack_range:
				state = State.ATTACK
				velocity = Vector2.ZERO
			else:
				velocity = global_position.direction_to(_player.global_position) * enemy_data.move_speed
		State.ATTACK:
			velocity = Vector2.ZERO
			if dist > enemy_data.attack_range:
				state = State.CHASE
			elif _can_attack:
				_attack_player()
	move_and_slide()

func _attack_player() -> void:
	_can_attack = false
	attack_timer.start()
	GameState.damage_player(enemy_data.attack)

func _on_attack_timer_timeout() -> void:
	_can_attack = true

func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	_refresh_label()
	if hp <= 0:
		queue_free()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _player != null and _player.has_method("set_target"):
			_player.set_target(self)

func _refresh_label() -> void:
	hp_label.text = "%d/%d" % [hp, enemy_data.max_hp]
