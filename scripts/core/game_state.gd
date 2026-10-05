extends Node
# GameState — Autoload. Holds current-session state: the player's
# chosen character, party roster, current map id, live HP/SP. The only
# autoload allowed to hold mutable game-session state.

var player_character: CharacterData
var current_map_id: String = ""
var player_hp: int = 0
var player_sp: int = 0

func _ready() -> void:
	player_character = DataLoader.load_resource("res://data/characters/player_fisherman.tres")
	if player_character != null:
		player_hp = player_character.max_hp
		player_sp = 0

func add_sp(amount: int) -> void:
	if player_character == null:
		return
	player_sp = clampi(player_sp + amount, 0, player_character.max_sp)
	EventBus.player_sp_changed.emit(player_sp, player_character.max_sp)

func damage_player(amount: int) -> void:
	if player_character == null:
		return
	player_hp = clampi(player_hp - amount, 0, player_character.max_hp)
	EventBus.player_hp_changed.emit(player_hp, player_character.max_hp)
