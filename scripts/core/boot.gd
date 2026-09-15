extends Node
# Entry point scene script. Confirms the autoload chain initialized and
# hands off to SceneManager. This is the Phase 0 "smallest bootable
# prototype" per CLAUDE.md Section 34.

func _ready() -> void:
	print("[Boot] Project Red Gate booting...")
	print("[Boot] Autoloads ready -> EventBus=%s DataLoader=%s GameState=%s SceneManager=%s SaveLoad=%s" % [
		EventBus != null, DataLoader != null, GameState != null, SceneManager != null, SaveLoad != null
	])
	SceneManager.go_to_town()
