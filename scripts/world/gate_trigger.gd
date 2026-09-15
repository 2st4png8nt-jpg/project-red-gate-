extends Area2D
## Opens the Gate interface when the player walks in. Re-enterable, like
## ShopTrigger — this replaces the Phase 1-4 placeholder doorway that
## went straight to Cinderfall Woods (see ARCHITECTURE.md Section 5a:
## "Phase 5 will make normal-map entry go through Gate combination
## resolution instead of a walk-up door").

signal gate_opened

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		gate_opened.emit()
