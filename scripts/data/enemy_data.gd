extends Resource
class_name EnemyData
## Enemy definition (spec Section 37) — data-driven so new enemy types
## need no new code, only a new .tres instance.

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 50
@export var attack: int = 8
@export var move_speed: float = 90.0
@export var aggro_range: float = 220.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.2
@export var is_elite: bool = false
