extends Area2D
## One-shot "walk here to fight" trigger. Placed in dungeons. Guards
## against double-firing while the deferred scene change is pending.

@export var encounter_id: String = ""

var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered or encounter_id == "" or not body.is_in_group("player"):
		return
	_triggered = true
	SceneManager.go_to_battle(encounter_id)
