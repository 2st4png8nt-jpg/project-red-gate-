extends Node
## Entry point scene (project.godot run/main_scene). Confirms autoloads
## are alive, then hands off to the current test environment.

func _ready() -> void:
	print("[Boot] Tower RPG booting...")
	print("[Boot] Autoloads ready -> EventBus=%s DataLoader=%s GameState=%s SceneManager=%s" % [
		EventBus != null, DataLoader != null, GameState != null, SceneManager != null
	])
	SceneManager.go_to_test_arena()
