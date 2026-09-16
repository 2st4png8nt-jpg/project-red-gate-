extends Resource
class_name EncounterData
## A battle definition against one or more enemies fought together as a
## pack (depth pass, post-Phase-6). 1 enemy = a solo boss/miniboss
## fight; 2-3 = a common-encounter pack. See AGENT_CONTRACTS.md.

@export var id: String = ""
@export var enemy_ids: Array[String] = []
@export var can_flee: bool = true
@export var level: int = 1 # scales every enemy via EnemyScaler; 1 = no change (default for all hand-authored rows)
@export var loot_table_id_override: String = "" # if set, used instead of any enemy's own loot_table_id (generated dungeons)
