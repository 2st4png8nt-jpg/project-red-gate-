extends Area2D
## Opens the Waymark shop when the player walks in. Re-enterable (no
## one-shot guard, unlike EncounterTrigger) — browsing a shop
## repeatedly is normal.

signal shop_opened

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		shop_opened.emit()
