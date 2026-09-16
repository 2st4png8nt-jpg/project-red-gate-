extends Resource
class_name EnemyData
## Enemy schema. `family` is used by equipment special effects
## (e.g. Cindermourn's bonus vs. the "ashen" family). See AGENT_CONTRACTS.md.

@export var id: String = ""
@export var display_name: String = ""
@export var family: String = ""
@export var max_hp: int = 10
@export var attack: int = 3
@export var defense: int = 1
@export var magic_power: int = 0
@export var speed: int = 3
@export var xp_reward: int = 5
@export var gold_reward: int = 2
@export var skill_ids: Array[String] = []
@export var loot_table_id: String = ""
@export var gate_clue_id: String = "" # discovered via GameState.discover_clue() on defeat, if set

# Enrage (added Phase 6 — boss AI variety): once hp/max_hp drops to or
# below enrage_threshold, BattleManager always uses enrage_skill_id
# instead of the normal attack/skill alternation, once, with a one-time
# flavor message. enrage_skill_id == "" means this enemy never enrages
# (every non-boss enemy today).
@export var enrage_threshold: float = 0.0
@export var enrage_skill_id: String = ""
