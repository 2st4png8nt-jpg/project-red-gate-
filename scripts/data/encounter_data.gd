extends Resource
class_name EncounterData
## A single-enemy battle definition. Multi-enemy encounters are a
## future extension (would grow `enemy_id` into an array) — not needed
## for the prototype. See AGENT_CONTRACTS.md.

@export var id: String = ""
@export var enemy_id: String = ""
@export var can_flee: bool = true
@export var level: int = 1 # scales the enemy via EnemyScaler; 1 = no change (default for all hand-authored rows)
@export var loot_table_id_override: String = "" # if set, used instead of the enemy's own loot_table_id (generated dungeons)
