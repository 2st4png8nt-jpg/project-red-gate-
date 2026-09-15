extends Area2D
## Generic "walk onto this doorway to change map" trigger. Placed at map
## edges. Phase 1 doorways are a direct stand-in for the real Gate-driven
## entry point (Phase 5 adds the Gate interface in Town; Cinderfall
## Woods and The Silent Marsh will ultimately be entered by resolving a
## Gate combination, not by walking through a plain doorway — this node
## just proves map transitions work mechanically until then).

@export var target_map_id: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if target_map_id != "" and body.is_in_group("player"):
		SceneManager.go_to_map(target_map_id)
