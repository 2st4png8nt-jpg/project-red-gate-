extends Resource
class_name CharacterData
## Base character definition (spec Section 37). Shared by the player's
## adaptive character and AI party members: the stat/AI shape is the
## same, only `specialization` differs — "Adaptive" for the player
## (flexible, not as specialized as any one build), a named specialist
## (e.g. "Duelist") for companions. A character's `position_name` is
## permanent once chosen; nothing in the game ever changes it.

@export var id: String = ""
@export var display_name: String = ""
@export var position_name: String = "" # Fisherman | Spear Bearer | Scout | Light Bearer | Wave Controller
@export var specialization: String = "Adaptive" # "Adaptive" for the player; a specialist name for companions
@export var max_hp: int = 100
@export var max_sp: int = 100
@export var sp_per_basic_attack: int = 5
@export var attack: int = 10
@export var defense: int = 5
@export var move_speed: float = 180.0
@export var attack_range: float = 48.0 # melee reach in px; ranged Positions use a larger value
@export var is_player_controlled: bool = false
