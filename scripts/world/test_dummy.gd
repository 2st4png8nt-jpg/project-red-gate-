extends CharacterBody2D
class_name TestDummy
## Minimal Phase 1 test enemy — stationary, no AI yet (Phase 2 adds
## targeting + enemy AI). Exists purely so the player's basic attack
## can be validated end-to-end before anything else is built on top.

@export var max_hp: int = 50

var hp: int

@onready var hp_label: Label = $HPLabel

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	_refresh_label()

func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	_refresh_label()
	if hp <= 0:
		queue_free()

func _refresh_label() -> void:
	hp_label.text = "%d/%d" % [hp, max_hp]
