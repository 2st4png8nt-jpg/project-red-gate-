extends Node2D
# Phase 0 placeholder for Waymark. Proves the Boot -> SceneManager ->
# Town chain works. Real movement/camera/tilemap arrive in Phase 1
# (owned by Agent 4, see AGENT_CONTRACTS.md).

func _ready() -> void:
	print("[Town] Waymark loaded. current_map_id=%s player_level=%d" % [
		GameState.current_map_id, GameState.player.level
	])
